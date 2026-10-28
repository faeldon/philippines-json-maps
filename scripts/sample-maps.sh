#!/usr/bin/env bash
# Render the README's sample maps from latest/ lowres: the island groups and the regions of the
# country, the provinces of one region, and the municipalities and cities of one province. Rerun
# after a new quarter.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 0 ] || { echo "usage: $(basename "$0")   (no arguments; reads latest/, writes images/)" >&2; exit 2; }
SRC="$ROOT/latest/geojson"
OUT="$ROOT/images"

render() {
  mapshaper "$SRC/$1" -proj merc -style fill="${3:-'#dbe7f3'}" stroke='#2f557f' stroke-width=0.7 \
    -o format=svg width=600 margin=4 "$OUT/$2"
}

mkdir -p "$OUT"
render islandgroups/lowres/islandgroups.0.001.json islandgroups.svg \
  "{Luzon: '#dbe7f3', Visayas: '#f3e6c8', Mindanao: '#d9ecd4'}[island_group]"       # Luzon, Visayas, Mindanao
render country/lowres/country.0.001.json regions.svg                                 # 18 regions
render regions/lowres/provdists-region-1800000000.0.001.json provinces.svg           # Negros Island Region
render provdists/lowres/municities-provdist-1804500000.0.001.json municities.svg     # Negros Occidental
