---
name: doc-audit
description: A hard look at every document in a project — tracked docs, local notes, to-do lists, agent memory and the install instructions of companion repos — so that each is true to the code and the machine, current (plans are the plan as it stands, history archived), stated once in the place it is most useful, safe to publish, and free of one installation's or one person's settings. Use when the session-start reminder says an audit is due, or when asked. During other work, when you notice a document that contradicts the code or the machine, a plan that is no longer the plan, a fact stated in two places, or a private or installation-specific detail in a tracked file, say so and offer this audit; do not start it unasked.
---

# Documentation audit

Documents rot quietly: the code moves on, a plan is half done, a number was true on the day it
was measured, and a fact written in two places is soon true in one. This audit finds that rot and
fixes it, on a schedule rather than by accident. Every document should come out of it:

1. **True** — it matches the code, the data and the machine as they are today.
2. **Current** — a plan is the plan as it stands; finished work and history have moved out.
3. **In one place** — each fact lives where it is most useful, and everywhere else points there.
4. **Safe to publish** — nothing private in a tracked file or a commit.
5. **General** — nothing depends on one installation's hardware or one person's settings.

## Take inventory first

List every document before judging any of them, because the stale ones are usually the ones
nobody opens:

- **Tracked:** `git ls-files '*.md'`, plus prose that ships in code (docstrings, comments,
  templates, unit files, scripts' usage text).
- **Untracked:** `git status --ignored --short`, looking for notes such as `CLAUDE.local.md`,
  private `docs/` files and to-do lists.
- **Agent memory:** the project's memory directory, if the agent keeps one. Memories go stale
  like any other document, and a stale one is repeated with confidence.
- **Companion repositories** the docs send a reader to: plugins, kits, templates. Their install
  instructions are part of this project's documentation.

## The checks

Run each check over each document. Fix what is yours to fix; collect what is not for the report.

**True.** Verify, do not trust. Every claim that something is built, installed, running,
measured, merged or pushed is checked against the code, the database, the service or the
remote. Every reference must resolve: file paths, functions, classes, settings and their
defaults, commands, section numbers, links. Try install and clone instructions as a stranger
would, without your credentials (`git ls-remote https://…` needs none for a public repository).
Where two documents disagree, reality decides, not the newer document.

**Current.**

- A plan document holds only the present plan: what is decided, what is next, what is open.
  Finished items, the history behind decisions and measurements that fed a decision now made
  move **verbatim** to an archive beside it, under the same headings or section numbers, with
  the date they moved. Section numbers never change, so citations in commit messages and other
  documents keep resolving.
- A to-do list holds only open items; done ones move to its archive with the note they had.
- Numbers that decay — counts, free space, versions, "as of" snapshots — are re-measured and
  dated, or replaced by how to measure them.
- A design document states decisions, never a pending state (see python-style, "Design
  documents").

**In one place.** Decide where each fact belongs, then make every other mention a pointer:

| document | holds |
|---|---|
| source comments | what the code cannot say; spartan, present tense |
| design document | why the code is as it is: the decision, its reason, its date |
| roadmap and its archive | the plan as it stands; what was done and why it changed |
| agent guide (`CLAUDE.md`) | the traps an agent must not fall into, and how to work here |
| README | what a stranger needs to install and use it |
| local notes (`CLAUDE.local.md`) | this machine and its owner |
| to-do list and its archive | what only the owner can do |
| agent memory | only what none of the above records |

Two statements of one fact are a contradiction waiting to happen: keep the one in the right home
and cut or point the other. Rationale found in a source comment moves to the design document.

**Safe to publish.** Tracked files, commit messages and commit authors are public. Run the
project's private-terms check if it has one; otherwise grep the tracked tree and the unpushed
commits (`git log HEAD --not --remotes`, messages and author lines) for addresses, hostnames,
share names, account names, absolute home paths, tokens, email addresses, and people's and pets'
names. Anything private moves to a gitignored file. If it has already been pushed, report it;
rewriting pushed history is the owner's decision.

**General.** A stranger with different hardware and different settings should be able to follow
every tracked document. Look for:

- Rules that hold only because of one person's configuration (their git identity, shell, editor,
  paths, sudo rights). Replace them with a check the repository runs or a requirement stated
  for every user.
- Installation-specific values written as if universal (a device model, a count, a network
  service, a screen size). Make them configuration with a documented default, or state them as
  "this installation uses X; Y also works because…", and say which choices would change how
  well the project works.
- Examples that use real names. Use made-up ones.

**Consistent with the conventions.** Comments and docstrings follow python-style; design entries
give what, why and when; a project's `docs/STYLE.md` still matches the python-style skill below
its front matter.

## How to run it

- Tracked changes go on a branch and follow the project's review rules; never push, merge or
  restart anything as part of the audit. Untracked documents are edited in place and backed up
  the way the project backs them up.
- Keep the commands read-only while verifying: query, list and grep; do not start services.
- When text moves to an archive, prove nothing was lost: every line of the old file appears in
  the new file or the archive, or is a rewrite you can name.
- Run the project's checks before committing.

## Report

Group the findings:

- **Fixed**, each with its file.
- **Needs the owner:** decisions, hardware, anything needing their credentials or sudo, history
  rewrites.
- **Questions** the audit could not answer from the code, the data or the machine.

Give measurements with their date. Then record the audit, which quiets the session-start
reminder for this project:

```
bash ${CLAUDE_SKILL_DIR}/doc-audit.sh mark
```

## Between audits

The reminder at session start comes when the last recorded audit is more than 30 days old
(`DOC_AUDIT_DAYS` changes that). Between audits, drift you notice while working is fixed if it is
in a file you are already changing and mentioned otherwise, with an offer to run this audit.
