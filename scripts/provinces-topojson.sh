#!/usr/bin/env bash

GEOJSON="../geojson/provinces"
TOPOJSON="../topojson/provinces"
rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres
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

getArray "regions.dat"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  g=$(($e + 1))
  echo "[PROVINCE] Processing $g-$f"
  ogr2ogr -where "REGION='${array[$e]}'" -f GeoJSON $GEOJSON/provinces-region-${f}.json ../shapefile/provinces/Provinces.shp
  
  mapshaper $GEOJSON/provinces-region-${f}.json -simplify 10% -o $GEOJSON/hires/provinces-region-${f}.0.1.json
  mapshaper $GEOJSON/provinces-region-${f}.json -simplify 1% -o $GEOJSON/medres/provinces-region-${f}.0.01.json
  mapshaper $GEOJSON/provinces-region-${f}.json -simplify 0.1% -o $GEOJSON/lowres/provinces-region-${f}.0.001.json

  geo2topo --id-property ID_1 -p name=NAME_1 -p region=REGION -o $TOPOJSON/hires/provinces-region-${f}.topo.0.1.json $GEOJSON/hires/provinces-region-${f}.0.1.json
  geo2topo --id-property ID_1 -p name=NAME_1 -p region=REGION -o $TOPOJSON/medres/provinces-region-${f}.topo.0.01.json $GEOJSON/medres/provinces-region-${f}.0.01.json
  geo2topo --id-property ID_1 -p name=NAME_1 -p region=REGION -o $TOPOJSON/lowres/provinces-region-${f}.topo.0.001.json $GEOJSON/lowres/provinces-region-${f}.0.001.json
done

