#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(modules))
suppressMessages(library(argparse))
suppressMessages(library(tidyverse))
suppressMessages(library(BiocParallel))

options(error=function(){traceback(3); quit(save="no", status=1, runLast=FALSE)})

HERE <- (function() {return (dirname(sub("--file=", "", commandArgs(trailingOnly=FALSE)[grep("--file=", commandArgs(trailingOnly=FALSE))])))})()
suppressMessages(io <- modules::use(file.path(HERE, "modules/io.R")))
suppressMessages(analyses <- modules::use(file.path(HERE, "modules/analyses.R")))
suppressMessages(graphics <- modules::use(file.path(HERE, "modules/graphics.R")))
suppressMessages(logger <- modules::use(file.path(HERE, "modules/logger.R")))


assert_args <- function(args){
    args$target <- unique(trimws(unlist(strsplit(args$target, "[, \\s]+"))))             # to use it as a string input in CWL
    return(args)
}


get_args <- function() {
    parser <- ArgumentParser(description = "DESeq2 LRT Step 2")
    parser$add_argument(
        "--query",
        help=paste(
            "Path to the RDS file to load DESeq contrasts and",
            "expression data from. This file should be produced",
            "by the run_deseq_lrt_step_1.R script when executed",
            "with the --wald parameter and have a name",
            "*_all_contrasts.rds."
        ),
        type="character", required="True"
    )
    parser$add_argument(
        "--target",
        help=paste(
            "Target contrasts to run Wald test with. The available",
            "values can be selected from the Contrast number column",
            "of the *_all_contrasts.tsv file produced by the",
            "run_deseq_lrt_step_1.R script when executed with the",
            "--wald parameter. Multiple values are allowed."
        ),
        type="character", required="True", nargs="+"
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
            "Log2 fold change threshold used in the alternative",
            "hypothesis test. The alternative hypothesis can be",
            "selected in the --alternative parameter. Default: 0."
        ),
        type="double", default=0
    )
    parser$add_argument(
        "--alternative",
        help=paste(
            "The alternative hypothesis for the Wald test.",
            "greater - tests if the log2 fold change is greater",
            "than the threshold specified in the --logfc parameter,",
            "less - tests if the log2 fold change is less than the",
            "negative threshold specified in the --logfc parameter,",
            "lessAbs - tests if the absolute log2 fold change is",
            "less than the threshold specified in the --logfc parameter,",
            "greaterAbs - tests if the the absolute log2 fold change is",
            "greater than the threshold specified in the --logfc parameter.",
            "Default: greaterAbs"
        ),
        type="character", default="greaterAbs",
        choices=c("greater", "less", "lessAbs", "greaterAbs")
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
        header="DESeq2 LRT Step 2 (run_deseq_lrt_step_2.R)"
    )
    args <- assert_args(args)
    return(args)
}


args <- get_args()
print("Used parameters.")
print(args)

print(paste("Setting parallelizations to", args$cpus, "cores."))
register(MulticoreParam(args$cpus))

print("Loading query data.")
query_data <- readRDS(args$query)

print("Loaded metadata.")
metadata <- query_data$metadata
print(metadata)

print("Loaded design formula.")
args$design <- query_data$args$design                # should be already parsed as formula
print(args$design)

print("Loaded expression data.")
collected_deseq_results <- query_data$expression_data                                # we will save in this variable all deseq results
print(head(collected_deseq_results))

print("Loaded counts data.")
counts_data <- query_data$counts_data
print(head(counts_data))

print("Loaded normalized counts data.")                                              # we will need it for heatmap
norm_counts_data <- query_data$norm_counts_data                                      # may be already batch corrected by limma. Not filtered
print(head(norm_counts_data))

print("Loaded contrasts.")
all_contrasts <- query_data$contrasts
for (i in 1:length(all_contrasts)) {
    print(paste(names(all_contrasts)[[i]], "-", all_contrasts[[i]]$alias))
}

print("Selected contrasts.")
selected_contrasts <- all_contrasts[intersect(args$target, names(all_contrasts))]    # to select only those contrasts that a present
print(selected_contrasts)

if (length(selected_contrasts) == 0) {
    logger$info(
        paste(
            "Exiting: no target contrasts found."
        )
    )
    quit(save="no", status=1, runLast=FALSE)
}

cached_deseq_wald <- NULL
for (i in 1:length(selected_contrasts)) {
    current_contrast <- selected_contrasts[[i]]
    current_contrast_name <- names(selected_contrasts)[[i]]

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
    diff_expr_data <- analyses$get_diff_expr_data(
        counts_data=counts_data,                                        # this can be already batch-corrected by CombatSeq
        metadata=metadata,
        contrast=current_contrast,
        design_formula=args$design,
        padj=args$padj,
        logfc=args$logfc,
        alternative_hypothesis=args$alternative,
        cpus=args$cpus,
        cached_deseq_wald=cached_deseq_wald
    )
    if (!is.null(diff_expr_data)){
        current_deseq_results <- as.data.frame(diff_expr_data$results) %>%                                  # not filtered, may include NA's
                                 dplyr::select(log2FoldChange, pvalue, padj) %>%
                                 dplyr::rename(
                                     !!paste0(current_contrast_name, "_log2FoldChange"):=log2FoldChange,
                                     !!paste0(current_contrast_name, "_pvalue"):=pvalue,
                                     !!paste0(current_contrast_name, "_padj"):=padj
                                 )
        collected_deseq_results <- collected_deseq_results[rownames(current_deseq_results), ] %>%                   # to make sure the proper order
                                   bind_cols(current_deseq_results)
        cached_deseq_wald <- diff_expr_data$deseq_wald

        volcano_plot_data <- as.data.frame(diff_expr_data$results) %>%
                             rownames_to_column(var="Feature")
        graphics$volcano_plot(
            data=volcano_plot_data,
            x_axis="log2FoldChange",
            y_axis="padj",
            x_cutoff=args$logfc,
            y_cutoff=args$padj,
            x_label="log2 FC",
            y_label="-log10 Padj",
            label_column="Feature",
            plot_title=paste(current_contrast_name, current_contrast$alias, sep=", "),
            plot_subtitle="",
            caption=paste(nrow(volcano_plot_data), "features"),
            rootname=paste(args$output, current_contrast_name, "vlcn", sep="_")
        )
    }
}
print("Collected DESeq results")
collected_deseq_results <- collected_deseq_results %>%
                           rownames_to_column(var="Feature")                                 # we need to to join with cluster information
print(head(collected_deseq_results))
if(!any(grepl("_padj$", colnames(collected_deseq_results)))){                                # to check that we have at least one contrast successfully calculated
    logger$info(
        paste(
            "Exiting: neither of the selected",
            "contrasts were successfully calculated."
        )
    )
    quit(save="no", status=1, runLast=FALSE)
}

print(
    paste(
        "Filtering collected DESeq results to include",
        "only differentially expressed features with padj <=", args$padj,
        "in at least one contrast"
    )
)
row_metadata <- collected_deseq_results %>%
                remove_rownames() %>%
                column_to_rownames("Feature") %>%
                dplyr::select(
                    RefseqId, GeneId, Chrom, TxStart, TxEnd, Strand,
                    ends_with("_log2FoldChange"), ends_with("_pvalue"), ends_with("_padj")
                ) %>%
                dplyr::filter(
                    if_any(ends_with("_padj"), function(x) x<=args$padj)
                )
print(head(row_metadata))

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
                collected_deseq_results <- merge(
                    collected_deseq_results,
                    row_metadata[, cluster_columns, drop=FALSE] %>% rownames_to_column(var="Feature"),    # need drop=FALSE in case only one HCL column present
                    by="Feature",
                    all.x=TRUE,
                    sort=FALSE
                )
                print(head(collected_deseq_results))
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
    collected_deseq_results,
    location=paste0(args$output, "_diff_expr.tsv"),
    row_names=FALSE
)