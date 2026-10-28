#!/usr/bin/env bash
# The island groups (Luzon, Visayas, Mindanao), dissolved from the regions by
# scripts/island-groups.csv. Not a PSGC level: the ids are the groups' names.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 2 ] && [[ $2 =~ ^[0-9]{4}-[1-4]q$ ]] || {
  echo "usage: $(basename "$0") TAG QUARTER   (e.g. v1.0.0 2026-3q)" >&2; exit 2; }
TAG=$1 QUARTER=$2
"$ROOT/scripts/fetch-shapefiles.sh" "$TAG" "$QUARTER"

SHAPEFILE="$ROOT/scripts/processed/$QUARTER"
MAPPING="$ROOT/scripts/island-groups.csv"
GEOJSON="$ROOT/$QUARTER/geojson/islandgroups"
TOPOJSON="$ROOT/$QUARTER/topojson/islandgroups"

# The mapping must name every region of the quarter exactly once, and nothing else, before
# anything is written: a new region code stops the build instead of falling off the map.
codes() { tail -n +2 "$1" | cut -d, -f1 | tr -d '\r' | sort; }
bad=$(tail -n +2 "$MAPPING" | tr -d '\r' | awk -F, '$2 !~ /^(Luzon|Visayas|Mindanao)$/')
dup=$(codes "$MAPPING" | uniq -d)
missing=$(comm -23 <(codes "$SHAPEFILE/PH_Adm1_Regions.csv") <(codes "$MAPPING" | uniq))
extra=$(comm -13 <(codes "$SHAPEFILE/PH_Adm1_Regions.csv") <(codes "$MAPPING" | uniq))
if [ -n "$bad$dup$missing$extra" ]; then
  [ -z "$bad" ] || echo "[ISLANDGROUPS] not Luzon, Visayas or Mindanao: $(echo $bad)" >&2
  [ -z "$dup" ] || echo "[ISLANDGROUPS] mapped twice: $(echo $dup)" >&2
  [ -z "$missing" ] || echo "[ISLANDGROUPS] regions of $QUARTER with no island group: $(echo $missing)" >&2
  [ -z "$extra" ] || echo "[ISLANDGROUPS] mapped but not a region of $QUARTER: $(echo $extra)" >&2
  echo "refusing: fix $MAPPING" >&2
  exit 1
fi

unzip -o -q $SHAPEFILE/PH_Adm1_Regions.shp.zip -d $SHAPEFILE/country/

rm -rf "$GEOJSON"/*
rm -rf "$TOPOJSON"/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

# Simplify before dissolving: the arcs are simplified over the whole region layer, as for
# country/, so every vertex here is one of the country file's at the same resolution.
dissolve() {
  mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp -simplify $1 keep-shapes \
    -join $MAPPING keys=adm1_psgc,adm1_psgc field-types=adm1_psgc:number \
    -dissolve island_group sum-fields=area_km2 -rename-layers islandgroups \
    -proj wgs84 -o format=$2 id-field=island_group $3
}

echo "[ISLANDGROUPS] Simplifying GeoJSON"
dissolve 10% geojson $GEOJSON/hires/islandgroups.0.1.json
dissolve 1% geojson $GEOJSON/medres/islandgroups.0.01.json
dissolve 0.1% geojson $GEOJSON/lowres/islandgroups.0.001.json

echo "[ISLANDGROUPS] Converting to Topojson"
dissolve 10% topojson $TOPOJSON/hires/islandgroups.topo.0.1.json
dissolve 1% topojson $TOPOJSON/medres/islandgroups.topo.0.01.json
dissolve 0.1% topojson $TOPOJSON/lowres/islandgroups.topo.0.001.json
