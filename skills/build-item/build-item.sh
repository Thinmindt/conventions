#!/bin/bash
# locate <item-id>: prints the item's file and its project's documents in the Project Manager's
#        workbench, and refuses an item whose state is not ToDo or In progress.
# gates: runs the repository's own gates, those it finds: scripts/check.sh, then `npm run check`
#        when package.json defines one. Stops at the first that fails.
# report <item-id>: reads the Build report on stdin and writes it, never overwriting, to
#        <exports>/builds/<timestamp>-<item-id>.md, where the Project Manager reads it. Without an
#        exports path it prints the block and exits non-zero, so the owner can paste it instead.
# The workbench path is $WORKBENCH, or the one line of
# ${XDG_CONFIG_HOME:-~/.config}/conventions/workbench; the exports path is $EXPORTS, or the one
# line of ${XDG_CONFIG_HOME:-~/.config}/conventions/exports. Each is its own file.
set -euo pipefail

# The lines every Build report starts with, after its "Build report, <item-id>" title.
report_fields=("Branch:" "Rounds:" "Criteria:" "Gates:" "Lessons:" "Out of scope, seen:" "Documents:" "Next:")

# The timestamp that names a report file. SOURCE_DATE_EPOCH fixes it, for tests.
stamp() {
    if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
        date -u -d "@$SOURCE_DATE_EPOCH" +%Y-%m-%dT%H%M%SZ
    else
        date -u +%Y-%m-%dT%H%M%SZ
    fi
}

# Whether some line of $2 starts with $1.
has_line() {
    local line
    while IFS= read -r line; do
        case $line in "$1"*) return 0 ;; esac
    done <<<"$2"
    return 1
}

# A path the owner configures outside every project: the variable named by $2, or the one line
# of ${XDG_CONFIG_HOME:-~/.config}/conventions/$1. Each path has its own file.
configured() {
    local name=$1 var=$2 config=${XDG_CONFIG_HOME:-$HOME/.config}/conventions/$1
    if [ -n "${!var:-}" ]; then
        printf '%s\n' "${!var}"
    elif [ -f "$config" ]; then
        head -n1 "$config"
    else
        echo "no $name configured: set $var, or write its path as the one line of $config" >&2
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
    wb=$(configured workbench WORKBENCH)
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
report)
    id=${2:-}
    [ -n "$id" ] || { echo "usage: build-item.sh report <item-id> < report" >&2; exit 2; }
    case $id in
    */* | *..*)
        echo "refused item id '$id': an id has no / or .. in it" >&2
        exit 2
        ;;
    esac
    block=$(cat)
    [ -n "$block" ] || { echo "no report on stdin" >&2; exit 2; }
    missing=()
    for field in "Build report, $id" "${report_fields[@]}"; do
        has_line "$field" "$block" || missing+=("$field")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        echo "not a Build report for $id: no line starts with ${missing[*]}" >&2
        exit 1
    fi
    # From here on, a failure prints the block so nothing is lost: the owner pastes it instead.
    if ! exports=$(configured exports EXPORTS); then
        printf '%s\n' "$block"
        exit 2
    fi
    if [ ! -d "$exports" ]; then
        echo "exports folder not found at $exports" >&2
        printf '%s\n' "$block"
        exit 2
    fi
    mkdir -p "$exports/builds"
    file=$exports/builds/$(stamp)-$id.md
    # noclobber makes the write fail instead of replacing a file that is already there.
    if ! (set -C && printf '%s\n' "$block" >"$file") 2>/dev/null; then
        echo "$file exists already; nothing overwritten" >&2
        printf '%s\n' "$block"
        exit 1
    fi
    echo "report=$file"
    ;;
*)
    echo "usage: build-item.sh locate <item-id> | gates | report <item-id>" >&2
    exit 2
    ;;
esac
