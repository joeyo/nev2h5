meta:
  id: timespec
  endian: le

doc: |
  Windows SYSTEM TIME structure
  The Coordinated Universal Time (UTC) at which the data in the file was
  collected. This also corresponds to time index zero for the time stamps in
  the file. The structure consists of eight 2-byte unsigned int-16 values
  defining the Year, Month, DayOfWeek, Day, Hour, Minute, Second, and
  Millisecond.

doc-ref: Trellis NEV Spec, Document Version R01838_07

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