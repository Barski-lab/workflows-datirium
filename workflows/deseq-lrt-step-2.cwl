cwlVersion: v1.0
class: Workflow

label: "DESeq2 LRT Step 2"
doc: "DESeq2 LRT Step 2"
sd:version: 100

"sd:upstream":
  deseq_lrt_step_1:
    - "deseq-lrt-step-1.cwl"

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
    label: "Target contrasts to run pairwise Wald test with"
    doc: |
      Space or comma separated list of target contrasts
      to run pairwise Wald test with. The available values
      can be selected from the "Contrast number" column of
      the Wald tests contrasts table produced by the
      "DESeq2 LRT Step 1" Analysis.

  padj_threshold:
    type: float?
    default: 0.1
    label: "Maximum P-adjusted for considering features significantly differentially expressed"
    doc: |
      The significance cutoff for optimizing the Wald
      test's independent filtering. It is also used in
      the exploratory visualization part of the analysis
      for generating read counts heatmap, volcano plots,
      and results table.
      Default: 0.1.

  logfc_threshold:
    type: float?
    default: 0.59
    label: "Minimum log2 fold change for the Wald test results filtering"
    doc: |
      Log2 fold change threshold used in the Wald test
      results filtering. This value can also be used as
      the threshold in the alternative hypothesis testing.
      Otherwise, the alternative hypothesis is tested
      with the log2 fold change value equal to 0.
      Default: 0.59.

  strict:
    type: boolean?
    default: false
    label: "Use minimum log2 fold change in the Wald test's alternative hypothesis testing"
    doc: |
      Use the provided log2 fold change threshold in
      the Wald test's alternative hypothesis testing.
      Default: use 0 as the log2 fold change threshold
      in the alternative hypothesis testing.
    "sd:layout":
      advanced: true

  alternative_hypothesis:
    type:
    - "null"
    - type: enum
      symbols:
      - "greater"
      - "less"
      - "greaterAbs"
    default: "greaterAbs"
    label: "Wald test's alternative hypothesis"
    doc: |
      The alternative hypothesis used in the Wald
      test. "greater" - tests if the log2 fold
      change is greater than 0 or the specified
      threshold. "less" - tests if the log2 fold
      change is less than 0 or the negative value
      of the specified threshold. "greaterAbs" -
      tests if the absolute log2 fold change is
      greater than 0 or the specified threshold.
      Default: greaterAbs.
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
    label: "Heatmap clustering method"
    doc: |
      Hopach clustering method to be run on the
      normalized read counts for the exploratory
      visualization part of the analysis (heatmap).
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
      - "cor"
      - "abscor"
    default: "cosangle"
    label: "Row clustering distance metric"
    doc: |
      Distance metric for row (feature) clustering.
      Ignored if the heatmap clustering method is
      set to none. Default: cosangle
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
      - "cor"
      - "abscor"
    default: "euclid"
    label: "Column clustering distance metric"
    doc: |
      Distance metric for column (sample) clustering.
      Ignored if the heatmap clustering method is
      set to none. Default: euclid
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

  volcano_plot_html:
    type: File?
    outputSource: deseq_lrt_step_2/volcano_plot_html
    label: "Volcano plots for target contrasts"
    doc: |
      Interactive volcano plots for selected contrasts.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  volcano_plot_data:
    type: Directory?
    outputSource: deseq_lrt_step_2/volcano_plot_data
    label: "Volcano plots for target contrasts (data)"
    doc: |
      Directory with the html data needed for
      the interactive volcano plots to function.

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

  summary_md:
    type: File
    outputSource: deseq_lrt_step_2/summary_md
    label: "Analysis summary"
    doc: |
      Analysis summary
    "sd:visualPlugins":
      - markdownView:
          tab: "Overview"

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
    label: "Differentially expressed features (not filtered)"
    doc: |
      TSV file with not filtered differentially
      expressed features produced by the pairwise
      DESeq2 Wald tests for the target contrasts.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "Wald"
        Title: "Differentially expressed features (not filtered)"

  read_counts_gct:
    type: File?
    outputSource: deseq_lrt_step_2/read_counts_gct
    label: "Heatmap of normalized read counts (GCT)"
    doc: |
      Morpheus heatmap of normalized read counts.
      GCT format.

  human_log:
    type: File?
    outputSource: deseq_lrt_step_2/human_log
    label: "Human readable error log"
    doc: |
      Human readable error log
      from the deseq_lrt_step_2 step.

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
      strict: strict
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
    - volcano_plot_data
    - volcano_plot_html
    - diff_expr_tsv
    - summary_md
    - human_log
    - stdout_log
    - stderr_log