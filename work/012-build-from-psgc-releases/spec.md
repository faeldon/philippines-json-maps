---
id: 012
slug: build-from-psgc-releases
kind: spec
created: 2026-10-25
updated: 2026-10-25
---

# 012 — Build from the faeldon/philippines-psgc-shapefiles releases · spec

> Tier 2 only. Reads from intent.md; read by plan.md. If you can't write a testable requirement
> list, the intent isn't understood yet — go back to Stage 1 rather than designing around the fog.

## Requirements

1. **R1. No reference to the old source.** `git grep -n 'altcoder/philippines-psgc-shapefiles' --
   ':!2011' ':!2019' ':!work'` prints nothing (change records in `work/` name it on purpose); `README.md`, `AGENTS.md` and `.sdlc/SDLC.md` link
   `https://github.com/faeldon/philippines-psgc-shapefiles` instead.
2. **R2. One fetch step, pinned.** `scripts/fetch-shapefiles.sh <tag> <quarter>` puts the four zips
   the scripts read (`PH_Adm1_Regions`, `PH_Adm2_ProvDists`, `PH_Adm3_MuniCities`,
   `PH_Adm4_BgySubMuns`, each `.shp.zip`), the adm2–adm4 CSVs (which R9's check reads) and the
   release's `SHA256SUMS` in
   `scripts/processed/<quarter>/`. The 2023 scripts call it with `psgc-2023-4q 2023-4q`; no script
   names `releases/latest`.
3. **R3. Local copy first, verified.** When
   `../philippines-psgc-shapefiles/release-staging/<quarter>/` (sibling of the repo's main checkout;
   overridable with `PSGC_STAGING`) exists, its `meta.json` `publication` equals `<quarter>`, and
   `shasum -a 256 -c` passes there for the four zips, they are **copied** (never linked) into
   `scripts/processed/<quarter>/`. Nothing is written into `release-staging/`.
4. **R4. Release download otherwise.** When that folder is missing, its `publication` differs, or
   its checksums fail, the fetch downloads the same files with `curl -fL` from
   `https://github.com/faeldon/philippines-psgc-shapefiles/releases/download/<tag>/<file>`, and
   says which source it used.
5. **R5. Verified before use.** Whatever the source, `shasum -a 256 -c` against the release's
   `SHA256SUMS` passes for every zip in `scripts/processed/<quarter>/` before any script unzips
   one; a mismatch deletes the bad file and exits non-zero. A re-run with all four already present
   and verified copies and downloads nothing.
6. **R6. Scripts read the new zip layout.** Each script unzips its zip and reads the one layer
   `PH_AdmN_*.shp` (not `*.shp.shp`); the four run in order with no manual step after the README's
   dependency install.
7. **R7. Output lands at the root.** Every script resolves its paths from its own location, so it
   writes `2023/...` at the repo root wherever it is run from; after a full run, the gate's
   `scripts/2023` test still passes.
8. **R8. WGS84 out, same resolutions and names.** Output is EPSG:4326 longitude/latitude (every
   coordinate within lon 114–128, lat 4–22), at 10%/1%/0.1% in GeoJSON and TopoJSON, with the
   existing file-name pattern and codes written as integers.
9. **R9. Hierarchy holds in every file.** For every child file under `2023/`, each feature's parent
   property (`adm1_psgc` in `regions/`, `adm2_psgc` in `provdists/`, `adm3_psgc` in `municities/`)
   equals the code in the file's name, and the feature ids in a parent's file are exactly the
   release's children of that parent with a shape. Checked by a `checks.md` section over all 2023
   lowres GeoJSON files.
10. **R10. The 24 missing municipalities appear.** The 16 cities under no province (e.g.
    `1030500000`, `330100000`) are in their geographic province's or NCR district's
    `provdists/` file, and `1999901000`–`1999908000` are in `municities-provdist-1999900000.*`.
11. **R11. Manila's barangays appear.** `bgysubmuns-municity-1380600000.*` holds Manila's 899 rows
    with a shape; the 14 sub-municipalities `1380601000`–`1380614000` (`geom_src = none`) are
    left out. No file under `2023/` has a feature with a null geometry.
12. **R12. The one renamed file.** `municities-provdist-1909900000.*` (6 files, empty today) is
    deleted, `municities-provdist-1999900000.*` exists in all six forms, and the README says the
    BARMM interim province's file moved and why. Ship settles `impact: major`.
13. **R13. Nothing else moves.** `git diff --stat master -- 2011 2019` is empty, and no other 2023
    path is added or removed: the set of 2023 file names differs from `master`'s by R12's twelve
    names only.
14. **R14. Every other changed file is accounted for.** The ship review lists 2023 files whose bytes
    changed outside the parents R10–R12 name; each is explained (geometry or a new `geom_src`
    property) in `notes.md`, or it is a finding.
15. **R15. README matches.** "Source Files" names the new repo and the pinned release; "Using the
    Scripts" no longer says to copy zips by hand and says what the fetch does (local staging copy
    if present, else the release).

## Design

**Fetch, once, in its own script.** `scripts/fetch-shapefiles.sh TAG QUARTER` is the only place
that knows where input comes from. It works out `ROOT` from its own path (`cd "$(dirname "$0")/.."`)
and writes to `$ROOT/scripts/processed/$QUARTER/`, which the existing `.gitignore` line
`scripts/processed/` already ignores, so no ignore change is needed and `scripts/2023/processed/`
stops being used. Steps:

1. If every wanted zip is present and `shasum -a 256 -c --ignore-missing SHA256SUMS` passes there,
   stop (R5's re-run).
2. Staging: `PSGC_STAGING` if set, else `$(git rev-parse --path-format=absolute
   --git-common-dir)/../../philippines-psgc-shapefiles/release-staging` — the sibling of the main
   checkout, so it resolves the same from a worktree. Use it if `meta.json`'s `publication` is
   `$QUARTER` (`jq -r`) and its own `shasum -c --ignore-missing` passes; `cp` the zips and
   `SHA256SUMS`.
3. Otherwise `curl -fL` each zip and `SHA256SUMS` from the tag's download URL.
4. Verify in the destination; on failure delete what didn't match and exit 1.

`SHA256SUMS` lists every asset (CSVs too); `--ignore-missing` lets it check just the four zips.

**The four generation scripts** keep their shape: per parent code, `ogr2ogr -where` then six
`mapshaper` runs. Changes:

- A header sets `ROOT`, `YEAR=2023`, `TAG=psgc-2023-4q`, `QUARTER=2023-4q`, then calls the fetch.
  `SHAPEFILE`, `GEOJSON` and `TOPOJSON` become `$ROOT/scripts/processed/$QUARTER`,
  `$ROOT/$YEAR/geojson/<level>`, `$ROOT/$YEAR/topojson/<level>` (R7).
- Layer paths drop the doubled extension: `.../country/PH_Adm1_Regions.shp`, etc. (R6).
- Reprojection stays explicit: `ogr2ogr -t_srs EPSG:4326` (already there), and the country
  script's `mapshaper -proj wgs84` reads the zip's `.prj` (EPSG:32651) (R8).
- Shapeless rows are dropped at the filter: the municities script's `ogr2ogr -where` gains
  `AND geom_src <> 'none'` (R11). The other levels have no `geom_src` and no shapeless rows in
  this release; R9's check would catch one.
- `unzip -o` so a re-run doesn't stop at a prompt.
- Every `-simplify` gains `keep-shapes` (R11), found at build: without it, medres and lowres
  simplification collapses small polygons to `geometry: null`. That was already true on `master`
  (703 lowres and 195 medres barangays, 5 lowres municipalities), so this also changes the
  medres/lowres shapes of files whose members didn't change. Decided 2026-10-25: fix it here, so
  hotlinkers see one round of shape changes, not two.

The rename in R12 needs no special code: the regions script deletes and rewrites its level
(`rm -rf $GEOJSON/*`), and the provdists script makes one file per adm2 row, so `1909900000` is
simply not regenerated and `1999900000` is. Deleting through the scripts' own `rm -rf` is the
existing behaviour, limited to the `2023/` level directories; nothing else is deleted.

**What a regeneration changes, measured before design** (release CSVs vs. the published lowres
GeoJSON, 2026-10-25): file names identical at every level except R12's one; membership changes in
1 `regions/` file (`1900000000`: interim province code), 14 `provdists/` files (16 cities added),
the renamed BARMM file (8 added), and Manila's `municities/` file (empty → 899). Properties
already match the release's columns; adm4 gains `geom_src`. No names carry trailing spaces on
either side. Whether geometry bytes change elsewhere isn't known until the run, which is R14.

**Acceptance checks** go in `work/012-build-from-psgc-releases/checks.md`: R1, R9 (a Python or
`jq` pass over all `2023/*/lowres/*.json`), R10, R11, R12 and R13. They are acceptance, not suite
tests: only a revert breaks them. R9's check is also the obvious `commands.scan` for later; making
it one is a separate change.

## Contracts touched

- **Paths are public API.** This change removes one published name (×6:
  `municities-provdist-1909900000.*`) and adds one (`…-1999900000.*`). The invariant isn't changed:
  it says a rename is breaking, and this is recorded as breaking — `impact: major` at ship, a
  README note — rather than hidden. The removed file is empty today, so no hotlink loses data.
  Every other name is untouched (R13).
- **The PSGC hierarchy holds.** The purpose of the change; R9 checks it over every 2023 file, which
  nothing did before.
- **Old vintages are frozen.** `2011/` and `2019/` aren't regenerated or edited, and no script
  writes outside `$ROOT/2023` (R13).
- **Output location and form.** Output goes to `$ROOT/2023` from any working directory (R7), in
  WGS84 at the same three resolutions (R8); input lives only in the ignored `scripts/processed/`,
  never committed (R2, R5).

## Alternatives rejected

- **`releases/latest/download/`.** It moves when a quarter is published, so `2023/` would silently
  become 3Q 2026. A pinned tag per vintage.
- **Symlinking `release-staging/`.** It is the shapefiles repo's scratch area, may be replaced or
  deleted, and exists on this Mac only. Copy, verify, fall back to the release.
- **Download only, ignoring the local copy.** Works everywhere, but re-downloads ~1 GB that is
  already on disk; the copy is checked against the same `SHA256SUMS`, so it buys nothing in trust.
- **Keeping `municities-provdist-1909900000` as an alias.** It is empty today; an alias would serve
  either nothing or a duplicate under a wrong code. Deleted, with a README note.
- **Keeping shapeless rows with `geometry: null`.** Breaks some renderers and draws nothing; the
  barangays under those sub-municipalities carry the shapes.
- **Adding `2026/` (3Q 2026, `v1.0.0`) here.** Its own Tier 2 change, which this one reduces to
  setting `TAG`/`QUARTER`/`YEAR` and reviewing the output.
- **Shrinking the history** (the ~20 MB of shapefiles and ~590 MB of old JSON in it). A rewrite
  breaks every clone and fork; not this change.

## Verification

- **Gate:** `commands.check` passes (every 2023 file parses; nothing under `scripts/2023`).
- **Fetch:** `scripts/fetch-shapefiles.sh psgc-2023-4q 2023-4q` reports the staging copy and
  `OK` for four zips; a second run copies nothing; with `PSGC_STAGING=/nonexistent` and an empty
  `scripts/processed/2023-4q/` it downloads from the release and verifies; a corrupted zip is
  deleted and the script exits 1.
- **Generation:** the four scripts, run from `scripts/` and from the root, end with output only
  under `2023/`.
- **`checks.md`:** R1, R9–R13 sections each exit 0.
- **Diff review:** `git diff --stat master -- 2023 | tail -1`, and the list of changed files outside
  the parents R10–R12 name, explained in `notes.md` (R14).
