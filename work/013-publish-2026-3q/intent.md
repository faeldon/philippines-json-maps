---
id: 013
slug: publish-2026-3q
tier: 2
impact: major
stage: shipped
created: 2026-10-25
updated: 2026-10-25
shipped: 2026-10-25
idea:
depends_on:
serves: [O1, O2, O3]
---

# 013 — Publish PSGC 3Q 2026 as v1.0.0, with latest/ in the tree and every quarter as a release

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

The newest maps in this repo are `2023/`, PSGC 4Q 2023: almost three years and 11 PSA quarterly
updates behind. The source repo has published 3Q 2026 as release `v1.0.0` (marked Latest), and it
differs from what users get here in ways a map shows:

- **New region:** the Negros Island Region (`1800000000`) exists, so there are 18 regions, not 17.
- **Transfers:** Negros Occidental, Negros Oriental and Siquijor moved to it, and Sulu moved to
  Region IX. Their codes changed, e.g. `604500000`→`1804500000` and `1906600000`→`906600000`.
  That's 82 municipalities and ~1,770 barangays under new codes.
- **New BARMM municipalities:** the eight created in May 2024.
- **Other updates:** barangays created, merged and split, and dozens of names corrected.

Anyone drawing a current map of Negros, Siquijor, Sulu or BARMM from this repo today gets the
wrong region, the wrong codes, or missing areas.

Change 012 made the scripts fetch a pinned release. So a new vintage is now a header change plus a
run, but nothing has picked up the latest quarter.

## Outcome

- The scripts build any quarter into a local `<year>-<quarter>/` directory (`2026-3q/` from
  release `v1.0.0`), in the same layout as `2023/`; these build directories are not committed:
  - the same levels (`country/`, `regions/`, `provdists/`, `municities/`) and resolutions, in
    GeoJSON and TopoJSON;
  - the same file-name pattern;
  - 18 region files, one per region in the release, and one file per province/district and per
    municipality/city.
- Every child file holds exactly its parent's children with a shape, the hierarchy check R9 ran
  for 2023. No feature has a null geometry.
- The repo publishes **one** distribution in its tree, the most recent quarter (3Q 2026), at a
  path the spec settles. Every quarter is published as a GitHub release of this repo instead,
  with its built files as assets and a `SHA256SUMS`, the way the shapefiles repo publishes its
  input, so an older quarter stays downloadable without living in the tree.
- The gate covers `2026-3q/` too. Today it checks only `2023/`.
- **Moves O1:** the gap between PSA's latest PSGC and the newest vintage here drops from
  ~33 months to ~1.
- **Moves O2:** the Negros Island Region and Sulu's transfer are filed under their correct parents,
  and checked file by file.
- **Moves O3:** the README and its demo link point at the one published distribution, and at the
  releases for any other quarter, so a new user starts on current boundaries and a pinned user
  has a fixed URL per quarter.

## Affected

- **Area:** a new published vintage, the generation scripts, the gate, and the docs that say which
  vintage is current.
- **Files & components:**
  - `2026-3q/**` (new, ~10,500 files).
  - `scripts/topojson-*.sh`: the vintage header. Today it's hard-coded `YEAR=2023`, so building
    two vintages means taking it as input.
  - `.sdlc/config.toml` `commands.check`.
  - `README.md`: the directory tree, the demo link, Source Files, Previous Maps.
  - `AGENTS.md`: the invariant on vintage names, and the commands.
- **Downstream:** everyone who hotlinks `raw.githubusercontent.com/.../master/<vintage>/...`. The
  new paths become public API the day `master` is pushed.
- **Contracts:**
  - **Paths are public API / old vintages frozen:** both change on purpose. Publishing one
    distribution means `2023/` (and possibly `2011/` and `2019/`) leaves the tree or is replaced,
    which breaks every hotlink to it; the invariants are rewritten in `AGENTS.md` to say what is
    stable instead (the published path, and each release's assets).
  - **PSGC hierarchy.**
  - **Output location and form.**
  - The vintage-naming wording in `AGENTS.md` changes on purpose: from `<year>/` to `<year>/` for
    vintages up to 2023, and `<year>-<quarter>/` from now on.

## Constraints

- **Not committed:** build directories and release assets never are; only the one published
  distribution is.
- **Same layout:** `2026-3q/` uses `2023/`'s naming. Codes are written as integers, and the levels,
  resolutions and suffixes are unchanged.
- **Pinned:** build from tag `v1.0.0`, never `releases/latest`.
- **The fetch rules from 012 still hold:** copy from `release-staging/2026-3q/` or download, never
  link, and verify against `SHA256SUMS`.
- **Same simplification:** `keep-shapes` stays on every `-simplify`.

## Open questions

- ~~Barangays: the standard `PH_Adm4_BgySubMuns` (18 shapeless rows left out) or
  `PH_Adm4_BgySubMuns_complete` (approximates the 4 new barangays)? Whichever is used, the README
  should say what an approximated barangay is.~~ Resolved: the standard file (spec R12); `_complete` would replace 4 surveyed barangays with approximations.
- ~~Should a barangay carry `geom_src` values other than `source`, such as `dissolved`, `plotted` or
  `approximated`, and does the README need to explain them?~~ Resolved: `geom_src` is kept, and the README explains `plotted` and `dissolved` (R12).
- ~~How do the scripts take the vintage: arguments, an environment variable, or one header per
  vintage? Re-running `2023/` must still produce what 012 shipped.~~ Resolved: two positional arguments, `TAG QUARTER` (R1); 4Q 2023 rebuilds with `psgc-2023-4q 2023-4q`.
- ~~Does the gate's `scripts/2023` check need to cover any `scripts/<vintage>` output? Since 012,
  the scripts write to the root, so maybe it's moot.~~ Resolved: the gate fails on anything tracked under build directories, `dist/` or `scripts/20*` (R13).
- ~~The README's demo link and tree point at `2023/`. Should `2023/` move under "Previous Maps" now?~~ Resolved: `2023/` leaves the tree for release `2023-4q`; the README points at `latest/` and the releases (R7, R14).
- ~~Does `2026-3q/` need a note on its code changes (Negros, Sulu)? Someone moving a link from
  `2023/` will find, e.g., `municities-provdist-604500000` gone and `…-1804500000` in its place.~~ Resolved: yes, the v1.0.0 notes list every renamed path, generated by script (R11).
- ~~Repo size: another ~10,500 files adds to a `.git` already at 617 MB. Is that acceptable, or does
  it raise the history question from 012?~~ Resolved: only `latest/` medres+lowres is committed, ~23 MB per quarter; the clone keeps its history, no rewrite (Design, What it costs).
- ~~Where does the published distribution live? Options: a stable name (e.g. `latest/`) that never
  moves; the newest quarter's own name (`2026-3q/`, which moves every quarter); or overwriting
  `2023/` in place.~~ Resolved: `latest/` (R5).
- ~~What happens to `2023/`, `2019/` and `2011/`? Keep them in the tree, move them to releases
  (`2023-4q`, …) and remove them, or keep `2023/` until a stated date. Every hotlink to them breaks
  if they go.~~ Resolved: all three move to releases `2023-4q`, `2019`, `2011` before the push, then leave the tree (R7, R10).
- ~~How much history should a new quarter cost? A full rewrite of the published files each quarter
  adds about 80 MB packed. Should the tree hold only lowres/medres or TopoJSON, with everything else
  in releases, or is the history cost accepted?~~ Resolved: the tree holds medres and lowres only; hires is in each release (R5, R8).
- ~~How are releases made: `/sdlc:publish` through `release.publish` (`gh release create` with the
  zipped vintage and `SHA256SUMS`), versioned how, and tagged per quarter like the source repo's
  `psgc-2023-4q` and `v1.0.0`?~~ Resolved: `/sdlc:release` and `/sdlc:publish` through `release.prepare`/`publish`, semver tagged `v{version}`, v1.0.0 = 3Q 2026; legacy releases are one-off tags (R8–R10).
- ~~Does 012's still-unpushed `2023/` regeneration get published at all, or does it ship only as the
  `2023-4q` release?~~ Resolved: it is pushed as is, accepting ~111 MB of history, and is also the `2023-4q` release, from `195f6db2` (R7).
