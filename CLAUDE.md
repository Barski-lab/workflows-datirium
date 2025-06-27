# CLAUDE.md

This file provides guidance to Claude Code when working with this CWL bioinformatics workflows repository.

# UPDATE YOURSELF PROMPTLY
- If you notice any GAME-CHANGER (really efficient) way of optimize your work (through special commands / tools / approach / anything) - update that memory file to include it and to ease your next hours of work. Imaging you are saving a ton of time and so you will use it much better. 
- Use those tips to even more enhance it: https://cursorintro.com/best-practices

## Key Principles
- **Minimalistic approach**: Don't create unnecessary files - explain why each file is required
- **Relative paths**: Always use relative paths unless absolute paths are mandatory
- **Modern R practices**: Use tidyverse, explicit `package::function()` calls, conflicted package for namespace management
- **Advanced CLI tools**: Use efficient terminal tools for file manipulation and navigation

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
docker image prune -f                                 # Clean dangling images
unset DOCKER_DEFAULT_PLATFORM                         # Use native ARM64 for 3x performance

# Multi-arch Docker builds (ARM64 + AMD64 for HPC)
cd tools/dockerfiles
docker buildx create --use
docker buildx build --platform linux/arm64,linux/amd64 -t biowardrobe2/scidap-deseq:v0.0.XX --push -f scidap-deseq-Dockerfile ../..
docker buildx build --platform linux/arm64,linux/amd64 -t biowardrobe2/scidap-atac:v0.0.XX --push -f scidap-atacseq-Dockerfile ../..
docker buildx imagetools inspect biowardrobe2/scidap-deseq:v0.0.XX  # Verify platforms

# Error diagnosis shortcuts
find . -name "*stderr.log" -path "*/outputs/*" -exec tail -10 {} \; -print  # Check recent errors
grep -r "ERROR\|FAILED" */outputs/*/test.log          # Find failed tests
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
- **Docker**: Use latest fixed images - `biowardrobe2/scidap-deseq:v0.0.66-fixed`, `biowardrobe2/scidap-atac:v0.0.68-fixed`
- **Paths**: Use relative paths to core_data/ in CWL input YAML files
- **Path validation**: Before testing, check input YAML files for correct relative paths (../../core_data/ not ../core_data/)
- **Test data completeness**: Verify core_data/ has all required files: *.csv, *.bam, contrasts_table_example.csv, diffbind_results.rds
- **Always use descriptive variable names**
- **Never create a new version of script using "fixed/updated/final/enhanced/backup" or other suffixes. Work with the files that are already exists.**
- **After each reasonable (!!) changing do git commit with description of those changes also explaining the reason of that change.**
- **Before git push always using reasoning critique the changes making sure they are reasonable.**
- **Before git push check out that there's no large files (>150MB) that are loading into GitHub. Unstage them and add to .gitignore if there some.**
- **Always use lintr and other (like styler from R, cwltool --valid from cwltool) tools before git push to make sure scripts doesn't contain errors.**

### Common Error Prevention
- **Missing output files**: Common issue is missing `*summary.md` files for pairwise workflows - ensure `generate_deseq_summary()` is called in workflow functions
- **CWL output collection**: Use proper glob patterns and verify output file naming matches CWL expectations
- **Docker platform**: Use `unset DOCKER_DEFAULT_PLATFORM` for native ARM64 performance (~3x faster)
- **Test file creation**: Use Write tool for complex files, simple echo for basic files
- **Output verification**: Use `verify_outputs()` function with correct workflow type ("deseq", "lrt_step1", "lrt_step2")

## RECENT CRITICAL FIXES (2025-06-27)

### Docker Images with Fixed Output Generation
- **DESeq workflows**: `biowardrobe2/scidap-deseq:v0.0.66-fixed` 
- **ATAC workflows**: `biowardrobe2/scidap-atac:v0.0.68-fixed`
- **Key fix**: Added `generate_deseq_summary()` calls to both DESeq2 and EdgeR workflows
- **Verification**: Updated workflow types in main entry scripts

### CWL Tools Updated (2025-06-27)
All CWL tools now reference fixed Docker images:
- `deseq-pairwise.cwl` → v0.0.66-fixed
- `deseq-lrt-step-1.cwl` → v0.0.66-fixed  
- `deseq-lrt-step-2.cwl` → v0.0.66-fixed
- `atac-lrt-step-2.cwl` → v0.0.68-fixed
- `atac-pairwise.cwl` → v0.0.68-fixed

### Workflow Status (Last Updated: 2025-06-27)
✅ **Working**: DESeq LRT Step 1, DESeq LRT Step 2
🔧 **Fixed (pending verification)**: DESeq Pairwise, ATAC Pairwise, ATAC LRT Step 2
- **Root cause resolved**: Missing `*summary.md` output files in pairwise workflows
- **Technical solution**: Enhanced R workflow functions with proper summary generation

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

## Docker Management

### Docker Optimization Workflow
```bash
# ALWAYS run this sequence when working with Docker:
docker images | grep -E "(scidap|biowardrobe)" | head -20  # Check current images
docker image prune -f                                       # Remove dangling images
docker system df                                           # Check disk usage
unset DOCKER_DEFAULT_PLATFORM                              # Ensure native ARM64 performance
```

### Docker Platform Strategy
- **Local Development**: Use native ARM64 images (3x faster, `unset DOCKER_DEFAULT_PLATFORM`)
- **HPC Deployment**: Build multi-arch images with buildx (AMD64 + ARM64)
- **Never force platform** unless specifically building for HPC deployment

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

### Systematic Error Diagnosis
```bash
# 1. Quick test status check
cd my_local_test_data && ./comprehensive_test.sh 2>&1 | grep -A 20 "COMPREHENSIVE TEST SUMMARY"

# 2. Find specific errors
find . -name "*stderr.log" -path "*/outputs/*" -exec tail -10 {} \; -print
grep -r "ERROR\|FAILED\|permanentFail" */outputs/*/test.log

# 3. Check missing files patterns
find . -name "test.log" -exec grep -l "No such file or directory" {} \;
find . -name "test.log" -exec grep -l "Did not find output file" {} \;
```

### Common Error Categories

**Path Resolution Errors:**
- Input YAML files using wrong relative paths (../core_data/ vs ../../core_data/)
- Missing input files in core_data/ directory
- **Quick Fix**: Check all YAML files with `grep -r "path.*\.\." */inputs/`

**Missing Output Files:**
- R scripts not generating required summary.md or .gct files
- **Pattern**: "Did not find output file with glob pattern"
- **Fix**: Ensure `generate_deseq_summary()` is called in workflow functions and verify output file naming

**Docker Platform Issues:**
- DOCKER_DEFAULT_PLATFORM causing 3x slower emulated execution
- **Fix**: Always run `unset DOCKER_DEFAULT_PLATFORM` before testing

**File Creation Guidelines:**
```bash
# Minimal test files (use echo)
echo "header1,header2" > simple_file.csv

# Complex files (use Write tool)
# For RDS, BAM, or structured data files
```

## Development Philosophy

### Minimalistic Style and Modular Design
- Always keep minimalistic style - don't create a lot of new files if only it is not indeed required (and you have to explain and prove it at least to yourself). 
- Same logic works for individual scripts - keep it minimalistic with all modular functions.
- Functions must be manageable and clear. 
- One function - one purpose.

### R Development Best Practices
- Always make sure script is using efficient and advanced libraries / methods. It's often a trouble with out-of-date. Especially things in R like tidyverse, Seurat and so on. 
- Always use the :: to clarify what package the function calls from. 
- Don't forget about the conflicted package - ideally you need to use it with one file for several functions for example.