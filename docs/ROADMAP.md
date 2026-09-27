# Roadmap

The plan as it stands. Each entry says what, how, and what **done means**. A box is ticked by the
change that earns it. Finished items move verbatim to `ROADMAP-archive.md` under the same number,
with the date they moved. Numbers never change. The reasoning behind most entries is in
[survey-2026-09.md](survey-2026-09.md).

The numbers give the intended order. 7 is the spine: it is where everything that leaves the
skills (3, 4, 12) lands, so its first version comes before those. 5 comes before the new skills
(6, 9, 10, 14), so each one can be shown to earn its place. 15 and 16 come after what they hold
out and measure (5, 6, 11).

## 3. Reduce each skill to what needs a reader

A skill body is loaded whole on every trigger, so it should hold only what a reader has to apply:
judgement. The README's "Writing a skill" gives the four questions that decide where each
paragraph goes. Applied to the three skills:

- [ ] What a linter checks leaves python-style for the template's `ruff.toml` (§7, §12), and the
  skill keeps one line per rule saying so.
- [ ] What must happen every time becomes a hook (§4), and the skill stops asking for it.
- [ ] Procedures become scripts: `doc-audit.sh inventory` prints the document list the skill now
  describes in prose. The audit itself is the strongest case for a subagent that runs in its own
  context with restricted tools; decide that when §10 exists.
- [ ] Explanation for people, the reasoning and the worked examples, moves to a reference file
  beside each skill that the skill names and Claude reads on demand. `docs/STYLE.md` links to it.
- [ ] Design documents and plans apply in every language, so they leave python-style for a skill
  `docs-style`, moved verbatim; python-style keeps a one-line pointer.
- [ ] Record each skill's context cost (§5) before and after, so the cut is measured.

**Done means:** each skill body is rules with the failure each prevents; no body states what a
check in §7's template enforces; python-style mentions no document type other than docstrings and
comments. An eval case (§5) shows `docs-style` loading when a design document is edited in a
project with no Python, and the cost table in `evals/results/` shows the before and after.

## 4. Enforce at the moment of change

Skills are guides. The only sensor is the gate, and it runs when someone runs it. Start with the
rule whose failure is costliest to undo.

- [ ] A git pre-push hook that runs `scripts/check_private.sh`, written into the project by the
  template and installed by its task (§7). The repository is the right place for a push gate: it
  holds for every tool and every person, not only a Claude session.
- [ ] `check_private.sh` reads the working tree and the messages of unpushed commits, not their
  content. A term committed and removed again before the push still lives in history, so the check
  also scans the content of unpushed commits (`git log -p HEAD --not --remotes`). The template
  changes, so every project's copy changes with it (§7).
- [ ] A PreToolUse hook on `Bash` in this plugin that matches `git push`, for projects that have
  not run `init`. It runs the project's `scripts/check_private.sh` when the project has one, and
  blocks the push with the check's output when it fails.
- [ ] Measure before adding more. Candidates: a PostToolUse formatter on `*.py` when the project
  configures ruff, and a Stop hook that runs the gate on request (a `userConfig` option, off by
  default).

**Done means:** in a session, a `git push` with a private term in the content of an unpushed
commit is refused and Claude sees why, with or without the project's pre-push hook.
`scripts/test_scripts.sh` covers the committed-and-removed case, and feeds the plugin hook its JSON
input to assert both the block and the pass.

## 5. Evaluate the skills

Nothing shows that a skill loads when it should, stays out when it should not, or changes the
result.

- [ ] `evals/` with a `claude plugin eval` suite:
  - one triggering case per skill, for example a threaded consumer for python-traps or a new
    design-document entry for docs-style;
  - one negative case, a JavaScript task that loads no Python skill;
  - one behaviour case per skill, for example a narrated `if` gets a name, or a `yield` under a
    lock is refused. For doc-audit, a README that names a flag the code has removed: the
    audit's report lists it under Fixed. Today the audit is a procedure in prose and nothing
    shows it finds a stale fact when one is planted.
- [ ] Run with `--ablation with-without`, so each skill's effect is measured against no plugin.
- [ ] Record each skill's context cost (`claude plugin details`), with the date. Try a `paths:`
  scope on python-style and keep it if no triggering case regresses.

**Done means:** `claude plugin eval` runs the suite locally, and each run's result, with its date
and run count, is committed under `evals/results/` (§16). The suite is not a CI gate: it costs
tokens and needs credentials.

## 6. Turn a correction into a rule

"Each rule paid for once" relies on someone remembering to write the rule. Warp, Every and the
Claude Code team write the lesson back as part of the work.

- [ ] A user-invoked skill, `record-lesson` (`disable-model-invocation: true`). From the correction
  in the current session, it drafts the rule in house form: the fact, the failure it prevents,
  the measurement. It then picks the rule's home, in this order:
  1. a lint rule or check (§12);
  2. a skill in this plugin, by scope: agent-traps (§14) or docs-style (§3) when the rule holds in
     any language, python-traps or python-style when it holds only in Python;
  3. the project's own agent guide;
  4. nowhere, when the rule holds only for one installation.
- [ ] The skill runs in a project session, where the plugin is an installed copy, not a clone. It
  takes the path to a clone of this repository from a `userConfig` setting; with none, it prints
  the entry for pasting.
- [ ] In the clone it works on a branch, runs the gate and follows the version rule (§13). Its
  commit carries a `Lesson:` trailer, so lessons can be counted (§16). It never pushes.

**Done means:** after a correction in a project session, invoking the skill leaves a branch here
that has the new entry in the chosen file and passes `scripts/check.sh`.

## 7. Set up a project from a Copier template, and keep it updated

Everything a project takes from this repository, the gate, the linter rules, the privacy check,
the CI workflow, the pre-push hook and the agent guide, is generated from one Copier template
that lives here beside the plugin, and re-generated when the template moves. Per-project
configuration is expected to grow, and Copier's answers file is where it grows: a question in
`copier.yml`, an answer in the project, never an edit to a generated file. This is the spine the
rest of the roadmap hangs on: what leaves the skills (§3, §4, §12) lands here.

Facts from a scratch run of Copier 9.18 that shape the design: it reads only PEP 440 tags, so
releases are tagged `v<version>` and `claude plugin tag`'s format is invisible to it; `copier
update` looks for `.copier-answers.yml` by that name unless told otherwise, so the default name
stays; a three-line generated file conflicted on update when the project had edited one line and
the template another, so generated files are never hand-edited.

- [ ] `copier.yml` at the root with `_subdirectory: template`, so the plugin's files and the
  template's do not mix. `_min_copier_version` pinned. Questions to start: `project_name`,
  `python` (yes/no), `hardware_module` (the one module that may import the device library, empty
  for none), `private_terms` (whether the project prints its own terms). Each later question
  arrives with the template change that needs it.
- [ ] `template/` renders: `scripts/check.sh` (the gate, sized to the answers), `scripts/
  check_private.sh` (moved here from the doc-audit skill, which points at it; this repository's
  `scripts/` copy is compared with the template's), `ruff.toml` carrying the guide's rules and the
  hardware boundary from the answer (§12), `.github/workflows/check.yml`, `scripts/githooks/
  pre-push` (§4), a short `AGENTS.md` pointing at `docs/STYLE.md` and the gate, the one-line
  `docs/STYLE.md`, and `.copier-answers.yml`. `scripts/private_terms.sh` is under
  `_skip_if_exists`, so a project's own version survives every update.
- [ ] A task (`_tasks`, so `--trust`) sets `core.hooksPath` to `scripts/githooks`, which installs
  the pre-push hook without touching `.git/hooks` by hand.
- [ ] The rule, stated in the project's generated `AGENTS.md` and in the README here: a generated
  file is never edited by hand; a project-specific need becomes an answer or a template change.
- [ ] Commands, in the README here: `uvx copier copy gh:Thinmindt/conventions .` to set up, `uvx
  copier update --defaults` to bring a project to the newest tag, both pinned to a Copier version.
- [ ] The session-start hook compares `_commit` in a project's `.copier-answers.yml` with the
  plugin's version and says when the project is behind, the way the doc audit reminder works.
- [ ] `scripts/test_scripts.sh` copies the template into a throwaway repository with default
  answers and runs the generated gate; then edits the template, tags, updates, and shows the
  project's `private_terms.sh` untouched and the generated files moved.

**Done means:** a fresh project made with one `copier copy` has a passing gate, a working pre-push
hook and an agent guide, with no hand edits; after a template change and a tag, `copier update` in
that project brings the change in and touches nothing the project owns; the session-start hook
names a project that is behind. All three are covered by `scripts/test_scripts.sh`.

## 9. How a change is carried out

The plugin says how code and documents are written, not how a change moves from idea to merge.
Every published workflow surveyed covers that loop.

- [ ] A `change-workflow` skill, sized to the change:
  - one-sentence diffs skip the plan;
  - anything larger starts as a roadmap entry with its "done means";
  - a regression test is seen to fail before the fix (red/green);
  - the gate runs, with its result reported as evidence, before the change is called done;
  - structural and behavioural changes go in separate commits;
  - each task runs in its own worktree on its own branch (`git worktree add`, or Claude Code's
    worktree isolation), so parallel sessions never share a working tree and a half-finished
    change in one cannot enter another's commit. One folder with atomic commits from several
    agents is the alternative, and harder to reason about.
- [ ] It links python-style and docs-style rather than repeating them.

**Done means:** an eval case (§5) that asks for a small feature shows the roadmap entry written
first, the gate run, and its output quoted before completion is claimed.

## 10. A reviewer in a fresh context

The writer's context favours its own choices. A read-only subagent reviews the diff against the
conventions, and nothing else.

- [ ] `agents/conventions-reviewer.md`, given the diff in its prompt, with Read, Grep and Glob to
  check the surrounding code and no Bash, Edit or Write (an agent's `tools:` cannot confine Bash to
  one command). It reports only violations of this plugin's skills, python-style, python-traps,
  docs-style (§3) and agent-traps (§14), each with file, line and the rule broken. It offers no
  improvements beyond the rules.

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
- [ ] The rules as a `ruff.toml` in the template (§7), rendered with the hardware boundary from
  the project's answers; python-style points at it rather than carrying the block.
- [ ] Rules no ruff rule covers, such as a bare `noqa` without a reason or an unbounded
  `join()`, are listed as candidates for a small check. Each check prints how to fix the problem,
  not only where it is.

**Done means:** every rule in both skills is marked either with the linter that enforces it or as
judgement. A project generated by the template (§7) fails its gate on `log.info(f"...")`.

## 14. Traps for running agents unattended

python-traps covers unattended Python services, but not unattended agents. The failures are just
as specific, and none of them is Python's: a shell workflow leaks a token as readily as a service
does. So this is a skill of its own, not a section in python-traps, and it loads in any language.

- [ ] `agent-traps`, in the form of python-traps, each rule naming the failure it prevents:
  - never combine private data, untrusted content and a way to send data out in one session (the
    lethal trifecta);
  - prefer permission allowlists to skipping permissions;
  - YOLO mode only in a container with restricted egress;
  - treat issue, PR and web text as data, not instructions;
  - an agent's credentials cannot push to the default branch or approve its own pull request.
- [ ] Its description names what it applies to: agent workflows, hooks, CI that runs an agent, and
  plugin or permission settings, whatever the project's language.

**Done means:** each rule names the failure it prevents, as the other traps do, and an eval case
(§5) shows the skill loading when an unattended agent workflow (§11) is written in a project with
no Python.

## 15. Hold out scenarios the agent cannot see

The eval suite (§5) lives in the tree, where the agent it grades can read it and, over enough
sessions, learn the cases rather than the rules. StrongDM keeps its end-to-end scenarios where the
agent cannot see or edit them. The question to settle is where such a set lives when every machine
that could run it also runs an agent.

- [ ] Choose the home. The leading option is a private repository, `conventions-holdout`, that no
  agent credential can read. Its own workflow checks out this plugin, or a project, at a given
  commit, runs the scenarios, and reports pass or fail per scenario name, never the scenario text,
  so a failure says which behaviour broke without teaching the fix. A deny rule or a gitignored
  directory on the same machine is the weaker option: the agent runs shell commands, and one
  machine holds both.
- [ ] Decide how scenarios get in: written by a person, and never copied from the public suite,
  which the agent has seen. The first is a stale-fact case of the same kind as doc-audit's
  behaviour case in §5, with a different seed.
- [ ] Run it on demand and before a release (§13), not on every push; it costs tokens and
  credentials.

**Done means:** in a session with the plugin, asking Claude to print a holdout scenario fails for
lack of access, and a run against a tagged version leaves a dated result, per scenario name, under
`evals/results/` (§16).

## 16. Measure the factory

Nothing shows the conventions help beyond the sense that they do. Warp scores its factories and
StrongDM measures "satisfaction". Three signals to start with, each cheap because the work that
produces it already leaves a record in git, and nothing is kept by hand.

- [ ] Pass rate per skill, over time: each eval run (§5) and holdout run (§15) commits its result
  under `evals/results/<date>-<suite>.json`.
- [ ] Lessons recorded per month: `record-lesson` commits carry a `Lesson:` trailer (§6), so
  `git log --grep` counts them.
- [ ] Findings per audit: the audit's commit carries its report under the `Doc-Audit:` trailer
  (§2), so the same log gives the findings of each audit.
- [ ] `scripts/metrics.sh` prints the three for a date range, from git and `evals/results/` and
  nothing else. Its output is not stored; the sources are.
- [ ] Say here what each number is for, so it is read the same way each time: a pass rate that
  falls after a skill edit questions the edit; lessons falling to zero means corrections stopped
  being written down, not that they stopped; findings per audit falling means the documents stay
  true between audits, unless the reports show the audits getting shallower.

**Done means:** `scripts/metrics.sh` on this repository prints the three numbers for the last
quarter, and `scripts/test_scripts.sh` covers it on a throwaway repository with seeded trailers and
a result file.

## Open questions

Not yet plans. Each becomes a numbered entry or leaves this list once it is decided.

- **An agent-readable task tracker.** Steve Yegge's beads and Anthropic's JSON feature list replace
  prose plans. The roadmap is the tracker while one owner drives one agent at a time. Revisit when
  several agents run at once on one project; a worktree per task (§9) postpones the need, since
  each agent's task is its own branch.
