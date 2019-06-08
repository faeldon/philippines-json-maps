#!/usr/bin/env bash

GEOJSON="../geojson/municties"
TOPOJSON="../topojson/municities"
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

getArray "provinces.dat"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  g=$(($e + 1))
  echo "[MUNICITY] Processing $g-$f"
  ogr2ogr -where "PROVINCE='${array[$e]}' AND TYPE_2<>'Waterbody'" -f GeoJSON $GEOJSON/municities-province-${g}-${f}.json ../shapefile/municities/MuniCities.shp
  
  mapshaper $GEOJSON/municities-province-${g}-${f}.json -simplify 10% -o $GEOJSON/hires/municities-province-${g}-${f}.0.1.json
  mapshaper $GEOJSON/municities-province-${g}-${f}.json -simplify 1% -o $GEOJSON/medres/municities-province-${g}-${f}.0.01.json
  mapshaper $GEOJSON/municities-province-${g}-${f}.json -simplify 0.1% -o $GEOJSON/lowres/municities-province-${g}-${f}.0.001.json

  geo2topo --id-property ID_2 -p name=NAME_2 -p province=PROVINCE -p region=REGION -p mctype=ENGTYPE_2 -o $TOPOJSON/hires/municities-province-${g}-${f}.topo.0.1.json $GEOJSON/hires/municities-province-${g}-${f}.0.1.json
  geo2topo --id-property ID_2 -p name=NAME_2 -p province=PROVINCE -p region=REGION -p mctype=ENGTYPE_2 -o $TOPOJSON/medres/municities-province-${g}-${f}.topo.0.01.json $GEOJSON/medres/municities-province-${g}-${f}.0.01.json
  geo2topo --id-property ID_2 -p name=NAME_2 -p province=PROVINCE -p region=REGION -p mctype=ENGTYPE_2 -o $TOPOJSON/lowres/municities-province-${g}-${f}.topo.0.001.json $GEOJSON/lowres/municities-province-${g}-${f}.0.001.json
done

