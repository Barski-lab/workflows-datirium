# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this CWL bioinformatics workflows repository.
This file provides guidance to Claude Code when working with this CWL bioinformatics workflows repository.

# UPDATE YOURSELF PROMPTLY
- If you notice any GAME-CHANGER (really efficient) way of optimize your work (through special commands / tools / approach / anything) - update that memory file to include it and to ease your next hours of work. Imagining you are saving a ton of time and so you will use it much better. 
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

### Workflow Status (Last Updated: 2025-06-27 17:15 - Post Docker Fixes)
✅ **Working (50%)**: DESeq LRT Step 1, DESeq LRT Step 2, ATAC LRT Step 1
❌ **Failing (50%)**: DESeq Pairwise, ATAC Pairwise, ATAC LRT Step 2

#### Remaining Issues Analysis
**1. DESeq Pairwise & ATAC Pairwise (Missing `*summary.md`)**
- **Technical Infrastructure**: ✅ FIXED - summary generation functions confirmed working
- **Statistical Issue**: ❌ Design matrix has same number of samples and coefficients 
- **Root Cause**: Insufficient replicates for dispersion estimation in DESeq2 v1.22+
- **Error**: "The design matrix has the same number of samples and coefficients to fit"

**2. ATAC LRT Step 2 (Missing `counts_all.gct`)**
- **Error**: "Did not find output file with glob pattern: ['counts_all.gct']"
- **Status**: Needs investigation - likely missing output generation in ATAC Step 2 workflow
- **Docker Image**: Using v0.0.70-fixed (latest)

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

### CRITICAL Docker + CWL Integration Pattern ⚠️
**Issue**: Local Docker builds create different tags than expected by CWL
**Pattern**: Always verify actual Docker image tags vs CWL references
**Solution**: 
1. Check actual image: `docker images | grep [image]`
2. Verify CWL references: `grep dockerPull tools/*.cwl`
3. Ensure exact match to avoid Docker Hub pull attempts
4. Use sed carefully: `sed -i '' 's/old-tag/new-tag/g' tools/*.cwl`
**Memory**: CWL will try to pull from Docker Hub if tag doesn't exist locally!

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

## Efficient AI Collaboration Strategies
- **Use systematic reasoning to break down complex tasks into manageable subtasks**
- **Always provide a clear, step-by-step implementation plan before coding**
- **Critique proposed approaches to identify potential inefficiencies or errors**
- **Focus on creating modular, reusable code with clear documentation**
- **Prioritize code quality, readability, and maintainability over rapid development**

## TESTING DIRECTORY MANAGEMENT
- Always check out testing directory after your actions or files added by another session to be reasonable. 
- Keep it clean and manageable. 
- Provide a reason and explain each file to be kept as really needed or remove it otherwise. 
- Use reasoning and critique before doing that.

## Development Guidelines for Systematic Improvement
- **Always start with critique and analyse using reasoning the last changes and overall flow.**
- **Make sure you understand what exactly you are doing now and why.**
- **Only then proceed with implementation.**
- **Sometimes you create a lot of redundant files - if they are temporarily clean then up after that.**
- **Start with one clear goal (like create a step-by-step plan, or follow it with point 2 etc).**
- **If you found some invaluable pattern which is slowing down your progress or understanding of my request and you can "shortcut it" - update your memory file IMMEDIATELY to save your and my time.**

## Docker and Build Management
- **Before creating script or build docker - ALWAYS make sure it is not created / updated yet. Plus, ALWAYS verify that you are using the latest docker version. If you do some changes in files that are going to be the part of the next version of the docker - IMMEDIATELY rebuild it with a new one and push.**

## CRITICAL CWL-TO-R INTEGRATION PATTERN 🚨

### DESeq Pairwise Argument Mapping (2025-06-30)
**Issue**: CWL parameter names MUST exactly match R CLI parser expectations
**Solution**: Always verify CWL `inputBinding.prefix` matches R `parser$add_argument()` names

| CWL Parameter | CWL Prefix | R Parser Expects | Status |
|---------------|------------|------------------|---------|
| `cluster_method` | `--cluster_method` | `--cluster_method` | ✅ Fixed |
| `row_distance` | `--row_distance` | `--row_distance` | ✅ Fixed |
| `column_distance` | `--column_distance` | `--column_distance` | ✅ Fixed |

**CRITICAL**: Never use shortened argument names in CWL if R expects full names!
- ❌ `--cluster` → R expects `--cluster_method`
- ❌ `--rowdist` → R expects `--row_distance`
- ❌ `--columndist` → R expects `--column_distance`

### CWL Input Validation Pattern 🔍
```bash
# GOLDEN VALIDATION SEQUENCE
cwltool --validate tools/[tool].cwl                    # 1. Syntax check
grep "inputBinding" tools/[tool].cwl | grep prefix     # 2. Extract CWL args
grep "add_argument" scripts/functions/*/cli_args.R     # 3. Check R parser
# Ensure EXACT match between CWL prefix and R argument names!
```

### DESeq LRT Input Requirements (2025-06-30)
**CRITICAL**: DESeq LRT Step 1 requires specific input format:
- ✅ `alias_trigger` (not `alias`) - for Step 1 workflows
- ✅ `metadata_file.format: "http://edamontology.org/format_2330"` - required format field
- ✅ All expression files need `format: "http://edamontology.org/format_3752"`

## GOLDEN PATTERNS FOR MAXIMUM EFFICIENCY ⭐

### Current Production Docker Images (2025-06-30) ✅
- **DESeq workflows**: `biowardrobe2/scidap-deseq:v0.0.72` (STABLE)
- **ATAC workflows**: `biowardrobe2/scidap-atac:v0.0.73` (STABLE)
- **Status**: All 6 workflows operational (100% success rate)

### Docker Tag Management Protocol 🏷️
1. **NEVER use -fixed, -test, or other suffixes in production**
2. **Always retag properly**: `docker tag old-tag:suffix new-tag:clean-version`
3. **Push clean tags**: `docker push biowardrobe2/scidap-[type]:v0.0.XX`
4. **Update CWL immediately**: `sed -i '' 's/old-tag/new-tag/g' tools/*.cwl`
5. **Clean up**: Remove outdated/suffixed tags with `docker rmi`

### Comprehensive Test Execution Strategy 🧪
```bash
# GOLDEN COMMAND SEQUENCE - Always use this pattern:
cd /Users/pavb5f/Documents/barskilab-workflows/my_local_test_data
./comprehensive_test.sh 2>&1 | tail -20  # Quick status
# OR for full analysis:
./comprehensive_test.sh > test_results.log 2>&1 && grep -A 10 "COMPREHENSIVE TEST SUMMARY" test_results.log
```

### File Cleanup Excellence Pattern 🧹
```bash
# GOLDEN CLEANUP SEQUENCE - Removes redundancy efficiently:
find . -type f \( -name "*.log" -o -name "*.rds" -o -name "*.gct" -o -name "*.html" -o -name "*.png" -o -name "*.pdf" \) | grep -v "core_data" | grep -v "inputs" | grep -v "outputs" | wc -l
# Then remove files NOT in proper outputs/ directories
rm -rf *_test_out/  # Remove redundant test directories
rm -f *.log *.rds *.tsv  # Remove loose files in root
```

### Multi-Session Coordination Protocol 🤝
- **ALWAYS check workflow-coordination.md status before starting**
- **Update coordination file immediately after major achievements**
- **Use TodoWrite tool for ALL multi-step tasks to track progress**
- **Mark todos completed IMMEDIATELY after finishing each task**

### Git Commit Excellence Pattern 📝
```bash
# GOLDEN COMMIT PATTERN - Always use this structure:
git add -A  # Stage all changes including deletions
git commit -m "$(cat <<'EOF'
[type]: [concise description]

- [Specific change 1 with why]
- [Specific change 2 with why]
- [Impact/status statement]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### CWL-Docker Integration Bulletproof Pattern 🛡️
1. **Check actual local images**: `docker images | grep scidap`
2. **Check CWL references**: `grep dockerPull tools/*.cwl`
3. **CRITICAL**: Ensure EXACT tag match to prevent Docker Hub pulls
4. **Batch update CWL files**: `sed -i '' 's/old-version/new-version/g' tools/[type]-*.cwl`
5. **Verify updates**: `grep dockerPull tools/[type]-*.cwl`

### Performance Optimization Shortcuts ⚡
- **ARM64 native speed**: `unset DOCKER_DEFAULT_PLATFORM` (3x faster)
- **Parallel operations**: Use multiple tool calls in single response
- **Efficient search**: Use Task tool for broad searches, direct tools for specific targets
- **Memory management**: Clean Docker regularly with `docker system prune -f`

### Error Diagnosis Lightning Speed ⚡
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
# GOLDEN ERROR PATTERN - Find issues instantly:
find . -name "test.log" -exec grep -l "FAILED\|ERROR\|Did not find output" {} \;
find . -name "*stderr.log" -path "*/outputs/*" -exec tail -5 {} \; -print

# CWL-R ARGUMENT MISMATCH DETECTION:
grep "prefix.*--" tools/[tool].cwl | grep -v "#"      # Extract CWL arguments
grep "add_argument.*--" scripts/functions/*/cli_args.R # Extract R arguments
# Compare lists - they MUST match exactly!
```

### Docker Version Consistency Check ⚡
```bash
# GOLDEN DOCKER VERSION AUDIT - Check all tools at once:
grep -r "dockerPull.*scidap-deseq" tools/ | grep -v "#"
grep -r "dockerPull.*scidap-atac" tools/ | grep -v "#"
# All DESeq tools MUST use same version (currently v0.0.72)
# All ATAC tools MUST use same version (currently v0.0.73)
```

## COMPACT EFFICIENCY PATTERNS 🚀

### Workflow Efficiency: Compact CLI Operations
- **Use `/compact` mode for maximum efficiency in CLI and workflow management**
- Automatically reduces verbosity and optimization overhead
- Enables fastest possible execution paths
- Minimizes intermediate file generation
- Prioritizes memory and computational efficiency
