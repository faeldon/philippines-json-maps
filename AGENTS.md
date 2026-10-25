# AGENTS.md

Philippine administrative boundaries as GeoJSON and TopoJSON, generated from the PSGC shapefiles
in [altcoder/philippines-psgc-shapefiles](https://github.com/altcoder/philippines-psgc-shapefiles).
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

Regenerating needs `brew install gdal`, `npm install -g mapshaper`, and the source zips copied
into `scripts/2023/processed/` (gitignored). The scripts run from `scripts/`, in order: country,
regions, provdists, municities. Each `rm -rf`s its level's output before writing it.

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

The scripts write relative to `scripts/`, so a run lands in `scripts/2023/...`; the published
copy is `2023/...` at the root, and the output has to be moved there.

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
