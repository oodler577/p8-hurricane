#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export REQUIRE_EMULATOR=1
export VICE="${VICE:-/usr/bin/x64sc}"
export VICE_DATA_DIR="${VICE_DATA_DIR:-/usr/share/vice}"
export VICE_KERNAL="${VICE_KERNAL:-/opt/vice-c64-roms/kernal-901227-03.bin}"
export VICE_BASIC="${VICE_BASIC:-/opt/vice-c64-roms/basic-901226-01.bin}"
export VICE_CHARGEN="${VICE_CHARGEN:-/opt/vice-c64-roms/chargen-901225-01.bin}"
export VICE_DOS1541II="${VICE_DOS1541II:-$PWD/build/tools/dos1541ii-251968-03.bin}"
exec prove -v t/*.t
