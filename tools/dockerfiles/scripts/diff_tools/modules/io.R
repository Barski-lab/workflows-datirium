import("cmapR", attach=FALSE)
import("dplyr", attach=FALSE)
import("purrr", attach=FALSE)
import("tibble", attach=FALSE)
import("forcats", attach=FALSE)
import("morpheus", attach=FALSE)
import("data.table", attach=FALSE)
import("magrittr", `%>%`, attach=TRUE)

export(
    "get_file_type",
    "adjust_names",
    "export_data",
    "export_rds",
    "export_lrt_summary",
    "export_mds_html_plot",
    "export_gct",
    "export_morpheus_html_heatmap",
    "load_metadata",
    "load_expression_data",
    "get_counts_data",
    "READ_COL",
    "RPKM_COL",
    "INTERSECT_BY"
)

READ_COL <- "TotalReads"
RPKM_COL <- "Rpkm"
INTERSECT_BY <- c("Feature", "RefseqId", "GeneId", "Chrom", "TxStart", "TxEnd", "Strand")

get_file_type <- function (filename){
    ext <- tools::file_ext(filename)
    separator <- "\t"
    if (ext == "csv"){
        separator <- ","
    }
    return (separator)
}

adjust_names <- function(names) {
    names <- base::gsub(
        "^_+|_+$", "",
        base::gsub(
            "[^[:alnum:]_]", "",
            base::gsub(
                "\\s+", "_",
                trimws(names)
            )
        )
    )
    return(names)
}

export_data <- function(data, location, row_names=FALSE, col_names=TRUE, quote=FALSE, digits=NULL){
    base::tryCatch(
        expr = {
            if (!is.null(digits)){
                data <- base::format(data, digits=digits)
            }
            utils::write.table(
                data,
                file=location,
                sep=get_file_type(location),
                row.names=row_names,
                col.names=col_names,
                quote=quote
            )
            base::print(base::paste("Export data to", location))
        },
        error = function(e){
            base::print(base::paste("Failed to export data to", location))
        }
    )
}

export_rds <- function(data, location){
    base::tryCatch(
        expr = {
            base::saveRDS(data, location)
            base::print(base::paste("Exporting data as RDS to", location))
        },
        error = function(e){
            base::print(base::paste("Failed to export data as RDS to", location))
        }
    )
}

export_lrt_summary <- function(deseq_results, location, args){
    significant_genes <- sum(deseq_results$padj < args$padj, na.rm=TRUE)
    total_genes <- sum(!is.na(deseq_results$padj))
    summary_output <- utils::capture.output(base::summary(deseq_results))
    outliers <- base::gsub(".*: ", "", summary_output[6])
    low_counts <- base::gsub(".*: ", "", summary_output[7])
    mean_count <- base::gsub("[^0-9]", "", summary_output[8])

    md_content <- base::paste0(
        "# Likelihood Ratio Test (LRT) Results\n\n---\n\n",
        "Based on your **full formula**: `~", as.character(args$design)[2], "` and **reduced formula**: `~", as.character(args$reduced)[2], "`, ",
        "this LRT analysis tests whether removing the term of interest significantly affects the expression levels. ",
        "The test uses only the **FDR adjusted p-value** (padj) to determine significance, as Log Fold Change (LFC) is irrelevant in the context of LRT.\n\n",
        "### Results Summary\n\n",
        "From this LRT analysis, **", significant_genes, " features** (out of ", total_genes, " tested) are identified as significant with a padj value < ", args$padj, ".\n\n",
        "**Outliers**<sup>1</sup>: ", outliers, " of features were detected as outliers and excluded from the analysis.\n\n",
        "**Low counts**<sup>2</sup>: ", low_counts, " of features were removed due to low counts (mean <", mean_count, ") and independent filtering.\n\n",
        "Arguments of ?DESeq2::results():   \n<sup>1</sup> - see 'cooksCutoff',\n<sup>2</sup> - see 'independentFiltering'\n\n",
        "---\n\n",
        "### Next Steps\n\n",
        "If the number of significant features is substantial, consider including the interaction term in your design formula ",
        "for a more detailed differential expression analysis.\n\n",
        "For further insights and to explore detailed contrasts using the Wald test for the complex design formula, ",
        "please visit the **Complex Interaction Analysis** tab for more information.\n\n"
    )
    base::writeLines(md_content, con=location)
}

export_mds_html_plot <- function(counts_data, metadata, location) {
    base::tryCatch(
        expr = {
            htmlwidgets::saveWidget(
                Glimma::glimmaMDS(
                    x=counts_data,
                    groups=base::as.data.frame(metadata),
                    labels=base::rownames(metadata)
                ),
                file=location
            )
            base::print(base::paste("Exporting MDS plot to", location))
        },
        error = function(e){
            base::print(
                base::paste(
                    "Failed to export MDS plot to",
                    location, "with error", e
                )
            )
        }
    )
}

export_gct <- function(counts_mat, location, row_metadata=NULL, col_metadata=NULL){
    base::tryCatch(
        expr = {
            if (!is.null(row_metadata)){
                row_metadata <- row_metadata %>%
                                tibble::rownames_to_column("id") %>%
                                dplyr::mutate_all(base::as.vector)               # all columns should be vectors
                counts_mat <- counts_mat[row_metadata$id, ]                      # to guarantee the order and number of rows
            }
            if (!is.null(col_metadata)){
                col_metadata <- col_metadata %>%
                                tibble::rownames_to_column("id") %>%
                                dplyr::mutate_all(base::as.vector)               # all columns should be vectors
                counts_mat <- counts_mat[, col_metadata$id]                      # to guarantee the order and number of columns
            }
            gct_data <- methods::new(
                "GCT",
                mat=counts_mat,
                rdesc=row_metadata,                                              # can be NULL
                cdesc=col_metadata                                               # can be NULL
            )
            cmapR::write_gct(
                ds=gct_data,
                ofile=location,
                appenddim=FALSE
            )
            base::print(base::paste("Exporting GCT data to", location))
        },
        error = function(e){
            base::print(base::paste("Failed to export GCT data to", location, "with error -", e))
        }
    )
}

export_morpheus_html_heatmap <- function(gct_location, rootname, color_scheme=NULL){
    base::tryCatch(
        expr = {
            location <- base::paste0(rootname, ".html")                             # need to define it before anything possibly fails
            is_all_numeric <- function(x) {
                !any(
                    is.na(base::suppressWarnings(as.numeric(stats::na.omit(x))))
                ) & is.character(x)
            }
            base::print(
                base::paste("Loading GCT data from", gct_location)
            )
            gct_data <- morpheus::read.gct(gct_location)
            html_data <- morpheus::morpheus(
                x=gct_data$data,
                rowAnnotations=if(base::nrow(gct_data$rowAnnotations) == 0)
                                   NULL
                               else
                                   gct_data$rowAnnotations %>% dplyr::mutate_if(is_all_numeric, as.numeric),
                columnAnnotations=if(base::nrow(gct_data$columnAnnotations) == 0)
                                      NULL
                                  else
                                      gct_data$columnAnnotations,
                colorScheme=color_scheme
            )
            htmlwidgets::saveWidget(
                html_data,
                file=location
            )
            base::print(
                base::paste0("Exporting morpheus heatmap to ", location)
            )
        },
        error = function(e){
            base::print(
                base::paste(
                    "Failed to export morpheus heatmap to",
                    location, "with error -", e
                )
            )
        }
    )
}

load_metadata <- function(location){
    metadata <- utils::read.table(
        location,
        sep=get_file_type(location),
        header=TRUE,
        stringsAsFactors=FALSE,
        row.names=1,
        quote="",
        colClasses="character"                                                          # to prevent loading numbers as numerical types
    ) %>% dplyr::mutate_at(base::colnames(.), forcats::fct_inorder)                     # assigns levels bases on the first appearance in the metadata
    base::rownames(metadata) <- adjust_names(base::rownames(metadata))                  # to make it correspond to the aliases

    for (i in 1:length(base::colnames(metadata))){
        base::print(
            base::paste0(
                "Column: ", colnames(metadata)[i],
                ", - with levels: ", paste(levels(metadata[[i]]), collapse=", ")
            )
        )
    }
    return (metadata)
}

load_expression_data <- function(locations, aliases, groupby=NULL, rpkm_threshold=0, read_colname=READ_COL, rpkm_colname=RPKM_COL, intersect_by=INTERSECT_BY){
    collected_expression_data <- NULL
    for (i in 1:length(locations)){
        current_location <- locations[i]
        alias <- aliases[i]
        expression_data <- data.table::setDT(
            utils::read.table(
                current_location,
                sep=get_file_type(current_location),
                header=TRUE,
                stringsAsFactors=FALSE,
                quote=""
            )
        )
        base::print(
            base::paste(
                "Loaded", base::nrow(expression_data),
                "isoforms from", current_location, "as",
                alias
            )
        )

        if (!is.null(groupby) && groupby == "gene"){
            expression_data <- base::as.data.frame(
                expression_data[
                    ,
                    .(
                        RefseqId=base::paste(base::sort(base::unique(RefseqId)), collapse=","),
                        Chrom=Chrom[1],
                        TxStart=TxStart[1],
                        TxEnd=TxEnd[1],
                        Strand=Strand[1],
                        TotalReads=sum(TotalReads),
                        Rpkm=sum(Rpkm)
                    ),
                    by=GeneId
                ]
            ) %>% dplyr::mutate(Feature=base::make.unique(as.character(GeneId), sep="_"))
            base::print(
                base::paste(
                    "Aggregated to", base::nrow(expression_data), "genes."
                )
            )
        } else if (!is.null(groupby) && groupby == "tss"){
            expression_data_up <- base::as.data.frame(
                expression_data[
                    Strand=="+",
                    .(
                        RefseqId=base::paste(base::sort(base::unique(RefseqId)), collapse=","),
                        GeneId=base::paste(base::sort(base::unique(GeneId)), collapse=","),
                        TxEnd=max(TxEnd),
                        TotalReads=sum(TotalReads),
                        Rpkm=sum(Rpkm)
                    ),
                    by=.(Chrom, TxStart, Strand)
                ]
            ) %>% dplyr::mutate(Feature=base::paste(Chrom, TxStart, "pos", sep="_"))

            expression_data_down <- base::as.data.frame(
                expression_data[
                    Strand=="-",
                    .(
                        RefseqId=base::paste(base::sort(base::unique(RefseqId)), collapse=","),
                        GeneId=base::paste(base::sort(base::unique(GeneId)), collapse=","),
                        TxStart=min(TxStart),
                        TotalReads=sum(TotalReads),
                        Rpkm=sum(Rpkm)
                    ),
                    by=.(Chrom, TxEnd, Strand)
                ]
            ) %>% dplyr::mutate(Feature=base::paste(Chrom, TxEnd, "neg", sep="_"))

            expression_data <- base::rbind(
                expression_data_up,
                expression_data_down
            )

            base::print(
                base::paste(
                    "Aggregated to", base::nrow(expression_data),
                    "records with common TSS."
                )
            )
        } else {
            expression_data <- expression_data %>%
                               dplyr::mutate(Feature=base::make.unique(as.character(RefseqId), sep="_"))                   # shouldn't happen but just in case
        }

        base::colnames(expression_data)[base::colnames(expression_data) == read_colname] <- base::paste(alias, read_colname)
        base::colnames(expression_data)[base::colnames(expression_data) == rpkm_colname] <- base::paste(alias, rpkm_colname)

        if (is.null(collected_expression_data)) {
            collected_expression_data <- expression_data
        } else {
            collected_expression_data <- base::merge(
                collected_expression_data,
                expression_data,
                by=intersect_by,
                sort=FALSE
            )
        }
    }

    collected_expression_data <- collected_expression_data %>%
                                 tibble::remove_rownames() %>%
                                 tibble::column_to_rownames("Feature")
    base::print(
        base::paste(
            "Total", base::nrow(collected_expression_data), "features loaded"
        )
    )

    if (rpkm_threshold > 0){
        selected_columns <- base::grep(
            base::paste0(rpkm_colname, "$"),
            base::colnames(collected_expression_data),
            value=TRUE
        )
        collected_expression_data <- collected_expression_data[
            base::apply(
                collected_expression_data[, selected_columns, drop=FALSE],
                1,                                                               # applying function per row
                function(x) any(x >= rpkm_threshold)),
            , drop=FALSE
        ]
        base::print(
            base::paste(
                "Total", base::nrow(collected_expression_data),
                "features remained after applying minimum RPKM",
                "threshold of", rpkm_threshold
            )
        )
    }

    return(collected_expression_data)
}

get_counts_data <- function(expression_data, metadata, read_colname=READ_COL){
    counts_data <- expression_data[
        ,
        base::grep(
            read_colname,
            base::colnames(expression_data),
            value=TRUE,
            ignore.case=TRUE
        )
    ]
    base::colnames(counts_data) <- base::lapply(
        base::colnames(counts_data),
        function(s){
            base::paste(
                utils::head(base::unlist(base::strsplit(s, " ", fixed=TRUE)), -1),
                collapse=" "
            )
        }
    )
    counts_data <- counts_data[, base::rownames(metadata)]               # we already checked that all aliases and samples names from the metadata correspond to each other.
    return (counts_data)
}