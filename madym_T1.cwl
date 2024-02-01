cwlVersion: v1.2
class: CommandLineTool
label: madym_T1 tool wrapper
doc: |
    Madym is a C++ toolkit for quantative DCE-MRI and DWI-MRI analysis developed 
    in the QBI Lab at the University of Manchester.

    This CWL wrapper is for the madym_T1 tool, applying the Variable Flip Angle method
    [with B1 correction], or the Inversion Recovery method [with efficiency weighting]
    to a set of input signal volumes.
    
    REFERENCES:
      - Berks et al., (2021). Madym: A C++ toolkit for quantitative DCE-MRI analysis.
        Journal of Open Source Software, 6(66), 3523, https://doi.org/10.21105/joss.03523
    
      - https://gitlab.com/manchester_qbi/manchester_qbi_public/madym_cxx/-/wikis/madym_t1

    NOTES:
      - The following defaults override the madym defaults:
        - `nifti_4D` is set to 1
        - `nifti_scaling` is set to 1
        - `use_BIDS` is set to 1
        - `img_fmt_r`is set to `NIFTI_GZ`
        - `img_fmt_w`is set to track `img_fmt_r`
      - Other settings, like `cwd`, `output_root` and `output` are set by the wrapper.
        Use `cwltool --basedir <base/dir> --outdir <root/out> ...` to set these.
      - Logs are time-stamped and auto-renamed by madym, e.g. `madym_T1_{date}_{time}_{log}`
        where `{log}` is the value of the `--program_log option`. This wrapper renames them
        to a consistent `madym_T1_{method}.log`. The same applies to the audit log, and the
        (override) config file, resp. `madym_T1_{method}.audit`, and `madym_T1_{method}.cfg`.

hints:
  DockerRequirement:
    dockerPull: ghcr.io/uomresearchit/radnet/preclinicalmri/core_pipelines:latest
  SoftwareRequirement:
    packages:
      - package: madym_T1
        version: [ "v4.23.0" ]

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: InitialWorkDirRequirement
    listing: $(inputs.T1_vols)

baseCommand: madym_T1
arguments:
  # - prefix: --cwd
  #   valueFrom: $(runtime.outdir)
  - prefix: --output_root
    valueFrom: $(runtime.outdir)
  - prefix: --output
    valueFrom: ""
  - prefix: --audit_dir
    valueFrom: $(runtime.outdir)
  - prefix: --audit
    valueFrom: cwl.audit # see NOTES
  - prefix: --program_log
    valueFrom: cwl.log # see NOTES
  - prefix: --config_out
    valueFrom: cwl.cfg # see NOTES
  - prefix: --overwrite
    valueFrom: "1"
  
inputs:
  T1_vols:
    label: File paths to input signal volumes
    type: File[]
    secondaryFiles: ^^.json
    inputBinding:
      prefix: --T1_vols
      valueFrom: |
        [$(inputs.T1_vols.map(function(v){return "'" + v.basename + "'";}).join(', '))]
  img_fmt_r:
    label: Image format of input signal volumes
    doc: |
      NIFTI_GZ / NIFTI will read all compressed and uncompressed NIFTI, and ANALYZE images 
      However, `img_fmt_r` gets mapped as the default for `img_fmt_w` where the choice does matter:
      - NIFTI_GZ (default) .nii.gz compressed NIFTI images (recommended, specially for masked images)
      - NIFTI .nii uncompressed NIFTI images
      - ANALYZE (.hdr, .img) pairs in the old Analyze 7.5 format
      For DICOM inputs use the `madym_DicomConvert` tool to generate NIFTI images first.
    default: NIFTI_GZ
    type:
      type: enum
      symbols:
        - NIFTI
        - NIFTI_GZ
        - ANALYZE
        - ANALYZE_SPARSE # undocumented
        # TODO: use edam ontology for formats? would need parsing to pass to madym
        #   NIFTI = edam:format_4001, DICOM = edam:format_3548, the rest seem not to be in edam
    inputBinding:
      prefix: --img_fmt_r
  img_fmt_w:
    label: Image format for writing output
    doc: |
      Format of images to write out (the default is to use `img_fmt_r`):
      - NIFTI_GZ generates .nii.gz compressed NIFTI images (recommended, specially for masked images)
      - NIFTI generates .nii uncompressed NIFTI images
      - ANALYZE generates (.hdr, .img) pairs in the old Analyze 7.5 format
      For DICOM output, use external tools to convert from NIFTI / NIFTI_GZ
    type:
      type: enum
      symbols:
        - "" # default to img_fmt_r
        - NIFTI
        - NIFTI_GZ
        - ANALYZE
        - ANALYZE_SPARSE # undocumented
    # default: $(inputs.img_fmt_r) doesn't work, so we use valueFrom expression (below)
    default: ""
    inputBinding:
      prefix: --img_fmt_w
      valueFrom: |
        $(self? self : inputs.img_fmt_r)

  T1_method:
    label: Method used for baseline T1 mapping
    doc: |
      VFA - Variable Flip-Angle
      VFA_B1 - Variable Flip-Angle (B1 corrected)
      IR - Inversion Recovery
      IR_E - Inversion Recovery (with efficiency weighting)
    default: IR_E
    type: 
      type: enum
      symbols:
        - VFA
        - VFA_B1
        - IR
        - IR_E
    inputBinding:
      prefix: --T1_method
  T1_noise:
    label: Noise threshold for fitting baseline T1
    type: double
    default: 0.1
    inputBinding:
      prefix: --T1_noise
  B1_scaling:
    label: Scaling value appplied to B1 map
    type: double
    default: 1000
    inputBinding:
      prefix: --B1_scaling
  B1:
    label: Path to B1 correction map
    type: File?
    # format: ??
    inputBinding:
      prefix: --B1
  TR:
    label: TR of dynamic series (ms)
    type: double?
    inputBinding:
      prefix: --TR
  roi:
    label: Path to ROI map
    type: File?
    # format: ??
    inputBinding:
      prefix: --roi
  err:
    label: Path to existing error tracker map
    doc: if empty, a new map is created
    type: File?
    # format: ??
    inputBinding:
      prefix: --err
  nifti_4D:
    label: Read NIFTI 4D images for T1 mapping and dynamic inputs (default TRUE)
    default: true
    type: boolean?
    inputBinding:
      prefix: --nifti_4D 1
      shellQuote: false
  nifti_scaling:
    label: Apply intensity scaling and offset when reading/writing NIFTI images
    type: boolean?
    inputBinding:
      prefix: --nifti_scaling 1
      shellQuote: false
  use_BIDS:
    label: Read/Write images using BIDS json meta info (default TRUE)
    default: true
    type: boolean?
    inputBinding:
      prefix: --use_BIDS 1
      shellQuote: false
  voxel_size_warn_only:
    label: warning only if image sizes do not match
    doc:  Only throw a warning (instead of error) if input image voxel sizes do not match
    type: boolean?
    inputBinding:
      prefix: --voxel_size_warn_only 1
      shellQuote: false
  no_log:
    label: Switch off program logging
    type: boolean?
    inputBinding:
      prefix: --no_log 1
      shellQuote: false
  quiet:
    label: Do not display logging messages in cout
    type: boolean?
    inputBinding:
      prefix: -q
  no_audit:
    label: Switch off audit logging
    type: boolean?
    inputBinding:
      prefix: --no_audit 1
      shellQuote: false

outputs:
  efficiency_map:
    type: File[]
    outputBinding:
      glob: "efficiency.*"
  T1_map:
    type: File[]
    outputBinding:
      glob: "T1.*"
  M0_map:
    type: File[]
    outputBinding:
      glob: "M0.*"
  error_tracker:
    type: File
    outputBinding:
      glob: "error_tracker.*"
  logs:
    type: File[]
    outputBinding:
      glob: madym_T1_*_cwl.*
      outputEval: | # Remove timestamps: madym_T1_{date}_{time}_cwl.{ext} -> madym_T1_{method}.{ext}
        ${
          self.forEach(function(f) {
            f.basename = f.basename.replace(/\d{8}_\d{6}/, inputs.T1_method).replace(/_cwl/, "");
            return f;
          });
          return self;
        }

# $namespaces:
#   edam: http://edamontology.org/
#   iana: https://www.iana.org/assignments/media-types/