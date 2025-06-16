#!/bin/bash

echo "Testing ATAC pairwise R script directly..."

# Set up test parameters from the CWL call
cd /Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts

# Run the R script directly with the same parameters as the CWL call
Rscript run_atac_pairwise.R \
  --batchcorrection none \
  --cluster row \
  --fdr 0.05 \
  --k 3 \
  --kmax 5 \
  --lfcthreshold 0.5 \
  -o atac_pairwise_test \
  --regulation both \
  --scaling_type zscore \
  --test_mode \
  -p 1 \
  -t /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/atac_pairwise/inputs/sample3_peaks.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/atac_pairwise/inputs/sample4_peaks.csv \
  -tn Act \
  -ta sample3 sample4 \
  -u /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/atac_pairwise/inputs/sample1_peaks.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/atac_pairwise/inputs/sample2_peaks.csv \
  -un Rest \
  -ua sample1 sample2 \
  --use_lfc_thresh

echo "ATAC R script test exit code: $?"
echo "Generated files:"
ls -la *.md *.tsv *.gct *.html 2>/dev/null || echo "No output files found"