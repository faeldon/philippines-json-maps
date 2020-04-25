# Philippines Administrative Boundaries JSON Maps

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/LICENSE)
[![Join the chat at https://gitter.im/faeldon/philippines-json-maps](https://badges.gitter.im/faeldon/philippines-json-maps.svg)](https://gitter.im/faeldon/philippines-json-maps?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Philippine administrative boundaries in geojson and topojson format at
various resolution.

[Demo](https://github.com/faeldon/philippines-json-maps/blob/master/topojson/provinces/lowres/provinces-region-ph020000000.topo.0.001.json)

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

Files are generated for all locations in the Philippines at different
administrative levels.

For example, the regions map will show regional boundaries on the
entire country. Shown below rendered using [geojson.io](www.geojson.io).

<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/regions.png" width="300">

[regions.topo.0.1.json](https://github.com/faeldon/philippines-json-maps/blob/master/topojson/regions/hires/regions.topo.0.1.json)

While the each of the provinces map will show provincial boundaries
in a region.

<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/province.png" width="300">

[provinces-region-ph020000000.topo.0.1.json](https://github.com/faeldon/philippines-json-maps/blob/master/topojson/provinces/hires/provinces-region-ph020000000.topo.0.1.json)

Same with municipalities and cities.

<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/municity.png" width="300">

[municities-province-47-ph137500000.topo.0.1.json](https://github.com/faeldon/philippines-json-maps/blob/master/topojson/municities/hires/municities-province-ph137500000.topo.0.1.json)

## Source Files

The raw shapefiles used to generate downstream json formats were
downloaded from [OCHA Services Website](https://data.humdata.org/dataset/philippines-administrative-levels-0-to-3).

Maps are using the WGS 1984, Lat/Long projection.

Maps last update was 2018.

LIMITATION: NIR Region is still present

ARCHIVE: Output from a 2011 version using [GADM Website Data](https://gadm.org)
is also available under 2011 directory.

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

GeoJSON and Topojson formats are available in high, medium and low resolution files.

## Conversion Process

Shapefiles to GeoJSON conversion with high fidelity was done using [ogr2ogr](https://gdal.org/programs/ogr2ogr.html).

The high fidelity GeoJSON file is "downsampled" using [mapshaper](https://mapshaper.org/) with `-simplify` flag at 10% (hires), 1% (medres), 0.1% (lowres) settings.

GeoJSON is then converted to a more compact topojson format using [geo2topo](https://github.com/topojson/topojson).

### Using the Scripts (OPTIONAL)

You can modify and run the scripts on your own. For example if you want to have your own settings for mapshaper simplify algorithm.

1. Install Dependencies

```bash
brew install gdal
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
```

### Git LFS

This repository uses Git LFS to store shapefiles larger than 100mb

## Contributing

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](./.github/CODE_OF_CONDUCT.md).



