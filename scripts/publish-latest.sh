#!/usr/bin/env bash
# Replace latest/ with the medres and lowres files of one built quarter, and record it in
# latest/manifest.json. Hires stays out of the tree; it ships only in the quarter's release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 1 ] && [[ $1 =~ ^[0-9]{4}-[1-4]q$ ]] || {
  echo "usage: $(basename "$0") QUARTER   (e.g. 2026-3q, built by build-quarter.sh)" >&2; exit 2; }
QUARTER=$1
BUILD="$ROOT/$QUARTER"
CSV="$ROOT/scripts/processed/$QUARTER"
LATEST="$ROOT/latest"

[ -f "$BUILD/build.json" ] || { echo "$BUILD/build.json missing: run build-quarter.sh first" >&2; exit 1; }

# One file per parent: the country, then one per region, province/district, municipality/city.
rows() {
  [ -f "$CSV/$1.csv" ] || { echo "$CSV/$1.csv missing: run fetch-shapefiles.sh for $QUARTER" >&2; exit 1; }
  echo $(( $(wc -l < "$CSV/$1.csv") - 1 ))
}
want_country=1
want_regions=$(rows PH_Adm1_Regions)
want_provdists=$(rows PH_Adm2_ProvDists)
want_municities=$(rows PH_Adm3_MuniCities)
bad=0
for fmt in geojson topojson; do
  for level in country regions provdists municities; do
    for res in medres lowres; do
      want="want_$level"
      have=$(find "$BUILD/$fmt/$level/$res" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
      if [ "$have" != "${!want}" ]; then
        echo "$fmt/$level/$res: $have files, the release has ${!want}" >&2; bad=1
      fi
    done
  done
done
[ $bad = 0 ] || { echo "refusing: $QUARTER is incomplete" >&2; exit 1; }

version=0.0.0
[ -f "$LATEST/manifest.json" ] && version=$(jq -r .version "$LATEST/manifest.json")

rm -rf "$LATEST/geojson" "$LATEST/topojson"
for fmt in geojson topojson; do
  for level in country regions provdists municities; do
    for res in medres lowres; do
      mkdir -p "$LATEST/$fmt/$level"
      cp -R "$BUILD/$fmt/$level/$res" "$LATEST/$fmt/$level/"
    done
  done
done

jq --arg version "$version" \
  '{version: $version, psgc: .quarter, source: {repo: .source, tag: .tag}, built: .built}' \
  "$BUILD/build.json" > "$LATEST/manifest.json"
echo "[LATEST] $QUARTER published to latest/ (version $version)"
