#!/usr/bin/env Rscript
#
# Command-line argument handling for DESeq/DESeq2 differential expression analysis
#
# This file contains functions for parsing and validating command-line arguments
# for the main DESeq analysis workflow.
#
# Version: 0.1.0

# Try to source helper functions (optional, with fallback)
tryCatch({
  source_path <- file.path(dirname(getwd()), "common", "cli_helpers.R")
  if (file.exists(source_path)) {
    source(source_path)
  } else {
    # Try Docker path
    docker_path <- "/usr/local/bin/functions/common/cli_helpers.R"
    if (file.exists(docker_path)) {
      source(docker_path)
    }
  }
}, error = function(e) {
  # Helpers not available, continue with manual parsing
  message("CLI helpers not available, using manual parsing")
})

#' Assert and validate command line arguments
#'
#' @param args The parsed arguments from ArgumentParser
#' @return Modified args with validated and processed values
assert_args <- function(args) {
  log_message("Checking input parameters")
  
  # Process aliases if not provided
  if (is.null(args$untreated_sample_names) | is.null(args$treated_sample_names)) {
    log_message("--untreated_sample_names or --treated_sample_names were not set, using default values based on expression file names")
    
    args$untreated_sample_names <- character(0)
    for (i in 1:length(args$untreated_files)) {
      args$untreated_sample_names <- append(args$untreated_sample_names, head(unlist(
        strsplit(basename(args$untreated_files[i]), ".", fixed = TRUE)
      ), 1))
    }
    
    args$treated_sample_names <- character(0)
    for (i in 1:length(args$treated_files)) {
      args$treated_sample_names <- append(args$treated_sample_names, head(unlist(
        strsplit(basename(args$treated_files[i]), ".", fixed = TRUE)
      ), 1))
    }
  } else {
    # Verify correct number of aliases
    if ((length(args$untreated_sample_names) != length(args$untreated_files)) |
        (length(args$treated_sample_names) != length(args$treated_files))) {
      log_error("Not correct number of inputs provided for files and sample names")
      quit(save = "no", status = 1, runLast = FALSE)
    }
  }

  # Check for minimum file requirements
  if (length(args$treated_files) == 1 || length(args$untreated_files) == 1) {
    log_warning("Only one file in a group. DESeq2 requires at least two replicates for accurate analysis.")
    args$batch_file <- NULL # reset batch_file to NULL. We don't need it for DESeq even if it was provided
  }

  # Process batch file if provided
  if (!is.null(args$batch_file)) {
    batch_metadata <- with_error_handling({
      read.table(
        args$batch_file,
        sep = get_file_type(args$batch_file),
        row.names = 1,
        col.names = c("name", "batch"),
        header = FALSE,
        stringsAsFactors = FALSE
      )
    })
    
    if (is.null(batch_metadata)) {
      log_error("Failed to read batch metadata file")
      args$batch_file <- NULL
      return(args)
    }
    
    log_message("Loaded batch metadata")
    rownames(batch_metadata) <- gsub("'|\"| ", "_", rownames(batch_metadata))
    
    if (all(is.element(c(args$untreated_sample_names, args$treated_sample_names), rownames(batch_metadata)))) {
      args$batch_file <- batch_metadata # dataframe
    } else {
      log_warning("Missing values in batch metadata file. Skipping multi-factor analysis")
      log_debug(paste("Expected:", paste(c(args$untreated_sample_names, args$treated_sample_names), collapse=", ")))
      log_debug(paste("Found:", paste(rownames(batch_metadata), collapse=", ")))
      args$batch_file <- NULL
    }
  }

  # Convert boolean string values if they came as strings
  for (arg_name in c("use_lfc_thresh", "test_mode")) {
    if (!is.null(args[[arg_name]])) {
      args[[arg_name]] <- convert_to_boolean(args[[arg_name]], FALSE)
    }
  }

  # Map argument names for compatibility with workflow
  args$treated <- args$treated_files
  args$untreated <- args$untreated_files
  args$talias <- args$treated_sample_names  
  args$ualias <- args$untreated_sample_names
  args$tname <- args$treated_name
  args$uname <- args$untreated_name
  args$output <- args$output_prefix
  args$batchfile <- args$batch_file

  return(args)
}

#' Parse command line arguments for DESeq analysis
#'
#' @return Parsed and validated argument list
get_args <- function() {
  parser <- ArgumentParser(description = "Run DESeq/DESeq2 for untreated-vs-treated groups (condition-1-vs-condition-2)")
  
  # Input file parameters
  parser$add_argument(
    "-u", "--untreated_files",
    help = "Untreated (condition 1) CSV/TSV isoforms expression files",
    type = "character",
    required = TRUE,
    nargs = "+"
  )
  parser$add_argument(
    "-t", "--treated_files",
    help = "Treated (condition 2) CSV/TSV isoforms expression files",
    type = "character",
    required = TRUE,
    nargs = "+"
  )
  parser$add_argument(
    "-ua", "--untreated_sample_names",
    help = "Unique aliases for untreated (condition 1) expression files. Default: basenames of -u without extensions",
    type = "character",
    nargs = "*"
  )
  parser$add_argument(
    "-ta", "--treated_sample_names",
    help = "Unique aliases for treated (condition 2) expression files. Default: basenames of -t without extensions",
    type = "character",
    nargs = "*"
  )
  
  # Condition naming parameters
  parser$add_argument(
    "-un", "--untreated_name",
    help = "Name for untreated (condition 1), use only letters and numbers",
    type = "character",
    default = "untreated"
  )
  parser$add_argument(
    "-tn", "--treated_name",
    help = "Name for treated (condition 2), use only letters and numbers",
    type = "character",
    default = "treated"
  )
  
  # Batch correction parameters
  parser$add_argument(
    "-bf", "--batch_file",
    help = paste(
      "Metadata file for multi-factor analysis. Headerless TSV/CSV file.",
      "First column - names from --untreated_sample_names and --treated_sample_names, second column - batch group name.",
      "Default: None"
    ),
    type = "character"
  )
  parser$add_argument(
    "--batchcorrection",
    help = paste(
      "Specifies the batch correction method to be applied.",
      "- 'combatseq' applies ComBat_seq at the beginning of the analysis, removing batch effects from the design formula before differential expression analysis.",
      "- 'model' applies removeBatchEffect from the limma package after differential expression analysis, incorporating batch effects into the model during DE analysis.",
      "- Default: none"
    ),
    type = "character",
    choices = c("none", "combatseq", "model"),
    default = "none"
  )
  
  # Statistical and filtering parameters
  parser$add_argument(
    "--fdr",
    help = paste(
      "In the exploratory visualization part of the analysis output only features",
      "with adjusted p-value (FDR) not bigger than this value. Also the significance",
      "cutoff used for optimizing the independent filtering. Default: 0.1."
    ),
    type = "double",
    default = 0.1
  )
  parser$add_argument(
    "--rpkm_cutoff",
    help = paste(
      "RPKM cutoff for filtering genes. Genes with RPKM values below this threshold will be excluded from the analysis.",
      "Default: NULL (no filtering)"
    ),
    type = "integer",
    default = NULL
  )
  parser$add_argument(
    "--regulation",
    help = paste(
      "Direction of differential expression comparison. β is the log2 fold change.",
      "'both' for both up and downregulated genes (|β| > lfcThreshold for greaterAbs and |β| < lfcThreshold for lessAbs, with p-values being two-tailed or maximum of the upper and lower tests, respectively); ",
      "'up' for upregulated genes (β > lfcThreshold in condition2 compared to condition1); ",
      "'down' for downregulated genes (β < -lfcThreshold in condition2 compared to condition1). ",
      "Default: both"
    ),
    type = "character",
    choices = c("both", "up", "down"),
    default = "both"
  )
  parser$add_argument(
    "--lfcthreshold",
    help = paste(
      "Log2 fold change threshold for determining significant differential expression.",
      "Genes with absolute log2 fold change greater than this threshold will be considered.",
      "Default: 0.59 (about 1.5 fold change)"
    ),
    type = "double",
    default = 0.59
  )
  parser$add_argument(
    "--use_lfc_thresh",
    help = paste(
      "Flag to indicate whether to use lfcthreshold as the null hypothesis value in the results function call.",
      "If TRUE, lfcthreshold is used in the hypothesis test (i.e., genes are tested against this threshold).",
      "If FALSE, the null hypothesis is set to 0, and lfcthreshold is used only as a downstream filter.",
      "Default: FALSE"
    ),
    action = "store_true",
    default = FALSE
  )
  
  # Clustering parameters
  parser$add_argument(
    "--cluster_method",
    help = paste(
      "Hopach clustering method to be run on normalized read counts for the",
      "exploratory visualization part of the analysis. Default: none"
    ),
    type = "character",
    choices = c("row", "column", "both", "none"),
    default = "none"
  )
  parser$add_argument(
    "--scaling_type",
    help = paste(
      "Specifies the type of scaling to be applied to the expression data.",
      "- 'minmax' applies Min-Max scaling, normalizing values to a range of [-2, 2].",
      "- 'zscore' applies Z-score standardization, centering data to mean = 0 and standard deviation = 1.",
      "- Default: zscore"
    ),
    type = "character",
    choices = c("minmax", "zscore"),
    default = "zscore"
  )
  parser$add_argument(
    "--row_distance",
    help = paste(
      "Distance metric for HOPACH row clustering. Ignored if --cluster_method is not",
      "provided. Default: cosangle"
    ),
    type = "character",
    default = "cosangle",
    choices = c("cosangle", "abscosangle", "euclid", "cor", "abscor")
  )
  parser$add_argument(
    "--column_distance",
    help = paste(
      "Distance metric for HOPACH column clustering. Ignored if --cluster_method is not",
      "provided. Default: euclid"
    ),
    type = "character",
    default = "euclid",
    choices = c("cosangle", "abscosangle", "euclid", "cor", "abscor")
  )
  parser$add_argument(
    "--k_hopach",
    help = "Number of levels (depth) for Hopach clustering: min - 1, max - 15. Default: 3.",
    type = "integer",
    default = 3
  )
  parser$add_argument(
    "--kmax_hopach",
    help = "Maximum number of clusters at each level for Hopach clustering: min - 2, max - 9. Default: 5.",
    type = "integer",
    default = 5
  )
  
  # Testing parameters
  parser$add_argument(
    "--test_mode",
    help = "Enable test mode for faster processing with reduced data. Default: FALSE",
    action = "store_true",
    default = FALSE
  )
  
  # Output parameters
  parser$add_argument(
    "-o", "--output_prefix",
    help = "Output prefix. Default: deseq",
    type = "character",
    default = "./deseq"
  )
  parser$add_argument(
    "-d", "--digits",
    help = "Precision, number of digits to print. Default: 3",
    type = "integer",
    default = 3
  )
  parser$add_argument(
    "-p", "--threads",
    help = "Number of threads to use for parallel processing. Default: 1",
    type = "integer",
    default = 1
  )
  
  # Parse arguments with better error handling
  tryCatch({
    args <- parser$parse_args()
  }, error = function(e) {
    message("Warning: Argument parsing error. Attempting to handle arguments manually.")
    
    all_args <- commandArgs(trailingOnly = TRUE)
    
    # Use helper functions if available, otherwise fallback to manual parsing
    if (exists("cli_helpers") && is.environment(cli_helpers)) {
      message("Using CLI helper functions for manual parsing")
      
      # Parse using helpers
      args <- list()
      
      # Multi-value arguments  
      args$untreated_files <- cli_helpers$parse_multi_value_args(all_args, "untreated_files")
      args$treated_files <- cli_helpers$parse_multi_value_args(all_args, "treated_files")
      args$untreated_sample_names <- cli_helpers$parse_multi_value_args(all_args, "untreated_sample_names")
      args$treated_sample_names <- cli_helpers$parse_multi_value_args(all_args, "treated_sample_names")
      
      # Try short flags too
      if (length(args$untreated_files) == 0) {
        args$untreated_files <- cli_helpers$parse_multi_value_args(all_args, "u")
      }
      if (length(args$treated_files) == 0) {
        args$treated_files <- cli_helpers$parse_multi_value_args(all_args, "t")
      }
      
      # Optional single-value arguments with defaults
      optional_args <- list(
        untreated_name = "untreated",
        treated_name = "treated",
        batchcorrection = "none",
        regulation = "both", 
        cluster_method = "none",
        scaling_type = "zscore",
        row_distance = "cosangle",
        column_distance = "euclid",
        output_prefix = "./deseq"
      )
      
      for (arg in names(optional_args)) {
        args[[arg]] <- cli_helpers$parse_single_value_arg(all_args, arg, optional_args[[arg]])
      }
      
      # Try short flags for some args
      if (is.null(args$batch_file)) {
        args$batch_file <- cli_helpers$parse_single_value_arg(all_args, "bf")
      }
      if (args$output_prefix == "./deseq") {
        args$output_prefix <- cli_helpers$parse_single_value_arg(all_args, "o", "./deseq") 
      }
      
      # Numeric arguments
      numeric_args <- list(fdr = "double", lfcthreshold = "double", k_hopach = "integer", kmax_hopach = "integer", threads = "integer", digits = "integer", rpkm_cutoff = "integer")
      numeric_defaults <- list(fdr = 0.1, lfcthreshold = 0.59, k_hopach = 3, kmax_hopach = 5, threads = 1, digits = 3, rpkm_cutoff = NULL)
      numeric_values <- cli_helpers$parse_numeric_args(all_args, numeric_args, numeric_defaults)
      args <- c(args, numeric_values)
      
      # Try short flag for threads
      if (args$threads == 1) {
        threads_val <- cli_helpers$parse_single_value_arg(all_args, "p", "1")
        args$threads <- as.integer(threads_val)
      }
      
      # Boolean flags
      boolean_flags <- c("use_lfc_thresh", "test_mode")
      boolean_values <- cli_helpers$parse_boolean_flags(all_args, boolean_flags)
      args <- c(args, boolean_values)
      
    } else {
      # Fallback to minimal manual parsing for required args only
      message("CLI helpers not available, using minimal manual parsing")
      args <- list(
        untreated_files = character(0),
        treated_files = character(0)
      )
      
      # Simple extraction for required arguments
      for (flag in c("-u", "--untreated_files")) {
        idx <- which(all_args == flag)
        if (length(idx) > 0 && idx[1] < length(all_args)) {
          args$untreated_files <- c(args$untreated_files, all_args[idx[1] + 1])
        }
      }
      
      for (flag in c("-t", "--treated_files")) {
        idx <- which(all_args == flag)
        if (length(idx) > 0 && idx[1] < length(all_args)) {
          args$treated_files <- c(args$treated_files, all_args[idx[1] + 1])
        }
      }
    }
    
    message("Manually parsed arguments using helpers")
  })
  
  # Validate arguments and set defaults
  args <- assert_args(args)
  
  # Convert numeric values
  for (arg_name in c("fdr", "lfcthreshold", "threads")) {
    if (!is.null(args[[arg_name]]) && is.character(args[[arg_name]])) {
      if (grepl("^[0-9.]+$", args[[arg_name]])) {
        args[[arg_name]] <- as.numeric(args[[arg_name]])
      }
    }
  }
  
  return(args)
} 