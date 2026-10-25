#!/usr/bin/env bash
# release.publish: upload dist/TAG/ (from release-assets.sh) as the GitHub release TAG, whose tag
# /sdlc:publish has just pushed. A published release is never replaced, so an existing one refuses.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 1 ] || { echo "usage: $(basename "$0") TAG   (e.g. v1.0.0)" >&2; exit 2; }
TAG=$1
DIST="$ROOT/dist/$TAG"
QUARTER=$(jq -r .psgc "$ROOT/latest/manifest.json")

[ -f "$DIST/SHA256SUMS" ] || { echo "$DIST/SHA256SUMS missing: run release-assets.sh $TAG" >&2; exit 1; }
(cd "$DIST" && shasum -a 256 -c --quiet SHA256SUMS)
if gh release view "$TAG" -R faeldon/philippines-json-maps >/dev/null 2>&1; then
  echo "refusing: release $TAG already exists" >&2; exit 1
fi
gh release create "$TAG" "$DIST"/*.zip "$DIST/SHA256SUMS" -R faeldon/philippines-json-maps \
  --verify-tag --title "$TAG: PSGC $QUARTER" --notes-file "$DIST/notes.md"
