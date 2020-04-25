#!/usr/bin/env bash

SHAPEFILE="../shapefile/2018"
GEOJSON="../geojson/provinces"
TOPOJSON="../topojson/provinces"

unzip $SHAPEFILE/provinces/Provinces.zip -d $SHAPEFILE/provinces/
for f in $SHAPEFILE/provinces/*.shp ; do mv "$f" "$SHAPEFILE/provinces/Provinces.shp"; done
for f in $SHAPEFILE/provinces/*.dbf ; do mv "$f" "$SHAPEFILE/provinces/Provinces.dbf"; done

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[PROVINCE] Generataing Region List"
ogr2ogr -f CSV -select ADM1_PCODE regions_raw.csv $SHAPEFILE/regions/Regions.shp
sed 1d regions_raw.csv > regions.csv # Remove header
rm regions_raw.csv
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

echo "[PROVINCE] Reading Array"
getArray "regions.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  echo "[PROVINCE] Processing $f"
  ogr2ogr -mapFieldType Date=String -where "ADM1_PCODE='${array[$e]}'" -f GeoJSON $GEOJSON/provinces-region-${f}.json $SHAPEFILE/provinces/Provinces.shp
  
  mapshaper $GEOJSON/provinces-region-${f}.json -simplify 10% -o $GEOJSON/hires/provinces-region-${f}.0.1.json
  mapshaper $GEOJSON/provinces-region-${f}.json -simplify 1% -o $GEOJSON/medres/provinces-region-${f}.0.01.json
  mapshaper $GEOJSON/provinces-region-${f}.json -simplify 0.1% -o $GEOJSON/lowres/provinces-region-${f}.0.001.json

  geo2topo --id-property ADM2_PCODE -p name=ADM2_EN -p region_id=ADM1_PCODE -o $TOPOJSON/hires/provinces-region-${f}.topo.0.1.json $GEOJSON/hires/provinces-region-${f}.0.1.json
  geo2topo --id-property ADM2_PCODE -p name=ADM2_EN -p region_id=ADM1_PCODE -o $TOPOJSON/medres/provinces-region-${f}.topo.0.01.json $GEOJSON/medres/provinces-region-${f}.0.01.json
  geo2topo --id-property ADM2_PCODE -p name=ADM2_EN -p region_id=ADM1_PCODE -o $TOPOJSON/lowres/provinces-region-${f}.topo.0.001.json $GEOJSON/lowres/provinces-region-${f}.0.001.json

  rm $GEOJSON/provinces-region-${f}.json # Delete because this is a large file
done

rm regions.csv
