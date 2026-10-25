# Contributing to philippines-json-maps

Thanks for helping. Most contributions here are reports: an area filed under the wrong parent, a
missing city, a name or boundary that's out of date. Those are as valuable as code.

## Reporting a data error

Use the [issue tracker](https://github.com/faeldon/philippines-json-maps/issues/new/choose) and
pick **Data error**. Search the open issues first; someone may have reported it already. A report
we can act on names:

1. **The file**, as a path in `latest/` or a raw URL, and which release or `latest/manifest.json`
   version you used.
2. **The PSGC code** of the area that's wrong, and of its parent if the problem is where it's
   filed.
3. **What's wrong**: filed under the wrong parent, missing, in two files, a wrong name, or a wrong
   shape.
4. **What it should be**, and where that comes from: a PSA PSGC publication, a law, or another
   source.

These maps are built from
[faeldon/philippines-psgc-shapefiles](https://github.com/faeldon/philippines-psgc-shapefiles), so
a wrong code, name or boundary is usually wrong there too. If you can tell it is, report it there;
either place is fine, and it gets fixed at the source either way.

## Requests

Pick **Request** for a newer PSGC quarter, another format, or a different way of splitting the
files (for example, all of a level in one file). Say what you'd use it for: it decides what's
worth building.

## Pull requests

Please open an issue before a large pull request, so we can agree on the approach first.

1. Fork the repository and branch from `master`.
2. Make your change. If it changes how the maps are built, rebuild the quarter with
   `scripts/build-quarter.sh` and publish it with `scripts/publish-latest.sh` (see the README),
   and say in the pull request which codes should change.
3. Run the gate in [AGENTS.md](../AGENTS.md) before you push: every file in `latest/` must parse,
   and no build directory, `dist/` or `hires/` file may be committed.
4. Open the pull request against `master`, describing what changed and why, and linking the issue.

Keep each pull request to one change. A change to the maps' file names breaks everyone's links,
so it needs a reason, and a release that lists it.

<a name="ai-assisted"></a>
## AI-assisted contributions

Pull requests written with an AI coding assistant are welcome. The person who submits one is
responsible for it: review every line before you open it, as you would your own. A change that
rebuilds `latest/` follows the same invariants in [AGENTS.md](../AGENTS.md) as any other.

**IMPORTANT**: By submitting a patch, you agree to allow the project owners to license your work
under the terms of the [MIT License](../LICENSE).
