# Checks

> The change's acceptance checks: each `## ` section is one, which only a deliberate revert could
> fail, so it stays out of the suite. `/sdlc:ship` reruns every one from the checkout root before
> it commits, and a check passes when its one `sh` block exits 0 and leaves the working tree as it
> found it. `sdlc.py` reads each section's name and that block, nothing else.

## R1: the build scripts take TAG QUARTER and refuse anything else

No arguments, or a quarter not written `YYYY-Nq`, prints the usage and exits 2 before anything is
fetched or deleted. Putting a hard-coded vintage back fails it.

```sh
for s in build-quarter topojson-country topojson-regions topojson-provdists topojson-municities; do
  for args in "" "v1.0.0 2026Q3"; do
    out=$(scripts/$s.sh $args 2>&1) && { echo "$s $args: exited 0"; exit 1; }
    case $out in usage:*) ;; *) echo "$s $args: $out"; exit 1;; esac
  done
done
! grep -n 'YEAR=' scripts/*.sh
```

## R3: latest/ holds every 3Q 2026 parent, in WGS84, with no null geometry

One file per parent in each format and resolution: the country, 18 regions, 88
provinces/districts and 1,642 municipalities/cities. Every lowres GeoJSON coordinate is inside the
Philippines in longitude/latitude, and no GeoJSON feature or TopoJSON geometry is null.

```sh
for fmt in geojson topojson; do for res in medres lowres; do
  for lv in "country 1" "regions 18" "provdists 88" "municities 1642"; do
    set -- $lv
    n=$(find latest/$fmt/$1/$res -name '*.json' | wc -l | tr -d ' ')
    [ "$n" = "$2" ] || { echo "$fmt/$1/$res: $n files, want $2"; exit 1; }
  done
done; done
find latest/geojson -path '*/lowres/*.json' -print0 | xargs -0 -n 200 jq -e -s '
  all(.[]; (.features // []) | all(.[];
    .geometry != null and
    ([.geometry | .. | arrays | select(length >= 2 and (.[0] | type) == "number")]
      | all(.[]; .[0] >= 114 and .[0] <= 128 and .[1] >= 4 and .[1] <= 22))))' >/dev/null
find latest/geojson -path '*/medres/*.json' -print0 | xargs -0 -n 200 jq -e -s \
  'all(.[]; (.features // []) | all(.[]; .geometry != null))' >/dev/null
find latest/topojson -name '*.json' -print0 | xargs -0 -n 200 jq -e -s \
  'all(.[]; [.objects[].geometries[]?] | all(.[]; .type != null))' >/dev/null
```

## R4: every latest/ child file holds exactly its parent's children

Each feature's parent code is the code in its file's name, and the ids are exactly the release's
children of that parent that have a shape (standard `PH_Adm4_BgySubMuns`, `geom_src <> 'none'`).
Reads the release CSVs that `fetch-shapefiles.sh` puts in `scripts/processed/2026-3q/`.

```sh
python3 -I - <<'PY'
import csv, glob, json, os, sys
src = "scripts/processed/2026-3q"
need = [f"{src}/PH_Adm{n}_{s}.csv" for n, s in [(2, "ProvDists"), (3, "MuniCities"), (4, "BgySubMuns")]]
missing = [p for p in need if not os.path.exists(p)]
if missing:
    sys.exit(f"run scripts/fetch-shapefiles.sh v1.0.0 2026-3q first; missing {missing}")
kids = {}
for n, path in zip((2, 3, 4), need):
    for r in csv.DictReader(open(path, encoding="utf-8")):
        if r.get("geom_src", "source") == "none":
            continue
        kids.setdefault((n, r[f"adm{n-1}_psgc"]), set()).add(r[f"adm{n}_psgc"])
bad = []
for d, n in [("regions", 2), ("provdists", 3), ("municities", 4)]:
    for fp in glob.glob(f"latest/geojson/{d}/lowres/*.json"):
        code = os.path.basename(fp).split("-")[2].split(".")[0]
        feats = json.load(open(fp)).get("features", [])
        if any(str(f["properties"][f"adm{n-1}_psgc"]) != code for f in feats):
            bad.append(f"{fp}: a feature's adm{n-1}_psgc is not {code}")
        if {str(f["id"]) for f in feats} != kids.get((n, code), set()):
            bad.append(f"{fp}: members differ from the release")
print("\n".join(bad[:20]))
sys.exit(1 if bad else 0)
PY
```

## R5, R7: only latest/'s medres and lowres are in the tree

No `hires/` file is tracked anywhere, `2011/`, `2019/` and `2023/` are gone, and `latest/` holds
only `geojson/`, `topojson/` and `manifest.json`, each format with medres and lowres only.

```sh
test -z "$(git ls-files -- ':(glob)**/hires/**')"
test -z "$(git ls-files -- 2011 2019 2023)"
test "$(ls latest | tr '\n' ' ')" = "geojson manifest.json topojson "
test -z "$(find latest/geojson latest/topojson -mindepth 2 -maxdepth 2 -type d ! -name medres ! -name lowres)"
```

## R6: latest/manifest.json says what latest/ is

```sh
jq -e '(.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and .psgc == "2026-3q"
  and .source.repo == "faeldon/philippines-psgc-shapefiles" and .source.tag == "v1.0.0"
  and (.built | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))' latest/manifest.json >/dev/null
test "$(grep -c '"version"' latest/manifest.json)" = 1
```

## R11: the renamed paths since 2023/ are 1 region file, 4 provdists and 82 municities

Generated from `2023/` at `195f6db2` and `latest/`, as the v1.0.0 notes are.

```sh
out=$(scripts/renamed-paths.sh 195f6db2 2023)
printf '%s\n' "$out" | grep -A2 '^### regions/' | grep -q '^0 removed, 1 added'
printf '%s\n' "$out" | grep -A2 '^### provdists/' | grep -q '^4 removed, 4 added'
printf '%s\n' "$out" | grep -A2 '^### municities/' | grep -q '^82 removed, 82 added'
printf '%s\n' "$out" | grep -q 'added `provdists-region-1800000000.0.001.json`'
```

## R13: the gate covers latest/ and names no vintage

```sh
grep -q "^check = \"find latest " .sdlc/config.toml
! grep -n '^check = .*2023' .sdlc/config.toml
```
