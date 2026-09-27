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

## 2. Trigger the audit by change, not by time (moved 2026-09-27)

Thirty days stands in for how much has changed, and stands in badly: a project untouched for a
year has nothing new to audit, and one that changed heavily last week does. The stamp under
`~/.local/state` is also per machine, so an ephemeral machine, such as a cloud session container,
reports "no audit recorded" in every session, and a second workstation repeats an audit already
done.

- [x] `doc-audit.sh mark` prints a `Doc-Audit: <date>` trailer for the audit's commit, so the
  commit that carries the audit's fixes also marks the state that was audited. The commit's body is
  the audit's report, so the findings travel with the state they describe (§16). Nothing is written
  outside the tree; the state directory goes, and `DOC_AUDIT_DAYS` with it.
- [x] `doc-audit.sh check` finds the newest commit with that trailer and measures what has changed
  since it: lines added and removed in tracked files (`git diff --numstat`), working tree
  included. It reminds when the total passes `DOC_AUDIT_CHANGED_LINES`, or when no audit commit
  exists, and the message gives the audit's date, the lines changed and the threshold.
- [x] The default threshold is a measurement, not a guess, and 500 is a guess. Take the lines a
  few months of ordinary work changed in a real project (`git diff --shortstat` against the
  commit of three months ago), set the default from it, and record the number and its date in
  the archive.
- [x] Code counts as well as documents, because documents rot most when the code moves and they
  stand still. Untracked documents (`CLAUDE.local.md`, notes) are outside git's view, so nothing
  triggers on them; the skill says they are checked whenever an audit runs for any other reason.
- [x] In a shallow clone the audit commit may lie beyond the cut. When no trailer is reachable and
  `git rev-parse --is-shallow-repository` says true, `check` says it cannot tell, rather than
  reminding.
- [x] Update the skill's "Report" and "Between audits" sections, the README and
  `scripts/test_scripts.sh`.

**Done means:** in a fresh clone on any machine, `check` is silent right after an audit commit and
reminds once enough has changed since it. `scripts/test_scripts.sh` covers no audit, a fresh
audit, churn past the threshold, and a shallow clone.

The threshold was not measured. What matters is how much change may have put a document out of
date, and that can be one line, so no measurement of past churn answers it. The default is 2000
lines, the size of a large feature or a set of smaller ones, chosen by judgement on 2026-09-27
and to be adjusted by how the audits feel. `--numstat` replaced `--shortstat` in the script
because it sums cleanly.

## 8. An agent guide here, and AGENTS.md for other tools (moved 2026-09-27)

This repository's agent guide is `AGENTS.md` alone. Claude Code reads an `AGENTS.md` when no
`CLAUDE.md` is in the working directory or above it, and `claude plugin validate --strict` (§1)
refuses a `CLAUDE.md` at a plugin root, so one file serves every tool. Projects touched by Codex,
Copilot, Warp or Cursor still get none of these conventions until `init` (§7) writes them one.

- [x] `AGENTS.md` here, as a table of contents of under 60 lines: run `scripts/check.sh`, the
  version rule as §13 settles it, keep `check_private.sh` identical to its template, and where
  plans and the survey live. No `CLAUDE.md`, here or in any directory above a checkout, since
  one would hide `AGENTS.md` from Claude Code.
- [x] The agent guide that `conventions-project init` writes (§7) follows the same shape and points
  at `docs/STYLE.md`, so tools other than Claude Code read the conventions too.

**Done means:** `AGENTS.md` exists, is under 60 lines, and nothing in it is also stated in the
README.

The first box is done as written. The second, the guide a project gets, is generated by the
Copier template and moved into §7 when the plugin was declared Claude-only and §7 was rebuilt
around Copier; `AGENTS.md` stays the name because Claude Code reads it when no `CLAUDE.md` is
present and the plugin validator refuses a `CLAUDE.md` at a plugin root.

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
Later the same day the tag format became `v<version>`, since Copier (§7) reads only PEP 440 tags
and `claude plugin tag` produces `conventions--v<version>`, which it ignores.
