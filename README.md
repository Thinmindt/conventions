# conventions

A Claude Code plugin carrying how code is written in every project, whatever machine it runs on.
Three skills, loaded when the work calls for them:

- **python-style** — the Python style guide: naming over narration, what a comment may say,
  docstrings, logging, interfaces versus internals (hardware behind a boundary), errors, tests,
  tooling, how to write a design document so it is still true months later, and how to keep a
  roadmap the plan as it stands. The skill body *is* the guide; a project's `docs/STYLE.md` is
  one line linking to it, so people read it without Claude and no copy drifts.
- **python-traps** — rules for code that runs unattended: threads and locks, callbacks on someone
  else's thread, files that must survive a crash, network filesystems, services under systemd,
  uv with apt-only packages, and what may go in a public repository. Each names the failure it
  prevents; each was paid for once.
- **doc-audit** — a periodic hard look at every document in a project, tracked or not: true to
  the code and the machine, current (plans are the plan as it stands, history archived), each
  fact in one place, nothing private, nothing tied to one installation or one person's settings.
  The privacy check every project's gate runs first, `scripts/check_private.sh`, is generated
  from the template below; a project adds its own terms with `scripts/private_terms.sh`.

A session-start hook reminds Claude to offer the audit when a project with a `CLAUDE.md`, an
`AGENTS.md` or a `docs/` directory has changed by more than 2000 lines since its last audit, or
has no audit recorded (`DOC_AUDIT_CHANGED_LINES` changes the threshold). An audit is recorded by
a `Doc-Audit: <date>` trailer on the commit that carries it, so it travels with the repository
and nothing is written outside the tree.

## Plans

What comes next is in [docs/ROADMAP.md](docs/ROADMAP.md). How this plugin compares with
published agentic-engineering practice is in [docs/survey-2026-09.md](docs/survey-2026-09.md), as
of that date.

## Checks

`scripts/check.sh` runs every gate, locally and in CI: the privacy check (and that its copy still
matches the template), `scripts/check_version.sh` (a change to what the plugin ships comes with a
version bump), the JSON files parse, `claude plugin validate --strict` over the manifests and
the skills (with the `claude` on PATH, or skipped with a message; CI installs a pinned version),
shellcheck, codespell, `scripts/check_examples.sh`,
which parses every `python` example in the skills and runs ruff over them with the rules the guide
itself states, and `scripts/test_scripts.sh`, which exercises the scripts in throwaway directories.
It needs `uv`; the tools run through `uvx` at pinned versions.

## Installing

```
claude plugin marketplace add Thinmindt/conventions
claude plugin install conventions@conventions
```

## In a project

A project is generated from the Copier template in this repository, `copier.yml` and
`template/`, and updated from it:

```
uvx copier==9.18.2 copy --trust gh:Thinmindt/conventions .
uvx copier==9.18.2 update --defaults --trust
```

The questions decide what is generated: the project's languages (Python, C#, C and C++, JavaScript,
any mix) choose the gate's steps, and for Python the type checker (ty, pyright or mypy, added as a
pinned dev dependency by a task) and the hardware boundary. Every project gets the gate script and
the CI workflow that runs it, the privacy check and a pre-push hook that refuses a push carrying a
private term, an agent guide, and a one-line `docs/STYLE.md` that links to the guide instead of
carrying a copy; a Python project also gets `ruff.toml` with the guide's rules. The gate's steps
for the other languages arrive with roadmap §18, §19 and §20. The answers live in
`.copier-answers.yml`. A generated file is never edited by hand: a project-specific need is an
answer, or a change to the template. `scripts/private_terms.sh` is the project's own and survives
every update. `--trust` is needed because the template's tasks install the hook and ignore
`.private-terms`. Copier reads only `v<version>` tags, so a project updates to the newest release,
and a session-start hook says when a project is behind the installed plugin.

## Updating

A change to `skills/`, `hooks/`, `agents/`, `template/` or `copier.yml` bumps `version` in
`.claude-plugin/plugin.json`; the gate compares them with `origin/main` and refuses the change if
the version stayed. The template needs the tag as much as the plugin does, since a project
updates only to a tag. Once the
change is on main, tag the release from a clean checkout of it, as `v<version>`, which is the
form Copier reads (roadmap §7):

```
git tag -a v1.3.0 -m "conventions 1.3.0" && git push origin v1.3.0
```

Then on each machine:

```
claude plugin marketplace update conventions
claude plugin update conventions@conventions
```

## Writing a skill

A skill's `description` is the only thing Claude reads before deciding whether to load it, so it
is written for that decision and nothing else. First what the skill covers, in the words a task
would use: the things being written, the libraries, the file types. Then `Use when`, naming the
situations. Then, where a near miss is likely, what it does not cover. It does not summarise the
body, and it stays under 1024 characters, the limit Claude Code enforces. The three skills here
are the pattern; a description that reads well but names no situation will not load.

The body is loaded whole on every trigger, so it holds only what needs a reader. For each
paragraph, in order: can a machine check it? Then it is a linter rule or a check, and the skill
keeps one line saying so. Must it happen every time? Then it is a hook. Is it a procedure with
steps? Then it is a script whose output the skill interprets, or a subagent. Is it judgement?
Then it stays, as the rule and the failure it prevents. What is left is explanation for people,
which goes in a reference file beside the skill, named by it and read on demand.
