#!/usr/bin/env bash

rm -rf ../geojson/regions/*
rm -rf ../topojson/regions/*
mkdir -p ../geojson/regions/hires
mkdir -p ../geojson/regions/medres
mkdir -p ../geojson/regions/lowres
mkdir -p ../topojson/regions/hires
mkdir -p ../topojson/regions/medres
mkdir -p ../topojson/regions/lowres

#echo "[REGION] Shape to GeoJSON"
#mapshaper ../shapefile/2018/regions/Regions.shp -o format=geojson ../geojson/regions/regions.json

echo "[REGION] Simplifying GeoJSON"
mapshaper ../shapefile/2018/regions/Regions.shp -simplify 10% -o format=geojson ../geojson/regions/hires/regions.0.1.json
mapshaper ../shapefile/2018/regions/Regions.shp -simplify 1% -o format=geojson ../geojson/regions/medres/regions.0.01.json
mapshaper ../shapefile/2018/regions/Regions.shp -simplify 0.1% -o format=geojson ../geojson/regions/lowres/regions.0.001.json

echo "[REGION] Converting to Topojson"
geo2topo --id-property REGION -p name=REGION -o ../topojson/regions/hires/regions.topo.0.1.json ../geojson/regions/hires/regions.0.1.json
geo2topo --id-property REGION -p name=REGION -o ../topojson/regions/medres/regions.topo.0.01.json ../geojson/regions/medres/regions.0.01.json
geo2topo --id-property REGION -p name=REGION -o ../topojson/regions/lowres/regions.topo.0.001.json ../geojson/regions/lowres/regions.0.001.json

