# Visual reference and native captures

The user supplied photographs of the original title and Hurricane Gilbert chart. Those photographs are the visual reference for this update. Their CRT perspective, camera white balance, glow and overscan are not reproduced as software effects.

## Presentation retained

- Large stacked SKIPPER / JIM'S / HURRICANE / TRACKING / CHART lettering.
- Orange border and HURRICANE line, cyan remaining lettering, black background and PRESS ANY KEY.
- James R. Brown's full author credit directly below the title.
- Original HUR1 coastline, filled land and complete grid, adapted into an embedded hires bitmap.
- Cyan land/grid, blue sea, original map heading, pale-yellow bulletin panel and a white current-fix marker.
- Bulletin number, storm name/class, date, MPH wind and west/north position.
- The chart capture selects Gilbert's second observation: 11 PM September 10, 1988, 80 MPH, 67.2 W, 16.0 N.

The old schematic coastline and dotted grid have been replaced. The chart uses the original window's five-degree spacing, with positions outside that window explicitly marked off chart. The original map is an illustrative chart, not modern detailed cartography.

The original graphics are multicolour. This version retains the two dominant colours in each 8x8 hires cell, allowing a sharp 40-column bulletin panel without a raster split. Crowded title/coastline cells may therefore differ slightly. See data/artwork/provenance.json and tools/prepare-map.pl for exact provenance and conversion.

## Screenshots

title-pal.png, chart-pal.png, title-ntsc.png and chart-ntsc.png under docs/screenshots are native PNGs emitted by VICE after the compiled rendering code runs. The captures use the same chart/title functions as the actual application. The keyboard-driven application smoke test separately loads Gilbert and opens the map through the real menu.

On the VM:

```sh
cd /opt/p8-hurricane
PROG8_VERSION=12.3.5 ./tools/ci-setup.sh
. build/tools/env.sh
./tools/build.sh --tests
perl tools/capture-screenshots.pl
VICE_VIDEO=ntsc perl tools/capture-screenshots.pl
```

The capture script requires xvfb-run and xauth. It waits at a completion breakpoint, allows the VIC-II to render frames, then asks VICE to save the screen on exit. A memory completion marker is checked so a missing sample or incomplete render cannot masquerade as a screenshot. Supporting logs, monitor commands and memory dumps remain under build/screenshots.

CI repeats both video-standard captures and uploads them beside the test diagnostics. It also checks the decoded artwork's exact size and SHA-256 and verifies the timestamp and storm-name glyphs in C64 bitmap memory.
