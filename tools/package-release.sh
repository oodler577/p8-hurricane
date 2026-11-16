#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
version=${1:?usage: package-release.sh VERSION PAL_ARTIFACT_DIR NTSC_ARTIFACT_DIR}
pal=${2:?PAL artifact directory required}
ntsc=${3:?NTSC artifact directory required}
case "$version" in
    v[0-9]*)
        case "$version" in *[!a-zA-Z0-9.-]*) echo "Invalid version" >&2; exit 2;; esac ;;
    *) echo "Version must begin with v and a digit" >&2; exit 2 ;;
esac
out="dist/$version"
mkdir -p "$out"
for video in PAL NTSC; do
    if [ "$video" = PAL ]; then source_dir=$pal; else source_dir=$ntsc; fi
    test -s "$source_dir/hurricane.prg"
    test "$(wc -c < "$source_dir/hurricane.d64" | tr -d ' ')" = 174848
    cp "$source_dir/hurricane.prg" "$out/p8-hurricane-$version-$video.prg"
    cp "$source_dir/hurricane.d64" "$out/p8-hurricane-$version-$video.d64"
done
(
    cd "$out"
    sha256sum ./*.prg ./*.d64 > SHA256SUMS.txt
    sha256sum -c SHA256SUMS.txt
)
cat > "$out/RELEASE_NOTES.md" <<'EOF'
Offline hurricane tracking for the Commodore 64, inspired by Skipper Jim's Hurricane Tracking Chart.

Download the PAL or NTSC PRG/D64 matching your machine. Each D64 contains the program and the original 19-observation Hurricane Gilbert sample.

- Load a D64 as drive 8, then enter `LOAD"HURRICANE",8,1` and `RUN`.
- Press L, enter `HF.GILBERT`, then V to view the track.
- Manual observations, saving to new sequential files, stepped map playback, and city distances are included.
- No internet/networking implementation.
- SHA256SUMS.txt verifies all four downloadable files.

Built with Prog8 12.3.5. Publication requires all eight compiler/video/drive configurations to pass: Prog8 12.3.5 and 14.0-BETA3, PAL and NTSC, filesystem IEC and emulated 1541-II. The C64 stress program executes 7,282 assertions per configuration, in addition to the parser, disk and application UI suites.

Physical C64, Ultimate II+ and C64U testing remains outstanding.
EOF
if cmp -s "$pal/hurricane.prg" "$ntsc/hurricane.prg" && cmp -s "$pal/hurricane.d64" "$ntsc/hurricane.d64"; then
    cat >> "$out/RELEASE_NOTES.md" <<'EOF'

The PAL and NTSC files are byte-identical in this version: the application has no video-standard-specific timing code. Both labels are supplied for convenience, and both video standards are exercised separately in VICE.
EOF
fi
echo "Release assets prepared in $out"
