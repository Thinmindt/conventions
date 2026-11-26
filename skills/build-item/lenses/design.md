# Design

**Seat:** when the diff adds or reshapes a module, an interface, a type, or the way two parts of
the code depend on each other. Not for a change confined to one function's body.

In the diff, look for:

- Knowledge stated twice: one rule, limit or format written in two places that must change
  together, and nothing that makes them.
- Dependencies that point the wrong way: stable policy importing a detail, a core module reaching
  into a caller, a decision mixed with the I/O that acts on it.
- An abstraction with one user and no present need, or a missing one where the diff copies a
  block a third time.
- Names that hide what a thing does, functions working at two levels at once, side effects a
  caller cannot see from the signature.
- Error paths that are swallowed, overloaded onto a normal return, or hard to trace back.
- Changes that are hard to reverse where a reversible shape was as cheap.

Prefer the smallest design that keeps the behavior and the contract. Raise naming or structure
only when it changes what a reader understands, what the next change costs, or whether the code
is correct.
