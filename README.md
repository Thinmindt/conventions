# conventions

A Claude Code plugin carrying how code is written in every project, whatever machine it runs on.
Three skills, loaded when the work calls for them:

- **python-style** — the Python style guide: naming over narration, what a comment may say,
  docstrings, logging, interfaces versus internals (hardware behind a boundary), errors, tests,
  tooling, how to write a design document so it is still true months later, and how to keep a
  roadmap the plan as it stands. The skill body *is* the guide; a new project
  copies it to `docs/STYLE.md` so people can read it without Claude.
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

What comes next is in [docs/ROADMAP.md](docs/ROADMAP.md). How this plugin compares with published
agentic-engineering practice is in [docs/survey-2026-09.md](docs/survey-2026-09.md), as of that date.

## Checks

`scripts/check.sh` runs every gate, locally and in CI: the privacy check (and that its copy still
matches the template), the JSON files parse, shellcheck, codespell, and `scripts/test_scripts.sh`,
which exercises `doc-audit.sh` and `check_private.sh` in throwaway directories. It needs `uv`; the
tools run through `uvx` at pinned versions.

## Installing

```
claude plugin marketplace add Thinmindt/conventions
claude plugin install conventions@conventions
```

## Updating

After a change, bump `version` in `.claude-plugin/plugin.json` and push. Then on each machine:

```
claude plugin marketplace update conventions
claude plugin update conventions@conventions
```

The guide in `skills/python-style/SKILL.md` and a project's `docs/STYLE.md` are meant to be
identical below the front matter. Check with:

```
diff <(tail -n +6 skills/python-style/SKILL.md) path/to/project/docs/STYLE.md
```
