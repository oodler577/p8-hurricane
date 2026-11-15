# Test maintenance

Tests use Perl TAP and run through prove. 01-disk.t verifies the generated D64 chains, types, exact file bytes and allocation map. 02-runtime.t runs compiled Prog8 code in VICE and translates assertions from C64 memory to TAP. runtime.p8 owns functional assertions; render.p8 exercises the actual bitmap path.

For behavior changes, update relevant runtime assertions and their corresponding names in 02-runtime.t. Keep entry and completion labels discoverable in the compiler's VICE symbol list. Tests must not require changes to production logic solely for test access. Use temporary disks/files, never the supplied fixture as writable storage. Supply VICE paths/ROMs through the documented environment variables. Add focused checks for changed behavior, not duplicated implementation logic.

HurricaneTest.pm centralizes bounded VICE execution and failure artifacts. Fixtures.pm supplies parser cases; tools/generate-tests.pl emits independent calendar/distance expectations. stress.p8 reports word-sized assertion counters. files.p8 runs the parser corpus. 05-ui.t drives the actual application through VICE keyboard buffering. In CI, never turn a missing ROM, binary or completion marker into a pass or skip. See docs/CI.md for exact matrix scope.
