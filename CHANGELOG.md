# Changes

## Unreleased

- Establish master and the VM development checkout.
- Add eight-way compiled C64 CI with real 1541-II emulation, strict prerequisites, deterministic builds and failure artifacts.
- Add parser, calendar, numeric, model, map, geographic, disk-builder and application keyboard stress tests.
- Fix command-channel lifetime during saving: closing channel 15 prematurely closed the 1541 output file.


## 0.1.0 — 2026-11-15

- First offline Prog8/C64 build inspired by Skipper Jim's Hurricane Tracking Chart.
- Import the original 19-point Hurricane Gilbert track.
- Add manual observations and save to new sequential files.
- Draw a schematic regional map with stepped track playback and selected-fix details.
- Calculate great-circle distances to four coastal cities.
- Add bounded input, calendar/coordinate validation and overwrite refusal.
- Supply a mountable D64, Perl disk builder and TAP/VICE tests.
- Keep record handling separate from rendering for future data providers; no networking.
