# Roadmap archive

Entries finished in [ROADMAP.md](ROADMAP.md), moved here verbatim under their numbers with the
date they moved. Numbers never change, so citations keep resolving. A note after an entry says
what was done differently from its text, and why.

## 1. Validate the plugin in the gate (moved 2026-09-27)

`claude plugin validate --strict` checks the manifests and every skill's front matter. It passes
today, but nothing runs it.

- [x] Add it to `scripts/check.sh`, pinned to a Claude Code version the way shellcheck and codespell
  are pinned. First confirm it runs without credentials on CI. If it does not, the gate skips it
  with a message, as the privacy check does with no terms.

**Done means:** a SKILL.md with broken front matter fails `scripts/check.sh` locally and in CI.

It runs without credentials. Three calls are needed, since a path selects one thing to validate:
the marketplace manifest, the plugin manifest and the skills directory. Locally the gate uses the
`claude` on PATH and skips with a message when there is none, since the machines that run it
install Claude Code natively, not through a package the gate could pin; CI installs 2.1.283 with
npm. `--strict` fails a skill with no name or description, but not malformed YAML in the front
matter, which it reads leniently.

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
