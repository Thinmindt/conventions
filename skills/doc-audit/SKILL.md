---
name: doc-audit
description: A hard look at every document in a project — tracked docs, local notes, to-do lists, agent memory and the install instructions of companion repos — so that each is true to the code and the machine, current (plans are the plan as it stands, history archived), stated once in the place it is most useful, shaped so a stranger could draw the system from it, readable by a person in a hurry, safe to publish, and free of one installation's or one person's settings. Use when the session-start reminder says an audit is due, or when asked. During other work, when you notice a document that contradicts the code or the machine, a plan that is no longer the plan, a fact stated in two places, a design document whose entries read in the order they were written, or a private or installation-specific detail in a tracked file, say so and offer this audit; do not start it unasked.
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
6. **Shaped** — it can be read whole: its sections are the mechanisms, each opened by how it
   works, with a picture where words would need a dozen entries.
7. **Readable** — a stranger gets its shape in five minutes, and its prose stays inside the
   budgets python-style sets.

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

An untracked document has no copy off the machine unless something makes one. Note how each is
backed up, and report any that is not.

## The project's own rules

Read the project's agent guide (`CLAUDE.md`) for documentation rules of its own — how its
roadmap is numbered, what must be backed up after an edit, which pages need a screenshot — and
apply them alongside the checks below. Run every check script the project has; its privacy
check in particular (below) is where project-specific private terms are defined.

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

**In one place.** Decide where each fact belongs, the place a reader would look for it, then
make every other mention a pointer, or a summary at a higher layer that points there:

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

**Shaped.** Read the document whole before any entry of it, and ask whether a stranger could
draw the system from it. For a design document the shape is python-style's ("Design
documents"): sections are the mechanisms in the order the data flows, each opening with how it
works today and a picture where there is a flow, a state machine or more than one thread; a
principle is stated once; an entry holds a measurement or a failure. The signs of the opposite:
entries in the order they were written, one reason repeated under several entries, a section
that is a third of the document and a grab-bag, a mechanism with a flow and no picture of it. A
picture is a set of claims: each box and arrow is checked against the code like a sentence, and
the picture is rendered and looked at, as a page change is.

`render.py`, beside this skill, renders a Markdown file as GitHub shows it, diagrams included,
and screenshots its first screen and the whole page. Read the images, not just its report that
every diagram rendered:

```
python3 ${CLAUDE_SKILL_DIR}/render.py docs/DESIGN.md /tmp/rendered
```

It needs chromium and the network, and takes a minute or two a page.

**Readable.** Measure every tracked document with the script beside this skill, the summary
tiers first and the evidence after `--detail`:

```
python3 ${CLAUDE_SKILL_DIR}/readability.py README.md docs/*.md --detail docs/design/*.md
```

It reports the average sentence, the long ones and every paragraph over budget, with its line. The
budgets are python-style's ("Written for a person") and bind the summary tiers: there a number
over budget is a finding, and the fix is a shorter sentence, a list, a paragraph split where its
argument turns, or detail moved down a tier, never the evidence cut. Evidence after `--detail` is
measured for information; long sentences belong there, not above it.

Beside the numbers, read the top tier's prose for its register (python-style, "The register
follows the tier"): a figure in a README's prose, an aside in parentheses, or "the maintainer"
where "you" would do is a finding there. The fix moves the figure to its table or the evidence and
rewrites the sentence to the reader.

Then read each document's opening as a stranger would, rendered (above): does it say which question it answers, does it
show the whole shape before the parts, is there an example of each artifact it describes, and are its words the
glossary's? After a large change, run a cold read: an agent started with no memory of the project
reads the opening for five minutes and lists what it could not answer, and each answer goes into
the document.

**Safe to publish.** Tracked files, commit messages and commit authors are public. Look for
network addresses, hostnames, share names, tokens, personal email addresses, and people's and
pets' names; anything private moves to a gitignored file. If it has already been pushed, report
it; rewriting pushed history is the owner's decision.

Every public project carries the check that enforces this, `scripts/check_private.sh`, copied
unchanged from `check_private.sh` in this skill's directory and run first by the project's gate
script. It fails when a term appears in a tracked or about-to-be-added file, or in the author,
committer or message of a commit no remote has yet. Its terms come from two places:

- `.private-terms`, gitignored, one per line: the addresses, hostnames and tokens of this
  installation. Add to it whenever a new one turns up.
- `scripts/private_terms.sh`, tracked and optional: the project's own rule for terms that live
  elsewhere, printed one per line. CatDetector's prints the cats' names from `CAT_NAMES` in
  `.env`, so the names are private without being written down twice.

Without either, as on CI or in a fresh clone, the check passes and says nothing is configured.
If the project's copy has drifted from the template, bring it back and move the difference into
`private_terms.sh`. A project with no copy gets one as part of the audit.

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
- Evidence cut down in the name of generality. A measurement or an incident that justifies a
  decision keeps its numbers and its date (python-style, "Written for a person"); generality
  removes whose setup it was, not how big it was.
- Hardware outside its boundary (python-style, "Hardware sits behind a boundary"). Every
  device library should be importable only inside its implementation, with the linter enforcing
  it; grep for its imports elsewhere, and for device-specific values (models, modes, formats,
  sizes) in code or docs that are not that implementation's.

**Consistent with the conventions.** Comments and docstrings follow python-style; design entries
give what, why and when; a project's `docs/STYLE.md` links to the python-style guide rather than
carrying a copy of it, which would drift. A project that makes the readability budgets a gate
copies `readability.py` into `scripts/` unchanged, as it does `check_private.sh`, and imports
`measure()` in a test; its copy matches this skill's.

## How to run it

- Tracked changes go on a branch and follow the project's review rules; never push, merge or
  restart anything as part of the audit. Untracked documents are edited in place and backed up
  the way the project backs them up.
- Keep the commands read-only while verifying: query, list and grep; do not start services.
- When text moves to an archive, prove nothing was lost: every line of the old file appears in
  the new file or the archive, or is a rewrite you can name.
- When a document is reorganized, do it in commits a reviewer can check: the moves alone,
  proved the same way; then the additions; then the merges, where each deletion stands on its
  own.
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
