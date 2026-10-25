# Ideas

> Seeds, not a backlog: what someone thought worth doing, before anyone decided to. Each one is a
> `## [YYYY-MM-DD] [seed] <title>` heading, then a few lines on why and where it came from;
> `[bug]` in place of `[seed]` marks something already broken. A seed that must wait for others
> carries an `After: "<title>", "<title>"` line. `/sdlc:status` reads the tags and that line to
> put forward what's next. `/sdlc:intent` promotes a seed into a change and tags it `[building]`;
> that change's commit deletes the entry, and history keeps it.

## [2026-10-25] [seed] Build the municities level in parallel

Building 3Q 2026 (change 013) spent about 25 of its ~30 minutes in `topojson-municities.sh`.
That script loops over the 1,642 municipalities and cities one at a time, and each one runs an
`ogr2ogr` extract plus six `mapshaper` calls. The parents are independent of each other: each
writes only its own `bgysubmuns-municity-<code>.*` files and its own temporary GeoJSON. So the
loop could run across cores (this machine has 18), e.g. with `xargs -P`, and finish in a few
minutes. `topojson-provdists.sh` and `topojson-regions.sh` have the same shape but are already
fast.

Points to keep:
- The output must be byte for byte what the one-at-a-time loop writes: `diff -r` of the two
  builds of one quarter.
- A failure in any one parent must still fail the build. Today `set -e` does that.
- The level's `rm -rf` has to happen once, before the parallel work starts.

Came from the user while 013's build ran: "Muni Cities processing takes a while to process.
Maybe we can parallelize this so that it can complete quickly."
