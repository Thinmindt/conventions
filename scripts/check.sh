#!/bin/bash
# The gates every commit must pass, in the order that fails fastest.
set -euo pipefail
cd "$(dirname "$0")/.."

shellcheck=(uvx --from shellcheck-py==0.11.0.1 shellcheck)
codespell=(uvx codespell==2.4.3)
files() { git ls-files -z --cached --others --exclude-standard "$@"; }

bash scripts/check_private.sh
if ! cmp -s template/scripts/check_private.sh scripts/check_private.sh; then
    echo "scripts/check_private.sh has drifted from template/scripts/check_private.sh" >&2
    exit 1
fi
bash scripts/check_version.sh
files '*.json' | xargs -0 -n1 python3 -m json.tool >/dev/null
# The manifests and every skill's front matter, as the Claude Code on PATH reads them; CI
# installs the version in .github/workflows/check.yml.
if command -v claude >/dev/null; then
    for target in .claude-plugin/marketplace.json .claude-plugin/plugin.json skills; do
        if ! report=$(claude plugin validate --strict "$target" 2>&1); then
            echo "$report" >&2
            exit 1
        fi
    done
    echo "plugin validate: manifests and skills valid ($(claude --version))"
else
    echo "plugin validate: claude is not on PATH, skipped"
fi
files '*.sh' | xargs -0 "${shellcheck[@]}"
files | xargs -0 "${codespell[@]}"
bash scripts/check_examples.sh
bash scripts/test_scripts.sh
echo "all checks passed"
