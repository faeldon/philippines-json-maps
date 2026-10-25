#!/usr/bin/env python3
"""Prove 017's rewrite changed nothing but the Claude trailer (spec R2-R4).

usage: verify-rewrite.py OLD_REPO NEW_REPO COMMIT_MAP EXPECTED_COUNT

OLD_REPO holds the original objects (the main checkout before import, or the backup bundle's
clone), NEW_REPO the rewritten ones (the mirror, or the main checkout after import). Exits 1 on
the first class of mismatch it finds, after printing every instance of it.
"""
import re
import subprocess
import sys

TRAILER = re.compile(rb"(?mi)^Co-Authored-By: Claude[^\n]*\n?")
HASHLIKE = re.compile(rb"\b[0-9a-f]{7,40}\b")
MOVED_TAGS = ["2023-4q", "v0.0.0", "v1.0.0"]
KEPT_TAGS = ["2011", "2019"]


def git(repo, *args):
    return subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True).stdout


def parse(raw):
    head, _, message = raw.partition(b"\n\n")
    headers = {}
    for line in head.split(b"\n"):
        key, _, value = line.partition(b" ")
        headers.setdefault(key, []).append(value)
    return headers, message


def main(old_repo, new_repo, map_path, expected):
    pairs = {}
    with open(map_path, "rb") as f:
        for line in f.read().split(b"\n")[1:]:
            if line:
                old, new = line.split()
                if old != new:
                    pairs[old] = new
    old_hex = [o.decode() for o in pairs]

    def mapped(sha):
        return pairs.get(sha, sha)

    def map_hashes(message):
        def sub(m):
            tok = m.group(0)
            hits = [o for o in pairs if o.startswith(tok)]
            return pairs[hits[0]][: len(tok)] if len(hits) == 1 else tok
        return HASHLIKE.sub(sub, message)

    failures = []
    if len(pairs) != expected:
        failures.append(f"{len(pairs)} commits changed, expected {expected}")

    for old, new in pairs.items():
        oh, om = parse(git(old_repo, "cat-file", "commit", old.decode()))
        nh, nm = parse(git(new_repo, "cat-file", "commit", new.decode()))
        short = old.decode()[:8]
        for key in (b"tree", b"author", b"committer"):
            if oh.get(key) != nh.get(key):
                failures.append(f"{short}: {key.decode()} differs")
        if [mapped(p) for p in oh.get(b"parent", [])] != nh.get(b"parent", []):
            failures.append(f"{short}: parents are not the mapped parents")
        if set(oh) - {b"gpgsig"} != set(nh):
            failures.append(f"{short}: header set differs ({sorted(set(oh) ^ set(nh))})")
        stripped = TRAILER.sub(b"", om)
        expect = map_hashes(stripped.rstrip(b"\n") + b"\n" if stripped != om else om)
        if nm != expect:
            failures.append(f"{short}: message differs beyond the trailer and mapped hashes")
        if TRAILER.search(nm):
            failures.append(f"{short}: still carries the trailer")
        for tok in HASHLIKE.findall(nm):
            if any(o.startswith(tok.decode()) for o in old_hex):
                failures.append(f"{short}: cites old hash {tok.decode()}")

    log = git(new_repo, "log", "--branches", "--tags", "-i",
              "--grep=Co-Authored-By: Claude", "--format=%h")
    if log.strip():
        failures.append(f"trailer still on: {log.decode().split()}")

    for tag in MOVED_TAGS:
        oh, om = parse(git(old_repo, "cat-file", "tag", tag))
        nh, nm = parse(git(new_repo, "cat-file", "tag", tag))
        if nh[b"object"] != [mapped(oh[b"object"][0])]:
            failures.append(f"{tag}: does not point at the mapped commit")
        if (oh[b"tag"], oh[b"tagger"], om) != (nh[b"tag"], nh[b"tagger"], nm):
            failures.append(f"{tag}: name, tagger or message differs")
    for tag in KEPT_TAGS:
        if git(old_repo, "rev-parse", tag) != git(new_repo, "rev-parse", tag):
            failures.append(f"{tag}: moved, and should not have")

    for f in failures:
        print("FAIL", f)
    if failures:
        return 1
    print(f"{len(pairs)} commits: tree, author, committer and parents identical; messages differ "
          f"only by the trailer and mapped hashes. Tags {', '.join(MOVED_TAGS)} moved with the "
          f"same name, tagger and message; {', '.join(KEPT_TAGS)} unchanged.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])))
