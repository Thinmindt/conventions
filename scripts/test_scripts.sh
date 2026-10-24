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
expect "build-item: state printed" "state=ToDo" "$(locate WORKBENCH="$wb" | sed -n 2p)"
mkdir -p "$work/config/conventions"
printf '%s\n' "$wb" >"$work/config/conventions/workbench"
expect "build-item: path from the config file" "lessons=$wb/review-lessons.md" \
    "$(locate | sed -n 4p)"
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

# build-item.sh report: writes the block on stdin to <exports>/builds/<timestamp>-<id>.md and
# never overwrites; refuses a path-shaped id or a block missing a field; with no exports path it
# prints the block and fails. SOURCE_DATE_EPOCH fixes the timestamp.
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
Next: review the branch, push, open the pull request"
report_exit() {
    printf '%s\n' "$block" |
        env -u EXPORTS XDG_CONFIG_HOME="$work/config" SOURCE_DATE_EPOCH=1000000000 "$@" \
            bash "$build" report "${id:-bird-counter-7}" 2>&1
}
report() { report_exit "$@" || true; }
written() { find "$exports/builds" -type f 2>/dev/null | wc -l | tr -d ' '; }
expect "report: no exports configured, prints the block" yes \
    "$(report | grep -q '^Build report, bird-counter-7' && echo yes)"
expect "report: no exports configured, fails" fail "$(report_exit >/dev/null && echo pass || echo fail)"
expect "report: nothing written without an exports path" 0 "$(written)"
first=$exports/builds/2001-09-09T014640Z-bird-counter-7.md
expect "report: EXPORTS set, file named by timestamp and id" "report=$first" "$(report EXPORTS="$exports")"
expect "report: the file holds the block" yes "$(printf '%s\n' "$block" | cmp -s - "$first" && echo yes)"
expect "report: a second write at the same time is refused" yes \
    "$(report EXPORTS="$exports" | grep -q 'exists already; nothing overwritten' && echo yes)"
expect "report: nothing overwritten, still one file" 1 "$(written)"
expect "report: a later write leaves two files" "report=$exports/builds/2001-09-09T014641Z-bird-counter-7.md" \
    "$(report EXPORTS="$exports" SOURCE_DATE_EPOCH=1000000001)"
expect "report: two files" 2 "$(written)"
printf '%s\n' "$exports" >"$work/config/conventions/exports"
expect "report: path from its own config file" "report=$exports/builds/2001-09-09T014642Z-bird-counter-7.md" \
    "$(report SOURCE_DATE_EPOCH=1000000002)"
expect "report: an id with / is refused" yes "$(id=projects/bird-counter-7 report | grep -q 'refused item id' && echo yes)"
expect "report: an id with .. is refused" yes "$(id=../bird-counter-7 report | grep -q 'refused item id' && echo yes)"
expect "report: a block for another item is refused" yes \
    "$(id=bird-counter-8 report | grep -q 'no line starts with Build report, bird-counter-8' && echo yes)"
expect "report: a missing exports folder prints the block" yes \
    "$(report EXPORTS="$work/absent" | grep -q '^Next: review the branch' && echo yes)"
block=$(printf '%s\n' "$block" | grep -v '^Gates:')
expect "report: a block missing a field is refused" yes \
    "$(report SOURCE_DATE_EPOCH=1000000003 | grep -q 'no line starts with Gates:' && echo yes)"
expect "report: still three files" 3 "$(written)"

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
