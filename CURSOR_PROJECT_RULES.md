# Cursor Project Rules & Documentation
## CWL Workflow Testing Environment for workflows-datirium

### CRITICAL CONTEXT OPTIMIZATION RULES

#### .cursorignore Configuration
- **ALWAYS use the .cursorignore file** to exclude large data files and non-essential directories
- **Focus context only on**: CWL files, R scripts, function files, and immediate test data
- **Exclude by default**: Large .csv files (>1MB), build artifacts, git history, unrelated workflows
- **Cost efficiency target**: Keep context under reasonable limits per conversation

#### File Modification Priority Order
1. **R Scripts** (`tools/dockerfiles/scripts/`) - Highest priority, core logic
2. **Function Libraries** (`tools/dockerfiles/scripts/functions/`) - High priority, modular components
3. **CWL Tools** (`tools/*.cwl`) - Medium priority, interface definitions
4. **CWL Workflows** (`workflows/*.cwl`) - Lower priority, orchestration only
5. **Docker configurations** - Only when necessary for environment issues

### TARGET WORKFLOWS (Focus Only On These)
- `workflows/deseq-lrt-step-1-test.cwl` - Primary target
- `workflows/deseq-lrt-step-2-test.cwl` - Secondary target  
- `workflows/deseq.cwl` - Standard workflow
- **NEVER modify** non-test workflows (without `-test` suffix)

### ERROR HANDLING PROTOCOL

#### Step 1: Identify Error Source
1. **CWL Syntax Errors**: Usually YAML formatting issues (indentation, colons)
2. **Docker/Container Errors**: Missing dependencies, path issues, permission problems
3. **R Script Errors**: Logic errors, missing packages, data format issues
4. **Data Format Errors**: File format mismatches, missing columns, encoding issues

#### Step 2: Fix at Appropriate Layer
YAML Syntax Error → Fix CWL file directly
Missing R Package → Update Dockerfile or R script
Logic Error → Fix R script or functions
Data Issue → Update test data or input validation

#### Step 3: Test Efficiently
- **Use test_mode=true** for rapid iteration (processes minimal data)
- **Mount scripts during development** instead of rebuilding Docker when possible
- **Run with --debug flag** to capture full error context
- **Create feature branch** for each major fix

### TESTING WORKFLOW PROTOCOL

#### Phase 1: Environment Validation
```bash
# Verify cwltool installation
cwltool --version

# Validate CWL syntax
cwltool --validate workflows/deseq-lrt-step-1-test.cwl

# Check Docker image availability  
docker images | grep scidap-deseq
```

#### Phase 2: Initial Test Run
```bash
# Run with debug and test mode
cwltool --debug workflows/deseq-lrt-step-1-test.cwl workflows/deseq-lrt-step-1-test-input-updated.yml
```

#### Phase 3: Error Analysis & Fix
1. **Capture full error log**
2. **Identify error type** (syntax, environment, logic, data)
3. **Create feature branch** if major changes needed
4. **Fix at appropriate layer** following priority order
5. **Test fix in isolation**

#### Phase 4: Validation
- Test with different parameter combinations
- Verify outputs are scientifically correct
- Check test_mode reduces runtime significantly
- Validate batch correction scenarios

### DOCKER MANAGEMENT STRATEGY

#### Development Mode (Faster)
```bash
# Mount updated scripts to avoid rebuild
docker run -v /path/to/local/script:/usr/local/bin/script biowardrobe2/scidap-deseq:v0.0.32
```

#### Production Mode (CI/CD)
- Commit changes to trigger automated Docker builds
- Use `.github/docker-build.yml` for automated building
- Only merge after complete validation

### GIT WORKFLOW RULES

#### Branching Strategy
```bash
# Create feature branch for each major change
git checkout -b fix-deseq-lrt-step1-yaml-syntax

# Commit frequently with descriptive messages
git commit -m "fix: correct YAML indentation in deseq-lrt-step-1.cwl line 9"

# Merge only after complete validation
git checkout master && git merge fix-deseq-lrt-step1-yaml-syntax
```

#### Commit Message Format
fix: brief description of what was fixed
feat: brief description of new feature
refactor: brief description of code restructuring
docs: brief description of documentation changes
test: brief description of testing changes

### COST OPTIMIZATION STRATEGIES

#### Context Management
- **Always check .cursorignore** before starting conversations
- **Exclude test results** and temporary files
- **Focus on relevant files only** for current issue
- **Use parallel tool calls** when reading multiple files

#### Efficient Development
- Use `test_mode=true` to reduce processing time
- Mount scripts during development to avoid Docker rebuilds
- Run validation checks before full workflow execution
- Cache Docker layers effectively

### COMMON ERROR PATTERNS & SOLUTIONS

#### YAML Syntax Errors
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

#### R Script Errors
- **Missing packages**: Update Dockerfile with install commands
- **Path issues**: Use absolute paths in CWL baseCommand
- **Memory issues**: Increase Docker memory limits
- **Test mode**: Ensure R scripts respect test_mode parameter

#### Data Format Issues
- **CSV header mismatch**: Verify column names match expected format
- **Sample name consistency**: Ensure metadata matches expression file names
- **File path issues**: Use absolute paths in input YAML files

### TESTING DATA REQUIREMENTS

#### Current Test Data (my_local_test_data/)
- 8 samples: 2 treatments (C, KO) × 2 conditions (Rest, Act) × 2 replicates
- Sufficient for basic DESeq2 LRT testing
- May need additional samples for complex interaction testing

#### Required File Format
```csv
RefseqId,GeneId,Chrom,TxStart,TxEnd,Strand,TotalReads,Rpkm
```

#### Metadata Format
```csv
sampleID,treatment,cond
SAMPLE_NAME,TREATMENT_GROUP,CONDITION
```

### VALIDATION CHECKLIST

#### Before Each Run
- [ ] Input file paths are correct and files exist
- [ ] Metadata sample names match expression file names exactly  
- [ ] Design formula syntax is valid R formula
- [ ] Docker image is available locally or remotely
- [ ] .cursorignore is optimized for current task

#### After Each Successful Run
- [ ] Output files are generated in expected format
- [ ] Log files contain no unexpected errors or warnings
- [ ] Results are scientifically plausible
- [ ] Test mode significantly reduces runtime vs normal mode
- [ ] All parameter combinations work correctly

### ENHANCEMENT OPPORTUNITIES (Future)

#### Visualization Improvements
- Add more interactive plots and charts
- Include pathway enrichment visualizations
- Generate summary reports in multiple formats

#### Robustness Improvements  
- Better error handling and user feedback
- Input validation before processing
- Automatic parameter optimization

#### Performance Optimizations
- Parallel processing where applicable
- Memory usage optimization for large datasets
- Caching of intermediate results

### SCIENTIFIC VALIDATION RULES

#### Statistical Methods
- **Always verify** DESeq2 parameters are appropriate for experimental design
- **Check normalization** methods are suitable for data type
- **Validate multiple testing correction** is properly applied
- **Ensure adequate replication** for statistical power

#### Result Interpretation
- **Log fold change thresholds** should be biologically meaningful
- **P-value cutoffs** should be appropriate for discovery vs validation
- **Batch effects** should be properly corrected when present
- **Interaction terms** should be interpreted correctly in LRT context

### EMERGENCY PROCEDURES

#### If Cursor Context Becomes Too Large
1. **Immediately check .cursorignore** and add exclusions
2. **Focus on single file** at a time
3. **Use file_search instead of reading entire files**
4. **Break conversation and restart** with optimized context

#### If Tests Keep Failing
1. **Step back to validate basics**: CWL syntax, Docker availability, file paths
2. **Test individual components**: R scripts, functions, data formats
3. **Use minimal test data** to isolate issues
4. **Create clean feature branch** and start systematic fixes

#### If Docker Issues Persist
1. **Check image availability**: `docker images | grep scidap`
2. **Try manual docker run** to test script execution
3. **Mount local scripts** to test without rebuilding
4. **Verify CI/CD pipeline** is functioning correctly

---

**REMEMBER**: Always maintain scientific rigor while optimizing for development efficiency. Each fix should be tested thoroughly before proceeding to the next component.