# Philippines Administrative Boundaries JSON Maps

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/LICENSE)

Philippine administrative boundaries in geojson and topojson format at various resolution.

[Demo](https://github.com/faeldon/philippines-json-maps/blob/master/latest/topojson/regions/lowres/provdists-region-200000000.topo.0.001.json)

This repository contains Philippines vector maps suitable for use on
web applications either as an overlay to interactive map services (ex.
[Leaflet](www.leafletjs.com)) or rendered on HTML canvas (ex.
[d3js](www.d3js.org)).

The newest maps are in `latest/`: PSGC 3Q 2026, in medium and low resolution.

    latest
    ├── manifest.json   # version, PSGC quarter, source release
    ├── topojson
    │   └── <country|regions|provdists|municities>/<medres|lowres>/
    └── geojson
        └── ...

High resolution files, and every earlier vintage, are in this repo's
[releases](https://github.com/faeldon/philippines-json-maps/releases), one zip per format and
resolution with a `SHA256SUMS`. Release `v1.0.0` is 3Q 2026; link a release asset, not
`latest/`, when you need a quarter that never changes.

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

Maps are in WGS84 longitude/latitude (EPSG:4326), reprojected from the source shapefiles' EPSG:32651.

The shapefiles used as source for this project are published as releases of [faeldon/philippines-psgc-shapefiles](https://github.com/faeldon/philippines-psgc-shapefiles). `latest/` is built from its release [`v1.0.0`](https://github.com/faeldon/philippines-psgc-shapefiles/releases/tag/v1.0.0), PSGC 3Q 2026; `latest/manifest.json` says which quarter and release it holds.

**Codes changed in 3Q 2026.** The Negros Island Region (`1800000000`) was created from Negros Occidental, Negros Oriental and Siquijor, and Sulu moved to Region IX, so their codes changed (e.g. `604500000` → `1804500000`, `1906600000` → `906600000`). A file's name holds its parent's code, so those files are renamed: the [v1.0.0 release notes](https://github.com/faeldon/philippines-json-maps/releases/tag/v1.0.0) list every one.

**Barangay shapes.** Each barangay keeps the source's `geom_src` property: `source` is the boundary file's own shape, `dissolved` the union of barangays PSA has merged, and `plotted` a barangay plotted from the bearings and distances of the law that created it. Barangays the source has no shape for (`geom_src` `none`) are left out.

## Previous Maps

`2023/`, `2019/` and `2011/` left the tree in v1.0.0. Each is a release, with every file it held:

- [`2023-4q`](https://github.com/faeldon/philippines-json-maps/releases/tag/2023-4q): PSGC 4Q 2023, formerly `2023/`
- [`2019`](https://github.com/faeldon/philippines-json-maps/releases/tag/2019): formerly `2019/`
- [`2011`](https://github.com/faeldon/philippines-json-maps/releases/tag/2011): formerly `2011/`

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

GeoJSON and Topojson formats are available in medium and low resolution in `latest/`, and in high, medium and low resolution in each release.

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

3. Build a quarter, naming the source release and the quarter. This runs the four level scripts in order and writes every format and resolution to `2026-3q/` (ignored by git). Each script fetches the shapefiles it needs with `scripts/fetch-shapefiles.sh` into `scripts/processed/2026-3q/` (also ignored) and checks them against the release's `SHA256SUMS`. It copies them from a local checkout of `philippines-psgc-shapefiles` beside this repo when one has them (set `PSGC_STAGING` to point elsewhere), and otherwise downloads them from the release. The barangay level takes a while.

```bash
scripts/build-quarter.sh v1.0.0 2026-3q
```

4. To publish it in the tree, `scripts/publish-latest.sh 2026-3q` replaces `latest/` with its medium and low resolution files.

## Contributing

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](./.github/CODE_OF_CONDUCT.md).

Kindly report data errors by filing issues.


