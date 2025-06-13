#!/bin/bash
set -e

echo "============================================"
echo "Running All DESeq2 LRT Step 2 Tests"
echo "============================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$PROJECT_ROOT"

echo "1. Validating CWL files..."
./my_local_test_data/deseq_lrt_step_2_tests/scripts/validate_all.sh

echo ""
echo "2. Running test mode (single contrast)..."
cwltool --outdir my_local_test_data/deseq_lrt_step_2_tests/outputs/test_mode \
    workflows/deseq-lrt-step-2-test.cwl \
    my_local_test_data/deseq_lrt_step_2_tests/inputs/test_mode.yml

echo ""
echo "3. Running single contrast test..."
cwltool --outdir my_local_test_data/deseq_lrt_step_2_tests/outputs/single_contrast \
    workflows/deseq-lrt-step-2-test.cwl \
    my_local_test_data/deseq_lrt_step_2_tests/inputs/single_contrast_test.yml

echo ""
echo "4. Running multiple contrasts test..."
cwltool --outdir my_local_test_data/deseq_lrt_step_2_tests/outputs/multiple_contrasts \
    workflows/deseq-lrt-step-2-test.cwl \
    my_local_test_data/deseq_lrt_step_2_tests/inputs/multiple_contrasts_test.yml

echo ""
echo "5. Running interaction test..."
cwltool --outdir my_local_test_data/deseq_lrt_step_2_tests/outputs/interaction \
    workflows/deseq-lrt-step-2-test.cwl \
    my_local_test_data/deseq_lrt_step_2_tests/inputs/interaction_test.yml

echo ""
echo "============================================"
echo "All tests completed! Check outputs in:"
echo "my_local_test_data/deseq_lrt_step_2_tests/outputs/"
echo "============================================" 