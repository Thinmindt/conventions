#!/bin/bash
# SessionStart hook: says when a project generated from the conventions template is behind the
# installed plugin, by comparing _commit in .copier-answers.yml with the plugin's version.
# Silent for a project with no answers file, or one generated from another template.
set -euo pipefail
project=${CLAUDE_PROJECT_DIR:-$PWD}
answers=$project/.copier-answers.yml
[ -f "$answers" ] || exit 0
grep -q '^_src_path: .*conventions' "$answers" || exit 0
commit=$(sed -n 's/^_commit: *//p' "$answers" | tr -d '"'"'")
manifest=${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/.claude-plugin/plugin.json
plugin=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$manifest")
[ "${commit#v}" = "$plugin" ] && exit 0
echo "This project was generated from conventions $commit; the installed plugin is $plugin." \
    "Offer to run \`uvx copier==9.18.2 update --defaults --trust\` in one line;" \
    "do not run it unasked."
