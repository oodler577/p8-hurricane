# p8-hurricane

[![C64 torture suite](https://github.com/oodler577/p8-hurricane/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/oodler577/p8-hurricane/actions/workflows/ci.yml)

An offline hurricane observation logger and track viewer, inspired by **Skipper Jim's Hurricane Tracking Chart** by James R. Brown. This is new Prog8 source, with an importer for the original storm records. The supplied Gilbert observations were extracted unchanged from the uploaded disk.

## Try the first build

Mount `build/hurricane.d64` as drive 8 on a C64, Ultimate II+, C64 Ultimate, or VICE, then:

```basic
LOAD"HURRICANE",8,1
RUN
```

Press **L**, enter `HF.GILBERT`, then press **V** to view the track.

| Key | Action |
|---|---|
| L | Load a storm file from drive 8 |
| N | Clear the current track and start a new storm |
| A | Add an observation |
| S | Save under a new filename |
| V | View the current track |
| F | Show the disk directory |
| Q | Quit; confirm before discarding unsaved observations |

On the map: **Space** advances, **B** goes back, **R** restarts at the first observation, **D** shows city distances, and **Q** returns to the menu. Playback is stepped rather than timed. The crosshair marks the selected observation, and the line shows the track up to that point.

For manual entry, use the displayed time format, for example `07 PM 09 10 1988`. Winds are whole MPH; coordinates are positive degrees west and north, with tenths supported. The date is calendar-checked, including leap years. Enter the data and press Y to commit the observation.

Saving always creates a new sequential file. Existing files are refused; use another filename to save an updated track. Names can have up to 16 characters: letters, digits, dots, hyphens and underscores. A malformed import clears the incomplete track; the program asks about discarding unsaved work before loading.

## Current scope

- Up to **128 observations** per track.
- Map covers **110° W–45° W, 5° N–45° N**.
- Newly drawn, schematic coastline; fixed extent and no zoom.
- Great-circle distances in nautical miles to Houston, Brownsville, New Orleans and Miami city centres.
- Gilbert fixture has **19 observations**, September 10–16, 1988.
- No internet, networking, Ultimate command-interface calls, or external service dependency.
- Editing/deleting individual observations, a storm-name editor, arbitrary saved locations, automatic playback and additional basins are future work.

The source has been compiled and tested in VICE. Physical C64, UII+ and C64U testing is still needed.

## Build

Requires Java 21+, Prog8 **12.3.5 or 14.0-BETA3**, Perl 5, and 64tass **1.59.3120 or newer** on PATH. Point `PROG8_JAR` at the compiler JAR, or install a `prog8c` command.

```sh
PROG8_JAR=/path/to/prog8c-12.3.5-all.jar ./tools/build.sh
```

The build creates `build/hurricane.prg` and `build/hurricane.d64`. The disk builder is Perl and does not require c1541. The original uploaded D64 is never modified.

The build deliberately uses `-noopt`: Prog8 12.3.5's optimizer raises an internal `NumericLiteral.parent` exception on this source. The non-optimized build fits comfortably below the reserved graphics area. Compiler and emulator binaries/ROMs are not distributed here.

## Tests

```sh
PROG8_JAR=/path/to/prog8c.jar ./tools/build.sh --tests
prove -v t/*.t
```

Disk layout tests run locally. Emulator tests are skipped unless these variables point to a working VICE installation and its ROMs:

```sh
export VICE=/path/to/x64sc
export VICE_DATA_DIR=/path/to/vice/data
export VICE_KERNAL=/path/to/kernal-901227-03.bin
export VICE_BASIC=/path/to/basic-901226-01.bin
export VICE_CHARGEN=/path/to/chargen-901225-01.bin
prove -v t/*.t
```

The emulator tests run the **compiled C64 code**, checking dates, bounded numeric parsing, track limits, the original Gilbert import, save/reload, overwrite refusal, malformed import, reference city distances and map rendering. They use a temporary filesystem drive and leave the sample data untouched. `docs/gilbert-preview.png` is rendered from the tested C64 bitmap memory, not an interface mockup.

## Where to extend it

| File | Responsibility |
|---|---|
| `src/main.p8` | Menus, bounded keyboard input and interaction |
| `src/model.p8` | Observation arrays, validation, selection and dirty state |
| `src/storage.p8` | Bounded legacy text import and sequential-file export |
| `src/chart.p8` | Projection, schematic coastline, track and bitmap labels |
| `src/geo.p8` | Great-circle distance calculation |
| `docs/FORMAT.md` | Record format and future data-provider boundary |

A future offline importer or Perl-backed provider should feed validated records through `storm.add()`. Keep transport and service details outside the chart and distance code. No network implementation is included.

## Repository and rigorous CI

The main branch is **master**. Development and C64 emulator validation run on the Prog8 VM in /opt/p8-hurricane. See [docs/CI.md](docs/CI.md) for the eight-way compiler/video/drive matrix, 7,282-assertion C64 stress program, parser corpus, keyboard-driven application smoke test, reproducible builds and failure diagnostics. The setup script can provision the exact verified compiler and ROM set used by CI. CI artifacts contain freshly built PRG and D64 files; generated binaries and toolchains are not tracked in git.
