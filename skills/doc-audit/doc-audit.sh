#!/bin/bash
# check: SessionStart hook; says when this project's tracked files have changed by more than
#        DOC_AUDIT_CHANGED_LINES (default 500) lines since its last documentation audit, or when
#        no audit commit is reachable. Silent for a directory with no CLAUDE.md, AGENTS.md or
#        docs/.
# mark:  prints the trailer that records an audit; the audit's commit carries it as its last line.
set -euo pipefail

project=${CLAUDE_PROJECT_DIR:-$PWD}
git=(git -C "$project")

case ${1:-} in
mark)
    echo "Doc-Audit: $(date +%F)"
    ;;
check)
    [ -f "$project/CLAUDE.md" ] || [ -f "$project/AGENTS.md" ] || [ -d "$project/docs" ] || exit 0
    threshold=${DOC_AUDIT_CHANGED_LINES:-500}
    offer="Offer the owner the conventions doc-audit skill in one line early in the session;"
    offer="$offer do not start it unasked."
    audit=$("${git[@]}" log -1 --format=%H --grep='^Doc-Audit: ' 2>/dev/null || true)
    if [ -z "$audit" ]; then
        if [ "$("${git[@]}" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
            echo "This is a shallow clone with no documentation audit commit in reach, so" \
                "whether an audit is due cannot be told here."
        else
            echo "No documentation audit is recorded for this project. $offer"
        fi
        exit 0
    fi
    day=$("${git[@]}" log -1 --format='%(trailers:key=Doc-Audit,valueonly)' "$audit" | head -n 1)
    changed=$("${git[@]}" diff --numstat "$audit" |
        awk '{ added += $1; removed += $2 } END { print added + removed + 0 }')
    [ "$changed" -lt "$threshold" ] && exit 0
    echo "Since the documentation audit of $day, $changed lines of tracked files have changed" \
        "(threshold $threshold). $offer"
    ;;
*)
    echo "usage: doc-audit.sh check|mark" >&2
    exit 2
    ;;
esac
