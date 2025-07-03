# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this CWL bioinformatics workflows repository.

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
# Primary testing (most common task) - MUST run from my_local_test_data/
cd my_local_test_data && ./quick_test.sh              # Fast validation (2-3 min)
cd my_local_test_data && ./comprehensive_test.sh      # Full test suite (10-15 min)

# Platform-specific setup (Apple Silicon)
export DOCKER_DEFAULT_PLATFORM=linux/amd64           # Required for ARM architecture

# CWL development
cwltool --validate tools/[workflow-name].cwl          # Syntax validation
cwltool --debug tools/[workflow-name].cwl inputs.yml  # Debug execution

# Docker management
docker images | grep -E "(scidap|biowardrobe)"       # List workflow images
docker stats                                          # Monitor container resource usage
```

## Development Guidelines

### CWL Workflow Architecture
Each workflow consists of three layers:
1. **CWL Tool Definition** (`tools/*.cwl`) - Defines interface, Docker image, and I/O
2. **R Entry Script** (`tools/dockerfiles/scripts/run_*.R`) - Coordinates execution
3. **Modular R Functions** (`tools/dockerfiles/scripts/functions/`) - Core logic

### Code Organization
**R Function Libraries** (primary development area):
```
tools/dockerfiles/scripts/functions/
├── common/                    # Shared utilities (logging, visualization)
│   ├── constants.R           # System-wide constants
│   ├── utilities.R           # File path resolution, source helpers
│   ├── output_utils.R        # File output and validation functions
│   ├── visualization.R       # Plot generation and customization
│   └── atac_common/          # ATAC-specific shared functions
├── deseq2_lrt_step_1/        # DESeq2 LRT step 1 functions
├── atac_lrt_step_1/          # ATAC-seq LRT step 1 functions
└── [workflow_type]/          # Workflow-specific functions
    ├── workflow.R            # Main orchestration and environment setup
    ├── cli_args.R           # Command line argument parsing and validation
    ├── data_processing.R    # Data validation, loading, and preprocessing
    └── [analysis].R         # Core statistical analysis functions
```

**Entry Scripts Pattern:**
- `run_[workflow].R` - Minimal coordination scripts that source workflow functions
- Handle Docker vs local path resolution for sourcing functions
- Parse CLI arguments and delegate to workflow functions

### Development Order
1. **R functions** (`functions/*/`) - Core logic
2. **Entry scripts** (`run_*.R`) - Coordination
3. **CWL tools** (`tools/*.cwl`) - Interface definitions

### Critical Rules
- **File creation**: Only create files in `my_local_test_data/` directory
- **Testing**: Always run `quick_test.sh` before finalizing changes
- **Test execution**: MUST run test scripts from `my_local_test_data/` directory (scripts validate location)
- **Docker Images**: 
  - DESeq2 workflows: `biowardrobe2/scidap-deseq:v0.0.62`
  - ATAC workflows: `biowardrobe2/scidap-atac:v0.0.67`
  - Images are pre-built with R scripts; development uses test_mode=true for faster iteration
- **Paths**: Use relative paths to `core_data/` in CWL input YAML files
- **Parameters**: Use `--input_files` (not `--input`) for ATAC workflows
- **R Function Sourcing**: All functions use `source_with_fallback()` for Docker/local path resolution
- **Test Mode**: All test files use `test_mode: true` for faster development iterations

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
- **Test Framework**: Streamlined to essential scripts (`quick_test.sh`, `comprehensive_test.sh`)

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
- **File path issues**: Ensure relative paths to core_data/ in CWL input files
- **Docker issues**: Verify image names and versions match exactly
- **Memory errors**: Large datasets may require resource adjustments
- **R package conflicts**: Check namespace collisions in workflow functions

**Quick Diagnostics:**

```bash
# Check what's failing (from my_local_test_data/)
cd my_local_test_data && ./quick_test.sh 2>&1 | grep -E "(FAIL|ERROR)"

# Examine specific test logs  
find my_local_test_data -name "test.log" -exec grep -l "ERROR" {} \;

# Validate CWL syntax for specific workflow
cwltool --validate ../tools/deseq-lrt-step-1.cwl

# Debug execution with verbose output
cwltool --debug ../tools/deseq-lrt-step-1.cwl deseq_lrt_step_1/inputs/basic_test.yml

# Check Docker image availability
docker images | grep -E "biowardrobe2/scidap-(deseq|atac)"

# Memory and resource debugging
docker stats  # Monitor container resource usage during execution
```

**Error Classification for Faster Debugging:**
- **Quick Failures (< 5s)**: Path/config issues, directory problems
- **Script Errors (10-30s)**: R function/dependency issues, missing constants
- **Long Running Failures (> 30s)**: Statistical/resource issues, memory problems

## Key Architectural Patterns

### Function Sourcing Strategy
All R functions use a fallback pattern for sourcing dependencies:
```r
source_with_fallback("functions/common/utilities.R", "/usr/local/bin/functions/common/utilities.R")
```
This enables development in both Docker containers and local environments.

### Test Mode Integration
Most workflows support `test_mode=true` parameter for faster development:
- Reduces statistical iterations
- Uses smaller datasets
- Skips computationally expensive steps

### Input File Naming Convention
Test YAML files follow descriptive naming: `{workflow_type}_{step}_{scope}_{scenario}_{mode}.yml`
- Examples: 
  - `deseq_lrt_s1_workflow_standard_testmode.yml`
  - `atac_lrt_s1_workflow_interaction_testmode.yml`
  - `deseq_lrt_s2_workflow_dual_contrast_testmode.yml`
- All paths are relative to `core_data/` directory
- Test outputs organized in `quick_test/` and `comprehensive_test/` subdirectories

### Docker Development Strategy
- **Incremental builds**: New Docker versions extend previous versions for faster builds
- **Script mounting**: During development, mount local scripts instead of rebuilding containers
- **Test modes**: Use `test_mode=true` parameter to skip computationally expensive steps
- **Resource monitoring**: Monitor Docker container memory usage during large dataset processing
