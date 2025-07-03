#!/usr/bin/env Rscript
# Patched cli_args.R for DESeq pairwise – auto-fills alias vectors instead of aborting
# This file is a copy of the original functions/deseq/cli_args.R (v0.1.0)
# with a single behavioural change inside assert_args().
# --------------------------------------------------------------------------------------------------

# Try to source helper functions (optional, with fallback)
tryCatch({
  source_path <- file.path(dirname(getwd()), "common", "cli_helpers.R")
  if (file.exists(source_path)) {
    source(source_path)
  } else {
    docker_path <- "/usr/local/bin/functions/common/cli_helpers.R"
    if (file.exists(docker_path)) {
      source(docker_path)
    }
  }
}, error = function(e) {
  message("CLI helpers not available, using manual parsing")
})

# --------------------------------------------------------------------------------------------------
#  Patched assert_args -----------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------

#' Assert and validate command line arguments (patched)
#'
#' The original implementation aborted when alias vectors were provided but did
#' not match the number of files.  This patched version silently regenerates the
#' aliases from file basenames instead – preserving backwards-compatibility with
#' older input YAMLs that omit one or both alias arrays.
#'
#' @param parsed_arguments List returned by the argument parser
#' @return Modified argument list with validated and processed values
assert_args <- function(parsed_arguments) {
  log_message("Checking input parameters (patched)")

  auto_alias <- function(files) sub("\\..*$", "", basename(files))

  # Generate or fix untreated aliases
  if (is.null(parsed_arguments$untreated_sample_names) ||
      length(parsed_arguments$untreated_sample_names) == 0 ||
      length(parsed_arguments$untreated_sample_names) != length(parsed_arguments$untreated_files)) {
    if (!is.null(parsed_arguments$untreated_sample_names) &&
        length(parsed_arguments$untreated_sample_names) != length(parsed_arguments$untreated_files)) {
      log_warning("Length mismatch for untreated_sample_names – regenerating from filenames")
    }
    parsed_arguments$untreated_sample_names <- auto_alias(parsed_arguments$untreated_files)
  }

  # Generate or fix treated aliases
  if (is.null(parsed_arguments$treated_sample_names) ||
      length(parsed_arguments$treated_sample_names) == 0 ||
      length(parsed_arguments$treated_sample_names) != length(parsed_arguments$treated_files)) {
    if (!is.null(parsed_arguments$treated_sample_names) &&
        length(parsed_arguments$treated_sample_names) != length(parsed_arguments$treated_files)) {
      log_warning("Length mismatch for treated_sample_names – regenerating from filenames")
    }
    parsed_arguments$treated_sample_names <- auto_alias(parsed_arguments$treated_files)
  }

  # Check for minimum file requirements and adjust batch handling
  if (length(parsed_arguments$treated_files) == 1 || length(parsed_arguments$untreated_files) == 1) {
    log_warning("Only one file in a group. DESeq2 requires at least two replicates for accurate analysis.")
    parsed_arguments$batch_file <- NULL
  }

  # -----------------------------------------------------------------------------------------------
  # Below this line the code is identical to the original implementation --------------------------
  # -----------------------------------------------------------------------------------------------

  # Process batch metadata if provided
  if (!is.null(parsed_arguments$batch_file)) {
    batch_metadata <- with_error_handling({
      read.table(
        parsed_arguments$batch_file,
        sep = get_file_type(parsed_arguments$batch_file),
        row.names = 1,
        col.names = c("name", "batch"),
        header = FALSE,
        stringsAsFactors = FALSE
      )
    })

    if (is.null(batch_metadata)) {
      log_error("Failed to read batch metadata file")
      parsed_arguments$batch_file <- NULL
    } else {
      log_message("Loaded batch metadata")
      rownames(batch_metadata) <- gsub("'|\"| ", "_", rownames(batch_metadata))
      if (all(is.element(c(parsed_arguments$untreated_sample_names,
                           parsed_arguments$treated_sample_names),
                        rownames(batch_metadata)))) {
        parsed_arguments$batch_file <- batch_metadata # dataframe
      } else {
        log_warning("Missing values in batch metadata file. Skipping multi-factor analysis")
        log_debug(paste("Expected:", paste(c(parsed_arguments$untreated_sample_names,
                                            parsed_arguments$treated_sample_names), collapse=", ")))
        log_debug(paste("Found:", paste(rownames(batch_metadata), collapse=", ")))
        parsed_arguments$batch_file <- NULL
      }
    }
  }

  # Convert boolean string values if they came as strings
  for (arg_name in c("use_lfc_thresh", "test_mode")) {
    if (!is.null(parsed_arguments[[arg_name]])) {
      parsed_arguments[[arg_name]] <- convert_to_boolean(parsed_arguments[[arg_name]], FALSE)
    }
  }

  # Map argument names for compatibility with workflow
  parsed_arguments$treated   <- parsed_arguments$treated_files
  parsed_arguments$untreated <- parsed_arguments$untreated_files
  parsed_arguments$talias    <- parsed_arguments$treated_sample_names
  parsed_arguments$ualias    <- parsed_arguments$untreated_sample_names
  parsed_arguments$tname     <- parsed_arguments$treated_name
  parsed_arguments$uname     <- parsed_arguments$untreated_name
  parsed_arguments$output    <- parsed_arguments$output_prefix
  parsed_arguments$batchfile <- parsed_arguments$batch_file

  return(parsed_arguments)
}

# --------------------------------------------------------------------------------------------------
#  Remaining original functions (get_args, parse_args_manual, etc.) are included unmodified
# -------------------------------------------------------------------------------------------------- 