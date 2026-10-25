# Plan: 016-remove-repo-cruft

## Context

Change 016 (Tier 1, issue #16) removes files that still describe how the repo worked before change
012, when the shapefiles were zipped in the tree. Nothing under `latest/` changes.

I swept every tracked file outside `latest/` with `git ls-files` and grepped each one for a reader.
Four things have no reader or job left:

| File | Why it goes |
|---|---|
| `scripts/.gitattributes` | Sends `*.zip` through LFS, but no zip is tracked and nothing uses LFS |
| `.gitignore` line `scripts/2023/processed/` | `scripts/2023/` no longer exists. The `# Input Data ` header also has a trailing space |
| `.github/ISSUE_TEMPLATE.md` | Legacy single template. The `ISSUE_TEMPLATE/` folder supersedes it |
| `scripts/release-legacy.sh` | Made the one-off releases `2023-4q`, `2019` and `2011`, all published. Nothing runs it now |

Everything else stays, because each has a reader:

- `.sdlc/*`: plugin config and state. `setup.json` is the plugin's record of setup.
- `.claude/settings.json`: permission allowlist.
- `CLAUDE.md`: imports `AGENTS.md`.
- `images/*.svg`: shown in the README and redrawn by `sample-maps.sh`.
- `.github/CODE_OF_CONDUCT.md`: linked from the README.
- `CHANGELOG.md`, `LICENSE` and the `PULL_REQUEST_TEMPLATE.md` are all in use.
- Untracked `2026-3q/`, `dist/` and `scripts/processed/`: needed for releasing, and already ignored.

## Decisions (resolving the intent's open questions)

- **Blank issues:** turn them off with `ISSUE_TEMPLATE/config.yml`, plus a contact link to
  `CONTRIBUTING.md`. You chose this.
- **The gate's `scripts/20*` guard stays.** `.sdlc/REVIEW.md:48` records the incident it guards
  against: `8bea49f3` committed a full second copy under `scripts/2023/`. `.sdlc/SDLC.md:244`
  documents the guard, it costs nothing, and the reason for it outlives the directory.
- **Sweep:** finds `release-legacy.sh`, which you said to remove. Nothing else turns up.

## Steps

1. `git rm scripts/.gitattributes`.
2. Edit `.gitignore`: delete `scripts/2023/processed/` and change `# Input Data ` to
   `# Source data: fetched shapefiles and CSVs`. Leave every other pattern as is.
3. `git rm .github/ISSUE_TEMPLATE.md` and create `.github/ISSUE_TEMPLATE/config.yml`:
   ```yaml
   blank_issues_enabled: false
   contact_links:
     - name: Contributing guide
       url: https://github.com/faeldon/philippines-json-maps/blob/master/.github/CONTRIBUTING.md
       about: What makes a data error or request easy to act on.
   ```
4. `git rm scripts/release-legacy.sh`. In `AGENTS.md` (lines 46–47), replace the sentence
   "`scripts/release-legacy.sh` made the one-off releases `2023-4q`, `2019` and `2011` from
   history." with "The one-off releases `2023-4q`, `2019` and `2011` were made from history by a
   script since removed (see change 013)." `CHANGELOG.md` already explains those releases.
5. Update `work/016-remove-repo-cruft/intent.md`:
   - Strike the three open questions with their resolutions, in the form
     `- ~~Q?~~ Resolved: …`.
   - Add the removal of `release-legacy.sh` to Approach.
   - Name nit **013-1** in Approach as made moot, so `/sdlc:ship` retires it.
6. No commit. `/sdlc:ship` does that.

## Verification

- Run the gate (`commands.check` from `AGENTS.md`). It must pass.
- `git check-attr -a scripts/x.zip` prints nothing.
- `git status --ignored --short` still lists `2026-3q/`, `dist/` and `scripts/processed/` as
  ignored (`!!`).
- `grep -rn 'release-legacy\|gitattributes\|scripts/2023/processed' --exclude-dir=latest --exclude-dir=.git .`
  finds nothing outside `work/` and the historical note in `.sdlc/REVIEW.md`.
- `git diff --stat master -- latest` is empty.
- Parse the new `config.yml` with `ruby -ryaml -e 'YAML.load_file(ARGV[0])'` (or `yq`).
