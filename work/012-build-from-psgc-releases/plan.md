---
id: 012
slug: build-from-psgc-releases
kind: plan
created: 2026-10-25
updated: 2026-10-25
---

# 012 — Build from the faeldon/philippines-psgc-shapefiles releases · plan

> Produced by Claude Code plan mode on 2026-10-25 after reading the scripts, the release zips
> and the tooling on this machine; approved and saved here.

## Context

Change 012 (Tier 2, spec approved: `work/012-build-from-psgc-releases/spec.md`, R1–R15). The
source shapefiles moved to `faeldon/philippines-psgc-shapefiles`, which publishes them only as
GitHub release assets in a new zip layout (one `PH_AdmN_*.shp` layer per zip, EPSG:32651). The
four scripts in `scripts/` can't read it, still expect zips copied by hand, and write to
`scripts/2023/...` when run from `scripts/`. Regenerating `2023/` from release `psgc-2023-4q`
also fixes the hierarchy: 24 municipalities missing from `provdists/`, Manila's empty barangay
file, and the BARMM interim province's code (`1909900000` → `1999900000`).

Facts checked while planning:
- The `psgc-2023-4q` zips each hold exactly `PH_AdmN_*.{cpg,dbf,prj,shp,shx}`; `SHA256SUMS`
  lists all 10 assets (5 zips, 5 CSVs); the release URL resolves (302 → 200).
- **`ogr2ogr` and `mapshaper` are not installed** on this machine (`brew` gdal 3.13.3 and npm
  mapshaper 0.7.98 are available). `jq`, `curl`, `unzip` and `shasum` (6.02, has
  `--ignore-missing`) are.

## Files to change

- `scripts/fetch-shapefiles.sh` (new): fetch + verify, the only place that knows the source.
- `scripts/topojson-country.sh`, `topojson-regions.sh`, `topojson-provdists.sh`,
  `topojson-municities.sh`: shared header, new layer names, root-relative paths, temp CSVs out of
  the cwd, `unzip -o`; municities filter drops `geom_src = 'none'`.
- `2023/geojson/**`, `2023/topojson/**`: regenerated. `municities-provdist-1909900000.*` (6)
  removed, `…-1999900000.*` (6) added.
- `README.md`: Source Files, Using the Scripts, a note on the BARMM rename.
- `AGENTS.md`: source link, regeneration instructions (no manual copy, fetch step).
- `.sdlc/SDLC.md`: the worktree paragraph's source link and copy instruction.
- `work/012-build-from-psgc-releases/checks.md` (new): acceptance checks R1, R9–R13.
- `work/012-build-from-psgc-releases/notes.md` (new): R14's accounting of other changed files.
- `work/012-build-from-psgc-releases/spec.md`: R2 also names the three CSVs (see step 2).

## Work order

0. **Install the tools (needs your OK: system-wide installs).** `brew install gdal` and
   `npm install -g mapshaper`, as the README already says. Confirm `ogr2ogr --version` and
   `mapshaper -v`.
1. **Fetch script.** `scripts/fetch-shapefiles.sh TAG QUARTER`, `set -euo pipefail`:
   - `ROOT=$(cd "$(dirname "$0")/.." && pwd)`, `DEST=$ROOT/scripts/processed/$QUARTER`
     (already ignored by `scripts/processed/`).
   - `FILES`: the four zips the scripts read, plus `PH_Adm2/3/4_*.csv` (small; R9's check reads
     them), and `SHA256SUMS`.
   - Already done? All present and `(cd "$DEST" && shasum -a 256 -c --ignore-missing --quiet
     SHA256SUMS)` passes → print "verified, nothing fetched", exit 0.
   - Staging: `PSGC_STAGING` or `$(dirname "$(git -C "$ROOT" rev-parse --path-format=absolute
     --git-common-dir)")/../philippines-psgc-shapefiles/release-staging/$QUARTER`. Used only if
     `jq -r .publication meta.json` = `$QUARTER` and its own `shasum -c --ignore-missing` passes;
     then `cp` each file (never `ln`), print "copied from staging".
   - Else `curl -fsSL -o` each file from
     `https://github.com/faeldon/philippines-psgc-shapefiles/releases/download/$TAG/<file>`,
     print "downloaded from release $TAG".
   - Verify in `DEST`; on any `FAILED`, delete the listed files and exit 1.
   - Test it here before going on (see Tests, R2–R5).
2. **Spec R2 wording.** Edit R2 to say "four zips, the adm2–adm4 CSVs and `SHA256SUMS`" in the
   same commit: the build adds the CSVs so R9's membership check can run offline.
3. **Generation scripts.** For each of the four, replace the header with:
   ```bash
   set -euo pipefail
   ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   YEAR=2023 TAG=psgc-2023-4q QUARTER=2023-4q
   "$ROOT/scripts/fetch-shapefiles.sh" "$TAG" "$QUARTER"
   SHAPEFILE="$ROOT/scripts/processed/$QUARTER"
   GEOJSON="$ROOT/$YEAR/geojson/<level>"; TOPOJSON="$ROOT/$YEAR/topojson/<level>"
   ```
   then: `unzip -o -q`, and each script also unzips the parent layer it lists codes from (built:
   it used to rely on the previous script having unzipped it); every `PH_AdmN_X.shp.shp` →
   `PH_AdmN_X.shp`; the parent-list CSV
   (`regions_raw.csv` etc.) written to `$SHAPEFILE/` not the cwd; in the municities script,
   `-where "adm3_psgc=$f AND geom_src <> 'none'"`. Everything else (the loop, `-t_srs
   EPSG:4326`, the six `mapshaper` calls, the per-level `rm -rf "$GEOJSON"/*`) unchanged. Quote
   the `rm -rf` targets so an empty variable can't widen it (with `set -u` it already fails).
   (Built: every `-simplify` also gained `keep-shapes`, after the first full run left small
   polygons as `geometry: null` at medres and lowres, as `master` already had. See spec Design.)
4. **Regenerate**, in order, once from `scripts/` and confirm nothing lands under `scripts/2023`:
   country, regions, provdists, municities (barangays take minutes). Then the gate.
5. **Docs.** README (Source Files: new repo + pinned release; Using the Scripts: install, run, no
   copy step, what the fetch does; a note that `municities-provdist-1909900000` moved to
   `…-1999900000`), `AGENTS.md`, `.sdlc/SDLC.md`. Then `git grep` for R1.
6. **`checks.md` and `notes.md`.** Write the acceptance checks; run them. Diff the regenerated
   tree against `master` and account for every changed file outside the parents R10–R12 name.
7. `stage: test` in the intent, then `/sdlc:ship`.

## Tests

No suite exists; the gate plus `checks.md` (rerun by ship) and the manual checks below.

- **R1** (checks.md): `! git grep -q 'altcoder/philippines-psgc-shapefiles' -- ':!2011' ':!2019'
  ':!work'` (built: `work/` excluded, since this change's own records name the old repo; spec R1
  amended to match).
- **R2–R5** (manual, recorded in notes.md): (a) run fetch: "copied from staging", 4 zips + 3
  CSVs OK; (b) run again: "nothing fetched"; (c) empty `DEST`, `PSGC_STAGING=/nonexistent`:
  "downloaded from release psgc-2023-4q", OK; (d) append a byte to one zip: exit 1, file
  deleted; (e) `find ../philippines-psgc-shapefiles/release-staging -newer <marker>` is empty
  (nothing written there).
- **R6–R8**: the full run succeeds with no prompt; `git status --short scripts/` is clean apart
  from the script edits; a `jq` pass asserts every lowres coordinate is within lon 114–128,
  lat 4–22 (checks.md); file-name pattern covered by R13.
- **R9** (checks.md): Python over `2023/geojson/{regions,provdists,municities}/lowres/*.json`:
  each feature's parent property equals the file's code, and the ids equal the CSV's children
  with a shape (`scripts/processed/2023-4q/*.csv`, `geom_src <> none` at adm4). Fails, naming the
  missing CSVs, if they haven't been fetched.
- **R10, R11** (checks.md): `jq` asserts the 16 city ids and `1999901000`–`1999908000` are present
  where the spec says; Manila's file has 899 features and none of `1380601000`–`1380614000`; no
  feature anywhere has `geometry: null`.
- **R12, R13** (checks.md): the 6 `1909900000` files are gone and 6 `1999900000` files exist;
  `git diff --name-status master -- 2023 | grep -v '^M'` lists exactly those 12;
  `git diff --quiet master -- 2011 2019`.
- **R14**: notes.md lists changed-file counts per level/format/resolution, the changes inside the
  named parents, and the cause of any other change, with a `- [ ]` for anything unexplained.
- **R15**: read at review.
- **Gate**: `commands.check` passes.

## Rollback

`git revert <sha>` restores the scripts, docs and every 2023 file, including the
`1909900000` names. Not covered:
- Once pushed to `master`, hotlinkers have already seen the new files; a revert is a new push.
- `scripts/processed/2023-4q/` (~1 GB, ignored): `rm -rf scripts/processed/2023-4q`.
- The tools installed in step 0: `brew uninstall gdal`, `npm uninstall -g mapshaper`.
