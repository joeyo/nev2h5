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

doc: |

  !!! NOTE !!! THIS DOCUMENTS THE RIPPLE NEURO IMPLEMENTATION OF THE NEV SPEC.

  This data format provides a method for encoding digitized extracellular
  spikes, stimulation waveforms, and digital input events from up to 512
  electrodes (future revisions of the specification will provide higher
  counts). This format represents a balance between flexibility to encode a
  variety of different event types, efficiency of encoding, and simplicity of
  organization for quick analysis.

  A *.NEV file is composed of three sections:

  1) Header Basic Information

    A series of fixed-width fields containing information about timebase,
    authoring application, extended headers, and any user generated comments.

  2) Header Extended Information

    A variable number of fixed-width packets which hold data about the
    configuration of individual electrode channels and other important
    experiment information.

  3) Data Packets
    A series of fixed-width packets containing continuous data from
    individual electrodes.

doc-ref: Trellis NEV Spec, Document Version R01838_07
doc-ref: https://rippleneuro.s3-us-west-2.amazonaws.com/sites/5817b02bbc9d752748a1409d/assets/58559c85bc9d756e810d825d/NEVspec2_2_v07.pdf

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
    doc: |
      This is the first section in the NEV file. It contains one header with
      the following fields (in the order listed). All multi-byte data types are
      stored in little-endian format.
    seq:
      - id: file_type_id
        contents: NEURALEV
        doc: Always set to "NEURALEV" for "neural events".
      - id: file_spec
        type: filespec
      - id: additional_flags
        type: u2
        doc: |
          File format additional flags. Bit 0: Set if all spike waveform values
          in the file are 16-bit; un-set if a mixture is to be expected.
          In the un-set case you MUST look at NEUEVWAV to determine the number
          of bytes per waveform sample. All other bits are reserved and should
          be set to 0.
      - id: bytes_in_headers
        type: u4
        doc: |
          The total number of bytes in both headers (Standard and Extended).
          This value can also be considered to be a zero-indexed pointer to the
          first data packet.
      - id: bytes_in_data_packets
        type: u4
        doc: |
          The length (in bytes) of the fixed width data packets in the data
          section of the file. The packet sizes must be between 12 and 256
          bytes (see Data Section description). Packet sizes are required to be
          multiples of 4 so that the packets are aligned for 32-bit file
          access. Referred to as Packet_width in Nev Data Packets section.
      - id: time_resolution_of_timestamps
        type: u4
        doc: |
          This value denotes the frequency (counts per second) of the clock
          used to specify sample time.
      - id: time_resolution_of_samples
        type: u4
        doc: |
          This value denotes the sampling frequency (samples per second) used
          to digitize neural waveforms.
      - id: time_origin
        type: timespec
      - id: application_to_create_file
        type: strz
        size: 32
        doc: |
          A 32-character string labeling the program which created the file.
          Trellis will also include its revision number in this label.
          The string must be null terminated.
      - id: comment_field
        type: strz
        size: 200
        doc: |
          A 200-character, null-terminated string used for embedding user
          comments into the data field. Multi-line comments should ideally use
          no more than 80 characters per line and no more than 8 lines.
          The string must be NULL terminated.
      - id: reserved
        size: 52
        doc: Reserved for future information (written as 0).
      - id: processor_timestamp
        type: u4
        doc: |
          The processor timestamp (in 30 kHz clock cycles) at which
          the data in the file were collected.
      - id: number_of_extended_headers
        type: u4
        doc: A long value indicating the number of extended header entries.

  extended_header:
    doc: |
      This section of the NEV file contains a variable number of 32-byte,
      fixed-length headers. The exact number of headers in this section is
      specified at the end of the Basic Header section (see above). These
      headers may be used to include additional configuration information and
      comments into the file.

      Each 32-byte header consists of an 8 byte identifier and a 24 byte
      information field. These headers are not required to be of any registered
      type. For example, a program can add extended headers to the NEV file
      that only the program or related programs can utilize. However, there are
      several standard entries and identifiers that are defined in the
      specification and listed below with the 8 character identifier and 24
      byte information field.

      Note: For NEUEVWAV headers, the Stim Amp Digitization Factor is set to 0
      for neural waveforms, and the Neural Amp Digitization Factor is set to 0
      for stimulation waveforms. Stimulation channels have associated NEUEVWAV
      and NEUEVLBL headers but not NEUEVFLT headers.
    seq:
      - id: packet_id
        type: str
        size: 8
      - id: body
        type:
          switch-on: packet_id
          cases:
            '"NEUEVWAV"': neuevwav_body # neural event waveform
            '"NEUEVFLT"': neuevflt_body # neural event filter
            '"NEUEVLBL"': neuevlbl_body # neural event label
            '"DIGLABEL"': diglabel_body # digital label
        size: 24
    types:
      neuevwav_body:
        seq:
        - id: electrode_id
          type: u2
          doc: |
            Electrode ID number used in the data section of the file. Recording
            electrodes start at 1 and Stimulation electrodes start at 5121.
            Also used in NEUEVFLT and NEUEVLBL.
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
        - id: stim_amp_digitization_factor # is this really a float?
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

  # TODO: HANDLE CONTINUATION PACKETS
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
            event::analog: analog
            _: unknown
        size: packet_body_size
    instances:
      packet_type:
        value: >
          (packet_id <  1) ? event::digital :
          (packet_id >= 1) and (packet_id <= 512) ? event::spike :
          (packet_id >= 5121) and (packet_id <= 5632) ? event::stim :
          (packet_id >= 10241) ? event::analog :
          event::unknown
      electrode_id:
        value: >
          (packet_id >= 5121) and (packet_id <= 5632) ? packet_id - 5120 :
          (packet_id >= 10241) ? packet_id - 10240 :
          packet_id
      packet_body_size:
        value: _root.file_header.bytes_in_data_packets - 6
    enums:
      event:
        0: digital
        1: spike
        2: stim
        3: analog
        4: unknown
    types:
      digital:
        seq:
          - id: packet
            type: packet_insertion_reason
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
        types:
          packet_insertion_reason:
            # note that kaitai reads the most-significant bits first
            # so this is ordered"backwards"
            seq:
              - id: serial
                type: b1
              - id: periodic
                type: b1
              - id: unused
                type: b1
              - id: sma4
                type: b1
              - id: sma3
                type: b1
              - id: sma2
                type: b1
              - id: sma1
                type: b1
              - id: strobe
                type: b1
      spike:
        seq:
          - id: unit_classification_number
            type: u1
          - id: reserved
            type: u1
          - id: waveform
            size: _parent.packet_body_size - 2
      stim:
        seq:
          - id: reserved
            type: u2
          - id: waveform
            size: _parent.packet_body_size - 2
      analog:
        seq:
          - id: reserved
            size: _parent.packet_body_size
      unknown:
        seq:
          - id: reserved
            size: _parent.packet_body_size