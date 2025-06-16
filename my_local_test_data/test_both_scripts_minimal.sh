#!/bin/bash

echo "=== Testing Both R Scripts Minimally ==="

cd /Users/pavb5f/Documents/Git/workflows-datirium/tools/dockerfiles/scripts

echo "1. Testing DESeq Pairwise..."
echo "Command: Rscript run_deseq_pairwise.R -tn Test -un Control --test_mode"
if timeout 30s Rscript run_deseq_pairwise.R -tn Test -un Control --test_mode 2>/dev/null >/dev/null; then
    echo "   ✅ DESeq pairwise: SUCCESS (exited cleanly)"
else
    exit_code=$?
    echo "   ❌ DESeq pairwise: FAILED (exit code: $exit_code)"
fi

echo ""
echo "2. Testing ATAC Pairwise..."
echo "Command: Rscript run_atac_pairwise.R -tn Test -un Control --test_mode"
if timeout 30s Rscript run_atac_pairwise.R -tn Test -un Control --test_mode 2>/dev/null >/dev/null; then
    echo "   ✅ ATAC pairwise: SUCCESS (exited cleanly)" 
else
    exit_code=$?
    echo "   ❌ ATAC pairwise: FAILED (exit code: $exit_code)"
fi

echo ""
echo "=== Summary ==="
echo "Both scripts tested with minimal arguments to check basic functionality"