---
id: 015
slug: parallel-municities
kind: plan
created: 2026-10-25
updated: 2026-10-25
---

# 015 — Build the municities level in parallel · plan

## Context

Change 015 is Tier 1 (`work/015-parallel-municities/intent.md`, serves O1, from the seed of the same
name). `scripts/topojson-municities.sh` took about 25 of the 30 minutes of 013's 3Q 2026 build. It
handles the 1,642 municipalities and cities one at a time: per municipality, one `ogr2ogr` extract
and six `mapshaper` calls, about 0.9 s each, which is mostly Node start-up. The machine has 18
cores and 36 GB of RAM. Each municipality's work writes only its own files, so they can run
concurrently. The output must stay byte for byte the same.

What I read:
- **The loop** (`scripts/topojson-municities.sh`, after the `rm -rf`/`mkdir` block):
  - `getArray` reads `$SHAPEFILE/municities.csv` into an array;
  - each code goes through `tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`;
  - then the `ogr2ogr -where "adm3_psgc=$f AND geom_src <> 'none'"` extract to
    `$GEOJSON/bgysubmuns-municity-$f.json`, the six `mapshaper` calls, and `rm` of the temp file.
- **Inputs:** `PH_Adm4_BgySubMuns.shp` is 272 MB with a 16 MB `.dbf`. `ogr2ogr -where` scans the
  `.dbf` and reads only matching geometries, and 18 concurrent readers of one file are fine.
- **The reference build** for the comparison is in the main checkout:
  `/Users/jafaeldon/projects-personal/faeldon/philippines-json-maps/2026-3q/`, built sequentially
  by this same loop in 013. It's read only, never written.

## Decisions on the intent's open questions

- **How many at once:** `JOBS` defaults to the core count (`getconf _NPROCESSORS_ONLN`, falling
  back to 4) and can be overridden from the environment (`JOBS=8 scripts/build-quarter.sh …`).
  18 Node processes fit easily in 36 GB.
- **Determinism:** proven by the `diff -r` below, not assumed.
- **Logging:** keep one `[BGYSUBMUNS] Processing <code>` line per municipality. Each `echo` is one
  line, so lines interleave but aren't garbled. mapshaper's own `[o] Wrote …` lines stay as they
  are; the flags don't change, so the output can't either.
- **4Q 2023:** 2026-3q is enough proof. The code path is the same; only the input differs.

## Changes

1. **`scripts/topojson-municities.sh`.** Replace `getArray` and the `for` loop with a worker
   function and `xargs -P`. The `rm -rf`/`mkdir` block and the CSV step before it stay, and still
   run once, before any worker starts.
   ```bash
   JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

   # One municipality or city: extract its barangays, then write the six simplified files.
   # Each writes only its own files, so they run $JOBS at a time.
   build_municity() {
     set -euo pipefail
     f=$1
     echo "[BGYSUBMUNS] Processing $f"
     # geom_src = 'none' rows have no shape (Manila's sub-municipalities); their barangays do.
     ogr2ogr ... (unchanged)
     mapshaper ... (the six calls, unchanged)
     rm "$GEOJSON/bgysubmuns-municity-$f.json" # Delete because this is a large file
   }
   export -f build_municity
   export SHAPEFILE GEOJSON TOPOJSON

   echo "[MUNICITIES] Processing $(wc -l < "$SHAPEFILE/municities.csv" | tr -d ' ') municipalities and cities, $JOBS at a time"
   tr -dc '[:alnum:]\n\r' < "$SHAPEFILE/municities.csv" | tr -d '\r' | tr '[:upper:]' '[:lower:]' \
     | xargs -n 1 -P "$JOBS" bash -c 'build_municity "$1"' _
   ```
   - The code clean-up is the same as today's `tr` per line. It's applied to the whole file at
     once, and `\r` is dropped so each code is one argument.
   - **Failure:** `xargs` exits 123 when any worker exits non-zero, and the script's
     `set -euo pipefail` then fails the build, as today.
   - `rm $SHAPEFILE/municities.csv` stays at the end.
2. **`AGENTS.md`:** "municities takes the longest by far" becomes "municities takes the longest;
   it builds `JOBS` municipalities at once (default: every core)". The README's "The barangay level
   takes the longest" stays true.
3. **`work/015-parallel-municities/`:** `plan.md` (this plan), `notes.md` (timings, diff, failure
   test), the intent's open questions struck as above, and `stage` moved along.

## Verification (in this worktree, recorded in notes.md)

1. **Fetch:** `scripts/fetch-shapefiles.sh v1.0.0 2026-3q` copies from staging into this
   worktree's ignored `scripts/processed/2026-3q/`.
2. **Time the parallel run:** `time scripts/topojson-municities.sh v1.0.0 2026-3q`, which builds
   this worktree's ignored `2026-3q/{geojson,topojson}/municities/`. Record the wall time against
   about 25 minutes.
3. **Identical output:** `diff -r` of `2026-3q/geojson/municities` and
   `2026-3q/topojson/municities` against the main checkout's `2026-3q/` must be empty. Also compare
   the file counts: 1,642 per resolution × 6.
4. **Failure fails:** put a fake `mapshaper` first on `PATH` (in the scratchpad) that exits 1 for
   one code and runs the real one otherwise. Run with `JOBS=4`: the script must exit non-zero and
   the failing code must show in stderr. Then rerun normally so the build directory is complete
   again.
5. **Gates:** the gate and `check --strict` pass. `git status` shows only the script, `AGENTS.md`
   and the change folder; the build directories are ignored.
6. **Clean up:** delete this worktree's `2026-3q/` and `scripts/processed/2026-3q/` before close.
   The main checkout's copies are untouched.

There's no checks.md: the proof needs a 2 GB input and a full level build, which is too heavy to
rerun at ship. The diff and timing in notes.md are the record.

## Rollback

`git revert` the commit; the loop comes back as it was. Nothing published changes either way.
