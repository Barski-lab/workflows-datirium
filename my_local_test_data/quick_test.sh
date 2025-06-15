#!/bin/bash

# Quick test script for DESeq and ATAC-seq workflows
# Must be run from repository root directory
# Usage: cd my_local_test_data && ./quick_test.sh

set -e  # Exit on any error

# Check if we're in the right directory
if [[ ! -f "../tools/deseq-lrt-step-1.cwl" ]]; then
    echo "❌ Error: Must run from my_local_test_data directory"
    echo "Usage: cd my_local_test_data && ./quick_test.sh"
    exit 1
fi

echo "=========================================="
echo "Quick DESeq & ATAC workflow tests"
echo "Running in TEST MODE for faster execution"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local tool_path="$2"  # Now using tools/ directly
    local input_file="$3"
    local output_dir="$4"
    
    echo -e "\n${YELLOW}Running: $test_name${NC}"
    echo -e "${BLUE}Tool: $tool_path${NC}"
    echo -e "${BLUE}Input: $input_file${NC}"
    echo -e "${BLUE}Output: $output_dir${NC}"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Run the test (tools only for quick testing)
    if cwltool --outdir "$output_dir" "$tool_path" "$input_file" > "$output_dir/test.log" 2>&1; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        echo -e "${RED}  Check log: $output_dir/test.log${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        # Continue with other tests instead of exiting
    fi
}

echo -e "\n${YELLOW}=== CORE TOOL TESTS (FAST) ===${NC}"

# Test 1: DESeq LRT Step 1 - Basic Test (KNOWN WORKING)
run_test "DESeq LRT Step 1 Tool" \
         "../tools/deseq-lrt-step-1.cwl" \
         "deseq_lrt_step_1/inputs/basic_test.yml" \
         "deseq_lrt_step_1/outputs/quick_test"

# Test 2: ATAC LRT Step 1 - Basic Test (NEEDS FIXING)
run_test "ATAC LRT Step 1 Tool" \
         "../tools/atac-lrt-step-1.cwl" \
         "atac_lrt_step_1/inputs/basic_test.yml" \
         "atac_lrt_step_1/outputs/quick_test"

# Summary
echo -e "\n=========================================="
echo -e "${YELLOW}QUICK TEST SUMMARY${NC}"
echo "=========================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  - $test"
    done
    echo -e "\n${YELLOW}💡 Tip: Check individual log files for details${NC}"
    exit 1
else
    echo -e "\n${GREEN}🎉 All quick tests passed!${NC}"
    exit 0
fi 