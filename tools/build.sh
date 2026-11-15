#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build
compile() {
    if [ -n "${PROG8_JAR:-}" ]; then
        java -jar "$PROG8_JAR" -noopt -target c64 -srcdirs src:t/support:build -out build "$1"
    else
        prog8c -noopt -target c64 -srcdirs src:t/support:build -out build "$1"
    fi
}
# 12.3.5 optimizer crashes on this source; noopt is tested on both supported compilers.
compile src/main.p8
cp build/main.prg build/hurricane.prg
perl tools/disk.pl build/hurricane.d64 build/hurricane.prg data/HF.GILBERT
if [ "${1:-}" = "--tests" ]; then
    perl tools/generate-tests.pl
    for test in runtime render files stress; do compile "t/$test.p8"; done
elif [ "${1:-}" != "" ]; then
    echo "usage: $0 [--tests]" >&2
    exit 2
fi
