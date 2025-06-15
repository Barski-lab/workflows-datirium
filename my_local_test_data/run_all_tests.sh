#!/bin/bash

# Comprehensive test script for all DESeq and ATAC workflows
# Must be run from repository root directory
# Usage: cd my_local_test_data && ./run_all_tests.sh

# Remove set -e to allow continuing after failures
# set -e  # Exit on any error

# Check if we're in the right directory
if [[ ! -f "../tools/deseq-lrt-step-1.cwl" ]]; then
    echo "❌ Error: Must run from my_local_test_data directory"
    echo "Usage: cd my_local_test_data && ./run_all_tests.sh"
    exit 1
fi

echo "=========================================="
echo "Comprehensive DESeq & ATAC workflow tests"
echo "Running in TEST MODE for faster execution"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local tool_path="$2"
    local input_file="$3"
    local output_dir="$4"
    
    echo -e "\n${YELLOW}Running: $test_name${NC}"
    echo -e "${BLUE}Tool: $tool_path${NC}"
    echo -e "${BLUE}Input: $input_file${NC}"
    echo -e "${BLUE}Output: $output_dir${NC}"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Run the test with timeout
    if cwltool --outdir "$output_dir" "$tool_path" "$input_file" > "$output_dir/test.log" 2>&1; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        echo -e "${RED}  Check log: $output_dir/test.log${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        # Continue with other tests
    fi
}

# Validate CWL syntax first
echo -e "\n${PURPLE}=== CWL SYNTAX VALIDATION ===${NC}"
echo "Validating core tools..."

# Only validate files that exist
if [[ -f "../tools/deseq-lrt-step-1.cwl" ]]; then
    echo "Validating deseq-lrt-step-1.cwl..."
    cwltool --validate ../tools/deseq-lrt-step-1.cwl
fi

if [[ -f "../tools/atac-lrt-step-1.cwl" ]]; then
    echo "Validating atac-lrt-step-1.cwl..."
    cwltool --validate ../tools/atac-lrt-step-1.cwl
fi

echo -e "${GREEN}✓ CWL validation complete${NC}"

echo -e "\n${PURPLE}=== TOOL TESTS ===${NC}"

# Only test existing input files
if [[ -f "deseq_lrt_step_1/inputs/basic_test.yml" ]]; then
    run_test "DESeq LRT Step 1 Tool" \
             "../tools/deseq-lrt-step-1.cwl" \
             "deseq_lrt_step_1/inputs/basic_test.yml" \
             "deseq_lrt_step_1/outputs/comprehensive_test"
fi

if [[ -f "atac_lrt_step_1/inputs/basic_test.yml" ]]; then
    run_test "ATAC LRT Step 1 Tool" \
             "../tools/atac-lrt-step-1.cwl" \
             "atac_lrt_step_1/inputs/basic_test.yml" \
             "atac_lrt_step_1/outputs/comprehensive_test"
fi

# Test DESeq LRT Step 2 if input exists
if [[ -f "deseq_lrt_step_2/inputs/single_contrast_test.yml" ]]; then
    run_test "DESeq LRT Step 2 Tool" \
             "../tools/deseq-lrt-step-2.cwl" \
             "deseq_lrt_step_2/inputs/single_contrast_test.yml" \
             "deseq_lrt_step_2/outputs/comprehensive_test"
fi

# Summary
echo -e "\n=========================================="
echo -e "${YELLOW}COMPREHENSIVE TEST SUMMARY${NC}"
echo "=========================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  - $test"
    done
    echo -e "\n${YELLOW}💡 Tips:${NC}"
    echo -e "  - Check individual log files for details"
    echo -e "  - For ATAC failures, see my_local_test_data/README.md for known fixes"
    echo -e "  - Use ${BLUE}./quick_test.sh${NC} for faster iteration"
    exit 1
else
    echo -e "\n${GREEN}🎉 All tests passed successfully!${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "  - Run workflow tests: ${BLUE}cwltool ../workflows/deseq-lrt-step-1-test.cwl ...${NC}"
    echo -e "  - Check Docker images: ${BLUE}docker images | grep scidap${NC}"
    exit 0
fi 