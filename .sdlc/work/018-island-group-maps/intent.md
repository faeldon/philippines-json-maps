---
id: 018
slug: island-group-maps
tier: 2
impact: minor
stage: shipped
created: 2026-10-28
updated: 2026-10-28
shipped: 2026-10-28
idea: 2026-10-28-1
depends_on:
serves: [O1, O2, O3]
closes: [2]
---

# 018 — Island-group maps (Luzon, Visayas, Mindanao)

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

People often map the Philippines by island group: Luzon, Visayas and Mindanao. Sales
territories, disaster reporting and news graphics all use it. The repo has no file for it. The
smallest unit we ship is the 18 regions in `latest/{geojson,topojson}/country/`, so anyone who
wants three shapes has to install mapshaper or GDAL and dissolve the regions themselves, using
their own guess about which region goes where. Issue #2 (chitgoks, January 2021: "Luzon, Visayas
Mindanao. Feature request. in geojson?") has been open for almost six years asking for this.

Island groups aren't a PSGC level. There is no code and no shapefile layer for them, so the
region-to-group mapping has to come from us. Two regions don't fit neatly. MIMAROPA
(`1700000000`) is part of Luzon administratively, but Palawan is often drawn with the Visayas or
on its own. The Negros Island Region (`1800000000`), created in 2024 from Negros Occidental,
Negros Oriental and Siquijor, is in the Visayas, but it's new enough that older lookup tables
won't have it.

## Outcome

- One file per format and resolution holds three features, Luzon, Visayas and Mindanao,
  dissolved from the same quarter's region boundaries. GeoJSON and TopoJSON go in `latest/` at
  medres and lowres, and hires goes in each quarter's release, like every other level.
- Every region is in exactly one island group, by a written mapping in the repo that the build
  reads. A `jq` check over the output shows all 18 `adm1_psgc` codes assigned, none twice and
  none missing.
- The file is rebuilt by `scripts/build-quarter.sh` and published by `scripts/publish-latest.sh`
  with the rest of the quarter, so it never falls behind the regions it is made from.
- The README names the file and the mapping.
- **Moves O3:** a developer gets an island-group map from one raw URL, with no GIS tools. Issue
  #2 closes with a link instead of a mapshaper recipe.
- **Moves O2:** the mapping that has to be guessed today is written down and checked, so no
  region ends up in two island groups or in none.
- **Moves O1:** island groups follow region changes, like NIR in 2024, on the next quarterly
  build with no manual step.

## Affected

- **Area:** generation scripts and the `latest/` distribution.
- **Files & components:** a new mapping file (region code → island group); a new step in
  `scripts/topojson-country.sh` or a new script called by `scripts/build-quarter.sh`;
  `scripts/publish-latest.sh` (its file-count check and its copy loop list only the four
  levels); `scripts/release-assets.sh` if it lists levels; `README.md`; possibly
  `scripts/sample-maps.sh` for an image; `AGENTS.md`'s table of levels.
- **Downstream:** people who hotlink `raw.githubusercontent.com/.../master/latest/...`. The new
  path is live as soon as `master` is pushed, and it can't be renamed after that. Each quarter's
  release zips will contain the new file.
- **Contracts:** *Paths are public API* (the new file's name and directory are permanent once
  pushed); *Output location and form* (WGS84, 10% / 1% / 0.1% from one source, `keep-shapes` on
  every `-simplify`, only medres and lowres committed). *The PSGC hierarchy holds* is a nearby
  risk: island groups aren't a PSGC level and have no code, so their feature id and their
  position in the hierarchy have to stay clearly separate from the four PSGC levels.

## Constraints

- No existing path under `latest/` changes, and no existing file's contents change. `country/`,
  `regions/`, `provdists/` and `municities/` stay byte-identical for the same quarter.
- The island-group shapes come from the same region layer and simplification settings as
  `country/`, so their borders match the regions'. That means `-simplify` with `keep-shapes`,
  reprojected to WGS84.
- `publish-latest.sh` still refuses an incomplete build. The new file adds to its checks; it
  doesn't loosen them.
- Hires stays out of the tree. The gate (`commands.check`) still passes.
- Releases already published don't change. The new file first appears in the next quarter's
  release, or in the next version built from 2026-3q.

## Open questions

- ~~Where does MIMAROPA go: Luzon, as in the official grouping, or a split with Palawan in the
  Visayas? A split would mean dissolving from provinces rather than regions.~~ Resolved: Luzon,
  whole; the groups are dissolved from regions only (spec R1).
- ~~Is NIR (`1800000000`) Visayas? Presumably yes, but the mapping should say why.~~ Resolved:
  Visayas, since Negros and Siquijor are; Sulu, now in Region IX, stays in Mindanao (spec R1).
- ~~What's the file's name and directory? Options include `latest/geojson/islandgroups/…`,
  `country/islandgroups.0.01.json` next to `country.0.01.json`, or another name. Whatever we pick
  is permanent, and it's outside the `<children>-<parent level>-<parent psgc>` naming scheme.~~
  Resolved: a new `islandgroups/` directory beside `country/`, files named
  `islandgroups[.topo].<res>.json` (spec R3).
- ~~What's the feature id? There's no PSGC code. A name (`luzon`), a made-up code, or something
  else, and what goes in `properties` (the region codes it holds?).~~ Resolved: the name
  (`Luzon`, `Visayas`, `Mindanao`), with `island_group` and summed `area_km2` in properties
  (spec R5).
- ~~Should the file go into 2026-3q now, as a minor release built from the existing build, or wait
  for 2026-4q?~~ Resolved: now, built into the 2026-3q build and released as a minor version.
- ~~Should the README image (`scripts/sample-maps.sh`) include it?~~ Resolved: yes, a fourth
  image, `images/islandgroups.svg` (spec R11).
