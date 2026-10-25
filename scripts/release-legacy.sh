#!/usr/bin/env bash
# Publish an old vintage directory as its own GitHub release, from history (git archive REF), so it
# works after the directory has left the tree. One zip per format and resolution; files with no
# resolution directory (2011's unsimplified GeoJSON) go in <format>-full.zip, anything else in
# extras.zip. --dry-run builds and verifies dist/TAG/ but tags, pushes and uploads nothing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY=0
[ "${1:-}" = --dry-run ] && { DRY=1; shift; }
[ $# -eq 3 ] || { echo "usage: $(basename "$0") [--dry-run] TAG DIR REF   (e.g. 2019 2019 685d702b)" >&2; exit 2; }
TAG=$1 DIR=$2 REF=$3
REPO=faeldon/philippines-json-maps
SHA=$(git -C "$ROOT" rev-parse --verify "$REF^{commit}")
DIST="$ROOT/dist/$TAG"
SRC="$DIST/src"

if [ $DRY = 0 ] && gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
  echo "refusing: release $TAG already exists" >&2; exit 1
fi

rm -rf "$DIST"
mkdir -p "$SRC"
git -C "$ROOT" archive "$SHA" -- "$DIR" | tar -x -C "$SRC"
[ -d "$SRC/$DIR" ] || { echo "$DIR is not in $REF" >&2; exit 1; }

# Bucket every file: <fmt>-<res> by its parent directory, <fmt>-full without one, extras otherwise.
(cd "$SRC/$DIR" && find . -type f | sed 's|^\./||' | sort) > "$DIST/files.txt"
awk -F/ -v out="$DIST" '{
  if ($1 == "geojson" || $1 == "topojson") {
    res = $(NF-1); b = (res == "hires" || res == "medres" || res == "lowres") ? $1 "-" res : $1 "-full"
  } else b = "extras"
  print > (out "/" b ".list")
}' "$DIST/files.txt"
for list in "$DIST"/*.list; do
  (cd "$SRC/$DIR" && zip -q -X "$DIST/$(basename "$list" .list).zip" -@ < "$list")
done
rm "$DIST"/*.list

# The zips together hold exactly the archive's files.
for z in "$DIST"/*.zip; do zipinfo -1 "$z"; done | grep -v '/$' | sort > "$DIST/zipped.txt"
diff -q "$DIST/files.txt" "$DIST/zipped.txt" >/dev/null || {
  echo "zips differ from $DIR at $REF:" >&2; diff "$DIST/files.txt" "$DIST/zipped.txt" | head >&2; exit 1; }
echo "[LEGACY] $(wc -l < "$DIST/files.txt" | tr -d ' ') files from $DIR at ${SHA:0:8}, all zipped"
rm -rf "$SRC" "$DIST/files.txt" "$DIST/zipped.txt"
(cd "$DIST" && shasum -a 256 *.zip > SHA256SUMS)

cat > "$DIST/notes.md" <<NOTES
The \`$DIR/\` maps as \`master\` held them at $SHA. They left the tree in v1.0.0, which put the
newest quarter at \`latest/\`; this release keeps them downloadable.

Each zip holds one format and resolution, with the paths as they were under \`$DIR/\`
(\`<format>/<level>/<resolution>/...\`); a \`-full\` zip holds the files that sat in no resolution
directory, and \`extras.zip\` anything outside \`geojson/\` and \`topojson/\`. \`SHA256SUMS\` covers them.
NOTES
ls -l "$DIST"

[ $DRY = 1 ] && { echo "[LEGACY] dry run: nothing tagged, pushed or uploaded"; exit 0; }
git -C "$ROOT" tag -a "$TAG" "$SHA" -m "$DIR/ as master held it, moved to this release in v1.0.0"
git -C "$ROOT" push origin "refs/tags/$TAG"
gh release create "$TAG" "$DIST"/*.zip "$DIST/SHA256SUMS" -R "$REPO" \
  --verify-tag --latest=false --title "$TAG: the $DIR/ maps" --notes-file "$DIST/notes.md"
