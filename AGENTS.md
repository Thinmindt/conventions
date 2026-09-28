# Agent guide

The table of contents for working on this repository. Each rule lives in one place, named here,
and is not restated.

## What this is

A Claude Code plugin and the Copier template beside it: the skills under `skills/`, the
session-start hooks in `hooks/`, the template under `template/`, and the scripts that check them.
What each skill does, and how the plugin is installed: the README.

## Before a change is done

- The gate passes: `scripts/check.sh`, described under "Checks" in the README.
- If what the plugin ships moved, so did its version: "Updating" in the README.
- A new or changed skill description follows "Writing a skill" in the README.

## Where things are

- The plan as it stands: `docs/ROADMAP.md`, whose introduction gives the rules for keeping it.
  Finished entries: `docs/ROADMAP-archive.md`.
- How the plugin compares with published practice, as of its date: `docs/survey-2026-09.md`.
- The rules for design documents and plans in any project: the python-style skill, "Design
  documents" and "Plans". They apply to `docs/` here.
- What a project is generated from: `copier.yml` and `template/`, described under "In a
  project" in the README. `scripts/check_private.sh` here is this repository's own copy of the
  template's.

## Habits

- Each rule in a skill names the failure it prevents, and was paid for once. A correction made
  in a session is a candidate rule; roadmap §6 says where it goes.
- An audit of the documents here is recorded the way the doc-audit skill's "Report" says.
