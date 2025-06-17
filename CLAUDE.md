# CLAUDE.md

This file provides guidance to Claude Code when working with this CWL bioinformatics workflows repository.

## Repository Structure

**CWL Bioinformatics Workflows** for ChIP-Seq, ATAC-Seq, RNA-Seq analysis:
- `tools/` - CWL tool definitions wrapping R/Python scripts in Docker containers
- `workflows/` - Multi-step analysis pipelines
- `tools/dockerfiles/scripts/functions/` - Modular R function libraries by workflow type
- `tools/dockerfiles/scripts/run_*.R` - Main execution scripts

### Core Workflows
- **DESeq2 LRT** - Differential expression likelihood ratio testing (2-step)
- **ATAC-seq LRT** - Differential chromatin accessibility analysis  
- **Standard DESeq2** - Pairwise differential expression
- **Single-cell** - scRNA-seq, scATAC-seq pipelines

## Essential Commands

```bash
# Primary testing (most common task)
cd my_local_test_data && ./quick_test.sh              # Fast validation (2-3 min)
cd my_local_test_data && ./run_all_tests.sh           # Full test suite (10-15 min)

# CWL development
cwltool --validate tools/[workflow-name].cwl          # Syntax validation
cwltool --debug tools/[workflow-name].cwl inputs.yml  # Debug execution

# Docker management
docker images | grep -E "(scidap|biowardrobe)"       # List workflow images
```

## Development Guidelines

### Code Organization
**R Function Libraries** (primary development area):
```
tools/dockerfiles/scripts/functions/
├── common/                    # Shared utilities (logging, visualization)
├── deseq2_lrt_step_1/        # DESeq2 LRT step 1 functions
├── atac_lrt_step_1/          # ATAC-seq LRT step 1 functions
└── [workflow_type]/          # Workflow-specific functions
    ├── workflow.R            # Main orchestration
    ├── cli_args.R           # Command line parsing
    ├── data_processing.R    # Data validation/loading
    └── [analysis].R         # Core analysis functions
```

### Development Order
1. **R functions** (`functions/*/`) - Core logic
2. **Entry scripts** (`run_*.R`) - Coordination
3. **CWL tools** (`tools/*.cwl`) - Interface definitions

### Critical Rules
- **File creation**: Only create files in `my_local_test_data/` directory
- **Testing**: Always run `quick_test.sh` before finalizing changes
- **Docker**: Use specific images - `biowardrobe2/scidap-deseq:v0.0.62` (DESeq2), `biowardrobe2/scidap-atac:v0.0.67` (ATAC)
- **Paths**: Use absolute paths in CWL input YAML files
- **Parameters**: Use `--input_files` (not `--input`) for ATAC workflows

## Current Status: 6/6 Workflows Working ✅

### ✅ All Workflows Confirmed Working:
- **DESeq LRT Step 1** - Complete functionality (`biowardrobe2/scidap-deseq:v0.0.62`)
- **DESeq LRT Step 2** - Multi-contrast analysis (`biowardrobe2/scidap-deseq:v0.0.62`) 
- **DESeq Pairwise** - Pairwise differential expression (`biowardrobe2/scidap-deseq:v0.0.62`)
- **ATAC LRT Step 1** - Test mode bypass functional (`biowardrobe2/scidap-atac:v0.0.67`)
- **ATAC LRT Step 2** - Fixed MDS plot filename (`biowardrobe2/scidap-atac:v0.0.67`)
- **ATAC Pairwise** - Fixed missing summary.md creation (`biowardrobe2/scidap-atac:v0.0.67`)

### 🧹 Infrastructure Cleanup Complete (2025-06-16):
- **Test Directory**: Cleaned my_local_test_data/, removed 50+ redundant files
- **Docker Images**: Updated to latest versions with all script fixes
- **Paths**: Converted absolute paths to relative paths in all test YAML files
- **Data Consolidation**: Moved all shared test data to `core_data/` directory
- **Test Framework**: Streamlined to essential scripts (`quick_test.sh`, `final_comprehensive_test.sh`)

## Maintenance Tasks

- Periodic Docker image updates
- Monitor for upstream CWL/R dependency changes
- Validate scientific accuracy of statistical outputs

### When asked to "add new functionality"

1. Identify target workflow type (DESeq2/ATAC/etc.)
2. Modify appropriate R functions in `functions/[workflow_type]/`
3. Update entry point script `run_[workflow].R` if needed
4. Update CWL tool definition in `tools/`
5. Test with `quick_test.sh`

### When asked to "debug specific errors"

1. Use `cwltool --debug` for CWL issues
2. Check Docker image availability with `docker images | grep scidap`
3. For R errors, examine function libraries and CLI argument parsing
4. Common fixes: missing constants, incorrect parameter names, closure errors

### When asked to "optimize performance"

1. Use `test_mode=true` in R scripts for faster development
2. Mount scripts for testing instead of rebuilding Docker images
3. Focus on data processing functions first

## Debugging Patterns

**Common Error Types:**

- **CLI parsing errors**: Check `cli_args.R` files for parameter mismatches
- **Missing constants**: Look for undefined variables in R functions
- **File path issues**: Ensure absolute paths in CWL input files
- **Docker issues**: Verify image names and versions match exactly

**Quick Diagnostics:**

```bash
# Check what's failing
cd my_local_test_data && ./quick_test.sh 2>&1 | grep -E "(FAIL|ERROR)"

# Examine specific test logs  
find my_local_test_data -name "test.log" -exec grep -l "ERROR" {} \;
```
