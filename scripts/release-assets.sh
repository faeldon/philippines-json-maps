#!/usr/bin/env bash
# release.prepare: zip the quarter latest/ holds, every format and resolution (hires included),
# into dist/TAG/ with SHA256SUMS and notes.md. Builds from <quarter>/, which has hires; refuses
# if its medres/lowres differ from latest/. Changes no tracked file.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 1 ] || { echo "usage: $(basename "$0") TAG   (e.g. v1.0.0)" >&2; exit 2; }
TAG=$1
QUARTER=$(jq -r .psgc "$ROOT/latest/manifest.json")
SRC_TAG=$(jq -r .source.tag "$ROOT/latest/manifest.json")
SRC_REPO=$(jq -r .source.repo "$ROOT/latest/manifest.json")
BUILD="${BUILD_ROOT:-$ROOT}/$QUARTER"
DIST="$ROOT/dist/$TAG"

[ -d "$BUILD" ] || { echo "$BUILD missing: run build-quarter.sh $SRC_TAG $QUARTER first" >&2; exit 1; }
for fmt in geojson topojson; do
  for level in country regions provdists municities; do
    for res in medres lowres; do
      diff -rq "$BUILD/$fmt/$level/$res" "$ROOT/latest/$fmt/$level/$res" >/dev/null || {
        echo "refusing: $BUILD/$fmt/$level/$res differs from latest/" >&2; exit 1; }
    done
  done
done

rm -rf "$DIST"
mkdir -p "$DIST"
for fmt in geojson topojson; do
  for res in hires medres lowres; do
    (cd "$BUILD" && find "$fmt" -path "$fmt/*/$res/*" -type f | sort | zip -q -X "$DIST/$fmt-$res.zip" -@)
  done
done
(cd "$DIST" && shasum -a 256 *.zip > SHA256SUMS)

{
  echo "PSGC $QUARTER, built from [\`$SRC_TAG\`](https://github.com/$SRC_REPO/releases/tag/$SRC_TAG) of $SRC_REPO."
  echo
  echo "\`latest/\` in the tree holds this release's medres and lowres files. Each zip here holds one format"
  echo "and resolution, as \`<format>/<level>/<resolution>/...\`; \`SHA256SUMS\` covers them."
  echo
  rel=https://github.com/faeldon/philippines-json-maps/releases/tag
  echo "Older vintages are the releases [\`2023-4q\`]($rel/2023-4q),"
  echo "[\`2019\`]($rel/2019) and [\`2011\`]($rel/2011); they left the tree in v1.0.0."
  echo
  # Renames since the previous release's latest/. Before v1.0.0 there was no latest/, so the first
  # release compares with 2023/ as 012 left it.
  prev=$(git -C "$ROOT" describe --tags --abbrev=0 --match 'v*' --exclude "$TAG" HEAD 2>/dev/null || true)
  if [ -n "$prev" ] && git -C "$ROOT" cat-file -e "$prev:latest/geojson" 2>/dev/null; then
    since="$prev" base=("$prev" latest)
  else
    since="2023/" base=(195f6db2 2023)
  fi
  echo "## Renamed paths since \`$since\`"
  echo
  echo "A file's name holds its parent's PSGC code, so these changed with the codes."
  echo
  "$ROOT/scripts/renamed-paths.sh" "${base[@]}"
} > "$DIST/notes.md"

ls -l "$DIST"
cat "$DIST/SHA256SUMS"
