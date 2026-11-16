# C64 torture suite

Development checkout: /opt/p8-hurricane on zbumj.vps.hosterdaddy.net. The repository's main branch is master. Application networking is intentionally absent.

## Matrix

GitHub Actions runs eight independent C64 configurations:

| Compiler | Video | Disk backend |
|---|---|---|
| Prog8 12.3.5 | PAL and NTSC | Filesystem IEC and emulated 1541-II |
| Prog8 14.0-BETA3 | PAL and NTSC | Filesystem IEC and emulated 1541-II |

The 1541-II jobs execute the drive CPU and DOS ROM with virtual-device traps disabled. They build temporary multi-file D64 images and read/write through the real KERNAL IEC routines. This matters: the initial filesystem-only suite did not expose that closing command channel 15 also closes the drive's open data channels. The production save routine now keeps channel 15 open until output is closed.

Each configuration compiles the application and five dedicated C64 test programs, repeats the application build to check byte-for-byte determinism, then runs TAP through prove. An additional host job checks Perl/shell/workflow syntax and disk construction.

No emulator suite may silently skip in CI: REQUIRE_EMULATOR=1 turns missing prerequisites into a bailout. Timeouts, a missing completion breakpoint, a nonzero emulator exit, incomplete memory dumps and nonzero C64 failure counters all fail the job. The aggregate check requires both the host job and every matrix job to succeed.

## What runs on the emulated C64

- Original Gilbert import, first/last records, timestamp preservation, save/reload, existing-file refusal and capacity bounds.
- 36 parser fixtures: CR/LF/CRLF, sentinel variants, empty/truncated files, bad dates, malformed numbers, invalid bounds, nonzero separators, embedded NUL/high-bit bytes, oversized input and 128/129-record boundaries.
- Eight complete 128-record fill/verify cycles.
- Leap-day validation for every year from 1800 through 2400, compared to independently generated Gregorian expectations.
- Every longitude tenth from 45.0 W through 110.0 W passes decimal conversion and value checks.
- 48 deterministic geographic cases compared to a Perl great-circle reference, with one-nautical-mile tolerance.
- Map projection extremes, ROM-font glyph verification and a guard region immediately beyond the bitmap.
- Keyboard-driven use of the actual application: menu, filename entry, file import and opening the first observation's map.

The model/math/render stress program alone executes 7,282 assertions. Counts are read back from emulated memory, not inferred from successful compilation. Host tests additionally cover allocation maps, extended directories, sector boundaries, binary and empty payloads, duplicate/invalid names, missing inputs, disk-full errors and deterministic output.

The UI smoke test uses filesystem IEC in every matrix row; the runtime and parser suites use that row's selected backend. CI is emulation evidence, not physical C64/UII+/C64U certification.

## Reproduce on the VM

With the installed compiler and the VM's existing C64 ROM directory:

```sh
cd /opt/p8-hurricane
make test
VICE_VIDEO=ntsc VICE_DRIVE=1541 ./tools/test-vm.sh
```

To reproduce an exact CI compiler and verified ROM set:

```sh
PROG8_VERSION=12.3.5 ./tools/ci-setup.sh
. build/tools/env.sh
./tools/build.sh --tests
VICE_VIDEO=pal VICE_DRIVE=1541 ./tools/test-vm.sh
```

The setup script verifies SHA-256 hashes of the compiler and all downloaded ROMs. ROM URLs are pinned to one upstream VICE source commit; ROMs and compiler binaries are not checked into this repository.

VICE_VIDEO accepts pal/ntsc, VICE_DRIVE accepts filesystem/1541, and VICE_SEED controls initial emulator randomness. TEST_ARTIFACTS selects the diagnostics directory. The default is build/test-results. Logs, monitor command files, C64 memory snapshots and test D64s are uploaded by CI even on failure. KEEP_EMULATOR_FILES=1 also retains temporary files locally.

## Compiler details

Both supported versions build with -noopt. Prog8 12.3.5's optimizer crashes on this source. The 14.0-BETA3 code generator also mishandles an implicit byte-to-word comparison in an early stress assertion, reading an adjacent byte as the high byte. The test checks low/high bytes explicitly; the full stored wind values are verified. Do not remove these workarounds without executing both compiler rows.

Avoid placing undocumented tool-specific assumptions into production code just to make tests pass. Keep the memory map in FORMAT.md authoritative.

## Releases

A pushed v* tag runs the same full matrix and host checks. The release job waits for the aggregate success check, downloads the PAL/NTSC filesystem artifacts built by Prog8 12.3.5, and packages four clearly named PRG/D64 assets plus SHA256SUMS.txt. It publishes a GitHub Release with a job-scoped contents:write token. Failed or skipped checks prevent publication. PAL and NTSC artifacts may be identical when no machine-specific timing is needed; the release notes explicitly report that case.

To prepare equivalent files on the VM after building and testing, run tools/package-release.sh v0.1.0 build build. This only prepares dist/v0.1.0; publication happens in the tag-triggered workflow. Do not move an existing release tag to a different commit.

## Visual capture and attribution

The stable-compiler filesystem rows also run the compiled title/chart capture fixtures under Xvfb and save native PAL/NTSC VICE screenshots in the diagnostic artifact. Artwork size/SHA-256 checks and bitmap glyph checks guard the restored map, bulletin timestamp and storm name. Every platform must preserve the original title and James R. Brown attribution; see CREDITS.md and docs/VISUALS.md.
