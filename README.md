# conventions

A Claude Code plugin carrying how code is written in every project, whatever machine it runs on.
Two skills, loaded when the work calls for them:

- **python-style** — the Python style guide: naming over narration, what a comment may say,
  docstrings, logging, interfaces versus internals, errors, tests, tooling, and how to write a
  design document so it is still true months later. The skill body *is* the guide; a new project
  copies it to `docs/STYLE.md` so people can read it without Claude.
- **python-traps** — rules for code that runs unattended: threads and locks, callbacks on someone
  else's thread, files that must survive a crash, network filesystems, services under systemd,
  uv with apt-only packages, and what may go in a public repository. Each names the failure it
  prevents; each was paid for once.

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
