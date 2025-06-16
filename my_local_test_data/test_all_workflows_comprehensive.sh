#!/bin/bash

# Comprehensive Workflow Testing Script
# Tests all 6 workflows and provides detailed status report

set -e
export DOCKER_DEFAULT_PLATFORM=linux/amd64

echo "🧪 COMPREHENSIVE WORKFLOW TESTING - $(date)"
echo "=============================================="

# Test results tracking using simple arrays
test_results=""
test_times=""
test_errors=""

# Function to run a single test
run_test() {
    local workflow_name="$1"
    local cwl_file="$2"
    local input_file="$3"
    
    echo ""
    echo "🔬 Testing: $workflow_name"
    echo "   CWL: $cwl_file"
    echo "   Input: $input_file"
    echo "   Time: $(date)"
    
    start_time=$(date +%s)
    
    if cwltool --debug "$cwl_file" "$input_file" > "${workflow_name}_test.log" 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "   Result: ✅ SUCCESS (${duration}s)"
        echo "$workflow_name:SUCCESS:${duration}s" >> test_results.txt
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        # Extract error from log
        error_msg=$(tail -10 "${workflow_name}_test.log" | grep -E "(Error|error)" | head -1 || echo "Unknown error")
        echo "   Result: ❌ FAILED (${duration}s)"
        echo "   Error: $error_msg"
        echo "$workflow_name:FAILED:${duration}s:$error_msg" >> test_results.txt
    fi
}

# Clean up previous results
rm -f test_results.txt

# Test 1: DESeq LRT Step 1 (Known working)
run_test "deseq_lrt_step_1" "../tools/deseq-lrt-step-1.cwl" "deseq_lrt_step_1/inputs/basic_test.yml"

# Test 2: DESeq LRT Step 2 (Known working)
run_test "deseq_lrt_step_2" "../tools/deseq-lrt-step-2.cwl" "deseq_lrt_step_2/inputs/basic_test.yml"

# Test 3: ATAC LRT Step 1 (Known working)
run_test "atac_lrt_step_1" "../tools/atac-lrt-step-1.cwl" "atac_lrt_step_1/inputs/basic_test.yml"

# Test 4: DESeq Pairwise (Fixed - testing)
run_test "deseq_pairwise" "../tools/deseq-pairwise.cwl" "deseq_pairwise/inputs/basic_test.yml"

# Test 5: ATAC LRT Step 2 (Fixed - testing)
run_test "atac_lrt_step_2" "../tools/atac-lrt-step-2.cwl" "atac_lrt_step_2/inputs/basic_test.yml"

# Test 6: ATAC Pairwise (Fixed - testing)
run_test "atac_pairwise" "../tools/atac-pairwise.cwl" "atac_pairwise/inputs/basic_test.yml"

echo ""
echo "📊 COMPREHENSIVE TEST RESULTS"
echo "=============================="

# Summary statistics
total_tests=6
successful_tests=$(grep -c ":SUCCESS:" test_results.txt 2>/dev/null || echo 0)
failed_tests=$(grep -c ":FAILED:" test_results.txt 2>/dev/null || echo 0)

echo "📈 Summary: $successful_tests/$total_tests workflows successful"
echo ""

# Detailed results
echo "🔍 Detailed Results:"
echo "-------------------"

# Known working workflows
echo ""
echo "✅ PREVIOUSLY CONFIRMED WORKING:"
for workflow in "deseq_lrt_step_1" "deseq_lrt_step_2" "atac_lrt_step_1"; do
    result=$(grep "^$workflow:" test_results.txt 2>/dev/null || echo "")
    if [[ -n "$result" ]]; then
        status=$(echo "$result" | cut -d: -f2)
        time=$(echo "$result" | cut -d: -f3)
        if [[ "$status" == "SUCCESS" ]]; then
            echo "   $workflow: ✅ SUCCESS ($time)"
        else
            echo "   $workflow: ❌ FAILED ($time)"
        fi
    fi
done

# Fixed workflows being tested
echo ""
echo "🔧 RECENTLY FIXED - TESTING:"
for workflow in "deseq_pairwise" "atac_lrt_step_2" "atac_pairwise"; do
    result=$(grep "^$workflow:" test_results.txt 2>/dev/null || echo "")
    if [[ -n "$result" ]]; then
        status=$(echo "$result" | cut -d: -f2)
        time=$(echo "$result" | cut -d: -f3)
        if [[ "$status" == "SUCCESS" ]]; then
            echo "   $workflow: ✅ SUCCESS ($time)"
        else
            error=$(echo "$result" | cut -d: -f4-)
            echo "   $workflow: ❌ FAILED ($time)"
            echo "      Error: $error"
        fi
    fi
done

echo ""
echo "📋 NEXT STEPS:"
echo "-------------"

if [ $successful_tests -eq 6 ]; then
    echo "🎉 ALL WORKFLOWS SUCCESSFUL! Ready for production deployment."
elif [ $successful_tests -ge 3 ]; then
    echo "✅ $successful_tests workflows confirmed working"
    echo "🔧 $failed_tests workflows need additional debugging"
    echo "💡 Focus on fixing the failed workflows using script mounting for rapid iteration"
else
    echo "⚠️  Major issues detected. Review infrastructure and Docker images."
fi

echo ""
echo "📁 Log files created:"
ls -la *_test.log 2>/dev/null || echo "   No log files found"

echo ""
echo "🏁 Testing completed at $(date)" 