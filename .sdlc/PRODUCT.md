# Product

> What this repo's product is for, and the outcomes it is after. Every change names the
> outcomes it serves on its intent's `serves:` line (or `none`), and `/sdlc:retro` scores each
> outcome against the evidence `retro.evidence` prints. The plugin reads only the outcome ids
> and their short names, which the skills show beside each id; the rest is yours.
>
> Outcomes keep their ids from one retrospective to the next, and end done, dropped or revised,
> never silently gone: `sdlc.py retro-commit` refuses a doc that drops an open one. The forms:
>
> ```
> - O1. **Unaided setup.** A new user finishes setup without help. Measured by: setups finished / started
> - ~~O2. Exports open in a spreadsheet~~ Done: 0 failed-export reports since 1.4.0
> - ~~O3. Teams share drafts~~ Revised → O4: they share links, not drafts
> ```
>
> Evidence commands, set in `.sdlc/config.toml` under `[retro] evidence`, print counts and
> summaries: never a person's name, address or message. What they print stays in the session
> that ran the retrospective.

## Users

Web developers and analysts drawing maps of the Philippines: a choropleth in d3, an overlay in
Leaflet, a dashboard keyed by PSGC code. They want the boundaries of one level, inside one parent
area, small enough to load in a browser, and they usually link the raw file straight from GitHub.

## Problem

The official boundaries come as large shapefiles in a projected coordinate system. Turning them
into something a web page can load means installing GIS tools, reprojecting, simplifying, and
splitting each level by its parent, then keeping up when the PSA releases a new PSGC. Most people
who need a province map don't want to learn any of that.

## Outcomes

- O1. **Current boundaries.** The latest vintage matches the PSA's latest PSGC release. Measured
  by: months between a PSGC release and the matching `<year>/` directory
- O2. **Correct hierarchy.** Users find every area in exactly its parent's file, under its PSGC
  code. Measured by: data-error issues opened per release
- O3. **Drop-in web use.** A developer renders any level from a raw URL with no conversion.
  Measured by: clones and views; issues asking for help with the formats

## Bets

- People link the raw files on `master` rather than downloading a copy, so a stable path matters
  more than a release number.
- Three fixed resolutions (10%, 1%, 0.1%) cover what web maps need; nobody asks for another.
- Users report data errors when they find them, so the issue count is a fair measure of O2.
