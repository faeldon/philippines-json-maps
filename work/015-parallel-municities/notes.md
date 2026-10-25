# Notes

> What happened while this change was built that its intent, spec and plan don't say. Free-form,
> with one rule: anything left undone is an unticked `- [ ]` line. `/sdlc:ship` gives each one a
> disposition, carried to a `work/ideas.md` seed or dropped with a reason, and `sdlc.py ship`
> refuses while one is still unticked.

## Timing

`scripts/topojson-municities.sh v1.0.0 2026-3q` on this machine (18 cores, 36 GB), 2026-10-25:

| Build | Municipalities | Wall time |
|---|---|---|
| one at a time (013's build) | 1,642 | about 25 min (19:25 to 19:50) |
| parallel, `JOBS` = 18 (default) | 1,642 | **151 s** |

## Identical output

`diff -r` of this worktree's `2026-3q/{geojson,topojson}/municities/` against the main checkout's
`2026-3q/`, built one at a time by 013, is empty for both formats: 1,642 files in each of the six
resolution directories, 9,852 in all. No temporary `bgysubmuns-municity-*.json` is left behind.

## A failure fails the build

`PATH=<scratchpad>/fakebin:$PATH JOBS=4 scripts/topojson-municities.sh v1.0.0 2026-3q`, with a
fake `mapshaper` that exits 1 for Bago City (`1804502000`) and runs the real one otherwise:
- the script exits 1;
- the log has `fake mapshaper: failing on purpose for 1804502000`;
- the build is left with 1,641 lowres files, missing only Bago City.

`xargs` lets the other workers finish, then exits non-zero, so the script fails at the end of the
level rather than at the first error. A failed build is still a failed build; nothing publishes
from it.

## Deviation from the plan

The plan said to rerun normally after the failure test, so the build directory would be complete.
I skipped that, because the build directory is deleted before close and the successful run above is
the proof.
