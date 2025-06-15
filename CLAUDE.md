# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# CWL Bioinformatics Workflows - workflows-datirium

## Repository Architecture

This repository contains **ChIP-Seq, ATAC-Seq, RNA-Seq CWL workflows** for use in SciDAP/BioWardrobe platforms or standalone with cwltool. The architecture follows a **modular design**:

- **CWL Tools** (`tools/`) - Individual tool definitions that wrap R/Python scripts in Docker containers
- **CWL Workflows** (`workflows/`) - Complex pipelines that orchestrate multiple tools  
- **R Function Libraries** (`tools/dockerfiles/scripts/functions/`) - Modular, reusable R functions organized by workflow type
- **Entry Point Scripts** (`tools/dockerfiles/scripts/run_*.R`) - Main execution scripts that coordinate function libraries

### Core Workflow Types
- **DESeq2 LRT** - Likelihood ratio testing for differential expression (2-step process)
- **ATAC-seq LRT** - Differential chromatin accessibility analysis
- **Standard DESeq2** - Traditional pairwise differential expression
- **Single-cell workflows** - scRNA-seq, scATAC-seq processing pipelines

## Essential Commands

```bash
# Testing workflow (primary development task)
cd my_local_test_data && ./quick_test.sh              # Fast core tool tests
cd my_local_test_data && ./run_all_tests.sh           # Comprehensive tests

# CWL validation and execution
cwltool --validate tools/deseq-lrt-step-1.cwl         # Validate CWL syntax
cwltool tools/deseq-lrt-step-1.cwl inputs.yml         # Run individual tool

# Docker image management
docker images | grep -E "(scidap|biowardrobe)"       # Check available images
docker run --rm -v "$(pwd)/tools/dockerfiles/scripts:/usr/local/bin" biowardrobe2/scidap-deseq:v0.0.53 ls /usr/local/bin
```

## Development Workflow & Critical Rules

### R Script Development (Highest Priority)
The core logic resides in **modular R function libraries** organized by workflow type:
- `functions/common/` - Shared utilities (logging, visualization, clustering)
- `functions/deseq2_lrt_step_1/` - DESeq2 LRT step 1 specific functions
- `functions/atac_lrt_step_1/` - ATAC-seq LRT step 1 specific functions

**Entry point scripts** (`run_*.R`) coordinate these functions. Modify functions first, then entry points.

### Docker Image Architecture
Each workflow type uses specific Docker images:
- `biowardrobe2/scidap-deseq:v0.0.53` - DESeq2 workflows (✅ Working)
- `biowardrobe2/scidap-atac:v0.0.61-fixed` - ATAC workflows (🔧 Partially working)

### File Management Rules
#### ⚠️ NEVER
- Create files outside `my_local_test_data/` directory
- Use `--input` instead of `--input_files` for ATAC workflows
- Modify git-tracked CWL files without testing

#### ✅ ALWAYS  
- Rebuild Docker images after R script changes
- Run tests with `test_mode=true` for faster iteration
- Use absolute paths in CWL input YAML files

## Key Development Patterns

### CWL Extended Features (SciDAP Platform)
This repository uses **augmented CWL** with platform-specific extensions:
- `sd:metadata` - Dynamic form fields for UI generation
- `sd:upstream` - Workflow dependency graphs  
- `sd:visualPlugins` - Output visualization (line, pie, igvbrowser, syncfusiongrid)

### R Function Organization Pattern
```
run_deseq_lrt_step_1.R              # Entry point - sources workflow.R
└── functions/deseq2_lrt_step_1/
    ├── workflow.R                  # Main workflow orchestration
    ├── cli_args.R                  # Command line argument parsing
    ├── data_processing.R           # Data loading and validation
    ├── deseq2_analysis.R          # DESeq2-specific analysis
    └── contrast_generation.R      # Statistical contrast generation
```

### Common Issues & Debugging
- **ATAC workflows**: CLI parsing works, but "closure error" remains in R functions
- **Test mode**: Always use `test_mode=true` for faster development iterations  
- **Docker mounting**: Use script mounting for development instead of rebuilding images

## Current Status & Testing

### ✅ Working Components
- **DESeq2 LRT Step 1**: Fully functional, all tests pass
- **Test infrastructure**: `quick_test.sh` and `run_all_tests.sh` operational
- **Docker images**: `biowardrobe2/scidap-deseq:v0.0.53` functional

### 🔧 Partially Working
- **ATAC-seq LRT Step 1**: CLI parsing fixed, R closure error remains
- **Docker image**: `biowardrobe2/scidap-atac:v0.0.61-fixed` has improvements but incomplete

### Development Priority Order
1. **R function libraries** (`functions/*/`) - Core logic, highest impact
2. **Entry point scripts** (`run_*.R`) - Workflow coordination  
3. **CWL tools** (`tools/*.cwl`) - Interface definitions
4. **CWL workflows** (`workflows/*.cwl`) - Orchestration layer

## Testing & Debugging Commands

```bash
# Primary testing workflow
cd my_local_test_data
./quick_test.sh                        # Fast validation (2-3 min)
./run_all_tests.sh                     # Comprehensive testing (10-15 min)

# Individual debugging  
cwltool --validate tools/deseq-lrt-step-1.cwl
cwltool --debug tools/atac-lrt-step-1.cwl my_local_test_data/atac_lrt_step_1/inputs/basic_test.yml

# Check test logs
cat my_local_test_data/*/outputs/*/test.log
```

## Known Fixes & Common Issues

### ATAC-seq Workflows
- **CLI parsing**: Fixed `--input_files` parameter handling in `cli_args.R`
- **DiffBind constants**: Added missing constants in `constants.R` (DBA_CONDITION, DBA_DESEQ2, etc.)
- **Remaining issue**: "object of type 'closure' is not subsettable" error in R functions

### Common Debugging Patterns
- **File paths**: Use absolute paths in CWL input YAML files
- **Docker issues**: Check `docker images | grep scidap` for available images
- **Script development**: Mount scripts for testing instead of rebuilding Docker images
- **Test mode**: Always use `test_mode=true` for faster iteration

---

**Key Reference**: Complete testing documentation available in `my_local_test_data/README.md`