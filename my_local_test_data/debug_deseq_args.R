#!/usr/bin/env Rscript

# Debug DESeq argument parsing
cat("Raw command line arguments:\n")
args <- commandArgs(trailingOnly = TRUE)
cat(paste("Args:", paste(args, collapse = " ")), "\n")

# Set working directory  
setwd("/Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts")

# Source the cli_args file
source("functions/deseq/cli_args.R")

# Test manual parsing
result <- get_args()
cat("Parsed arguments:\n")
print(names(result))
cat("treated files:", result$treated, "\n")
cat("untreated files:", result$untreated, "\n")
cat("uname:", result$uname, "\n")
cat("tname:", result$tname, "\n")