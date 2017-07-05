meta:
  id: nev
  title: Ripple NEV
  file-extension: nev
  encoding: ASCII
  endian: le
  license: CC0-1.0
doc-ref: Trellis NEV Spec, Document Version R01838_07
seq:
  - id: nev_file_header
    type: nev_file_header
  - id: nev_extended_header
    type: nev_extended_header
    repeat: expr
    repeat-expr: nev_file_header.number_of_extended_headers
  - id: nev_data_packet
    type: nev_data_packet
    size: nev_file_header.bytes_in_data_packets
    repeat: eos

types:

  file_spec:
    seq:
      - id: major
        type: u1
      - id: minor
        type: u1

  time_spec:
    doc-ref: Windows SYSTEM TIME structure
    seq:
      - id: year
        type: u2
      - id: month
        type: u2
      - id: day_of_week
        type: u2
      - id: day
        type: u2
      - id: hour
        type: u2
      - id: minute
        type: u2
      - id: second
        type: u2
      - id: millisecond
        type: u2

  nev_file_header:
    seq:
      - id: file_type_id
        contents: NEURALEV
      - id: file_spec
        type: file_spec
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
        type: time_spec
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

  nev_extended_header:
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
          - id: high_pass_corner_frequency
            type: u4
          - id: high_pass_filter_order
            type: u4
          - id: high_pass_filter_type
            type: u2
            enum: filter_type
          - id: low_pass_corner_frequency
            type: u4
          - id: low_pass_filter_order
            type: u4
          - id: low_pass_filter_type
            type: u2
            enum: filter_type
        enums:
          filter_type:
            0: none
            1: butterworth
            2: chebyshev
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

  nev_data_packet:
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
          packet_id < 0 ? event::digital :
          packet_id >= 1 and packet_id <= 512 ? event::spike :
          event::stim
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
            size: _root.nev_file_header.bytes_in_data_packets - 8
      stim:
        seq:
          - id: reserved
            type: u2
          - id: waveform
            size: _root.nev_file_header.bytes_in_data_packets - 8