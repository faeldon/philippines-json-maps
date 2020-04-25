#!/usr/bin/env bash

SHAPEFILE="../shapefile/2018"
GEOJSON="../geojson/regions"
TOPOJSON="../topojson/regions"

unzip $SHAPEFILE/regions/Regions.zip -d $SHAPEFILE/regions/
for f in $SHAPEFILE/regions/*.shp ; do mv "$f" "$SHAPEFILE/regions/Regions.shp"; done
for f in $SHAPEFILE/regions/*.dbf ; do mv "$f" "$SHAPEFILE/regions/Regions.dbf"; done

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[REGION] Simplifying GeoJSON"
mapshaper $SHAPEFILE/regions/Regions.shp -simplify 10% -o format=geojson $GEOJSON/hires/regions.0.1.json
mapshaper $SHAPEFILE/regions/Regions.shp -simplify 1% -o format=geojson $GEOJSON/medres/regions.0.01.json
mapshaper $SHAPEFILE/regions/Regions.shp -simplify 0.1% -o format=geojson $GEOJSON/lowres/regions.0.001.json

echo "[REGION] Converting to Topojson"
geo2topo --id-property ADM1_PCODE -p name=ADM1_EN -o $TOPOJSON/hires/regions.topo.0.1.json $GEOJSON/hires/regions.0.1.json
geo2topo --id-property ADM1_PCODE -p name=ADM1_EN -o $TOPOJSON/medres/regions.topo.0.01.json $GEOJSON/medres/regions.0.01.json
geo2topo --id-property ADM1_PCODE -p name=ADM1_EN -o $TOPOJSON/lowres/regions.topo.0.001.json $GEOJSON/lowres/regions.0.001.json
