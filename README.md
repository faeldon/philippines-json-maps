# Philippines Administrative Boundaries JSON Maps

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/faeldon/ph-administrative-boundaries/master/LICENSE)

Philippine administrative boundaries in geojson and topojson format at
various resolution.

[Demo](https://github.com/faeldon/philippines-json-maps/blob/master/topojson/provinces/hires/provinces-region-calabarzonregioniva.topo.0.1.json)

This repository contains Philippines vector maps suitable for use on
web applications either as an overlay to interactive map services (ex.
[Leaflet](www.leafletjs.com)) or rendered on HTML canvas (ex.
[d3js](www.d3js.org)).

You can download the map files in the following directories.

    .
    ├── topojson
    ├── geojson
    └── ...

Low resolution topojson files are well suited for resource-constrained
scenarios such as rendering dynamic maps using slow network
connection. For optimal performance use medium resolution or low
resolution maps.

## Sample Maps

Files are generated for all locations in the Philippines at all
administrative levels.

For example the the regions map will show regional boundaries on the
entire country. Shown below rendered using [geojson.io](www.geojson.io).

`./topojson/regions/hires/regions.topo.0.1.json`
<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/regions.png" width="300">

While the each of the provinces map will show provincial boundaries
in a region.

`./topojson/provinces/hires/provinces-region-cagayanvalleyregionii.topo.0.1.json`
<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/province.png" width="300">

Same with municipalities and cities.

`./topojson/municities/hires/municities-province-47-metropolitanmanila.topo.0.1.json`
<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/municity.png" width="300">

## Source Files

The raw shapefiles used to generate downstream json formats were
downloaded from [GADM Website](http://www.gadm.org/).

Maps are using the WGS 1984, Lat/Long projection.

Maps last update was 2011.

## Files Available

Raw shapefiles, geojson and topojson for all political boundary are
made available. Barangay level is still under development. Please feel
free to file any issues found.

| Level   | Name                     |
| ------- | ------------------------ |
| Level 0 | Country                  |
| Level 1 | Region                   |
| Level 2 | Province                 |
| Level 3 | Municipality/Cities      |
| Level 4 | Barangays (EXPERIMENTAL) |

GeoJSON and Topojson formats are available in high, medium and low resolution files.

## Conversion Process

Shapefiles to GeoJSON conversion with high fidelity was done using [ogr2ogr](https://gdal.org/programs/ogr2ogr.html).

The high fidelity GeoJSON file is "downsampled" using [mapshaper](https://mapshaper.org/) with `-simplify` flag at 10% (hires), 1% (medres), 0.1% (lowres) settings.

GeoJSON is then converted to a more compact topojson format using [geo2topo](https://github.com/topojson/topojson).

### Using the Scripts (OPTIONAL)

You can modify and run the scripts on your own. For example if you want to have your own settings for mapshaper simplify algorithm.

1. Install Dependencies

```bash
npm install -g mapshaper
npm install -g topojson
```

2. Modify scripts under `scripts/`

3. Run the scripts (running barangays-topojson.sh might take a few minutes to finish)

```bash
cd scripts
./country-topojson.sh
./regions-topojson.sh
./provinces-topojson.sh
./municities-topojson.sh
./barangays-topojson.sh
```

## Contributing

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](CODE_OF_CONDUCT.md).



