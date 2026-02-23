cwlVersion: v1.0
class: Workflow

label: "Multi-factor DiffBind Step 2 Wald"
doc: "Multi-factor DiffBind Step 2 Wald"
sd:version: 100

"sd:upstream":
  diffbind_lrt_step_1:
  - "diffbind-lrt-step-1.cwl"

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
    label: "DiffBind LRT Step 1 Analysis"
    "sd:upstreamSource": "diffbind_lrt_step_1/all_contrasts_rds"
    "sd:localLabel": true

  coverage_folder_in:
    type: Directory?
    "sd:upstreamSource": "diffbind_lrt_step_1/coverage_folder_out"

  target_contrasts:
    type: string
    label: "Target contrasts to run pairwise Wald test with"
    doc: |
      Space or comma separated list of target contrasts
      to run pairwise Wald test with. The available values
      can be selected from the "Contrast number" column of
      the Wald tests contrasts table produced by the
      "DiffBind LRT Step 1" Analysis.

  padj_threshold:
    type: float?
    default: 0.1
    label: "Maximum P-adjusted for considering consensus peaks significantly differentially accessible/bound"
    doc: |
      The significance cutoff for optimizing the Wald
      test's independent filtering. It is also used in
      the exploratory visualization part of the analysis
      for generating read counts heatmap, volcano plots,
      and results table. To enable -log10 scale, use
      negative numbers.
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
      When consensus is selected, all peaks produced by the DiffBind
      LRT Step 1 Analysis will be used. Both consensus and filtered
      regions are extended around their centers in both direction based
      on the specified flanking distance. When none is selected  - do
      not modify bigWig file (only apply CPM for all reads except those
      which are mapped on the chrX, chrY, and chrM chromosomes).
      Default: consensus
    "sd:layout":
      advanced: true

outputs:

  volcano_plot_html:
    type: File?
    outputSource: diffbind_lrt_step_2/volcano_plot_html
    label: "Volcano plots for target contrasts"
    doc: |
      Interactive volcano plots for selected contrasts.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  ma_plot_html:
    type: File?
    outputSource: diffbind_lrt_step_2/ma_plot_html
    label: "MA plots for target contrasts"
    doc: |
      Interactive MA plots for selected contrasts.
      HTML format.
    "sd:visualPlugins":
    - linkList:
        tab: "Overview"
        target: "_blank"

  read_counts_html:
    type: File?
    outputSource: diffbind_lrt_step_2/read_counts_html
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
    outputSource: diffbind_lrt_step_2/tag_dnst_htmp_html
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
    outputSource: diffbind_lrt_step_2/igv_html
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
    outputSource: diffbind_lrt_step_2/igv_json
    label: "Configuration file for IGV Browser"
    doc: |
      Configuration file for IGV Browser.
      JSON format.

  summary_md:
    type: File
    outputSource: diffbind_lrt_step_2/summary_md
    label: "Analysis summary"
    doc: |
      Analysis summary
    "sd:visualPlugins":
      - markdownView:
          tab: "Overview"

  all_cons_peaks_bed:
    type: File
    outputSource: diffbind_lrt_step_2/all_cons_peaks_bed
    label: "All consensus peaks (significant peaks highlighted)"
    doc: |
      All consensus peaks. Significant peaks are selected
      based on the Wald results for at least one of the
      target contrasts.
      BED format.

  fltr_cons_peaks_bed:
    type: File?
    outputSource: diffbind_lrt_step_2/fltr_cons_peaks_bed
    label: "Filtered consensus peaks (only significant)"
    doc: |
      Filtered consensus peaks. Significant peaks are selected
      based on the Wald results for at least one of the
      target contrasts.
      BED format.

  trgt_peaks_bed:
    type:
    - "null"
    - type: array
      items: File
    outputSource: diffbind_lrt_step_2/trgt_peaks_bed
    label: "Significant peaks for a specific target contrast"
    doc: |
      Significant peaks for a specific target contrast.
      BED format.

  coverage_folder_out:
    type: Directory?
    outputSource: diffbind_lrt_step_2/coverage_folder_out
    label: "Folder with bigWig and BED files (for IGV)"
    doc: |
      Folder with bigWig and BED files needed for IGV.

  diff_access_tsv:
    type: File
    outputSource: diffbind_lrt_step_2/diff_access_tsv
    label: "Differentially accessible/bound sites (not filtered)"
    doc: |
      TSV file with not filtered differentially
      accessible/bound sites produced by the pairwise
      DESeq2 Wald tests for the target contrasts.
    "sd:visualPlugins":
    - syncfusiongrid:
        tab: "Wald"
        Title: "Differentially accessible/bound sites (not filtered)"

  volcano_plot_data:
    type: Directory?
    outputSource: diffbind_lrt_step_2/volcano_plot_data
    label: "Volcano plots for target contrasts (data)"
    doc: |
      Directory with the html data needed for
      the interactive volcano plots to function.

  ma_plot_data:
    type: Directory?
    outputSource: diffbind_lrt_step_2/ma_plot_data
    label: "MA plots for target contrasts (data)"
    doc: |
      Directory with the html data needed for
      the interactive MA plots to function.

  read_counts_gct:
    type: File?
    outputSource: diffbind_lrt_step_2/read_counts_gct
    label: "Heatmap of normalized read counts (GCT)"
    doc: |
      Morpheus heatmap of normalized read counts.
      GCT format.

  tag_dnst_score:
    type: File?
    outputSource: diffbind_lrt_step_2/tag_dnst_score
    label: "Score matrix for tag density heatmap"
    doc: |
      Score matrix for tag density heatmap around the centers
      of filtered differentially accessible/bound sites.
      GCT format.

  tag_dnst_htmp_gct:
    type: File?
    outputSource: diffbind_lrt_step_2/tag_dnst_htmp_gct
    label: "Tag density heatmap around the centers of filtered differentially accessible/bound sites (GCT)"
    doc: |
      Morpheus tag density heatmap around the centers of
      filtered differentially accessible/bound sites.
      GCT format.

  human_log:
    type: File?
    outputSource: diffbind_lrt_step_2/human_log
    label: "Human readable error log"
    doc: |
      Human readable error log
      from the diffbind_lrt_step_2 step.

  stdout_log:
    type: File
    outputSource: diffbind_lrt_step_2/stdout_log
    label: "DiffBind stdout log"
    doc: "DiffBind stdout log"

  stderr_log:
    type: File
    outputSource: diffbind_lrt_step_2/stderr_log
    label: "DiffBind stderr log"
    doc: "DiffBind stderr log"

steps:

  diffbind_lrt_step_2:
    run: ../tools/diffbind-lrt-step-2.cwl
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
      coverage_folder_in: coverage_folder_in
      export_density: export_density
      flank_distance: flank_distance
      bin_size: bin_size
      bw_norm_method:
        source: bw_norm_method
        valueFrom: $(self=="none"?null:self)
    out:
    - read_counts_gct
    - read_counts_html
    - volcano_plot_html
    - volcano_plot_data
    - ma_plot_html
    - ma_plot_data
    - diff_access_tsv
    - all_cons_peaks_bed
    - fltr_cons_peaks_bed
    - trgt_peaks_bed
    - coverage_folder_out
    - tag_dnst_score
    - tag_dnst_htmp_html
    - tag_dnst_htmp_gct
    - summary_md
    - igv_html
    - igv_json
    - human_log
    - stdout_log
    - stderr_log