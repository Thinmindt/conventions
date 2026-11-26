# Agents and models

**Seat:** when the diff changes what a model or agent is told, given, allowed or trusted: an
instruction file, a skill, a plugin, a hook, an MCP server or client, a tool definition, a prompt,
or the code that feeds any of them.

In the diff, look for:

- Text from outside (a message, a file, a page, another agent's reply) placed where the model
  reads it as an instruction, with nothing that marks it as data.
- A tool or permission wider than the task, or one that combines private data, untrusted content
  and a way to send data out in one session.
- A loop with no stop condition, a hand-off with no fixed shape, a step that must repeat
  exactly and is left to the model instead of code.
- Instructions that contradict each other or the project's guide, or that only work if read in
  one order.
- A skill or plugin file that breaks its format: front matter, a description that names no
  situation to load in, a path the loader will not find. Name the format and its rule; when you
  are not sure of the rule's current wording, say so instead of quoting it.
- Behavior that can only be judged by running the model, with no eval or smoke test that shows it.

Prefer a fix in the tooling or the structure over another sentence of prompt.
