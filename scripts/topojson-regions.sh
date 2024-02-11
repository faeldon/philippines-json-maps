#!/usr/bin/env bash

SHAPEFILE="2023/processed"
GEOJSON="2023/geojson/regions"
TOPOJSON="2023/topojson/regions"

unzip $SHAPEFILE/PH_Adm2_ProvDists.shp.zip -d $SHAPEFILE/regions/

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[REGIONS] Generataing Region List"
ogr2ogr -f CSV -select adm1_psgc regions_raw.csv $SHAPEFILE/country/PH_Adm1_Regions.shp.shp
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

echo "[REGIONS] Reading Array"
getArray "regions.csv"

for e in "${!array[@]}"
do
  f=`echo ${array[$e]} | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
  echo "[PROVDISTS] Processing $f"
  ogr2ogr -mapFieldType Date=String -where "adm1_psgc=$f" -t_srs "EPSG:4326" -f GeoJSON $GEOJSON/provdists-region-${f}.json $SHAPEFILE/regions/PH_Adm2_ProvDists.shp.shp

  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 10% -o format=geojson id-field=adm2_psgc $GEOJSON/hires/provdists-region-${f}.0.1.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 1% -o format=geojson id-field=adm2_psgc $GEOJSON/medres/provdists-region-${f}.0.01.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 0.1% -o format=geojson id-field=adm2_psgc $GEOJSON/lowres/provdists-region-${f}.0.001.json

  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 10% -o format=topojson id-field=adm2_psgc $TOPOJSON/hires/provdists-region-${f}.topo.0.1.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 1% -o format=topojson id-field=adm2_psgc $TOPOJSON/medres/provdists-region-${f}.topo.0.01.json
  mapshaper $GEOJSON/provdists-region-${f}.json -simplify 0.1% -o format=topojson id-field=adm2_psgc $TOPOJSON/lowres/provdists-region-${f}.topo.0.001.json

  rm $GEOJSON/provdists-region-${f}.json # Delete because this is a large file
done

rm regions.csv