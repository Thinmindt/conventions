#!/bin/bash
# Fail if what the plugin or the template ships (skills/, hooks/, agents/, template/, copier.yml)
# differs from origin/main and the version in .claude-plugin/plugin.json does not (README,
# "Updating"). Skipped, with a message, where there
# is no origin/main to compare with.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! git rev-parse -q --verify origin/main >/dev/null; then
    echo "version bump: no origin/main to compare with, skipped"
    exit 0
fi
if git diff --quiet origin/main -- skills hooks agents template copier.yml; then
    echo "version bump: nothing the plugin or the template ships differs from origin/main"
    exit 0
fi
version() { python3 -c 'import json, sys; print(json.load(sys.stdin)["version"])'; }
before=$(git show origin/main:.claude-plugin/plugin.json | version)
now=$(version <.claude-plugin/plugin.json)
if [ "$before" = "$now" ]; then
    echo "what the plugin or the template ships differs from origin/main, but the version is" \
        "still $now; bump it in .claude-plugin/plugin.json" >&2
    exit 1
fi
echo "version bump: $before -> $now"
