cwlVersion: v1.0
class: Workflow


requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement


'sd:upstream':
  genome_indices:
  - "genome-indices.cwl"
  - "https://github.com/datirium/workflows/workflows/genome-indices.cwl"


inputs:

  alias:
    type: string
    label: "Experiment short name/Alias"
    sd:preview:
      position: 1

  fastq_file_1:
    type:
    - File
    - type: array
      items: File
    format: "http://edamontology.org/format_1930"
    label: "FASTQ file(s) 1 (optionally compressed)"
    doc: "FASTQ file(s) 1 (optionally compressed)"

  fastq_file_2:
    type:
    - File
    - type: array
      items: File
    format: "http://edamontology.org/format_1930"
    label: "FASTQ file(s) 2 (optionally compressed)"
    doc: "FASTQ file(s) 2 (optionally compressed)"

  sc_technology:
    type:
    - type: enum
      name: "sc_technology"
      symbols:
      - 10XV2       # 2 input files 
      - 10XV3       # 2 input files 
      - CELSEQ      # 2 input files
      - CELSEQ2     # 2 input files
      - DROPSEQ     # 2 input files
      - INDROPSV1   # 2 input files
      - INDROPSV2   # 2 input files
      - SCRUBSEQ    # 2 input files
      - SURECELL    # 2 input files
    label: "Single-cell technology used"
    doc: "Single-cell technology used"

  workflow_type:
    type:
    - "null"
    - type: enum
      name: "workflow_type"
      symbols:
      - standard
      - lamanno
      - nucleus
      - kite
    default: "standard"
    label: "Workflow type"
    doc: |
      Type of workflow. Use lamanno to calculate RNA velocity based
      on La Manno et al. 2018 logic. Use nucleus to calculate RNA
      velocity on single-nucleus RNA-seq reads.
      Default: standard

  genome_fasta_file:
    type: File
    format: "http://edamontology.org/format_1929"
    label: "Reference genome FASTA file"
    doc: "Reference genome FASTA file that includes all chromosomes"
    'sd:upstreamSource': "genome_indices/fasta_output"

  annotation_gtf_file:
    type: File
    format: "http://edamontology.org/format_2306"
    label: "GTF annotation file"
    doc: "GTF annotation file that includes refGene and mitochondrial DNA annotations"
    'sd:upstreamSource': "genome_indices/annotation_gtf"

  threads:
    type: int?
    default: 4
    label: "Number of threads"
    doc: "Number of threads for those steps that support multithreading"
    'sd:layout':
      advanced: true

  memory_limit:
    type: string?
    default: "4G"
    label: "Maximum memory used"
    doc: "Maximum memory used"
    'sd:layout':
      advanced: true


outputs:

  counts_unfiltered_folder:
    type: File
    outputSource: compress_counts_folder/compressed_folder
    label: "Compressed folder with count matrix files"
    doc: |
      Compressed folder with count matrix files generated by bustools count

  whitelist_file:
    type: File
    outputSource: generate_counts_matrix/whitelist_file
    label: "Whitelisted barcodes"
    doc: |
      Whitelisted barcodes that correspond to the used single-cell technology

  bustools_inspect_report:
    type: File
    outputSource: generate_counts_matrix/bustools_inspect_report
    label: "Report summarizing BUS file content"
    doc: |
      Report summarizing BUS file content generated by bustools inspect

  collected_statistics:
    type: File
    outputSource: collect_statistics/collected_statistics
    label: "Collected statistics in Markdown format"
    doc: "Collected statistics in Markdown format"
    'sd:visualPlugins':
    - markdownView:
        tab: 'Overview'

  kallisto_bus_report:
    type: File
    outputSource: generate_counts_matrix/kallisto_bus_report
    label: "Pseudoalignment report"
    doc: |
      Pseudoalignment report generated by kallisto bus

  ec_mapping_file:
    type: File
    outputSource: generate_counts_matrix/ec_mapping_file
    label: "Mapping equivalence classes to transcripts"
    doc: |
      Mapping equivalence classes to transcripts generated by kallisto bus

  transcripts_file:
    type: File
    outputSource: generate_counts_matrix/transcripts_file
    label: "Transcript names"
    doc: |
      Transcript names file generated by kallisto bus

  not_sorted_bus_file:
    type: File
    outputSource: generate_counts_matrix/not_sorted_bus_file
    label: "Not sorted BUS file"
    doc: |
      Not sorted BUS file generated by kallisto bus

  corrected_sorted_bus_file:
    type: File
    outputSource: generate_counts_matrix/corrected_sorted_bus_file
    label: "Sorted BUS file with corrected barcodes"
    doc: |
      Sorted BUS file with corrected barcodes generated by bustools correct

  prepare_indices_stdout_log:
    type: File
    outputSource: prepare_indices/stdout_log
    label: stdout log generated by kb ref
    doc: |
      stdout log generated by kb ref

  prepare_indices_stderr_log:
    type: File
    outputSource: prepare_indices/stderr_log
    label: stderr log generated by kb ref
    doc: |
      stderr log generated by kb ref

  generate_counts_matrix_stdout_log:
    type: File
    outputSource: generate_counts_matrix/stdout_log
    label: stdout log generated by kb count
    doc: |
      stdout log generated by kb count

  generate_counts_matrix_stderr_log:
    type: File
    outputSource: generate_counts_matrix/stderr_log
    label: stderr log generated by kb count
    doc: |
      stderr log generated by kb count


steps:

  prepare_indices:
    run: ../tools/kb-ref.cwl
    in:
      genome_fasta_file: genome_fasta_file
      annotation_gtf_file: annotation_gtf_file
      workflow_type: workflow_type
    out:
    - kallisto_index_file
    - tx_to_gene_mapping_file
    - tx_fasta_file
    - intron_fasta_file
    - tx_to_capture_mapping_file
    - intron_tx_to_capture_mapping_file
    - stdout_log
    - stderr_log

  extract_fastq_1:
    run: ../tools/extract-fastq.cwl
    in:
      compressed_file: fastq_file_1
      output_prefix:
        default: "read_1"
    out:
    - fastq_file

  extract_fastq_2:
    run: ../tools/extract-fastq.cwl
    in:
      compressed_file: fastq_file_2
      output_prefix:
        default: "read_2"
    out:
    - fastq_file

  generate_counts_matrix:
    run: ../tools/kb-count.cwl
    in:
      fastq_file_1: extract_fastq_1/fastq_file
      fastq_file_2: extract_fastq_2/fastq_file
      kallisto_index_file: prepare_indices/kallisto_index_file
      tx_to_gene_mapping_file: prepare_indices/tx_to_gene_mapping_file
      sc_technology: sc_technology
      workflow_type: workflow_type
      h5ad:
        default: true
      tx_to_capture_mapping_file: prepare_indices/tx_to_capture_mapping_file
      intron_tx_to_capture_mapping_file: prepare_indices/intron_tx_to_capture_mapping_file
      threads: threads
      memory_limit: memory_limit
    out:
    - counts_unfiltered_folder
    - whitelist_file
    - bustools_inspect_report
    - kallisto_bus_report
    - ec_mapping_file
    - transcripts_file
    - not_sorted_bus_file
    - corrected_sorted_bus_file
    - stdout_log
    - stderr_log

  compress_counts_folder:
    run: ../tools/tar-compress.cwl
    in:
      folder_to_compress: generate_counts_matrix/counts_unfiltered_folder
    out:
    - compressed_folder

  collect_statistics:
    run:
      cwlVersion: v1.0
      class: CommandLineTool
      hints:
      - class: DockerRequirement
        dockerPull: rackspacedot/python37
      inputs:
        script:
          type: string?
          default: |
            #!/usr/bin/env python3
            import sys, json, os, yaml
            kallisto_name = os.path.splitext(os.path.basename(sys.argv[1]))[0]
            bustools_name = os.path.splitext(os.path.basename(sys.argv[2]))[0]
            with open(sys.argv[1], "r") as kallisto_stream:
              with open(sys.argv[2], "r") as bustools_stream:
                with open("collected_statistics.md", "w") as report_stream:
                  combined_data = {
                    "Pseudoalignment statistics": json.load(kallisto_stream),
                    "BUS statistics": json.load(bustools_stream)
                  }
                  for line in yaml.dump(combined_data, width=1000, sort_keys=False).split("\n"):
                    if not line.strip():
                      continue
                    if line.startswith("  - "):
                      report_stream.write(line+"\n")
                    elif line.startswith("    "):
                      report_stream.write("<br>"+line+"\n")
                    elif line.startswith("  "):
                      report_stream.write("- "+line+"\n")
                    else:
                      report_stream.write("### "+line+"\n")
          inputBinding:
            position: 5
        kallisto_report:
          type: File
          inputBinding:
            position: 6
        bustools_report:
          type: File
          inputBinding:
            position: 7
      outputs:
        collected_statistics:
          type: File
          outputBinding:
            glob: "*"
      baseCommand: ["python3", "-c"]
    in:
      kallisto_report: generate_counts_matrix/kallisto_bus_report
      bustools_report: generate_counts_matrix/bustools_inspect_report
    out:
    - collected_statistics


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

s:name: "Single-Cell Preprocessing Pipeline"
label: "Single-Cell Preprocessing Pipeline"
s:alternateName: "Single-Cell Preprocessing Pipeline"

s:downloadUrl: https://raw.githubusercontent.com/datirium/workflows/master/workflows/single-cell-preprocess.cwl
s:codeRepository: https://github.com/datirium/workflows
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
  Devel version of Single-Cell Preprocessing Pipeline
  ===================================================