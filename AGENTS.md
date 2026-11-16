# Hurricane / Prog8

This project is an offline C64 recreation inspired by Skipper Jim's Hurricane Tracking Chart. Keep networking unimplemented unless Brett explicitly authorizes it. Preserve the provider boundary documented in docs/FORMAT.md; a Perl service may be added later.

Use Prog8 for C64 application code and Perl for host utilities and TAP tests. Keep the original sample bytes unchanged. Do not modify or redistribute the uploaded original program as part of the new executable. Any reused original assets need an explicit provenance note.

Read README.md and docs/FORMAT.md before changes. Reserve the documented graphics, import and font memory regions. Build with tools/build.sh --tests and run prove -v t/*.t. Emulator tests must exercise compiled C64 code; skipping them is not equivalent to passing. Keep limitations and physical-hardware verification status accurate. Never claim a picture rendered from memory is a physical-machine screenshot.

## Repository and VM

Use master as the main branch. The development checkout is /opt/p8-hurricane on zbumj.vps.hosterdaddy.net; perform builds and C64 emulation there. Do not substitute host-language simulations for VICE execution. Read docs/CI.md before changing the CI matrix or emulator harness. CI must fail if emulation is skipped. Test PAL/NTSC, both supported Prog8 compilers, and the emulated 1541-II path when changing file I/O.

## Original-program credit (all platforms)

Every C64 PAL/NTSC build and every future X16 or other port must prominently display the full original title, Skipper Jim's Hurricane Tracking Chart, and the author, James R. Brown. Use the shared credits module in the title/menu UI. Preserve CREDITS.md, the README's leading attribution, and docs/RELEASE_CREDIT.md in release descriptions. Credit must be visible to users, not just in source comments. Existing release descriptions should also receive the shared attribution; do not replace historical binaries or move their tags. Read CREDITS.md before changing branding.

## Visual fidelity

Use the original-program photographs as the visual reference: large stacked title, orange/cyan palette, filled original coastline, solid grid and pale bulletin panel. The embedded map data is adapted original HUR1 artwork, not a new schematic drawing. Preserve its provenance manifest and artwork integrity tests. Read docs/VISUALS.md before display changes. Capture actual running screens in VICE and inspect them; compilation and data tests do not establish appearance.
