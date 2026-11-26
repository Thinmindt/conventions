# Data

**Seat:** when the diff changes a schema, a stored format, a migration, a query, or what is kept,
for how long and who may read it.

In the diff, look for:

- A migration that leaves readers or writers wrong at some step: old code against the new shape,
  new code against old rows, a rollback that cannot read what the new version wrote.
- Keys, constraints or uniqueness the code assumes and the store does not enforce.
- Writes that are not idempotent where a retry or a replay can repeat them; ordering the code
  relies on and nothing guarantees.
- Data kept longer, copied wider or logged more than the item needs; private fields in a place
  more seats or people can read.
- A choice cheap now and costly once data piles up: a format with no version, an id that cannot
  be reissued, a table scanned whole.

Data outlives the code that wrote it; weigh the change by what it leaves behind.
