#!/bin/bash
set -e

echo "DEBUG: Testing DESeq2 LRT Step 2 with verbose output"
echo "Current directory: $(pwd)"
echo "Docker images available:"
docker images | grep scidap-deseq | head -3

echo ""
echo "Checking input files:"
echo "dsq_obj_data: /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/deseq_lrt_step_1_tests/local_test_deseq_lrt_step1_contrasts.rds"
ls -la "/Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/deseq_lrt_step_1_tests/local_test_deseq_lrt_step1_contrasts.rds"

echo ""
echo "contrasts_table: /Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/deseq_lrt_step_1_tests/deseq_lrt_step_1_contrasts_table.tsv"
ls -la "/Users/pavb5f/Documents/Git/workflows-datirium/my_local_test_data/deseq_lrt_step_1_tests/deseq_lrt_step_1_contrasts_table.tsv"

echo ""
echo "Testing Docker container access to R script:"
docker run --rm local/scidap-deseq:v0.0.48 ls -la /usr/local/bin/run_deseq_lrt_step_2.R

echo ""
echo "Testing Docker container access to workflow functions:"
docker run --rm local/scidap-deseq:v0.0.48 ls -la /usr/local/bin/functions/deseq2_lrt_step_2/

echo ""
echo "Running step-2 tool with debug output..."
cwltool --debug --outdir my_local_test_data/deseq_lrt_step_2_tests/outputs/test_mode tools/deseq-lrt-step-2.cwl my_local_test_data/deseq_lrt_step_2_tests/inputs/test_mode.yml 