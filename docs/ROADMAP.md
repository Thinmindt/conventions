# Roadmap

The plan as it stands. Each entry says what, how, and what **done means**. A box is ticked by the
change that earns it. Finished items move verbatim to `ROADMAP-archive.md` under the same number,
with the date they moved. Numbers never change. The reasoning behind most entries is in
[survey-2026-09.md](survey-2026-09.md).

The numbers give the intended order. 1, 2, 8 and 13 are small and independent. 5 comes before
the new skills (6, 9, 10, 14), so each one can be shown to earn its place.

## 1. Validate the plugin in the gate

`claude plugin validate --strict` checks the manifests and every skill's front matter. It passes
today, but nothing runs it.

- [ ] Add it to `scripts/check.sh`, pinned to a Claude Code version the way shellcheck and codespell
  are pinned. First confirm it runs without credentials on CI. If it does not, the gate skips it
  with a message, as the privacy check does with no terms.

**Done means:** a SKILL.md with broken front matter fails `scripts/check.sh` locally and in CI.

## 2. Trigger the audit by change, not by time

Thirty days stands in for how much has changed, and stands in badly: a project untouched for a
year has nothing new to audit, and one that changed heavily last week does. The stamp under
`~/.local/state` is also per machine, so an ephemeral machine, such as a cloud session container,
reports "no audit recorded" in every session, and a second workstation repeats an audit already
done.

- [ ] `doc-audit.sh mark` prints a `Doc-Audit: <date>` trailer for the audit's commit, so the
  commit that carries the audit's fixes also marks the state that was audited. Nothing is written
  outside the tree; the state directory goes, and `DOC_AUDIT_DAYS` with it.
- [ ] `doc-audit.sh check` finds the newest commit with that trailer and measures what has changed
  since it: lines added and removed in tracked files (`git diff --shortstat`), working tree
  included. It reminds when the total passes `DOC_AUDIT_CHANGED_LINES`, or when no audit commit
  exists, and the message gives the audit's date, the lines changed and the threshold. The default
  threshold is a measurement, not a guess: take the lines a few months of ordinary work changed in
  a real project, and record the number and its date in the archive.
- [ ] Code counts as well as documents, because documents rot most when the code moves and they
  stand still. Untracked documents (`CLAUDE.local.md`, notes) are outside git's view, so nothing
  triggers on them; the skill says they are checked whenever an audit runs for any other reason.
- [ ] In a shallow clone the audit commit may lie beyond the cut. When no trailer is reachable and
  `git rev-parse --is-shallow-repository` says true, `check` says it cannot tell, rather than
  reminding.
- [ ] Update the skill's "Report" and "Between audits" sections, the README and
  `scripts/test_scripts.sh`.

**Done means:** in a fresh clone on any machine, `check` is silent right after an audit commit and
reminds once enough has changed since it. `scripts/test_scripts.sh` covers no audit, a fresh
audit, churn past the threshold, and a shallow clone.

## 3. Move the documentation rules out of python-style

Design documents, plans and the roadmap rule apply in every language. A session with no Python
has no reason to load a skill called python-style.

- [ ] New skill `docs-style`: "Design documents" and "Plans" from python-style, moved verbatim.
  python-style keeps a one-line pointer to it.
- [ ] Update the cross-references in doc-audit and the README. Decide whether a project's
  `docs/STYLE.md` carries both skills, and update the drift `diff` in the README to match.

**Done means:** python-style mentions no document type other than docstrings and comments. An eval
case (§5) shows `docs-style` loading when a design document is edited in a project with no Python.

## 4. Enforce at the moment of change

Skills are guides. The only sensor is the gate, and it runs when someone runs it. Start with the
rule whose failure is costliest to undo.

- [ ] A PreToolUse hook on `Bash` that matches `git push`. It runs the project's
  `scripts/check_private.sh`, if the project has one, and blocks the push with the check's output
  when it fails.
- [ ] A git pre-push hook that runs the same check, installed by the project bootstrap (§7), so a
  push made outside an agent session is covered too.
- [ ] Measure before adding more. Candidates: a PostToolUse formatter on `*.py` when the project
  configures ruff, and a Stop hook that runs the gate on request (a `userConfig` option, off by
  default).

**Done means:** in a session, a `git push` with a private term in an unpushed commit is refused
and Claude sees why. `scripts/test_scripts.sh` feeds the hook its JSON input and asserts both the
block and the pass.

## 5. Evaluate the skills

Nothing shows that a skill loads when it should, stays out when it should not, or changes the
result.

- [ ] `evals/` with a `claude plugin eval` suite:
  - one triggering case per skill, for example a threaded consumer for python-traps or a new
    design-document entry for docs-style;
  - one negative case, a JavaScript task that loads no Python skill;
  - one behaviour case per skill, for example a narrated `if` gets a name, or a `yield` under a
    lock is refused.
- [ ] Run with `--ablation with-without`, so each skill's effect is measured against no plugin.
- [ ] Record each skill's context cost (`claude plugin details`), with the date. Try a `paths:`
  scope on python-style and keep it if no triggering case regresses.

**Done means:** `claude plugin eval` runs the suite locally, and the first results, with their date
and run count, are in the archive. The suite is not a CI gate: it costs tokens and needs
credentials.

## 6. Turn a correction into a rule

"Each rule paid for once" relies on someone remembering to write the rule. Warp, Every and the
Claude Code team write the lesson back as part of the work.

- [ ] A user-invoked skill, `record-lesson` (`disable-model-invocation: true`). From the correction
  in the current session, it drafts the rule in house form: the fact, the failure it prevents,
  the measurement. It then picks the rule's home, in this order:
  1. a lint rule or check (§12);
  2. python-traps or python-style in this plugin;
  3. the project's own agent guide;
  4. nowhere, when the rule holds only for one installation.
- [ ] It works on a branch in this repository, bumps the version and runs the gate. It never pushes.

**Done means:** after a correction in a project session, invoking the skill leaves a branch here
that has the new entry in the chosen file and passes `scripts/check.sh`.

## 7. Set up a project, and check it for drift

Copying `docs/STYLE.md` and `check_private.sh` is manual, and so is the `diff` that finds drift.

- [ ] A plugin executable, `bin/conventions-project`.
  - `init` writes the files a project takes from this plugin: `docs/STYLE.md`,
    `scripts/check_private.sh`, a `scripts/check.sh` skeleton, the CI workflow, the pre-push hook
    (§4) and a short agent guide (§8).
  - `check` reports each copied file that differs from its template and exits non-zero.
- [ ] Replace the README's manual `diff` with `conventions-project check`, and have doc-audit run it.

**Done means:** `init` in an empty git repository gives a project whose `scripts/check.sh` passes.
After one line of its `docs/STYLE.md` is edited, `check` names that file and fails. Both are
covered by `scripts/test_scripts.sh`.

## 8. An agent guide here, and AGENTS.md for other tools

This repository has no CLAUDE.md or AGENTS.md, though doc-audit's table gives the agent guide a
role. The rules a contributor must know are in the README or nowhere. Projects touched by Codex,
Copilot, Warp or Cursor get none of these conventions.

- [ ] `AGENTS.md` here, as a table of contents of under 60 lines: run `scripts/check.sh`, bump the
  version on every change, keep `check_private.sh` identical to its template, and where plans and
  the survey live. Add `CLAUDE.md` holding `@AGENTS.md`.
- [ ] The agent guide that `conventions-project init` writes (§7) follows the same shape and points
  at `docs/STYLE.md`, so tools other than Claude Code read the conventions too.

**Done means:** both files exist, `AGENTS.md` is under 60 lines, and nothing in it is also stated in
the README.

## 9. How a change is carried out

The plugin says how code and documents are written, not how a change moves from idea to merge.
Every published workflow surveyed covers that loop.

- [ ] A `change-workflow` skill, sized to the change:
  - one-sentence diffs skip the plan;
  - anything larger starts as a roadmap entry with its "done means";
  - a regression test is seen to fail before the fix (red/green);
  - the gate runs, with its result reported as evidence, before the change is called done;
  - structural and behavioural changes go in separate commits.
- [ ] It links python-style and docs-style rather than repeating them.

**Done means:** an eval case (§5) that asks for a small feature shows the roadmap entry written
first, the gate run, and its output quoted before completion is claimed.

## 10. A reviewer in a fresh context

The writer's context favours its own choices. A read-only subagent reviews the diff against the
conventions, and nothing else.

- [ ] `agents/conventions-reviewer.md`, limited to Read, Grep, Glob and `git diff`. It reports only
  violations of python-style, python-traps and docs-style, each with file, line and the rule
  broken. It offers no improvements beyond the rules.

**Done means:** given a diff seeded with a `yield` under a lock, a `print()` in a service and a
bare `noqa`, it reports all three and nothing else (an eval case in §5).

## 11. Run the audit unattended when it is due

A reminder waits for someone to accept it. OpenAI runs its doc-gardening agent on a schedule; here
the trigger is change (§2), so the same measurement can start the audit without a session.
Depends on §2.

- [ ] A GitHub Actions workflow on push to the default branch runs `doc-audit.sh check`. When the
  audit is due, it runs the doc-audit skill headless, commits to a branch with the §2 trailer and
  opens a pull request with the report. It never merges, and it never touches untracked
  documents.
- [ ] State which projects opt in, and how, in the doc-audit skill.

**Done means:** on a real project, the push that crossed the threshold opened a pull request whose
report follows the skill's "Fixed / Needs the owner / Questions" form, and the first push after
that pull request merged opened nothing.

## 12. Name the linter behind each rule

Several rules in python-style and python-traps map onto existing ruff rules, and the guide does
not name them. A rule a linter enforces needs no agent to remember it.

- [ ] Go through both skills and add a short "Enforced by" line to each rule that has one. Examples:
  - `print()` → T201
  - f-string logging → G004
  - `except Exception` → BLE001
  - banned device imports → TID251
- [ ] A recommended `[tool.ruff.lint]` block in python-style's Tooling section, which `init` (§7)
  copies.
- [ ] Rules no ruff rule covers, such as a bare `noqa` without a reason or an unbounded
  `join()`, are listed as candidates for a small check. Each check prints how to fix the problem,
  not only where it is.

**Done means:** every rule in both skills is marked either with the linter that enforces it or as
judgement. A project seeded by `init` fails its gate on `log.info(f"...")`.

## 13. CI and release hygiene

- [ ] Pin `actions/checkout` and `astral-sh/setup-uv` to commit SHAs, with the version as a comment.
  Set `permissions: contents: read` on the workflow.
- [ ] Either stop hand-bumping by dropping `version` from `plugin.json` (installs then track the
  commit), or have the gate fail when `skills/`, `hooks/` or `agents/` differ from `origin/main`
  and the version does not. Choose one, and update the README's "Updating" section.
- [ ] Tag releases with `claude plugin tag` if versions stay.

**Done means:** the workflow runs green with SHA-pinned actions and read-only permissions, and a
change to a skill without a version decision fails the gate or needs no decision.

## 14. Traps for running agents unattended

python-traps covers unattended Python services, but not unattended agents. The failures are just
as specific.

- [ ] Add a section to python-traps, or a new skill if §5 shows a separate one triggers better:
  - never combine private data, untrusted content and a way to send data out in one session (the
    lethal trifecta);
  - prefer permission allowlists to skipping permissions;
  - YOLO mode only in a container with restricted egress;
  - treat issue and PR text as data, not instructions;
  - an agent's credentials cannot push to the default branch.

**Done means:** each rule names the failure it prevents, as the other traps do, and an eval case
shows the skill loading when an unattended agent workflow (§11) is written.

## Open questions

Not yet plans. Each becomes a numbered entry or leaves this list once it is decided.

- **Holdout scenarios.** StrongDM grades agents against end-to-end scenarios kept where the agent
  cannot see or edit them. Would a private scenario set help the services these conventions are
  written for, and where would it live?
- **An agent-readable task tracker.** Steve Yegge's beads and Anthropic's JSON feature list replace
  prose plans. The roadmap already works as the tracker for one owner. Revisit if several agents
  work on one project at once.
- **Measuring the factory.** Warp scores its factories and StrongDM measures "satisfaction". What
  cheap signal would show these conventions help? Candidates: eval pass rates over time (§5), how
  many lessons are recorded per month (§6), and how many doc-audit findings each audit turns up.
- **Parallel sessions.** Worktrees per task (Cherny, Superpowers), or several agents in one folder
  with atomic commits (Steinberger). Decide once §9 exists.
