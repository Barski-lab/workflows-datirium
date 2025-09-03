cwlVersion: v1.0
class: CommandLineTool

hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/diff-tools:v0.0.1

inputs:

  expression_files:
    type: File[]
    inputBinding:
      prefix: "--expression"

  expression_names:
    type: string[]
    inputBinding:
      prefix: "--aliases"

  feature_type:
    type:
    - "null"
    - type: enum
      symbols:
      - "gene"
      - "isoform"
      - "tss"
    inputBinding:
      prefix: "--groupby"

  metadata_file:
    type: File
    inputBinding:
      prefix: "--metadata"

  design_formula:
    type: string
    inputBinding:
      prefix: "--design"

  reduced_formula:
    type: string
    inputBinding:
      prefix: "--reduced"

  batch_correction_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "combatseq"
      - "limma"
    inputBinding:
      prefix: "--correction"

  batch_correction_variable:
    type: string?
    inputBinding:
      prefix: "--batch"

  rpkm_threshold:
    type: float?
    inputBinding:
      prefix: "--rpkm"

  padj_threshold:
    type: float?
    inputBinding:
      prefix: "--padj"

  logfc_threshold:
    type: float?
    inputBinding:
      prefix: "--logfc"

  cluster_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "row"
      - "column"
      - "both"
    inputBinding:
      prefix: "--cluster"

  cluster_row_distance:
    type:
    - "null"
    - type: enum
      symbols:
      - "cosangle"
      - "abscosangle"
      - "euclid"
      - "abseuclid"
      - "cor"
      - "abscor"
    inputBinding:
      prefix: "--rowdist"

  cluster_col_distance:
    type:
    - "null"
    - type: enum
      symbols:
      - "cosangle"
      - "abscosangle"
      - "euclid"
      - "abseuclid"
      - "cor"
      - "abscor"
    inputBinding:
      prefix: "--columndist"

  cluster_max_depth:
    type: int?
    inputBinding:
      prefix: "--depth"

  cluster_max_branches:
    type: int?
    inputBinding:
      prefix: "--branches"

  wald_test:
    type: boolean?
    inputBinding:
      prefix: "--wald"

  output_prefix:
    type: string?
    inputBinding:
      prefix: "--output"

  threads:
    type: int?
    inputBinding:
      prefix: "--cpus"

outputs:

  mds_plot_html:
    type: File?
    outputBinding:
      glob: "*_mds_plot.html"

  summary_md:
    type: File
    outputBinding:
      glob: "*_summary.md"

  read_counts_gct:
    type: File?
    outputBinding:
      glob: "*_read_counts.gct"

  read_counts_html:
    type: File?
    outputBinding:
      glob: "*_read_counts.html"

  diff_expr_tsv:
    type: File
    outputBinding:
      glob: "*_diff_expr.tsv"

  all_contrasts_rds:
    type: File?
    outputBinding:
      glob: "*_all_contrasts.rds"

  all_contrasts_tsv:
    type: File?
    outputBinding:
      glob: "*_all_contrasts.tsv"

  human_log:
    type: File?
    outputBinding:
      glob: "error_report.txt"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr

baseCommand: [run_deseq_lrt_step_1.sh]
stdout: error_msg.txt
stderr: deseq_lrt_step_1_stderr.log