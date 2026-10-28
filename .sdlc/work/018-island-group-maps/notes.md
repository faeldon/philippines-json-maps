# Notes

> What happened while this change was built that its intent, spec and plan don't say. Free-form,
> with one rule: anything left undone is an unticked `- [ ]` line. `/sdlc:ship` gives each one a
> disposition, carried to a `.sdlc/work/inbox.md` seed or dropped with a reason, and `sdlc.py ship`
> refuses while one is still unticked.

## How it was built

The worktree got the 2026-3q build as an APFS clone of the main checkout's
(`cp -cR <main>/2026-3q ./2026-3q`, gitignored); `fetch-shapefiles.sh` found the staging copy in
`../philippines-psgc-shapefiles/release-staging/2026-3q` through git's common dir, as planned.
`scripts/topojson-islandgroups.sh v1.0.0 2026-3q` took 34 s and wrote six files (hires GeoJSON
50 MB, lowres TopoJSON 118 KB), then `publish-latest.sh 2026-3q` put the four medres/lowres in
`latest/`.

## Proofs that need a build directory (not in checks.md)

- **R2.** With the output moved aside, four broken copies of the mapping each exited 1 with the
  offending code named and created no `islandgroups/` directory: NIR row missing
  ("regions of 2026-3q with no island group: 1800000000"), NIR row twice ("mapped twice"),
  `1700000000,Palawan` ("not Luzon, Visayas or Mindanao"), and an extra `2000000000`
  ("mapped but not a region of 2026-3q"). The mapping was restored and compared with `cmp`.
- **R5.** The summed `area_km2` came out whole (Luzon 138851, Visayas 55160, Mindanao 100520;
  total 294531, the regions CSV's total), so the plan's optional rounding wasn't needed.
- **R8.** With `2026-3q/geojson/islandgroups` moved aside, `publish-latest.sh 2026-3q` printed
  `geojson/islandgroups/medres: 0 files, the release has 1` (and lowres) and refused; restored,
  it published.
- **R9.** `release-assets.sh v0.0.0-test` against the worktree build: all six zips hold their
  islandgroups file and `notes.md` has "Added paths since `v1.0.1`" listing the four `latest/`
  files. With `BUILD_ROOT` pointed at the main checkout (its `2026-3q/` has no island groups yet)
  it refused: `.../2026-3q/geojson/islandgroups/medres differs from latest/`. `dist/` removed.
- **R10.** After publishing, `git status` under `latest/` showed only the four new files, and
  `git diff --quiet -- latest/` passed: every tracked file, `manifest.json` included, unchanged.
- **R11.** `sample-maps.sh` rewrote the other three SVGs byte-identical; `islandgroups.svg` fills
  each group its own tint (one fill and stroke made it read as the country outline, since most
  borders between groups are sea), via an optional third argument to `render`.

## Found along the way

`publish-latest.sh` refused a build with a level directory missing *silently*: under `pipefail`,
`find` failing on the missing directory failed `have=$(...)`, and `set -e` exited before the
message. Fixed with `|| true` in that substitution, so the count is 0 and the level is named.

## Left to do

- [x] Before `/sdlc:release`, add the level to the main checkout's build: run
  `scripts/topojson-islandgroups.sh v1.0.0 2026-3q` there (after this change lands on `master`).
  `release-assets.sh` refuses until its output matches the committed `latest/`. → seed: 2026-10-28-2
