#!/bin/bash
# Fail if a ```python example in a skill does not parse, or breaks a rule the guide itself
# states (no print, no f-string logging, no bare except, a reason on every noqa). Examples are
# fragments: names from their surroundings and a bare return are allowed.
# Usage: check_examples.sh [SKILL.md ...]; with no arguments, every skill in this plugin.
set -euo pipefail
cd "$(dirname "$0")/.."

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
if [ "$#" -eq 0 ]; then
    set -- skills/*/SKILL.md
fi
python3 - "$work" "$@" <<'PY'
import ast, pathlib, re, subprocess, sys

RUFF = ["uvx", "ruff==0.15.8", "check", "--quiet", "--no-cache", "--isolated",
        "--output-format=concise", "--select=F,T20,G,BLE,S,PGH004",
        "--ignore=F401,F706,F821,F841"]

work = pathlib.Path(sys.argv[1])
origin = {}  # extracted file -> (skill path, line of the opening fence)
failed = False
for path in sys.argv[2:]:
    block, start = None, 0
    for number, line in enumerate(pathlib.Path(path).read_text().splitlines(), 1):
        if block is None:
            if line.strip() == "```python":
                block, start = [], number
        elif line.strip() == "```":
            source = "\n".join(block) + "\n"
            try:
                ast.parse(source)
            except SyntaxError as e:
                print(f"{path}:{start + (e.lineno or 1)}: {e.msg}")
                failed = True
            else:
                extracted = work / f"{len(origin)}.py"
                extracted.write_text(source)
                origin[str(extracted)] = (path, start)
            block = None
        else:
            block.append(line)
    if block is not None:
        print(f"{path}:{start}: ```python block never closed")
        failed = True

if origin:
    result = subprocess.run(RUFF + sorted(origin), capture_output=True, text=True)
    for line in result.stdout.splitlines():
        m = re.match(r"(.+?\.py):(\d+):(\d+): (.*)", line)
        if m and m[1] in origin:
            path, start = origin[m[1]]
            print(f"{path}:{start + int(m[2])}:{m[3]}: {m[4]}")
        else:
            print(line)
    sys.stderr.write(result.stderr)
    failed = failed or result.returncode != 0
sys.exit(1 if failed else 0)
PY
echo "skill examples: parse and pass ruff"
