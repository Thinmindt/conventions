# Security

**Seat:** when the diff crosses a trust boundary: input from a user, a file, the network, another
agent or a model; a credential, a permission or a command line; anything run, parsed or fetched.

In the diff, look for:

- Input that reaches a shell, a query, a path, a template or a parser before it is checked, or
  checked before it is normalized.
- Text from outside (a message, a web page, a file, tool output) that the code or an agent may
  treat as an instruction.
- A credential printed, logged, written to a file a wider set can read, or put in an argument or
  a URL.
- Permissions broader than the task: a writable mount, a wildcard rule, a default that allows.
- A deputy doing for an untrusted caller what the caller could not do itself.
- Unbounded work an outside party controls: size, count, recursion, retries.
- A guard that stops nothing the existing checks do not already stop; the simplicity rule wants
  it named or gone.

Think like an attacker and stay defensive. Rank by the realistic path, not the dramatic one.
