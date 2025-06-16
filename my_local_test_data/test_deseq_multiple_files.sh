#!/bin/bash

echo "Testing DESeq pairwise R script with multiple files (to trigger DESeq2 mode)..."

cd /Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts

# Test with multiple files per condition to trigger DESeq2 instead of EdgeR
Rscript run_deseq_pairwise.R \
  --test_mode \
  -t /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0226_KMR_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0230_KMR_rm.isoforms.csv \
  -u /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0218_CMR_rm.isoforms.csv \
     /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0222_CMR_rm.isoforms.csv \
  -tn Treated \
  -un Control \
  -ta ABSK0226_KMR_rm ABSK0230_KMR_rm \
  -ua ABSK0218_CMR_rm ABSK0222_CMR_rm

echo "DESeq with multiple files test exit code: $?"
echo "Generated files:"
ls -la *.md *.tsv *.gct *.html 2>/dev/null || echo "No output files found"