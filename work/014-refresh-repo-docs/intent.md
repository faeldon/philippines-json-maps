---
id: 014
slug: refresh-repo-docs
tier: 1
impact: patch
stage: shipped
created: 2026-10-25
updated: 2026-10-25
shipped: 2026-10-25
idea:
depends_on:
serves: [O3]
---

# 014 — Refresh the README, contributing guide, license and repo templates for v1.0.0

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

v1.0.0 changed how people get these maps: `latest/` holds medres and lowres only, and every
quarter, hires included, ships as a release. The repo's own docs mostly predate that, and much of
them were copied in from other projects:

- **The README has no download path for the releases.** A user who wants hires, or a quarter that
  never changes, has to find `releases/latest/download/<format>-<res>.zip` and
  `shasum -a 256 -c SHA256SUMS` on their own. A first-time user also isn't told how files are
  named:
  - which file holds a given area;
  - that codes are integers;
  - that every feature carries its parents' codes.
- **The README doesn't credit the data's source.** The boundaries come from OCHA's COD-AB
  (NAMRIA/PSA, **CC BY-IGO**), through `faeldon/philippines-psgc-shapefiles`, and the README never
  says so.
- **The README has outright errors.**
  - "Raw shapefiles … are made available" is false, since no shapefiles are here.
  - The Leaflet and d3 links (`www.leafletjs.com`, `www.d3js.org`) have no scheme, so GitHub
    resolves them inside the repo.
- **The README has no AI-assistance disclosure,** though the shapefiles repo has one and this repo
  is built the same way.
- **`.github/PULL_REQUEST_TEMPLATE.md` describes another project:**
  - a `dev` branch;
  - "100% coverage";
  - "internal code generators";
  - a broken link to `.guthub/CONTRIBUTING.md`.
- **`.github/CONTRIBUTING.md` and the issue templates are generic web-app boilerplate.** They ask
  for "browser(s) and OS". They never ask for what a map report needs: the file path, the PSGC
  code, and what's wrong (wrong parent, missing area, wrong shape or name).
- **Leftover config from before:**
  - `.gitattributes` still sends `*.shp` to git-lfs, though no shapefiles live here since 012.
  - `.github/lock.yml` and `issue_close_app.yml` configure Probot apps that may no longer run.
- **No changelog says what each release holds.** The shapefiles repo has one.

The user asked for it after v1.0.0: "Now that we've released version 1.0, maybe it's time to
update the README markdown files, licenses, contributing. You can look at the Philippines PSGC
shapefiles, README docs for some inspiration."

## Outcome

- **README**, modelled on `philippines-psgc-shapefiles/README.md`:
  - a **Download** section: `latest/` via raw URLs, releases with `releases/latest/download/…`
    links, and `shasum -a 256 -c SHA256SUMS`;
  - **Files** and **Conventions** sections: one file per parent, the naming pattern, integer
    codes, parent codes on every feature, `geom_src`;
  - a **Sources and license** section crediting COD-AB (NAMRIA/PSA, CC BY-IGO) via the
    shapefiles repo, with MIT for this repo's scripts and maps;
  - an **AI assistance** section pointing at `AGENTS.md` and `.sdlc/SDLC.md`;
  - working links throughout, and no claim about shapefiles.
- **`LICENSE`:** MIT, worded like the shapefiles repo's.
- **`CHANGELOG.md`:** new. It lists v1.0.0 (PSGC 3Q 2026, from source `v1.0.0`) and the legacy
  releases `2023-4q`, `2019` and `2011`, each with what it holds.
- **`.github/`:**
  - `CONTRIBUTING.md`, the PR template and the issue templates are rewritten for a data repo.
  - The bug report asks for the file path, the PSGC code and what's wrong.
  - Contributions are made against `master`.
- **Removed:** the `*.shp` LFS rule in `.gitattributes`, and the Probot configs if they're dead.
- **Every relative link and anchor in the changed files resolves,** checked by a script, not by
  eye.
- **Moves O3:** a developer gets the right file or release asset, and checks it, from the README
  alone, without opening issues to ask where hires or older quarters went.

## Affected

- **Area:** the repo's user-facing docs and GitHub config.
- **Files & components:**
  - `README.md` and `LICENSE`;
  - `CHANGELOG.md`, which is new;
  - `.github/CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md` and
    `.github/ISSUE_TEMPLATE.md`;
  - `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md`;
  - `.github/lock.yml`, `.github/issue_close_app.yml` and `.gitattributes`;
  - possibly `.github/CODE_OF_CONDUCT.md`, to match the shapefiles repo's.
- **Downstream:** everyone who reads the README on GitHub, and anyone opening an issue or PR. No
  data path, file name or release asset changes.
- **Contracts:** none. No `latest/` path, file or release asset changes, so "Paths are public API"
  and "Vintages are releases" are untouched.

## Constraints

- **Links must point at real files.** The demo link and every raw URL in the README must point at
  files that exist.
- **The license may not narrow what MIT already granted.** The attribution adds a credit for the
  upstream data. It doesn't relicense anything.
- **Wording follows the shapefiles repo** where the two repos are alike, so the pair reads as one
  project.

## Open questions

- ~~Are `lock.yml` and `issue_close_app.yml` still read by anything? Probot's lock app was retired.
  If they're dead, delete them; if not, keep or replace them with an Actions workflow like the
  shapefiles repo's `stale.yml`.~~ Resolved: delete both, and add no automation in their place.
- ~~Should `CODE_OF_CONDUCT.md` be replaced with the shapefiles repo's version, or left alone?~~
  Resolved: left alone.
- ~~Does the README keep the `images/` sample maps (`regions.png`, `province.png`, `municity.png`)?
  They show 2019-era boundaries. Should they be redrawn from 3Q 2026?~~ Resolved: redrawn as SVGs
  from `latest/` by a new `scripts/sample-maps.sh`.
- ~~Should the README name which PSGC quarter is in `latest/` in prose, which needs an edit each
  quarter, or only point at `latest/manifest.json` and the changelog?~~ Resolved: name it, and
  point at the manifest and the changelog; each new quarter's change updates the line.

## Approach

- **README:** restructure it on the shapefiles repo's sections: intro, Download, Files,
  Conventions, Sources and license, AI assistance, Contributing. Keep the existing Sample Maps,
  Conversion Process and Using the Scripts sections, corrected.
- **LICENSE:** reword to the shapefiles repo's MIT text.
- **CHANGELOG.md:** one table of releases, newest first, each linking its GitHub release and its
  source release.
- **`.github/`:** rewrite CONTRIBUTING and the templates from the shapefiles repo's, adapted to
  this repo: map files, the build scripts, `/sdlc` stages.
- **Delete** the LFS rule and the dead Probot configs.
- **Verify** with a link check over the changed Markdown: relative paths exist, anchors resolve,
  and `raw.githubusercontent` and `releases/download` URLs return 200. Record it as the acceptance
  check.
- **Nits:** none open on these paths.
