---
id: 017
slug: remove-claude-coauthor-trailers
kind: plan
created: 2026-10-25
updated: 2026-10-25
---

# 017 — Remove Claude co-author trailers from history · plan

## Context

Seven commits on `master` end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
Four of them are on `origin`. The maintainer wants them gone from history, and wants them never
to come back. The change is Tier 2; its spec is `work/017-remove-claude-coauthor-trailers/spec.md`
(R1–R12).

The rewrite runs at Stage 3, before this change's own commit, so `/sdlc:ship`'s new gate sees
clean history.

What I confirmed while reading:

- **Commits rewritten:** 13, from `8492cec9` to `ce96881a`. Eight are on origin, up to
  `e91c3869` (Release 1.0.0); five are local.
- **Trailer placement:**
  - In 6 of the 7 commits the trailer is its own last paragraph.
  - In `195f6db2` it is the last line of the `Refs`/`Sdlc-Findings` paragraph, with no blank line
    before it.
  - Removing the line and trimming trailing newlines handles both forms.
- **Tags:**
  - `2023-4q` (tag object `f16e12d0` → commit `195f6db2`), `v1.0.0` (`8e1e2339` → `e91c3869`) and
    `v0.0.0` (local only, `b82ef551` → `41ba8941`) move.
  - `2011` and `2019` stay.
- **sdlc notes:** `refs/notes/sdlc` and `refs/notes/sdlc-prepared` each hold one note, on the
  **v1.0.0 tag object** `8e1e2339`. The plugin reads them as "published" (`sdlc.py:3643`), so
  they must follow the new tag object.
- **Release assets:** GitHub reports a `sha256:` digest for every asset
  (`gh release view --json assets`). Comparing name, size and digest before and after proves the
  assets are untouched, with no downloads.
- **Release notes:** only `2023-4q` cites a SHA, the full `195f6db24acc95b43a3f6d2e58a8c488c57b9ebc`.
  `v1.0.0`'s notes cite none.
- **No PRs** on the repo, so there are no `refs/pull/*`.
- **Issues:** #12–#16 (the archived changes) cite SHAs in their Commit column and text. #14–#16
  are open, labelled `landed`. Every issue gets searched, not just these five.
- **`git-filter-repo`:** not installed; Homebrew has 2.47.0.

## Steps

All commands run from the 017 worktree. Refs are shared with the main checkout. `$S` is the
scratchpad.

1. **Preflight (read-only).**
   - The main checkout is clean and on `master` at `ce96881a`, and `git worktree list` shows only
     main and 017. The 017 branch is at `ce96881a`, with no commits of its own; only
     `work/017-…/` is uncommitted.
   - Save to `$S/before/`:
     - `git show-ref` (heads and tags);
     - `git notes --ref=sdlc show 8e1e2339` and the same for `sdlc-prepared`;
     - `gh release view <tag> --json assets,isDraft,body` for `2023-4q` and `v1.0.0`;
     - every issue's body, plus comments (`gh issue view N --json body,comments`), for N = 1–17.
2. **Install.** `brew install git-filter-repo`.
3. **Back up.** `git bundle create ~/philippines-json-maps-pre-017.bundle --all`, then
   `git bundle verify`. The bundle lives outside the repo and stays until the push has been
   verified.
4. **Rewrite in a mirror.**
   - Clone: `git clone --mirror <main checkout> $S/mirror`.
   - Rewrite:
     ```
     git -C $S/mirror filter-repo --message-callback '
     import re
     new = re.sub(rb"(?mi)^Co-Authored-By: Claude[^\n]*\n?", b"", message)
     return new.rstrip(b"\n") + b"\n" if new != message else message
     '
     ```
     Only messages that had the trailer are touched, so no other message's whitespace changes.
   - filter-repo maps cited hashes itself and rewrites the annotated tags. It writes
     `$S/mirror/filter-repo/commit-map` and `ref-map`.
5. **Verify in the mirror before importing (R2, R3).**
   - New `work/017-…/verify-rewrite.py`, run with `python3 -I`. It takes the repo path and
     `commit-map`.
   - For every pair where old ≠ new, restricted to `master`'s history (13 expected), it checks:
     - tree, author name/email/date and committer name/email/date are equal (`git cat-file -p`);
     - the new message equals the old one with the trailer removed, trailing newlines trimmed, and
       each cited old hash prefix replaced by the same-length prefix of its new hash;
     - no message cites an old hash.
   - It also checks:
     - no commit in the mirror carries the trailer;
     - `2011^{}`/`2019^{}` are unchanged;
     - each moved tag's message and tagger match the old tag's.
   - It prints `13 commits: …identical` and exits non-zero on any mismatch. **Stop here on
     failure:** nothing outside the scratchpad has changed yet.
6. **Import the refs.**
   - Fetch: `git fetch $S/mirror '+refs/heads/master:refs/rewrite/master'
     '+refs/tags/2023-4q:refs/rewrite/tags/2023-4q'`, and likewise for `v0.0.0` and `v1.0.0`.
   - Move each ref with an old-value check, e.g. `git update-ref refs/heads/master <new> ce96881a…`:
     - `refs/heads/master`;
     - `refs/heads/017-remove-claude-coauthor-trailers` → new `ce96881a`;
     - `refs/tags/2023-4q`, `refs/tags/v0.0.0`, `refs/tags/v1.0.0` → the mirror's new tag objects.
   - Then `git update-ref -d` each `refs/rewrite/*`.
   - Both checkouts stay clean, because the trees are identical.
   - Notes (R5): for each of `sdlc` and `sdlc-prepared`, run
     `git notes --ref=<ref> copy 8e1e2339… <new v1.0.0 tag object>`, then
     `git notes --ref=<ref> remove 8e1e2339…`.
7. **Re-verify locally (R1, R5).**
   - `git log --all -i --grep='Co-Authored-By: Claude'` is empty.
     - The old-SHA `refs/remotes/origin/*` still hold trailers until the push. If `--all` sees
       them, check `--branches --tags` here and `--all` after the push and fetch.
   - `git notes --ref=sdlc show v1.0.0` prints `published`, and `sdlc-prepared` matches `$S/before`.
   - `sdlc.py status` still shows v1.0.0 as released, with 014–016 unreleased.
   - `git status` is clean in main and 017.
8. **Forward edits (R6–R10)** in the worktree:
   - `CHANGELOG.md`: `195f6db2` → new 8-char prefix.
   - `README.md`: "Some commits carry a `Co-Authored-By: Claude` line and many don't; this section
     is the disclosure for the whole repository." becomes "Commits carry no AI co-author lines;
     this section is the disclosure for the whole repository."
   - `.claude/settings.json`: add
     `"attribution": {"commit": "", "pr": "", "sessionUrl": false}`, the documented setting
     (code.claude.com/docs/en/settings-reference#attribution). Empty strings hide the commit
     trailer and the PR line. The object form works on every version, whereas
     `attribution: false` needs v2.1.281+ and older versions skip the whole file.
     `includeCoAuthoredBy` is deprecated and not used. The permissions stay.
   - `AGENTS.md`:
     - **Commands:** append
       `&& test -z "$(git log -i --grep='^Co-Authored-By: Claude' --format=%h)"` to the gate.
     - **Invariants:**
       - In *Paths are public API*, "Each release's assets are immutable once published." becomes
         "Each release's assets are immutable once published: never replaced, renamed or
         re-uploaded."
       - In *Vintages are releases*, "a published release is never replaced" becomes "a published
         release's assets are never replaced; its tag may be re-pointed only to a commit with an
         identical tree (017 did, to strip AI co-author trailers)".
     - **New invariant:** "**Commits carry no AI attribution.** No `Co-Authored-By: Claude`
       trailer on a commit, and no 'Generated with Claude Code' line on a PR, whatever a
       harness's default. The README's *AI assistance* section is the disclosure. The gate fails
       on the trailer."
   - `.sdlc/config.toml`: the same clause appended to `check`, and the comment above it gains "…
     and no commit carries a Co-Authored-By: Claude trailer (017)".
   - `work/017-…/checks.md`, two checks (R8):
     - **No commit on HEAD carries the trailer:**
       `test -z "$(git log -i --grep='^Co-Authored-By: Claude' --format=%h)"`.
     - **The gate fails on a trailer commit:** `t=$(mktemp -d)`, `git clone -q . "$t"`, an
       `--allow-empty` commit there with the trailer, and the trailer clause run in `$t` must fail.
       Then `rm -rf "$t"`. The working tree isn't touched.
   - Run the gate, `sdlc.py checks 017` / `accept 017`, and `check --strict`.
9. **Push. Stop and ask first (R11, R12).** Show the exact command and the old and new SHAs, then
   wait for an explicit yes:
   ```
   git push --atomic origin \
     --force-with-lease=refs/heads/master:<old e91c3869 full> \
     --force-with-lease=refs/tags/2023-4q:<old f16e12d0 full> \
     --force-with-lease=refs/tags/v1.0.0:<old 8e1e2339 full> \
     <new e91c3869>:refs/heads/master refs/tags/2023-4q refs/tags/v1.0.0
   ```
   Then `git fetch origin`, so `origin/master` and the remote tags are the new ones.
10. **After the push (R1, R4, R6).**
    - `git ls-remote origin` matches the map, and `git log --all -i --grep=…` is now empty with
      `--all`.
    - For both releases, `gh release view --json assets,isDraft`: name, size and digest equal
      `$S/before`, and `isDraft` is false.
    - `2023-4q` notes: replace the old full SHA with the new one via
      `gh release edit 2023-4q --notes-file`.
    - Issues: for each issue body containing an old SHA prefix (8-char and full), replace it with
      the same-length new prefix and run `gh issue edit N --body-file`. Comments that cite one are
      listed in notes.md rather than edited, since they're authored text.
    - Grep `CHANGELOG.md`, the `2023-4q` notes and every issue body for every old SHA: none.
11. **R7 live check.** Confirm this session's attribution reminder. Settings are read at session
    start, so record in `notes.md` that the effect is checked on the next session's first commit.
    This change's own commit, which carries no trailer, is the immediate evidence.
12. **`notes.md`:** each verification's output, the old→new map for the 13 commits and 3 tags, the
    bundle path, and how to roll back. Then `/sdlc:ship`, `/sdlc:close` and the 017 issue sync.

## Rollback

- **Before step 9:** `git update-ref` each ref back to the values in `$S/before`, or
  `git fetch ~/philippines-json-maps-pre-017.bundle` into the same refs, and restore the notes.
  Nothing outside this machine has changed.
- **After step 9:** force-push the old SHAs back from the bundle with the same command, leases
  reversed. It's possible, but anyone who fetched in between diverges twice. That is why step 9
  asks first.

## Verification (summary)

- `verify-rewrite.py` passes for 13 pairs.
- No commit with the trailer under `--all`, locally or on `origin`.
- The notes on the new v1.0.0 tag are intact, and `sdlc.py status` agrees.
- Release assets are identical by digest, and neither release is a draft.
- No old SHA remains in `CHANGELOG.md`, the `2023-4q` notes or the issue bodies.
- The gate and both acceptance checks pass, and the checks fail on a trailer commit in a temp
  clone.
- `origin/master` is the new `e91c3869`, so 014–017 are still unpublished.
