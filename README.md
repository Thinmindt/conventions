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
  It carries `check_private.sh`, the privacy check every public project copies into `scripts/`
  unchanged; a project adds its own terms with `scripts/private_terms.sh`.

A session-start hook reminds Claude to offer the audit when a project with a `CLAUDE.md` or a
`docs/` directory has not had one for 30 days (`DOC_AUDIT_DAYS` changes that). The date of the
last audit is kept per project under `${XDG_STATE_HOME:-~/.local/state}/conventions/doc-audit/`,
outside the project, so it never shows up in a diff.

## Plans

What comes next is in [docs/ROADMAP.md](docs/ROADMAP.md). How this plugin compares with
published agentic-engineering practice is in [docs/survey-2026-09.md](docs/survey-2026-09.md), as
of that date.

## Checks

`scripts/check.sh` runs every gate, locally and in CI: the privacy check (and that its copy still
matches the template), `scripts/check_version.sh` (a change to what the plugin ships comes with a
version bump), the JSON files parse, shellcheck, codespell, `scripts/check_examples.sh`,
which parses every `python` example in the skills and runs ruff over them with the rules the guide
itself states, and `scripts/test_scripts.sh`, which exercises the scripts in throwaway directories.
It needs `uv`; the tools run through `uvx` at pinned versions.

## Installing

```
claude plugin marketplace add Thinmindt/conventions
claude plugin install conventions@conventions
```

## In a project

A project's `docs/STYLE.md` links to the guide instead of carrying a copy:

```
This project follows [the conventions style guide](https://github.com/Thinmindt/conventions/blob/main/skills/python-style/SKILL.md).
```

`scripts/check_private.sh` is the one file a project copies, unchanged, from
`skills/doc-audit/`; its terms live outside the copy.

## Updating

A change to `skills/`, `hooks/` or `agents/` bumps `version` in `.claude-plugin/plugin.json`;
the gate compares both with `origin/main` and refuses the change if the version stayed. Once the
change is on main, tag the release from a clean checkout of it:

```
claude plugin tag --push
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
