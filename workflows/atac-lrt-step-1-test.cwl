cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement

inputs:
  test_peak_files:
    type: File[]
    label: "Peak files"

  peak_file_names:
    type: string[]
    label: "Peak file names"

  bam_files:
    type: File[]
    label: "BAM files"

  metadata_file:
    type: File
    label: "Metadata file"

  design_formula:
    type: string
    label: "Design formula"

  reduced_formula:
    type: string
    label: "Reduced formula"

  test_mode:
    type: boolean
    default: true

  lrt_only_mode:
    type: boolean
    default: true

  output_prefix:
    type: string
    default: "atac_lrt_step_1"

outputs:
  contrasts_table:
    type: File?
    outputSource: atac_lrt_step_1/contrasts_table

  stdout_log:
    type: File
    outputSource: atac_lrt_step_1/stdout_log

steps:
  atac_lrt_step_1:
    run: ../tools/atac-lrt-step-1.cwl
    in:
      test_peak_files: test_peak_files
      peak_file_names: peak_file_names
      bam_files: bam_files
      metadata_file: metadata_file
      design_formula: design_formula
      reduced_formula: reduced_formula
      test_mode: test_mode
      lrt_only_mode: lrt_only_mode
      output_prefix: output_prefix
    out:
      - contrasts_table
      - stdout_log
