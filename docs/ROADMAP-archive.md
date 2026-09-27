# Roadmap archive

Entries finished in [ROADMAP.md](ROADMAP.md), moved here verbatim under their numbers with the
date they moved. Numbers never change, so citations keep resolving. A note after an entry says
what was done differently from its text, and why.

## 13. CI and release hygiene (moved 2026-09-27)

- [x] Pin `actions/checkout` and `astral-sh/setup-uv` to commit SHAs, with the version as a comment.
  Set `permissions: contents: read` on the workflow.
- [x] Either stop hand-bumping by dropping `version` from `plugin.json` (installs then track the
  commit), or have the gate fail when `skills/`, `hooks/` or `agents/` differ from `origin/main`
  and the version does not. Choose one, and update the README's "Updating" section.
- [x] Tag releases with `claude plugin tag` if versions stay.

**Done means:** the workflow runs green with SHA-pinned actions and read-only permissions, and a
change to a skill without a version decision fails the gate or needs no decision.

Versions stay, and the gate enforces the bump (`scripts/check_version.sh`, against `origin/main`;
the workflow fetches main for it). Tagging is manual, `claude plugin tag --push` after the merge,
so the workflow keeps `contents: read`. `actions/checkout` went to v7.0.1 and `astral-sh/setup-uv`
to v10.2.0, both on Node 24, which also clears the runner's Node 20 deprecation warning.
