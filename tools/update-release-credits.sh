#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
gh api --paginate "repos/$GH_REPO/releases?per_page=100" --jq '.[].tag_name' > "$work/tags"
while IFS= read -r tag; do
    gh release view "$tag" --json body --jq '.body' > "$work/body"
    if grep -q '<!-- original-program-credit -->' "$work/body"; then
        continue
    fi
    cat docs/RELEASE_CREDIT.md > "$work/credited"
    printf '\n' >> "$work/credited"
    cat "$work/body" >> "$work/credited"
    gh release edit "$tag" --notes-file "$work/credited"
done < "$work/tags"
