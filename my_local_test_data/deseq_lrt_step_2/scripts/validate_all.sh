#!/bin/bash

# Script to validate all CWL files for DESeq2 LRT Step 2
# Run this first before executing any tests

set -e

echo "============================================"
echo "Validating DESeq2 LRT Step 2 CWL Files"
echo "============================================"

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Project root: $PROJECT_ROOT"
echo ""

# Validate step-2 tool
echo "1. Validating DESeq2 LRT Step 2 Tool..."
if cwltool --validate tools/deseq-lrt-step-2.cwl; then
    echo "✓ Tool validation passed"
else
    echo "✗ Tool validation failed"
    exit 1
fi
echo ""

# Validate step-2 workflow
echo "2. Validating DESeq2 LRT Step 2 Workflow..."
if cwltool --validate workflows/deseq-lrt-step-2-test.cwl; then
    echo "✓ Workflow validation passed"
else
    echo "✗ Workflow validation failed"
    exit 1
fi
echo ""

echo "============================================"
echo "All CWL files validated successfully!"
echo "============================================" 