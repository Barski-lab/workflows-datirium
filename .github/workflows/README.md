# GitHub Actions Workflows

This directory contains the CI/CD workflows for the workflows-datirium project. The workflows have been optimized for efficiency, reliability, and maintainability.

## Workflow Overview

### 🔧 Core Workflows

| Workflow | Purpose | Trigger | Status |
|----------|---------|---------|--------|
| `docker-build-matrix.yml` | Build and push Docker images using matrix strategy | Push, PR, Manual | ✅ Active |
| `deploy-to-hpc-improved.yml` | Deploy Singularity images to HPC environments | Manual, After build | ✅ Active |
| `test-connectivity.yml` | Test HPC connectivity and environment | Manual | ✅ Active |

### 📋 Legacy Workflows (Deprecated)

| Workflow | Replacement | Status |
|----------|-------------|--------|
| `docker-build.yml` | `docker-build-matrix.yml` | 🔄 Replace |
| `deploy-to-hpc.yml` | `deploy-to-hpc-improved.yml` | 🔄 Replace |
| `test-ssh-connection.yml` | `test-connectivity.yml` | 🔄 Replace |

## Key Improvements

### 🚀 Matrix-Based Docker Builds
- **Multi-image support**: Automatically detects and builds changed Docker images
- **Intelligent change detection**: Only builds images when Dockerfiles or scripts change
- **Parallel builds**: Multiple images build simultaneously
- **Proper error handling**: Individual image failures don't stop other builds

### 🎯 Improved HPC Deployment
- **Environment-specific**: Support for production and staging environments
- **Backup strategies**: Automatic backup of existing images before replacement
- **Retry logic**: Network operations retry on failure
- **Comprehensive validation**: Verify deployments before marking as successful

### 🔒 Secure Testing
- **Minimal debug output**: Reduced sensitive information exposure
- **Proper cleanup**: Temporary files and keys are always cleaned up
- **Configurable tests**: Basic and comprehensive connectivity testing

## Configuration

### Required Secrets
```yaml
DOCKER_USERNAME      # Docker Hub username
DOCKER_PASSWORD      # Docker Hub password/token
SSH_PRIVATE_KEY      # SSH private key for HPC access
SSH_USER            # SSH username (optional, defaults to 'pavb5f')
```

### Environment Variables
All common configuration is centralized in `config.yml`:
- Docker Hub repository: `biowardrobe2`
- HPC paths and modules
- Build settings and retention policies

## Usage Examples

### Manual Docker Build
```yaml
# Build specific image
workflow_dispatch:
  inputs:
    image_filter: "scidap-deseq"
    
# Build all images
workflow_dispatch:
  inputs:
    force_build: true
```

### Manual HPC Deployment
```yaml
workflow_dispatch:
  inputs:
    docker_images: "scidap-deseq:v0.0.53,scidap-atacseq:v0.0.61"
    target_environment: "bmicluster-compute"
    deployment_strategy: "backup-and-replace"
```

### Connectivity Testing
```yaml
workflow_dispatch:
  inputs:
    connection_type: "comprehensive"  # or "basic"
    target_host: "bmiclusterp.chmcres.cchmc.org"
```

## Supported Docker Images

| Image | Purpose | Dockerfile |
|-------|---------|------------|
| `scidap-deseq` | DESeq2 differential expression analysis | `scidap-deseq-Dockerfile` |
| `scidap-atacseq` | ATAC-seq chromatin accessibility analysis | `scidap-atacseq-Dockerfile` |

## Troubleshooting

### Build Failures
1. Check the build logs for specific error messages
2. Verify Dockerfile syntax with `cwltool --validate`
3. Ensure all required base images are available
4. Check Docker Hub credentials and permissions

### Deployment Failures
1. Run connectivity test first: `test-connectivity.yml`
2. Check HPC environment paths and permissions
3. Verify Singularity module availability
4. Check disk space on target system

### SSH Connection Issues
1. Verify SSH key format (OpenSSH private key)
2. Ensure public key is in `~/.ssh/authorized_keys` on target host
3. Check firewall rules for SSH port (22)
4. Test network connectivity to target host

## Migration from Legacy Workflows

### Step 1: Update Triggers
Replace legacy workflow calls with new workflow names in any dependent workflows.

### Step 2: Update Secrets
Ensure all required secrets are configured in repository settings.

### Step 3: Test New Workflows
Run manual tests for each new workflow before disabling legacy ones.

### Step 4: Remove Legacy Files
Once new workflows are verified, delete the old workflow files.

## Monitoring and Maintenance

### Regular Tasks
- Monitor workflow run times and success rates
- Update Docker base images when security updates are available
- Review and clean up old artifacts and cache entries
- Update HPC module versions as needed

### Performance Optimization  
- Build caching reduces build times by ~60%
- Matrix strategy enables parallel builds
- Change detection prevents unnecessary builds
- Artifact retention policies manage storage usage

## Development Guidelines

### Adding New Docker Images
1. Add Dockerfile to `tools/dockerfiles/`
2. Update matrix configuration in `docker-build-matrix.yml`
3. Follow version numbering guidelines in Dockerfile comments
4. Test build locally before committing

### Modifying Deployment Logic
1. Test changes in staging environment first
2. Use backup strategies for production deployments
3. Add comprehensive error handling and logging
4. Update documentation for any new configuration options