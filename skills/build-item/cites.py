"""Check every file:line citation in a text against a commit of the current checkout.

Reads the text on stdin: an evidence map, a reviewer's verdict, a pull request body. For each
`path:line` or `path:first-last` it answers three questions: is there exactly one tracked file at
the commit whose path is the cited one or ends with it, and do the lines exist. It does not judge
whether the lines support the claim; that stays with a reader. It reads git objects only, never
the working tree, so it checks what was committed.

Usage: python3 -I cites.py [<commit>] < text      (commit defaults to HEAD)
Exit 0 when every citation resolves, 1 when one does not, 2 when git fails.
"""

import re
import subprocess
import sys

CITATION = re.compile(
    r"(?<![\w./@-])"
    r"(?P<path>(?:[\w.@-]+/)*(?:[\w@-][\w.@-]*\.[A-Za-z]\w*|Dockerfile|Makefile))"
    r":(?P<first>\d+)(?:-(?P<last>\d+))?"
    r"(?![\w:])"
)


def git(*args: str) -> str:
    result = subprocess.run(["git", *args], capture_output=True, text=True, errors="replace")
    if result.returncode != 0:
        sys.exit(f"git {' '.join(args)}: {result.stderr.strip()}")
    return result.stdout


def matching_files(cited: str, tracked: list[str]) -> list[str]:
    if cited in tracked:
        return [cited]
    return [path for path in tracked if path.endswith("/" + cited)]


def main() -> int:
    commit = sys.argv[1] if len(sys.argv) > 1 else "HEAD"
    tracked = git("ls-tree", "-r", "--name-only", commit).splitlines()
    line_counts: dict[str, int] = {}
    checked = failed = 0
    for number, line in enumerate(sys.stdin.read().splitlines(), 1):
        for match in CITATION.finditer(line):
            cited, first = match["path"], int(match["first"])
            last = int(match["last"] or first)
            checked += 1
            files = matching_files(cited, tracked)
            if len(files) != 1:
                failed += 1
                problem = "missing" if not files else f"ambiguous, {len(files)} files"
                print(f"line {number}: {match[0]}: {problem}")
                continue
            path = files[0]
            if path not in line_counts:
                line_counts[path] = len(git("show", f"{commit}:{path}").splitlines())
            length = line_counts[path]
            if not 1 <= first <= last <= length:
                failed += 1
                print(f"line {number}: {match[0]}: out of range, {path} has {length} lines")
    print(f"{checked} citations checked at {commit}, {failed} unresolved")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
