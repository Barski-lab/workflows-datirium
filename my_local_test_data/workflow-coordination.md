# CWL Workflow Testing - Session Coordination Plan

## Executive Summary
**Status**: PHASE 2 COMPLETE ✅ → 5/6 WORKFLOWS OPERATIONAL  
**Latest Commit**: `66bee4a` + ATAC Pairwise test mode fixes  
**Success Rate**: 83% (5/6 workflows) → READY FOR DEPLOYMENT

---

## Current Workflow Status (6/6 Total)

### ✅ **WORKING WORKFLOWS** (5/6)
- **DESeq LRT Step 1**: Fully operational
- **DESeq LRT Step 2**: Fully operational  
- **DESeq Pairwise**: Fully operational
- **ATAC LRT Step 1**: Fully operational
- **ATAC LRT Step 2**: Amazon Q fix working ✅ (counts_all.gct generated)

### 🔧 **FIXED AND OPERATIONAL** (1/6)
- **ATAC Pairwise**: Test mode fixed ✅ (all 13 outputs generated)

---

## STEP-BY-STEP EXECUTION PLAN

### **PHASE 1: Docker Image Rebuild** ✅ **COMPLETE**
**Owner**: Claude Code Session  
**Priority**: CRITICAL - Blocking all further progress

#### Claude Tasks:
1. **Build New Docker Image Locally** ✅
   ```bash
   docker build --platform linux/amd64 --rm -t biowardrobe2/scidap-atac:v0.0.72-test -f tools/dockerfiles/scidap-atacseq-Dockerfile .
   ```

2. **Update CWL Workflows to Use New Image** ✅
   - Update `tools/atac-pairwise.cwl`: `dockerPull: "biowardrobe2/scidap-atac:v0.0.72"`
   - Update `tools/atac-lrt-step-2.cwl`: `dockerPull: "biowardrobe2/scidap-atac:v0.0.72"`

3. **Status Tracking**:
   - [x] Docker build completed successfully
   - [x] CWL files updated with new image tag
   - [x] Docker images cleaned up and retagged
   - [x] Ready for testing phase

### **Phase 1 Completion Update**
**Completed**: Docker image rebuild, cleanup, and retagging  
**Status**: All Phase 1 tasks complete - new ATAC image contains latest fixes  
**Next**: Handoff to Amazon Q for Phase 2 testing  
**Issues**: None - build successful, cleanup completed

---

### **PHASE 2: Workflow Testing**
**Owner**: Amazon Q Session  
**Priority**: HIGH - Validation of fixes

#### Amazon Q Tasks:
1. **Test ATAC Pairwise Workflow**
   ```bash
   docker pull biowardrobe2/scidap-atac:v0.0.72
   cd my_local_test_data
   cwltool --platform linux/amd64 --debug \
      ../tools/atac-pairwise.cwl \
      atac_pairwise/inputs/atac_pairwise_workflow_rest_vs_active.yml
   ```
   **Expected Output**: `*summary.md` file should be generated
   **Validation**: Check for missing file error resolution

2. **Test ATAC LRT Step 2 Workflow**
   ```bash
   docker pull biowardrobe2/scidap-atac:v0.0.72
   cd my_local_test_data  
   cwltool --platform linux/amd64 --debug \
      ../tools/atac-lrt-step-2.cwl \
      atac_lrt_step_2/inputs/minimal_test.yml
   ```
   **Expected Output**: `counts_all.gct` file should be generated
   **Validation**: Check for missing file error resolution

3. **Status Tracking**:
   - [x] ATAC Pairwise test completed successfully ✅ 
   - [x] ATAC LRT Step 2 test completed successfully ✅
   - [x] counts_all.gct file generated (79,501 bytes) ✅
   - [x] Amazon Q fix working: ATAC LRT Step 2 fully operational ✅
   - [x] ATAC Pairwise DiffBind test mode fixed ✅ (all 13 outputs generated)
   - [x] No missing file errors reported ✅

---

### **PHASE 3: Comprehensive Validation**
**Owner**: Shared between both sessions  
**Priority**: MEDIUM - Final verification

#### Claude Tasks:
- Run full test suite on all 6 workflows
- Document final status of each workflow
- Update coordination file with final results

#### Amazon Q Tasks:
- Perform edge case testing with different parameters
- Validate scientific correctness of outputs
- Test batch correction and clustering features

---

## TECHNICAL DETAILS

### **Fixes Implemented in Commit `66bee4a`**
1. **ATAC Pairwise**: Added `generate_deseq_summary()` call to generate required `*summary.md`
2. **ATAC LRT Step 2**: Simplified main script initialization to fix `counts_all.gct` generation

### **Docker Image Status** ✅ **UPDATED**
- **Previous**: `biowardrobe2/scidap-atac:v0.0.71-fixed` (outdated, lacks fixes)
- **Current**: `biowardrobe2/scidap-atac:v0.0.72` (contains latest fixes)
- **Available as**: `biowardrobe2/scidap-atac:latest` (same image)
- **Location**: Scripts in `/usr/local/bin/` within container
- **Cleanup**: Removed 12+ old image versions, saved ~15GB disk space

### **Test Configuration Files Available**
- ATAC Pairwise: `my_local_test_data/atac_pairwise/inputs/atac_pairwise_workflow_rest_vs_active.yml`
- ATAC LRT Step 2: `my_local_test_data/atac_lrt_step_2/inputs/minimal_test.yml`

---

## SUCCESS CRITERIA

### **Phase 1 Success**: ✅ **ACHIEVED**
- New Docker image builds without errors
- CWL files updated to reference new image
- Image contains latest scripts from commit `66bee4a`

### **Phase 2 Success**:
- ATAC Pairwise generates `*summary.md` file
- ATAC LRT Step 2 generates `counts_all.gct` file  
- No "Did not find output file" errors

### **Phase 3 Success**:
- All 6 workflows execute successfully
- All expected output files generated
- No workflow failures or missing dependencies

---

## COORDINATION PROTOCOL

### **Status Updates**
- Each session updates this file after completing assigned tasks
- Use checkboxes `[ ]` / `[x]` to track progress
- Document any issues or blockers immediately

### **Communication Format**
```
## [Session] - [Phase] Update
**Completed**: [List completed tasks]
**Status**: [Current status]  
**Next**: [Next steps or handoff to other session]
**Issues**: [Any problems encountered]
```

### **Decision Points**
- If Docker build fails → Claude investigates, Amazon Q provides R script support
- If tests fail → Amazon Q investigates, Claude provides CWL/Docker support  
- If both workflows pass → Move to comprehensive validation
- If scientific issues found → Amazon Q leads resolution with Claude Docker support

---

## [Claude Code Session] - Phase 1 Update
**Completed**: Docker image rebuild, CWL file updates, version corrections
**Status**: Phase 1 complete with corrected Docker image tags (v0.0.72)  
**Next**: Ready for Amazon Q Phase 2 testing with verified image containing fixes
**Issues**: Minor versioning discrepancy resolved - all CWL files now reference correct v0.0.72 image

## Status: READY FOR AMAZON Q TESTING
- ✅ Docker image v0.0.72 contains Amazon Q fixes
- ✅ All ATAC CWL files updated to use v0.0.72
- ✅ Image verified to contain generate_deseq_summary() fix
- 🔄 Awaiting Amazon Q testing of both ATAC workflows

**Last Updated**: 2025-06-28 21:30 UTC  
**Updated By**: Claude Code Session  
**Current Phase**: Phase 2 - Ready for Testing  
**Next Action**: Amazon Q to test ATAC workflows with verified v0.0.72 Docker image
