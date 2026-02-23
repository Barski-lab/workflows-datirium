cwlVersion: v1.0
class: CommandLineTool

hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/diff-tools:v0.0.3

requirements:
- class: ResourceRequirement
  ramMin: 61036       # 64GB
  coresMin: 6

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

  coverage_folder_in:
    type: Directory?
    inputBinding:
      prefix: "--coverage"

  export_density:
    type: boolean?
    inputBinding:
      prefix: "--density"

  flank_distance:
    type: int?
    inputBinding:
      prefix: "--flank"

  bin_size:
    type: int?
    inputBinding:
      prefix: "--binsize"

  bw_norm_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "consensus"
      - "filtered"
    inputBinding:
      prefix: "--bwnorm"

  output_prefix:
    type: string?
    inputBinding:
      prefix: "--output"

  threads:
    type: int?
    default: 6
    inputBinding:
      prefix: "--cpus"

outputs:

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
      glob: "*_volcano_plot"

  ma_plot_html:
    type: File?
    outputBinding:
      glob: "*_ma_plot/html_data/index.html"

  ma_plot_data:
    type: Directory?
    outputBinding:
      glob: "*_ma_plot"

  diff_access_tsv:
    type: File
    outputBinding:
      glob: "*_diff_access.tsv"

  all_cons_peaks_bed:
    type: File
    outputBinding:
      glob: "*_all_cons_peaks.bed"

  fltr_cons_peaks_bed:
    type: File?
    outputBinding:
      glob: "*_fltr_cons_peaks.bed"

  trgt_peaks_bed:
    type:
    - "null"
    - type: array
      items: File
    outputBinding:
      glob: "*_trgt_peaks_*.bed"

  coverage_folder_out:
    type: Directory?
    outputBinding:
      glob: "coverage"

  tag_dnst_score:
    type: File?
    outputBinding:
      glob: "*_tag_dnst_score.gz"

  tag_dnst_htmp_gct:
    type: File?
    outputBinding:
      glob: "*_tag_dnst_htmp.gct"

  tag_dnst_htmp_html:
    type: File?
    outputBinding:
      glob: "*_tag_dnst_htmp.html"

  summary_md:
    type: File
    outputBinding:
      glob: "*_summary.md"

  igv_html:
    type: File?
    outputBinding:
      glob: "*_igv.html"

  igv_json:
    type: File?
    outputBinding:
      glob: "*_igv.json"

  human_log:
    type: File?
    outputBinding:
      glob: "error_report.txt"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr

baseCommand: [run_diffbind_lrt_step_2.sh]
stdout: error_msg.txt
stderr: diffbind_lrt_step_2_stderr.log