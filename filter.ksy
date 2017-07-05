meta:
  id: filter
  endian: le

doc: |
  This type describes channel filtering for NEV, NSx, and NFx file formats

doc-ref: Trellis NEV Spec, Document Version R01838_07

seq:
- id: corner_frequency
  type: u4
- id: filter_order
  type: u4
- id: filter_type
  type: u2
  enum: filter_type
enums:
  filter_type:
    0: none
    1: butterworth
    2: chebyshev