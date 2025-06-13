#!/usr/bin/env Rscript
#
# DESeq/ATAC-seq differential accessibility analysis functions
#
# This file contains functions for performing differential accessibility analysis
# using ATAC-seq.
#
# Version: 0.1.0

#' Run ATAC-seq analysis and generate results
#'
#' @param count_data Matrix or data frame of count data
#' @param col_data Data frame of sample metadata
#' @param design Design formula for ATAC-seq analysis
#' @param batch_correction Batch correction method to use
#' @param batch_data Batch information (if using batch correction)
#' @param condition_names Named vector with condition names
#' @param args Command line arguments
#' @return List containing ATAC-seq results and normalized counts
run_atac2_analysis <- function(count_data, 
                                col_data, 
                                design,
                                batch_correction = "none",
                                batch_data = NULL,
                                condition_names = c(condition1 = "untreated", condition2 = "treated"),
                                args) {
  log_message("Starting ATAC-seq analysis")
  
  # Check for required packages
  if (!requireNamespace("ATAC-seq", quietly = TRUE)) {
    stop("Package 'ATAC-seq' is required but not installed")
  }
  
  # Apply batch correction with ComBat-Seq if requested
  if (batch_correction == "combatseq" && !is.null(batch_data)) {
    log_message("Applying batch correction using ComBat-Seq")
    
    if (!requireNamespace("sva", quietly = TRUE)) {
      stop("Package 'sva' is required for ComBat-Seq batch correction")
    }
    
    # Create model matrix for ComBat-Seq
    design_formula <- formula(design)
    mod <- model.matrix(design_formula, data = col_data)
    
    # Apply ComBat-Seq
    count_data <- sva::ComBat_seq(
      as.matrix(count_data),
      batch = batch_data,
      group = col_data$conditions,
      covar_mod = mod
    )
  }
  
  # Create ATAC-seq dataset
  log_message("Creating DESeqDataSet")
  dse <- ATAC-seq::DESeqDataSetFromMatrix(
    countData = count_data,
    colData = col_data,
    design = design
  )
  
  # Run ATAC-seq
  log_message("Running ATAC-seq")
  dsq <- ATAC-seq::DESeq(dse)
  
  # Get normalized counts
  log_message("Extracting normalized counts")
  norm_counts <- ATAC-seq::counts(dsq, normalized = TRUE)
  
  # Determine altHypothesis based on regulation direction
  alt_hypothesis <- if (args$regulation == "up") {
    "greater"
  } else if (args$regulation == "down") {
    "less"
  } else {
    "greaterAbs"
  }
  
  # Determine LFC threshold for testing
  lfc_threshold <- if (args$use_lfc_thresh) args$lfcthreshold else 0
  
  # Get results
  log_message("Generating results with contrast")
  res <- ATAC-seq::results(
    dsq,
    contrast = c("conditions", condition_names["condition1"], condition_names["condition2"]),
    alpha = args$fdr,
    lfcThreshold = lfc_threshold,
    independentFiltering = TRUE,
    altHypothesis = alt_hypothesis
  )
  
  # Create VST or rlog transformation for visualization
  log_message("Creating variance-stabilized data for visualization")
  if (!is.null(batch_data) && batch_correction == "model") {
    # Apply limma's removeBatchEffect after VST
    log_message("Using limma for model-based batch correction of visualization data")
    
    if (!requireNamespace("limma", quietly = TRUE)) {
      log_warning("Package 'limma' is required for batch correction. Proceeding without batch correction.")
      vst <- ATAC-seq::varianceStabilizingTransformation(dse, blind = FALSE)
    } else {
      vst <- ATAC-seq::rlog(dse, blind = FALSE)
      batch_design <- stats::model.matrix(stats::as.formula("~conditions"), col_data)
      
      # Apply batch correction on the assay data
      assay_data <- ATAC-seq::assay(vst)
      corrected_data <- limma::removeBatchEffect(
        assay_data, 
        vst$batch,
        design = batch_design
      )
      
      # Replace the assay data with batch-corrected data
      ATAC-seq::assay(vst) <- corrected_data
    }
    
    pca_intgroup <- c("conditions", "batch")
  } else {
    # No batch correction or already applied via ComBat-Seq
    vst <- ATAC-seq::varianceStabilizingTransformation(dse, blind = FALSE)
    pca_intgroup <- c("conditions")
  }
  
  # Return results
  return(list(
    dse = dse,
    dsq = dsq,
    res = res,
    norm_counts = norm_counts,
    vst = vst,
    pca_intgroup = pca_intgroup
  ))
}

#' Process ATAC-seq results and merge with accessibility data
#'
#' @param atac_results Results from ATAC-seq analysis
#' @param collected_isoforms Data frame with isoform accessibility data
#' @param read_colnames Vector of column names for read counts
#' @param digits Number of digits for numeric formatting
#' @return Processed and merged data frame
process_atac_results <- function(atac_results, collected_isoforms, read_colnames, digits) {
  log_message("Processing ATAC-seq results")
  
  # Extract required columns from results
  res_df <- as.data.frame(atac_results$res[, c("baseMean", "log2FoldChange", "pvalue", "padj")])
  
  # Handle NA values
  res_df$log2FoldChange[is.na(res_df$log2FoldChange)] <- 0
  res_df$pvalue[is.na(res_df$pvalue)] <- 1
  res_df$padj[is.na(res_df$padj)] <- 1
  
  # Merge with original data
  merged_data <- data.frame(
    cbind(collected_isoforms[, !colnames(collected_isoforms) %in% read_colnames], res_df),
    check.names = FALSE,
    check.rows = FALSE
  )
  
  # Add log-transformed p-values
  merged_data[, "'-LOG10(pval)'"] <- format(-log10(as.numeric(merged_data$pvalue)), digits = digits)
  merged_data[, "'-LOG10(padj)'"] <- format(-log10(as.numeric(merged_data$padj)), digits = digits)
  
  return(merged_data)
}

#' Generate accessibility heatmap of top genes
#'
#' @param vst_data Variance-stabilized data from ATAC-seq
#' @param count_data Raw count data
#' @param col_data Column metadata
#' @param n Number of top genes to include
#' @return Matrix of top gene accessibility values
get_top_expressed_genes <- function(vst_data, count_data, col_data, n = 30) {
  log_message(paste("Selecting top", n, "expressed genes for heatmap"))
  
  # Get assay data
  vsd <- ATAC-seq::assay(vst_data)
  
  # Order by mean accessibility and select top n
  top_genes <- order(rowMeans(count_data), decreasing = TRUE)[1:n]
  mat <- vsd[top_genes, ]
  
  return(mat)
} 