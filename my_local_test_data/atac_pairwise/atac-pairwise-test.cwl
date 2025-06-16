cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement

inputs:
  untreated_files:
    type: File[]
    label: "Untreated condition peak files"

  treated_files:
    type: File[]
    label: "Treated condition peak files"

  untreated_name:
    type: string?
    label: "Name for untreated condition"
    default: "Untreated"

  treated_name:
    type: string?
    label: "Name for treated condition"
    default: "Treated"

  untreated_sample_names:
    type: string[]?
    label: "Sample names for untreated files"

  treated_sample_names:
    type: string[]?
    label: "Sample names for treated files"

  fdr:
    type: float?
    label: "FDR threshold"
    default: 0.1

  lfcthreshold:
    type: float?
    label: "Log2 fold change threshold"
    default: 0.59

  use_lfc_thresh:
    type: boolean
    label: "Use LFC threshold in testing"
    default: false

  regulation:
    type:
      - "null"
      - type: enum
        symbols: ["both", "up", "down"]
    label: "Regulation direction"
    default: "both"

  batchcorrection:
    type:
      - "null"
      - type: enum
        symbols: ["none", "combatseq", "model"]
    label: "Batch correction method"
    default: "none"

  scaling_type:
    type:
      - "null"
      - type: enum
        symbols: ["minmax", "zscore"]
    label: "Scaling method"
    default: "zscore"

  cluster_method:
    type:
      - "null"
      - type: enum
        symbols: ["row", "column", "both"]
    label: "Clustering method"

  row_distance:
    type:
      - "null"
      - type: enum
        symbols: ["cosangle", "abscosangle", "euclid", "cor", "abscor"]
    label: "Row distance metric"

  column_distance:
    type:
      - "null"
      - type: enum
        symbols: ["cosangle", "abscosangle", "euclid", "cor", "abscor"]
    label: "Column distance metric"

  k_hopach:
    type: int?
    label: "Hopach clustering depth"
    default: 3

  kmax_hopach:
    type: int?
    label: "Maximum Hopach clustering"

  output_prefix:
    type: string?
    label: "Output file prefix"
    default: "atac_pairwise"

outputs:
  diff_expr_file:
    type: File
    outputSource: atac_pairwise/diff_expr_file

  deseq_summary_md:
    type: File
    outputSource: atac_pairwise/deseq_summary_md

  read_counts_file_all:
    type: File
    outputSource: atac_pairwise/read_counts_file_all

  read_counts_file_filtered:
    type: File
    outputSource: atac_pairwise/read_counts_file_filtered

  phenotypes_file:
    type: File
    outputSource: atac_pairwise/phenotypes_file

  plot_lfc_vs_mean:
    type: File?
    outputSource: atac_pairwise/plot_lfc_vs_mean

  gene_expr_heatmap:
    type: File?
    outputSource: atac_pairwise/gene_expr_heatmap

  plot_pca:
    type: File?
    outputSource: atac_pairwise/plot_pca

  mds_plot_html:
    type: File?
    outputSource: atac_pairwise/mds_plot_html

  stdout_log:
    type: File
    outputSource: atac_pairwise/stdout_log

  stderr_log:
    type: File
    outputSource: atac_pairwise/stderr_log

steps:
  atac_pairwise:
    run: ../../../tools/atac-pairwise.cwl
    in:
      untreated_files: untreated_files
      treated_files: treated_files
      untreated_name: untreated_name
      treated_name: treated_name
      untreated_sample_names: untreated_sample_names
      treated_sample_names: treated_sample_names
      fdr: fdr
      lfcthreshold: lfcthreshold
      use_lfc_thresh: use_lfc_thresh
      regulation: regulation
      batchcorrection: batchcorrection
      scaling_type: scaling_type
      cluster_method: cluster_method
      row_distance: row_distance
      column_distance: column_distance
      k_hopach: k_hopach
      kmax_hopach: kmax_hopach
      output_prefix: output_prefix
    out:
      - diff_expr_file
      - deseq_summary_md
      - read_counts_file_all
      - read_counts_file_filtered
      - phenotypes_file
      - plot_lfc_vs_mean
      - gene_expr_heatmap
      - plot_pca
      - mds_plot_html
      - stdout_log
      - stderr_log 