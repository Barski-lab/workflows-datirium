#\!/bin/bash
echo "🧪 FINAL COMPREHENSIVE TEST - All 6 Workflows"
echo "=============================================="

# Test all 6 workflows with new Docker images
workflows=(
  "deseq_lrt_step_1:../tools/deseq-lrt-step-1.cwl:deseq_lrt_step_1/inputs/basic_test.yml"
  "deseq_lrt_step_2:../tools/deseq-lrt-step-2.cwl:deseq_lrt_step_2/inputs/basic_test.yml"
  "atac_lrt_step_1:../tools/atac-lrt-step-1.cwl:atac_lrt_step_1/inputs/basic_test.yml"
  "deseq_pairwise:../tools/deseq-pairwise.cwl:deseq_pairwise/inputs/basic_test.yml"
  "atac_pairwise:../tools/atac-pairwise.cwl:atac_pairwise/inputs/basic_test.yml"
  "atac_lrt_step_2:../tools/atac-lrt-step-2.cwl:atac_lrt_step_2/inputs/basic_test.yml"
)

success_count=0
total_count=6

for workflow in "${workflows[@]}"; do
  IFS=":" read -r name cwl input <<< "$workflow"
  echo "Testing: $name"
  
  if cwltool "$cwl" "$input" > "${name}_final_validation.log" 2>&1; then
    echo "  ✅ SUCCESS"
    ((success_count++))
  else
    echo "  ❌ FAILED"
  fi
done

echo "=============================================="
echo "🎯 FINAL RESULTS: $success_count/$total_count workflows successful"
echo "=============================================="

