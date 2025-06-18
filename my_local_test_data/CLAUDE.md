# CWL Workflow Testing Guide

This file provides specific testing guidance for the my_local_test_data directory.

## Quick Testing Commands

```bash
# Primary testing commands (run from my_local_test_data/)
./quick_test.sh                    # Fast validation (2-3 min)
./comprehensive_test.sh            # Full test suite (10-15 min)

# Environment setup for Apple Silicon
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

## Test Structure

Each workflow has its own test directory:
- `deseq_lrt_step_1/` - DESeq2 LRT step 1 tests
- `deseq_lrt_step_2/` - DESeq2 LRT step 2 tests  
- `atac_lrt_step_1/` - ATAC-seq LRT step 1 tests
- `atac_lrt_step_2/` - ATAC-seq LRT step 2 tests
- `deseq_pairwise/` - Pairwise DESeq2 tests
- `atac_pairwise/` - Pairwise ATAC-seq tests

### Input Files
All input YAML files use **descriptive, self-documenting names** and **relative paths** to `core_data/`.

### Input File Naming Convention
Files follow the pattern: `{workflow_type}_{test_scope}_{test_scenario}_{complexity}.yml`

**Examples:**
- `deseq_lrt_s1_workflow_standard_testmode.yml` - DESeq2 LRT Step 1 standard workflow with test mode
- `atac_pairwise_workflow_rest_vs_active.yml` - ATAC pairwise comparison between Rest and Active conditions
- `deseq_lrt_s2_workflow_multicontrast_complex.yml` - DESeq2 LRT Step 2 with multiple contrasts and complex clustering

### Output Validation
Check these files for successful runs:
- `*_gene_exp_table.tsv` - Results tables
- `*_contrasts_table.tsv` - Statistical contrasts
- `*.gct` - Count matrices
- `*_mds_plot.html` - Quality control plots
- `test.log` - Execution logs

## Error Classification

**Quick Failures (< 5s):**
- Input file path issues
- Missing test data files
- YAML configuration errors

**Script Errors (10-30s):**
- R function errors
- Missing library dependencies
- Variable scoping issues

**Long Running Failures (> 30s):**
- Statistical computation errors
- Memory/resource issues
- Docker platform problems

## Docker Images

**Currently Active Images (CWL-Verified):**
- `biowardrobe2/scidap-deseq:v0.0.58` - DESeq2 workflows (confirmed working)
- `biowardrobe2/scidap-atac:v0.0.62-fixed` - ATAC workflows (latest available)

**Available Newer Versions:**
- `biowardrobe2/scidap-deseq:v0.0.54-58` - Multiple recent DESeq versions
- `biowardrobe2/scidap-atac:v0.0.60-62-fixed` - Multiple recent ATAC versions

**Platform Note:** Apple Silicon users will see platform warnings but workflows function correctly.

## Current Status: 6/6 Workflows Working (Last Updated: 2025-06-17)

**✅ All Workflows Confirmed Working:**
- **DESeq LRT Step 1** - Complete functionality
- **DESeq LRT Step 2** - Multi-contrast analysis
- **DESeq Pairwise** - Pairwise differential expression
- **ATAC LRT Step 1** - Test mode bypass functional
- **ATAC LRT Step 2** - Fixed MDS plot filename
- **ATAC Pairwise** - Fixed missing summary.md creation

**🧹 Infrastructure Cleanup Complete (2025-06-17):**
- ✅ Test directory cleaned: removed 8 redundant files
- ✅ All paths converted to relative references (`core_data/`, step outputs)
- ✅ Fixed ATAC metadata file paths to reference `core_data/`
- ✅ Consolidated test framework: `quick_test.sh`, `comprehensive_test.sh`
- ✅ Standardized parameter naming across workflows
- ✅ Renamed all input files to descriptive, self-documenting names

**Docker Images in Use:**
- DESeq workflows: `biowardrobe2/scidap-deseq:v0.0.62`
- ATAC workflows: `biowardrobe2/scidap-atac:v0.0.67`

## Debugging Commands

```bash
# Check specific test logs
find . -name "test.log" -exec grep -l "ERROR" {} \;

# Validate CWL syntax
cwltool --validate ../tools/[workflow-name].cwl

# Debug specific workflow
cwltool --debug ../tools/[workflow-name].cwl [workflow]/inputs/basic_test.yml
```