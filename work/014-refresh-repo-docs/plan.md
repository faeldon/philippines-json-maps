---
id: 014
slug: refresh-repo-docs
kind: plan
created: 2026-10-25
updated: 2026-10-25
---

# 014 — Refresh the README, contributing guide, license and repo templates for v1.0.0 · plan

## Context

Change 014 is Tier 1 (`work/014-refresh-repo-docs/intent.md`, serves O3). v1.0.0 put the newest
quarter in `latest/` (medres + lowres) and every quarter, hires included, in GitHub releases. The
repo's docs still describe the old layout, or were copied from other projects. You asked for the
README, license and contributing guide to be updated, using the shapefiles repo as inspiration.

Your answers on the open questions:

| Question | Decision |
|---|---|
| Probot configs | delete them, add no automation |
| Sample images | redraw them from `latest/` |
| Which quarter `latest/` holds | name it in prose, and point at the manifest and the changelog |
| Templates | write ones for a data repo |
| Data license | MIT plus a data attribution |

Facts found while planning:
- **The shapefiles repo's templates are boilerplate too.** Its `.github/CONTRIBUTING.md`, PR
  template and bug template mention a `dev` branch, 100% coverage and browser versions. What's
  worth taking from it:
  - its README structure (Download, Files, Conventions, Sources, AI assistance, Contributing);
  - its "AI-assisted contributions" section;
  - its MIT wording (`MIT License` / `Copyright (c) James Faeldon.`).
- **Issues users actually file** (#1–#10):
  - wrong or missing data: #3, #4, #6, #7, #10;
  - a newer PSGC quarter: #9, #5;
  - another format or a merged file: #8, #2.

  The issue templates should ask for those cases.
- **Provenance for the changelog:**
  - `2019/` is the "Dec 2018" maps from OCHA HDX's levels 0–3 shapefiles (README at `83f99518`),
    moved into `2019/` in `685d702b`.
  - `2011/` is from GADM.
  - `2023-4q` is PSGC 4Q 2023, from source `psgc-2023-4q` (change 012, `195f6db2`).
  - `v1.0.0` is PSGC 3Q 2026, from source `v1.0.0`.
- **Source data credit:** OCHA COD-AB (NAMRIA/PSA), CC BY-IGO, release of 2023-11-06, as the
  shapefiles README states.
- **The old images** (`images/{regions,province,municity}.png`) date from 2019. The README links
  them by `raw.githubusercontent.../master/images/...`.
- **No open nits** touch these paths.

## Files to change

- `README.md`: restructured (below).
- `LICENSE`: MIT text worded as the shapefiles repo's.
- `CHANGELOG.md`: new.
- `.github/CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE.md`, and
  `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md`, renamed to `data_error.md` and
  `request.md`: rewritten.
- `.github/lock.yml`, `.github/issue_close_app.yml`: deleted.
- `.gitattributes`: deleted. Its only line is the `*.shp` LFS rule.
- `scripts/sample-maps.sh`: new. It renders the README's three SVGs from `latest/` with mapshaper.
- `images/{regions,province,municity}.png` → `images/{regions,provinces,municities}.svg`.
- `work/014-refresh-repo-docs/`: `intent.md` (open questions struck, stage), `checks.md`,
  `notes.md`, `plan.md` (this plan).
- `.github/CODE_OF_CONDUCT.md`: unchanged.

## Work order

1. **Intent:** strike the 4 open questions with the decisions above. Save this plan as
   `plan.md`, and set `stage: build`.
2. **`scripts/sample-maps.sh`:**
   - Uses the usage guard style of the other scripts, and `ROOT` from its own path. It takes no
     arguments.
   - Runs `mapshaper <lowres geojson> -proj wgs84 -style fill=... stroke=... -o format=svg width=...`
     for three files:
     - `latest/geojson/country/lowres/country.0.001.json` → `images/regions.svg`, the 18 regions;
     - `latest/geojson/regions/lowres/provdists-region-1800000000.0.001.json` →
       `images/provinces.svg`, the Negros Island Region's provinces;
     - `latest/geojson/provdists/lowres/municities-provdist-1804500000.0.001.json` →
       `images/municities.svg`, Negros Occidental's municipalities and cities.
   - Run it, check the SVGs render (`Read` them as images), and `git rm` the old PNGs.
3. **README.md**, in this order:
   - **Title and badge:** the badge links `LICENSE`, relative.
   - **One paragraph:** what the repo is. Name "PSGC 3Q 2026" and point at
     `latest/manifest.json` and `CHANGELOG.md`. Keep the Demo link.
   - **Download:**
     - `latest/` by raw URL (`https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/latest/<format>/<level>/<res>/<file>`), with one worked example.
     - Releases for hires and pinned quarters: a table of the six assets linked by
       `releases/latest/download/<format>-<res>.zip`.
     - `shasum -a 256 -c SHA256SUMS`.
     - Older vintages: `2023-4q`, `2019`, `2011`.
   - **Files:** a table of the 4 levels: directory, one file per, holds, feature id. Then the
     naming pattern and resolutions. This replaces "Files Available", and the false shapefile
     claim goes.
   - **Conventions:**
     - integer codes (`100000000`);
     - parent codes on every feature (`adm1_psgc`…);
     - WGS84;
     - `geom_src` (moved here from Source Files);
     - the 3Q 2026 renamed-codes note, linking the v1.0.0 release notes.
   - **Sample maps:** the three SVGs by relative path, with `https://` links to Leaflet, d3 and
     geojson.io.
   - **Sources and license:**
     - built from `faeldon/philippines-psgc-shapefiles` (release named in the manifest);
     - its boundaries from OCHA COD-AB by NAMRIA and PSA, CC BY-IGO;
     - this repo's scripts and maps are MIT (`LICENSE`), and reusers should credit the upstream
       data as CC BY-IGO requires.
   - **Building the maps:** the existing "Conversion Process" and "Using the Scripts", tightened,
     adding `scripts/sample-maps.sh`.
   - **AI assistance:** adapted from the shapefiles repo. Development uses Claude Code; you review
     and approve every change; the rules are in `AGENTS.md` and `.sdlc/SDLC.md`. Commits carry a
     `Co-Authored-By` line, so this section says so; it doesn't claim there are none.
   - **Contributing:** link `.github/CONTRIBUTING.md` and `.github/CODE_OF_CONDUCT.md`. "Found a
     wrong code, name or boundary? File an issue."
4. **LICENSE:** the shapefiles repo's text: `MIT License`, `Copyright (c) James Faeldon.`, and the
   same body. Copyright and the grant are unchanged.
5. **CHANGELOG.md:** a short intro (each release's assets and how releases relate to `latest/`).
   Then one table, newest first: release (linked), date, PSGC, source, notes.
   - `v1.0.0`: 2026-10-25, 3Q 2026, source `v1.0.0`, "`latest/` introduced; 2011/2019/2023 moved
     to releases; Negros Island Region, Sulu → IX".
   - `2023-4q`: 4Q 2023, source `psgc-2023-4q`, formerly `2023/`.
   - `2019`: Dec 2018, OCHA HDX levels 0–3, formerly `2019/`.
   - `2011`: GADM, formerly `2011/`.

   No PSA update table; the shapefiles repo's changelog has that, and this links it.
6. **.github:**
   - **`CONTRIBUTING.md`:**
     - Reporting a data error: the file path or URL, the PSGC code, and what's wrong (wrong parent,
       missing area, wrong shape or name). Check the source repo first, since most errors are
       upstream.
     - Requests: a new quarter, a format.
     - Pull requests against `master`: fork, branch, run `scripts/build-quarter.sh` only if your
       change regenerates, and run the gate command from `AGENTS.md`.
     - AI-assisted contributions, adapted.
     - The MIT clause, with a relative link to `../LICENSE`.
   - **`PULL_REQUEST_TEMPLATE.md`:** a short checklist: targets `master`; the gate passes; no
     build directory, `dist/` or `hires/` committed; docs updated; links the issue.
   - **`ISSUE_TEMPLATE.md`:** a pointer to the two templates.
   - **`ISSUE_TEMPLATE/data_error.md`:** frontmatter `name: Data error`, `labels: data`. Fields:
     the file (path or raw URL), the PSGC code(s), what's wrong, what it should be and its source
     (a PSA link if any), and the release or `latest/manifest.json` version.
   - **`ISSUE_TEMPLATE/request.md`:** `name: Request`. Fields: what you need (newer quarter,
     format, merged file) and what you'd use it for.
   - `git rm` `lock.yml`, `issue_close_app.yml`, the old `bug_report.md` and `feature_request.md`
     (renamed into the new ones), and `.gitattributes`.
7. **`checks.md`:** one acceptance check, run offline. A Python link check over `README.md`,
   `CHANGELOG.md` and `.github/**/*.md`:
   - every relative link or `src` (anchor stripped) exists;
   - every `#anchor` matches a GitHub heading slug or an `<a name>` in its file;
   - every `raw.githubusercontent.com/faeldon/philippines-json-maps/master/<path>` exists in the
     tree;
   - every `releases/latest/download/<name>` is one of the 7 v1.0.0 asset names;
   - no `www.`-without-scheme links, and no `.guthub`.

   Plus `! grep -n 'shp' .gitattributes 2>/dev/null` and `test ! -e .github/lock.yml`.
8. **Online, once, recorded in notes.md:** `curl -sI` every absolute URL in the changed files
   (GitHub release, tag and download links, psa.gov.ph, humdata, gadm) and record their status
   codes.
9. `stage: test`, then `/sdlc:ship`. Proposed impact: `patch`, since nothing anyone downloads
   changes and the docs describe it better.

## Verification

- The gate (`commands.check`) passes. It's unaffected, since `latest/` doesn't change.
- `checks.md`'s link check passes. Pointing a link at a missing file or anchor makes it fail.
- The SVGs are viewed once to confirm they render: 18 regions; Negros Occidental, Negros Oriental
  and Siquijor; Negros Occidental's cities and municipalities.
- The notes.md URL table: every external link returns 200 or 302.
- Read the README top to bottom as a new user: find a lowres region file, the hires zip, and how
  to verify it, without leaving the README.

## Rollback

`git revert` the commit. That restores the old docs, PNGs, Probot configs and `.gitattributes`.
Nothing outside the repo changes.
