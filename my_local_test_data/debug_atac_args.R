#!/usr/bin/env Rscript

# Debug ATAC argument parsing
cat("Raw command line arguments:\n")
args <- commandArgs(trailingOnly = TRUE)
cat(paste("Args:", paste(args, collapse = " ")), "\n")

# Set working directory  
setwd("/Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts")

# Source the cli_args file
source("functions/atac_pairwise/cli_args.R")

# Test manual parsing
result <- parse_args_manual_atac()
cat("Parsed arguments:\n")
print(result)

# Check specific fields
cat("treated_name:", result$treated_name, "\n")
cat("untreated_name:", result$untreated_name, "\n")
cat("output:", result$output, "\n")