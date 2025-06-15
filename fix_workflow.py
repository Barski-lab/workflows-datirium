#!/usr/bin/env python3

# Script to add missing BAM files parameter connection in ATAC workflow

def fix_workflow():
    workflow_file = 'workflows/atac-lrt-step-1-test.cwl'
    
    with open(workflow_file, 'r') as f:
        content = f.read()
    
    # Find the location after peak_file_names parameter
    old_section = '''      peak_file_names: peak_file_names
      metadata_file: metadata_file'''
    
    new_section = '''      peak_file_names: peak_file_names
      bam_files: bam_files
      metadata_file: metadata_file'''
    
    # Insert the BAM files parameter
    if 'bam_files: bam_files' not in content:
        new_content = content.replace(old_section, new_section)
        
        with open(workflow_file, 'w') as f:
            f.write(new_content)
        
        print("✅ Added BAM files parameter connection to ATAC workflow")
        print("🔧 Fixed the missing step parameter connection")
    else:
        print("❌ BAM files parameter connection already exists in workflow")

if __name__ == "__main__":
    fix_workflow() 