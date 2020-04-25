#!/usr/bin/env bash

rm -rf ../geojson/country/*
rm -rf ../topojson/country/*
mkdir -p ../geojson/country/hires
mkdir -p ../geojson/country/medres
mkdir -p ../geojson/country/lowres
mkdir -p ../topojson/country/hires
mkdir -p ../topojson/country/medres
mkdir -p ../topojson/country/lowres

#echo "[COUNTRY] Shape to GeoJSON"
#mapshaper ../shapefile/2018/country/Country.shp -o format=geojson ../geojson/country/country.json

echo "[COUNTRY] Simplifying GeoJSON"
mapshaper ../shapefile/2018/country/Country.shp -simplify 10% -o format=geojson ../geojson/country/hires/country.0.1.json
mapshaper ../shapefile/2018/country/Country.shp -simplify 1% -o format=geojson ../geojson/country/medres/country.0.01.json
mapshaper ../shapefile/2018/country/Country.shp -simplify 0.1% -o format=geojson ../geojson/country/lowres/country.0.001.json

echo "[COUNTRY] Converting to Topojson"
geo2topo --id-property ID_0 -p name=NAME_ENGLI -o ../topojson/country/hires/country.topo.0.1.json ../geojson/country/hires/country.0.1.json
geo2topo --id-property ID_0 -p name=NAME_ENGLI -o ../topojson/country/medres/country.topo.0.01.json ../geojson/country/medres/country.0.01.json
geo2topo --id-property ID_0 -p name=NAME_ENGLI -o ../topojson/country/lowres/country.topo.0.001.json ../geojson/country/lowres/country.0.001.json
