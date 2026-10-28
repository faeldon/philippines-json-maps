---
id: 018
slug: island-group-maps
kind: spec
created: 2026-10-28
updated: 2026-10-28
---

# 018 — Island-group maps (Luzon, Visayas, Mindanao) · spec

> Tier 2 only. Reads from intent.md; read by plan.md. If you can't write a testable requirement
> list, the intent isn't understood yet — go back to Stage 1 rather than designing around the fog.

## Requirements

1. **R1. The mapping is a file.** `scripts/island-groups.csv` has columns
   `adm1_psgc,island_group` and one row for each of the 18 regions in 2026-3q. NCR, CAR, I, II,
   III, IV-A, V and MIMAROPA are `Luzon`. VI, VII, VIII and NIR are `Visayas`. IX, X, XI, XII,
   Caraga and BARMM are `Mindanao`. The codes are integers, like everywhere else.
2. **R2. The build refuses a mapping that doesn't match.** `scripts/topojson-islandgroups.sh TAG
   QUARTER` exits non-zero and writes nothing if any of these is true: a region in the quarter's
   `PH_Adm1_Regions.csv` has no row, a row names a code that isn't in the CSV, a code appears
   twice, or a group isn't one of `Luzon`, `Visayas` or `Mindanao`. A new region code in a future
   quarter then stops the build instead of disappearing from the map.
3. **R3. Six files, the same layout as every other level.** The script writes
   `<quarter>/{geojson,topojson}/islandgroups/{hires,medres,lowres}/islandgroups[.topo].{0.1,0.01,0.001}.json`.
   Each holds exactly three features with ids `Luzon`, `Visayas` and `Mindanao`.
4. **R4. Shapes come from the regions, simplified the same way.** Each resolution is made by
   applying `-simplify N% keep-shapes` to the same `PH_Adm1_Regions.shp` the country level uses,
   then `-dissolve island_group`, then `-proj wgs84`. Every vertex of `islandgroups.0.0N.json` is
   a vertex of `country.0.0N.json` at the same resolution, so the groups' borders and coastlines
   are the regions' own. (The trial on 2026-3q found 0 extra vertices out of 12,118 at lowres and
   125,307 at medres.)
5. **R5. Feature properties.** Each feature has `island_group` (its name, the same as its `id`)
   and `area_km2`, the sum of its regions' `area_km2`. The TopoJSON object is named
   `islandgroups`.
6. **R6. Laguna de Bay is the only hole.** In both lowres and medres, Luzon has exactly one
   interior ring, Laguna de Bay, which no region claims. Visayas and Mindanao have none. Any other
   hole means the dissolve has opened a gap.
7. **R7. It's part of the quarterly build.** `scripts/build-quarter.sh` runs
   `topojson-islandgroups.sh` after `topojson-country.sh`.
8. **R8. publish-latest covers it.** `scripts/publish-latest.sh` expects one `islandgroups` file
   per format and resolution, refuses a build without it, and copies its medres and lowres to
   `latest/`.
9. **R9. release-assets covers it.** `scripts/release-assets.sh` refuses when the build's
   `islandgroups/` medres or lowres differs from `latest/`'s. The release zips contain all six
   islandgroups files, hires included. In the first release that has the new directory, the notes
   say which paths it added.
10. **R10. Nothing that exists today changes.** Rebuilding 2026-3q with this change leaves every
    file under `latest/{geojson,topojson}/{country,regions,provdists,municities}/`, and
    `latest/manifest.json`, byte-identical to `master`. The only new paths are the four files
    under `latest/*/islandgroups/{medres,lowres}/`.
11. **R11. The docs and images say so.** `README.md`'s Files table gets an `islandgroups/` row
    (one file for the country, holding island groups, id = name), plus a sentence saying where
    MIMAROPA and NIR go and that the mapping is in `scripts/island-groups.csv`.
    `scripts/sample-maps.sh` renders `images/islandgroups.svg` from lowres, and the README shows
    it as a fourth image. `AGENTS.md`'s level table and its "four level scripts" text include the
    new level, and its invariants make room for it (see Contracts touched).
12. **R12. The gate still passes,** and no `hires/` file, build directory or `dist/` is committed.

## Design

**Mapping.** `scripts/island-groups.csv` follows PSA's usual grouping, with MIMAROPA, including
Palawan, in Luzon. NIR is in the Visayas because Negros and Siquijor are. Sulu, which moved to
Region IX, stays in Mindanao either way. The CSV is the only place the grouping is written down.
The README points to it rather than repeating it.

**Script.** `scripts/topojson-islandgroups.sh` follows `topojson-country.sh` line for line. It
takes the same `TAG QUARTER` arguments, calls `fetch-shapefiles.sh`, unzips
`PH_Adm1_Regions.shp.zip`, and `rm -rf`s its own output before writing. Before running mapshaper
it checks the mapping against `scripts/processed/<quarter>/PH_Adm1_Regions.csv` (R2) with
`cut`/`sort`/`comm`, so the mapping is checked against the PSA's list rather than mapshaper's join
count. Each of the six outputs is one mapshaper command:

```
mapshaper PH_Adm1_Regions.shp -simplify N% keep-shapes \
  -join scripts/island-groups.csv keys=adm1_psgc,adm1_psgc field-types=adm1_psgc:number \
  -dissolve island_group sum-fields=area_km2 -rename-layers islandgroups \
  -proj wgs84 -o format=geojson|topojson id-field=island_group <out>
```

Simplifying before dissolving is what makes R4 hold. Arcs are simplified once, over the whole
region layer, exactly as for `country/`, and the dissolve only throws away the arcs inside each
group. Dissolving first would simplify a different set of arcs, so the coastlines wouldn't line up
with `country/`.

**Pipeline.** `build-quarter.sh`'s level loop becomes `country islandgroups regions provdists
municities`. `publish-latest.sh` and `release-assets.sh` add `islandgroups` to their level loops,
with `want_islandgroups=1`. The zips are built with `find "$fmt" -path "$fmt/*/$res/*"`, so they
pick up the new directory without changes. `renamed-paths.sh` stays as it is, because island-group
file names never carry a code. Instead, `release-assets.sh` adds an "Added paths" section to
`notes.md` when the previous tag had no `latest/geojson/islandgroups`.

**Shipping on 2026-3q.** The change runs `topojson-islandgroups.sh v1.0.0 2026-3q` into the
existing 2026-3q build directory, then runs `publish-latest.sh 2026-3q`, which rewrites `latest/`
from that directory (R10 checks nothing else moved). After ship, a minor release ships the new
files. The build directory, the source shapefiles under `scripts/processed/2026-3q/`, and
`../philippines-psgc-shapefiles/release-staging/` are all in the main checkout, not in this
worktree. How the worktree gets to them (`PSGC_STAGING`, a symlinked build directory, or building
in the main checkout) is a plan-mode decision. Either way, R9's diff check stops a release from a
build directory that lacks the new level.

## Contracts touched

- **Paths are public API.** Four new paths go under `latest/` (medres and lowres, both formats)
  and are permanent once pushed. No existing path is renamed or removed (R10). The names follow
  the `country.*` pattern for a file with no parent code: `islandgroups[.topo].<res>.json`.
- **Vintages are releases.** No published release changes. The new files first appear in the next
  minor release. Earlier releases (v1.0.0, and v1.0.1 when it's published) never get them.
- **The PSGC hierarchy holds.** ⚠ **This needs a policy edit.** The invariant says "Feature ids
  are the PSGC code of their level", and island groups have no PSGC code: their ids are names.
  AGENTS.md gets one sentence: `islandgroups/` is the one level outside the PSGC, its ids are its
  names, and its contents are set by `scripts/island-groups.csv` (R1, R2). The four PSGC levels
  and their hierarchy don't change.
- **Output location and form.** WGS84, simplified to 10%, 1% and 0.1% of the same
  `PH_Adm1_Regions` source, with `keep-shapes` on every `-simplify`. Only medres and lowres are
  committed. The gate is unchanged (R12).

## Alternatives rejected

- **Putting it under `country/`.** That's fewer directories, but `country/` would hold two files,
  which breaks its "one file per country, holds regions" row and the count of one file that
  publish-latest and release-assets check.
- **Dissolving before simplifying.** The coastlines would come out of a different simplification
  than `country/`'s. Overlaying the island groups on the regions would then show slivers, and R4
  couldn't be checked.
- **Splitting MIMAROPA, with Palawan in the Visayas.** That would mean dissolving from provinces,
  for a grouping few sources agree on. Rejected at Stage 2.
- **Leaving the grouping to users with a mapshaper recipe** (the #8 approach). That's what #2 has
  had for six years, and each user ends up guessing their own mapping.
- **A made-up numeric code for the ids** (e.g. `1`, `2`, `3`). It would look like a PSGC code and
  isn't one. Names are clearer and can't be confused with the hierarchy.
- **Listing each group's region codes in properties.** Arrays don't work well in Power BI and
  shapefile round-trips, and the CSV already records the mapping.

## Verification

- **Gate:** `commands.check` exits 0.
- **R2:** run the script with a copy of the CSV that has one row missing, then with one row
  duplicated. Each run exits non-zero and leaves no `islandgroups/` output.
- **R3, R5:** for each of the four committed files plus the two hires files,
  `jq '[.features[].id]'` (GeoJSON) or `jq '.objects.islandgroups.geometries | map(.id)'`
  (TopoJSON) gives `["Luzon","Visayas","Mindanao"]`. Each feature has `island_group` and
  `area_km2`, and the three areas add up to the country's total `area_km2`.
- **R4:** for lowres and medres, the vertex set-difference against `country.*` at the same
  resolution is 0.
- **R6:** a `jq` count of holes gives Luzon 1 (inside 121.05–121.48 E, 14.18–14.54 N) and Visayas
  and Mindanao 0.
- **R8:** with the islandgroups output removed, `publish-latest.sh 2026-3q` refuses with an
  `islandgroups` line. With it present, it succeeds.
- **R9:** `scripts/release-assets.sh <tag>` succeeds against the build,
  `unzip -l geojson-hires.zip | grep islandgroups` lists the file, and `notes.md` has the Added
  section.
- **R10:** `git diff --stat master -- latest/` shows only the four new `islandgroups` files. Every
  other path under `latest/`, `manifest.json` included, is unchanged.
- **R11:** `images/islandgroups.svg` renders three shapes, and the README shows it.
