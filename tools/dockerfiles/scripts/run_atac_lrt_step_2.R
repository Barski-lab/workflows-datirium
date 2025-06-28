#!/usr/bin/env Rscript

# Main runner script for ATAC-seq LRT Step 2 Analysis

# Source the workflow functions
source("/usr/local/bin/functions/atac_lrt_step_2/workflow.R")

# Run the main workflow
tryCatch({
  initialize_environment()
  main_with_memory_management()
}, error = function(e) {
  cat("ERROR: ATAC-seq LRT Step 2 analysis failed\n")
  cat("Error message:", conditionMessage(e), "\n")
  traceback()
  quit(status = 1)
})
