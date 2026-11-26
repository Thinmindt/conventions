# Performance and algorithms

**Seat:** when the diff adds a loop over data that grows, a search, a sort, a parser, a cache,
numeric work, or a claim about speed.

In the diff, look for:

- Cost that multiplies: work inside a loop that belongs outside it, a scan per item, a quadratic
  pattern on input an outsider controls.
- An invariant the algorithm needs and nothing checks; termination that depends on input.
- Numeric precision, overflow, rounding or randomness the result is sensitive to.
- A performance claim with no measurement behind it, or a measurement on input unlike the real
  workload.
- A cache with no bound or no way to go stale correctly.

Prefer the simplest algorithm that meets the constraint the item states; do not ask for speed the
item does not need.
