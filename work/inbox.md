# Ideas

> Seeds, not a backlog: what someone thought worth doing, before anyone decided to. Each one is a
> `## [YYYY-MM-DD] [seed] <title>` heading, then a few lines on why and where it came from;
> `[bug]` in place of `[seed]` marks something already broken. A seed that must wait for others
> carries an `After: "<title>", "<title>"` line. `/sdlc:status` reads the tags and that line to
> put forward what's next. `/sdlc:intent` promotes a seed into a change and tags it `[building]`;
> that change's commit deletes the entry, and history keeps it.

## [2026-10-25-1] [nit] fetch-shapefiles.sh prints a git "fatal" outside a checkout

Run from a downloaded ZIP (no `.git`), `git rev-parse` prints `fatal: not a git repository` and
the staging path resolves relative to the cwd; the release download still runs.

Theme: robustness
Paths: scripts/fetch-shapefiles.sh
Cost: S
Value: low
Raised by: 012-build-from-psgc-releases (correctness)

## [2026-10-25-2] [nit] Staging SHA256SUMS isn't checked against meta.json's sha256sums

A staging copy is verified against its own `SHA256SUMS`; `meta.json` records that file's hash
(`sha256sums`), which would anchor it to the release.

Theme: robustness
Paths: scripts/fetch-shapefiles.sh
Cost: S
Value: low
Raised by: 012-build-from-psgc-releases (correctness)
