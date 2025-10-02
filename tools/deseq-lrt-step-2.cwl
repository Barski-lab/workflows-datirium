cwlVersion: v1.0
class: CommandLineTool

hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/diff-tools:v0.0.1

inputs:

  query_rds:
    type: File
    inputBinding:
      prefix: "--query"

  target_contrasts:
    type:
    - string
    - string[]
    inputBinding:
      prefix: "--target"

  padj_threshold:
    type: float?
    inputBinding:
      prefix: "--padj"

  logfc_threshold:
    type: float?
    inputBinding:
      prefix: "--logfc"

  strict:
    type: boolean?
    inputBinding:
      prefix: "--strict"

  alternative_hypothesis:
    type:
    - "null"
    - type: enum
      symbols:
      - "greater"
      - "less"
      - "greaterAbs"
    inputBinding:
      prefix: "--alternative"

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

  output_prefix:
    type: string?
    inputBinding:
      prefix: "--output"

  threads:
    type: int?
    inputBinding:
      prefix: "--cpus"

outputs:

  vlcn_png:
    type:
    - "null"
    - type: array
      items: File
    outputBinding:
      glob: "*_vlcn.png"

  read_counts_gct:
    type: File?
    outputBinding:
      glob: "*_read_counts.gct"

  read_counts_html:
    type: File?
    outputBinding:
      glob: "*_read_counts.html"

  volcano_plot_html:
    type: File?
    outputBinding:
      glob: "*_volcano_plot/html_data/index.html"

  volcano_plot_data:
    type: Directory?
    outputBinding:
      glob: "*_volcano_plot/html_data"

  ma_plot_html:
    type: File?
    outputBinding:
      glob: "*_ma_plot/html_data/index.html"

  ma_plot_data:
    type: Directory?
    outputBinding:
      glob: "*_ma_plot/html_data"

  diff_expr_tsv:
    type: File
    outputBinding:
      glob: "*_diff_expr.tsv"

  summary_md:
    type: File
    outputBinding:
      glob: "*_summary.md"

  human_log:
    type: File?
    outputBinding:
      glob: "error_report.txt"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr

baseCommand: [run_deseq_lrt_step_2.sh]
stdout: error_msg.txt
stderr: deseq_lrt_step_2_stderr.log