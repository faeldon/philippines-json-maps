# Checks

> The change's acceptance checks: each `## ` section is one, which only a deliberate revert could
> fail, so it stays out of the suite. `/sdlc:ship` reruns every one from the checkout root before
> it commits, and a check passes when its one `sh` block exits 0 and leaves the working tree as it
> found it. `sdlc.py` reads each section's name and that block, nothing else.

## No commit on HEAD carries a Co-Authored-By: Claude trailer

Only undoing the rewrite, or a new trailer commit, could put one back.

```sh
test -z "$(git log -i --grep='^Co-Authored-By: Claude' --format=%h)"
```

## The gate's trailer clause fails on a commit that carries one

The clause in `commands.check` could be weakened into one that never fails; this proves it fails
on a trailer commit, made in a throwaway clone so the checkout is untouched.

```sh
t=$(mktemp -d) && git clone -q . "$t/repo" \
  && git -C "$t/repo" -c user.name=check -c user.email=check@example.invalid commit -q --allow-empty \
       -m "throwaway" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" \
  && ! (cd "$t/repo" && test -z "$(git log -i --grep='^Co-Authored-By: Claude' --format=%h)"); \
  r=$?; rm -rf "$t"; exit $r
```
