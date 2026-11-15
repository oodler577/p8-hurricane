# Hurricane / Prog8

This project is an offline C64 recreation inspired by Skipper Jim's Hurricane Tracking Chart. Keep networking unimplemented unless Brett explicitly authorizes it. Preserve the provider boundary documented in docs/FORMAT.md; a Perl service may be added later.

Use Prog8 for C64 application code and Perl for host utilities and TAP tests. Keep the original sample bytes unchanged. Do not modify or redistribute the uploaded original program as part of the new executable. Any reused original assets need an explicit provenance note.

Read README.md and docs/FORMAT.md before changes. Reserve the documented graphics, import and font memory regions. Build with tools/build.sh --tests and run prove -v t/*.t. Emulator tests must exercise compiled C64 code; skipping them is not equivalent to passing. Keep limitations and physical-hardware verification status accurate. Never claim a picture rendered from memory is a physical-machine screenshot.

## Repository and VM

Use master as the main branch. The development checkout is /opt/p8-hurricane on zbumj.vps.hosterdaddy.net; perform builds and C64 emulation there. Do not substitute host-language simulations for VICE execution. Read docs/CI.md before changing the CI matrix or emulator harness. CI must fail if emulation is skipped. Test PAL/NTSC, both supported Prog8 compilers, and the emulated 1541-II path when changing file I/O.
