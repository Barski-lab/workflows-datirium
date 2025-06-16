#!/usr/bin/env Rscript
#
# ATAC-seq Pairwise Analysis Entry Point
# Main script for pairwise differential accessibility analysis
#

# Initialize the environment and run the workflow
main <- function() {
  tryCatch({
    # Source the workflow functions
    source_with_fallback <- function(relative_path, docker_path) {
      if (file.exists(docker_path)) {
        source(docker_path)
      } else if (file.exists(relative_path)) {
        source(relative_path)
      } else {
        stop(paste("Could not find file:", relative_path, "or", docker_path))
      }
    }
    
    # Try to load workflow functions
    source_with_fallback(
      "functions/atac_pairwise/workflow.R",
      "/usr/local/bin/functions/atac_pairwise/workflow.R"
    )
    
    # Initialize environment
    initialize_environment()
    
    # Parse command line arguments
    args <- get_args()
    
    # Run the workflow
    results <- run_workflow(args)
    
    message("ATAC-seq pairwise analysis completed successfully")
    
  }, error = function(e) {
    message("Error in ATAC-seq pairwise analysis:")
    message(e$message)
    quit(save = "no", status = 1, runLast = FALSE)
  })
}

# Run the main function
main() 