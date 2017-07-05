meta:
  id: nsx
  title: Ripple NSx
  file-extension: nsx
  encoding: ASCII
  endian: le
  license: CC0-1.0
  imports:
    - filespec
    - timespec
    - filter

doc-ref: Trellis NEV Spec, Document Version R01838_07

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
        contents: NEURALCD
      - id: file_spec
        type: filespec
      - id: bytes_in_headers
        type: u4
      - id: label
        type: strz
        size: 16
      - id: comments
        type: strz
        size: 200
      - id: application_to_create_file # zero terminated?
        type: strz
        size: 52
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
        contents: CC
      - id: electrode_id
        type: u2
      - id: electrode_label
        type: strz
        size: 16
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
        size: number_of_datapoints * channel_count * 2 # two bytes per channel
        doc: |
          This corresponds to a single data collection point.  There will be
          exactly “Channel Count” number of values per data point. They will be
          sorted in the same order as they are presented in “Channel ID”. Data
          will be stored as digital values.
    instances:
      channel_count:
        value: _root.file_header.channel_count
