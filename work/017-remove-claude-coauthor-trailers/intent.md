---
id: 017
slug: remove-claude-coauthor-trailers
tier: 2
impact: patch
stage: shipped
created: 2026-10-25
updated: 2026-10-25
shipped: 2026-10-25
idea:
depends_on:
serves: none
---

# 017 — Remove Claude co-author trailers from history

> Stage 1: why this change is worth making, in its originator's words. Read by `/sdlc:spec` at
> Tier 2, or by plan mode at Tier 1; `/sdlc:status` counts the open questions not yet struck.

## Problem

Seven commits on `master` end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`:

| | Commits |
|---|---|
| Pushed to GitHub | `8492cec9` Set the repo up for the sdlc plugin, `cbe47d62` Refresh the sdlc setup for 1.1.0, `195f6db2` fix: build 2023 maps…, `7f5884fb` feat: publish PSGC 3Q 2026… |
| Local, not pushed yet | `98f7be68` docs: refresh the README…, `134010c5` perf: build the municities level in parallel, `cb221801` chore: remove the LFS rule… |

The maintainer doesn't want them in the history. The repo already discloses AI assistance in the
README's "AI assistance" section, which is meant to cover the whole repository. That section
currently says "Some commits carry a `Co-Authored-By: Claude` line and many don't".

The trailers keep appearing because Claude Code's commit attribution adds them to every commit an
agent writes. `/sdlc:ship` passed that through as recently as `cb221801` today. Nothing in the
repo stops it: not a setting, not `AGENTS.md`, not the gate.

## Outcome

- `git log --all -i --grep='Co-Authored-By: Claude'` prints nothing, locally and on `origin`,
  including tags.
- Every rewritten commit keeps its tree, author, date and the rest of its message. Only the trailer
  line goes. For each old/new pair, `git diff <old> <new>` is empty.
- Each moved tag still names the same tree, and its GitHub release keeps its assets byte for byte.
  - Tags that move: `2023-4q`, `v0.0.0` and `v1.0.0`.
  - Tags that stay where they are: `2011` and `2019`, which come before the first trailer.
  - The assets are verified against each release's `SHA256SUMS`.
- Hashes cited in commit messages (`Its artifacts are in 134010c5`, `as master held it at
  195f6db2`) and in tracked docs (`CHANGELOG.md`'s `195f6db2`) name the rewritten commits.
- A new commit made with Claude Code in this repo carries no Claude trailer, and a commit that does
  carry one is caught before it reaches `origin`.
- The README's disclosure no longer mentions the trailers. It still discloses AI assistance.

## Affected

- **Area:** git history and tags on `master` and `origin`, release metadata on GitHub, the repo's
  Claude Code settings and its gate.
- **Files & components:**
  - Every commit from `8492cec9` on, about 25 of them.
  - Tags `2023-4q`, `v0.0.0` and `v1.0.0`.
  - The GitHub releases `2023-4q` and `v1.0.0` (each tag's target, and the release notes' cited
    SHA).
  - `CHANGELOG.md`, the README's "AI assistance" section, `.claude/settings.json`, `AGENTS.md`,
    and possibly `.sdlc/config.toml` (the gate).
  - The archived bodies of issues #12–#16, which cite commit SHAs.
- **Downstream:**
  - Anyone who has cloned or forked `master` since `8492cec9`: their next pull diverges.
  - `raw.githubusercontent.com/.../master/latest/...` hotlinks: unaffected, because they resolve
    by branch, not by SHA.
  - Anyone who pinned a URL to one of the rewritten SHAs: that link stops resolving once GitHub
    collects the old objects.
  - The four published releases: they keep their assets, but their tags point at new commits.
- **Contracts:**
  - *Vintages are releases*: "a published release is never replaced". This change re-points
    release tags without touching the assets, and the spec has to say whether that counts as
    replacing a release.
  - *Paths are public API*: no path changes.

## Constraints

- No file content changes anywhere in history: every rewritten commit's tree is identical to the
  original's.
- Release assets are not re-uploaded, renamed or deleted.
- `master` must be at a known state first. Nothing unpushed is lost, and no other change's branch
  or worktree is open when the rewrite runs (`status` shows 0 open), because every branch off the
  old history would need rebasing.
- Commit messages must keep their `Refs #N`, `Closes #N` and `Sdlc-*` trailers. `/sdlc:retro`
  reads them.
- Force-pushing `master` and tags is outward-facing and can't be undone. It runs once, under its
  own explicit approval, with a backup of the old refs.

## Open questions

- ~~Is re-pointing a release's tag "replacing" it under the *Vintages are releases* invariant, or
  does the invariant mean only the assets? Does the invariant's wording need to change, with its
  reasoning in the spec?~~ Resolved: the invariant is reworded (spec R9). Assets are immutable;
  a tag may be re-pointed only to a commit with the identical tree.
- ~~Which tool should do the rewrite? `git filter-repo --message-callback` rewrites abbreviated
  hashes in messages for you; `filter-branch` doesn't. Is filter-repo installed, or can it be?~~
  Resolved: filter-repo 2.47.0 from Homebrew (not installed yet), run in a mirror clone.
- ~~How should this change's own commit relate to the rewrite? Its folder is committed on a branch
  off the history being rewritten. Does the rewrite happen at close, after the change lands, or
  before the change's commit?~~ Resolved: before, at Stage 3. The branch has no commits yet and
  the rewrite keeps `ce96881a`'s tree, so the uncommitted work survives, and ship's gate sees
  clean history.
- ~~Should the published notes of the `2023-4q` and `v1.0.0` releases ("as `master` held it at
  `195f6db2`") be edited to the new SHA? Editing notes isn't changing assets, but it does touch a
  published release.~~ Resolved: yes. Only `2023-4q`'s notes cite a SHA; they're edited through
  the commit-map (R6).
- ~~Should the archived issues #12–#16, which cite SHAs, be re-synced with the new hashes, or left
  citing the old ones?~~ Resolved: their SHAs are rewritten through the commit-map with
  `gh issue edit` (R6).
- ~~What prevents a repeat?~~ Resolved:
  - the attribution setting in `.claude/settings.json`;
  - a rule in `AGENTS.md`;
  - a gate check over `git log` (R7, R8).

  A `commit-msg` hook is rejected: it needs setting up per clone.
- ~~Does `/sdlc:release`, or the sdlc plugin's ship skill, add the trailer anywhere itself, or only
  Claude Code's attribution?~~ Resolved: only Claude Code's attribution. The plugin's skills and
  scripts never mention it.
- ~~Should GitHub be asked to garbage-collect the old objects, so the trailers are gone from cached
  views and old SHAs too? That needs a support request.~~ Resolved: no. They age out, and nothing
  sensitive is in them.
