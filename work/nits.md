# Nits

> Small technical debt: findings ship approved unfixed, kept until a change fixes them or makes
> them moot. Each one is a `## NNN-n [theme] <title>` heading (the raising change's number and a
> count), then `- **raised:** YYYY-MM-DD by NNN-slug (pass)`, `- **paths:** a, b` and
> `- **cost:** S|M  **value:** med|low` lines, then a line or two on what's wrong. The process
> doc's rubric says what each cost and value means. `/sdlc:intent` and `/sdlc:spec` offer the ones
> a change touches, `/sdlc:ship` adds and retires entries, and `/sdlc:retro` counts them by theme
> and age; history keeps a retired one.

## 012-1 [docs] README states the output projection as EPSG:32651
- **raised:** 2026-10-25 by 012-build-from-psgc-releases (correctness)
- **paths:** README.md
- **cost:** S  **value:** med

`README.md` says "Maps are using EPSG:32651, Lat/Long projection." The published files are WGS84
lon/lat (EPSG:4326); EPSG:32651 is the source shapefiles' UTM projection.

## 012-2 [robustness] fetch-shapefiles.sh prints a git "fatal" outside a checkout
- **raised:** 2026-10-25 by 012-build-from-psgc-releases (correctness)
- **paths:** scripts/fetch-shapefiles.sh
- **cost:** S  **value:** low

Run from a downloaded ZIP (no `.git`), `git rev-parse` prints `fatal: not a git repository` and
the staging path resolves relative to the cwd; the release download still runs.

## 012-3 [robustness] Staging SHA256SUMS isn't checked against meta.json's sha256sums
- **raised:** 2026-10-25 by 012-build-from-psgc-releases (correctness)
- **paths:** scripts/fetch-shapefiles.sh
- **cost:** S  **value:** low

A staging copy is verified against its own `SHA256SUMS`; `meta.json` records that file's hash
(`sha256sums`), which would anchor it to the release.
