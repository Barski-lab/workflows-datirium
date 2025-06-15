#!/usr/bin/env Rscript
#
# Command-line argument handling for ATAC-seq Pairwise Analysis
#

# Try to source helper functions with robust path resolution
if (exists("source_cli_helpers")) {
  source_cli_helpers()
} else {
  # Fallback to basic sourcing
  tryCatch({
    possible_paths <- c(
      file.path(dirname(getwd()), "common", "cli_helpers.R"),
      "../common/cli_helpers.R",
      "/usr/local/bin/functions/common/cli_helpers.R"
    )
    sourced <- FALSE
    for (path in possible_paths) {
      if (file.exists(path)) {
        source(path)
        sourced <- TRUE
        break
      }
    }
    if (!sourced) {
      message("CLI helpers not available, using manual parsing")
    }
  }, error = function(e) {
    message("CLI helpers not available, using manual parsing")
  })
}

#' Define and parse command line arguments for ATAC-seq pairwise analysis
#'
#' @return Parsed arguments list
#' @export
get_args <- function() {
  parser <- ArgumentParser(description = "ATAC-seq pairwise differential accessibility analysis")
  
  # Input files
  parser$add_argument(
    "--input_files",
    help = "Peak files for all samples (space-separated)",
    nargs = "+",
    required = TRUE,
    type = "character"
  )
  parser$add_argument(
    "--bamfiles",
    help = "BAM files for all samples (space-separated)",
    nargs = "+",
    required = TRUE,
    type = "character"
  )
  parser$add_argument(
    "--name",
    help = "Sample names (space-separated)",
    nargs = "+",
    required = TRUE,
    type = "character"
  )
  parser$add_argument(
    "--meta",
    help = "Metadata file with sample information",
    required = TRUE,
    type = "character"
  )
  
  # Group definitions for pairwise comparison
  parser$add_argument(
    "--condition_column",
    help = "Column name in metadata that defines the groups to compare",
    type = "character",
    default = "condition"
  )
  parser$add_argument(
    "--condition1",
    help = "First condition/group name for comparison (numerator)",
    required = TRUE,
    type = "character"
  )
  parser$add_argument(
    "--condition2", 
    help = "Second condition/group name for comparison (denominator/reference)",
    required = True,
    type = "character"
  )
  
  # DiffBind parameters
  parser$add_argument(
    "--peakformat",
    help = "Peak file format",
    type = "character",
    choices = c("bed", "narrow", "macs"),
    default = "narrow"
  )
  parser$add_argument(
    "--peakcaller",
    help = "Peak caller used",
    type = "character",
    choices = c("macs", "bed", "narrow"),
    default = "macs"
  )
  parser$add_argument(
    "--scorecol",
    help = "Column to use for peak scores",
    type = "integer",
    default = 5
  )
  parser$add_argument(
    "--minoverlap",
    help = "Minimum overlap for consensus peaks",
    type = "integer",
    default = 2
  )
  
  # Analysis parameters
  parser$add_argument(
    "--fdr",
    help = "FDR cutoff for significance filtering. Default: 0.1",
    type = "double",
    default = 0.1
  )
  parser$add_argument(
    "--lfcthreshold",
    help = "Log2 fold change threshold for significance. Default: 0.59 (1.5 fold)",
    type = "double",
    default = 0.59
  )
  parser$add_argument(
    "--use_lfc_thresh",
    help = "Use lfcthreshold as null hypothesis in results function",
    action = "store_true",
    default = FALSE
  )
  parser$add_argument(
    "--regulation",
    help = "Direction of differential accessibility: 'both', 'up', or 'down'",
    type = "character",
    choices = c("both", "up", "down"),
    default = "both"
  )
  
  # Batch correction
  parser$add_argument(
    "--batchcorrection",
    help = "Batch correction method: 'none', 'combatseq', 'limmaremovebatcheffect'",
    type = "character",
    choices = c("none", "combatseq", "limmaremovebatcheffect"),
    default = "none"
  )
  
  # Clustering options
  parser$add_argument(
    "--cluster",
    help = "Hopach clustering method to be run on normalized accessibility counts",
    type = "character",
    choices = c("row", "column", "both", "none"),
    default = "none"
  )
  parser$add_argument(
    "--scaling_type",
    help = "Type of scaling for accessibility data: 'minmax' or 'zscore'",
    type = "character",
    choices = c("minmax", "zscore"),
    default = "zscore"
  )
  parser$add_argument(
    "--rowdist",
    help = "Distance metric for HOPACH row clustering",
    type = "character",
    choices = c("cosangle", "abscosangle", "euclid", "cor", "abscor"),
    default = "cosangle"
  )
  parser$add_argument(
    "--columndist",
    help = "Distance metric for HOPACH column clustering",
    type = "character",
    choices = c("cosangle", "abscosangle", "euclid", "cor", "abscor"),
    default = "euclid"
  )
  parser$add_argument(
    "--k",
    help = "Number of levels for Hopach clustering (1-15). Default: 3.",
    type = "integer",
    default = 3
  )
  parser$add_argument(
    "--kmax",
    help = "Maximum number of clusters at each level (2-9). Default: 5.",
    type = "integer",
    default = 5
  )
  
  # Output options
  parser$add_argument(
    "--output",
    help = "Output prefix. Default: atac-pairwise",
    type = "character",
    default = "atac-pairwise"
  )
  parser$add_argument(
    "--threads",
    help = "Number of threads",
    type = "integer",
    default = 1
  )
  parser$add_argument(
    "--test_mode",
    help = "Run in test mode (first 500 peaks only)",
    action = "store_true",
    default = FALSE
  )
  
  # Parse arguments with better error handling
  args <- tryCatch({
    parser$parse_args(commandArgs(trailingOnly = TRUE))
  }, error = function(e) {
    message("Warning: Argument parsing error. Attempting to handle arguments manually.")
    
    all_args <- commandArgs(trailingOnly = TRUE)
    
    # Use helper functions if available, otherwise fallback to manual parsing
    if (exists("cli_helpers") && is.environment(cli_helpers)) {
      message("Using CLI helper functions for manual parsing")
      
      # Parse using helpers
      manual_args <- list()
      
      # Required single-value arguments
      required_args <- c("meta", "condition_column", "condition1", "condition2")
      for (arg in required_args) {
        manual_args[[arg]] <- cli_helpers$parse_single_value_arg(all_args, arg)
      }
      
      # Multi-value arguments (arrays)
      array_args <- c("input_files", "bamfiles", "name")
      for (arg in array_args) {
        manual_args[[arg]] <- cli_helpers$parse_multi_value_arg(all_args, arg)
      }
      
      # Optional single-value arguments with defaults
      optional_args <- list(
        peakformat = "narrow",
        peakcaller = "macs",
        regulation = "both",
        batchcorrection = "none",
        cluster = "none",
        scaling_type = "zscore",
        rowdist = "cosangle",
        columndist = "euclid",
        output = "atac-pairwise"
      )
      
      for (arg in names(optional_args)) {
        manual_args[[arg]] <- cli_helpers$parse_single_value_arg(all_args, arg, optional_args[[arg]])
      }
      
      # Numeric arguments
      numeric_args <- list(
        scorecol = "integer", minoverlap = "integer", 
        fdr = "double", lfcthreshold = "double", 
        k = "integer", kmax = "integer", threads = "integer"
      )
      numeric_defaults <- list(
        scorecol = 5, minoverlap = 2, fdr = 0.1, lfcthreshold = 0.59, 
        k = 3, kmax = 5, threads = 1
      )
      numeric_values <- cli_helpers$parse_numeric_args(all_args, numeric_args, numeric_defaults)
      manual_args <- c(manual_args, numeric_values)
      
      # Boolean flags
      boolean_flags <- c("use_lfc_thresh", "test_mode")
      boolean_values <- cli_helpers$parse_boolean_flags(all_args, boolean_flags)
      manual_args <- c(manual_args, boolean_values)
      
    } else {
      # Fallback to original manual parsing logic
      message("CLI helpers not available, using original manual parsing")
      manual_args <- list()
      
      # Basic manual parsing for required arguments
      required_args <- c("meta", "condition1", "condition2")
      for (req_arg in required_args) {
        req_flag <- paste0("--", req_arg)
        arg_idx <- which(all_args == req_flag)
        if (length(arg_idx) > 0 && arg_idx[1] < length(all_args)) {
          manual_args[[req_arg]] <- all_args[arg_idx[1] + 1]
        }
      }
      
      # Simple flag processing for other arguments
      i <- 1
      while (i <= length(all_args)) {
        current_arg <- all_args[i]
        if (grepl("^--", current_arg)) {
          arg_name <- sub("^--", "", current_arg)
          if (i < length(all_args) && !grepl("^--", all_args[i + 1])) {
            manual_args[[arg_name]] <- all_args[i + 1]
            i <- i + 2
          } else {
            manual_args[[arg_name]] <- TRUE
            i <- i + 1
          }
        } else {
          i <- i + 1
        }
      }
    }
    
    message("Manually parsed arguments using helpers")
    return(manual_args)
  })
  
  # Validate required arguments
  required_args <- c("input_files", "bamfiles", "name", "meta", "condition1", "condition2")
  missing_args <- required_args[!required_args %in% names(args)]
  if (length(missing_args) > 0) {
    stop(paste("Missing required arguments:", paste(missing_args, collapse=", ")))
  }
  
  # Validate input file counts
  if (length(args$input_files) != length(args$bamfiles)) {
    stop("Number of peak files must match number of BAM files")
  }
  
  if (length(args$input_files) != length(args$name)) {
    stop("Number of input files must match number of sample names")
  }
  
  # Convert boolean string values if needed
  for (arg_name in c("use_lfc_thresh", "test_mode")) {
    if (!is.null(args[[arg_name]])) {
      if (is.character(args[[arg_name]])) {
        args[[arg_name]] <- toupper(args[[arg_name]]) %in% c("TRUE", "T", "YES", "Y", "1")
      }
    }
  }
  
  # Convert numeric values
  for (arg_name in c("scorecol", "minoverlap", "fdr", "lfcthreshold", "k", "kmax", "threads")) {
    if (!is.null(args[[arg_name]]) && is.character(args[[arg_name]])) {
      if (grepl("^[0-9.]+$", args[[arg_name]])) {
        args[[arg_name]] <- as.numeric(args[[arg_name]])
      }
    }
  }
  
  return(args)
}

#' Validate command line arguments for ATAC-seq pairwise analysis
#'
#' @param args Parsed arguments
#' @return Validated args
#' @export
validate_args <- function(args) {
  log_message("Validating ATAC-seq pairwise arguments")
  
  # Check file existence
  for (file in args$input_files) {
    if (!file.exists(file)) {
      stop(paste("Peak file not found:", file))
    }
  }
  
  for (file in args$bamfiles) {
    if (!file.exists(file)) {
      stop(paste("BAM file not found:", file))
    }
  }
  
  if (!file.exists(args$meta)) {
    stop(paste("Metadata file not found:", args$meta))
  }
  
  # Validate numeric parameters
  if (args$fdr <= 0 || args$fdr >= 1) {
    stop("FDR must be between 0 and 1")
  }
  
  if (args$lfcthreshold < 0) {
    stop("Log fold change threshold must be non-negative")
  }
  
  if (args$minoverlap < 1) {
    stop("Minimum overlap must be at least 1")
  }
  
  log_message("ATAC-seq pairwise arguments validated successfully")
  return(args)
}

#' Print command line arguments for debugging
#'
#' @param args Parsed arguments
#' @export
print_args <- function(args) {
  log_message("ATAC-seq Pairwise Analysis Arguments:")
  log_message(paste("  Input files:", length(args$input_files), "peak files"))
  log_message(paste("  BAM files:", length(args$bamfiles), "files"))
  log_message(paste("  Sample names:", paste(args$name, collapse=", ")))
  log_message(paste("  Metadata file:", args$meta))
  log_message(paste("  Condition column:", args$condition_column))
  log_message(paste("  Condition 1 (treatment):", args$condition1))
  log_message(paste("  Condition 2 (reference):", args$condition2))
  log_message(paste("  Peak format:", args$peakformat))
  log_message(paste("  Peak caller:", args$peakcaller))
  log_message(paste("  Score column:", args$scorecol))
  log_message(paste("  Minimum overlap:", args$minoverlap))
  log_message(paste("  FDR threshold:", args$fdr))
  log_message(paste("  LFC threshold:", args$lfcthreshold))
  log_message(paste("  Regulation:", args$regulation))
  log_message(paste("  Batch correction:", args$batchcorrection))
  log_message(paste("  Clustering:", args$cluster))
  log_message(paste("  Output prefix:", args$output))
  log_message(paste("  Test mode:", args$test_mode))
}