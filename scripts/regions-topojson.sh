#!/usr/bin/env bash

rm -rf ../geojson/regions/*
rm -rf ../topojson/regions/*
mkdir -p ../geojson/regions/hires
mkdir -p ../geojson/regions/medres
mkdir -p ../geojson/regions/lowres
mkdir -p ../topojson/regions/hires
mkdir -p ../topojson/regions/medres
mkdir -p ../topojson/regions/lowres
echo "[REGION] Shape to GeoJSON"
ogr2ogr -f GeoJSON ../geojson/regions/regions.json ../shapefile/regions/Regions.shp

echo "[REGION] Simplifying GeoJSON"
mapshaper ../geojson/regions/regions.json -simplify 10% -o ../geojson/regions/hires/regions.0.1.json
mapshaper ../geojson/regions/regions.json -simplify 1% -o ../geojson/regions/medres/regions.0.01.json
mapshaper ../geojson/regions/regions.json -simplify 0.1% -o ../geojson/regions/lowres/regions.0.001.json

echo "[REGION] Converting to Topojson"
geo2topo --id-property REGION -p name=REGION -o ../topojson/regions/hires/regions.topo.0.1.json ../geojson/regions/hires/regions.0.1.json
geo2topo --id-property REGION -p name=REGION -o ../topojson/regions/medres/regions.topo.0.01.json ../geojson/regions/medres/regions.0.01.json
geo2topo --id-property REGION -p name=REGION -o ../topojson/regions/lowres/regions.topo.0.001.json ../geojson/regions/lowres/regions.0.001.json

