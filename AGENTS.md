# AGENTS.md

Philippine administrative boundaries as GeoJSON and TopoJSON, generated from the PSGC shapefiles
released by [faeldon/philippines-psgc-shapefiles](https://github.com/faeldon/philippines-psgc-shapefiles).
The repo is data: the JSON files are the product, and the scripts in `scripts/` made them.
The tree holds one distribution, `latest/` (the newest quarter, medres and lowres, recorded in
`latest/manifest.json`); every quarter, with hires, is a GitHub release of this repo.

## Commands

```bash
# The gate: every latest/ file parses, and nothing that must stay out of the tree is in it
find latest -name '*.json' -print0 | xargs -0 -n 500 jq empty \
  && test -z "$(git ls-files --cached --others --exclude-standard -- ':(glob)[0-9][0-9][0-9][0-9]-[1-4]q/**' dist 'scripts/20*' ':(glob)**/hires/**')"

# One file
jq empty latest/topojson/regions/lowres/provdists-region-1100000000.topo.0.001.json

# Which parent codes a child file's features carry (should be one: the code in its name)
jq '[.features[].properties.adm2_psgc] | unique' latest/geojson/provdists/lowres/municities-provdist-1102400000.0.001.json
```

Regenerating needs `brew install gdal` and `npm install -g mapshaper`. A new quarter is:

```bash
scripts/build-quarter.sh v1.0.0 2026-3q   # source release tag, quarter: builds 2026-3q/ (ignored)
scripts/publish-latest.sh 2026-3q         # replaces latest/ with its medres + lowres
scripts/sample-maps.sh                    # redraws the README's images/ from latest/
```

`build-quarter.sh` runs the four level scripts in order (country, regions, provdists,
municities; each takes the same `TAG QUARTER` and prints its usage without them) and writes
`<quarter>/build.json`. Each script first runs `scripts/fetch-shapefiles.sh <tag> <quarter>`,
which puts the release's zips and CSVs in `scripts/processed/<quarter>/` (gitignored), copied
from `../philippines-psgc-shapefiles/release-staging/<quarter>/` when that verifies
(`PSGC_STAGING` overrides it) and otherwise downloaded from the release, then checked against
`SHA256SUMS`. Each script `rm -rf`s its level's output before writing it. municities takes the
longest by far. `publish-latest.sh` refuses a build whose file counts don't match the release
CSVs, and keeps the manifest's `version`, which only `/sdlc:release` changes.

Releases: `/sdlc:release` bumps `latest/manifest.json`'s version and tags `v<version>`; its
`release.prepare` (`scripts/release-assets.sh`) zips the quarter's build directory, hires
included, into `dist/<tag>/` with `SHA256SUMS` and notes (renamed paths from
`scripts/renamed-paths.sh`); `/sdlc:publish` pushes and runs `scripts/release-publish.sh`. The
build directory must exist in the checkout that releases. `scripts/release-legacy.sh` made the
one-off releases `2023-4q`, `2019` and `2011` from history.

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
all its ancestors in `properties` (`adm1_psgc` … ), which is how a misfiled area shows. A name
changes when its parent's code does (3Q 2026 renamed 4 `provdists/` and 82 `municities/` files,
from the Negros Island Region and Sulu's transfer), and each release's notes list those.

The scripts find the repo root from their own path and write `<quarter>/...` there. The source
layers are in EPSG:32651 metres; `ogr2ogr -t_srs EPSG:4326` and `mapshaper -proj wgs84`
reproject them. Barangays come from the standard `PH_Adm4_BgySubMuns` (not `_complete`); rows
with `geom_src = 'none'` have no shape and are left out, and `geom_src` stays in the properties.

mapshaper's `-simplify N%` keeps N% of the *whole layer's* vertices, so adding or removing one
feature from a parent's file reshapes its neighbours at medres and lowres. A membership change
shows up as geometry diffs across that whole file.
Every `-simplify` carries `keep-shapes`; without it, small barangays collapse to `geometry: null`
at medres and lowres (911 did before change 012).

## Invariants

- **Paths are public API.** `latest/`'s layout and naming are stable and hotlinked through
  `raw.githubusercontent.com/.../master/latest/...`. A file name changes only when its PSGC code
  does, and every release's notes list those. Each release's assets are immutable once published.
- **Vintages are releases.** Every PSGC quarter is a GitHub release of this repo with all
  resolutions and a `SHA256SUMS`; a published release is never replaced. Only the newest quarter
  is in the tree, at `latest/`, medres and lowres only.
- **The PSGC hierarchy holds.** Feature ids are the PSGC code of their level, and each child file
  holds exactly the children of the parent its name gives: every feature's parent code is that
  code, and no child of that parent is missing or in another file.
- **Output location and form.** Generated files are committed only under `latest/`; build
  directories, `dist/` and source shapefiles never are. WGS84 longitude/latitude, at 10%, 1% and
  0.1% from one source, with `keep-shapes` on every `-simplify`.
