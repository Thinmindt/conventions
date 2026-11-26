# Language

**Seat:** one per language whose semantics bear on a risk no other seated lens covers, with the
language named in the seat line and a watch list (for example, "shell: quoting, exit status in
pipelines, set -e inside functions"). A file in a language is not by itself a reason.

In the diff, look for, within the watch list:

- Idioms carried over from another language that misbehave in this one.
- Runtime semantics the code relies on and the language does not promise: evaluation order,
  truthiness, integer width, string encoding, copy versus reference.
- Error handling, resource lifetime and concurrency in the language's own terms.
- Tooling the project already has (the linter, the type checker) that would catch the problem if
  configured; say so rather than repeat the rule.

A style preference becomes a finding only when it carries a concrete failure.
