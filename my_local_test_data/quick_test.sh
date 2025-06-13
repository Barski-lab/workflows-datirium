#!/bin/bash

# Quick test script for DESeq and ATAC-seq workflows (without CWL validation)
# Updated for clean directory structure

set -e  # Exit on any error

echo "=========================================="
echo "Quick DESeq & ATAC workflow tests (no validation)"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local workflow="$2"
    local input_file="$3"
    local output_dir="$4"
    
    echo -e "\n${YELLOW}Running: $test_name${NC}"
    echo "Workflow: $workflow"
    echo "Input: $input_file"
    echo "Output: $output_dir"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Run the test with timeout (5 minutes per test)
    if cwltool --outdir "$output_dir" "$workflow" "$input_file"; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

# ===========================================
# DESEQ WORKFLOW TESTS
# ===========================================

# Test 1: DESeq LRT Step 1 - Basic Test (most important)
run_test "DESeq LRT Step 1 - Basic Test" \
         "workflows/deseq-lrt-step-1-test.cwl" \
         "my_local_test_data/deseq_lrt_step_1/inputs/basic_test.yml" \
         "my_local_test_data/deseq_lrt_step_1/outputs/basic_test"

# Test 2: DESeq LRT Step 2 - Single Contrast Test
run_test "DESeq LRT Step 2 - Single Contrast" \
         "workflows/deseq-lrt-step-2-test.cwl" \
         "my_local_test_data/deseq_lrt_step_2/inputs/single_contrast_test.yml" \
         "my_local_test_data/deseq_lrt_step_2/outputs/single_contrast"

# Test 3: DESeq Standard - Basic Test
run_test "DESeq Standard - Basic Test" \
         "workflows/deseq.cwl" \
         "my_local_test_data/deseq_standard/inputs/basic_test.yml" \
         "my_local_test_data/deseq_standard/outputs/basic_test"

# ===========================================
# ATAC-SEQ WORKFLOW TESTS
# ===========================================

# Test 4: ATAC LRT Step 1 - Basic Test
run_test "ATAC LRT Step 1 - Basic Test" \
         "workflows/atac-lrt-step-1-test.cwl" \
         "my_local_test_data/atac_lrt_step_1/inputs/basic_test.yml" \
         "my_local_test_data/atac_lrt_step_1/outputs/basic_test"

# Test 5: ATAC Standard - Basic Test
run_test "ATAC Standard - Basic Test" \
         "workflows/atac-advanced.cwl" \
         "my_local_test_data/atac_standard/inputs/basic_test.yml" \
         "my_local_test_data/atac_standard/outputs/basic_test"

# Summary
echo -e "\n=========================================="
echo -e "${YELLOW}TEST SUMMARY${NC}"
echo "=========================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  - $test"
    done
    exit 1
else
    echo -e "\n${GREEN}🎉 All tests passed successfully!${NC}"
    exit 0
fi 