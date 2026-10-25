# Notes

> What happened while this change was built that its intent, spec and plan don't say. Free-form,
> with one rule: anything left undone is an unticked `- [ ]` line. `/sdlc:ship` gives each one a
> disposition, carried to a `work/ideas.md` seed or dropped with a reason, and `sdlc.py ship`
> refuses while one is still unticked.

## Deviations from the plan

- **Issue template labels are `bug` and `enhancement`, not `data`.** The repository has no `data`
  label, and creating one changes GitHub, so the templates use the existing labels instead.
- **LICENSE keeps the standard ending, `SOFTWARE.`** Only its heading and copyright line take the
  shapefiles repo's wording (`MIT License`, `Copyright (c) James Faeldon.`). That repo's copy drops
  the final period of the MIT text, which looks like a slip, not a choice.
- **The 2011 row of CHANGELOG.md says "not matched to a quarter".** `2011/` was drawn from GADM's
  2011 map, never matched to a PSGC publication.
- **The README also links MapLibre** beside Leaflet and d3, as a current web-map library.
- **The sample maps are `images/{regions,provinces,municities}.svg`.** `scripts/sample-maps.sh`
  draws them with `mapshaper -proj merc`, and they were checked once by rendering them: 18
  regions; Negros Occidental, Negros Oriental and Siquijor; Negros Occidental's 32 municipalities
  and cities.

## Links, online, once (2026-10-25)

Every absolute URL in `README.md`, `CHANGELOG.md` and `.github/**/*.md`: 32 return 200 or 206,
following redirects. Those are:
- the six `releases/latest/download/*.zip` assets;
- the four release tags;
- the source repo's `v1.0.0` and `psgc-2023-4q`;
- HDX's `cod-ab-phl`, CC BY-IGO, GADM, gdal, mapshaper and the demo file.

The only 404 is the README's URL template (`.../master/latest/<format>/...`), which the checker
cut at `<`; it isn't a link. The checks.md link check runs offline and fails on master's old README
(scheme-less links, missing images).
