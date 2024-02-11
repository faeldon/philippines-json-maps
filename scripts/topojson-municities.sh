#!/usr/bin/env bash

SHAPEFILE="2023/processed"
GEOJSON="2023/geojson/municities"
TOPOJSON="2023/topojson/municities"

unzip $SHAPEFILE/PH_Adm4_BgySubMuns.shp.zip -d $SHAPEFILE/municities/

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[MUNICITIES] Generataing Municipality and City List"
ogr2ogr -f CSV -select adm3_psgc municities_raw.csv $SHAPEFILE/provdists/PH_Adm3_MuniCities.shp.shp
sed 1d municities_raw.csv > municities.csv # Remove header
rm municities_raw.csv
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
getArray "municities.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  echo "[BGYSUBMUNS] Processing $f"
  ogr2ogr -mapFieldType Date=String -where "adm3_psgc=$f" -t_srs "EPSG:4326" -f GeoJSON $GEOJSON/bgysubmuns-municity-${f}.json $SHAPEFILE/municities/PH_Adm4_BgySubMuns.shp.shp

  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 10% -o format=geojson id-field=adm4_psgc $GEOJSON/hires/bgysubmuns-municity-${f}.0.1.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 1% -o format=geojson id-field=adm4_psgc $GEOJSON/medres/bgysubmuns-municity-${f}.0.01.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 0.1% -o format=geojson id-field=adm4_psgc $GEOJSON/lowres/bgysubmuns-municity-${f}.0.001.json

  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 10% -o format=topojson id-field=adm4_psgc $TOPOJSON/hires/bgysubmuns-municity-${f}.topo.0.1.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 1% -o format=topojson id-field=adm4_psgc $TOPOJSON/medres/bgysubmuns-municity-${f}.topo.0.01.json
  mapshaper $GEOJSON/bgysubmuns-municity-${f}.json -simplify 0.1% -o format=topojson id-field=adm4_psgc $TOPOJSON/lowres/bgysubmuns-municity-${f}.topo.0.001.json

  rm $GEOJSON/bgysubmuns-municity-${f}.json # Delete because this is a large file
done

rm municities.csv