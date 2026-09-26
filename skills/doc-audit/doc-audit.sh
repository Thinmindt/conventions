#!/bin/bash
# check: SessionStart hook; says when this project's last documentation audit is more than
#        DOC_AUDIT_DAYS (default 30) old, or when none is recorded. Silent for a directory
#        with neither CLAUDE.md nor docs/.
# mark:  records now as this project's last documentation audit.
set -euo pipefail

project=${CLAUDE_PROJECT_DIR:-$PWD}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/conventions/doc-audit
stamp=$state_dir/$(printf '%s' "$project" | sed 's|[^A-Za-z0-9._-]|-|g')

case ${1:-} in
mark)
    mkdir -p "$state_dir"
    echo "$(date +%s) $(date +%F)" >"$stamp"
    echo "documentation audit recorded for $project"
    ;;
check)
    [ -f "$project/CLAUDE.md" ] || [ -d "$project/docs" ] || exit 0
    days=${DOC_AUDIT_DAYS:-30}
    offer="Offer the owner the conventions doc-audit skill in one line early in the session; do not start it unasked."
    if [ -f "$stamp" ]; then
        read -r when day <"$stamp"
        age=$((($(date +%s) - when) / 86400))
        [ "$age" -lt "$days" ] && exit 0
        echo "The last documentation audit of this project was on $day, $age days ago. $offer"
    else
        echo "No documentation audit is recorded for this project. $offer"
    fi
    ;;
*)
    echo "usage: doc-audit.sh check|mark" >&2
    exit 2
    ;;
esac
