cwlVersion: v1.0
class: Workflow

label: "DESeq2 LRT Step 2"
doc: "DESeq2 LRT Step 2"
sd:version: 100

"sd:upstream":
  deseq_lrt_step_1:
    - "deseq-lrt-step-1.cwl"
    - "https://github.com/datirium/workflows/workflows/deseq-lrt-step-1.cwl"

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:

  alias:
    type: string
    label: "Analysis name"
    sd:preview:
      position: 1

  query_rds:
    type: File
    label: "DESeq2 LRT Step 1 Analysis"
    "sd:upstreamSource": "deseq_lrt_step_1/all_contrasts_rds"
    "sd:localLabel": true

  target_contrasts:
    type: string
    label: "Target contrasts to run Wald test with"
    doc: |
      Space or comma separated list of target contrasts
      to run Wald test with. The available values can be
      selected from the Contrast number column of the
      DESeq2 Wald tests contrasts table produced by the
      DESeq2 LRT Step 1 Analysis.

  padj_threshold:
    type: float?
    default: 0.1
    label: "P-adjusted threshold for exploratory visualization part of the analysis"
    doc: |
      In the exploratory visualization part of the analysis output
      only features with the adjusted p-value (FDR) not bigger than
      this value. Also this value is used the significance cutoff
      used for optimizing the independent filtering. Default: 0.1.

  logfc_threshold:
    type: float?
    default: 0
    label: "Log2 fold change threshold used in the alternative hypothesis for Wald test"
    doc: |
      Log2 fold change threshold used in the alternative
      hypothesis test. The alternative hypothesis can be
      set to one of: greater, less, lessAbs, or greaterAbs.
      Default: 0.

  alternative_hypothesis:
    type:
    - "null"
    - type: enum
      symbols:
      - "greater"
      - "less"
      - "lessAbs"
      - "greaterAbs"
    default: "greaterAbs"
    label: "The alternative hypothesis for the Wald test"
    doc: |
      The alternative hypothesis for the Wald test.
      greater - tests if the log2 fold change is greater
      than the specified logfc threshold, less - tests
      if the log2 fold change is less than the negative
      specified logfc threshold, lessAbs - tests if the
      absolute log2 fold change is less than the specified
      logfc threshold, greaterAbs - tests if the the
      absolute log2 fold change is greater than the specified
      logfc threshold. Default: greaterAbs
    "sd:layout":
      advanced: true

  cluster_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "row"
      - "column"
      - "both"
      - "none"
    default: "none"
    label: "Clustering method"
    doc: |
      Hopach clustering method to be run on normalized read
      counts for the exploratory visualization analysis.
      Default: do not run clustering.
    "sd:layout":
      advanced: true

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
    default: "cosangle"
    label: "Row clustering distance metric"
    doc: |
      Distance metric for row clustering.
      Ignored clustering method is set to none.
      Default: cosangle
    "sd:layout":
      advanced: true

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
    default: "euclid"
    label: "Column clustering distance metric"
    doc: |
      Distance metric for column clustering.
      Ignored clustering method is set to none.
      Default: euclid
    "sd:layout":
      advanced: true

  cluster_max_depth:
    type: int?
    default: 3
    label: "The maximum number of clustering levels"
    doc: |
      The maximum number of clustering levels.
      Default: 3.
    "sd:layout":
      advanced: true

  cluster_max_branches:
    type: int?
    default: 5
    label: "The maximum number of clustering branches"
    doc: |
      The maximum number of clustering branches.
      Default: 5.
    "sd:layout":
      advanced: true

  threads:
    type:
    - "null"
    - type: enum
      symbols:
      - "1"
      - "2"
      - "3"
      - "4"
      - "5"
      - "6"
    default: "4"
    label: "Cores/CPUs"
    doc: |
      Parallelization parameter to define the
      number of cores/CPUs that can be utilized
      simultaneously.
      Default: 4
    "sd:layout":
      advanced: true

outputs:

  read_counts_html:
    type: File?
    outputSource: deseq_lrt_step_2/read_counts_html
    label: "Heatmap of normalized read counts"
    doc: |
      Morpheus heatmap of normalized read counts.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  vlcn_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: deseq_lrt_step_2/vlcn_png
    label: "Volcano plots for target contrasts"
    doc: |
      Volcano plots for target contrasts.
      PNG format.
    "sd:visualPlugins":
    - image:
        tab: "Volcano Plots"
        Caption: "Volcano plots for target contrasts"

  diff_expr_tsv:
    type: File
    outputSource: deseq_lrt_step_2/diff_expr_tsv
    label: "Differentially expressed features"
    doc: |
      TSV file with not filtered differentially
      expressed features produced by DESeq2 Wald
      tests for target contrasts.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "DESeq2 Wald"
        Title: "Differentially expressed features"

  read_counts_gct:
    type: File?
    outputSource: deseq_lrt_step_2/read_counts_gct
    label: "Heatmap of normalized read counts (GCT)"
    doc: |
      Morpheus compatible heatmap of normalized read counts.
      GCT format.

  stdout_log:
    type: File
    outputSource: deseq_lrt_step_2/stdout_log
    label: "DESeq2 stdout log"
    doc: "DESeq2 stdout log"

  stderr_log:
    type: File
    outputSource: deseq_lrt_step_2/stderr_log
    label: "DESeq2 stderr log"
    doc: "DESeq2 stderr log"

steps:

  deseq_lrt_step_2:
    run: ../tools/deseq-lrt-step-2.cwl
    in:
      query_rds: query_rds
      target_contrasts: target_contrasts
      padj_threshold: padj_threshold
      logfc_threshold: logfc_threshold
      alternative_hypothesis: alternative_hypothesis
      cluster_method:
        source: cluster_method
        valueFrom: $(self=="none"?null:self)
      cluster_row_distance: cluster_row_distance
      cluster_col_distance: cluster_col_distance
      cluster_max_depth: cluster_max_depth
      cluster_max_branches: cluster_max_branches
      threads:
        source: threads
        valueFrom: $(parseInt(self))
    out:
    - vlcn_png
    - read_counts_gct
    - read_counts_html
    - diff_expr_tsv
    - stdout_log
    - stderr_log