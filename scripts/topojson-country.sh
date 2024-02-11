#!/usr/bin/env bash

SHAPEFILE="2023/processed"
GEOJSON="2023/geojson/country"
TOPOJSON="2023/topojson/country"

unzip $SHAPEFILE/PH_Adm1_Regions.shp.zip -d $SHAPEFILE/country/

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[COUNTRY] Simplifying GeoJSON"
mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp.shp -simplify 10% -proj wgs84 -o format=geojson id-field=adm1_psgc $GEOJSON/hires/country.0.1.json
mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp.shp -simplify 1% -proj wgs84 -o format=geojson id-field=adm1_psgc $GEOJSON/medres/country.0.01.json
mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp.shp -simplify 0.1% -proj wgs84 -o format=geojson id-field=adm1_psgc $GEOJSON/lowres/country.0.001.json

echo "[COUNTRY] Converting to Topojson"
mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp.shp -simplify 10% -proj wgs84 -o format=topojson id-field=adm1_psgc $TOPOJSON/hires/country.topo.0.1.json
mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp.shp -simplify 1% -proj wgs84 -o format=topojson id-field=adm1_psgc $TOPOJSON/medres/country.topo.0.01.json
mapshaper $SHAPEFILE/country/PH_Adm1_Regions.shp.shp -simplify 0.1% -proj wgs84 -o format=topojson id-field=adm1_psgc $TOPOJSON/lowres/country.topo.0.001.json
