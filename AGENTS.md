# AGENTS.md

Philippine administrative boundaries as GeoJSON and TopoJSON, generated from the PSGC shapefiles
released by [faeldon/philippines-psgc-shapefiles](https://github.com/faeldon/philippines-psgc-shapefiles)
(`2023/` from release `psgc-2023-4q`).
The repo is data: the JSON files are the product, and the scripts in `scripts/` made them.

## Commands

```bash
# The gate: every 2023 file parses, and nothing landed under scripts/2023/
find 2023 -name '*.json' -print0 | xargs -0 -n 500 jq empty \
  && test -z "$(git ls-files --cached --others --exclude-standard scripts/2023)"

# One file
jq empty 2023/topojson/regions/lowres/provdists-region-1100000000.topo.0.001.json

# Which parent codes a child file's features carry (should be one: the code in its name)
jq '[.features[].properties.adm2_psgc] | unique' 2023/geojson/provdists/lowres/municities-provdist-1102400000.0.001.json
```

Regenerating needs `brew install gdal` and `npm install -g mapshaper`. Run the scripts in order,
from anywhere: country, regions, provdists, municities. Each first runs
`scripts/fetch-shapefiles.sh <tag> <quarter>`, which puts the release's zips and CSVs in
`scripts/processed/<quarter>/` (gitignored), copied from
`../philippines-psgc-shapefiles/release-staging/<quarter>/` when that verifies (`PSGC_STAGING`
overrides it) and otherwise downloaded from the release, then checked against `SHA256SUMS`.
Each script `rm -rf`s its level's output before writing it. municities takes the longest by far.

## How the files are made

Each script takes one administrative level's shapefile and, for every area one level up, filters
its children with `ogr2ogr -where "admN_psgc=<code>"`, reprojects to EPSG:4326, then writes six
files with `mapshaper`: GeoJSON and TopoJSON, each simplified to 10% (`hires`, `.0.1`), 1%
(`medres`, `.0.01`) and 0.1% (`lowres`, `.0.001`). The script named for a level writes the
*children* of that level, so the names are offset by one:

| Script | Directory | One file per | Holds | Feature id |
|---|---|---|---|---|
| `topojson-country.sh` | `country/` | the country | regions | `adm1_psgc` |
| `topojson-regions.sh` | `regions/` | region | provinces and districts | `adm2_psgc` |
| `topojson-provdists.sh` | `provdists/` | province or district | municipalities and cities | `adm3_psgc` |
| `topojson-municities.sh` | `municities/` | municipality or city | barangays and sub-municipalities | `adm4_psgc` |

File names are `<children>-<parent level>-<parent psgc>[.topo].<0.1|0.01|0.001>.json`, the
code written as an integer (`100000000` for region 01). Every feature also carries the codes of
all its ancestors in `properties` (`adm1_psgc` … ), which is how a misfiled area shows.

The scripts find the repo root from their own path and write `2023/...` there. Each pins its
vintage in one header line (`YEAR=2023 TAG=psgc-2023-4q QUARTER=2023-4q`). The source layers are in
EPSG:32651 metres; `ogr2ogr -t_srs EPSG:4326` and `mapshaper -proj wgs84` reproject them.
Barangay rows with `geom_src = 'none'` have no shape and are left out.

mapshaper's `-simplify N%` keeps N% of the *whole layer's* vertices, so adding or removing one
feature from a parent's file reshapes its neighbours at medres and lowres. A membership change
shows up as geometry diffs across that whole file.
Every `-simplify` carries `keep-shapes`; without it, small barangays collapse to `geometry: null`
at medres and lowres (911 did before change 012).

## Invariants

- **Paths are public API.** The directory layout and every file name are hotlinked through
  `raw.githubusercontent.com/.../master/...`. Renaming or moving a published file, or changing
  how a code is written in a name, is a breaking change.
- **The PSGC hierarchy holds.** Feature ids are the PSGC code of their level, and each child file
  holds exactly the children of the parent its name gives: every feature's parent code is that
  code, and no child of that parent is missing or in another file.
- **Old vintages are frozen.** `2011/` and `2019/` are never regenerated or edited. A new PSGC
  release becomes a new `<year>/` directory.
- **Output location and form.** Generated files live only under `<year>/` at the repo root, in
  WGS84 longitude/latitude, at 10%, 1% and 0.1% from the same source. Source shapefiles are never
  committed.
