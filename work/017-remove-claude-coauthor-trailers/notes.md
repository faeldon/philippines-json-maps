# Notes

> What happened while this change was built that its intent, spec and plan don't say. Free-form,
> with one rule: anything left undone is an unticked `- [ ]` line. `/sdlc:ship` gives each one a
> disposition, carried to a `work/ideas.md` seed or dropped with a reason, and `sdlc.py ship`
> refuses while one is still unticked.

## The rewrite, 2026-10-25

`git filter-repo` 2.47.0 (Homebrew), in a `--no-local` mirror clone in the session scratchpad,
limited to the commits after `8eeead56` (see the deviation below):

```
git filter-repo --refs ^8eeead56… refs/heads/master refs/heads/017-remove-claude-coauthor-trailers \
  refs/tags/2023-4q refs/tags/v0.0.0 refs/tags/v1.0.0 --message-callback '
import re
new = re.sub(rb"(?mi)^Co-Authored-By: Claude[^\n]*\n?", b"", message)
return new.rstrip(b"\n") + b"\n" if new != message else message
'
```

filter-repo's report listed 24 hash-like strings it left alone because no commit has them, e.g.
`13733359` and `1999900000`. They are token counts in `Sdlc-Totals` trailers and a PSGC code, so
leaving them is correct.

The refs were brought back into the main repository with one `git update-ref --stdin`
transaction, which checked each ref's old value. The two sdlc notes were moved to the new v1.0.0
tag object with `git notes copy`, then `remove`.

### Old → new

| Commit | Old | New |
|---|---|---|
| Set the repo up for the sdlc plugin | `8492cec9` | `6b7a4895` |
| Refresh the sdlc setup for 1.1.0 | `cbe47d62` | `58729c04` |
| fix: build 2023 maps… | `195f6db2` | `209763ab` |
| Close 012 | `41ba8941` | `39e3f9f3` |
| feat: publish PSGC 3Q 2026… | `7f5884fb` | `2b823013` |
| Close 013 | `0032cb58` | `902bbd99` |
| Release 1.0.0 | `e91c3869` | `6f47f967` |
| docs: refresh the README… | `98f7be68` | `95e8b4a4` |
| Close 014 | `9779ef25` | `b155dae6` |
| perf: build the municities level in parallel | `134010c5` | `7d040562` |
| Close 015 | `4677bdb7` | `0b39f286` |
| chore: remove the LFS rule… | `cb221801` | `c29cba26` |
| Close 016 | `ce96881a` | `5cec5050` |

| Tag | Old object | New object | Points at |
|---|---|---|---|
| `2023-4q` | `f16e12d0` | `b52150e8` | `209763ab` |
| `v0.0.0` (local only) | `b82ef551` | `1bc43b8d` | `39e3f9f3` |
| `v1.0.0` | `8e1e2339` | `691ce8b7` | `6f47f967` |
| `2011`, `2019` | unchanged | | |

## Verification

- **R2, R3, R4 (tags):** `verify-rewrite.py <bundle clone> <main repo> commit-map 13`:
  > 13 commits: tree, author, committer and parents identical; messages differ only by the
  > trailer and mapped hashes. Tags 2023-4q, v0.0.0, v1.0.0 moved with the same name, tagger and
  > message; 2011, 2019 unchanged.

  - Given 12, it fails ("13 commits changed, expected 12"), so it isn't vacuous.
  - Spot check: Close 015 now reads "Its artifacts are in 7d040562", and `209763ab`'s message
    ends at its `Sdlc-Findings` line.
- **R1:** after the push and `git fetch origin`:
  - `git log --all -i --grep='Co-Authored-By: Claude'` finds 0 commits;
  - `git ls-remote origin`: `master` and `v1.0.0^{}` are at `6f47f967`, `2023-4q^{}` at
    `209763ab`, and `2011`/`2019` are unchanged.
- **R4 (assets):** for `2023-4q` and `v1.0.0`, every asset's name, size and GitHub `sha256:` digest
  matches the snapshot taken before the rewrite (7 assets each), and neither release is a draft.
- **R5:**
  - `git notes --ref=sdlc show v1.0.0` prints `published`;
  - the `sdlc-prepared` note is byte for byte the snapshot's;
  - `sdlc.py status` still shows v1.0.0 as the last release, with 014–016 unreleased.
- **R6:**
  - The `2023-4q` release notes now cite `209763ab80e8a3def8446fad878a726749128942`.
  - Issue bodies rewritten through the map: #12 (1 citation), #13 (14), #14 (2), #15 (1) and
    #16 (1).
  - A re-read of the live bodies, issues 1–16, finds no old SHA. No issue comment cited one.
  - `CHANGELOG.md` cites `209763ab`.
  - #17 is left alone: it cites the old SHAs on purpose, and ship re-syncs it from this folder.
- **R8:** both `checks.md` checks pass (`sdlc.py accept 017`). The trailer clause fails on a
  throwaway commit in a temporary clone.
- **R11:**
  - `~/philippines-json-maps-pre-017.bundle` verified ("complete history"), with every head, tag
    and `refs/notes/*`.
  - Cloning it back gave the old objects the verifier read.
- **R12:** the push sent `master` only up to `6f47f967`. The rewritten 014–016 commits stay local
  for `/sdlc:release` and `/sdlc:publish`. The push was `--atomic`, with
  `--force-with-lease` on all three refs, and ran on the maintainer's explicit yes.
- **R7:**
  - `.claude/settings.json` sets
    `"attribution": {"commit": "", "pr": "", "sessionUrl": false}`, per the settings reference
    (code.claude.com/docs/en/settings-reference#attribution).
  - Settings are read when a session starts, so this session's attribution reminder predates it.
    The evidence here is this change's own commit, which carries no trailer.
  - The first commit from a fresh session is the live test.
  - **R7's `AGENTS.md` rule was dropped** at the maintainer's call, after it was written. The
    setting turns attribution off at its source, which makes the rule redundant. The gate's
    trailer clause (R8) stays as the backstop for anything the setting doesn't cover, such as
    another tool or a hand-written commit.
  - `AGENTS.md` keeps the gate line, which mirrors `commands.check`, and the reworded release
    invariant (R9).

## Deviation from the plan

The first filter-repo run, over all history, changed **23** commits and moved `2019`.

- **Cause:** ten older commits, made in GitHub's web UI, carry GitHub's GPG signature
  (`committer GitHub`, `gpgsig`). filter-repo strips signatures by default, which changes their
  hashes, and 2.47.0 has no option to keep them.
- **Fix:** none of the 13 target commits is signed, so I discarded that mirror and rewrote only
  the commits after `8eeead56` (`--refs ^8eeead56 …`).
- **Result:** exactly 13 changed, and every signed commit, and `2011`/`2019`, kept its hash.

The verifier also fails a commit whose header set changed, a dropped `gpgsig` aside, so a
silently stripped signature would show.

## Rollback

- **Before the push:** restore from `~/philippines-json-maps-pre-017.bundle`, or `update-ref` back
  to the old SHAs above. Not needed.
- **Now:** the old objects are in the bundle. Putting them back on `origin` would be the same push
  with old and new swapped, and would diverge anyone who has fetched since. Keep the bundle until
  this change has been released and nobody has reported a problem, then delete it.
