#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 2 ] && [[ $2 =~ ^[0-9]{4}-[1-4]q$ ]] || {
  echo "usage: $(basename "$0") TAG QUARTER   (e.g. v1.0.0 2026-3q)" >&2; exit 2; }
TAG=$1 QUARTER=$2
"$ROOT/scripts/fetch-shapefiles.sh" "$TAG" "$QUARTER"

SHAPEFILE="$ROOT/scripts/processed/$QUARTER"
GEOJSON="$ROOT/$QUARTER/geojson/municities"
TOPOJSON="$ROOT/$QUARTER/topojson/municities"

unzip -o -q $SHAPEFILE/PH_Adm4_BgySubMuns.shp.zip -d $SHAPEFILE/municities/
unzip -o -q $SHAPEFILE/PH_Adm3_MuniCities.shp.zip -d $SHAPEFILE/provdists/

rm -rf "$GEOJSON"/*
rm -rf "$TOPOJSON"/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[MUNICITIES] Generataing Municipality and City List"
ogr2ogr -f CSV -select adm3_psgc $SHAPEFILE/municities_raw.csv $SHAPEFILE/provdists/PH_Adm3_MuniCities.shp
sed 1d $SHAPEFILE/municities_raw.csv > $SHAPEFILE/municities.csv # Remove header
rm $SHAPEFILE/municities_raw.csv

# How many municipalities to build at once; set JOBS to override.
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

# One municipality or city: extract its barangays, then write its six simplified files.
# Each writes only its own files, so they run $JOBS at a time.
build_municity() {
  set -euo pipefail
  f=$1
  echo "[BGYSUBMUNS] Processing $f"
  # geom_src = 'none' rows have no shape (Manila's sub-municipalities); their barangays do.
  ogr2ogr -mapFieldType Date=String -where "adm3_psgc=$f AND geom_src <> 'none'" -t_srs "EPSG:4326" -f GeoJSON $GEOJSON/bgysubmuns-municity-${f}.json $SHAPEFILE/municities/PH_Adm4_BgySubMuns.shp

  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 10% keep-shapes -o format=geojson id-field=adm4_psgc $GEOJSON/hires/bgysubmuns-municity-${f}.0.1.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 1% keep-shapes -o format=geojson id-field=adm4_psgc $GEOJSON/medres/bgysubmuns-municity-${f}.0.01.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 0.1% keep-shapes -o format=geojson id-field=adm4_psgc $GEOJSON/lowres/bgysubmuns-municity-${f}.0.001.json

  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 10% keep-shapes -o format=topojson id-field=adm4_psgc $TOPOJSON/hires/bgysubmuns-municity-${f}.topo.0.1.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 1% keep-shapes -o format=topojson id-field=adm4_psgc $TOPOJSON/medres/bgysubmuns-municity-${f}.topo.0.01.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 0.1% keep-shapes -o format=topojson id-field=adm4_psgc $TOPOJSON/lowres/bgysubmuns-municity-${f}.topo.0.001.json

  rm $GEOJSON/bgysubmuns-municity-${f}.json # Delete because this is a large file
}
export -f build_municity
export SHAPEFILE GEOJSON TOPOJSON

echo "[MUNICITIES] Processing $(wc -l < "$SHAPEFILE/municities.csv" | tr -d ' ') municipalities and cities, $JOBS at a time"
# xargs exits non-zero if any municipality fails, which fails the script.
tr -dc '[:alnum:]\n\r' < "$SHAPEFILE/municities.csv" | tr -d '\r' | tr '[:upper:]' '[:lower:]' \
  | xargs -n 1 -P "$JOBS" bash -c 'build_municity "$1"' _

rm $SHAPEFILE/municities.csv
