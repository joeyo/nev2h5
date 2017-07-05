meta:
  id: nev
  title: Ripple NEV
  file-extension: nev
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
    repeat-expr: file_header.number_of_extended_headers
  - id: data_packet
    type: data_packet
    size: file_header.bytes_in_data_packets
    repeat: eos

types:

  file_header:
    seq:
      - id: file_type_id
        contents: NEURALEV
      - id: file_spec
        type: filespec
      - id: additional_flags
        type: u2
      - id: bytes_in_headers
        type: u4
      - id: bytes_in_data_packets
        type: u4
      - id: time_resolution_of_timestamps
        type: u4
      - id: time_resolution_of_samples
        type: u4
      - id: time_origin
        type: timespec
      - id: application_to_create_file
        type: strz
        size: 32
      - id: comment_field
        type: strz
        size: 200
      - id: reserved
        size: 52
      - id: processor_timestamp
        type: u4
      - id: number_of_extended_headers
        type: u4

  extended_header:
    seq:
      - id: packet_id
        type: str
        size: 8
      - id: body
        type:
          switch-on: packet_id
          cases:
            '"NEUEVWAV"': neuevwav_body
            '"NEUEVFLT"': neuevflt_body
            '"NEUEVLBL"': neuevlbl_body
            '"DIGLABEL"': diglabel_body
        size: 24
    types:
      neuevwav_body:
        seq:
        - id: electrode_id
          type: u2
        - id: front_end_id
          type: u1
        - id: front_end_connector_pin
          type: u1
        - id: neural_amp_digitization_factor
          type: u2
        - id: energy_threshold
          type: u2
        - id: high_threshold
          type: s2
        - id: low_threshold
          type: s2
        - id: number_of_sorted_units
          type: u1
        - id: bytes_per_sample
          type: u1
        - id: stim_amp_digitization_factor
          type: f4
      neuevflt_body:
        seq:
          - id: electrode_id
            type: u2
          - id: high_pass_filter
            type: filter
          - id: low_pass_filter
            type: filter
      neuevlbl_body:
        seq:
          - id: electrode_id
            type: u2
          - id: label
            type: strz
            size: 16
      diglabel_body:
        seq:
          - id: label
            type: strz
            size: 16
          - id: mode
            type: u1
            enum: mode
        enums:
          mode:
            0: serial
            1: parallel

  data_packet:
    seq:
      - id: timestamp
        type: u4
      - id: packet_id
        type: u2
      - id: body
        type:
          switch-on: packet_type
          cases:
            event::digital: digital
            event::spike: spike
            event::stim: stim
    instances:
      packet_type:
        value: >
          packet_id < 1 ? event::digital :
          packet_id >= 1 and packet_id <= 512 ? event::spike :
          event::stim
      electrode_id:
        value: >
          packet_id > 5121 ? packet_id - 5120 : packet_id
    enums:
      event:
        0: digital
        1: spike
        2: stim
    types:
      digital:
        seq:
          - id: packet_insertion_reason
            type: u1
          - id: reserved
            type: u1
          - id: parallel_input
            type: s2
          - id: sma_input_1
            type: s2
          - id: sma_input_2
            type: s2
          - id: sma_input_3
            type: s2
          - id: sma_input_4
            type: s2
      spike:
        seq:
          - id: unit_classification_number
            type: u1
          - id: reserved
            type: u1
          - id: waveform
            size: _root.file_header.bytes_in_data_packets - 8
      stim:
        seq:
          - id: reserved
            type: u2
          - id: waveform
            size: _root.file_header.bytes_in_data_packets - 8