---
id: 017
slug: remove-claude-coauthor-trailers
kind: spec
created: 2026-10-25
updated: 2026-10-25
---

# 017 — Remove Claude co-author trailers from history · spec

> Tier 2 only. Reads from intent.md; read by plan.md. If you can't write a testable requirement
> list, the intent isn't understood yet — go back to Stage 1 rather than designing around the fog.

## Requirements

1. **R1. No trailer anywhere.**
   - After the rewrite, `git log --all -i --grep='Co-Authored-By: Claude'` is empty in the main
     checkout.
   - `git ls-remote origin` names only rewritten commits: `master` is at the new `e91c3869`,
     `2023-4q^{}` at the new `195f6db2`, and `v1.0.0^{}` at the new `e91c3869`.
2. **R2. Content identical.**
   - For every pair in filter-repo's `commit-map`, the old and new commits have the same tree,
     author, author date, committer and committer date.
   - Each new message equals the old one with the trailer line, and the blank line before it if
     it's left trailing, removed, and with cited hashes mapped.
   - A script over the map checks all 13 pairs and reports 13 identical.
3. **R3. Cited hashes follow.**
   - Hashes in rewritten messages (`Its artifacts are in 134010c5`, `as master held it at
     195f6db2`) name the new commits.
   - No rewritten message cites a hash from the old side of the map.
4. **R4. Tags move, assets don't.**
   - `2023-4q`, `v0.0.0` and `v1.0.0` are new annotated tags with the same name, message and
     tagger, each pointing at the mapped commit.
   - `2011` and `2019` are byte for byte unchanged.
   - Every asset of the `2023-4q` and `v1.0.0` releases downloads and matches the release's own
     `SHA256SUMS`, and their asset names and counts are as before.
5. **R5. The plugin's notes survive.** `git notes --ref=sdlc show v1.0.0` and
   `git notes --ref=sdlc-prepared show v1.0.0` print what they printed before the rewrite.
   `sdlc.py status` still treats v1.0.0 as published.
6. **R6. Docs and records cite the new SHAs.**
   - `CHANGELOG.md`'s `195f6db2`, the `2023-4q` release notes' full SHA, and the bodies of issues
     #12–#16 are rewritten through the commit-map.
   - No old SHA from the map remains in any of them.
7. **R7. No new trailers.**
   - `.claude/settings.json` turns off Claude Code's commit and PR attribution, using the setting
     Claude Code currently documents (confirmed against its docs at build).
   - `AGENTS.md` says commits and PRs carry no AI co-author or "Generated with" lines. Per the
     attribution reminder, the user's instructions in CLAUDE.md take precedence over it.
8. **R8. The gate catches one.**
   - `commands.check`, and its copy in `AGENTS.md`'s Commands block, also fails when
     `git log -i --grep='^Co-Authored-By: Claude'` finds anything on `HEAD`.
   - Proven both ways in `checks.md`: it passes on the rewritten history, and fails on a throwaway
     branch carrying a trailer commit.
9. **R9. The invariant says what it means.**
   - *Paths are public API* and *Vintages are releases* are reworded: a published release's assets
     are immutable and never replaced or re-uploaded.
   - Its tag may be re-pointed only to a commit with the identical tree, as this change did.
10. **R10. The disclosure stays true.**
    - The README's "AI assistance" section drops "Some commits carry a `Co-Authored-By: Claude`
      line and many don't".
    - It still says the repo is developed with Claude through Claude Code, and that this section is
      the disclosure for the whole repository.
11. **R11. Reversible until pushed.**
    - Before anything is rewritten, `git bundle create` saves every ref (heads, tags,
      `refs/notes/*`) to a file outside the repo, and `git bundle verify` passes.
    - The force-push names the expected old values (`--force-with-lease=<ref>:<old sha>`) and runs
      only on its own explicit approval.
12. **R12. Unreleased work stays unreleased.**
    - The force-push sends `master` only up to the new `e91c3869`, the commit `origin` already has
      in its old form.
    - The rewritten 014–016 commits and this change stay local until `/sdlc:release` and
      `/sdlc:publish`.

## Design

The rewrite runs at Stage 3, from this worktree. It happens **before** this change's own commit,
so `/sdlc:ship` runs the new gate over clean history, and `/sdlc:close` fast-forwards as usual.
The 017 branch has no commits yet: its uncommitted edits sit on `ce96881a`, whose tree the rewrite
keeps, so they survive untouched.

1. **Install and back up.**
   - `brew install git-filter-repo`.
   - `git bundle create ~/philippines-json-maps-pre-017.bundle --all`, which takes in heads, tags
     and `refs/notes/*`. Then `git bundle verify`.
   - Record `git notes --ref=sdlc show v1.0.0` and the same for `sdlc-prepared`.
2. **Rewrite in a mirror, not in the checkout.**
   - `git clone --mirror` the main checkout into the scratchpad, then run
     `git filter-repo --message-callback` there, dropping lines matching
     `^Co-Authored-By: Claude.*$` and a resulting trailing blank line.
   - A fresh mirror is what filter-repo expects. It never touches the main checkout's ignored
     `2026-3q/`, `dist/` or `scripts/processed/`, and its reflog-expiring `gc` stays inside the
     mirror.
   - Keep `filter-repo/commit-map` and `ref-map`.
3. **Bring the refs back.**
   - Fetch the mirror's objects into the main checkout.
   - Point `master` and `017-remove-claude-coauthor-trailers` at their mapped commits with
     `git update-ref <ref> <new> <old>`. Both checkouts stay clean, because the trees are
     identical.
   - Replace the three moved tags with the mirror's tag objects.
   - Re-add the two notes to the new `v1.0.0` tag object with `git notes --ref=… add -f -m`, and
     remove them from the old one.
4. **Prove it (R1–R5).** Run a `scripts`-free check, kept in the change folder, over `commit-map`:
   trees, author and committer data and messages per pair, grep for the trailer, the old hashes
   absent from messages, `2011` and `2019` unchanged, notes shown. Its output is recorded in
   `notes.md`.
5. **Forward edits (R6–R10)** in this worktree:
   - `CHANGELOG.md`'s SHA, through the map.
   - `README.md`.
   - `.claude/settings.json`.
   - `AGENTS.md`: the rule, the invariant wording and the gate command.
   - `.sdlc/config.toml`: the gate, with its comment saying why.
6. **Push (R11, R12), on its own approval.**
   - `git push origin --force-with-lease=master:e91c3869… <new e91c3869>:refs/heads/master`.
   - `git push origin --force-with-lease=refs/tags/2023-4q:f16e12d0…
     --force-with-lease=refs/tags/v1.0.0:8e1e2339… refs/tags/2023-4q refs/tags/v1.0.0`.
   - `v0.0.0` was never on `origin` and stays local.
7. **After the push (R4, R6).**
   - Edit the `2023-4q` release notes' SHA with `gh release edit --notes-file`.
   - Rewrite issues #12–#16 through the map with `gh issue edit --body-file`.
   - Download both releases' assets and check them against `SHA256SUMS`.
8. **Then `/sdlc:ship` and `/sdlc:close`** as for any change, and the issue syncs for 017 last.

## Contracts touched

- **Vintages are releases / "Each release's assets are immutable once published" — CHANGED
  (policy edit).**
  - Today's wording, "a published release is never replaced", can be read to forbid moving a
    release's tag.
  - The new wording keeps what the invariant protects: the bytes people downloaded never change,
    and a new quarter is a new release.
  - It permits re-pointing a tag only to a commit with the identical tree. The reason: a tag names
    a tree, and the commit wrapper around it carries metadata that may need correcting.
  - Assets are not re-uploaded, renamed or deleted, and R4 proves it.
- **Paths are public API.** No path changes. Hotlinks through `.../master/latest/...` resolve by
  branch, so they keep working. Only links pinned to an old SHA break, once GitHub collects the
  old objects.
- **Output location and form, and the PSGC hierarchy.** Untouched: R2 proves every tree is
  identical.
- **Confirm before writing (review).** The rewrite is local and reversible from the bundle. The
  push is the one irreversible step, behind its own approval and a lease.

## Alternatives rejected

- **Rewriting only the five unpushed commits.** The user chose "all of it". Four trailers would
  stay on `origin`.
- **`git filter-branch --msg-filter`.** It's deprecated and slow, and it doesn't map the hashes
  cited in messages, so `Its artifacts are in 134010c5` would point at dead commits.
- **filter-repo in the main checkout with `--force`.** It resets the checkout and expires every
  reflog, which removes the cheapest undo. It also has to reason about two live worktrees. The
  mirror avoids all three.
- **Rewriting after `/sdlc:close`.** The new gate would then fail at ship on the trailers still in
  history, and the push and its proofs would happen after the change's folder had been archived,
  with nowhere to record them.
- **A `commit-msg` hook instead of a gate check.** Every clone needs `core.hooksPath` set, and it's
  silent where unset. The setting stops the trailers at the source. The gate is the backstop that
  fails visibly at the next ship, before anything reaches `master`.
- **Asking GitHub to purge the old objects.** The user decided against it. Nothing sensitive is in
  them.
- **Pushing all of `master`.** That would publish 014–016 outside a release.

## Verification

- `git log --all -i --grep='Co-Authored-By: Claude' --format=%h` is empty, and
  `git ls-remote origin` matches the mapped SHAs (R1).
- The pair-by-pair check prints `13 commits: tree, author, committer identical; messages differ
  only by the trailer` (R2, R3).
- `git cat-file -p` of each moved tag shows the same tag message and tagger and the new object.
  `2011` and `2019` resolve to the same IDs as before (R4).
- `gh release download` for `2023-4q` and `v1.0.0` into the scratchpad, then
  `shasum -a 256 -c SHA256SUMS` passes for every asset (R4).
- `git notes --ref=sdlc show v1.0.0` prints `published`, and `sdlc.py status` shows v1.0.0 as the
  last release (R5).
- `grep` of `CHANGELOG.md`, `gh release view 2023-4q` and issues #12–#16 for every old SHA in the
  map finds none (R6).
- R7 needs one live commit: an empty commit on a throwaway branch made through Claude Code carries
  no trailer. It's deleted afterwards and recorded in `notes.md`.
- `checks.md`: the gate passes on `HEAD`, and fails on a throwaway branch with a trailer commit
  (R8).
- The diff shows the `AGENTS.md` and README edits (R9, R10).
- `git bundle verify` passes before the rewrite (R11).
- `git ls-remote origin refs/heads/master` equals the mapped `e91c3869` (R12).
