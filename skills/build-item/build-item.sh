#!/bin/bash
# locate <item-id>: prints the item's file and its project's documents in the Project Manager's
#        workbench, and refuses an item whose state is not ToDo or In progress.
# gates: runs the repository's own gates, those it finds: scripts/check.sh, then `npm run check`
#        when package.json defines one. Stops at the first that fails.
# The workbench path is $WORKBENCH, or the one line of
# ${XDG_CONFIG_HOME:-~/.config}/conventions/workbench.
set -euo pipefail

workbench() {
    local config=${XDG_CONFIG_HOME:-$HOME/.config}/conventions/workbench
    if [ -n "${WORKBENCH:-}" ]; then
        printf '%s\n' "$WORKBENCH"
    elif [ -f "$config" ]; then
        head -n1 "$config"
    else
        echo "no workbench configured: set WORKBENCH, or write its path as the one line of $config" >&2
        exit 2
    fi
}

# The value of one key in a file's YAML front matter; empty when absent.
frontmatter() {
    awk -v key="$1:" '
        NR == 1 && $0 != "---" { exit }
        NR > 1 && $0 == "---" { exit }
        $1 == key { sub(/^[^:]*:[ \t]*/, ""); print; exit }
    ' "$2"
}

case ${1:-} in
locate)
    id=${2:-}
    [ -n "$id" ] || { echo "usage: build-item.sh locate <item-id>" >&2; exit 2; }
    wb=$(workbench)
    [ -d "$wb" ] || { echo "workbench not found at $wb" >&2; exit 2; }
    project=${id%-*}
    item=$wb/projects/$project/items/$id.md
    [ -f "$item" ] || { echo "no item $id: expected $item" >&2; exit 1; }
    state=$(frontmatter state "$item")
    case $state in
    ToDo | "In progress") ;;
    *)
        echo "item $id is ${state:-without a state}, not ToDo or In progress; the Project Manager moves it first" >&2
        exit 1
        ;;
    esac
    echo "item=$item"
    echo "state=$state"
    echo "project=$wb/projects/$project"
    echo "lessons=$wb/review-lessons.md"
    echo "projects=$wb/projects.md"
    ;;
gates)
    ran=0
    if [ -f scripts/check.sh ]; then
        echo "== bash scripts/check.sh"
        bash scripts/check.sh
        ran=1
    fi
    if [ -f package.json ] && python3 -c 'import json, sys; sys.exit(0 if "check" in json.load(open("package.json")).get("scripts", {}) else 1)'; then
        echo "== npm run check"
        npm run check
        ran=1
    fi
    if [ "$ran" -eq 0 ]; then
        echo "no gate found: neither scripts/check.sh nor an npm check script; run what the item's definition of done names" >&2
        exit 1
    fi
    ;;
*)
    echo "usage: build-item.sh locate <item-id> | gates" >&2
    exit 2
    ;;
esac
