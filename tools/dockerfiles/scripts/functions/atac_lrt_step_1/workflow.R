#!/usr/bin/env Rscript

# --- Main workflow functions for ATAC-seq LRT Step 1 ---

#' Initialize the environment for ATAC-seq LRT Step 1 analysis
#'
#' Loads required libraries, sources dependency files, and configures environment
initialize_environment <- function() {
  # Display startup message
  message("Starting ATAC-seq LRT Step 1 Analysis")
  message("Working directory:", getwd())
  
  # Print command line arguments for debugging purposes
  args <- commandArgs(trailingOnly = TRUE)
  message("Command line arguments received:")
  message(paste(args, collapse = " "))
  
  # First, make sure we have the utilities module
  if (file.exists("/usr/local/bin/functions/common/utilities.R")) {
    message("Loading utilities from Docker path: /usr/local/bin/functions/common/utilities.R")
    source("/usr/local/bin/functions/common/utilities.R")
  } else if (file.exists("functions/common/utilities.R")) {
    message("Loading utilities from relative path: functions/common/utilities.R")
    source("functions/common/utilities.R")
  } else {
    # Try one more location
    script_dir <- tryCatch({
      dirname(sys.frame(1)$ofile)
    }, error = function(e) {
      NULL
    })
    
    if (!is.null(script_dir)) {
      potential_path <- file.path(script_dir, "../common/utilities.R")
      if (file.exists(potential_path)) {
        message(paste("Loading utilities from script relative path:", potential_path))
        source(potential_path)
      } else {
        stop("Could not find utilities.R file")
      }
    } else {
      stop("Could not find utilities.R file")
    }
  }
  
  # Now we have access to source_with_fallback and other utilities
  # Source common functions
  source_with_fallback("functions/common/constants.R", "/usr/local/bin/functions/common/constants.R")
  source_with_fallback("functions/common/output_utils.R", "/usr/local/bin/functions/common/output_utils.R")
  source_with_fallback("functions/common/visualization.R", "/usr/local/bin/functions/common/visualization.R")
  source_with_fallback("functions/common/clustering.R", "/usr/local/bin/functions/common/clustering.R")
  source_with_fallback("functions/common/export_functions.R", "/usr/local/bin/functions/common/export_functions.R")
  source_with_fallback("functions/common/error_handling.R", "/usr/local/bin/functions/common/error_handling.R")
  source_with_fallback("functions/common/logging.R", "/usr/local/bin/functions/common/logging.R")

  # Source ATAC-seq LRT Step 1 specific functions
  source_with_fallback("functions/atac_lrt_step_1/cli_args.R", "/usr/local/bin/functions/atac_lrt_step_1/cli_args.R")
  source_with_fallback("functions/atac_lrt_step_1/data_processing.R", "/usr/local/bin/functions/atac_lrt_step_1/data_processing.R")
  source_with_fallback("functions/atac_lrt_step_1/atac_analysis.R", "/usr/local/bin/functions/atac_lrt_step_1/atac_analysis.R")
  source_with_fallback("functions/atac_lrt_step_1/contrast_generation.R", "/usr/local/bin/functions/atac_lrt_step_1/contrast_generation.R")
  
  # Load required libraries with clear error messages
  tryCatch({
    message("Loading required libraries...")
    suppressPackageStartupMessages({
      required_packages <- c(
        "DiffBind",
        "DESeq2",
        "BiocParallel",
        "data.table",
        "ggplot2",
        "plotly",
        "limma",
        "hopach",
        "stringr",
        "GenomicRanges",
        "rtracklayer",
        "Rsamtools"
      )
      
      for (pkg in required_packages) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
          stop(paste("Required package not found:", pkg))
        }
        message(paste("Loading package:", pkg))
        library(pkg, character.only = TRUE)
      }
    })
  }, error = function(e) {
    stop(paste("Error loading libraries:", e$message))
  })

  # Configure R options
  configure_r_options()
  
  # Configure plot theme
  configure_plot_theme()
  
  log_message("Environment initialized for ATAC-seq LRT Step 1 analysis")
}

# Load and validate metadata
load_and_validate_metadata <- function(args) {
  message("Loading metadata...")
  
  # Get the file delimiter
  delimiter <- check_file_delimiter(args$meta)
  
  # Load metadata
  metadata_df <- read.table(
    args$meta,
    sep = delimiter,
    header = TRUE,
    stringsAsFactors = FALSE,
    row.names = 1
  )
  
  # Clean metadata column and row names
  colnames(metadata_df) <- clean_sample_names(colnames(metadata_df))
  rownames(metadata_df) <- clean_sample_names(rownames(metadata_df))
  
  message(glue::glue("Loaded metadata for {nrow(metadata_df)} samples with {ncol(metadata_df)} covariates"))
  
  # Check design formulas
  design_formula <- as.formula(args$design)
  
  # Apply comprehensive metadata validation using the common utility function
  metadata_df <- validate_metadata(metadata_df, args$batchcorrection, design_formula)
  
  # Add formulas to metadata for convenience
  attr(metadata_df, "design_formula") <- design_formula
  attr(metadata_df, "reduced_formula") <- as.formula(args$reduced)
  
  return(metadata_df)
}

# Load and validate ATAC-seq data (peak files and BAM files)
load_and_validate_atac_data <- function(args, metadata_df) {
  message("Loading ATAC-seq data...")
  
  # Clean sample names for consistency
  clean_names <- clean_sample_names(args$name)
  
  # Trim any trailing whitespace which can cause issues
  clean_names <- trimws(clean_names)
  
  # Check if we have the correct number of sample names
  if (length(clean_names) == 0) {
    stop("No sample names provided. Please provide sample names with --name parameter.")
  }
  
  # Validate we have the right number of files and names
  if (length(args$input_files) != length(clean_names)) {
    warning(sprintf("Mismatch between number of input files (%d) and sample names (%d).",
                    length(args$input_files), length(clean_names)))
    
    # Handle two specific cases:
    # 1. More files than names: use file basename as names
    # 2. More names than files: truncate names to match files
    
    if (length(args$input_files) > length(clean_names)) {
      message("More input files than sample names. Using file basenames for missing names.")
      
      # Generate names from file paths for the missing slots
      missing_names_count <- length(args$input_files) - length(clean_names)
      file_basenames <- basename(args$input_files[(length(clean_names)+1):length(args$input_files)])
      file_basenames <- gsub("\\.(tsv|csv)$", "", file_basenames)
      
      # Append the generated names
      clean_names <- c(clean_names, file_basenames)
      message(sprintf("Added %d names from file basenames. Now have %d names.", 
                      missing_names_count, length(clean_names)))
    } else if (length(clean_names) > length(args$input_files)) {
      message("More sample names than input files. Truncating sample names list.")
      clean_names <- clean_names[1:length(args$input_files)]
    }
  }
  
  # Validate BAM files match peak files
  if (length(args$bamfiles) != length(args$input_files)) {
    stop(sprintf("Number of BAM files (%d) must match number of peak files (%d)",
                 length(args$bamfiles), length(args$input_files)))
  }
  
  # Create DiffBind sample sheet
  message(sprintf("Creating DiffBind sample sheet for %d files with %d sample names", 
                  length(args$input_files), length(clean_names)))
  
  sample_sheet <- create_diffbind_sample_sheet(args, clean_names, metadata_df)
  
  message(glue::glue("Created DiffBind sample sheet for {nrow(sample_sheet)} samples"))
  
  return(sample_sheet)
}

# Create DiffBind sample sheet
create_diffbind_sample_sheet <- function(args, clean_names, metadata_df) {
  # Create the basic sample sheet structure required by DiffBind
  sample_sheet <- data.frame(
    SampleID = clean_names,
    Peaks = args$input_files,
    bamReads = args$bamfiles,
    stringsAsFactors = FALSE
  )
  
  # Add metadata columns to the sample sheet
  # Match sample names to metadata rownames
  for (col_name in colnames(metadata_df)) {
    sample_sheet[[col_name]] <- metadata_df[match(clean_names, rownames(metadata_df)), col_name]
  }
  
  # Remove any rows with missing metadata
  complete_rows <- complete.cases(sample_sheet)
  if (!all(complete_rows)) {
    warning(sprintf("Removing %d samples with missing metadata", sum(!complete_rows)))
    sample_sheet <- sample_sheet[complete_rows, , drop = FALSE]
  }
  
  # Check that we still have samples
  if (nrow(sample_sheet) == 0) {
    stop("No samples remain after matching with metadata")
  }
  
  return(sample_sheet)
}

# Run DiffBind analysis pipeline
run_diffbind_analysis <- function(sample_sheet, args) {
  message("Running DiffBind analysis pipeline...")
  
  # Create DBA object
  message("Creating DBA object...")
  dba_obj <- dba(
    sampleSheet = sample_sheet,
    peakFormat = args$peakformat,
    peakCaller = args$peakcaller,
    scoreCol = args$scorecol
  )
  
  # Create consensus peaks
  message("Creating consensus peaks...")
  dba_consensus <- dba.peakset(dba_obj, consensus = DBA_CONDITION, minOverlap = args$minoverlap)
  dba_consensus <- dba(dba_consensus, mask = dba_consensus$masks$Consensus, minOverlap = 1)
  
  # Get consensus peaks
  consensus_peaks <- dba.peakset(dba_consensus, bRetrieve = TRUE, minOverlap = 1)
  
  # Count reads in consensus peaks
  message("Counting reads in consensus peaks...")
  dba_obj <- dba.count(dba_obj, peaks = consensus_peaks, minOverlap = 1)
  
  # Apply test mode filtering if requested
  if (args$test_mode) {
    message("Test mode: reducing to first 500 peaks for faster processing...")
    # Get binding matrix
    binding_matrix <- dba_obj$binding
    n_peaks <- min(500, nrow(binding_matrix))
    
    # Create subset of peaks
    test_peaks <- consensus_peaks[1:n_peaks]
    
    # Recreate DBA object with subset
    dba_obj <- dba.count(dba_obj, peaks = test_peaks, minOverlap = 1)
  }
  
  return(list(dba_obj = dba_obj, consensus_peaks = consensus_peaks))
}

# Run DESeq2 LRT analysis on DiffBind results
run_deseq2_lrt_analysis <- function(dba_obj, args) {
  message("Running DiffBind differential analysis...")
  
  # First run DiffBind analysis to set up DESeq2 framework
  if (args$with_interaction) {
    dba_analyzed <- dba.analyze(
      dba_obj, 
      method = DBA_DESEQ2, 
      design = paste0("~", args$design)
    )
  } else {
    dba_analyzed <- dba.analyze(
      dba_obj, 
      method = DBA_DESEQ2, 
      design = paste0("~", gsub("\\*.*", "", args$design))  # Remove interaction term
    )
  }
  
  # Save the DBA object for potential later use
  saveRDS(dba_analyzed, file.path(args$output, paste0(args$alias, "_dba_deseq2_analyzed.rds")))
  
  # CRITICAL: Extract the DESeq2 object for custom LRT analysis
  # This is what allows us to bypass DiffBind limitations for complex interactions
  message("Extracting DESeq2 object for custom LRT analysis...")
  dds <- dba_analyzed$DESeq2$DEdata
  
  # Run custom LRT with proper reduced model
  message("Running custom LRT test with reduced model...")
  reduced_formula <- if (args$reduced == "~1") {
    as.formula("~1")
  } else {
    as.formula(args$reduced)
  }
  
  dds_lrt <- DESeq(dds, test = "LRT", reduced = reduced_formula)
  
  # Get LRT results
  lrt_results <- results(dds_lrt, alpha = args$fdr)
  
  # Extract count matrix and peak information for downstream analysis
  message("Extracting count matrix and genomic coordinates...")
  
  # Get the interaction peakset with proper genomic coordinates
  interaction_peakset <- dba.peakset(dba_analyzed, bRetrieve = TRUE)
  
  # Extract count matrix (this preserves proper chromosome ordering)
  counts_mat <- as.matrix(mcols(interaction_peakset))
  rownames(counts_mat) <- paste0(seqnames(interaction_peakset), ":", 
                                 start(interaction_peakset), "-", 
                                 end(interaction_peakset))
  colnames(counts_mat) <- dba_analyzed$samples$SampleID
  
  return(list(
    dba_analyzed = dba_analyzed,
    dds_lrt = dds_lrt,
    lrt_results = lrt_results,
    interaction_peakset = interaction_peakset,
    counts_mat = counts_mat
  ))
}

# Generate contrasts (same structure as DESeq2 version)
generate_contrasts <- function(dds_lrt, args) {
  message("Generating contrasts...")
  
  if (args$lrt_only_mode) {
    message("LRT only mode: skipping contrast generation")
    return(NULL)
  }
  
  # Use the contrast generation logic from the original workflow
  # This will be implemented in contrast_generation.R
  contrasts_list <- generate_atac_contrasts(dds_lrt, args)
  
  return(contrasts_list)
}

# Main workflow execution function
run_atac_lrt_workflow <- function() {
  # Parse and validate arguments
  args <- get_args()
  validate_args(args)
  print_args(args)
  
  # Load and validate metadata
  metadata_df <- load_and_validate_metadata(args)
  
  # Load and validate ATAC-seq data
  sample_sheet <- load_and_validate_atac_data(args, metadata_df)
  
  # Run DiffBind analysis
  diffbind_results <- run_diffbind_analysis(sample_sheet, args)
  dba_obj <- diffbind_results$dba_obj
  consensus_peaks <- diffbind_results$consensus_peaks
  
  # Apply score type for counting (matching example: DBA_SCORE_RPKM)
  if (args$score_type == "DBA_SCORE_RPKM") {
    message("Applying RPKM scoring for count normalization...")
    dba_obj <- dba.count(dba_obj, peaks = NULL, score = DBA_SCORE_RPKM)
  }
  
  # Run sophisticated DESeq2 LRT analysis with DESeq2 object extraction
  message("Running sophisticated DESeq2 analysis with object extraction...")
  deseq2_results <- run_deseq2_lrt_analysis(dba_obj, args)
  dds_lrt <- deseq2_results$dds_lrt
  lrt_results <- deseq2_results$lrt_results
  interaction_peakset <- deseq2_results$interaction_peakset
  counts_mat <- deseq2_results$counts_mat
  
  # Export significant peaks with proper genomic coordinates
  export_significant_peaks_genomic(interaction_peakset, lrt_results, args)
  
  # Apply advanced limma batch correction if requested
  limma_results <- NULL
  if (args$use_limma_correction || args$batchcorrection == "limmaremovebatcheffect") {
    limma_results <- apply_limma_batch_correction(
      counts_mat, deseq2_results$dba_analyzed, lrt_results, args
    )
  }
  
  # Generate contrasts if not in LRT-only mode
  contrasts_list <- generate_contrasts(dds_lrt, args)
  
  # Apply other batch correction methods if specified
  if (args$batchcorrection == "combatseq") {
    message("Applying ComBat-seq batch correction...")
    # Implementation would go here
  }
  
  # Generate standard outputs
  message("Generating outputs...")
  
  # Export LRT results with genomic coordinates
  export_lrt_results(lrt_results, interaction_peakset, args)
  
  # Export contrasts table if generated
  if (!is.null(contrasts_list)) {
    export_contrasts_table(contrasts_list, args)
  }
  
  # Export DESeq2 object
  export_deseq_object(dds_lrt, args)
  
  # Export normalized counts from both DiffBind and DESeq2
  export_normalized_counts(dds_lrt, args)
  
  # Export count matrix for downstream analysis
  saveRDS(counts_mat, file.path(args$output, paste0(args$alias, "_count_matrix.rds")))
  
  # Generate visualizations
  generate_visualizations(dds_lrt, lrt_results, args)
  
  # Perform clustering if requested
  if (args$cluster_method != "none") {
    perform_clustering(dds_lrt, lrt_results, args)
  }
  
  # Generate summary report
  generate_summary_report(lrt_results, limma_results, args)
  
  message("ATAC-seq LRT Step 1 analysis with sophisticated DiffBind+DESeq2 approach completed successfully!")
}

# Generate summary report
generate_summary_report <- function(lrt_results, limma_results, args) {
  message("Generating summary report...")
  
  # Calculate basic statistics
  total_peaks <- nrow(lrt_results)
  significant_peaks <- sum(!is.na(lrt_results$padj) & lrt_results$padj < args$fdr)
  
  # Create summary
  summary_stats <- list(
    total_peaks = total_peaks,
    significant_peaks = significant_peaks,
    fdr_threshold = args$fdr,
    design_formula = args$design,
    reduced_formula = args$reduced,
    with_interaction = args$with_interaction,
    batch_correction = args$batchcorrection,
    limma_correction_applied = !is.null(limma_results)
  )
  
  # Save summary
  saveRDS(summary_stats, file.path(args$output, paste0(args$alias, "_analysis_summary.rds")))
  
  # Print summary
  cat("=== ATAC-seq LRT Analysis Summary ===\n")
  cat("Total peaks analyzed:", total_peaks, "\n")
  cat("Significant peaks (FDR <", args$fdr, "):", significant_peaks, "\n")
  cat("Percentage significant:", round(100 * significant_peaks / total_peaks, 2), "%\n")
  cat("Design formula:", args$design, "\n")
  cat("Interaction design:", args$with_interaction, "\n")
  cat("Batch correction:", args$batchcorrection, "\n")
  if (!is.null(limma_results)) {
    cat("Limma correction applied to", length(limma_results$significant_peaks), "significant peaks\n")
  }
  cat("======================================\n")
} 