meta:
  id: nsx
  title: Ripple NFx
  file-extension: nfx
  encoding: ASCII
  endian: le
  license: CC0-1.0
  imports:
    - filespec
    - timespec
    - filter

doc: |

  NFx files have the extension .NFx where x is some number between 1 and 9.
  This file type is used to store information and data for channels which are
  sampled continuously (e.g., Hi-Res data for EMG). All data are written in a
  time non-decreasing manner in 32-bit floating point format (IEEE 754 single
  precision). A file with the extension .NFx will often be accompanied by a
  .NEV file with the same base name: for instance, data.nev and data.nf2. The
  existence of a single extended NFx file does not require or preclude the
  existence of other NFx files. Moreover, the NFx files will not necessarily
  start with .nf1; the combination of data.nev and data.nf2 is perfectly valid.

doc-ref: Trellis NEV Spec, Document Version R01838_07
doc-ref: https://rippleneuro.s3-us-west-2.amazonaws.com/sites/5817b02bbc9d752748a1409d/assets/58559c85bc9d756e810d825d/NEVspec2_2_v07.pdf

seq:
  - id: file_header
    type: file_header
  - id: extended_header
    type: extended_header
    repeat: expr
    repeat-expr: file_header.channel_count
  - id: data_packet
    type: data_packet
    repeat: eos

types:

  file_header:
    seq:
      - id: file_type_id
        contents: NEUCDFLT
        doc: Always set to "NEUCDFLT" for "neural continuous data float".
      - id: file_spec
        type: filespec
      - id: bytes_in_headers
        type: u4
      - id: label
        type: strz
        size: 16
      - id: application_to_create_file # zero terminated?
        type: strz
        size: 52
      - id: comments
        type: strz
        size: 200
      - id: processor_timestamp
        type: u4
      - id: period
        type: u4
      - id: time_resolution_of_timestamps
        type: u4
      - id: time_origin
        type: timespec
      - id: channel_count
        type: u4

  extended_header:
    seq:
      - id: type
        contents: FC
        doc: Always set to "FC" for "float channels".
      - id: electrode_id
        type: u2
        doc: |
          ID of electrode being sampled. This field is the same as the
          Electrode ID field of the NEV file. Recording electrodes start at 1
          and analog data channels start at 10241.
      - id: electrode_label
        type: strz
        size: 16
        doc: |
          Label or name of the electrode (e.g. "elec1").
          Must be NULL terminated.
      - id: front_end_id
        type: u1
      - id: front_end_connector_pin
        type: u1
      - id: min_digital_value
        type: s2
      - id: max_digital_value
        type: s2
      - id: min_analog_value
        type: s2
      - id: max_analog_value
        type: s2
      - id: units
        type: strz
        size: 16
        doc: |
          Units of the analog min/max values ("mV", "μV").
          Must be NULL terminated.
      - id: high_pass_filter
        type: filter
      - id: low_pass_filter
        type: filter

  data_packet:
    seq:
      - id: header
        contents: [0x01]
      - id: timestamp
        type: u4
        doc: |
          A time stamp of zero corresponds to the beginning of the data
          acquisition cycle. The frequency of the time stamp clock and the
          time of the file creation are stored in the file header.
      - id: number_of_datapoints
        type: u4
        doc: Number of data points following this header.
      - id: datapoint
        size: number_of_datapoints * channel_count * 4 # four bytes per channel
        doc: |
          This corresponds to a single data collection point.  There will be
          exactly "Channel Count" number of values per data point. They will be
          sorted in the same order as they are presented in "Channel ID". Data
          will be stored as digital values.
    instances:
      channel_count:
        value: _root.file_header.channel_count
