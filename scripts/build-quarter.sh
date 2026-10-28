#!/usr/bin/env bash
# Build every level of one PSGC quarter into <quarter>/ at the repo root (gitignored).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 2 ] && [[ $2 =~ ^[0-9]{4}-[1-4]q$ ]] || {
  echo "usage: $(basename "$0") TAG QUARTER   (e.g. v1.0.0 2026-3q)" >&2; exit 2; }
TAG=$1 QUARTER=$2

for level in country islandgroups regions provdists municities; do
  "$ROOT/scripts/topojson-$level.sh" "$TAG" "$QUARTER"
done

jq -n --arg tag "$TAG" --arg quarter "$QUARTER" --arg built "$(date -u +%Y-%m-%d)" \
  '{tag: $tag, quarter: $quarter, source: "faeldon/philippines-psgc-shapefiles", built: $built}' \
  > "$ROOT/$QUARTER/build.json"
echo "[BUILD] $QUARTER from $TAG done"
