#!/bin/bash

echo "Testing DESeq pairwise R script with actual input files..."

cd /Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts

# Test with minimal required arguments including input files
Rscript run_deseq_pairwise.R \
  --test_mode \
  -t /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0226_KMR_rm.isoforms.csv \
  -u /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/core_data/ABSK0218_CMR_rm.isoforms.csv \
  -tn Treated \
  -un Control \
  -ta ABSK0226_KMR_rm \
  -ua ABSK0218_CMR_rm

echo "DESeq with files test exit code: $?"
echo "Generated files:"
ls -la *.md *.tsv *.gct *.html 2>/dev/null || echo "No output files found"