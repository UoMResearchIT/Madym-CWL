cwlVersion: v1.2
class: CommandLineTool
label: qbidcemri.processes.OE_DCE_summary tool wrapper
doc: |
    Apply ROI masks to maps, generate significance maps and summary statistics.

    For every `ROI` in `ROI_MASKS_DIR/*.nii[.gz]`, returns:

    - `ROI_DIR` - a directory containing masked maps
    - `ROI_map_stats.csv` - a table of summary statistics for each masked map

    The set of masked maps in `ROI_DIR` is defined by `*_MAP_LOCATIONS` settings
    in a YAML `CONFIG` file:
    
    a. For every `(SRC, TGT)` tuple in `COPY_MAP_LOCATIONS` apply `ROI` to
        `DATA_DIR/SRC.nii.gz` and save masked map to `ROI_DIR/TGT.nii.gz`

    b. For every `(SRC, TGT, OP)` tuple in `CONVERTED_MAP_LOCATIONS` apply `ROI`
        and operation `OP ('reciprocal' or 'zero-mask')` to `DATA_DIR/SRC.nii.gz`
        and save converted map to `ROI_DIR/TGT.nii.gz`

    c. For every `(SRC, TGT)` tuple in `P_VAL_MAP_LOCATIONS` apply `ROI` to
        `DATA_DIR/SRC.nii.gz` and use `timeseries.enhancing_maps` to
        create binary significance maps:

        - `ROI_DIR/TGT_sig.nii.gz`  
        - `ROI_DIR/TGT_sig_bf.nii.gz`  
        - `ROI_DIR/TGT_sig_forman.nii.gz`  

    d. For every `KEY, SRC` in the `DCE_MAP_LOCATIONS` dictionary (containing
        **at least** the keys `v_e`, `v_p`), apply `ROI` to `DATA_DIR/SRC.nii.gz`
        in addition to the condition: `(v_e >= 0) & (v_e + v_p <= 1.0)`
        Save masked maps to `FINAL_MAPS_DIR/ROI/DCE_KEY.nii.gz`

    Other settings (e.g. P-value, cluster-significance threshold, etc.) are NOT
    exposed in this wrapper, but can be provided in the `CONFIG` file.
    See the function documentation for details.

    REFERENCES:
      - Preclinical MRI Wiki. <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/wikis/home>
      - Wrapped function: <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/blob/main/src/PreclinicalMRI/pipelines/qMRI_processes/OE_DCE_summary.py>

    SEE ALSO: ../workflows/DCE_VFA.cwl, ../workflows/OE_IR.cwl

hints:
  DockerRequirement:
    dockerPull: registry.gitlab.com/manchester_qbi/preclinical_mri/core_pipelines:latest

requirements:
  ShellCommandRequirement: {}
  LoadListingRequirement: {loadListing: "deep_listing"}
  InitialWorkDirRequirement:
    listing: 
      - $(inputs.roi_masks_dir)
      - $(inputs.shared_masks_dir)
      - $(inputs.data_dir)

baseCommand: python
arguments:
  - prefix: -m
    valueFrom: qbidcemri.processes.OE_DCE_summary
  - prefix: --output_dir
    valueFrom: $(runtime.outdir)
  - prefix: --final_maps_dir
    valueFrom: masked_maps
  - prefix: --log_file
    valueFrom: OE_DCE_summary.log

inputs:
  config:
    label: YAML configuration file
    type: File
    inputBinding:
      prefix: --config
  data_dir:
    label: Base directory for all relative paths in CONFIG
    type: Directory
    inputBinding:
      prefix: --data_dir
  roi_masks_dir:
    label: Directory containing ROI masks
    type: Directory?
    inputBinding:
      prefix: --roi_masks_dir
  shared_masks_dir:
    label: Directory with shared ROI masks
    type: Directory?
    inputBinding:
      prefix: --shared_masks_dir
  search_string:
    label: String to match against SHARED_MASKS_DIR/* file tokens
    type: string?
    inputBinding:
      prefix: --search_string
  debug:
    label: Print debug messages
    type: boolean?
    inputBinding:
      prefix: --debug
      shellQuote: false

outputs:
  roi_map_stats:
    label: table(s) of summary statistics for each masked map
    type: File[]
    outputBinding: { glob: "*_map_stats.csv" }
  roi_dir:
    label: directory(ies) containing masked maps
    type: Directory[]
    outputBinding: { glob: "masked_maps/*" }
  log_file:
    type: File
    outputBinding: { glob: "OE_DCE_summary.log" }