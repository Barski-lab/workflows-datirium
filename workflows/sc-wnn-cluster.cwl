cwlVersion: v1.0
class: Workflow


requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement
    expressionLib:
    - var split_features = function(line) {
          function get_unique(value, index, self) {
            return self.indexOf(value) === index && value != "";
          }
          let splitted_line = line?line.split(/[\s,]+/).filter(get_unique):null;
          return (splitted_line && !!splitted_line.length)?splitted_line:null;
      };
    - var split_numbers = function(line) {
          let splitted_line = line?line.split(/[\s,]+/).map(parseFloat):null;
          return (splitted_line && !!splitted_line.length)?splitted_line:null;
      };


'sd:upstream':
  sc_tools_sample:
  - "sc-rna-cluster.cwl"
  - "sc-atac-cluster.cwl"
  - "sc-rna-reduce.cwl"
  - "sc-atac-reduce.cwl"
  sc_arc_sample:
  - "cellranger-arc-count.cwl"
  - "cellranger-arc-aggr.cwl"


inputs:

  alias:
    type: string
    label: "Experiment short name/alias"
    sd:preview:
      position: 1

  query_data_rds:
    type: File
    label: "Experiment run through both Single-cell RNA-Seq and ATAC-Seq Dimensionality Reduction Analyses"
    doc: |
      Path to the RDS file to load Seurat object from. This file should include
      genes expression and chromatin accessibility information stored in the RNA
      and ATAC assays correspondingly. Additionally, 'pca', 'rnaumap', 'atac_lsi'
      and 'atacumap' dimensionality reductions should be present.
    'sd:upstreamSource': "sc_tools_sample/seurat_data_rds"
    'sd:localLabel': true

  rna_dimensions:
    type: int?
    default: 40
    label: "Dimensionality from the 'pca' reduction to use when constructing weighted nearest-neighbor graph before clustering (from 1 to 50)"
    doc: |
      Dimensionality from the 'pca' reduction to use when constructing weighted
      nearest-neighbor graph before clustering (from 1 to 50). If single value N
      is provided, use from 1 to N dimensions. If multiple values are provided,
      subset to only selected dimensions.
      Default: from 1 to 10

  atac_dimensions:
    type: int?
    default: 40
    label: "Dimensionality from the 'atac_lsi' reduction to use when constructing weighted nearest-neighbor graph before clustering (from 1 to 50)"
    doc: |
      Dimensionality from the 'atac_lsi' reduction to use when constructing weighted
      nearest-neighbor graph before clustering (from 1 to 50). If single value N
      is provided, use from 2 to N dimensions. If multiple values are provided,
      subset to only selected dimensions.
      Default: from 2 to 10

  resolution:
    type: string?
    default: "0.3 0.5 1.0"
    label: "Comma or space separated list of clustering resolutions"
    doc: |
      Clustering resolution applied to the constructed weighted nearest-neighbor
      graph. Can be set as an array.
      Default: 0.3, 0.5, 1.0

  atac_fragments_file:
    type: File?
    secondaryFiles:
    - .tbi
    label: "Cell Ranger ARC Count/Aggregate Experiment"
    doc: |
      Count and barcode information for every ATAC fragment used in the loaded Seurat
      object. File should be saved in TSV format with tbi-index file.
    'sd:upstreamSource': "sc_arc_sample/atac_fragments_file"

  genes_of_interest:
    type: string?
    default: null
    label: "Genes of interest to build gene expression and Tn5 insertion frequency plots"
    doc: |
      Genes of interest to build gene expression and Tn5 insertion frequency plots
      for the nearest peaks. If '--fragments' is not provided only gene expression
      plots will be built.
      Default: None

  identify_diff_genes:
    type: boolean?
    default: false
    label: "Identify differentially expressed genes (putative gene markers) between each pair of clusters for all resolutions"
    doc: |
      Identify differentially expressed genes (putative gene markers) between each
      pair of clusters for all resolutions.
      Default: false
    'sd:layout':
      advanced: true

  identify_diff_peaks:
    type: boolean?
    default: false
    label: "Identify differentially accessible peaks between each pair of clusters for all resolutions"
    doc: |
      Identify differentially accessible peaks between each pair of clusters for all resolutions.
      Default: false
    'sd:layout':
      advanced: true

  rna_minimum_logfc:
    type: float?
    default: 0.25
    label: "Include only those genes that on average have log fold change difference in expression between every tested pair of clusters not lower than this value"
    doc: |
      For putative gene markers identification include only those genes that
      on average have log fold change difference in expression between every
      tested pair of clusters not lower than this value. Ignored if '--diffgenes'
      is not set.
      Default: 0.25
    'sd:layout':
      advanced: true

  rna_minimum_pct:
    type: float?
    default: 0.1
    label: "Include only those genes that are detected in not lower than this fraction of cells in either of the two tested clusters"
    doc: |
      For putative gene markers identification include only those genes that
      are detected in not lower than this fraction of cells in either of the
      two tested clusters. Ignored if '--diffgenes' is not set.
      Default: 0.1
    'sd:layout':
      advanced: true

  atac_minimum_logfc:
    type: float?
    default: 0.25
    label: "Include only those peaks that on average have log fold change difference in the chromatin accessibility between every tested pair of clusters not lower than this value"
    doc: |
      For differentially accessible peaks identification include only those peaks that
      on average have log fold change difference in the chromatin accessibility between
      every tested pair of clusters not lower than this value. Ignored if '--diffpeaks'
      is not set.
      Default: 0.25
    'sd:layout':
      advanced: true

  atac_minimum_pct:
    type: float?
    default: 0.05
    label: "Include only those peaks that are detected in not lower than this fraction of cells in either of the two tested clusters"
    doc: |
      For differentially accessible peaks identification include only those peaks that
      are detected in not lower than this fraction of cells in either of the two tested
      clusters. Ignored if '--diffpeaks' is not set.
      Default: 0.05
    'sd:layout':
      advanced: true

  umap_spread:
    type: float?
    label: "UMAP Spread - the effective scale of embedded points (determines how clustered/clumped the embedded points are)"
    default: 1
    doc: |
      The effective scale of embedded points on UMAP. In combination with '--mindist'
      it determines how clustered/clumped the embedded points are.
      Default: 1
    'sd:layout':
      advanced: true

  umap_mindist:
    type: float?
    label: "UMAP Min. Dist. - controls how tightly the embedding is allowed compress points together"
    default: 0.3
    doc: |
      Controls how tightly the embedding is allowed compress points together on UMAP.
      Larger values ensure embedded points are moreevenly distributed, while smaller
      values allow the algorithm to optimise more accurately with regard to local structure.
      Sensible values are in the range 0.001 to 0.5.
      Default:  0.3
    'sd:layout':
      advanced: true

  umap_neighbors:
    type: int?
    label: "UMAP Neighbors Number - determines the number of neighboring points used"
    default: 30
    doc: |
      Determines the number of neighboring points used in UMAP. Larger values will result
      in more global structure being preserved at the loss of detailed local structure.
      In general this parameter should often be in the range 5 to 50.
      Default: 30
    'sd:layout':
      advanced: true

  umap_metric:
    type:
    - "null"
    - type: enum
      symbols:
      - "euclidean"
      - "cosine"
      - "correlation"
    label: "UMAP Dist. Metric - the metric to use to compute distances in high dimensional space"
    default: "cosine"
    doc: |
      The metric to use to compute distances in high dimensional space for UMAP.
      Default: cosine
    'sd:layout':
      advanced: true

  umap_method:
    type:
    - "null"
    - type: enum
      symbols:
      - "uwot"
      - "uwot-learn"
      - "umap-learn"
    label: "UMAP implementation to run (if set to 'umap-learn' use 'correlation' distance metric)"
    default: "uwot"
    doc: |
      UMAP implementation to run. If set to 'umap-learn' use --umetric 'correlation'
      Default: uwot
    'sd:layout':
      advanced: true

  parallel_memory_limit:
    type:
    - "null"
    - type: enum
      symbols:
      - "32"
    default: "32"
    label: "Maximum memory in GB allowed to be shared between the workers when using multiple CPUs"
    doc: |
      Maximum memory in GB allowed to be shared between the workers
      when using multiple --cpus.
      Forced to 32 GB
    'sd:layout':
      advanced: true

  vector_memory_limit:
    type:
    - "null"
    - type: enum
      symbols:
      - "64"
    default: "64"
    label: "Maximum vector memory in GB allowed to be used by R"
    doc: |
      Maximum vector memory in GB allowed to be used by R.
      Forced to 64 GB
    'sd:layout':
      advanced: true

  threads:
    type:
    - "null"
    - type: enum
      symbols:
      - "1"
    default: "1"
    label: "Number of cores/cpus to use"
    doc: |
      Number of cores/cpus to use
      Forced to 1
    'sd:layout':
      advanced: true


outputs:

  umap_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_res_plot_png
    label: "Clustered cells UMAP"
    doc: |
      Clustered cells UMAP.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Overall'
        Caption: 'Clustered cells UMAP'

  umap_spl_idnt_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_spl_idnt_res_plot_png
    label: "Split by dataset clustered cells UMAP"
    doc: |
      Split by dataset clustered cells UMAP.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Split by dataset clustered cells UMAP'

  cmp_gr_clst_spl_idnt_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_clst_spl_idnt_res_plot_png
    label: "Grouped by cluster split by dataset cells composition plot. Downsampled."
    doc: |
      Grouped by cluster split by dataset cells composition plot. Downsampled.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Overall'
        Caption: 'Grouped by cluster split by dataset cells composition plot. Downsampled.'

  cmp_gr_idnt_spl_clst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_idnt_spl_clst_res_plot_png
    label: "Grouped by dataset split by cluster cells composition plot. Downsampled."
    doc: |
      Grouped by dataset split by cluster cells composition plot. Downsampled.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Overall'
        Caption: 'Grouped by dataset split by cluster cells composition plot. Downsampled.'

  umap_spl_cnd_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_spl_cnd_res_plot_png
    label: "Split by grouping condition clustered cells UMAP"
    doc: |
      Split by grouping condition clustered cells UMAP.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per group'
        Caption: 'Split by grouping condition clustered cells UMAP'

  cmp_gr_clst_spl_cnd_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_clst_spl_cnd_res_plot_png
    label: "Grouped by cluster split by condition cells composition plot. Downsampled."
    doc: |
      Grouped by cluster split by condition cells composition plot. Downsampled.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per group'
        Caption: 'Grouped by cluster split by condition cells composition plot. Downsampled.'

  cmp_gr_cnd_spl_clst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_cnd_spl_clst_res_plot_png
    label: "Grouped by condition split by cluster cells composition plot. Downsampled."
    doc: |
      Grouped by condition split by cluster cells composition plot. Downsampled.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per group'
        Caption: 'Grouped by condition split by cluster cells composition plot. Downsampled.'

  umap_spl_ph_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/umap_spl_ph_res_plot_png
    label: "Split by cell cycle phase clustered cells UMAP"
    doc: |
      Split by cell cycle phase clustered cells UMAP.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Split by cell cycle phase clustered cells UMAP'

  cmp_gr_ph_spl_idnt_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_ph_spl_idnt_res_plot_png
    label: "Grouped by cell cycle phase split by dataset cells composition plot. Downsampled."
    doc: |
      Grouped by cell cycle phase split by dataset cells composition plot. Downsampled.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Grouped by cell cycle phase split by dataset cells composition plot. Downsampled.'

  cmp_gr_ph_spl_clst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cmp_gr_ph_spl_clst_res_plot_png
    label: "Grouped by cell cycle phase split by cluster cells composition plot. Downsampled."
    doc: |
      Grouped by cell cycle phase split by cluster cells composition plot. Downsampled.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Per dataset'
        Caption: 'Grouped by cell cycle phase split by cluster cells composition plot. Downsampled.'

  xpr_avg_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_avg_res_plot_png
    label: "Log normalized scaled average gene expression per cluster"
    doc: |
      Log normalized scaled average gene expression per cluster.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Gene expression'
        Caption: 'Log normalized scaled average gene expression per cluster'

  xpr_per_cell_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_per_cell_res_plot_png
    label: "Log normalized gene expression on cells UMAP"
    doc: |
      Log normalized gene expression on cells UMAP.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Gene expression'
        Caption: 'Log normalized gene expression on cells UMAP'

  xpr_dnst_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/xpr_dnst_res_plot_png
    label: "Log normalized gene expression density per cluster"
    doc: |
      Log normalized gene expression density per cluster.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Gene expression'
        Caption: 'Log normalized gene expression density per cluster'

  cvrg_res_plot_png:
    type:
    - "null"
    - type: array
      items: File
    outputSource: sc_wnn_cluster/cvrg_res_plot_png
    label: "Tn5 insertion frequency plot around gene"
    doc: |
      Tn5 insertion frequency plot around gene.
      PNG format
    'sd:visualPlugins':
    - image:
        tab: 'Genome coverage'
        Caption: 'Tn5 insertion frequency plot around gene'

  gene_markers_tsv:
    type: File?
    outputSource: sc_wnn_cluster/gene_markers_tsv
    label: "Differentially expressed genes between each pair of clusters for all resolutions"
    doc: |
      Differentially expressed genes between each pair of clusters for all resolutions.
      TSV format
    'sd:visualPlugins':
    - syncfusiongrid:
        tab: 'Gene markers'
        Title: 'Differentially expressed genes between each pair of clusters for all resolutions'

  peak_markers_tsv:
    type: File?
    outputSource: sc_wnn_cluster/peak_markers_tsv
    label: "Differentially accessible peaks between each pair of clusters for all resolutions"
    doc: |
      Differentially accessible peaks between each pair of clusters for all resolutions.
      TSV format
    'sd:visualPlugins':
    - syncfusiongrid:
        tab: 'Diff. peaks'
        Title: 'Differentially accessible peaks between each pair of clusters for all resolutions'

  ucsc_cb_config_data:
    type: File
    outputSource: compress_cellbrowser_config_data/compressed_folder
    label: "Compressed directory with UCSC Cellbrowser configuration data"
    doc: |
      Compressed directory with UCSC Cellbrowser configuration data.

  ucsc_cb_html_data:
    type: Directory
    outputSource: sc_wnn_cluster/ucsc_cb_html_data
    label: "Directory with UCSC Cellbrowser html data"
    doc: |
      Directory with UCSC Cellbrowser html data.

  ucsc_cb_html_file:
    type: File
    outputSource: sc_wnn_cluster/ucsc_cb_html_file
    label: "Open in UCSC Cell Browser"
    doc: |
      HTML index file from the directory with UCSC Cellbrowser html data.
    'sd:visualPlugins':
    - linkList:
        tab: 'Overview'
        target: "_blank"

  seurat_data_rds:
    type: File
    outputSource: sc_wnn_cluster/seurat_data_rds
    label: "Processed Seurat data in RDS format"
    doc: |
      Processed Seurat data in RDS format

  sc_wnn_cluster_stdout_log:
    type: File
    outputSource: sc_wnn_cluster/stdout_log
    label: "stdout log generated by sc_wnn_cluster step"
    doc: |
      stdout log generated by sc_wnn_cluster step

  sc_wnn_cluster_stderr_log:
    type: File
    outputSource: sc_wnn_cluster/stderr_log
    label: "stderr log generated by sc_wnn_cluster step"
    doc: |
      stderr log generated by sc_wnn_cluster step


steps:

  sc_wnn_cluster:
    doc: |
      Clusters multiome ATAC and RNA-Seq datasets, identifies
      gene markers and differentially accessible peaks
    run: ../tools/sc-wnn-cluster.cwl
    in:
      query_data_rds: query_data_rds
      rna_dimensions: rna_dimensions
      atac_dimensions: atac_dimensions
      resolution:
        source: resolution
        valueFrom: $(split_numbers(self))
      atac_fragments_file: atac_fragments_file
      genes_of_interest:
        source: genes_of_interest
        valueFrom: $(split_features(self))
      identify_diff_genes: identify_diff_genes
      identify_diff_peaks: identify_diff_peaks
      rna_minimum_logfc: rna_minimum_logfc
      rna_minimum_pct: rna_minimum_pct
      atac_minimum_logfc: atac_minimum_logfc
      atac_minimum_pct: atac_minimum_pct
      only_positive_diff_genes:
        default: true
      rna_test_to_use: 
        default: wilcox
      atac_test_to_use:
        default: LR
      umap_spread: umap_spread
      umap_mindist: umap_mindist
      umap_neighbors: umap_neighbors
      umap_metric: umap_metric
      umap_method: umap_method
      verbose:
        default: true      
      export_ucsc_cb:
        default: true
      parallel_memory_limit:
        source: parallel_memory_limit
        valueFrom: $(parseInt(self))
      vector_memory_limit:
        source: vector_memory_limit
        valueFrom: $(parseInt(self))
      threads:
        source: threads
        valueFrom: $(parseInt(self))
    out:
    - umap_res_plot_png
    - umap_spl_idnt_res_plot_png
    - cmp_gr_clst_spl_idnt_res_plot_png
    - cmp_gr_idnt_spl_clst_res_plot_png
    - umap_spl_cnd_res_plot_png
    - cmp_gr_clst_spl_cnd_res_plot_png
    - cmp_gr_cnd_spl_clst_res_plot_png
    - umap_spl_ph_res_plot_png
    - cmp_gr_ph_spl_idnt_res_plot_png
    - cmp_gr_ph_spl_clst_res_plot_png
    - xpr_avg_res_plot_png
    - xpr_per_cell_res_plot_png
    - xpr_dnst_res_plot_png
    - cvrg_res_plot_png
    - gene_markers_tsv
    - peak_markers_tsv
    - ucsc_cb_config_data
    - ucsc_cb_html_data
    - ucsc_cb_html_file
    - seurat_data_rds
    - stdout_log
    - stderr_log

  compress_cellbrowser_config_data:
    run: ../tools/tar-compress.cwl
    in:
      folder_to_compress: sc_wnn_cluster/ucsc_cb_config_data
    out:
    - compressed_folder


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

label: "Single-cell WNN Cluster Analysis"
s:name: "Single-cell WNN Cluster Analysis"
s:alternateName: "Clusters multiome ATAC and RNA-Seq datasets, identifies gene markers and differentially accessible peaks"

s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows-datirium/master/workflows/sc-wnn-cluster.cwl
s:codeRepository: https://github.com/Barski-lab/workflows-datirium
s:license: http://www.apache.org/licenses/LICENSE-2.0

s:isPartOf:
  class: s:CreativeWork
  s:name: Common Workflow Language
  s:url: http://commonwl.org/

s:creator:
- class: s:Organization
  s:legalName: "Cincinnati Children's Hospital Medical Center"
  s:location:
  - class: s:PostalAddress
    s:addressCountry: "USA"
    s:addressLocality: "Cincinnati"
    s:addressRegion: "OH"
    s:postalCode: "45229"
    s:streetAddress: "3333 Burnet Ave"
    s:telephone: "+1(513)636-4200"
  s:logo: "https://www.cincinnatichildrens.org/-/media/cincinnati%20childrens/global%20shared/childrens-logo-new.png"
  s:department:
  - class: s:Organization
    s:legalName: "Allergy and Immunology"
    s:department:
    - class: s:Organization
      s:legalName: "Barski Research Lab"
      s:member:
      - class: s:Person
        s:name: Michael Kotliar
        s:email: mailto:misha.kotliar@gmail.com
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898


doc: |
  Single-cell WNN Cluster Analysis

  Clusters multiome ATAC and RNA-Seq datasets, identifies gene markers
  and differentially accessible peaks.