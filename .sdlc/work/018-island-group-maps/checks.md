# Checks

> The change's acceptance checks: each `## ` section is one, which only a deliberate revert could
> fail, so it stays out of the suite. `/sdlc:ship` reruns every one from the checkout root before
> it commits, and a check passes when its one `sh` block exits 0 and leaves the working tree as it
> found it. `sdlc.py` reads each section's name and that block, nothing else.

## R3 R5 latest holds the three island groups in both formats

Only removing the files or changing the dissolve could change their ids and properties.

```sh
set -e
for f in latest/geojson/islandgroups/medres/islandgroups.0.01.json latest/geojson/islandgroups/lowres/islandgroups.0.001.json; do
  test "$(jq -c '[.features[].id]' "$f")" = '["Luzon","Visayas","Mindanao"]'
  test "$(jq -c '[.features[].properties|keys]|unique' "$f")" = '[["area_km2","island_group"]]'
  test "$(jq -c '[.features[]|.id == .properties.island_group]|all' "$f")" = true
done
for f in latest/topojson/islandgroups/medres/islandgroups.topo.0.01.json latest/topojson/islandgroups/lowres/islandgroups.topo.0.001.json; do
  test "$(jq -c '[.objects.islandgroups.geometries[].id]' "$f")" = '["Luzon","Visayas","Mindanao"]'
done
test "$(jq '[.features[].properties.area_km2]|add' latest/geojson/islandgroups/lowres/islandgroups.0.001.json)" = \
     "$(jq '[.features[].properties.area_km2]|add' latest/geojson/country/lowres/country.0.001.json)"
```

## R4 island-group borders are the regions' own, vertex for vertex

Simplifying after the dissolve, or from another source, would put vertices outside `country/`'s.

```sh
set -e
coords() { jq -r '[.features[].geometry.coordinates|..|arrays|select(length==2 and (.[0]|type)=="number")|"\(.[0]),\(.[1])"]|unique[]' "$1"; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for s in medres:0.01 lowres:0.001; do
  res=${s%%:*} suf=${s#*:}
  coords latest/geojson/islandgroups/$res/islandgroups.$suf.json > "$tmp/ig"
  coords latest/geojson/country/$res/country.$suf.json > "$tmp/country"
  test -s "$tmp/ig"
  test "$(comm -23 "$tmp/ig" "$tmp/country" | wc -l | tr -d ' ')" = 0
done
```

## R6 Laguna de Bay is the only hole

A gap opened by the dissolve would show up as another interior ring.

```sh
set -e
for f in latest/geojson/islandgroups/medres/islandgroups.0.01.json latest/geojson/islandgroups/lowres/islandgroups.0.001.json; do
  test "$(jq -c '[.features[] | {(.id): ([.geometry.coordinates[]|length-1]|add)}] | add' "$f")" = '{"Luzon":1,"Visayas":0,"Mindanao":0}'
  test "$(jq '[.features[] | select(.id=="Luzon") | .geometry.coordinates[] | .[1:][] | .[] | select(.[0] < 121.0 or .[0] > 121.5 or .[1] < 14.1 or .[1] > 14.6)] | length' "$f")" = 0
done
```

## R1 the mapping puts every region in exactly one island group

The CSV and `latest/country/` agree on the 18 regions; only an edit to either could split them.

```sh
set -e
test -z "$(tail -n +2 scripts/island-groups.csv | awk -F, '$2 !~ /^(Luzon|Visayas|Mindanao)$/')"
test -z "$(tail -n +2 scripts/island-groups.csv | cut -d, -f1 | sort | uniq -d)"
test "$(tail -n +2 scripts/island-groups.csv | cut -d, -f1 | sort)" = \
     "$(jq -r '.features[].properties.adm1_psgc' latest/geojson/country/lowres/country.0.001.json | sort)"
grep -qx '1700000000,Luzon' scripts/island-groups.csv
grep -qx '1800000000,Visayas' scripts/island-groups.csv
```

## R7 R8 R9 the quarterly pipeline builds, publishes and releases islandgroups

Dropping the level from any of the three loops would leave it stale in `latest/` or out of a release.

```sh
set -e
grep -q 'for level in country islandgroups regions provdists municities' scripts/build-quarter.sh
test "$(grep -c 'for level in country islandgroups regions provdists municities' scripts/publish-latest.sh)" = 2
grep -q '^want_islandgroups=1$' scripts/publish-latest.sh
grep -q 'for level in country islandgroups regions provdists municities' scripts/release-assets.sh
grep -q 'Added paths since' scripts/release-assets.sh
test -x scripts/topojson-islandgroups.sh
```

## R11 the README and AGENTS.md describe the level and show it

The docs name the file, the mapping and the image only while this change stands.

```sh
set -e
grep -q '^| `islandgroups/` |' README.md
grep -q 'images/islandgroups.svg' README.md
grep -q 'scripts/island-groups.csv' README.md
grep -q '^| `topojson-islandgroups.sh` |' AGENTS.md
grep -q '`islandgroups/` is the one' AGENTS.md
test "$(grep -c '<path' images/islandgroups.svg)" = 3
grep -q 'render islandgroups/lowres/islandgroups.0.001.json islandgroups.svg' scripts/sample-maps.sh
```
