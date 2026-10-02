#!/bin/sh
# After the docs PR with the charts is merged, point the release notes at the copy in HdrHistogram_c.
# Usage: pin-chart-urls.sh <commit-of-HdrHistogram_c-main-that-contains-docs/images/0.12.0>
set -eu
[ $# -eq 1 ] || { echo "usage: $0 <40-char commit sha>" >&2; exit 2; }
sha=$1
case $sha in *[!0-9a-f]*|"") echo "not a hex sha" >&2; exit 2;; esac
[ ${#sha} -eq 40 ] || { echo "need the full 40-character sha" >&2; exit 2; }
f=$(dirname "$0")/RELEASE-NOTES-0.12.0.md
base=https://raw.githubusercontent.com/HdrHistogram/HdrHistogram_c/$sha/docs/images/0.12.0
sed -i -E "s#https://raw.githubusercontent.com/[^)]*/(speedup|write|read|list)\.png#$base/\1.png#g" "$f"
echo "image links now:"; grep -o 'https://raw[^)]*png' "$f"
