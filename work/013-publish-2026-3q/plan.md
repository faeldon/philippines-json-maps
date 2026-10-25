---
id: 013
slug: publish-2026-3q
kind: plan
created: 2026-10-25
updated: 2026-10-25
---

# 013 — Publish PSGC 3Q 2026 as v1.0.0, with latest/ in the tree and every quarter as a release · plan

## Context

Change 013 (Tier 2, spec approved: `work/013-publish-2026-3q/spec.md`, R1–R15). The maps here are
PSGC 4Q 2023; the source repo has 3Q 2026 as release `v1.0.0`. Committing every quarter as its
own directory costs about 111 MB of history each time, so the tree will hold one distribution,
`latest/` (medres + lowres). Every quarter, including the old `2011/`, `2019/` and `2023/`, ships
as a GitHub release of this repo with all resolutions. v1.0.0 of this repo is 3Q 2026, cut through
`/sdlc:release` and `/sdlc:publish`.

Facts checked while planning:
- The four scripts share one header (`YEAR=2023 TAG=psgc-2023-4q QUARTER=2023-4q`) and write
  `$ROOT/$YEAR/{geojson,topojson}/<level>/{hires,medres,lowres}`. Nothing else in them names a
  vintage.
- The release CSVs have 18 adm1 rows, 88 adm2 rows and 1,642 adm3 rows, which gives R3's counts.
  Staging `2026-3q/meta.json` has `publication: 2026-3q`. `ogr2ogr`, `mapshaper`, `zip` and `gh`
  are installed.
- **sdlc release:**
  - `VERSION_RE` reads `"version": "X"` from a JSON file.
  - `unreleased` counts the `Close` commits since the tag of the current version.
  - Below 1.0, a `major` proposes 0.1.0, so 1.0.0 is chosen with "release as another version".
  - `prepare` and `publish` run non-interactively, and `prepare` must change no tracked file.
- **Legacy refs:**

  | Release | Directory | Ref | On origin? |
  |---|---|---|---|
  | `2019` | `2019/` | `685d702b` | yes |
  | `2011` | `2011/` | `1d02f67d` | yes |
  | `2023-4q` | `2023/` | `195f6db2` (change 012) | **no**, master is unpushed |

  A GitHub release can only be created on a commit GitHub has. So `2023-4q`'s tag has to be pushed
  first, and that tag push carries 012's commits, but not `master`.
- **2011's layout is irregular:**
  - Its levels are `barangays`, `municties`, `provinces`, `regions` and `country`.
  - 1,647 unsimplified GeoJSON files sit directly under `geojson/barangays/` and the other level
    directories, with no resolution directory.
  - `2011/images/` has 3 PNGs.

  The legacy zips must cover every file, not only `<fmt>/*/<res>/`.
- **`git worktree remove`** deletes ignored files. The full `2026-3q/` build, which is ignored and
  holds hires, would be lost at close, and `release.prepare` needs it later from the main
  checkout.

## Files to change

- `scripts/topojson-{country,regions,provdists,municities}.sh`: take `TAG QUARTER` as arguments
  and write to `$ROOT/$QUARTER/...`.
- New scripts in `scripts/`:
  - `build-quarter.sh`
  - `publish-latest.sh`
  - `renamed-paths.sh`
  - `release-assets.sh`
  - `release-publish.sh`
  - `release-legacy.sh`
- `.gitignore`: add `/[0-9][0-9][0-9][0-9]-[1-4]q/` and `/dist/`.
- `latest/**`: new, about 7,000 files, plus `latest/manifest.json`.
- `2011/**`, `2019/**`, `2023/**`: deleted.
- `.sdlc/config.toml`: `commands.check`, and a new `[release]` section.
- `README.md`, `AGENTS.md`, and `.sdlc/SDLC.md` where it names `2023/`.
- `work/013-publish-2026-3q/checks.md` (new), `notes.md` (new), and `intent.md` (stage).

## Work order

### Build (this worktree)

1. **Script arguments (R1).** Replace each script's header line with:
   ```bash
   [ $# -eq 2 ] && [[ $2 =~ ^[0-9]{4}-[1-4]q$ ]] || {
     echo "usage: $(basename "$0") TAG QUARTER   (e.g. v1.0.0 2026-3q)" >&2; exit 2; }
   TAG=$1 QUARTER=$2
   ```
   - `GEOJSON` and `TOPOJSON` become `$ROOT/$QUARTER/...`.
   - The quarter pattern guarantees the output path matches the ignore rule. It also keeps
     `rm -rf "$GEOJSON"/*` inside a build directory.
   - Nothing else in the scripts changes.
2. **`.gitignore` (R2):** add the two lines.
3. **`scripts/build-quarter.sh TAG QUARTER`:**
   - Uses the same usage guard.
   - Runs the four scripts in order.
   - Then writes `$QUARTER/build.json` with `tag`, `quarter`, `source` and `built`, the date in UTC.
4. **Build:** `scripts/build-quarter.sh v1.0.0 2026-3q`, run in the background. Municities takes
   the longest.
   - Then `git status --short` should show nothing under `2026-3q/`.
   - Then check that the hires files have no `geometry: null`. checks.md covers medres and lowres
     through `latest/`; this hires check runs once and is recorded in notes.md.
5. **`scripts/publish-latest.sh QUARTER` (R5, R6):**
   - Reads `$QUARTER/build.json`.
   - Refuses unless every format × medres/lowres × level has the file count the CSVs in
     `scripts/processed/$QUARTER/` give: 1 country, plus one per adm1, adm2 and adm3.
   - Then runs `rm -rf latest/geojson latest/topojson`.
   - Copies `$QUARTER/<fmt>/<level>/{medres,lowres}` into the same layout under `latest/`.
   - Writes `latest/manifest.json` with `jq`:
     ```json
     {
       "version": "0.0.0",
       "psgc": "2026-3q",
       "source": {"repo": "faeldon/philippines-psgc-shapefiles", "tag": "v1.0.0"},
       "built": "2026-10-25"
     }
     ```
     - `version` is kept from the existing manifest when there is one; otherwise it is `0.0.0`.
     - Only `/sdlc:release` changes `version`.
6. **Remove the old vintages (R7):** `git rm -r -q 2011 2019 2023`. Their content stays reachable at
   the refs above.
7. **`scripts/renamed-paths.sh OLD_REF OLD_DIR` (R11):**
   - Compares `git ls-tree -r --name-only OLD_REF -- OLD_DIR/geojson` (lowres) with
     `latest/geojson/*/lowres`, by level and name with the vintage prefix stripped.
   - Prints Markdown: per level, the files added and removed, with counts.
   - Reads history, so it still works once `2023/` is gone.
   - Run as `renamed-paths.sh 195f6db2 2023`. The expected counts are: regions +1, provdists
     −4/+4, municities −82/+82.
8. **Release scripts (R8, R10).**

   **`release-assets.sh TAG`** writes into `dist/$TAG/`:
   - Reads `latest/manifest.json` for the quarter, and builds from `${BUILD_ROOT:-$ROOT}/$quarter`.
   - Refuses if the build directory is missing, or if `diff -rq` finds a difference between it and
     `latest/` for medres/lowres.
   - Runs `zip -q -r -X` once per format × resolution (`geojson-hires.zip` … `topojson-lowres.zip`).
     The paths inside each zip stay `<fmt>/<level>/<res>/…`.
   - Writes `SHA256SUMS`.
   - Writes `notes.md`: the PSGC quarter, the source release link, the assets, and the
     `renamed-paths.sh 195f6db2 2023` output.
   - Changes no tracked file.

   **`release-publish.sh TAG`:**
   - Refuses if `gh release view "$TAG"` succeeds.
   - Otherwise runs `gh release create "$TAG" dist/$TAG/*.zip dist/$TAG/SHA256SUMS --verify-tag`,
     with `--title "$TAG: PSGC <quarter>" --notes-file dist/$TAG/notes.md`.

   **`release-legacy.sh [--dry-run] TAG DIR REF`:**
   - Unpacks `git archive REF -- DIR` into `dist/$TAG/src`.
   - Builds one zip per format × resolution. Files with no resolution directory, i.e. 2011's
     unsimplified GeoJSON, go in `<fmt>-full.zip`. Anything outside `geojson/` and `topojson/`
     goes in `extras.zip`, which holds 2011's images.
   - Writes `SHA256SUMS` and notes ("PSGC vintage DIR, as `master` held it at REF; moved out of
     the tree in v1.0.0").
   - Verifies that the zips together list exactly the archive's files.
   - Without `--dry-run`, it also:
     - refuses an existing release;
     - runs `git tag -a TAG REF` and `git push origin refs/tags/TAG`, which pushes the tag only;
     - runs `gh release create TAG … --verify-tag --latest=false`.
9. **Gate and config (R9, R13).** Set `.sdlc/config.toml` to:
   ```toml
   check = "find latest -name '*.json' -print0 | xargs -0 -n 500 jq empty && test -z \"$(git ls-files --cached --others --exclude-standard -- ':(glob)[0-9][0-9][0-9][0-9]-[1-4]q/**' dist 'scripts/20*' ':(glob)**/hires/**')\""
   [release]
   version_files = ["latest/manifest.json"]
   tag = "v{version}"
   prepare = "scripts/release-assets.sh {tag}"
   publish = "scripts/release-publish.sh {tag}"
   ```
   Each key gets a comment saying why.
10. **Docs:**
    - **README (R12, R14):** demo link and tree on `latest/`; medres/lowres in the tree, hires in
      releases; links to the releases; "Previous Maps" becomes the release list; "Source Files"
      covers v1.0.0 and 3Q 2026; the projection line becomes "WGS84 longitude/latitude
      (EPSG:4326), reprojected from the source's EPSG:32651" (nit 012-1); `geom_src` gets a short
      explanation of `plotted` and `dissolved`; "Using the Scripts" uses
      `build-quarter.sh v1.0.0 2026-3q`. The BARMM note is replaced by the Negros/Sulu rename note,
      pointing to the v1.0.0 release notes.
    - **`AGENTS.md` (R15):** the gate command, regeneration, a `latest/` and release paragraph, and
      the invariants exactly as spec "Contracts touched" words them.
    - **Leftover references:** `git grep -n '2023/' -- ':!work'` and fix what is left in `.sdlc/`.
11. **`checks.md`**, in 012's format, one `sh` block per section:
    - **R1:** each script exits non-zero with `usage:` on stderr, both with no arguments and with
      `2026Q3`.
    - **R3:**
      - `latest/` counts per fmt × res: country 1, regions 18, provdists 88, municities 1,642.
      - WGS84 bounds on lowres.
      - No `geometry: null` in medres or lowres.
    - **R4:** 012's hierarchy script run on `latest/geojson/*/lowres`, against
      `scripts/processed/2026-3q/*.csv`. It fails, naming the fetch command, when the CSVs are
      missing.
    - **R5, R7:**
      - `git ls-files -- '*/hires/*'` is empty.
      - Nothing is tracked under `2011/`, `2019/` or `2023/`.
      - `latest/` contains only `geojson/`, `topojson/` and `manifest.json`.
    - **R6:** `jq -e` on the manifest's fields, with `psgc == "2026-3q"` and
      `source.tag == "v1.0.0"`.
    - **R11:** `renamed-paths.sh 195f6db2 2023` gives counts 1, 4/4 and 82/82.
    - **R13:** the gate text no longer names `2023`.
12. **Dry runs (Verification):**
    - `scripts/release-assets.sh v1.0.0`: `SHA256SUMS` verifies, and unzipping all the zips gives
      a tree that `diff -r` finds identical to `2026-3q/` (minus `build.json`).
    - `release-legacy.sh --dry-run` for each of the three refs. Its own check, that the zips list
      exactly the archive's files, passes.
    - Delete `dist/` afterwards. Results are recorded in notes.md.
13. `stage: test`, then **`/sdlc:ship`** (impact: major; retires nit 012-1).

### After ship: each step needs its own approval

14. **Keep the build through close:** move `2026-3q/` and `scripts/processed/2026-3q/` from the
    worktree to the scratchpad `hold/` (same volume, a rename). Then **`/sdlc:close 013`**. Then
    move both into the main checkout. There they are ignored, because `.gitignore` arrived with the
    fast-forward.
15. **Legacy releases (one approval):**
    - Runs `release-legacy.sh` for `2023-4q 2023 195f6db2`, `2019 2019 685d702b…` and
      `2011 2011 1d02f67d…`.
    - This **pushes three tags**: `2023-4q` carries 012's commits to GitHub, not `master`.
    - It creates three public releases.
16. **Baseline tag:** `git tag -a v0.0.0 -m v0.0.0 41ba8941`, on the master tip before 013. It is
    local only. `unreleased` then lists 013 alone.
17. **`/sdlc:release`:** choose "release as another version", 1.0.0. That sets the manifest version
    to 1.0.0, then commits "Release 1.0.0", tags `v1.0.0` and runs `prepare`, which builds
    `dist/v1.0.0/` in the main checkout.
18. **`/sdlc:publish`:** pushes `master` and `v1.0.0`, then runs `release-publish.sh v1.0.0`.

## Tests

The gate plus `checks.md` (rerun by ship), the step 4 and 12 checks recorded in notes.md, and
after publish (manual, in notes.md):
- `gh release view` for each of the four releases lists its assets.
- `curl -L` of one asset per release matches its `SHA256SUMS`.
- `raw.githubusercontent.com/.../master/latest/manifest.json` serves version 1.0.0.

## Rollback

- **Before publish:** `git revert` the change commit. That restores `2011/`, `2019/` and `2023/`,
  the scripts and the docs. A local `v0.0.0`/`v1.0.0` is undone with
  `git tag -d v1.0.0 && git reset --keep HEAD~1`.
- **After push:** a revert is a new push, and hotlinkers will already have seen the removed
  directories.
- **Releases:** `gh release delete <tag> --cleanup-tag` removes a release. But a published asset
  may already be downloaded or pinned, and the invariant says releases are never replaced, so
  rollback there means a new release, not an edit.
- **Local:** `rm -rf 2026-3q dist scripts/processed/2026-3q` (all ignored).
