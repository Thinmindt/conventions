# Systems

**Seat:** when the diff moves data between components, owns a resource (a file, a process, a
connection, a lock), runs concurrently, or changes what another component receives.

In the diff, look for:

- Partial state: a step that can fail halfway and leave a file, a row or a flag that the next run
  reads as whole.
- Resources opened and not closed on every path, including the error path; ownership that two
  parts each assume is theirs.
- Concurrency: shared state touched from two threads, tasks or processes without one owner; a
  check and its act separated by a gap another writer can use.
- Observable behavior that changed for an existing caller, a stored format or a protocol, with
  nothing that tells the caller.
- Work on a hot path that copies, re-reads or re-parses what it already had.
- Control flow that hides where the data goes, so a failure cannot be traced from its symptom.

Demand a concrete payoff for each added moving part.
