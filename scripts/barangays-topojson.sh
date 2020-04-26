#!/usr/bin/env bash

SHAPEFILE="../shapefile/2018"
GEOJSON="../geojson/barangays"
TOPOJSON="../topojson/barangays"

unzip $SHAPEFILE/barangays/Barangays.zip -d $SHAPEFILE/barangays/

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

array=()

echo "[BARANGAY] Generataing Municity List"
ogr2ogr -f CSV -select ADM3_PCODE municities_raw.csv $SHAPEFILE/municities/Municities.shp
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

echo "[BARANGAY] Reading Array"
getArray "municities.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  echo "[BARANGAY] Processing $f"
  ogr2ogr -mapFieldType Date=String -where "ADM3_PCODE='${array[$e]}'" -f GeoJSON $GEOJSON/barangays-municity-${f}.json $SHAPEFILE/barangays/Barangays.shp

  mapshaper $GEOJSON/barangays-municity-${f}.json -simplify 10% -o $GEOJSON/hires/barangays-municity-${f}.0.1.json
  mapshaper $GEOJSON/barangays-municity-${f}.json -simplify 1% -o $GEOJSON/medres/barangays-municity-${f}.0.01.json
  mapshaper $GEOJSON/barangays-municity-${f}.json -simplify 0.1% -o $GEOJSON/lowres/barangays-municity-${f}.0.001.json

  geo2topo --id-property ADM4_PCODE -p name=ADM4_EN -p municity_id=ADM3_PCODE -p province_id=ADM2_PCODE -p region_id=ADM1_PCODE -o $TOPOJSON/hires/barangays-municity-${f}.topo.0.1.json $GEOJSON/hires/barangays-municity-${f}.0.1.json
  geo2topo --id-property ADM4_PCODE -p name=ADM4_EN -p municity_id=ADM3_PCODE -p province_id=ADM2_PCODE -p region_id=ADM1_PCODE -o $TOPOJSON/medres/barangays-municity-${f}.topo.0.01.json $GEOJSON/medres/barangays-municity-${f}.0.01.json
  geo2topo --id-property ADM4_PCODE -p name=ADM4_EN -p municity_id=ADM3_PCODE -p province_id=ADM2_PCODE -p region_id=ADM1_PCODE -o $TOPOJSON/lowres/barangays-municity-${f}.topo.0.001.json $GEOJSON/lowres/barangays-municity-${f}.0.001.json

  rm $GEOJSON/barangays-municity-${f}.json # Delete because this is a large file
done

rm municities.csv
