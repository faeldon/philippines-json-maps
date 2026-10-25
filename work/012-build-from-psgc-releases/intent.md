---
id: 012
slug: build-from-psgc-releases
tier: 2
impact: major
stage: shipped
created: 2026-10-25
updated: 2026-10-25
shipped: 2026-10-25
idea:
depends_on:
serves: [O1, O2]
---

# 012 — Build from the faeldon/philippines-psgc-shapefiles releases

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

The source shapefiles moved. `altcoder/philippines-psgc-shapefiles` is archived (its last commit,
`e2954bd`, is a banner pointing to `faeldon/philippines-psgc-shapefiles`) and its files stay at
4Q 2023 for good. Four places still send people to the old repo: `README.md:49` (source link),
`README.md:91` (step 3 of "Using the Scripts"), `AGENTS.md:4` and `.sdlc/SDLC.md:190`.

Following those links wouldn't get anyone working input anyway. To fix its Git LFS problems, the
new repo publishes shapefiles only as GitHub release assets: nothing is in git or LFS, and it has
one commit. So the README's step "copy the zipped shapefiles into `scripts/2023/processed`" points
at files that no longer exist where it says. Even with the right zips, the scripts wouldn't run on
them. The new releases changed the zip layout in every release, `psgc-2023-4q` included:

- Each zip holds one layer, `PH_AdmN_*.shp` (the scripts read `PH_AdmN_*.shp.shp`).
- The layer is in EPSG:32651 metres. The old WGS84 layer that sat first in each zip is gone.
- `.cpg` now declares UTF-8.

The new release also corrects parent codes that the published `2023/` files got wrong:

- The BARMM interim province is `1999900000`, not `1909900000`.
- Cities under no province carry their geographic province or NCR district as `adm2_psgc`.
- Manila's sub-municipalities sit under `1380600000`.
- Every `adm1/2/3_psgc` now exists in the level above.

This is the class of bug behind `8bea49f3`, `8eeead56` and `c389e081`, which were each fixed by
hand.

## Outcome

- Every reference to the shapefile source names `faeldon/philippines-psgc-shapefiles`.
  `git grep altcoder/philippines-psgc-shapefiles` finds nothing outside `2011/` and `2019/`.
- The scripts get their input themselves, never by a manual copy. Locally, they copy the zips
  from `/Users/jafaeldon/projects-personal/faeldon/philippines-psgc-shapefiles/release-staging/<quarter>/`
  after `shasum -a 256 -c SHA256SUMS` passes there, and after checking that `meta.json`'s
  `publication` is the quarter asked for. Anywhere else, or when that folder is missing, they
  download the same files from the pinned release
  (`https://github.com/faeldon/philippines-psgc-shapefiles/releases/download/psgc-2023-4q/<file>`,
  plain `curl -L`) and verify them the same way. The GitHub release is the source of record. No
  shapefile is committed here.
- `2023/` is regenerated from `psgc-2023-4q` with the corrected parent codes. Every feature in a
  child file carries the parent code in its file's name (the check `.sdlc/SDLC.md` proposes as the
  first scan). The BARMM interim province's municipalities are in a file named for `1999900000`.
- **Moves O1:** building a newer vintage becomes a change to one release tag, not hunting down and
  copying zips. The next quarter, 3Q 2026 as `v1.0.0`, is within one change's reach.
- **Moves O2:** the hierarchy errors that reached users and had to be fixed one by one by hand are
  corrected at the source: the 24 municipalities and Manila's 899 barangays missing from today's
  files appear, and the hierarchy check passes for every 2023 file. Data-error issues about
  misfiled areas in `2023/` should stop.

## Affected

- **Area:** the generation scripts, the `2023/` vintage, and the docs that describe how it's made.
- **Files & components:**
  - `scripts/topojson-{country,regions,provdists,municities}.sh`: get, verify, unzip, new layer
    names.
  - `README.md` (Source Files, Using the Scripts), `AGENTS.md`, `.sdlc/SDLC.md`, `.gitignore` if
    the download location changes.
  - Every file under `2023/geojson` and `2023/topojson`: 88 provdist and 1,642 municity files per
    format and resolution, plus country and regions.
- **Downstream:** everyone who hotlinks `raw.githubusercontent.com/.../master/2023/...`. Pushing
  `master` publishes. Anyone rebuilding the maps themselves follows the README.
- **Contracts:** all four invariants in `AGENTS.md`.
  - **Paths are public API:** the parent-code corrections rename some published files
    (`municities-provdist-1909900000.*` becomes `…-1999900000.*`) and may drop files named after a
    city's own code.
  - **PSGC hierarchy:** the reason for regenerating.
  - **Output location and CRS:** the input is now UTM, so reprojecting to EPSG:4326 must be
    explicit in every script.
  - **Old vintages frozen:** `2011/` and `2019/` must not be touched, old links included.

## Constraints

- `2011/` and `2019/` stay byte for byte as they are.
- Output stays WGS84 longitude/latitude at 10%, 1% and 0.1%, with the same file-name pattern and
  integer codes (`100000000`, not `0100000000`).
- Build from a pinned tag, never `releases/latest/download/`. That URL moves when a quarter is
  published, and would silently turn `2023/` into a different vintage.
- Don't consume the `sources` release; it holds raw OCHA/HDX inputs.
- Copy from `release-staging/`, never symlink or hard-link it, and never write into it: it is the
  shapefiles repo's scratch area and can be replaced or deleted.
- Nothing may depend on that path existing: it is on this Mac only.
- The fetched input is never committed, and the script output lands at the repo root, not under
  `scripts/2023/`. The gate checks the second.

## Open questions

- ~~What happens to a hotlinked file whose name changes (e.g. `municities-provdist-1909900000`)?
  Keep the old path as a copy for a while, or delete it and say so in the README? The invariant
  calls either a breaking change.~~ Resolved: delete it (it is empty today) with a README note;
  ship records `impact: major` (spec R12).
- ~~Which published files disappear or appear when cities move from their own code to their
  geographic province or NCR district? We need the full list of renamed, added and removed paths
  before anything is pushed.~~ Resolved: none but the one rename. The 16 cities were missing from
  every `provdists/` file, so they are added to existing files (spec R10, R13).
- ~~Do the new zips' attributes match the properties the published files carry? The `pop_2015`,
  `pop_2020`, `city_class`, `inc_class`, `urb_rur` and `status` columns are gone, and `geom_src` is
  new at adm4. Is dropping them from the 2023 files acceptable?~~ Resolved: the published files
  never carried those columns; properties already match, and adm4 gains `geom_src`.
- ~~`psgc-2023-4q`'s adm4 has 42,017 rows, and some may have no shape. How should the scripts handle
  a null geometry: skip it, keep it with null geometry, or fail?~~ Resolved: 14 rows (Manila's
  sub-municipalities) have none; they are left out (spec R11).
- ~~Names lost trailing spaces (80 adm3, 2,774 adm4). Does anything key on the old names?~~
  Resolved: neither the published files nor the 2023-4q release carry trailing spaces.
- ~~Where do fetched files go (`scripts/2023/processed/` or a cache outside the repo), and does a
  re-run skip files already fetched and verified?~~ Resolved: `scripts/processed/<quarter>/`,
  already ignored; a re-run with verified files fetches nothing (spec R2, R5).
- ~~Should 3Q 2026 (`v1.0.0`) become `2026/` here, or in its own change? Probably its own: a new
  vintage is always Tier 2.~~ Resolved: its own change.
