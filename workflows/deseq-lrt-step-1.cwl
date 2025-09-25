cwlVersion: v1.0
class: Workflow

label: "DESeq2 LRT Step 1"
doc: "DESeq2 LRT Step 1"
sd:version: 100

"sd:upstream":
  rnaseq_sample:
    - "trim-rnaseq-pe.cwl"
    - "trim-rnaseq-se.cwl"
    - "trim-rnaseq-pe-dutp.cwl"
    - "trim-rnaseq-se-dutp.cwl"

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:

  alias:
    type: string
    label: "Analysis name"
    sd:preview:
      position: 1

  expression_files:
    type: File[]
    label: "RNA-Seq Analyses"
    "sd:upstreamSource": "rnaseq_sample/rpkm_isoforms"
    "sd:localLabel": true

  expression_names:
    type: string[]
    "sd:upstreamSource": "rnaseq_sample/alias"

  feature_type:
    type:
    - "null"
    - type: enum
      symbols:
      - "gene"
      - "isoform"
      - "tss"
    default: "gene"
    label: "Group expression by"

  design_formula:
    type: string
    label: "Design formula (represents the full model)"
    doc: |
      Specifies all variables you want to model in
      your data, including possible interactions
      between them, representing the full model. The
      formula should start with ~ and consist of the
      values that correspond to the column names of
      the samples metadata. It should be provided in
      the expanded format (without *).

  reduced_formula:
    type: string
    label: "Reduced formula (same as the design formula but with variables of interest removed)"
    doc: |
      Same as the design formula but with the variables
      or entire terms of interest removed; used to test
      if those variables significantly improve the model
      in the LRT. The formula should start with ~ and
      consist of values that correspond to the column
      names of the samples metadata. The formula should
      be provided in the expanded format (without *).

  batch_correction_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "combatseq"
      - "limma"
      - "none"
    default: "none"
    label: "Batch correction method"
    doc: |
      An optional batch correction method. When combatseq
      is selected the batch effect is removed from the raw
      read counts before running the differential expression
      analysis. limma corrects batch effect only after
      differential expression analysis has already finished
      running and mainly impacts the read counts heatmap.
      Both batch correction method and batch correction
      variable should be provided. Default: do not correct
      for batch effect.

  batch_correction_variable:
    type: string?
    default: ""
    label: "Batch correction variable"
    doc: |
      Column from the samples metadata to correct for
      batch effect. If provided, it should also be present
      in the design formula. When batch correction method
      is set to combatseq, all formula terms that include
      the batch correction variable will be removed from
      the design and reduced formulas as the batch effect
      was corrected on the raw read counts level. When batch
      correction method is set to limma, no adjustments of
      the design or reduced formulas are made. Both batch
      correction method and batch correction variable should
      be provided. Default: do not correct for batch effect.

  rpkm_threshold:
    type: float?
    default: 3
    label: "Minimum RPKM to exclude features with low expression across all RNA-Seq Analyses"
    doc: |
      Filtering threshold to keep only those features where
      the max RPKM across all RNA-Seq Analyses is bigger
      than or equal to the provided value. The filtering
      is applied before running the differential expression
      analysis. Default: 3

  padj_threshold:
    type: float?
    default: 0.1
    label: "Maximum P-adjusted for considering features significantly differentially expressed"
    doc: |
      The significance cutoff for optimizing the independent
      filtering for both LRT and optional Wald tests. It is
      also used in the exploratory visualization part of the
      analysis for generating read counts heatmap and reports.
      Default: 0.1.

  wald_test:
    type: boolean?
    default: true
    label: "Run Wald test for all possible pairwise contrasts (needed for DESeq2 LRT Step 2)"
    doc: |
      Based on the sample metadata, generates all possible
      pairwise contrasts and runs Wald test for each of
      them. The number of the significantly differentially
      expressed features is reported after filtering by the
      maximum P-adjusted and minimum log2 fold change
      thresholds. This step is required if you plan to run
      "DESeq2 LRT Step 2" with the results of this analysis,
      but can be skipped to save computational time if the
      main interest is only the LRT analysis. Default: true

  logfc_threshold:
    type: float?
    default: 0.59
    label: "Minimum log2 fold change for the Wald test results filtering"
    doc: |
      Log2 fold change threshold used in the Wald test
      results filtering. This value can also be used as
      the threshold in the alternative hypothesis testing.
      Otherwise, the alternative hypothesis is tested
      with the log2 fold change value equal to 0. Ignored
      if running Wald test for all possible pairwise
      contrasts is disabled. Default: 0.59.

  metadata_file:
    type: File
    label: "Metadata file to describe the relation between the RNA-Seq analyses"
    doc: |
      TSV/CSV file to describe the relation between the
      selected RNA-Seq analyses. All column names can be
      arbitrary but should be unique. The first column
      should correspond to the names of the selected
      RNA-Seq analyses. All the remaining columns can be
      used in the design and reduced formulas.

  strict:
    type: boolean?
    default: false
    label: "Use minimum log2 fold change in the Wald test's alternative hypothesis testing"
    doc: |
      Use the provided log2 fold change threshold in
      the Wald test's alternative hypothesis testing.
      Ignored if running Wald test for all possible
      pairwise contrasts is disabled. Default: use 0
      as the log2 fold change threshold in the
      alternative hypothesis testing.
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
      Ignored if running Wald test for all possible
      pairwise contrasts is disabled.
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

  diff_expr_tsv:
    type: File
    outputSource: deseq_lrt_step_1/diff_expr_tsv
    label: "Differentially expressed features (not filtered)"
    doc: |
      TSV file with not filtered differentially
      expressed features produced by DESeq2 LRT
      test.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "LRT"
        Title: "Differentially expressed features (not filtered)"

  all_contrasts_tsv:
    type: File?
    outputSource: deseq_lrt_step_1/all_contrasts_tsv
    label: "All pairwise contrasts produced by DESeq2 Wald tests"
    doc: |
      All pairwise contrasts produced by DESeq2 Wald tests.
      TSV format.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "Wald"
        Title: "All pairwise contrasts produced by DESeq2 Wald tests"

  mds_plot_html:
    type: File?
    outputSource: deseq_lrt_step_1/mds_plot_html
    label: "MDS plot of normalized read counts"
    doc: |
      MDS plot of normalized, optionally batch
      corrected with combatseq, read counts.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  read_counts_html:
    type: File?
    outputSource: deseq_lrt_step_1/read_counts_html
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
    outputSource: deseq_lrt_step_1/summary_md
    label: "Analysis summary"
    doc: |
      Analysis summary
    "sd:visualPlugins":
      - markdownView:
          tab: "Overview"

  read_counts_gct:
    type: File?
    outputSource: deseq_lrt_step_1/read_counts_gct
    label: "Heatmap of normalized read counts (GCT)"
    doc: |
      Morpheus heatmap of normalized read counts.
      GCT format.

  all_contrasts_rds:
    type: File?
    outputSource: deseq_lrt_step_1/all_contrasts_rds
    label: "All pairwise contrasts produced by DESeq2 Wald tests"
    doc: |
      All pairwise contrasts produced by DESeq2 Wald tests.
      RDS format.

  human_log:
    type: File?
    outputSource: deseq_lrt_step_1/human_log
    label: "Human readable error log"
    doc: |
      Human readable error log
      from the deseq_lrt_step_1 step.

  stdout_log:
    type: File
    outputSource: deseq_lrt_step_1/stdout_log
    label: "DESeq2 stdout log"
    doc: "DESeq2 stdout log"

  stderr_log:
    type: File
    outputSource: deseq_lrt_step_1/stderr_log
    label: "DESeq2 stderr log"
    doc: "DESeq2 stderr log"

steps:

  deseq_lrt_step_1:
    run: ../tools/deseq-lrt-step-1.cwl
    in:
      expression_files: expression_files
      expression_names: expression_names
      feature_type: feature_type
      metadata_file: metadata_file
      design_formula: design_formula
      reduced_formula: reduced_formula
      batch_correction_method:
        source: batch_correction_method
        valueFrom: $(self=="none"?null:self)
      batch_correction_variable:
        source: batch_correction_variable
        valueFrom: $(self==""?null:self)
      rpkm_threshold: rpkm_threshold
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
      wald_test: wald_test
      threads:
        source: threads
        valueFrom: $(parseInt(self))
    out:
    - mds_plot_html
    - summary_md
    - read_counts_gct
    - read_counts_html
    - diff_expr_tsv
    - all_contrasts_rds
    - all_contrasts_tsv
    - human_log
    - stdout_log
    - stderr_log