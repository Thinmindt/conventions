# Testing

**Seat:** always. Every criterion is shown true by a test or a repeatable check.

In the diff, look for:

- A test that would still pass if the behavior it names broke: it asserts on a mock's calls, on
  the code's own constants, or on nothing the criterion is about.
- Failure paths, boundaries and realistic data the changed code meets and no test feeds it: the
  empty input, the second call, the partial write, the value at the limit.
- Tests that depend on the clock, randomness, ordering, the network or leftover state, so a pass
  does not repeat.
- Tests that pin the implementation rather than the behavior, so the next refactor breaks them
  with nothing wrong.
- Several cases that run one code path, where one would do; and one case standing in for paths
  that differ.

Judge a test by the failure it would catch. The smallest addition that covers the riskiest
untested behavior is the fix to name.
