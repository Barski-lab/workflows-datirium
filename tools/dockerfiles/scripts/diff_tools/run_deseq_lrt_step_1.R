#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(DESeq2))
suppressMessages(library(modules))
suppressMessages(library(argparse))
suppressMessages(library(tidyverse))
suppressMessages(library(BiocParallel))

options(error=function(){traceback(3); quit(save="no", status=1, runLast=FALSE)})

# https://www.atakanekiz.com/technical/a-guide-to-designs-and-contrasts-in-DESeq2/

HERE <- (function() {return (dirname(sub("--file=", "", commandArgs(trailingOnly=FALSE)[grep("--file=", commandArgs(trailingOnly=FALSE))])))})()
suppressMessages(io <- modules::use(file.path(HERE, "modules/io.R")))
suppressMessages(analyses <- modules::use(file.path(HERE, "modules/analyses.R")))
suppressMessages(logger <- modules::use(file.path(HERE, "modules/logger.R")))


assert_args <- function(args){

    if (length(args$expression) != length(args$aliases)) {
        logger$info(
            paste(
                "Exiting: the --expression and --aliases",
                "parameters should have the same length."
            )
        )
        quit(save="no", status=1, runLast=FALSE)
    }

    if (is.null(args$batch) != is.null(args$correction)){
        logger$info(
            paste(
                "Exiting: for batch correction both",
                "--batch and --correction parameters",
                "should be provided."
            )
        )
        quit(save="no", status=1, runLast=FALSE)
    }

    if (
        grepl("\\*", args$design) ||
        grepl("\\*", args$reduced)
    ){
        logger$info(
            paste(
                "Exiting: both of the --design and",
                "--reduced formulas should be povided",
                "in the expanded form (without *)."
            )
        )
        quit(save="no", status=1, runLast=FALSE)
    }
    args$design <- as.formula(args$design)
    args$reduced <- as.formula(args$reduced)

    if (
        !is.null(args$batch) &&
        !(args$batch %in% unique(all.vars(args$design)))
    ){
        logger$info(
            paste(
                "Exiting: the --batch parameter should",
                "also be used in the --design formula."
            )
        )
        quit(save="no", status=1, runLast=FALSE)
    }

    args$aliases <- io$adjust_names(args$aliases)
    if (anyDuplicated(args$aliases) > 0) {
        logger$info(
            paste(
                "Exiting: the sample names provided",
                "in the --aliases parameter shouldn't",
                "include any duplicates."
            )
        )
        quit(save="no", status=1, runLast=FALSE)
    }

    return(args)
}


get_args <- function() {
    parser <- ArgumentParser(description = "DESeq2 LRT Step 1")
    parser$add_argument(
        "--expression",
        help=paste(
            "Path to the TSV/CSV files to load expression data from.",
            "The following header is required: RefseqId, GeneId,",
            "Chrom, TxStart, TxEnd, Strand, TotalReads, Rpkm.",
            "The expression data should be grouped by RefseqId."
        ),
        type="character",
        required="True",
        nargs="+"
    )
    parser$add_argument(
        "--groupby",
        help=paste(
            "Feature type to group expression by. gene - group by",
            "the GeneId column, isoform - group by the RefseqId",
            "column, tss - group by the Chrom, TxStart, and Strand",
            "columns for a positive strand and by the Chrom, TxEnd,",
            "and Strand columns for a negative strand. Default: gene."
        ),
        type="character",
        default="gene",
        choices=c("gene", "isoform", "tss")
    )
    parser$add_argument(
        "--aliases",
        help=paste(
            "Unique sample names to be assigned to the expression",
            "files provided in the --expression parameter. The number",
            "and the order of the provided values should match the",
            "expression files."
        ),
        type="character",
        required="True",
        nargs="+"
    )
    parser$add_argument(
        "--metadata",
        help=paste(
            "Path to the TSV/CSV file to describe the relation between",
            "the samples. All columns names can be arbitrary but should.",
            "be unique. The first column should correspond to the values",
            "provided in the --aliases parameter. All the remaining columns",
            "can be used in the design and reduced formulas."
        ),
        type="character",
        required="True"
    )
    parser$add_argument(
        "--design",
        help=paste(
            "A design formula. It should start with ~ and consist",
            "of values that correspond to the column names of the",
            "samples metadata loaded from the file provided in the",
            "--metadata parameter. The formula should be provided in",
            "the expanded format (without *)."
        ),
        type="character",
        required="True"
    )
    parser$add_argument(
        "--reduced",
        help=paste(
            "A reduced formula to compare against the design formula",
            "The term(s) of interest should be removed. The formula",
            "should start with ~ and consist of values that correspond",
            "to the column names of the samples metadata loaded from",
            "the file provided in the --metadata parameter. The formula",
            "should be provided in the expanded format (without *)."
        ),
        type="character",
        required="True"
    )
    parser$add_argument(
        "--correction",
        help=paste(
            "Optional batch correction method. When combatseq is selected",
            "the batch effect is removed from the read counts before running",
            "the differential expression analysis. limma correct batch effect",
            "only after differential expression analysis has already finished",
            "running and mainly impacts the read counts heatmap. Both --correction",
            "and --batch parameters should be provided. Default: do not correct",
            "for batch effect."
        ),
        type="character",
        choices=c("combatseq", "limma")
    )
    parser$add_argument(
        "--batch",
        help=paste(
            "Column from the samples metadata loaded from the file provided in",
            "the --metadata parameter to correct for batch effect. If provided",
            "it should also be present in the design formula. When --correction",
            "is set to combatseq, all formula terms that include the value provided",
            "in the --batch parameter will be removed from the design and reduced",
            "formulas as the batch effect was corrected on the raw read counts level.",
            "When --correction is set to limma, no adjustments of the design or reduced",
            "formulas are made. Both --batch and --correction parameters should be",
            "provided. Default: do not correct for batch effect."
        ),
        type="character"
    )
    parser$add_argument(
        "--rpkm",
        help=paste(
            "Filtering threshold to keep only those features where the max RPKM for",
            "all datasets is bigger than or equal to the provided value. Default: 3"
        ),
        type="double", default=3
    )
    parser$add_argument(
        "--padj",
        help=paste(
            "In the exploratory visualization part of the analysis output only features",
            "with adjusted p-value (FDR) not bigger than this value. Also this value is",
            "used the significance cutoff used for optimizing the independent filtering.",
            "Default: 0.1."
        ),
        type="double",
        default=0.1
    )
    parser$add_argument(
        "--logfc",
        help=paste(
            "Log2 fold change threshold used in the Wald test results filtering.",
            "This value is also used in the alternative hypothesis testing when",
            "the analysis is run with the --strict parameter. Otherwise, the",
            "alternative hypothesis is tested with the log2 fold change value",
            "equal to 0. Ignored when --wald parameter is not provided.",
            "Default: 0.59."
        ),
        type="double", default=0.59
    )
    parser$add_argument(
        "--strict",
        help=paste(
            "Use provided --logfc threshold in the alternative hypothesis",
            "testing. The alternative hypothesis can be set with the",
            "--alternative parameter. Ignored when --wald parameter is",
            "not provided. Default: not strict, use 0 as the log2 fold",
            "change threshold in the alternative hypothesis testing."
        ),
        action="store_true"
    )
    parser$add_argument(
        "--alternative",
        help=paste(
            "The alternative hypothesis for the Wald test.",
            "greater - tests if the log2 fold change is greater",
            "than 0 or the threshold specified in the --logfc parameter",
            "when run with --strict.",
            "less - tests if the log2 fold change is less than 0 or the",
            "negative threshold specified in the --logfc parameter",
            "when run with --strict.",
            "greaterAbs - tests if the the absolute log2 fold change is",
            "greater than 0 or the threshold specified in the --logfc parameter",
            "when run with --strict. Ignored when --wald parameter is",
            "not provided. Default: greaterAbs"
        ),
        type="character", default="greaterAbs",
        choices=c("greater", "less", "greaterAbs")
    )
    parser$add_argument(
        "--cluster",
        help=paste(
            "Hopach clustering method to be run on normalized read counts for the",
            "exploratory visualization analysis. Default: do not run clustering."
        ),
        type="character",
        choices=c("row", "column", "both")
    )
    parser$add_argument(
        "--rowdist",
        help=paste(
            "Distance metric for HOPACH row clustering. Ignored if --cluster is not",
            "provided. Default: cosangle."
        ),
        type="character", default="cosangle",
        choices=c("cosangle", "abscosangle", "euclid", "abseuclid", "cor", "abscor")
    )
    parser$add_argument(
        "--columndist",
        help=paste(
            "Distance metric for HOPACH column clustering. Ignored if --cluster is not",
            "provided. Default: euclid."
        ),
        type="character", default="euclid",
        choices=c("cosangle", "abscosangle", "euclid", "abseuclid", "cor", "abscor")
    )
    parser$add_argument(
        "--depth",
        help=paste(
            "The maximum number of levels (depth) in",
            "the HOPACH clustering tree. Default: 3."
        ),
        type="integer", default=3
    )
    parser$add_argument(
        "--branches",
        help=paste(
            "The maximum number of children (branches) at each",
            "node in the HOPACH clustering tree. Default: 5."
        ),
        type="integer", default=5
    )
    parser$add_argument(
        "--wald",
        help=paste(
            "Run Wald test to calculate results",
            "for multiple contrasts."
        ),
        action="store_true"
    )
    parser$add_argument(
        "--output",
        help=paste(
            "Output prefix for generated files."
        ),
        type="character", default="./deseq"
    )
    parser$add_argument(
        "--cpus",
        help="Number of cores/cpus to use. Default: 1.",
        type="integer",
        default=1
    )
    args <- parser$parse_args(commandArgs(trailingOnly=TRUE))
    logger$setup(
        file.path(dirname(ifelse(args$output == "", "./", args$output)), "error_report.txt"),
        header="DESeq2 LRT Step 1 (run_deseq_lrt_step_1.R)"
    )
    logger$setup(
        location=paste0(args$output, "_summary.md"),
        name="summary",
        header="# Results Summary\n---"
    )
    args <- assert_args(args)
    return(args)
}


args <- get_args()
print("Used parameters.")
print(args)

print(paste("Setting parallelizations to", args$cpus, "cores."))
register(MulticoreParam(args$cpus))

print("Loading metadata.")
metadata <- io$load_metadata(args$metadata)
print(metadata)

logger$info(
    message="### Metadata",
    name="summary",
    skip_stdout=TRUE
)
for (i in 1:length(colnames(metadata))){
    logger$info(
        message=paste0(
            "- Column ***", colnames(metadata)[i], "*** ",
            "with levels ***", paste(levels(metadata[[i]]), collapse="***, ***"), "***."
        ),
        name="summary",
        skip_stdout=TRUE
    )
}

if (anyDuplicated(rownames(metadata)) > 0) {
    logger$info(
        paste(
            "Exiting: the first columns in",
            "the metadata shouldn't include",
            "any duplicates."
        )
    )
    quit(save="no", status=1, runLast=FALSE)
}

if (!setequal(rownames(metadata), args$aliases)){                               # we already cheched that neither metadata nor aliases have duplicates
    logger$info(
        paste(
            "Exiting: the sample names in the",
            "metadata should correspond to the",
            "sample names provided in the aliases",
            "parameter."
        )
    )
    quit(save="no", status=1, runLast=FALSE)
}

if (!is.null(args$batch) && !(args$batch %in% colnames(metadata))){
    logger$info(
        paste(
            "Exiting: the batch parameter",
            "should be used as one of the",
            "samples metadata column."
        )
    )
    quit(save="no", status=1, runLast=FALSE)
}

print("Loading gene expression.")
expression_data <- io$load_expression_data(
    locations=args$expression,
    aliases=args$aliases,
    groupby=args$groupby,
    rpkm_threshold=args$rpkm
)
print(head(expression_data))

logger$info(
    message="### Expression",
    name="summary",
    skip_stdout=TRUE
)
logger$info(
    message=paste0(
        "- Total of ***", nrow(expression_data), "*** features ",
        "grouped by ***", args$groupby, "***",
        ifelse(
            args$rpkm > 0,
            paste0(
                " filtered by minimum ***", args$rpkm,
                "*** rpkm accross all samples."
            ),
            "."
        )
    ),
    name="summary",
    skip_stdout=TRUE
)

if (nrow(expression_data) == 0){
    logger$info(
        paste(
            "Exiting: loaded expression",
            "data is empty - check the",
            "minimum RPKM threshold."
        )
    )
    quit(save="no", status=1, runLast=FALSE)
}

print("Extracting counts data.")
counts_data <- io$get_counts_data(expression_data, metadata)
print(head(counts_data))

if (!is.null(args$correction) && args$correction=="combatseq"){            # we already checked that --correction was provided, the --batch
    print(                                                                 # was provided and the --batch was present in the --design formula
        paste(
            "Removing the effect of", args$batch,
            "from the raw read counts using ComBat-Seq.",
            "All terms that include", args$batch,
            "will be removed from the design and",
            "reduced formulas."
        )
    )
    args$design <- as.formula(
        paste0(
            "~",
            paste(
                grep(
                    args$batch,
                    unlist(
                        strsplit(
                            as.character(args$design)[2],
                            "\\+"
                        )
                    ),
                    value=TRUE,
                    ignore.case=TRUE,
                    invert=TRUE
                ),
                collapse="+"
            )
        )
    )
    print(
        paste(
            "Updated design formula:",
            as.character(args$design)[2]
        )
    )

    args$reduced <- as.formula(
        paste0(
            "~",
            paste(
                grep(
                    args$batch,
                    unlist(
                        strsplit(
                            as.character(args$reduced)[2],
                            "\\+"
                        )
                    ),
                    value=TRUE,
                    ignore.case=TRUE,
                    invert=TRUE
                ),
                collapse="+"
            )
        )
    )
    print(
        paste(
            "Updated reduced formula:",
            as.character(args$reduced)[2]
        )
    )

    counts_data <- analyses$get_combat_seq_counts(                                      # either GeneId or RefseqId will be the rownames
        counts_data=counts_data,
        metadata=metadata,
        batch=args$batch,
        design_formula=args$design
    )
    print("CombatSeq batch corrected counts data.")
    print(head(counts_data))
}

print("Constracting DESeq2 object.")
deseq_data <- DESeqDataSetFromMatrix(
    countData=counts_data,                                                     # can be already batch corrected by CombatSeq
    colData=metadata,
    design=args$design                                                         # the terms with the --batch might be already excluded if CombatSeq was applied
)

print("Running DESeq2 using LRT")
deseq_lrt <- DESeq(
    deseq_data,
    test="LRT",
    reduced=args$reduced,                                                      # the terms with the --batch might be already exclude if CombatSeq was applied
    quiet=TRUE,
    parallel=TRUE,
    BPPARAM=MulticoreParam(args$cpus)
)

print("Retrieving normalized counts data.")
norm_counts_data <- assay(rlog(deseq_lrt, blind=FALSE))                        # it doesn't matter which test we run Wald or LRT
print(head(norm_counts_data))

if (!is.null(args$correction) && args$correction=="limma"){                    # we already checked that --correction was provided, the --batch
    print(                                                                     # was provided and the --batch was present in the --design formula
        paste(
            "Removing the effect of", args$batch,
            "from the normalized read counts using",
            "limma. All terms that include", args$batch,
            "will be temporary removed the from the",
            "design formula."
        )
    )
    norm_counts_data <- analyses$get_limma_counts(
        counts_data=norm_counts_data,
        metadata=metadata,
        batch=args$batch,
        design_formula=args$design
    )
    print("Limma batch corrected normalized counts data.")
    print(head(counts_data))
}

logger$info(
    message="### Experimental Design",
    name="summary",
    skip_stdout=TRUE
)
logger$info(
    message=paste0(
        "- Design formula ***~ ", as.character(args$design)[2], "***.\n",
        "- Reduced formula ***~ ", as.character(args$reduced)[2], "***.\n",
        ifelse(
            !is.null(args$correction),
            paste0(
                "- Batch correction by ***", args$batch, "*** using ***",
                args$correction, "*** method",
                ifelse(
                    args$correction == "combatseq",
                    paste0(
                        " (correcting raw read counts, all terms that include",
                        " ***", args$batch, "*** have been removed from the design",
                        " and reduced formulas)."
                    ),
                    paste0(
                        " (correcting normalized read counts, both design and",
                        " reduced formulas have not been changed, only MDS plot and",
                        " heatmap show corrected results)."
                    )
                )
            ),
            ""
        )
    ),
    name="summary",
    skip_stdout=TRUE
)

io$export_mds_html_plot(
    counts_data=norm_counts_data,
    metadata=metadata,
    location=paste0(args$output, "_mds_plot.html")
)

print("Retrieving DESeq2 LRT results")
deseq_lrt_results <- results(
    deseq_lrt,
    alpha=args$padj,
    independentFiltering=TRUE,
    parallel=TRUE,
    BPPARAM=MulticoreParam(args$cpus)
)

logger$info(
    message="### LRT Results",
    name="summary",
    skip_stdout=TRUE
)
deseq_lrt_summary <- capture.output(DESeq2::summary(deseq_lrt_results))
logger$info(
    message=paste0(
        "- Removing the term(s) of interest from the reduced formula",
        " resulted in changes in expression levels for ***",
        sum(deseq_lrt_results$padj < args$padj, na.rm=TRUE), "*** features _<sup>1</sup>_",
        " (***padj <= ", args$padj, "***).\n",
        "- Number of features removed as outliers: ***",
        gsub(".*: ", "", deseq_lrt_summary[6]), "***.\n",
        "- Number of features removed due to low read counts",
        " (***mean < ",  gsub("[^0-9]", "", deseq_lrt_summary[8]), "***):",
        " ***", gsub(".*: ", "", deseq_lrt_summary[7]), "***."
    ),
    name="summary",
    skip_stdout=TRUE
)

deseq_lrt_results <- as.data.frame(deseq_lrt_results) %>%
                     dplyr::select(pvalue, padj) %>%
                     na.omit()

deseq_lrt_results <- expression_data[rownames(deseq_lrt_results), ] %>%             # to make sure the proper order and exlcuding all features with NA
                     bind_cols(deseq_lrt_results) %>%
                     rownames_to_column(var="Feature")                              # we need to to join with cluster information
print(head(deseq_lrt_results))

print(
    paste(
        "Filtering normalized read counts matrix to include",
        "only differentially expressed features with padj <=", args$padj
    )
)
row_metadata <- deseq_lrt_results %>%
                remove_rownames() %>%
                column_to_rownames("Feature") %>%
                dplyr::select(c("RefseqId", "GeneId", "Chrom", "TxStart", "TxEnd", "Strand", "pvalue", "padj")) %>%
                filter(.$padj <= args$padj)

col_metadata <- metadata %>%
                mutate_at(colnames(.), as.vector)

if(nrow(row_metadata) > 0){
    filtered_norm_counts_data <- norm_counts_data[as.vector(rownames(row_metadata)), ]

    if (!is.null(args$cluster)){
        if (args$cluster == "column" || args$cluster == "both") {
            print("Clustering filtered read counts by columns")
            clustered_data = analyses$get_clustered_data(
                expression_data=filtered_norm_counts_data,
                zscore=TRUE,
                dist=args$columndist,
                depth=args$depth,
                branches=args$branches,
                transpose=TRUE
            )
            col_metadata <- cbind(col_metadata, clustered_data$clusters)       # adding cluster labels
            col_metadata <- col_metadata[clustered_data$order, ]               # reordering samples order based on the HOPACH clustering resutls
            print("Reordered samples")
            print(col_metadata)
        }
        if (args$cluster == "row" || args$cluster == "both") {
            print("Clustering filtered normalized read counts by rows")
            clustered_data = analyses$get_clustered_data(
                expression_data=filtered_norm_counts_data,
                zscore=TRUE,
                dist=args$rowdist,
                depth=args$depth,
                branches=args$branches,
                transpose=FALSE
            )
            row_metadata <- cbind(row_metadata, clustered_data$clusters)       # adding cluster labels
            row_metadata <- row_metadata[clustered_data$order, ]               # reordering features order based on the HOPACH clustering results
            print("Reordered features")
            print(head(row_metadata))
            cluster_columns <- grep(
                "HCL",
                colnames(row_metadata),
                value=TRUE,
                ignore.case=TRUE
            )
            if (length(cluster_columns) > 0){                                  # check the length just in case
                deseq_lrt_results <- deseq_lrt_results %>%
                                     dplyr::left_join(
                                         row_metadata[, cluster_columns, drop=FALSE] %>% rownames_to_column(var="Feature"),
                                         by="Feature"
                                     )
                print(head(deseq_lrt_results))
            }
        }
    }

    print("Converting expression data to z-scores")                            # we always run it, because we don't use the modified expression data from the get_clustered_data
    filtered_norm_counts_data <- t(
        scale(t(filtered_norm_counts_data), center=TRUE, scale=TRUE)
    )

    io$export_gct(
        counts_mat=filtered_norm_counts_data,
        row_metadata=row_metadata,
        col_metadata=col_metadata,
        location=paste0(args$output, "_read_counts.gct")
    )
    expression_limits <- stats::quantile(                                      # to exclude outliers
        abs(filtered_norm_counts_data), 0.99, na.rm=TRUE, names=FALSE
    )
    io$export_morpheus_html_heatmap(
        gct_location=paste0(args$output, "_read_counts.gct"),
        rootname=paste0(args$output, "_read_counts"),
        color_scheme=list(
            scalingMode="fixed",
            stepped=FALSE,
            values=as.list(c(-expression_limits, 0, expression_limits)),
            colors=c("darkblue", "black", "yellow")
        )
    )
    rm(filtered_norm_counts_data)                                              # no reason to keep it
    gc(verbose=FALSE)
}

io$export_data(
    deseq_lrt_results,
    location=paste0(args$output, "_diff_expr.tsv"),
    row_names=FALSE
)

if (!is.null(args$wald) && args$wald) {
    all_contrasts <- analyses$get_all_contrasts(                                            # sorted by main_effect_levels contrasts
        metadata=metadata,
        design_formula=args$design
    )
    rds_data <- list(
        expression_data=expression_data,                                              # original expression data loaded from the --expression files
        counts_data=counts_data,
        norm_counts_data=norm_counts_data,                                            # not filtered normalized counts data. May be batch corrected by limma
        metadata=metadata,
        contrasts=all_contrasts,
        args=args
    )
    io$export_rds(rds_data, paste0(args$output, "_all_contrasts.rds"))

    collected_contrast_data <- NULL
    cached_deseq_wald <- NULL
    for (i in 1:length(all_contrasts)) {
        current_contrast <- all_contrasts[[i]]
        current_contrast_name <- names(all_contrasts)[[i]]

        print("Processing contrast")
        print(paste("   id:", current_contrast$id))
        print(paste("   name:", current_contrast_name))
        print(paste("   alias:", current_contrast$alias))
        print(paste("   main:", current_contrast$main_effect))
        print(paste("   interactions:", paste(current_contrast$interaction_effects, collapse=", ")))
        print(paste("   main variable:", current_contrast$main_effect_var))
        print(paste("   main levels:", paste(current_contrast$main_effect_levels, collapse=", ")))
        print(paste("   interaction variables:", paste(current_contrast$interaction_effect_vars, collapse=", ")))
        print(paste("   interaction levels:", paste(
                                                  sapply(current_contrast$interaction_effect_levels,
                                                  function(x) paste(x, collapse = ", ")),
                                                  collapse="; "
                                              )
                   )
        )
        similar_contrast <- collected_contrast_data[                            # can be either data frame with 0 or 1 row or NULL if collected_contrast_data is NULL
            collected_contrast_data$id == current_contrast$id, ,
            drop=FALSE
        ]

        filtered_features_count <- NULL
        if (!is.null(similar_contrast) && nrow(similar_contrast) == 1){         # if similar contrast present, there should be only one of it
            print("Found similar contrast, skipping running DESeq")
            print(similar_contrast)
            filtered_features_count <- similar_contrast[1, "Significant features count"]
        } else {
            diff_expr_data <- analyses$get_diff_expr_data(
                counts_data=counts_data,                                        # this can be already batch-corrected by CombatSeq
                metadata=metadata,
                contrast=current_contrast,
                design_formula=args$design,
                padj=args$padj,
                logfc=ifelse(args$strict, args$logfc, 0),                       # if run with --strict, we want to use --logfc in the alternative hypothesis testing
                alternative_hypothesis=args$alternative,
                cpus=args$cpus,
                cached_deseq_wald=cached_deseq_wald
            )
            if (!is.null(diff_expr_data)){
                filtered_features_count <- nrow(
                                               as.data.frame(diff_expr_data$results) %>%
                                               dplyr::filter(.$padj <= args$padj) %>%
                                               dplyr::filter(abs(.$log2FoldChange) >= args$logfc)
                                           )
                cached_deseq_wald <- diff_expr_data$deseq_wald
            }
        }

        if (!is.null(filtered_features_count)){                                 # we get it either from similar contrast of DESeq
            print(
                paste(
                    "Number of significant diff. expressed",
                    "features:", filtered_features_count
                )
            )
            current_contrast_data <- data.frame(
                                         "id"=current_contrast$id,
                                         "Contrast number"=current_contrast_name,
                                         "Description"=current_contrast$alias,
                                         "Main effect"=current_contrast$main_effect,
                                         "Interaction effect"=ifelse(
                                                                  length(current_contrast$interaction_effects) == 0,
                                                                  "None",
                                                                  paste(current_contrast$interaction_effects, collapse=", ")
                                                              ),
                                         "Significant features count"=filtered_features_count,
                                         stringsAsFactors=FALSE,
                                         check.names=FALSE
                                     )
            if (is.null(collected_contrast_data)) {
                collected_contrast_data <- current_contrast_data
            } else {
                collected_contrast_data = rbind(
                    collected_contrast_data, current_contrast_data
                )
            }
        }
    }
    io$export_data(
        collected_contrast_data %>% select(-c("id")),
        location=paste0(args$output, "_all_contrasts.tsv"),
        row_names=FALSE
    )
    logger$info(
        message="### Wald Results",
        name="summary",
        skip_stdout=TRUE
    )
    logger$info(
        message=paste0(
            "- Found ***",
            ifelse(
                !is.null(collected_contrast_data),
                nrow(collected_contrast_data),
                0
            ), "*** pairwise contrasts _<sup>2</sup>_."
        ),
        name="summary",
        skip_stdout=TRUE
    )
}

logger$info(
    message=paste0(
        "\n_<sup>1</sup> If the number of significant differentially expressed",
        " features is substantial, consider including the interaction term",
        " in your design formula._\n",
        ifelse(
            !is.null(args$wald) && args$wald,
            paste0(
                "\n_<sup>2</sup> Refer to the correspondent tab to view the number",
                " of significanlty differentially expressed features. The results",
                " were filtered by padj <= ",args$padj, " and |log2FoldChange| >= ",
                args$logfc, " in each of the calculated contrasts. The alternative",
                " hypothesis ", args$alternative, " tests if ",
                switch(
                    args$alternative,
                        "greater" = "the log2 fold change is greater than ",
                        "less" = paste0(
                                     "the log2 fold change is less than ",
                                     ifelse(args$strict && args$logfc != 0, "-", "")
                                 ),
                        "greaterAbs" = "the the absolute log2 fold change is greater than "
                ),
                ifelse(args$strict, args$logfc, 0),
                "._"
            ),
            ""
        )
    ),
    name="summary",
    skip_stdout=TRUE
)