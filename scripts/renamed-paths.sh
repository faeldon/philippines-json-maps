#!/usr/bin/env bash
# List the files whose names differ between an old vintage in history and latest/, per level:
# a name changes only when its parent's PSGC code does. Prints Markdown for release notes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 2 ] || { echo "usage: $(basename "$0") OLD_REF OLD_DIR   (e.g. 195f6db2 2023)" >&2; exit 2; }
REF=$1 DIR=$2

old=$(mktemp) new=$(mktemp)
trap 'rm -f "$old" "$new"' EXIT

for level in regions provdists municities; do
  git -C "$ROOT" ls-tree -r --name-only "$REF" -- "$DIR/geojson/$level/lowres/" | xargs -n1 basename | sort > "$old"
  find "$ROOT/latest/geojson/$level/lowres" -name '*.json' | xargs -n1 basename | sort > "$new"
  removed=$(comm -23 "$old" "$new") added=$(comm -13 "$old" "$new")
  echo "### $level/"
  echo
  echo "$(printf '%s' "$removed" | grep -c . || true) removed, $(printf '%s' "$added" | grep -c . || true) added (lowres GeoJSON names; every format and resolution follows them)."
  echo
  [ -z "$removed" ] || printf '%s\n' "$removed" | sed 's/^/- removed `/; s/$/`/'
  [ -z "$added" ] || printf '%s\n' "$added" | sed 's/^/- added `/; s/$/`/'
  echo
done
