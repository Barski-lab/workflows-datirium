#!/usr/bin/env Rscript

#
# Entry point script for DESeq2 Pairwise Analysis
# This script bridges the CWL tool with the DESeq2 pairwise workflow functions
#

suppressMessages(library(methods))

# Source the utilities and common functions
source_with_fallback <- function(file_path, fallback_path) {
  if (file.exists(file_path)) {
    cat("Sourcing:", file_path, "\n")
    source(file_path)
  } else if (file.exists(fallback_path)) {
    cat("Sourcing fallback:", fallback_path, "\n")
    source(fallback_path)
  } else {
    stop("Could not find source file: ", file_path, " or ", fallback_path)
  }
}

cat("Starting DESeq2 Pairwise Analysis\n")
cat("Working directory:", getwd(), "\n")

# Source common utilities first
source_with_fallback("functions/common/utilities.R", "/usr/local/bin/functions/common/utilities.R")
source_with_fallback("functions/common/logging.R", "/usr/local/bin/functions/common/logging.R")
source_with_fallback("functions/common/error_handling.R", "/usr/local/bin/functions/common/error_handling.R")

# Source DESeq2 pairwise workflow functions
source_with_fallback("functions/deseq/workflow.R", "/usr/local/bin/functions/deseq/workflow.R")

# Execute the main workflow
main_with_memory_management <- function() {
  # Log initial memory usage
  initial_memory <- gc(verbose = FALSE)
  cat("[Memory] Initial:", round(sum(initial_memory[,2]) * 1024^2 / 1024^2, 1), "MB\n")
  
  tryCatch({
    # Call the main DESeq2 pairwise workflow
    run_deseq_analysis()
    
    # Log final memory usage
    final_memory <- gc(verbose = FALSE)
    cat("[Memory] Final:", round(sum(final_memory[,2]) * 1024^2 / 1024^2, 1), "MB\n")
    
  }, error = function(e) {
    cat("An unexpected error occurred. Aborting script.\n")
    cat("Error details:", e$message, "\n")
    quit(save = "no", status = 1, runLast = FALSE)
  })
}

# Run the main analysis
main_with_memory_management()

cat("DESeq2 Pairwise Analysis completed successfully!\n") 