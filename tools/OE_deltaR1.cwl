cwlVersion: v1.2
class: CommandLineTool
label: PreclinicalMRI.dynamic.compute_dataset_delta_Ct tool wrapper
doc: |
    Delta-R1(t) for Oxygen Enhanced (OE) MRI analysis pipelines.
    Estimates dynamic relaxation rate R1(t) from signal S(t), [efficiency,] and T1 
    maps, then compares the average R1(t) for the baseline and enhancing periods.

    (CWL wrapper for PreclinicalMRI.dynamic.oe.compute_dataset_delta_R1)
    
    REFERENCES:
      - Preclinical MRI Wiki. <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/wikis/home>
      - Wrapped function: <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/blob/main/src/PreclinicalMRI/dynamic/oe.py>

    NOTES:
    - The following defaults override the defaults:
        - `oe_path` is a file, from which the base-name (passed as argument)
          and extension (used to set `oe_im_ext`) are extracted.
        - `oe_meta_ext` is hard-set to '.json', as current implementation does
          not support any other file types (uses json.load).
        - `no_audit` is set to 1
      - Settings like `data_dir`, `output_dir`, `maps_dir`, `overwrite`
        are set to work with CWL, i.e. reading all inputs from the staging
        directory, and writing all outputs to the output directory.
      - Logs are time-stamped and auto-renamed by QbiRunner. 
        This wrapper renames them to a consistent `OE_deltaR1.<ext>`.

    SEE ALSO: DCE_deltaCt.cwl, madym_T1.cwl

hints:
  DockerRequirement:
    dockerPull: registry.gitlab.com/manchester_qbi/preclinical_mri/core_pipelines:latest

requirements:
  InlineJavascriptRequirement:
    expressionLib:
    - { $include: utils:utils.js }
  ShellCommandRequirement: {}
  InitialWorkDirRequirement:
    listing: 
      - $(inputs.oe_path)
      - $(inputs.T1_path)
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml
baseCommand: python
arguments:
  - prefix: -m
    valueFrom: qbidcemri.processes.OE_deltaR1
  # - prefix: --data_dir
  #   valueFrom: $(runtime.outdir)
  - prefix: --output_dir
    valueFrom: $(runtime.outdir)
  - prefix: --maps_dir
    valueFrom: $(runtime.outdir)
  # - prefix: --audit_dir
  #   valueFrom: $(runtime.outdir)
  # - prefix: --audit_log
  #   valueFrom: .audit # see NOTES
  - prefix: --program_log
    valueFrom: .log # see NOTES
  - prefix: --config_log
    valueFrom: .cfg # see NOTES
  - prefix: --overwrite
    valueFrom: "1"
  - prefix: --no_audit
    valueFrom: "1"
  - prefix: --oe_im_ext
    valueFrom: $( extension2(inputs.oe_path) )
  - prefix: --oe_meta_ext
    valueFrom: .json # see NOTES

inputs:
  oe_path:
    label: Path to OE data
    doc: |
      Relative path to the OE data S(t), e.g. 'oe/oe_dyn.nii.gz'
    type: File
    secondaryFiles:
      - pattern: ^^.json # see NOTES
        required: true
    inputBinding:
      prefix: --oe_path
      valueFrom: $( nameroot2(self) )
  oe_limits:
    label: Baseline and enhancing time periods [B0, B1, E0, E1]
    doc: |
      4 element integer list [B0, B1, E0, E1], specifying the baseline and enhancing time periods
    type: int[]
    inputBinding:
      prefix: --oe_limits
  T1_path:
    label: Path to T1 map
    doc: Relative path to the T1 map (required)
    type: File
    inputBinding:
      prefix: --T1_path
  efficiency_path:
    label: Path to efficiency map
    type: File?
    inputBinding:
      prefix: --efficiency_path
  roi_path:
    label: Path to ROI map
    type: File?
    # format: ??
    inputBinding:
      prefix: --roi_path
  average_fun:
    label: Method used for temporal average{median, mean}
    default: median
    type: utils:custom_types.yml#average_method?
    inputBinding:
      prefix: --average_fun
  alternative:
    label: Hypothesis t-test {'two-sided', 'less', 'greater'}
    default: less
    type: utils:custom_types.yml#hypothesis_test?
    inputBinding:
      prefix: --alternative
  equal_var:
    label: Assume equal variance in pre/post enhancing periods
    default: true
    type: boolean?
    inputBinding:
      prefix: --equal_var 1
      shellQuote: false
  no_log:
    label: Switch off program logging
    type: boolean?
    inputBinding:
      prefix: --no_log 1
      shellQuote: false

outputs:
  R1_t:
    label: Relaxivity time series
    type: File
    outputBinding: { glob: R1_t.nii.gz }
  delta_R1:
    label: Difference between enhancing and baseline periods
    type: File
    outputBinding: { glob: delta_R1.nii.gz }
  R1_baseline:
    label: Average R1 in baseline period
    type: File
    outputBinding: { glob: R1_baseline.nii.gz }
  R1_enhancing:
    label: Average R1 in enhancing period
    type: File
    outputBinding: { glob: R1_enhancing.nii.gz }
  R1_p_vals:
    label: P-values comparing R1 in baseline vs enhancing periods
    type: File
    outputBinding: { glob: R1_p_vals.nii.gz }
  S_p_vals:
    label: P-values comparing signal in baseline vs enhancing periods
    type: File
    outputBinding: { glob: S_p_vals.nii.gz }
  logs:
    type: File[]
    outputBinding:
      glob: run_OE_deltaR1.*
      outputEval: | # Rename: run_OE_deltaR1.{ext}{date}_{time}.txt -> OE_deltaR1.{ext}
        ${
          self.forEach(function(f) {
            f.basename = f.basename.replace(/\d{8}_\d{6}.txt/, "").replace(/run_/, "");
            return f;
          });
          return self;
        }

$namespaces:
  utils: ../utils/
#   edam: http://edamontology.org/
#   iana: https://www.iana.org/assignments/media-types/