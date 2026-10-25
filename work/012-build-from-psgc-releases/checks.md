# Checks

> The change's acceptance checks: each `## ` section is one, which only a deliberate revert could
> fail, so it stays out of the suite. `/sdlc:ship` reruns every one from the checkout root before
> it commits, and a check passes when its one `sh` block exits 0 and leaves the working tree as it
> found it. `sdlc.py` reads each section's name and that block, nothing else.

## R1: nothing points at the archived source repo

Only putting the old links back could fail it.

```sh
! git grep -n -I 'altcoder/philippines-psgc-shapefiles' -- ':!2011' ':!2019' ':!work' ':!scripts/processed'
```

## R9: every 2023 child file holds exactly its parent's children

Each feature's parent code is the code in its file's name, and the ids are exactly the release's
children of that parent that have a shape. Reads the release CSVs that `fetch-shapefiles.sh` puts
in `scripts/processed/2023-4q/`; a revert to the old output fails it.

```sh
python3 -I - <<'PY'
import csv, glob, json, os, sys
src = "scripts/processed/2023-4q"
need = [f"{src}/PH_Adm{n}_{s}.csv" for n, s in [(2, "ProvDists"), (3, "MuniCities"), (4, "BgySubMuns")]]
missing = [p for p in need if not os.path.exists(p)]
if missing:
    sys.exit(f"run scripts/fetch-shapefiles.sh psgc-2023-4q 2023-4q first; missing {missing}")
kids = {}
for n, path in zip((2, 3, 4), need):
    for r in csv.DictReader(open(path, encoding="utf-8")):
        if r.get("geom_src", "source") == "none":
            continue
        kids.setdefault((n, r[f"adm{n-1}_psgc"]), set()).add(r[f"adm{n}_psgc"])
bad = []
for d, n in [("regions", 2), ("provdists", 3), ("municities", 4)]:
    for fp in glob.glob(f"2023/geojson/{d}/lowres/*.json"):
        code = os.path.basename(fp).split("-")[2].split(".")[0]
        doc = json.load(open(fp))
        feats = doc.get("features", [])
        if any(str(f["properties"][f"adm{n-1}_psgc"]) != code for f in feats):
            bad.append(f"{fp}: a feature's adm{n-1}_psgc is not {code}")
        if {str(f["id"]) for f in feats} != kids.get((n, code), set()):
            bad.append(f"{fp}: members differ from the release")
print("\n".join(bad[:20]))
sys.exit(1 if bad else 0)
PY
```

## R8, R11: WGS84 coordinates, no null geometries

Every lowres coordinate is inside the Philippines in longitude/latitude, and no feature lacks a
geometry. Output in metres or a shapeless row would fail it.

```sh
find 2023/geojson -path '*/lowres/*.json' -print0 | xargs -0 -n 200 jq -e -s '
  all(.[]; (.features // []) | all(.[];
    .geometry != null and
    ([.geometry | .. | arrays | select(length >= 2 and (.[0] | type) == "number")]
      | all(.[]; .[0] >= 114 and .[0] <= 128 and .[1] >= 4 and .[1] <= 22))))' >/dev/null
```

## R10: the 24 missing municipalities are filed

The 16 cities under no province appear in their province's or NCR district's file, and the 8
BARMM interim municipalities in `1999900000`'s.

```sh
for id in 1030500000 1030900000 1230800000 1430300000 1630400000 1731500000 330100000 331400000 \
          431200000 630200000 631000000 730600000 731100000 731300000 831600000 931700000; do
  n=$(cat 2023/geojson/provdists/lowres/*.json | jq -s --argjson id "$id" '[.[].features[]? | select(.id == $id)] | length')
  [ "$n" = 1 ] || { echo "$id appears $n times"; exit 1; }
done
jq -e '[.features[].id] | map(select(. >= 1999901000 and . <= 1999908000)) | length == 8' \
  2023/geojson/provdists/lowres/municities-provdist-1999900000.0.001.json >/dev/null
```

## R11: Manila's barangay file is filled, without its sub-municipalities

```sh
jq -e '(.features | length) == 899
  and ([.features[].id] | map(select(. >= 1380601000 and . <= 1380614000 and . % 1000 == 0)) | length == 0)' \
  2023/geojson/municities/lowres/bgysubmuns-municity-1380600000.0.001.json >/dev/null
```

## R12, R13: one renamed file, nothing else added, removed or touched

The only 2023 paths added or removed against `master` are the six `1909900000` files and their six
`1999900000` replacements, and `2011/` and `2019/` are unchanged.

```sh
base=$(git merge-base HEAD master)
changes=$( { git diff --name-status "$base" -- 2023; git ls-files --others --exclude-standard -- 2023 | sed 's/^/A\t/'; } | grep -v '^M')
test "$(printf '%s\n' "$changes" | grep -c .)" = 12
test "$(printf '%s\n' "$changes" | grep '^D' | grep -c 'municities-provdist-1909900000')" = 6
test "$(printf '%s\n' "$changes" | grep '^A' | grep -c 'municities-provdist-1999900000')" = 6
git diff --quiet "$base" -- 2011 2019
test -z "$(git ls-files --others --exclude-standard -- 2011 2019)"
```
