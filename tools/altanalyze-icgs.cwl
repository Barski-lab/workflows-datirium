cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/altanalyze:v0.0.4


inputs:

  bash_script:
    type: string?
    default: |
      #!/bin/bash
      
      # Copy altanalyze to the current working directory
      # which is mount with -rw- permissions. Otherwise 
      # we can't download anything because by default
      # container is run by cwltool with --read-only
      
      cp -r /opt/altanalyze .

      GENOME_DATA=$0
      FBC_MATRIX=$1
      GENOME_DATA_BASENAME=`basename ${GENOME_DATA}`
      ARR=(${GENOME_DATA_BASENAME//__/ })
      ENSEMBL_VERSION=${ARR[0]}
      SPECIES=${ARR[1]}

      echo "Load ${SPECIES} from ${ENSEMBL_VERSION}"
      ln -s ${GENOME_DATA} ./altanalyze/AltDatabase/${ENSEMBL_VERSION}
      mkdir ./altanalyze/userdata/
      cp ${FBC_MATRIX} ./altanalyze/userdata/raw_feature_bc_matrices_h5.h5
      python ./altanalyze/AltAnalyze.py --species ${SPECIES} \
      --platform RNASeq --runICGS yes \
      --ChromiumSparseMatrix ./altanalyze/userdata/ --output ./altanalyze/userdata/ \
      --expname icgs ${@:2}
    inputBinding:
      position: 5
    doc: |
      Bash script to run AltAnalyze ICGS with provided parameters

  genome_data:
    type: Directory
    inputBinding:
      position: 6
    doc: |
      Ensembl database from the altanalyze-prepare-genome.cwl pipeline.
      --species parameter and Ensembl version will be resolved based on
      this folder basename

  feature_bc_matrices_h5:
    type: File
    inputBinding:
      position: 7
    doc: |
      Feature-barcode matrices in HDF5 format. Output from Cell Ranger

  exclude_cell_cycle:
    type: boolean?
    default: false
    inputBinding:
      prefix: "--excludeCellCycle"
      position: 8
      valueFrom: $(self?"yes":"no")

  remove_outliers:
    type: boolean?
    default: true
    inputBinding:
      prefix: "--removeOutliers"
      position: 9
      valueFrom: $(self?"yes":"no")

  restrict_by:
    type:
    - "null"
    - type: enum
      symbols:
      - "None"
      - "protein_coding"
    default: "None"
    inputBinding:
      prefix: "--restrictBy"
      position: 10

  downsample:
    type: int?
    default: 5000
    inputBinding:
      prefix: "--downsample"
      position: 11

  marker_pearson_cutoff:
    type: float?
    default: 0.3
    inputBinding:
      prefix: "--markerPearsonCutoff"
      position: 12


outputs:

  icgs_data:
    type: Directory
    outputBinding: 
      glob: "altanalyze/userdata/ICGS-NMF"

  expression_matrix_file:
    type: File
    outputBinding:
      glob: "altanalyze/userdata/ExpressionInput/exp.icgs.txt"

  annotation_metadata_file:
    type: File
    outputBinding:
      glob: "altanalyze/userdata/ICGS-NMF/FinalGroups-CellTypesFull.txt"

  cell_coordinates_file:
    type: File
    outputBinding:
      glob: "altanalyze/userdata/ICGS-NMF/FinalMarkerHeatmap-UMAP_coordinates.txt"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: ["bash", "-c"]

stdout: altanalyze_icgs_stdout.log
stderr: altanalyze_icgs_stderr.log


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf


s:name: "altanalyze-icgs"
s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/tools/altanalyze-icgs.cwl
s:codeRepository: https://github.com/Barski-lab/workflows
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
    - class: s:Organization
      s:legalName: "Salomonis Research Lab"
      s:member:
      - class: s:Person
        s:name: Stuart Hay
        s:email: mailto:haysb91@gmail.com


doc: |
  Runs AltAnalyze Iterative Clustering and Guide-gene Selection for 10X Genomics data

s:about: |
  Runs AltAnalyze Iterative Clustering and Guide-gene Selection for 10X Genomics data
