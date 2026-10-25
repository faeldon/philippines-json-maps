# Changelog

Every release of these maps, newest first. Each release holds one zip per format and resolution
(GeoJSON and TopoJSON; hires, medres and lowres) and a `SHA256SUMS` file; the newest quarter's
medres and lowres are also in [`latest/`](latest/). A release is never replaced: a new PSGC quarter
is a new release.

For the PSA updates each source release reflects, see the
[Changelog of philippines-psgc-shapefiles](https://github.com/faeldon/philippines-psgc-shapefiles/blob/main/CHANGELOG.md).

| Release | Published | PSGC | Built from | Notes |
| :------ | :-------- | :--- | :--------- | :---- |
| [v1.0.0](https://github.com/faeldon/philippines-json-maps/releases/tag/v1.0.0) | 2026-10-25 | 3Q 2026 | [philippines-psgc-shapefiles `v1.0.0`](https://github.com/faeldon/philippines-psgc-shapefiles/releases/tag/v1.0.0) | `latest/` replaces the per-year directories, which moved to the releases below. Adds the Negros Island Region and Sulu's move to Region IX, so their files are renamed (listed in the release notes). |
| [2023-4q](https://github.com/faeldon/philippines-json-maps/releases/tag/2023-4q) | 2026-10-25 | 4Q 2023 | [philippines-psgc-shapefiles `psgc-2023-4q`](https://github.com/faeldon/philippines-psgc-shapefiles/releases/tag/psgc-2023-4q) | Formerly `2023/`, as `master` held it at `195f6db2`. |
| [2019](https://github.com/faeldon/philippines-json-maps/releases/tag/2019) | 2026-10-25 | December 2018 | OCHA's administrative levels 0 to 3 shapefiles, on the Humanitarian Data Exchange | Formerly `2019/`, as `master` held it at `685d702b`. Levels are `regions`, `provinces`, `municties` and `barangays`. |
| [2011](https://github.com/faeldon/philippines-json-maps/releases/tag/2011) | 2026-10-25 | not matched to a quarter | [GADM](https://gadm.org), the 2011 map | Formerly `2011/`, as `master` held it at `1d02f67d`. Adds `geojson-full.zip` (unsimplified GeoJSON) and `extras.zip` (its images). |
