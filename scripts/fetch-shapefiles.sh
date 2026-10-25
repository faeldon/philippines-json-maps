#!/usr/bin/env bash
# Fetch one PSGC quarter's shapefiles from faeldon/philippines-psgc-shapefiles into
# scripts/processed/<quarter>/, verified against the release's SHA256SUMS.
#
# Usage: fetch-shapefiles.sh <release tag> <quarter>    e.g. psgc-2023-4q 2023-4q
#
# Copies from a local release-staging/<quarter>/ checkout of the shapefiles repo when one exists
# and verifies (PSGC_STAGING overrides where to look), else downloads from the GitHub release.
set -euo pipefail

TAG="$1"
QUARTER="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/scripts/processed/$QUARTER"
RELEASE="https://github.com/faeldon/philippines-psgc-shapefiles/releases/download/$TAG"
FILES=(
  PH_Adm1_Regions.shp.zip
  PH_Adm2_ProvDists.shp.zip
  PH_Adm3_MuniCities.shp.zip
  PH_Adm4_BgySubMuns.shp.zip
  PH_Adm1_Regions.csv
  PH_Adm2_ProvDists.csv
  PH_Adm3_MuniCities.csv
  PH_Adm4_BgySubMuns.csv
)

# Exit 0 when every file in FILES is in $1 and matches its SHA256SUMS.
verified() {
  local f
  [ -f "$1/SHA256SUMS" ] || return 1
  for f in "${FILES[@]}"; do [ -f "$1/$f" ] || return 1; done
  (cd "$1" && shasum -a 256 -c --ignore-missing --quiet SHA256SUMS >/dev/null 2>&1)
}

mkdir -p "$DEST"
if verified "$DEST"; then
  echo "[FETCH] $QUARTER: verified in $DEST, nothing fetched"
  exit 0
fi

# The shapefiles repo checked out beside this repo's main checkout (works from a worktree too).
MAIN="$(dirname "$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)")"
STAGING="${PSGC_STAGING:-$MAIN/../philippines-psgc-shapefiles/release-staging}/$QUARTER"

if [ -f "$STAGING/meta.json" ] \
  && [ "$(jq -r .publication "$STAGING/meta.json")" = "$QUARTER" ] \
  && verified "$STAGING"; then
  for f in SHA256SUMS "${FILES[@]}"; do cp "$STAGING/$f" "$DEST/$f"; done
  echo "[FETCH] $QUARTER: copied from staging $STAGING"
else
  for f in SHA256SUMS "${FILES[@]}"; do curl -fsSL -o "$DEST/$f" "$RELEASE/$f"; done
  echo "[FETCH] $QUARTER: downloaded from release $TAG"
fi

if ! verified "$DEST"; then
  for f in $(cd "$DEST" && shasum -a 256 -c --ignore-missing SHA256SUMS 2>/dev/null | sed -n 's/: FAILED.*//p'); do
    rm -f "$DEST/$f"
    echo "[FETCH] $f failed its checksum and was deleted" >&2
  done
  exit 1
fi
echo "[FETCH] $QUARTER: ${#FILES[@]} files verified against SHA256SUMS"
