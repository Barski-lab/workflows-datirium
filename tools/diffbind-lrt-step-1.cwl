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

  alignment_files:
    type: File[]
    secondaryFiles:
    - .bai
    inputBinding:
      prefix: "--reads"

  peak_files:
    type: File[]
    inputBinding:
      prefix: "--peaks"

  alignment_names:
    type: string[]
    inputBinding:
      prefix: "--aliases"

  qvalue_threshold:
    type: float?
    inputBinding:
      prefix: "--qvalue"

  metadata_file:
    type: File
    inputBinding:
      prefix: "--metadata"

  group_variable:
    type:
    - "null"
    - string
    - string[]
    inputBinding:
      prefix: "--group"

  overlap_threshold:
    type: float?
    inputBinding:
      prefix: "--overlap"

  extend_distance:
    type: int?
    inputBinding:
      prefix: "--extend"

  rpkm_threshold:
    type: float?
    inputBinding:
      prefix: "--rpkm"

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

  annotation_tsv_file:
    type: File
    inputBinding:
      prefix: "--annotation"

  chrom_length_file:
    type: File
    inputBinding:
      prefix: "--seqinfo"

  genome_name:
    type: string
    inputBinding:
      prefix: "--genome"

  promoter_distance:
    type: int?
    inputBinding:
      prefix: "--promoter"

  upstream_distance:
    type: int?
    inputBinding:
      prefix: "--upstream"

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

  wald_test:
    type: boolean?
    inputBinding:
      prefix: "--wald"

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

  pk_vrlp_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputBinding:
      glob: "*_pk_vrlp_*.png"

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

  all_contrasts_rds:
    type: File?
    outputBinding:
      glob: "*_all_contrasts.rds"

  all_contrasts_tsv:
    type: File?
    outputBinding:
      glob: "*_all_contrasts.tsv"

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

baseCommand: [run_diffbind_lrt_step_1.sh]
stdout: error_msg.txt
stderr: diffbind_lrt_step_1_stderr.log