# Review

> This repo's additions to the review guide, which `/sdlc:ship` reads with this file
> (`docs.review.guide` in `sdlc.py config`). Each block here, a heading or a `- **lead**` bullet,
> stands in for the guide's block of the same heading path, or lead, when it holds text of its
> own, and is read after its parent's block there when the guide has none like it. A heading with
> nothing under it only places what follows.

## Pass 1 — Correctness

### The ways this repo's code fails

- **An area under the wrong parent.** A child file holds a feature whose parent code
  (`adm1_psgc`, `adm2_psgc`, `adm3_psgc`) isn't the code in the file's name, or a parent's file is
  missing children it should have. Davao City in Davao del Sur (`8bea49f3`, `8eeead56`) and NCR
  districts with no municipalities (`c389e081`) were both this.
- **Output in the wrong place.** The scripts build a quarter into `<quarter>/` at the root
  (ignored); only `latest/`, medres and lowres, is committed. A build directory, `dist/`, a
  `hires/` file or a copy under `scripts/` in the diff is this: `8bea49f3` committed a full second
  copy under `scripts/2023/`, and `8eeead56` took it out. The gate catches it; review checks
  `latest/` actually changed, and that `publish-latest.sh` made it.
- **A file renamed by accident.** A PSGC code is used as the shapefile gives it, as an integer
  (`provdists-region-100000000`, not `0100000000`). Padding, stripping or retyping a code renames
  every file built from it, and breaks every hotlink to them.
- **Resolutions out of step.** A level changed in one of `hires`/`medres`/`lowres`, or in GeoJSON
  but not TopoJSON. Each changed feature should change in all six files of its parent.
- **A published release changed.** Old vintages live only in releases (`2011`, `2019`,
  `2023-4q`, `v*`). A script or step that re-uploads, deletes or replaces a release's assets is
  this; a new quarter is a new release.

## Reporting rules

- **Out of scope, never reported:** formatting a formatter already fixes. The generated JSON is
  this repo's product, so it is reviewed, by its file list and the codes it changes rather than
  line by line: which files, how many per level and resolution, and whether a sample of their
  features carry the parent code their file names.
