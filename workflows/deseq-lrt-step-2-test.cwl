cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement

#"sd:upstream":
#  deseq_lrt_step1:
#    - "deseq-lrt-step-1.cwl"
#    - "https://github.com/Barski-lab/workflows-datirium/blob/master/workflows/deseq-lrt-step-1.cwl"


inputs:

  alias:
    type: string
    label: "Experiment short name/Alias"
  #    sd:preview:
  #      position: 1

  batchcorrection:
    type: string
    label: "Batch correction method"
    doc: "Batch correction method to use in DESeq2. Default: none"

  group_by:
    type:
      - "null"
      - type: enum
        symbols: [ "isoforms", "genes", "common tss" ]
    default: "genes"
    label: "Group by"
    doc: "Grouping method for features: isoforms, genes or common tss"

  dsq_obj_data:
    type: File
    doc: "RDS file containing the contrasts list from step 1"

  contrasts_table:
    type: File
    doc: "TSV file containing contrasts data"

  contrast_indices:
    type: string
    label: "Comma-separated list of integers representing contrast indices"
    default: "1,5,13 (Example of list of 3 contrasts)"
    doc: "Comma-separated list of integers representing contrast indices (e.g., 1,5,13)"

  fdr:
    type: float?
    default: 0.1
    label: "Maximum P-adjusted to show features in the exploratory visualization analysis"
    doc: |
      In the exploratory visualization part of the analysis, output only features
      with adjusted p-value (FDR) not bigger than this value. Also, the significance
      cutoff used for optimizing the independent filtering. Default: 0.1.
  #    'sd:layout':
  #      advanced: true

  lfcthreshold:
    type: float?
    default: 0.59
    label: "Log2 Fold Change Threshold"
    doc: |
      Log2 fold change threshold for determining significant differential expression.
      Genes with absolute log2 fold change greater than this threshold will be considered.
      Default: 0.59 (about 1.5 fold change)
  #    'sd:layout':
  #      advanced: true

  use_lfc_thresh:
    type: boolean
    default: true
    label: "Use lfcthreshold as the null hypothesis value in the results function call"
    doc: "Use lfcthreshold as the null hypothesis value in the results function call. Default: TRUE"
  #    'sd:layout':
  #      advanced: true

  regulation:
    type:
      - "null"
      - type: enum
        symbols:
          - "both"
          - "up"
          - "down"
    default: "both"
    label: "Direction of differential expression comparison"
    doc: |
      Direction of differential expression comparison. β is the log2 fold change.
      - 'both' for both up and downregulated genes (|β| > lfcThreshold);
      - 'up' for upregulated genes (β > lfcThreshold);
      - 'down' for downregulated genes (β < -lfcThreshold).
      Default: both
  #    'sd:layout':
  #      advanced: true

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
    label: "Hopach clustering method to be run on normalized read counts"
    doc: |
      Hopach clustering method to be run on normalized read counts for the
      exploratory visualization analysis. Default: do not run clustering
  #    'sd:layout':
  #      advanced: true

  k_hopach:
    type: int?
    default: 3
    label: "Number of levels for Hopach clustering"
    doc: "Number of levels (depth) for Hopach clustering: min - 1, max - 15. Default: 3."
    #    'sd:layout':
    #      advanced: true

  kmax_hopach:
    type: int?
    default: 5
    label: "Maximum number of clusters at each level for Hopach clustering"
    doc: "Maximum number of clusters at each level for Hopach clustering: min - 2, max - 9. Default: 5."
    #    'sd:layout':
    #      advanced: true

  threads:
    type: int?
    label: "Number of threads"
    doc: "Number of threads for those steps that support multithreading"
    default: 6
  #    'sd:layout':
  #      advanced: true

  test_mode:
    type: boolean
    default: false
    label: "Run only 100 genes for testing purposes to speed up DESeq2"
#    'sd:layout':
#      advanced: true

outputs:

  diff_expr_files:
    type: File[]
    outputSource: deseq/diff_expr_files
    label: "Differential expression files"
    doc: |
      Differential expression analysis results for each contrast

  mds_plots_html:
    type: File?
    outputSource: deseq/mds_plots_html
    label: "MDS Plots"
    doc: |
      HTML files for MDS Plots for each contrast

  counts_all_gct:
    type: File
    outputSource: deseq/counts_all_gct
    label: "GENE COUNTS GCT"
    doc: |
      Normalized counts in GCT format for all contrasts

  counts_filtered_gct:
    type: File
    outputSource: deseq/counts_filtered_gct
    label: "Filtered GENE COUNTS GCT"
    doc: |
      Filtered normalized counts in GCT format for all contrasts

  # COMMENTED OUT: volcano plot outputs due to missing volcano-plot.cwl tool
  # volcano_plots_html:
  #   type: File[]
  #   outputSource: make_volcano_plot/html_file
  #   label: "Volcano Plots"
  #   doc: |
  #     HTML files for Volcano Plots for each contrast

  # volcano_plots_html_data:
  #   type: Directory[]
  #   outputSource: make_volcano_plot/html_data
  #   label: "Volcano Plots"
  #   doc: |
  #     HTML data for Volcano Plots for each contrast

  heatmap_html:
    type: File
    outputSource: morpheus_heatmap/heatmap_html
    label: "Combined Heatmap of normalized counts"
    doc: |
      Morpheus heatmap in HTML format combining all contrasts

  deseq_stdout_log:
    type: File
    #    format: "http://edamontology.org/format_2330"
    label: "DESeq2 stdout log"
    doc: "DESeq2 stdout log"
    outputSource: deseq/stdout_log

  deseq_stderr_log:
    type: File
    #    format: "http://edamontology.org/format_2330"
    label: "DESeq2 stderr log"
    doc: "DESeq2 stderr log"
    outputSource: deseq/stderr_log

  morpheus_stdout_log:
    type: File
    outputSource: morpheus_heatmap/stdout_log
    label: "Morpheus heatmap stdout log"
    doc: "Morpheus heatmap stdout log"

  morpheus_stderr_log:
    type: File
    outputSource: morpheus_heatmap/stderr_log
    label: "Morpheus heatmap stderr log"
    doc: "Morpheus heatmap stderr log"

steps:

  deseq:
    run: ../tools/deseq-lrt-step-2.cwl
    in:
      dsq_obj_data: dsq_obj_data
      contrasts_table: contrasts_table
      contrast_indices: contrast_indices
      fdr_cutoff: fdr
      lfcthreshold: lfcthreshold
      regulation: regulation
      use_lfc_thresh: use_lfc_thresh
      cluster_method: cluster_method
      kmax_hopach: kmax_hopach
      k_hopach: k_hopach
      output_prefix: alias
      threads: threads
      test_mode: test_mode
    out:
      - diff_expr_files
      - mds_plots_html
      - counts_all_gct
      - counts_filtered_gct
      - stdout_log
      - stderr_log

  #  merge_gct_files:
  #    run: ../tools/merge_gct_files.cwl
  #    in:
  #      gct_files: deseq/counts_filtered_gct
  #    out:
  #      - merged_gct_file

  # COMMENTED OUT: volcano plot step due to missing volcano-plot.cwl tool
  # make_volcano_plot:
  #   run: ../tools/volcano-plot.cwl
  #   scatterMethod: dotproduct
  #   scatter:
  #     - diff_expr_file
  #   in:
  #     diff_expr_file: deseq/diff_expr_files
  #     output_filename:
  #       valueFrom: $(inputs.diff_expr_file.basename.replace(/\.tsv$/, '.html'))
  #     x_axis_column:
  #       default: "log2FoldChange"
  #     y_axis_column:
  #       default: "padj"
  #     label_column:
  #       source: group_by
  #       valueFrom: |
  #         ${
  #           if (self == "isoforms") {
  #             return "RefseqId";
  #           } else if (self == "genes") {
  #             return "GeneId";
  #           } else {
  #             return "GeneId";
  #           }
  #         }
  #   out:
  #     - html_file
  #     - html_data

  morpheus_heatmap:
    run: ../tools/morpheus-heatmap.cwl
    in:
      read_counts_gct: deseq/counts_filtered_gct
    out:
      - heatmap_html
      - stdout_log
      - stderr_log

#$namespaces:
#  s: http://schema.org/

#$schemas:
#  - https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

#s:name: "DESeq2 (LRT, step 2) - Differential gene expression analysis using likelihood ratio test"
#label: "DESeq2 (LRT, step 2) - Differential gene expression analysis using likelihood ratio test"
#s:alternateName: "Differential gene expression analysis based on the LRT (likelihood ratio test)"
#
#s:downloadUrl: https://raw.githubusercontent.com/datirium/workflows/master/workflows/deseq-lrt-step-2.cwl
#s:codeRepository: https://github.com/datirium/workflows
#s:license: http://www.apache.org/licenses/LICENSE-2.0
#
#s:isPartOf:
#  class: s:CreativeWork
#  s:name: Common Workflow Language
#  s:url: http://commonwl.org/
#
#s:creator:
#  - class: s:Organization
#    s:legalName: "Cincinnati Children's Hospital Medical Center"
#    s:location:
#      - class: s:PostalAddress
#        s:addressCountry: "USA"
#        s:addressLocality: "Cincinnati"
#        s:addressRegion: "OH"
#        s:postalCode: "45229"
#        s:streetAddress: "3333 Burnet Ave"
#        s:telephone: "+1(513)636-4200"
#    s:logo: "https://www.cincinnatichildrens.org/-/media/cincinnati%20childrens/global%20shared/childrens-logo-new.png"
#    s:department:
#      - class: s:Organization
#        s:legalName: "Allergy and Immunology"
#        s:department:
#          - class: s:Organization
#            s:legalName: "Barski Research Lab"
#        s:member:
#          - class: s:Person
#            s:name: Michael Kotliar
#            s:email: mailto:misha.kotliar@gmail.com
#            s:sameAs:
#              - id: http://orcid.org/0000-0002-6486-3898

doc: |
  Runs DESeq2 using LRT (Likelihood Ratio Test)
  =============================================

  The LRT examines two models for the counts, a full model with a certain number of terms and a reduced model, in which some of the terms of the full model are removed. The test determines if the increased likelihood of the data using the extra terms in the full model is more than expected if those extra terms are truly zero.

  The LRT is therefore useful for testing multiple terms at once, for example testing 3 or more levels of a factor at once, or all interactions between two variables. The LRT for count data is conceptually similar to an analysis of variance (ANOVA) calculation in linear regression, except that in the case of the Negative Binomial GLM, we use an analysis of deviance (ANODEV), where the deviance captures the difference in likelihood between a full and a reduced model.

  When one performs a likelihood ratio test, the p-values and the test statistic (the 'stat' column) are values for the test that removes all of the variables which are present in the full design and not in the reduced design. This tests the null hypothesis that all the coefficients from these variables and levels of these factors are equal to zero.

  The likelihood ratio test p-values therefore represent a test of all the variables and all the levels of factors which are among these variables. However, the results table only has space for one column of log fold change, so a single variable and a single comparison is shown (among the potentially multiple log fold changes which were tested in the likelihood ratio test). This indicates that the p-value is for the likelihood ratio test of all the variables and all the levels, while the log fold change is a single comparison from among those variables and levels.

  **Technical notes**

  1. At least two biological replicates are required for every compared category.
  2. The metadata file describes relations between compared experiments. For example:

     ```
     ,time,condition
     DH1,day5,WT
     DH2,day5,KO
     DH3,day7,WT
     DH4,day7,KO
     DH5,day7,KO
     ```
     where `time`, `condition`, `day5`, `day7`, `WT`, `KO` should be single words (without spaces), and `DH1`, `DH2`, `DH3`, `DH4`, `DH5` correspond to the experiment aliases set in **RNA-Seq experiments** input.
  3. Design and reduced formulas should start with `~` and include categories or, optionally, their interactions from the metadata file header. See details in the DESeq2 manual [here](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html#interactions) and [here](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html#likelihood-ratio-test).
  4. Contrast indices should correspond to the contrasts generated in the first step, allowing for specific comparisons in the differential expression analysis.
