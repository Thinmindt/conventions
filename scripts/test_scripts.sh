#!/bin/bash
# Exercises doc-audit.sh, the check_private.sh template and check_examples.sh in throwaway
# directories.
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
