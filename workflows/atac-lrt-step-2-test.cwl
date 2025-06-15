cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement

inputs:
  dsq_obj_data:
    type: File
    label: "DESeq object data"

  contrasts_table:
    type: File
    label: "Contrasts table"

  contrast_indices:
    type: string
    label: "Contrast indices"

  test_mode:
    type: boolean
    default: true

  output_prefix:
    type: string
    default: "atac_lrt_step_2"

outputs:
  diff_expr_files:
    type: File[]
    outputSource: atac_lrt_step_2/diff_expr_files

  mds_plots_html:
    type: File
    outputSource: atac_lrt_step_2/mds_plots_html

  counts_all_gct:
    type: File
    outputSource: atac_lrt_step_2/counts_all_gct

  stdout_log:
    type: File
    outputSource: atac_lrt_step_2/stdout_log

steps:
  atac_lrt_step_2:
    run: ../tools/atac-lrt-step-2.cwl
    in:
      dsq_obj_data: dsq_obj_data
      contrasts_table: contrasts_table
      contrast_indices: contrast_indices
      test_mode: test_mode
      output_prefix: output_prefix
    out:
      - diff_expr_files
      - mds_plots_html
      - counts_all_gct
      - stdout_log
