#!/bin/bash

echo "Testing only pairwise workflows..."

# DESeq Pairwise
echo "Testing DESeq Pairwise..."
if cwltool ../tools/deseq-pairwise.cwl deseq_pairwise/inputs/basic_test.yml > deseq_pairwise_test.log 2>&1; then
    echo "DESeq Pairwise: SUCCESS"
else
    echo "DESeq Pairwise: FAILED"
    echo "Last 10 lines of log:"
    tail -10 deseq_pairwise_test.log
fi

# ATAC Pairwise  
echo "Testing ATAC Pairwise..."
if cwltool ../tools/atac-pairwise.cwl atac_pairwise/inputs/basic_test.yml > atac_pairwise_test.log 2>&1; then
    echo "ATAC Pairwise: SUCCESS"
else
    echo "ATAC Pairwise: FAILED" 
    echo "Last 10 lines of log:"
    tail -10 atac_pairwise_test.log
fi

echo "Pairwise test completed."