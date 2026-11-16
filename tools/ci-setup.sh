#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
version="${PROG8_VERSION:-14.0-BETA3}"
case "$version" in
    12.3.5) jar_sha=aee4b749eda3b1397782a416ffe520dc8fc8b2a6a3537e87ae8f08cb0655843b ;;
    14.0-BETA3) jar_sha=7117cabdb1d3ecf11d4f38aa7e2cea570056a3eb2c3b3f4e8593838b1b4115c0 ;;
    *) echo "Unsupported compiler: $version" >&2; exit 2 ;;
esac
mkdir -p build/tools/vice-data/C64
fetch() {
    url=$1
    dest=$2
    sha=$3
    if [ ! -f "$dest" ] || ! printf '%s  %s\n' "$sha" "$dest" | sha256sum -c - >/dev/null 2>&1; then
        curl -fLsS --retry 3 --connect-timeout 15 --max-time 120 "$url" -o "$dest"
    fi
    printf '%s  %s\n' "$sha" "$dest" | sha256sum -c -
}
jar="$PWD/build/tools/prog8c-$version-all.jar"
fetch "https://github.com/irmen/prog8/releases/download/v$version/prog8c-$version-all.jar" "$jar" "$jar_sha"
rom_base=https://raw.githubusercontent.com/VICE-Team/svn-mirror/83095dcbf3a535167fb864fc4801b0c8ef5be517/vice/data
rom_dir="$PWD/build/tools/vice-data/C64"
fetch "$rom_base/C64/basic-901226-01.bin" "$rom_dir/basic-901226-01.bin" 89878cea0a268734696de11c4bae593eaaa506465d2029d619c0e0cbccdfa62d
fetch "$rom_base/C64/chargen-901225-01.bin" "$rom_dir/chargen-901225-01.bin" fd0d53b8480e86163ac98998976c72cc58d5dd8eb824ed7b829774e74213b420
fetch "$rom_base/C64/kernal-901227-03.bin" "$rom_dir/kernal-901227-03.bin" 83c60d47047d7beab8e5b7bf6f67f80daa088b7a6a27de0d7e016f6484042721
fetch "$rom_base/DRIVES/dos1541ii-251968-03.bin" "$PWD/build/tools/dos1541ii-251968-03.bin" 326c289c38753323d7e8167897447cf61ef35189d82eb8d75210ece949adda7c
for file in /usr/share/vice/C64/*; do
    [ -e "$file" ] || continue
    [ -e "$rom_dir/${file##*/}" ] || ln -s "$file" "$rom_dir/${file##*/}"
done
for directory in DRIVES PRINTER GLSL; do
    [ -e "build/tools/vice-data/$directory" ] || ln -s "/usr/share/vice/$directory" "build/tools/vice-data/$directory"
done
cat > build/tools/env.sh <<EOF
export PROG8_JAR='$jar'
export VICE='$(command -v x64sc)'
export VICE_DATA_DIR='$PWD/build/tools/vice-data'
export VICE_KERNAL='$rom_dir/kernal-901227-03.bin'
export VICE_BASIC='$rom_dir/basic-901226-01.bin'
export VICE_CHARGEN='$rom_dir/chargen-901225-01.bin'
export VICE_DOS1541II='$PWD/build/tools/dos1541ii-251968-03.bin'
export REQUIRE_EMULATOR=1
EOF
echo "Verified toolchain environment: build/tools/env.sh"
