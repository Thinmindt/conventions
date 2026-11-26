# Reliability

**Seat:** when the diff runs unattended (a service, a timer, a hook, a scheduled task) or calls
something that can be slow, absent or wrong.

In the diff, look for:

- A call with no timeout, a retry with no bound or backoff, a loop that waits on something that
  may never come.
- A failure that is silent: caught and dropped, logged where nobody reads, or reported as success.
- A failure that is loud and wrong: one bad input stopping the whole run, a crash loop, a restart
  that repeats the fault.
- Defaults that are unsafe when the config is missing or the environment differs.
- A procedure a person must follow at a bad moment with nothing to tell them the next step.

Prefer the boring, observable shape; recommend the smallest control that contains the failure.
