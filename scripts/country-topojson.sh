#!/usr/bin/env bash

SHAPEFILE="../shapefile/2018"
GEOJSON="../geojson/country"
TOPOJSON="../topojson/country"

unzip $SHAPEFILE/country/Country.zip -d $SHAPEFILE/country/

rm -rf $GEOJSON/*
rm -rf $TOPOJSON/*
mkdir -p $GEOJSON/hires
mkdir -p $GEOJSON/medres
mkdir -p $GEOJSON/lowres
mkdir -p $TOPOJSON/hires
mkdir -p $TOPOJSON/medres
mkdir -p $TOPOJSON/lowres

echo "[COUNTRY] Simplifying GeoJSON"
mapshaper $SHAPEFILE/country/Country.shp -simplify 10% -o format=geojson $GEOJSON/hires/country.0.1.json
mapshaper $SHAPEFILE/country/Country.shp -simplify 1% -o format=geojson $GEOJSON/medres/country.0.01.json
mapshaper $SHAPEFILE/country/Country.shp -simplify 0.1% -o format=geojson $GEOJSON/lowres/country.0.001.json

echo "[COUNTRY] Converting to Topojson"
geo2topo --id-property ADM0_PCODE -p name=ADM0_EN -o $TOPOJSON/hires/country.topo.0.1.json $GEOJSON/hires/country.0.1.json
geo2topo --id-property ADM0_PCODE -p name=ADM0_EN -o $TOPOJSON/medres/country.topo.0.01.json $GEOJSON/medres/country.0.01.json
geo2topo --id-property ADM0_PCODE -p name=ADM0_EN -o $TOPOJSON/lowres/country.topo.0.001.json $GEOJSON/lowres/country.0.001.json
