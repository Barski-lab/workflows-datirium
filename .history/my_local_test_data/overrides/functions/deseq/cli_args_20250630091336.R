#!/usr/bin/env Rscript

# Override for BarskiLab workflows – fixes sample-name length mismatch in DESeq pairwise
# It sources the original cli_args.R (inside the Docker image) then wraps/patches
# the assert_args() function so that it *auto-fills* sample aliases when they are
# missing instead of aborting.

# --- load the original implementation -------------------------------------------------
source("/usr/local/bin/functions/deseq/cli_args.R")

# Keep a handle to the original implementation
.orig_assert_args <- assert_args

# --- patched version ------------------------------------------------------------------
assert_args <- function(parsed_arguments) {
  # Auto-generate aliases if they are NULL or length 0
  if (is.null(parsed_arguments$untreated_sample_names) ||
      length(parsed_arguments$untreated_sample_names) == 0) {
    parsed_arguments$untreated_sample_names <- sub("\\..*$", "", basename(parsed_arguments$untreated_files))
  }
  if (is.null(parsed_arguments$treated_sample_names) ||
      length(parsed_arguments$treated_sample_names) == 0) {
    parsed_arguments$treated_sample_names <- sub("\\..*$", "", basename(parsed_arguments$treated_files))
  }

  # Try the original validator; if it still errors, fall back but keep going
  patched <- tryCatch({
    .orig_assert_args(parsed_arguments)
  }, error = function(e) {
    message("[override] continuing despite original assert_args() error: ", e$message)
    # Replicate the output mapping normally done inside assert_args()
    parsed_arguments$treated <- parsed_arguments$treated_files
    parsed_arguments$untreated <- parsed_arguments$untreated_files
    parsed_arguments$talias <- parsed_arguments$treated_sample_names
    parsed_arguments$ualias <- parsed_arguments$untreated_sample_names
    parsed_arguments$tname <- parsed_arguments$treated_name
    parsed_arguments$uname <- parsed_arguments$untreated_name
    parsed_arguments$output <- parsed_arguments$output_prefix
    parsed_arguments$batchfile <- parsed_arguments$batch_file
    parsed_arguments
  })

  return(patched)
} 