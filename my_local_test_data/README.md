# CWL Workflow Testing Environment

## CRITICAL RULES FOR TESTING
⚠️ **NEVER create files outside `my_local_test_data/` directory**  
⚠️ **ALWAYS check if files exist before creating new ones**  
⚠️ **MUST rebuild Docker images after script changes**

## Testing Pipeline Overview

The testing workflow follows this sequence:
1. **Run CWL tests** → Get errors
2. **Update core scripts** in `../tools/dockerfiles/scripts/`
3. **Rebuild Docker images** (deseq: `biowardrobe2/scidap-deseq`, atacseq: `biowardrobe2/scidap-atac`)
4. **Re-run tests** → Repeat until success

## Directory Structure

```
my_local_test_data/
├── README.md                    # This file - main testing documentation
├── core_data/                   # Shared test datasets
│   ├── *.isoforms.csv          # Expression data files
│   ├── metadata.csv            # Sample metadata
│   └── batch_file.csv          # Batch correction info
├── deseq_lrt_step_1/           # DESeq2 LRT Step 1 tests
│   ├── inputs/                 # Test input files (.yml configs)
│   ├── outputs/                # Test outputs (git-ignored)
│   └── scripts/                # Test helper scripts
├── deseq_lrt_step_2/           # DESeq2 LRT Step 2 tests
├── deseq_standard/             # Standard DESeq2 tests
├── atac_lrt_step_1/            # ATAC-seq LRT Step 1 tests
├── atac_lrt_step_2/            # ATAC-seq LRT Step 2 tests
├── atac_standard/              # Standard ATAC-seq tests
├── quick_test.sh               # Fast individual test runner
└── run_all_tests.sh            # Complete test suite runner
```

## Quick Start Testing

### 1. CWL Tool Testing (Start Here)
```bash
# Validate CWL syntax first
cwltool --validate ../tools/deseq-lrt-step-1.cwl
cwltool --validate ../tools/atac-lrt-step-1.cwl

# Test individual CWL tools
cd my_local_test_data/deseq_lrt_step_1
cwltool --debug ../../tools/deseq-lrt-step-1.cwl inputs/basic_test.yml
```

### 2. Workflow Testing
```bash
# Test complete workflows
cwltool --debug ../../workflows/deseq-lrt-step-1-test.cwl inputs/basic_test.yml
```

### 3. Docker Image Management
```bash
# Check current images
docker images | grep -E "(scidap-deseq|scidap-atac)"

# Rebuild after script changes (requires repository access)
# This should be done through CI/CD pipeline
```

## Test Data Requirements

### DESeq2 Tests
- **Expression files**: `*.isoforms.csv` with columns: RefseqId, GeneId, Chrom, TxStart, TxEnd, Strand, TotalReads, Rpkm
- **Metadata**: CSV with columns: sampleID, treatment, cond
- **8 samples**: 2 treatments × 2 conditions × 2 replicates

### ATAC-seq Tests  
- **Peak files**: `*_peaks.csv` with peak coordinates
- **BAM files**: `*.bam` alignment files
- **Metadata**: CSV with sample information
- **4+ samples**: Sufficient for differential accessibility analysis

## Known Fixes Applied (Critical Information)

### ATAC-seq CLI Argument Parsing Fix
**Problem**: Missing `--input_files` parsing in manual CLI fallback  
**Solution Applied**: Added missing input_files parsing in `cli_args.R`:
```r
# Added missing input_files parsing in manual fallback
input_idx <- which(all_args == "--input_files")
if (length(input_idx) > 0) {
  start_idx <- input_idx[1] + 1
  end_idx <- start_idx
  while (end_idx <= length(all_args) && !startsWith(all_args[end_idx], "--")) {
    end_idx <- end_idx + 1
  }
  args$input_files <- all_args[start_idx:(end_idx - 1)]
}
```

### Boolean Flag Parsing Fix  
**Problem**: CWL boolean argument handling incompatible with R scripts  
**Solution Applied**: Fixed CWL boolean argument handling in `cli_args.R`:
```r
# Handle both --flag and --flag TRUE/FALSE formats
for (flag in boolean_flags) {
  flag_idx <- which(all_args == flag_name)
  if (length(flag_idx) > 0) {
    if (flag_idx[1] < length(all_args) && !startsWith(all_args[flag_idx[1] + 1], "--")) {
      val <- all_args[flag_idx[1] + 1]
      args[[flag]] <- toupper(val) == "TRUE"
    } else {
      args[[flag]] <- TRUE
    }
  }
}
```

### DiffBind Constants Fix
**Problem**: Missing DiffBind constants causing ATAC-seq failures  
**Solution Applied**: Added missing constants in `constants.R`:
```r
# DiffBind constants (required for ATAC-seq analysis)
DBA_CONDITION <- 4         # DiffBind condition constant
DBA_DESEQ2 <- "DESeq2"     # DiffBind DESeq2 method constant (string!)
DBA_SCORE_READS <- 1       # DiffBind score type: raw reads
DBA_SCORE_RPKM <- 1        # DiffBind score type: RPKM
DBA_SCORE_TMM_MINUS_FULL <- 6  # DiffBind score type: TMM normalized
```

## Common Issues & Solutions

### Error: "File not found"
- ✅ **Fix**: Update file paths in `.yml` input files to use absolute paths
- ✅ **Check**: Ensure test data files exist in expected locations

### Error: "Docker image not found"
- ✅ **Fix**: Rebuild Docker images or use script mounting for development
- ✅ **Check**: `docker images | grep scidap`

### Error: "R script failure"
- ✅ **Fix**: Update scripts in `../tools/dockerfiles/scripts/`
- ✅ **Must**: Rebuild Docker image after script changes
- ✅ **Test**: Mount scripts during development to avoid rebuilds

### Error: "CLI argument parsing"
- ✅ **Fix**: Update `cli_args.R` functions for proper CWL argument handling
- ✅ **Check**: Boolean flags need special handling for CWL compatibility

### Error: "YAML Syntax Errors"
**Common patterns and fixes**:
```yaml
# WRONG (missing space after colon)
hints:
- class: DockerRequirement
    dockerPull: "image:tag"

# CORRECT (proper indentation)
hints:
  - class: DockerRequirement
    dockerPull: "image:tag"
```

## Development Workflow

### Script Development Mode (Fast)
```bash
# Mount updated scripts to avoid Docker rebuilds
docker run --rm \
  -v "$(pwd)/../tools/dockerfiles/scripts:/usr/local/bin" \
  -v "$(pwd)/inputs:/data" \
  biowardrobe2/scidap-deseq:latest \
  Rscript /usr/local/bin/run_deseq_lrt_step_1.R --args...
```

### Production Mode (Complete)
1. **Update scripts** in `../tools/dockerfiles/scripts/`
2. **Commit changes** to trigger Docker rebuild
3. **Test with new image** using CWL workflows
4. **Validate outputs** are scientifically correct

## Testing Commands Reference

### Individual Tests
```bash
# Quick DESeq2 test
./quick_test.sh deseq_lrt_step_1

# Quick ATAC-seq test  
./quick_test.sh atac_lrt_step_1

# All tests
./run_all_tests.sh
```

### Debug Mode
```bash
# Full debug output
CWLTOOL_OPTS="--debug" ./run_all_tests.sh

# Single test with debug
cwltool --debug ../../tools/deseq-lrt-step-1.cwl inputs/basic_test.yml
```

## Success Criteria

### For Each Test:
- ✅ CWL validation passes
- ✅ Docker container runs without errors  
- ✅ Expected output files are generated
- ✅ Log files show no unexpected errors
- ✅ Results are scientifically plausible

### For Complete Pipeline:
- ✅ All workflow types function correctly
- ✅ `test_mode=true` reduces runtime significantly  
- ✅ Different parameter combinations work
- ✅ Batch correction scenarios function properly

## File Management Rules

### ✅ ALLOWED:
- Update existing `.yml` input files
- Create new test cases in existing structure
- Add output directories (git-ignored)
- Update helper scripts within `my_local_test_data/`

### ❌ FORBIDDEN:
- Create files outside `my_local_test_data/`
- Create new documentation files in root directory
- Modify git-tracked files without explicit approval
- Create temporary directories in root

## File Modification Priority Order (CRITICAL)
1. **R Scripts** (`../tools/dockerfiles/scripts/`) - **Highest priority**, core logic
2. **Function Libraries** (`../tools/dockerfiles/scripts/functions/`) - **High priority**, modular components
3. **CWL Tools** (`../tools/*.cwl`) - Medium priority, interface definitions
4. **CWL Workflows** (`../workflows/*.cwl`) - Lower priority, orchestration only
5. **Docker configurations** - Only when necessary for environment issues

## Scientific Validation Requirements
### Statistical Methods
- **Always verify** DESeq2 parameters are appropriate for experimental design
- **Check normalization** methods are suitable for data type
- **Validate multiple testing correction** is properly applied
- **Ensure adequate replication** for statistical power

### Result Interpretation
- **Log fold change thresholds** should be biologically meaningful
- **P-value cutoffs** should be appropriate for discovery vs validation
- **Batch effects** should be properly corrected when present
- **Interaction terms** should be interpreted correctly in LRT context

## Cost Optimization Rules
### Context Management
- **Always check .cursorignore** before starting conversations
- **Exclude test results** and temporary files from context
- **Focus on relevant files only** for current issue
- **Use parallel tool calls** when reading multiple files

### Efficient Development
- Use `test_mode=true` to reduce processing time
- Mount scripts during development to avoid Docker rebuilds
- Run validation checks before full workflow execution
- Cache Docker layers effectively

## Git Workflow Rules
### Branching Strategy
```bash
# Create feature branch for each major change
git checkout -b fix-deseq-lrt-step1-yaml-syntax

# Commit frequently with descriptive messages
git commit -m "fix: correct YAML indentation in deseq-lrt-step-1.cwl line 9"

# Merge only after complete validation
git checkout master && git merge fix-deseq-lrt-step1-yaml-syntax
```

### Commit Message Format
- `fix:` brief description of what was fixed
- `feat:` brief description of new feature  
- `refactor:` brief description of code restructuring
- `docs:` brief description of documentation changes
- `test:` brief description of testing changes

## Emergency Procedures
### If Tests Keep Failing
1. **Step back to validate basics**: CWL syntax, Docker availability, file paths
2. **Test individual components**: R scripts, functions, data formats
3. **Use minimal test data** to isolate issues
4. **Create clean feature branch** and start systematic fixes

### If Docker Issues Persist
1. **Check image availability**: `docker images | grep scidap`
2. **Try manual docker run** to test script execution
3. **Mount local scripts** to test without rebuilding
4. **Verify CI/CD pipeline** is functioning correctly

### If Context Becomes Too Large
1. **Immediately check .cursorignore** and add exclusions
2. **Focus on single file** at a time
3. **Use file_search instead of reading entire files**
4. **Break conversation and restart** with optimized context

## Current Testing Status

### ✅ WORKING:
- DESeq2 LRT Step 1: Fully functional
- DESeq2 LRT Step 2: Fully functional
- Basic CWL validation: All tools validated

### 🔧 IN PROGRESS:
- ATAC-seq workflows: CLI parsing fixes applied
- Docker integration: Requires image rebuilds

### 📋 TODO:
- Complete ATAC-seq testing validation
- Extend test coverage for edge cases
- Document scientific validation procedures

---
**Remember**: Always start with CWL tool testing, then proceed to workflow testing. Update scripts → rebuild Docker → test → repeat.