# Notes

> What happened while this change was built that its intent, spec and plan don't say. Free-form,
> with one rule: anything left undone is an unticked `- [ ]` line. `/sdlc:ship` gives each one a
> disposition, carried to a `work/ideas.md` seed or dropped with a reason, and `sdlc.py ship`
> refuses while one is still unticked.

## The build

`scripts/build-quarter.sh v1.0.0 2026-3q` ran on 2026-10-25 from 19:20 to about 19:50 and exited 0.
The shapefiles were copied from staging, and all of them verified. Municities took about 25 of the
30 minutes, so the user suggested running it in parallel, now the seed "Build the municities
level in parallel" in `work/ideas.md`. `git status --ignored` shows `2026-3q/` as ignored, with
nothing tracked under it.

Hires was checked once here, because checks.md only covers what `latest/` holds: no
`2026-3q/geojson/*/hires` feature has a null geometry.

## Deviations from the plan

- **`fetch-shapefiles.sh` also fetches `PH_Adm1_Regions.csv`.** `publish-latest.sh` counts the
  regions from it, and 012's fetch took only the adm2–4 CSVs. The first publish refused, as it
  should have, but said "the release has -1". `rows()` now fails outright when a CSV is missing.
- **`build-quarter.sh` writes `<quarter>/build.json`** (tag, quarter, source, date).
  `publish-latest.sh` reads it, so it takes only `QUARTER`, as the spec says, and still knows the
  source release for the manifest.
- **The legacy zips cover every file, not only `<fmt>/<level>/<res>/`.** 2011 has 1,647
  unsimplified GeoJSON files with no resolution directory, which go in `geojson-full.zip`, and
  `2011/images/`, which goes in `extras.zip`.
- **`release-legacy.sh` pushes its tag before creating the release.** `2023-4q`'s ref,
  `195f6db2`, is not on GitHub, and a release needs its commit there. So the script pushes
  `refs/tags/<tag>` only, which carries 012's commits to GitHub without moving `master`. Plan
  step 15 asks for its own approval.

## Dry runs (plan step 12)

| Release | Ref | Files | Matches `git ls-tree` | `SHA256SUMS` |
|---|---|---|---|---|
| `2011` | `1d02f67d` | 12,173 | yes | verify |
| `2019` | `685d702b` | 10,524 | yes | verify |
| `2023-4q` | `195f6db2` | 10,488 | yes | verify |
| `v1.0.0` | `2026-3q/` build | 6 zips, 124 MB | `diff -r` with `2026-3q/` (minus `build.json`): identical | verify |

The legacy rows are `release-legacy.sh --dry-run`. The `v1.0.0` row is `release-assets.sh v1.0.0`;
its notes list 0/1 regions, 4/4 provdists and 82/82 municities removed/added. Nothing was tagged,
pushed or uploaded, and `dist/` was deleted afterwards.

## Size

`latest/` is 120 MB on disk: 6,996 JSON files plus `manifest.json`. That's
4 × (1 + 18 + 88 + 1,642).

## After ship

Plan steps 14–18 run after the commit, each behind its own approval:
- keep the build through close;
- the legacy releases;
- the `v0.0.0` baseline;
- `/sdlc:release` 1.0.0;
- `/sdlc:publish`;
- the post-publish checks.

They are the release, not unfinished build work, so they aren't `- [ ]` items here.
