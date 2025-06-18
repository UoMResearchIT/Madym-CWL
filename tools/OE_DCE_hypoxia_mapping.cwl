cwlVersion: v1.2
class: CommandLineTool
label: qbidcemri.processes.OE_DCE_hypoxia_mapping tool wrapper
doc: |
    Generates hypoxia maps from DCE and OE p-value maps:

    - perfused_frac: DCE p-value < SIG_LEVEL
    - non_perfused_frac: DCE p-value > SIG_LEVEL
    - pOxyR: DCE p-value < SIG_LEVEL and OE p-value > SIG_LEVEL
    - pOxyE: DCE p-value < SIG_LEVEL and OE p-value < SIG_LEVEL

    REFERENCES:
      - Preclinical MRI Wiki. <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/wikis/home>
      - Wrapped function: <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/blob/main/src/PreclinicalMRI/pipelines/qMRI_processes/OE_DCE_hypoxia_mapping.py>

    NOTES:
    - The following defaults override the defaults:
      - Settings like `data_dir`, `output_dir`, `maps_dir`, `overwrite`
        are set to work with CWL, i.e. reading all inputs from the staging
        directory, and writing all outputs to the output directory.
      - Logs are time-stamped and auto-renamed by QbiRunner. 
        This wrapper renames them to a consistent `OE_DCE_hypoxia_mapping.<ext>`.

    SEE ALSO: ../workflows/DCE_VFA.cwl, ../workflows/OE_IR.cwl

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
      - $(inputs.DCE_p_vals_path)
      - $(inputs.OE_p_vals_path)
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml

baseCommand: python
arguments:
  - prefix: -m
    valueFrom: qbidcemri.processes.OE_DCE_hypoxia_mapping
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

inputs:
  DCE_p_vals_path:
    label: Relative path to the DCE p\-value map
    doc: |
      Relative path to the DCE p\-value map, e.g. 'DCE_VFA/C_p_vals.nii.gz'
    type: File
    secondaryFiles:
      - pattern: ^^.json # see NOTES
        required: false
    inputBinding:
      prefix: --DCE_p_vals_path
  OE_p_vals_path:
    label: Path to OE p-value map
    doc: Relative path to OE p-value map, e.g. 'OE_IR/S_p_vals.nii.gz'
    type: File
    secondaryFiles:
      - pattern: ^^.json # see NOTES
        required: false
    inputBinding:
      prefix: --OE_p_vals_path
  sig_level:
    label: Significance level for p-value map thresholds
    default: 0.05
    type: double
    inputBinding:
      prefix: --sig_level
  no_log:
    label: Switch off program logging
    type: boolean?
    inputBinding:
      prefix: --no_log 1
      shellQuote: false

outputs:
  perfused_frac:
    label: DCE p-value < SIG_LEVEL
    type: File
    outputBinding: { glob: perfused_frac.nii.gz }
  non_perfused_frac:
    label: DCE p-value >= SIG_LEVEL
    type: File
    outputBinding: { glob: non_perfused_frac.nii.gz }
  pOxyR:
    label: DCE p-value < SIG_LEVEL and OE p-value > SIG_LEVEL
    type: File
    outputBinding: { glob: pOxyR.nii.gz }
  pOxyE:
    label: DCE p-value < SIG_LEVEL and OE p-value < SIG_LEVEL
    type: File
    outputBinding: { glob: pOxyE.nii.gz }
  logs:
    type: File[]
    outputBinding:
      glob: run_OE_DCE_hypoxia_mapping.*
      outputEval: | # Rename: run_OE_DCE_hypoxia_mapping.{ext}{date}_{time}.txt -> OE_DCE_hypoxia_mapping.{ext}
        ${
          self.forEach(function(f) {
            f.basename = f.basename.replace(/\d{8}_\d{6}.txt/, "").replace(/run_/, "");
            return f;
          });
          return self;
        }

$namespaces:
  utils: ../utils/