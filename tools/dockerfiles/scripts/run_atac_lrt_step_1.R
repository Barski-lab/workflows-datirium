#!/usr/bin/env Rscript
#
# Main entry point for ATAC-seq LRT Step 1 Analysis
#

# Source required function files
source("/usr/local/bin/functions/common/error_handling.R")
source("/usr/local/bin/functions/common/output_utils.R")
source("/usr/local/bin/functions/atac_lrt_step_1/workflow.R")

# Set up error handling
options(error = function(e) handle_error(e, "ATAC-seq LRT Step 1"))

# Run the workflow
tryCatch({
    # Initialize the environment and load required packages
    initialize_environment()
    
    # Execute the main workflow
    run_atac_lrt_workflow()
    
    message("ATAC-seq LRT Step 1 analysis completed successfully.")
}, error = function(e) {
    handle_error(e, "ATAC-seq LRT Step 1")
})
