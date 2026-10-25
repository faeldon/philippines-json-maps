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

echo "[MUNICITIES] Reading Array"
getArray "$SHAPEFILE/municities.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
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
done

rm $SHAPEFILE/municities.csv
