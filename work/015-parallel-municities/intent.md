---
id: 015
slug: parallel-municities
tier: 1
impact: none
stage: shipped
created: 2026-10-25
updated: 2026-10-25
shipped: 2026-10-25
idea: Build the municities level in parallel
depends_on:
serves: [O1]
---

# 015 — Build the municities level in parallel

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

Building a quarter takes about 30 minutes, and about 25 of them are
`scripts/topojson-municities.sh`. In change 013's 3Q 2026 build, the earlier levels were done by
19:25, and municities ran from then until about 19:50.

The script loops over the 1,642 municipalities and cities **one at a time**. For each, it runs one
`ogr2ogr` extract from `PH_Adm4_BgySubMuns.shp` and six `mapshaper` calls (GeoJSON and TopoJSON at
three resolutions). Only one of the machine's 18 cores is busy.

Each municipality's work is independent. It reads the shared shapefile and writes only its own
`bgysubmuns-municity-<code>.*` files and its own temporary `bgysubmuns-municity-<code>.json`.

The user, while 013's build ran: "Muni Cities processing takes a while to process. Maybe we can
parallelize this so that it can complete quickly."

## Outcome

- **Faster:** `scripts/topojson-municities.sh` processes municipalities concurrently, and the
  municities level of a quarter takes a few minutes instead of about 25. The time is measured and
  recorded.
- **Identical output:** a parallel build of 2026-3q is byte for byte what the one-at-a-time build
  wrote. `diff -r` of the two `municities/` trees is empty.
- **Failures still fail the build:** if any one municipality fails (`ogr2ogr` or `mapshaper`
  exits non-zero), the script exits non-zero, as `set -e` makes it today.
- **Moves O1:** a new PSGC quarter reaches `latest/` and a release sooner after the source repo
  publishes it, since a rebuild is no longer a half-hour wait.

## Affected

- **Area:** the municities level of the build.
- **Files & components:** `scripts/topojson-municities.sh`. Possibly `AGENTS.md`, where it says
  "municities takes the longest by far", and the README's "The barangay level takes the longest".
- **Downstream:** nobody directly. The script's output is an ignored `<quarter>/` build directory,
  and what's published (`latest/`, the release zips) must not change.
- **Contracts:**
  - **Output location and form** and **the PSGC hierarchy:** both stay as they are, because the
    files must be identical.
  - **`keep-shapes`:** stays on every `-simplify`.

## Constraints

- **Identical output** is the check that matters.
- **The level's `rm -rf` and `mkdir` run once,** before any parallel work starts.
- **One municipality's failure fails the script.**
- **No new dependency.** `xargs -P` or bash background jobs; GNU `parallel` isn't installed.
- **`regions` and `provdists` stay as they are.** They take seconds to a couple of minutes.

## Open questions

- ~~**How many at once?** All 18 cores, or fewer? `mapshaper` is a Node process, and the largest
  municipalities may need a lot of memory each. `JOBS` could default to the core count and be
  overridable.~~ Resolved: `JOBS` defaults to the core count and can be set from the environment.
- ~~**Is `mapshaper`'s output deterministic** when several instances run at once? It's expected to
  be, since each call is independent, but the `diff -r` is what proves it.~~ Resolved: the `diff -r`
  against 013's build decides it.
- ~~**Logging:** today each municipality prints `[BGYSUBMUNS] Processing <code>` and mapshaper's
  `[o] Wrote …` lines. Interleaved output from 18 jobs is hard to read. Keep it, or print one line
  per finished municipality?~~ Resolved: keep both, unchanged; lines interleave but stay whole.
- ~~**Does 4Q 2023 still build identically too,** or is 2026-3q enough proof?~~ Resolved: 2026-3q
  is enough; the code path is the same.

## Approach

- **The loop:** move its body into a function, or a small `bash -c` worker. Feed it the
  municipality codes from `municities.csv` through `xargs -P "$JOBS" -n 1`, so each code runs as
  its own job.
- **`xargs`'s exit status** makes a worker's failure fail the script.
- **The check:** build 2026-3q's municities level once more in parallel, into a separate quarter
  directory or by moving today's aside, then `diff -r` it against the existing `2026-3q/` build.
  Time both and record the times in notes.md.
- **Docs:** update the "takes the longest" lines in `AGENTS.md` and the README if they're no longer
  true.
