cwlVersion: v1.2
class: CommandLineTool
label: PreclinicalMRI.dynamic.compute_dataset_delta_Ct tool wrapper
doc: |
    Delta-C(t) for Dynamic Contrast Enhanced (DCE) MRI analysis pipelines.
    Estimates concentration C(t) from signal S(t) and T1 maps, then compares
    the average C(t) for the baseline and enhancing periods.

    (CWL wrapper for PreclinicalMRI.dynamic.dce.compute_dataset_delta_Ct)
    
    REFERENCES:
      - Preclinical MRI Wiki. <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/wikis/home>
      - Wrapped function: <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/blob/main/src/PreclinicalMRI/dynamic/dce.py>

    NOTES:
    - The following defaults override the defaults:
        - `dce_path` is a file, from which the base-name (passed as argument)
          and extension (used to set `dce_im_ext`) are extracted.
        - `dce_meta_ext` is hard-set to '.json', as current implementation does
          not support any other file types (uses json.load).
        - `no_audit` is set to 1
      - Settings like `data_dir`, `output_dir`, `maps_dir`, `overwrite`
        are set to work with CWL, i.e. reading all inputs from the staging
        directory, and writing all outputs to the output directory.
      - Logs are time-stamped and auto-renamed by QbiRunner. 
        This wrapper renames them to a consistent `DCE_deltaCt.<ext>`.

    SEE ALSO: OE_deltaR1.cwl, madym_DCE.cwl

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
      - $(inputs.dce_path)
      - $(inputs.T1_path)
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml

baseCommand: python
arguments:
  - prefix: -m
    valueFrom: qbidcemri.processes.DCE_deltaCt
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
  - prefix: --dce_im_ext
    valueFrom: $( extension2(inputs.dce_path) )
  - prefix: --dce_meta_ext
    valueFrom: .json # see NOTES

inputs:
  dce_path:
    label: Path to DCE data
    doc: |
      Relative path to the DCE data S(t), e.g. 'dce/dyn.nii.gz'
    type: File
    secondaryFiles:
      - pattern: ^^.json # see NOTES
        required: true
    inputBinding:
      prefix: --dce_path
      valueFrom: $( nameroot2(self) )
  dce_limits:
    label: Baseline and enhancing time periods [B0, B1, E0, E1]
    doc: |
      4 element integer list [B0, B1, E0, E1], specifying the baseline and enhancing time periods
      B1 is also used to set the time points to use for M0 calculation.
    type: int[]
    inputBinding:
      prefix: --dce_limits
  T1_path:
    label: Path to T1 map
    doc: Relative path to the T1 map (required)
    type: File
    inputBinding:
      prefix: --T1_path
  roi_path:
    label: Path to ROI map
    type: File?
    # format: ??
    inputBinding:
      prefix: --roi_path
  relax_coeff:
    label: Relaxivity coefficient for the contrast agent (ms)
    default: 0
    type: double
    inputBinding:
      prefix: --relax_coeff
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
  C_t:
    label: Concentration time series
    type: File
    outputBinding: { glob: C_t.nii.gz }
  delta_C:
    label: Difference between enhancing and baseline periods
    type: File
    outputBinding: { glob: delta_C.nii.gz }
  C_baseline:
    label: Average concentration in baseline period
    type: File
    outputBinding: { glob: C_baseline.nii.gz }
  C_enhancing:
    label: Average concentration in enhancing period
    type: File
    outputBinding: { glob: C_enhancing.nii.gz }
  C_p_vals:
    label: P-values comparing concentration in baseline vs enhancing periods
    type: File
    outputBinding: { glob: C_p_vals.nii.gz }
  S_p_vals:
    label: P-values comparing signal in baseline vs enhancing periods
    type: File
    outputBinding: { glob: S_p_vals.nii.gz }
  logs:
    type: File[]
    outputBinding:
      glob: run_DCE_deltaCt.*
      outputEval: | # Rename: run_DCE_deltaCt.{ext}{date}_{time}.txt -> DCE_deltaCt.{ext}
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