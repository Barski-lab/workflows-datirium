#!/bin/bash

echo "Testing DESeq pairwise R script directly..."

# Set up test parameters from the CWL call
cd /Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts

# Run the R script directly with the same parameters as the CWL call
Rscript run_deseq_pairwise.R \
  --batchcorrection none \
  --fdr 0.1 \
  --k 3 \
  --kmax 5 \
  --lfcthreshold 0.59 \
  --regulation both \
  --scaling_type zscore \
  --test_mode \
  -p 4 \
  -t /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0226_KMR_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0230_KMR_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0227_KMA_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK231238_rm.isoforms.csv \
  -tn Knockout \
  -ta ABSK0226_KMR_rm ABSK0230_KMR_rm ABSK0227_KMA_rm ABSK231238_rm \
  -u /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0218_CMR_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0222_CMR_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0219_CMA_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0223_CMA_rm.isoforms.csv \
  -un Control \
  -ua ABSK0218_CMR_rm ABSK0222_CMR_rm ABSK0219_CMA_rm ABSK0223_CMA_rm \
  --use_lfc_thresh

echo "DESeq R script test exit code: $?"
echo "Generated files:"
ls -la *.md *.tsv *.gct *.html 2>/dev/null || echo "No output files found"