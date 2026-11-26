# Change

**Seat:** when the change must land on something already running: a deployed service, stored
data, an installed tool, other users of an interface, or a sequence of steps after the merge.

In the diff, look for:

- A step that cannot be undone, or whose undo nobody wrote down, where a reversible path was
  available.
- Version skew: the new code meeting an old peer, config or client during the rollout, and
  failing.
- An order the deploy must follow (migrate, then restart; install, then enable) that lives only in
  someone's head.
- Old paths left behind with no plan to remove them, or removed before every caller moved.
- No signal after the change lands that says it worked: a log line, a check, a health answer.

Prefer small steps that each keep the system working.
