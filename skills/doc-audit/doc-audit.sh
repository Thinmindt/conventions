#!/bin/bash
# check: SessionStart hook; says when this project's last documentation audit is more than
#        DOC_AUDIT_DAYS (default 30) old, or when none is recorded. Silent for a directory
#        with neither CLAUDE.md nor docs/.
# mark:  records now as this project's last documentation audit.
# key [path]: prints the stamp file's name for a project directory (default: this project).
#
# The stamp is named after the project's path in one spelling, so D:\X (Claude Code's
# CLAUDE_PROJECT_DIR on Windows), D:/X and Git Bash's /d/X all find the same stamp.
set -euo pipefail

# The path with forward slashes and an upper-case drive letter. Git Bash and Cygwin have
# cygpath; elsewhere a plain rewrite does the same for the spellings above.
normalize() {
    local p=$1
    if command -v cygpath >/dev/null; then
        p=$(cygpath -m "$p")
    else
        p=${p//\\//}
        case $p in /[A-Za-z] | /[A-Za-z]/*) p=${p:1:1}:${p:2} ;; esac
    fi
    case $p in [a-z]:*) p=$(printf '%s' "${p:0:1}" | tr '[:lower:]' '[:upper:]')${p:1} ;; esac
    printf '%s\n' "$p"
}

sanitize() { printf '%s\n' "$1" | sed 's|[^A-Za-z0-9._-]|-|g'; }

key() { sanitize "$(normalize "$1")"; }

# Before 1.8.1 the name was the path as written, so a mark run from Git Bash (/d/X) wrote a stamp
# the hook (D:\X) never read. check still reads that name, so such an audit is not lost.
legacy_key() {
    local p
    p=$(normalize "$1")
    case $p in [A-Z]:*) p=/$(printf '%s' "${p:0:1}" | tr '[:upper:]' '[:lower:]')${p:2} ;; esac
    sanitize "$p"
}

project=${CLAUDE_PROJECT_DIR:-$PWD}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/conventions/doc-audit
stamp=$state_dir/$(key "$project")

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
    when='' day=''
    for file in "$stamp" "$state_dir/$(legacy_key "$project")"; do
        [ -f "$file" ] || continue
        read -r w d <"$file"
        if [ -z "$when" ] || [ "$w" -gt "$when" ]; then when=$w day=$d; fi
    done
    if [ -n "$when" ]; then
        age=$((($(date +%s) - when) / 86400))
        [ "$age" -lt "$days" ] && exit 0
        echo "The last documentation audit of this project was on $day, $age days ago. $offer"
    else
        echo "No documentation audit is recorded for this project. $offer"
    fi
    ;;
key)
    key "${2:-$project}"
    ;;
*)
    echo "usage: doc-audit.sh check | mark | key [path]" >&2
    exit 2
    ;;
esac
