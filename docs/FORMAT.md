# Legacy storm records and extension boundary

The original `HF.GILBERT` is a Commodore sequential file. It has no PRG load address. Lines are PETSCII/ASCII-compatible uppercase text with carriage-return separators:

```text
07 PM 09 10 1988
80
66.5
15.7
0
```

Fields are bulletin time/date (`HH AM MM DD YYYY` or PM), whole wind speed in MPH, positive longitude west, positive latitude north, then the legacy zero separator. Its exact original semantic purpose has not been established. This version accepts and writes zero; it does not reinterpret that field as a forecast flag.

An `END` line terminates the file. The original Gilbert file omits the zero separator after its final latitude and goes directly to `END`; the importer supports both forms. It also accepts CR, LF and CRLF line endings. Only whitespace may follow END. Empty or incomplete files, overlong lines, unsupported precision, out-of-map coordinates and excess observations are rejected. The bounded input buffer is 8192 bytes; files filling that buffer are refused.

Internally, positions are unsigned integer tenths of degrees, winds are whole MPH, and timestamps are 16 bytes plus a null terminator. Up to 128 records fit in the model. Inputs may have extra zero fractional digits (`17.00`), but nonzero precision finer than tenths is refused instead of silently rounded.

`storm.add(timestamp, mph, west_tenths, north_tenths)` validates and appends one record. A future data provider can call this interface without involving bitmap rendering or distance calculations. A future Perl service could normalize upstream products into the same offline format initially. Introducing distinct forecasts, advisory identifiers or additional units should use a documented new format rather than overloading the zero separator.

## C64 memory ownership

| Region | Owner |
|---|---|
| `$0801` to below `$5c00` | Program, variables and timestamp slab; compiler enforces the upper bound |
| `$5c00–$5fff` | Bitmap colour matrix |
| `$6000–$7f3f` | 320×200 monochrome bitmap |
| `$8000–$9fff` | Bounded import scratch buffer |
| `$c000–$c7ff` | Copied uppercase C64 character ROM font |

The application uses the ordinary KERNAL disk interface on drive 8. No REU, cartridge registers, special firmware or network hardware is required.

## Restored chart artwork

The embedded compressed HUR1 artwork restores the original-style 110 W–50 W, 10 N–45 N chart window and bulletin panel. The broader model/import bounds are retained; outside-window observations remain available in the record but are marked off chart and do not produce a misleading clipped track segment. The conversion and source SHA-256 are recorded in data/artwork/provenance.json. No external map asset is needed at runtime.
