#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 2 ] && [[ $2 =~ ^[0-9]{4}-[1-4]q$ ]] || {
  echo "usage: $(basename "$0") TAG QUARTER   (e.g. v1.0.0 2026-3q)" >&2; exit 2; }
TAG=$1 QUARTER=$2
"$ROOT/scripts/fetch-shapefiles.sh" "$TAG" "$QUARTER"

SHAPEFILE="$ROOT/scripts/processed/$QUARTER"
GEOJSON="$ROOT/$QUARTER/geojson/regions"
TOPOJSON="$ROOT/$QUARTER/topojson/regions"

unzip -o -q $SHAPEFILE/PH_Adm2_ProvDists.shp.zip -d $SHAPEFILE/regions/
unzip -o -q $SHAPEFILE/PH_Adm1_Regions.shp.zip -d $SHAPEFILE/country/

rm -rf "$GEOJSON"/*
rm -rf "$TOPOJSON"/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[REGIONS] Generataing Region List"
ogr2ogr -f CSV -select adm1_psgc $SHAPEFILE/regions_raw.csv $SHAPEFILE/country/PH_Adm1_Regions.shp
sed 1d $SHAPEFILE/regions_raw.csv > $SHAPEFILE/regions.csv # Remove header
rm $SHAPEFILE/regions_raw.csv
array=()

# Read the file in parameter and fill the array named "array"
getArray() {
  i=0
  while read line # Read a line
  do
    array[i]=$line # Put it into the array
    i=$(($i + 1))
  done < $1
}

echo "[REGIONS] Reading Array"
getArray "$SHAPEFILE/regions.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  echo "[PROVDISTS] Processing $f"
  ogr2ogr -mapFieldType Date=String -where "adm1_psgc=$f" -t_srs "EPSG:4326" -f GeoJSON $GEOJSON/provdists-region-${f}.json $SHAPEFILE/regions/PH_Adm2_ProvDists.shp

  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 10% keep-shapes -o format=geojson id-field=adm2_psgc $GEOJSON/hires/provdists-region-${f}.0.1.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 1% keep-shapes -o format=geojson id-field=adm2_psgc $GEOJSON/medres/provdists-region-${f}.0.01.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 0.1% keep-shapes -o format=geojson id-field=adm2_psgc $GEOJSON/lowres/provdists-region-${f}.0.001.json

  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 10% keep-shapes -o format=topojson id-field=adm2_psgc $TOPOJSON/hires/provdists-region-${f}.topo.0.1.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 1% keep-shapes -o format=topojson id-field=adm2_psgc $TOPOJSON/medres/provdists-region-${f}.topo.0.01.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 0.1% keep-shapes -o format=topojson id-field=adm2_psgc $TOPOJSON/lowres/provdists-region-${f}.topo.0.001.json

  rm $GEOJSON/provdists-region-${f}.json # Delete because this is a large file
done

rm $SHAPEFILE/regions.csv
