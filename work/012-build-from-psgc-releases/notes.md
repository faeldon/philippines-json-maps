# 012 — notes

## Build, 2026-10-25

- Installed `gdal` 3.13.3 (brew) and `mapshaper` 0.7.98 (npm -g); neither was on this machine.
- Every `-simplify` gained `keep-shapes` mid-build: the first full run left small polygons as
  `geometry: null` at medres and lowres, as `master` already had (see spec Design). The whole
  tree was then regenerated a second time; the results below are from that run.
- Each script now unzips the parent layer it lists codes from; it used to rely on the previous
  script having done it.

## Fetch (R2–R5), tested by hand

- [x] Staging present: "copied from staging …/release-staging/2023-4q", 7 files verified.
- [x] Re-run with everything present: "verified …, nothing fetched".
- [x] `PSGC_STAGING=/nonexistent`, fresh quarter folder: "downloaded from release psgc-2023-4q"
      (~690 MB in 70 s), 7 files verified.
- [x] A file corrupted before a run is detected and fetched again.
- [x] A release tag that doesn't exist: `curl` 404, exit 56, nothing left behind.
- [x] `find release-staging -newer <marker>` empty after all of the above: nothing written there.
- [x] The delete-on-mismatch branch (a copy or download that arrives corrupted) wasn't exercised:
      producing one needs a fake download source. → dropped: a corrupted fetch still fails
      verification and exits 1, so it is never used either way.

## What the regeneration changed (R14)

Against `master`: 10,387 of 10,488 2023 files changed, 6 removed (`1909900000`), 6 added
(`1999900000`). `2011/` and `2019/` untouched. Every change falls in one of these:

1. **Membership** (the point of the change), in every format and resolution: 14 `provdists/`
   files gain their 16 cities under no province; region `1900000000` swaps `1909900000` for
   `1999900000`; `municities-provdist-1999900000` holds the 8 interim municipalities; Manila's
   `bgysubmuns-municity-1380600000` goes from empty to 899 barangays.
2. **Parent codes** of the barangays of those 16 cities: `adm2_psgc` changes from the city's own
   code to its geographic province's (e.g. Cagayan de Oro's: `1030500000` → `1004300000`),
   2,123 barangays at each resolution. No other property value changes anywhere.
3. **`geom_src` added** to every barangay feature (new in the release; `source` for every row
   written, since `none` rows are left out). Additive.
4. **No null geometries**: `master` had 911 (703 lowres, 195 medres, 8 hires barangays; 5 lowres
   municipalities); now 0, from `keep-shapes`. Those features now have shapes, and their
   neighbours' shared boundaries move to make room.
5. **Simplification shifts.** mapshaper's `-simplify N%` budgets vertices across the whole file,
   so a membership change (1) or a restored polygon (4) reshapes the rest of that file at medres
   and lowres. In files whose members didn't change, area changes of 1% or more: hires 12 (8 were
   null, 4 are 0–2 km² barangays beside one, shrinking 1–8%), medres 248 (195 were null), lowres
   868 (707 were null). The rest are slivers that grew (68) or shrank (146) as `keep-shapes`
   rebalanced the budget.
6. **Reprojection noise**: unchanged features otherwise differ by ~1e-14° in the last digit
   (GDAL 3.13.3's UTM → WGS84). 126,398 of 128,351 features change area by less than 0.01%.

TopoJSON files: same object ids and properties as their GeoJSON pairs; arcs are quantized, so
they were compared by membership only.

## Checks

All of `checks.md` and the gate pass on the final tree, and leave the working tree unchanged.
R9's check reads all 1,747 lowres child files (43,733 features, matching the release's 88 + 1,642
+ 42,003 shaped rows) and fails when one municipality is removed from its file (tested on a copy).
