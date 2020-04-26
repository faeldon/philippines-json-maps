#!/usr/bin/env bash

SHAPEFILE="../shapefile/2018"
GEOJSON="../geojson/municties"
TOPOJSON="../topojson/municities"

unzip $SHAPEFILE/municities/Municities.zip -d $SHAPEFILE/municities/

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres
array=()

echo "[MUNICITY] Generataing Province List"
ogr2ogr -f CSV -select ADM2_PCODE provinces_raw.csv $SHAPEFILE/provinces/Provinces.shp
sed 1d provinces_raw.csv > provinces.csv # Remove header
rm provinces_raw.csv
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

echo "[MUNICITY] Reading Array"
getArray "provinces.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  echo "[MUNICITY] Processing $f"
  ogr2ogr -mapFieldType Date=String -where "ADM2_PCODE='${array[$e]}'" -f GeoJSON $GEOJSON/municities-province-${f}.json $SHAPEFILE/municities/Municities.shp
  
  mapshaper $GEOJSON/municities-province-${f}.json -simplify 10% -o $GEOJSON/hires/municities-province-${f}.0.1.json
  mapshaper $GEOJSON/municities-province-${f}.json -simplify 1% -o $GEOJSON/medres/municities-province-${f}.0.01.json
  mapshaper $GEOJSON/municities-province-${f}.json -simplify 0.1% -o $GEOJSON/lowres/municities-province-${f}.0.001.json

  geo2topo --id-property ADM3_PCODE -p name=ADM3_EN -p province_id=ADM2_PCODE -p region_id=ADM1_PCODE -o $TOPOJSON/hires/municities-province-${f}.topo.0.1.json $GEOJSON/hires/municities-province-${f}.0.1.json
  geo2topo --id-property ADM3_PCODE -p name=ADM3_EN -p province_id=ADM2_PCODE -p region_id=ADM1_PCODE -o $TOPOJSON/medres/municities-province-${f}.topo.0.01.json $GEOJSON/medres/municities-province-${f}.0.01.json
  geo2topo --id-property ADM3_PCODE -p name=ADM3_EN -p province_id=ADM2_PCODE -p region_id=ADM1_PCODE -o $TOPOJSON/lowres/municities-province-${f}.topo.0.001.json $GEOJSON/lowres/municities-province-${f}.0.001.json

  rm $GEOJSON/municities-province-${f}.json # Delete because this is a large file
done

rm provinces.csv
