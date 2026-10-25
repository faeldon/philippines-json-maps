# Checks

> The change's acceptance checks: each `## ` section is one, which only a deliberate revert could
> fail, so it stays out of the suite. `/sdlc:ship` reruns every one from the checkout root before
> it commits, and a check passes when its one `sh` block exits 0 and leaves the working tree as it
> found it. `sdlc.py` reads each section's name and that block, nothing else.

## Every link in the docs resolves

Offline. In `README.md`, `CHANGELOG.md` and every Markdown file under `.github/`:
- every relative link or image exists;
- every `#anchor` is a heading or `<a name>` in its file;
- every `raw.githubusercontent.com/.../master/<path>` link is a file in this tree;
- every `releases/latest/download/<name>` link is an asset the releases publish;
- no link lacks its scheme (`www.…`), and nothing says `.guthub`.

A link to a moved file, or the old README's `www.leafletjs.com`, fails it.

```sh
python3 -I - <<'PY'
import glob, os, re, sys
files = ["README.md", "CHANGELOG.md"] + sorted(glob.glob(".github/**/*.md", recursive=True))
assets = {f"{f}-{r}.zip" for f in ("geojson", "topojson") for r in ("hires", "medres", "lowres")} | {"SHA256SUMS"}
raw = "https://raw.githubusercontent.com/faeldon/philippines-json-maps/master/"
dl = "https://github.com/faeldon/philippines-json-maps/releases/latest/download/"
def slugs(text):
    out = {re.sub(r"[^\w\- ]", "", h.strip().lower()).replace(" ", "-") for h in re.findall(r"^#+ (.+)$", text, re.M)}
    return out | set(re.findall(r'<a name="([^"]+)"', text))
bad = []
for f in files:
    text = open(f, encoding="utf-8").read()
    links = re.findall(r"\]\(([^)\s]+)\)", text) + re.findall(r'src="([^"]+)"', text) + re.findall(r"<(https?://[^>]+)>", text)
    for link in links:
        if link.startswith(raw):
            if not os.path.isfile(link[len(raw):]):
                bad.append(f"{f}: {link} is not in the tree")
        elif link.startswith(dl):
            if link[len(dl):] not in assets:
                bad.append(f"{f}: {link} is not a release asset")
        elif link.startswith("www."):
            bad.append(f"{f}: {link} has no scheme")
        elif link.startswith("#"):
            if link[1:] not in slugs(text):
                bad.append(f"{f}: anchor {link} not found")
        elif not re.match(r"[a-z]+:", link):
            path, _, anchor = link.partition("#")
            target = os.path.normpath(os.path.join(os.path.dirname(f), path))
            if not os.path.exists(target):
                bad.append(f"{f}: {link} does not exist")
            elif anchor and anchor not in slugs(open(target, encoding="utf-8").read()):
                bad.append(f"{f}: anchor #{anchor} not in {target}")
    if ".guthub" in text:
        bad.append(f"{f}: says .guthub")
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
```

## The leftovers from before are gone

No git-lfs rule for shapefiles, no Probot configs, no 2019-era sample images, and the issue
templates are the two for this repository.

```sh
test ! -e .gitattributes
test ! -e .github/lock.yml && test ! -e .github/issue_close_app.yml
test -z "$(ls images/*.png 2>/dev/null)"
test "$(ls .github/ISSUE_TEMPLATE | tr '\n' ' ')" = "data_error.md request.md "
grep -q '^labels: bug$' .github/ISSUE_TEMPLATE/data_error.md
```
