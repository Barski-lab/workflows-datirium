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
cd my_local_test_data && ./comprehensive_test.sh      # Full test suite (10-15 min)

# CWL development
cwltool --validate tools/[workflow-name].cwl          # Syntax validation
cwltool --debug tools/[workflow-name].cwl inputs.yml  # Debug execution

# Docker management
docker images | grep -E "(scidap|biowardrobe)"       # List workflow images

# Multi-arch Docker builds (ARM64 + AMD64 for HPC)
cd tools/dockerfiles
docker buildx create --use
docker buildx build --platform linux/arm64,linux/amd64 -t biowardrobe2/scidap-deseq:v0.0.XX --push -f scidap-deseq-Dockerfile ../..
docker buildx build --platform linux/arm64,linux/amd64 -t biowardrobe2/scidap-atac:v0.0.XX --push -f scidap-atacseq-Dockerfile ../..
docker buildx imagetools inspect biowardrobe2/scidap-deseq:v0.0.XX  # Verify platforms
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
- **Paths**: Use relative paths to core_data/ in CWL input YAML files
- **Parameters**: Use `--input_files` (not `--input`) for ATAC workflows
- **Always use descriptive variable names**
- **Never create a new version of script using "fixed/updated/final/enhanced/backup" or other suffixes. Work with the files that are already exists.**
- **After each reasonable (!!) changing do git commit with description of those changes also explaining the reason of that change.**
- **Before git push always using reasoning critique the changes making sure they are reasonable.**
- **Before git push check out that there's no large files (>150MB) that are loading into GitHub. Unstage them and add to .gitignore if there some.**
- **Always use lintr and other (like styler from R, cwltool --valid from cwltool) tools before git push to make sure scripts doesn't contain errors.**

### Docker and Dockerfile Management
- For all dockerfiles located at "barskilab-workflows/tools/dockerfiles":
  - NEVER create any dockerfile out of that directory
  - ALWAYS use those that are latest (check it out first) on docker hub
  - Rebuild docker images ALWAYS using the biowardrobe/... naming with following after previous versions
  - RScripts and bash scripts used by dockerfiles are located at "barskilab-workflows/tools/dockerfiles/scripts" directory
  - ALWAYS update all CWL tools (from "barskilab-workflows/tools" dir) with the latest dockerfile version if you updated it - using efficient CLI tools check out which tools uses that docker image and update with latest
  - FOCUS on updating scripts (Rscript / bash) rather than CWL tools (but do it if it's necessary)
  - ALWAYS check out if docker consists of reasonable layers and update if it's not efficient (but provide a reason first and critique)

### Git Push Guidelines
- **Before doing git push ALWAYS make sure using reasoning and critique your own changes to make sure that there's no redundancy.**
- **Redundancy must be removed - in scripts, in directories (files) - you MUST keep things clean, manageable and providing key functionality as a first priority.**
- **Focus on one thing per time - quality, not quantity matters.**
- **Always make sure you are following best practices of code / analysis.**
- **Get rid of "extra" stuff that only adds mess.**

## Development Methodology

### Implementation Planning
- **ALWAYS before starting to implement something create a step-by-step plan of manageable tasks - then critique it using reasoning chain-of-thoughts, then update plan and only then start to implement.**
- **ALWAYS provide a strong reason if some file has to be added or deleted.**
- **Critique the proposed approach and if it still looks valid - proceed with implementation.**

## Efficiency Guidelines

- **Use advanced approaches/tools of operating in terminal and scripts to do everything efficiently.**
- **If you are repeating same command several times - put it into bash script to easier re-running without typing each time.**

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

**Quick Diagnostics:**

```bash
# Check what's failing
cd my_local_test_data && ./quick_test.sh 2>&1 | grep -E "(FAIL|ERROR)"

# Examine specific test logs  
find my_local_test_data -name "test.log" -exec grep -l "ERROR" {} \;
```