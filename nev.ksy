meta:
  id: nev
  title: Ripple NEV
  file-extension: nev
  encoding: ASCII
  endian: le
  license: CC0-1.0
doc-ref: Trellis NEV Spec, Document Version R01838_07
seq:
  - id: header
    type: nev_file_header

types:
  nev_file_header:
    seq:
      - id: file_type_id
        contents: NEURALEV
      - id: file_psec
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
        size: 16
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

  file_spec:
    seq:
      - id: major
        type: u1
      - id: minor
        type: u1

