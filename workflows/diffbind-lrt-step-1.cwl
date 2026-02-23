cwlVersion: v1.0
class: Workflow

label: "Multi-factor DiffBind Step 1 LRT"
doc: "Multi-factor DiffBind Step 1 LRT"
sd:version: 100

"sd:upstream":
  chipseq_sample:
  - "trim-chipseq-pe.cwl"
  - "trim-chipseq-se.cwl"
  - "trim-atacseq-pe.cwl"
  - "trim-atacseq-se.cwl"
  genome_indices:
  - "genome-indices.cwl"
  - "https://github.com/datirium/workflows/workflows/genome-indices.cwl"

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:

  alias:
    type: string
    label: "Analysis name"
    sd:preview:
      position: 1

  alignment_files:
    type: File[]
    secondaryFiles:
    - .bai
    label: "ChIP-Seq/ATAC-Seq Analyses"
    "sd:upstreamSource": "chipseq_sample/bambai_pair"
    "sd:localLabel": true

  peak_files:
    type: File[]
    "sd:upstreamSource": "chipseq_sample/macs2_called_peaks"

  alignment_names:
    type: string[]
    "sd:upstreamSource": "chipseq_sample/alias"

  annotation_tsv_file:
    type: File
    label: "Reference genome"
    "sd:upstreamSource": "genome_indices/annotation"
    "sd:localLabel": true

  chrom_length_file:
    type: File
    "sd:upstreamSource": "genome_indices/chrom_length"

  genome_name:
    type: string
    "sd:upstreamSource": "genome_indices/genome"

  qvalue_threshold:
    type: float?
    default: 0.05
    label: "Maximum q-value (FDR) for loading MACS2 peak data"
    doc: |
      Filtering threshold to keep only those peaks where
      q-value (FDR) is less than or equal to the provided
      value. This filter is applied to the peak data loaded
      from the ChIP-Seq/ATAC-Seq Analyses before constructing
      the consensus peaks. To enable -log10 scale, use negative
      numbers. Default: 0.05

  group_variable:
    type: string?
    default: ""
    label: "Grouping variable for minimum peak set overlap filtering"
    doc: |
      Column(s) from the samples metadata to define samples
      grouping for minimum peak set overlap filtering. The
      filtering will be applied within each group independently.
      Union of the resulted peaks from all groups will be used
      for constructing the consensus peaks. Overlapping peaks
      will be merged, extended around their summits, and
      filtered by the minimum RKPM counts threshold.
      Default: apply minimum peak set overlap filtering for
      all samples jointly.

  overlap_threshold:
    type: float?
    default: 2
    label: "Minimum peak set overlap"
    doc: |
      Filtering threshold to keep only those peaks that are
      present in at least this many samples when generating
      consensus set of peaks used in the differential analysis.
      If this threshold has a value between zero and one, only
      those peaks will be included, that are present in at least
      this proportion of samples. When grouping variable provided,
      first, the minimum peak set overlap threshold is applied per
      group, then, the union of the resulted peaks is used for
      constructing the consensus peaks. Overlapping peaks will
      be merged, extended around their summits, and filtered by
      the minimum RKPM counts threshold.
      Default: 2

  extend_distance:
    type: int?
    default: 200
    label: "Peaks extension distance around their summits"
    doc: |
      Peaks extension distance around their summits applied in
      both directions for peaks received after minimum peak set
      overlap filtering and merging overlaps. Any value bigger
      than 0 will result in all consensus peaks having the same
      size of the 2*D+1. Set it to 100 for ATAC-Seq, 200 for
      ChIP-Seq samples, and 0 or any negative number to disable
      consensus peak size unification.
      Default: 200 bp.

  rpkm_threshold:
    type: float?
    default: 3
    label: "Minimum RPKM to exclude consensus peaks with low read counts across all samples"
    doc: |
      Filtering threshold to keep only those consensus peaks where
      the max RPKM for all samples is bigger than or equal to the
      provided value.
      Default: 3

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
      the expanded format (without *) and include not
      more than 4 variables.

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
      read counts before running the differential analysis.
      limma corrects batch effect only after differential
      analysis has already finished running and mainly
      impacts the read counts heatmap. Both batch correction
      method and batch correction variable should be provided.
      Default: do not correct for batch effect.

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

  padj_threshold:
    type: float?
    default: 0.1
    label: "Maximum P-adjusted for considering consensus peaks significantly differentially accessible/bound"
    doc: |
      The significance cutoff for optimizing the independent
      filtering for both LRT and optional Wald tests. It is
      also used in the exploratory visualization part of the
      analysis for generating read counts heatmap and reports.
      To enable -log10 scale, use negative numbers.
      Default: 0.1.

  wald_test:
    type: boolean?
    default: true
    label: "Run Wald test for all possible pairwise contrasts (needed for DiffBind LRT Step 2)"
    doc: |
      Based on the sample metadata, generates all possible
      pairwise contrasts and runs Wald test for each of
      them. The number of the significantly differentially
      accessible/bound sites is reported after filtering by
      the maximum P-adjusted and minimum log2 fold change
      thresholds. This step is required if you plan to run
      "DiffBind LRT Step 2" with the results of this analysis,
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
    label: "Metadata file to describe the relation between samples"
    doc: |
      TSV/CSV file to describe the relation between the
      selected ChIP-Seq/ATAC-Seq analyses. All column names
      can be arbitrary but should be unique. The first column
      should correspond to the names of the selected
      ChIP-Seq/ATAC-Seq analyses. All the remaining columns
      can be used in the design and reduced formulas.

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

  promoter_distance:
    type: int?
    default: 1000
    label: "Promoter distance (for the nearest gene assignment)"
    doc: |
      Maximum distance from the gene TSS (in both direction)
      overlapping which the consensus peak will be assigned
      to the promoter region.
      Default: 1000
    "sd:layout":
      advanced: true

  upstream_distance:
    type: int?
    default: 20000
    label: "Upstream distance (for the nearest gene assignment)"
    doc: |
      Max distance from the promoter (only in upstream direction)
      overlapping which the the consensus peak will be assigned to
      the upstream region.
      Default: 20000
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

  export_density:
    type: boolean?
    default: true
    label: "Export tag density heatmap for filtered differentially accessible/bound sites"
    doc: |
      Export tag density heatmap for filtered by adjusted p-value
      (FDR) and optionally clustered differentially accessible/bound
      sites. Default: export tag density heatmap.
    "sd:layout":
      advanced: true

  flank_distance:
    type: int?
    default: 5000
    label: "Flanking distance for tag density heatmap"
    doc: |
      Distance in bp to extend all filtered by adjusted p-value (FDR)
      differentially accessible/bound sites around their centers in both
      directions. The extended regions are used for tag density heatmap
      generation. The same procedure is applied to regions used in the
      quantile-quantile normalization of the bigWig files, however, those
      regions are defined based on the selected bigWig quantile-quantile
      normalization method.
      Default: 5000
    "sd:layout":
      advanced: true

  bin_size:
    type: int?
    default: 100
    label: "Bin size for tag density heatmap"
    doc: |
      Bin size for the tag density heatmap generation.
      Not smaller than 10.
      Default: 100
    "sd:layout":
      advanced: true

  bw_norm_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "consensus"
      - "filtered"
      - "none"
    default: "consensus"
    label: "BigWig quantile-quantile normalization method"
    doc: |
      Type of the regions used in the quantile-quantile normalization
      of the bigWig files when generating tag density heatmap. Applied
      after CPM. When filtered is selected only the filtered by adjusted
      p-value (FDR) differentially accessible/bound sites will be used.
      When consensus is selected, all peaks that were first loaded from
      the samples and then filtered and modified by the combination of
      multiple thresholds will be used. Both consensus and filtered
      regions are extended around their centers in both direction based
      on the specified flanking distance. When none is selected  - do
      not modify bigWig file (only apply CPM for all reads except those
      which are mapped on the chrX, chrY, and chrM chromosomes).
      Default: consensus
    "sd:layout":
      advanced: true

outputs:

  mds_plot_html:
    type: File?
    outputSource: diffbind_lrt_step_1/mds_plot_html
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
    outputSource: diffbind_lrt_step_1/read_counts_html
    label: "Heatmap of normalized read counts"
    doc: |
      Morpheus heatmap of normalized read counts.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  tag_dnst_htmp_html:
    type: File?
    outputSource: diffbind_lrt_step_1/tag_dnst_htmp_html
    label: "Tag density heatmap around the centers of filtered differentially accessible/bound sites"
    doc: |
      Morpheus tag density heatmap around the centers of
      filtered differentially accessible/bound sites.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  igv_html:
    type: File?
    outputSource: diffbind_lrt_step_1/igv_html
    label: "IGV Browser"
    doc: |
      Integrative Genomics Viewer with loaded tracks.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  igv_json:
    type: File?
    outputSource: diffbind_lrt_step_1/igv_json
    label: "Configuration file for IGV Browser"
    doc: |
      Configuration file for IGV Browser.
      JSON format.

  summary_md:
    type: File
    outputSource: diffbind_lrt_step_1/summary_md
    label: "Analysis summary"
    doc: |
      Analysis summary
    "sd:visualPlugins":
    - markdownView:
        tab: "Overview"

  all_cons_peaks_bed:
    type: File
    outputSource: diffbind_lrt_step_1/all_cons_peaks_bed
    label: "All consensus peaks (significant peaks highlighted)"
    doc: |
      All consensus peaks. Significant peaks are selected
      based on the LRT results.
      BED format.

  fltr_cons_peaks_bed:
    type: File?
    outputSource: diffbind_lrt_step_1/fltr_cons_peaks_bed
    label: "Filtered consensus peaks (only significant)"
    doc: |
      Filtered consensus peaks. Significant peaks are selected
      based on the LRT results.
      BED format.

  coverage_folder_out:
    type: Directory?
    outputSource: diffbind_lrt_step_1/coverage_folder_out
    label: "Folder with bigWig and BED files (for IGV)"
    doc: |
      Folder with bigWig and BED files needed for IGV.

  pk_vrlp_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: diffbind_lrt_step_1/pk_vrlp_plot_png
    label: "Peak set overlap rate"
    doc: |
      Peak set overlap rate plots.
      PNG format
    "sd:visualPlugins":
    - image:
        tab: "Peak set overlap"
        Caption: "Peak set overlap rate"

  diff_access_tsv:
    type: File
    outputSource: diffbind_lrt_step_1/diff_access_tsv
    label: "Differentially accessible/bound sites (not filtered)"
    doc: |
      TSV file with not filtered differentially
      accessible/bound sites produced by DESeq2
      LRT test.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "LRT"
        Title: "Differentially accessible/bound sites (not filtered)"

  all_contrasts_tsv:
    type: File?
    outputSource: diffbind_lrt_step_1/all_contrasts_tsv
    label: "All possible pairwise contrasts (needed for DiffBind LRT Step 2)"
    doc: |
      All pairwise contrasts produced by DESeq2 Wald tests.
      TSV format.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "Wald"
        Title: "All possible pairwise contrasts (needed for DiffBind LRT Step 2)"

  read_counts_gct:
    type: File?
    outputSource: diffbind_lrt_step_1/read_counts_gct
    label: "Heatmap of normalized read counts (GCT)"
    doc: |
      Morpheus heatmap of normalized read counts.
      GCT format.

  tag_dnst_score:
    type: File?
    outputSource: diffbind_lrt_step_1/tag_dnst_score
    label: "Score matrix for tag density heatmap"
    doc: |
      Score matrix for tag density heatmap around the centers
      of filtered differentially accessible/bound sites.
      GCT format.

  tag_dnst_htmp_gct:
    type: File?
    outputSource: diffbind_lrt_step_1/tag_dnst_htmp_gct
    label: "Tag density heatmap around the centers of filtered differentially accessible/bound sites (GCT)"
    doc: |
      Morpheus tag density heatmap around the centers of
      filtered differentially accessible/bound sites.
      GCT format.

  all_contrasts_rds:
    type: File?
    outputSource: diffbind_lrt_step_1/all_contrasts_rds
    label: "All possible pairwise contrasts (needed for DiffBind LRT Step 2)"
    doc: |
      All pairwise contrasts produced by DESeq2 Wald tests.
      RDS format.

  human_log:
    type: File?
    outputSource: diffbind_lrt_step_1/human_log
    label: "Human readable error log"
    doc: |
      Human readable error log
      from the diffbind_lrt_step_1 step.

  stdout_log:
    type: File
    outputSource: diffbind_lrt_step_1/stdout_log
    label: "DiffBind stdout log"
    doc: "DiffBind stdout log"

  stderr_log:
    type: File
    outputSource: diffbind_lrt_step_1/stderr_log
    label: "DiffBind stderr log"
    doc: "DiffBind stderr log"

steps:

  diffbind_lrt_step_1:
    run: ../tools/diffbind-lrt-step-1.cwl
    in:
      alignment_files: alignment_files
      peak_files: peak_files
      alignment_names: alignment_names
      qvalue_threshold: qvalue_threshold
      metadata_file: metadata_file
      group_variable:
        source: group_variable
        valueFrom: $(self==""?null:self)
      overlap_threshold: overlap_threshold
      extend_distance: extend_distance
      rpkm_threshold: rpkm_threshold
      design_formula: design_formula
      reduced_formula: reduced_formula
      batch_correction_method:
        source: batch_correction_method
        valueFrom: $(self=="none"?null:self)
      batch_correction_variable:
        source: batch_correction_variable
        valueFrom: $(self==""?null:self)
      padj_threshold: padj_threshold
      logfc_threshold: logfc_threshold
      strict: strict
      alternative_hypothesis: alternative_hypothesis
      annotation_tsv_file: annotation_tsv_file
      chrom_length_file: chrom_length_file
      genome_name: genome_name
      promoter_distance: promoter_distance
      upstream_distance: upstream_distance
      cluster_method:
        source: cluster_method
        valueFrom: $(self=="none"?null:self)
      cluster_row_distance: cluster_row_distance
      cluster_col_distance: cluster_col_distance
      cluster_max_depth: cluster_max_depth
      cluster_max_branches: cluster_max_branches
      wald_test: wald_test
      export_density: export_density
      flank_distance: flank_distance
      bin_size: bin_size
      bw_norm_method:
        source: bw_norm_method
        valueFrom: $(self=="none"?null:self)
    out:
    - pk_vrlp_plot_png
    - mds_plot_html
    - summary_md
    - read_counts_gct
    - read_counts_html
    - diff_access_tsv
    - all_cons_peaks_bed
    - fltr_cons_peaks_bed
    - coverage_folder_out
    - tag_dnst_score
    - tag_dnst_htmp_gct
    - tag_dnst_htmp_html
    - all_contrasts_rds
    - all_contrasts_tsv
    - igv_html
    - igv_json
    - human_log
    - stdout_log
    - stderr_log