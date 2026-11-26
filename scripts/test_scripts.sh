#!/bin/bash
# Exercises doc-audit.sh, build-item.sh, the check_private.sh template and check_examples.sh in
# throwaway directories.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

expect() {
    local name=$1 want=$2 got=$3
    if [ "$want" = "$got" ]; then
        echo "ok   $name"
    else
        echo "FAIL $name: wanted $want, got $got"
        failures=$((failures + 1))
    fi
}

# doc-audit.sh: silent without docs, reminds when nothing is recorded or the audit is stale.
audit=$root/skills/doc-audit/doc-audit.sh
export XDG_STATE_HOME=$work/state
mkdir -p "$work/nodocs" "$work/project/docs"
expect "doc-audit: no docs, no reminder" "" "$(CLAUDE_PROJECT_DIR=$work/nodocs bash "$audit" check)"
export CLAUDE_PROJECT_DIR=$work/project
expect "doc-audit: none recorded, reminder" yes "$(bash "$audit" check | grep -q 'No documentation audit' && echo yes)"
bash "$audit" mark >/dev/null
expect "doc-audit: just marked, no reminder" "" "$(bash "$audit" check)"
stamp=$(find "$XDG_STATE_HOME" -type f)
echo "$(($(date +%s) - 40 * 86400)) 2000-01-01" >"$stamp"
expect "doc-audit: 40 days old, reminder" yes "$(bash "$audit" check | grep -q '40 days ago' && echo yes)"
unset CLAUDE_PROJECT_DIR

# doc-audit.sh key: every spelling of one Windows path names one stamp. Git Bash's cygpath does the
# rewrite on Windows; the plain fallback does it elsewhere, and leaves a POSIX path as it was.
stamp_key() { bash "$audit" key "$1"; }
expect 'doc-audit key: C:\X' C--Nanoclaw "$(stamp_key 'C:\Nanoclaw')"
expect 'doc-audit key: C:/X' C--Nanoclaw "$(stamp_key 'C:/Nanoclaw')"
expect 'doc-audit key: /c/X' C--Nanoclaw "$(stamp_key /c/Nanoclaw)"
expect 'doc-audit key: c:\X' C--Nanoclaw "$(stamp_key 'c:\Nanoclaw')"
if ! command -v cygpath >/dev/null; then
    expect "doc-audit key: a POSIX path keeps its key" -home-me-project "$(stamp_key /home/me/project)"
fi

# Regression, git-bash-mark-unseen-by-hook: a mark run from Git Bash wrote -c-Nanoclaw while the
# SessionStart hook, given C:\Nanoclaw, read C--Nanoclaw, so the audit stayed due.
stamps=$XDG_STATE_HOME/conventions/doc-audit
CLAUDE_PROJECT_DIR=/c/Nanoclaw bash "$audit" mark >/dev/null
expect "doc-audit regression: git-bash-mark-unseen-by-hook" yes \
    "$([ -f "$stamps/$(stamp_key 'C:\Nanoclaw')" ] && [ ! -f "$stamps/-c-Nanoclaw" ] && echo yes)"

# On Windows, the same end to end: mark from Git Bash, check as the hook does, and a stamp
# written under the old Git Bash name still counts.
if command -v cygpath >/dev/null; then
    mkdir -p "$work/winproject/docs" "$work/legacy/docs"
    CLAUDE_PROJECT_DIR=$work/winproject bash "$audit" mark >/dev/null
    expect "doc-audit: marked from Git Bash, seen by the hook" "" \
        "$(CLAUDE_PROJECT_DIR=$(cygpath -w "$work/winproject") bash "$audit" check)"
    legacy=$(cygpath -m "$work/legacy" | sed 's|^\(.\):|/\L\1|; s|[^A-Za-z0-9._-]|-|g')
    echo "$(date +%s) $(date +%F)" >"$stamps/$legacy"
    expect "doc-audit: a stamp under the old Git Bash name counts" "" \
        "$(CLAUDE_PROJECT_DIR=$(cygpath -w "$work/legacy") bash "$audit" check)"
fi

# build-item.sh locate: needs a workbench path, finds an item by id, refuses one that is not
# ToDo or In progress. gates: runs scripts/check.sh, fails when there is nothing to run.
build=$root/skills/build-item/build-item.sh
wb=$work/workbench
mkdir -p "$wb/projects/bird-counter/items" "$work/config"
printf -- '---\nid: bird-counter-7\nproject: bird-counter\nstate: ToDo\n---\n# Count birds\n' >"$wb/projects/bird-counter/items/bird-counter-7.md"
printf -- '---\nid: bird-counter-8\nstate: Done\n---\n' >"$wb/projects/bird-counter/items/bird-counter-8.md"
locate() { env -u WORKBENCH XDG_CONFIG_HOME="$work/config" "$@" bash "$build" locate "${id:-bird-counter-7}" 2>&1 || true; }
expect "build-item: no workbench configured" yes \
    "$(locate | grep -q 'no workbench configured' && echo yes)"
expect "build-item: WORKBENCH set, item found" "item=$wb/projects/bird-counter/items/bird-counter-7.md" \
    "$(locate WORKBENCH="$wb" | head -n1)"
mkdir -p "$work/config/conventions"
printf '%s\n' "$wb" >"$work/config/conventions/workbench"
expect "build-item: path from the config file" "lessons=$wb/review-lessons.md" \
    "$(locate | sed -n 3p)"
expect "build-item: a Done item is refused" yes \
    "$(id=bird-counter-8 locate | grep -q 'is Done, not ToDo' && echo yes)"
expect "build-item: a missing item is refused" yes \
    "$(id=bird-counter-9 locate | grep -q 'no item bird-counter-9' && echo yes)"
gated=$work/gated
mkdir -p "$gated/scripts"
gates() { (cd "$gated" && bash "$build" gates >/dev/null 2>&1 && echo pass || echo fail); }
expect "build-item: no gate found" fail "$(gates)"
printf '#!/bin/bash\nexit 0\n' >"$gated/scripts/check.sh"
expect "build-item: check.sh passes" pass "$(gates)"
printf '#!/bin/bash\nexit 1\n' >"$gated/scripts/check.sh"
expect "build-item: check.sh fails" fail "$(gates)"

# build-item.sh report: writes the block on stdin to <exports>/builds/<timestamp>-<id>.md;
# refuses a block missing a field; without an exports folder it prints the block.
# SOURCE_DATE_EPOCH fixes the timestamp.
exports=$work/exports
mkdir -p "$exports"
block="Build report, bird-counter-7
Branch: item/bird-counter-7 at abc1234, 2 commits on main
Rounds: 1 of 3; verdict: pass
Criteria:
1. met — the count is printed
Gates: bash scripts/check.sh pass
Lessons: kept
Out of scope, seen: none
Documents: none named
Retrospective:
- Went well: the count test failed first, then passed
- Cost a round: none
- Proposed lesson: none
Next: review the branch, push, open the pull request"
report() {
    printf '%s\n' "$block" |
        env -u EXPORTS XDG_CONFIG_HOME="$work/config" SOURCE_DATE_EPOCH=1000000000 "$@" \
            bash "$build" report bird-counter-7 2>&1 || true
}
expect "report: no exports configured, prints the block" yes \
    "$(report | grep -q '^Build report, bird-counter-7' && echo yes)"
first=$exports/builds/2001-09-09T014640Z-bird-counter-7.md
expect "report: EXPORTS set, file named by timestamp and id" "report=$first" "$(report EXPORTS="$exports")"
expect "report: the file holds the block" yes "$(printf '%s\n' "$block" | cmp -s - "$first" && echo yes)"
expect "report: a missing exports folder prints the block" yes \
    "$(report EXPORTS="$work/absent" | grep -q '^Next: review the branch' && echo yes)"
block=$(printf '%s\n' "$block" | grep -v '^Retrospective:')
expect "report: a block missing a field is refused" yes \
    "$(report EXPORTS="$exports" | grep -q 'no line starts with Retrospective:' && echo yes)"

# build-item.sh cites: every file:line on stdin names one tracked file at the commit and lines it has.
cited=$work/cited
mkdir -p "$cited/src" "$cited/tests"
git -C "$cited" init -q
printf 'one\ntwo\nthree\n' >"$cited/src/count.py"
printf 'one\n' >"$cited/tests/count.py"
git -C "$cited" add -A
git -C "$cited" -c user.name=Tester -c user.email=tester@example.org commit -q -m "first"
cites() { (cd "$cited" && printf '%s\n' "$1" | bash "$build" cites >/dev/null 2>&1 && echo pass || echo fail); }
expect "cites: a full path and a range that exist" pass "$(cites 'made true at src/count.py:2-3')"
expect "cites: a file not tracked" fail "$(cites 'shown at src/absent.py:1')"
expect "cites: a line past the end" fail "$(cites 'shown at src/count.py:4')"
expect "cites: a short path naming two files" fail "$(cites 'shown at count.py:1')"

# build-item.sh version: one line when the marketplace's manifest is newer than the installed one,
# silent when they match. A stub curl serves the marketplace's manifest from $latest.
mkdir -p "$work/bin"
cat >"$work/bin/curl" <<'SH'
#!/bin/bash
cat "$latest"
SH
chmod +x "$work/bin/curl"
version() { PATH="$work/bin:$PATH" latest=$1 bash "$build" version 2>&1 || true; }
expect "version: current, silent" "" "$(version "$root/.claude-plugin/plugin.json")"
printf '{ "version": "99.0.0" }\n' >"$work/latest.json"
expect "version: behind, one line" yes \
    "$(version "$work/latest.json" | grep -q 'the marketplace has 99.0.0' && echo yes)"

# check_private.sh: passes with no terms, fails on a term in a file or an unpushed commit.
repo=$work/repo
mkdir -p "$repo/scripts"
cp "$root/skills/doc-audit/check_private.sh" "$repo/scripts/"
git -C "$repo" init -q
git -C "$repo" config user.name Tester
git -C "$repo" config user.email tester@example.org
printf '.private-terms\n' >"$repo/.gitignore"
echo "hello" >"$repo/notes.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m "first"
status() { bash "$repo/scripts/check_private.sh" >/dev/null 2>&1 && echo pass || echo fail; }
expect "check_private: no terms configured" pass "$(status)"
printf '# a comment\nzanzibar\n' >"$repo/.private-terms"
expect "check_private: terms, none present" pass "$(status)"
echo "we met in Zanzibar" >"$repo/draft.md"
expect "check_private: term in an untracked file" fail "$(status)"
rm "$repo/draft.md"
printf '#!/bin/bash\necho quokka\n' >"$repo/scripts/private_terms.sh"
echo "a quokka" >"$repo/draft.md"
expect "check_private: term from private_terms.sh" fail "$(status)"
rm "$repo/draft.md"
git -C "$repo" -c user.email=me@zanzibar.example commit -q --allow-empty -m "second"
expect "check_private: term in an unpushed commit's author" fail "$(status)"

# check_examples.sh: a fragment that follows the guide passes; one that breaks it, or does not
# parse, fails at the skill's own line.
skill=$work/skill/SKILL.md
mkdir -p "$(dirname "$skill")"
examples() { bash "$root/scripts/check_examples.sh" "$skill" 2>/dev/null || echo "fail"; }
cat >"$skill" <<'MD'
```python
log.info("ok %s", x)
return None
```
MD
expect "check_examples: fragment following the guide" \
    "skill examples: parse and pass ruff" "$(examples)"
cat >"$skill" <<'MD'
text
```python
print("x")
```
MD
expect "check_examples: print in an example" yes \
    "$(examples | grep 'SKILL.md:3:1: T201' >/dev/null && echo yes)"
cat >"$skill" <<'MD'
```python
return 1 +
```
MD
expect "check_examples: example that does not parse" yes \
    "$(examples | grep 'SKILL.md:2: invalid syntax' >/dev/null && echo yes)"

[ "$failures" -eq 0 ] || exit 1
