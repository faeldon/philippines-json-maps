# Philippines Administrative Boundaries JSON Maps

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/LICENSE)

Philippine administrative boundaries in geojson and topojson format at various resolution.

[Demo](https://github.com/faeldon/philippines-json-maps/blob/master/2023/topojson/regions/lowres/provdists-region-200000000.topo.0.001.json)

This repository contains Philippines vector maps suitable for use on
web applications either as an overlay to interactive map services (ex.
[Leaflet](www.leafletjs.com)) or rendered on HTML canvas (ex.
[d3js](www.d3js.org)).

You can download the map files in the following directories.

    2023
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

While the each of the provinces map will show provincial boundaries
in a region.

<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/province.png" width="300">

Same with municipalities and cities and barangays.

<img src="https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/images/municity.png" width="300">

## Source Files

Maps are using EPSG:32651, Lat/Long projection.

The shapefiles used as source for this project is available from [altcoder/philippines-psgc-shapefiles](https://github.com/altcoder/philippines-psgc-shapefiles).

The administrative level shapefiles uses PSGC data updated as of [31 December 2023](https://psa.gov.ph/system/files/scd/PSGC-4Q-2023-National-and-Provincial-Summary.xlsx).

## Previous Maps

Output from a 2019, 2011 versions is available under `2011/` and `2019/` directory.

## Files Available

Raw shapefiles, geojson and topojson for all political boundary are
made available. Please feel free to file issues found.

| Level   | Name                     |
| ------- | ------------------------ |
| Level 0 | Country                  |
| Level 1 | Region                   |
| Level 2 | Province/District        |
| Level 3 | Municipality/Cities      |
| Level 4 | Barangays/Sub-Municipalities |

GeoJSON and Topojson formats are available in high, medium and low resolution files.

## Conversion Process

Shapefiles to GeoJSON conversion with high fidelity was done using [ogr2ogr](https://gdal.org/programs/ogr2ogr.html).

The high fidelity GeoJSON file is "downsampled" using [mapshaper](https://mapshaper.org/) with `-simplify` flag at 10% (hires), 1% (medres), 0.1% (lowres) settings and coverted to a more compact [topojson format](https://github.com/topojson/topojson).

### Using the Scripts (OPTIONAL)

You can modify and run the scripts on your own. For example if you want to have your own settings for mapshaper simplify algorithm.

1. Install Dependencies

```bash
brew install gdal
npm install -g mapshaper
```

2. Modify scripts under `scripts/`

3. Run the scripts (running barangays-topojson.sh might take a few minutes to finish)

```bash
cd scripts
./topojson-country.sh
./topojson-regions.sh
./topojson-provdists.sh
./topojson-municities.sh
```

## Contributing

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](./.github/CODE_OF_CONDUCT.md).

Kindly report data errors by filing issues.


