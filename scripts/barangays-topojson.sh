#!/usr/bin/env bash

GEOJSON="../geojson/barangays"
TOPOJSON="../topojson/barangays"
rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

array=()
array_id=()

# Read the file in parameter and fill the array named "array"
getArray() {
  i=0
  while read line # Read a line
  do
    array[i]=$line # Put it into the array
    i=$(($i + 1))
  done < $1
}

getArrayId() {
  i=0
  while read line # Read a line
  do
    array_id[i]=$line # Put it into the array
    i=$(($i + 1))
  done < $1
}

getArray "municities.dat"
getArrayId "municities_id.dat"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  g=${array_id[$e]}
  echo "[BARANGAY] Processing $g-$f"

  ogr2ogr -where "NAME_2='${array[$e]}' AND TYPE_3='Barangay'" -f GeoJSON $GEOJSON/barangays-municity-${g}-${f}.json ../shapefile/barangays/Barangays.shp

  mapshaper $GEOJSON/barangays-municity-${g}-${f}.json -simplify 10% -o $GEOJSON/hires/barangays-municity-${g}-${f}.0.1.json
  mapshaper $GEOJSON/barangays-municity-${g}-${f}.json -simplify 1% -o $GEOJSON/medres/barangays-municity-${g}-${f}.0.01.json
  mapshaper $GEOJSON/barangays-municity-${g}-${f}.json -simplify 0.1% -o $GEOJSON/lowres/barangays-municity-${g}-${f}.0.001.json
  
  geo2topo --id-property ID_3 -p name=NAME_3 -p municity=NAME_2 -p province=PROVINCE -p region=REGION -o $TOPOJSON/hires/barangays-municity-${g}-${f}.topo.0.1.json $GEOJSON/hires/barangays-municity-${g}-${f}.0.1.json
  geo2topo --id-property ID_3 -p name=NAME_3 -p municity=NAME_2 -p province=PROVINCE -p region=REGION -o $TOPOJSON/medres/barangays-municity-${g}-${f}.topo.0.01.json $GEOJSON/medres/barangays-municity-${g}-${f}.0.01.json
  geo2topo --id-property ID_3 -p name=NAME_3 -p municity=NAME_2 -p province=PROVINCE -p region=REGION -o $TOPOJSON/lowres/barangays-municity-${g}-${f}.topo.0.001.json $GEOJSON/lowres/barangays-municity-${g}-${f}.0.001.json
done

