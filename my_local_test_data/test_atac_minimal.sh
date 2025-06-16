#!/bin/bash

echo "Testing ATAC pairwise R script with minimal args..."

cd /Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts

# Test with minimal arguments that should work
Rscript run_atac_pairwise.R \
  -tn Act \
  -un Rest \
  -o atac_test \
  --test_mode \
  -t /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/atac_pairwise/inputs/sample3_peaks.csv \
  -u /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/atac_pairwise/inputs/sample1_peaks.csv \
  -ta sample3 \
  -ua sample1

echo "ATAC minimal test exit code: $?"
echo "Generated files:"
ls -la *.md *.tsv *.gct *.html 2>/dev/null || echo "No output files found"