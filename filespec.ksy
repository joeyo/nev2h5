meta:
  id: filespec
  endian: le

doc: |
  The major and minor revision numbers of the file specification used to create
  the file e.g. use 0x0202 for NEV Spec. 2.2.

doc-ref: Trellis NEV Spec, Document Version R01838_07

seq:
- id: major
  type: u1
- id: minor
  type: u1