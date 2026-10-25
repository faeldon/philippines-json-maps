---
id: 016
slug: remove-repo-cruft
tier: 1
impact: none
stage: shipped
created: 2026-10-25
updated: 2026-10-25
shipped: 2026-10-25
idea:
depends_on:
serves: none
---

# 016 — Remove leftover repo cruft

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

Some repo files still describe how the repo worked before change 012. Shapefiles now come from
the release of faeldon/philippines-psgc-shapefiles by way of `scripts/fetch-shapefiles.sh`, and
they no longer live in the tree:

- **`scripts/.gitattributes`** sends `*.zip` through Git LFS. It was added in
  `a846ba65 Zipped shapefiles`. `git ls-files '*.zip'` is now empty and nothing in the repo uses
  LFS, so the file does nothing. It also suggests to new contributors that they need LFS to clone
  or build.
- **`.gitignore`** still ignores `scripts/2023/processed/`. `scripts/2023/` is gone from the tree
  and from disk. The `# Input Data ` header has a trailing space.
- **`.github/ISSUE_TEMPLATE.md`** is the legacy single issue template. It sits beside
  `.github/ISSUE_TEMPLATE/` (`data_error.md`, `request.md`), which GitHub's template chooser uses
  instead. The file's only job is to tell people not to file blank issues, and the folder can do
  that itself.

Each one makes the repo look as if it needs something it doesn't.

## Outcome

- `scripts/.gitattributes` is gone. `git check-attr -a scripts/x.zip` prints nothing.
- Every pattern in `.gitignore` matches something the current scripts create:
  `scripts/processed/`, the quarter build directories, `dist/`, `.DS_Store` and
  `.claude/worktrees/`. No pattern points at a path that no longer exists.
- `.github/` has one issue-template mechanism, the `ISSUE_TEMPLATE/` folder. Blank issues are
  either turned off (`ISSUE_TEMPLATE/config.yml` with `blank_issues_enabled: false`) or point to
  the contributing guide from the chooser. `ISSUE_TEMPLATE.md` is deleted.
- Any other tracked file outside `latest/` that nothing reads or runs has been removed, or listed
  here with the reason it stays.
- The gate (`commands.check`) still passes.

## Affected

- **Area:** repo plumbing: git config files, `.github/` and the top level.
- **Files & components:** `scripts/.gitattributes`, `.gitignore`, `.github/ISSUE_TEMPLATE.md`,
  possibly a new `.github/ISSUE_TEMPLATE/config.yml`, and any further stale files found in a sweep
  outside `latest/`.
- **Downstream:** people who open issues on GitHub see the template chooser. Nobody reads these
  files through `raw.githubusercontent.com`. `latest/`, `images/` and the scripts' behaviour stay
  as they are.
- **Contracts:** none directly. *Output location and form* is close by: `.gitignore` is what keeps
  build directories, `dist/` and source shapefiles out of the tree, so its working patterns have to
  stay.

## Constraints

- Leave `latest/` and every path in it alone (*Paths are public API*).
- `.gitignore` must keep ignoring `scripts/processed/`, `/[0-9][0-9][0-9][0-9]-[1-4]q/` and
  `/dist/`. The release flow needs the local `2026-3q/` and `dist/` to exist in the releasing
  checkout but never be committed.
- The gate keeps its `scripts/20*` guard unless this change decides on purpose to drop it.
- Local untracked build output (`2026-3q/`, `dist/v1.0.0`, `scripts/processed/`) is not cruft to
  delete. Those directories are needed for releasing.

## Open questions

- ~~Should blank issues be turned off with `config.yml`, or should the chooser keep a blank option
  with a contact link to `CONTRIBUTING.md`?~~ Resolved: turned off, with `CONTRIBUTING.md` as a
  contact link, which is what `ISSUE_TEMPLATE.md` asked people to do.
- ~~Does the gate's `scripts/20*` guard still earn its place now that `scripts/2023/` is gone, or
  should it go along with the `.gitignore` line?~~ Resolved: it stays. It guards against
  `8bea49f3`'s second copy under `scripts/2023/` (`.sdlc/REVIEW.md`), costs nothing, and the
  mistake can recur without the directory.
- ~~Does a sweep of the rest of the tracked tree (`.sdlc/setup.json`, `.claude/settings.json`,
  `CHANGELOG.md`, `images/`) find anything else unused?~~ Resolved: only
  `scripts/release-legacy.sh`, whose three releases are all published; it goes. Everything else
  has a reader (the plugin, the README, `sample-maps.sh`).

## Approach

1. Delete `scripts/.gitattributes`.
2. Drop `scripts/2023/processed/` from `.gitignore` and fix the header.
3. Replace `.github/ISSUE_TEMPLATE.md` with `.github/ISSUE_TEMPLATE/config.yml`, carrying its
   contributing-guide link as a `contact_links` entry.
4. Sweep the tracked files outside `latest/` with `git ls-files`, grepping each for a reader.
   Remove what has none, and list what stays and why in the change's notes.
5. Delete `scripts/release-legacy.sh` and replace its sentence in `AGENTS.md`. That makes nit
   **013-1** (it can't resume after a partial failure) moot.
6. Run the gate.
