#!/usr/bin/env Rscript

# Debug which get_args function is being called
setwd("/Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts")

# Source workflow file  
source("functions/atac_pairwise/workflow.R")

# Initialize environment 
initialize_environment()

# Test get_args function directly
cat("Testing get_args function with arguments...\n")
result <- get_args()
cat("Result from get_args:\n")
print(names(result))
cat("condition1:", result$condition1, "\n")
cat("condition2:", result$condition2, "\n")