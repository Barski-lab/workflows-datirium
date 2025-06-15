cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement

inputs:
  untreated_files:
    type: File[]
    label: "Untreated files"

  treated_files:
    type: File[]
    label: "Treated files"

  untreated_name:
    type: string
    default: "Control"
    label: "Untreated name"

  treated_name:
    type: string
    default: "Treatment"
    label: "Treated name"

  test_mode:
    type: boolean
    default: true

  output_prefix:
    type: string
    default: "atac_advanced"

outputs:
  diff_expr_file:
    type: File?
    outputSource: atac_advanced/diff_expr_file

  stdout_log:
    type: File
    outputSource: atac_advanced/stdout_log

steps:
  atac_advanced:
    run: ../tools/atac-advanced.cwl
    in:
      untreated_files: untreated_files
      treated_files: treated_files
      untreated_name: untreated_name
      treated_name: treated_name
      test_mode: test_mode
      output_prefix: output_prefix
    out:
      - diff_expr_file
      - stdout_log
