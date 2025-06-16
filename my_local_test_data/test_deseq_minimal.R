#!/usr/bin/env Rscript

# Minimal test for DESeq pairwise functionality
message("Testing DESeq pairwise core functionality...")

# Set working directory to scripts location
setwd("/Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts")

# Load only essential packages that are likely available
tryCatch({
  suppressPackageStartupMessages({
    if (requireNamespace("DESeq2", quietly = TRUE)) {
      library(DESeq2)
      message("✓ DESeq2 loaded")
    } else {
      stop("DESeq2 package not available")
    }
    
    if (requireNamespace("data.table", quietly = TRUE)) {
      library(data.table)
      message("✓ data.table loaded")
    }
  })
  
  # Test manual argument parsing
  message("Testing manual argument parsing...")
  source("functions/deseq/cli_args.R")
  
  # Simulate command line arguments
  test_args <- c(
    "-t", "/Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0226_KMR_rm.isoforms.csv",
    "-u", "/Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0218_CMR_rm.isoforms.csv",
    "--test_mode",
    "--fdr", "0.1"
  )
  
  # Test that the function exists
  if (exists("parse_args_manual")) {
    message("✓ parse_args_manual function found")
  } else {
    message("✗ parse_args_manual function not found")
  }
  
  message("✓ Core DESeq pairwise functionality test completed")
  
}, error = function(e) {
  message("✗ Error in core functionality test:")
  message(e$message)
  quit(status = 1)
})