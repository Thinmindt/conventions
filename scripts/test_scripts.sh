#!/bin/bash
# Exercises doc-audit.sh, check_private.sh, check_examples.sh, check_version.sh, the Copier
# template and template-version.sh in throwaway directories.
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

# doc-audit.sh: silent without docs; reminds when no audit commit is reachable, is quiet right
# after one, reminds once enough has changed since it, and says so when a shallow clone hides it.
audit=$root/skills/doc-audit/doc-audit.sh
expect "doc-audit: mark prints the trailer" "Doc-Audit: $(date +%F)" "$(bash "$audit" mark)"
mkdir -p "$work/nodocs" "$work/agents" "$work/project/docs"
expect "doc-audit: no docs, no reminder" "" "$(CLAUDE_PROJECT_DIR=$work/nodocs bash "$audit" check)"
touch "$work/agents/AGENTS.md"
expect "doc-audit: AGENTS.md counts as docs" yes \
    "$(CLAUDE_PROJECT_DIR=$work/agents bash "$audit" check | grep 'No documentation audit' >/dev/null && echo yes)"
export CLAUDE_PROJECT_DIR=$work/project
reminder() { bash "$audit" check | grep "$1" >/dev/null && echo yes; }
expect "doc-audit: docs but no repository, reminder" yes "$(reminder 'No documentation audit')"
git -C "$work/project" init -q -b main
git -C "$work/project" config user.name Tester
git -C "$work/project" config user.email tester@example.org
seq 20 >"$work/project/docs/notes.md"
git -C "$work/project" add -A
git -C "$work/project" commit -q -m "first"
expect "doc-audit: no audit commit, reminder" yes "$(reminder 'No documentation audit')"
git -C "$work/project" commit -q --allow-empty -m "Audit the documentation" \
    --trailer "$(bash "$audit" mark)"
expect "doc-audit: just audited, no reminder" "" "$(bash "$audit" check)"
seq 21 32 >>"$work/project/docs/notes.md"
expect "doc-audit: 12 lines changed, under the threshold" "" "$(bash "$audit" check)"
expect "doc-audit: past the threshold, reminder with date and count" yes \
    "$(DOC_AUDIT_CHANGED_LINES=10 reminder "audit of $(date +%F), 12 lines of tracked files")"
git -C "$work/project" commit -q -am "more notes"
git clone -q --depth 1 "file://$work/project" "$work/shallow"
expect "doc-audit: shallow clone hides the audit, cannot tell" yes \
    "$(CLAUDE_PROJECT_DIR=$work/shallow reminder 'shallow clone')"
unset CLAUDE_PROJECT_DIR

# check_private.sh: passes with no terms, fails on a term in a file or an unpushed commit.
repo=$work/repo
mkdir -p "$repo/scripts"
cp "$root/template/scripts/check_private.sh" "$repo/scripts/"
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

# check_version.sh: a change under skills/ needs a new version, compared with origin/main.
bare=$work/origin.git
git init -q --bare "$bare"
plugin=$work/plugin
mkdir -p "$plugin/.claude-plugin" "$plugin/skills/one" "$plugin/scripts"
git -C "$plugin" init -q -b main
git -C "$plugin" config user.name Tester
git -C "$plugin" config user.email tester@example.org
git -C "$plugin" remote add origin "$bare"
cp "$root/scripts/check_version.sh" "$plugin/scripts/"
echo '{"name": "p", "version": "1.0.0"}' >"$plugin/.claude-plugin/plugin.json"
echo "rule" >"$plugin/skills/one/SKILL.md"
version_status() { bash "$plugin/scripts/check_version.sh" >/dev/null 2>&1 && echo pass || echo fail; }
git -C "$plugin" add -A
git -C "$plugin" commit -q -m "first"
expect "check_version: no origin/main, skipped" pass "$(version_status)"
git -C "$plugin" push -q -u origin main 2>/dev/null
expect "check_version: nothing differs" pass "$(version_status)"
echo "another rule" >>"$plugin/skills/one/SKILL.md"
expect "check_version: skill changed, version not" fail "$(version_status)"
echo '{"name": "p", "version": "1.1.0"}' >"$plugin/.claude-plugin/plugin.json"
expect "check_version: skill changed, version bumped" pass "$(version_status)"

# The Copier template: a fresh project's gate passes and its hook is installed and bites; an update
# brings the template's change in and leaves the project's own file alone; template-version.sh
# notices a project that is behind. The template is copied into a tagged repository first, since
# Copier updates only from tags.
copier=(uvx copier==9.18.2)
tpl=$work/conventions-template
mkdir -p "$tpl"
cp -r "$root/copier.yml" "$root/template" "$tpl/"
git -C "$tpl" init -q -b main
git -C "$tpl" config user.name Tester
git -C "$tpl" config user.email tester@example.org
git -C "$tpl" add -A
git -C "$tpl" commit -q -m "template"
git -C "$tpl" tag v0.0.1
gen=$work/gen
mkdir "$gen"
git -C "$gen" init -q -b main
git -C "$gen" config user.name Tester
git -C "$gen" config user.email tester@example.org
"${copier[@]}" copy -q --defaults --trust -d project_name=Gen -d private_terms=true "$tpl" "$gen"
gate() { (cd "$gen" && bash "$1" >/dev/null 2>&1) && echo pass || echo fail; }
expect "template: generated gate passes" pass "$(gate scripts/check.sh)"
expect "template: pre-push hook installed" scripts/githooks "$(git -C "$gen" config core.hooksPath)"
expect "template: .private-terms ignored" yes "$(grep -qx '.private-terms' "$gen/.gitignore" && echo yes)"
expect "template: answers record the tag" v0.0.1 "$(sed -n 's/^_commit: *//p' "$gen/.copier-answers.yml")"
git -C "$gen" add -A
git -C "$gen" commit -q -m "generated"
printf '#!/bin/bash\necho quokka\n' >"$gen/scripts/private_terms.sh"
echo "a quokka" >"$gen/notes.md"
expect "template: pre-push hook refuses a private term" fail "$(gate scripts/githooks/pre-push)"
rm "$gen/notes.md"
git -C "$gen" commit -q -am "own private terms"
echo "- A rule the template gained later." >>"$tpl/template/AGENTS.md.jinja"
git -C "$tpl" commit -q -am "a rule"
git -C "$tpl" tag v0.0.2
(cd "$gen" && "${copier[@]}" update -q --defaults --trust)
expect "template: update brings the template's change" yes \
    "$(grep -q 'A rule the template gained later' "$gen/AGENTS.md" && echo yes)"
expect "template: update leaves the project's private_terms.sh" quokka "$(bash "$gen/scripts/private_terms.sh")"
expect "template: answers move to the new tag" v0.0.2 "$(sed -n 's/^_commit: *//p' "$gen/.copier-answers.yml")"
versions() { CLAUDE_PROJECT_DIR=$1 CLAUDE_PLUGIN_ROOT=$root bash "$root/hooks/template-version.sh"; }
expect "template-version: project behind the plugin" yes \
    "$(versions "$gen" | grep -q 'generated from conventions v0.0.2' && echo yes)"
plugin_version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$root/.claude-plugin/plugin.json")
sed -i "s/^_commit: .*/_commit: v$plugin_version/" "$gen/.copier-answers.yml"
expect "template-version: project current, silent" "" "$(versions "$gen")"
expect "template-version: no answers file, silent" "" "$(versions "$work/nodocs")"

[ "$failures" -eq 0 ] || exit 1
