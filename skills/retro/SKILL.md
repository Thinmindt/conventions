---
name: retro
description: A retrospective at the end of a coding session — what fell short and why, what worked, what cost time — turned into concrete changes to the development process, each put where it will be enforced (a gate, a test, the project's agent guide, the python-traps or python-style skills, or agent memory). Use when a session is wrapping up, when a branch has just been handed over for review, right after a code review found what the gates missed, or when asked what the session teaches. At those moments offer it in one line; do not start it unasked. It proposes; the owner chooses what is applied.
---

# Session retrospective

A lesson that ends as a sentence in the chat is lost with the session. This retrospective finds
what the session can teach and turns each lesson into a change that makes the next session
better: a check the repository runs, a rule in the document an agent reads, a memory. It
proposes; the owner picks; only then is anything changed.

## Gather the evidence first

List what happened before judging any of it, from the record rather than from impressions:

- **Corrections.** Where the owner corrected, redirected or interrupted the work, and every claim
  that had to be retracted.
- **Rework.** What was written twice, reverted, rebased, or fixed after being called done. Every
  code review finding that survived verification belongs here.
- **Escapes.** Bugs found by a review, by hand or on the device after the gates had passed. These
  matter more than the failures a gate caught, because nothing yet stops them recurring.
- **Time sinks.** Tool friction, blocked commands and waits.
- **What worked.** A measurement that settled a choice, a check that caught a bug, an order of
  work that paid off. These are kept on purpose, or they drift away too.

The sources are the conversation, `git log` and `git diff` of every branch touched, review
reports, gate and test output, and the agent's memory. Each item names its instance: a file, a
commit, a finding, a message. No instance, no lesson.

Run in a fresh session, as after a restart, there is no conversation to read. The session under
review is a transcript under `~/.claude/projects/`, in the directory named for the project's path
with each `/` as `-`, one `.jsonl` file per session: the most recently modified one that is not
the running session's own. The owner's messages and the agent's reports in it are the record.
If that session already drew lessons, list which were applied and where, and propose only what
is still open.

## Find why it got through

For each shortfall, ask what should have stopped it:

- **A rule existed and was not followed.** Another rule will not help. The fix is enforcement: a
  gate, a test, a lint rule, a step in the project's checklist.
- **No rule covered it.** Write one, in the place below where it will be read at the right moment.
- **A rule covered it and was wrong.** Fix the rule.
- **Bad luck.** Nothing would have caught it at a reasonable cost. Say so and drop it.

Prefer, in this order: a check the repository runs, a rule in the right document, a memory. A
habit is the weakest fix and the first one forgotten.

Patterns that recur, to test each shortfall against:

- a conclusion generalised from one observation, where the code paths were not read
- a cheap safeguard removed because the case it guards seemed too unlikely
- a document promising what no test enforces
- only the case at hand tested, when the documentation names others
- a proxy measured instead of the goal (a process that is up, when the goal is its work getting
  done)
- work called done before it was reviewed

## Put each lesson where it will be used

| the lesson is | it goes in |
|---|---|
| checkable by a machine | a gate: a test, a lint rule, a check script, as well as any text |
| true of any Python project, and it cost something once | python-traps |
| how to write code or documents anywhere | python-style, and every project's `docs/STYLE.md` copy |
| about this project's code, hardware or workflow | the project's `CLAUDE.md`; its rationale in the design document |
| how the owner wants the work done | agent memory, as feedback, with the reason |
| a one-off | nowhere; say so |

Before adding a rule, search its target for one that already covers it, and sharpen that rule
rather than add a near-duplicate. Write it in the target's voice: the fact, the failure it
prevents, what to do instead. A lesson about this retrospective itself goes in this file.

## Report

Three short sections, each item with its instance:

- **Fell short** — what happened, what it cost, why it got through.
- **Worked** — what to keep doing.
- **Cost time** — what to change about how the work is arranged.

Then numbered proposals, each the change, where it goes, and the incident behind it, and ask
which to apply. Keep it proportional: a quiet session may have one proposal or none, and saying
so is a result. State each miss and its cost plainly, neither softened nor dramatised.

## Apply what the owner picks

- Tracked changes go on a branch and follow the target repository's rules: its gates, a version
  bump for a plugin, `docs/STYLE.md` copies kept identical to python-style. Push nothing.
- Check the changes by kind before handing them over: documents get the doc-audit checks, scoped
  to what changed; code gets a code review.
- Memory is edited in place, updating an existing memory rather than adding a duplicate.
- Report where each change landed and what still needs the owner: a review, a merge, a
  reinstall.
