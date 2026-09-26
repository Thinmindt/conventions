#!/bin/bash
# The gates every commit must pass, in the order that fails fastest.
set -euo pipefail
cd "$(dirname "$0")/.."

shellcheck=(uvx --from shellcheck-py==0.11.0.1 shellcheck)
codespell=(uvx codespell==2.4.3)
files() { git ls-files -z --cached --others --exclude-standard "$@"; }

bash scripts/check_private.sh
if ! cmp -s skills/doc-audit/check_private.sh scripts/check_private.sh; then
    echo "scripts/check_private.sh has drifted from the template in skills/doc-audit/" >&2
    exit 1
fi
files '*.json' | xargs -0 -n1 python3 -m json.tool >/dev/null
files '*.sh' | xargs -0 "${shellcheck[@]}"
files | xargs -0 "${codespell[@]}"
bash scripts/test_scripts.sh
echo "all checks passed"
