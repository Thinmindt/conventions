---
name: python-traps
description: Rules for Python that runs unattended — threads and locks, callbacks on someone else's thread, files that must survive a crash, network filesystems, services under systemd, uv with apt-only packages, and what may go in a public repository. Each rule names the failure it prevents. Use when writing or reviewing threaded code, a callback or consumer, a file write that a reader may see early, a long-running service or its unit file, a venv that depends on system packages, or anything about to be pushed to a public repository.
---

# Python traps

Each rule is a fact about Python or the operating system, with the failure it prevents. Every
one was paid for once. A number is a measurement, not an estimate.

## Threads and locks

**Never `yield` while holding a lock.** A suspended generator keeps its context managers, so a
`with lock:` around a `yield` holds the lock for as long as the consumer takes to ask for the
next value. One slow client of a streaming HTTP response blocks every other user of that lock
for as long as it stays connected. Copy what the generator needs under the lock, release, then
yield.

**A callback runs on the caller's thread.** A consumer registered with a producer runs on the
producer's loop, so a slow consumer throttles the producer and every other consumer, and a
blocking one stops them all. Copy what you keep, return fast, hand real work to a thread of
your own. Catch and log per callback, so one broken consumer fails loudly without stopping the
loop.

**Know which thread a library calls you on before deciding what may raise there.** An
exception escaping a library's worker thread kills that thread. If it was the thread that
returns buffers or refills a queue, everything upstream blocks forever with no error anywhere.
Catch at the boundary and mark the operation failed.

**Bounded queues drop and count; they never block the producer.** A hot loop that emits
metrics or log rows hands each one to a bounded queue and a writer thread. When the queue is
full, drop the row and count the drop; report the count at shutdown. A `put()` that blocks
turns a slow disk into a stalled producer.

**Durations come from `time.monotonic()`.** Wall time steps when NTP corrects the clock — by the
length of the downtime on a machine with no RTC — so an elapsed time from `time.time()` goes
negative or jumps by hours. Timestamps for humans; monotonic for elapsed.

**A check on a hot loop is throttled.** A `statvfs` plus a warning on every iteration at 30 Hz
is 30 syscalls and 30 log lines a second for as long as the condition holds. Check every few
seconds and remember the answer.

**Bound every join.** `thread.join()` with no timeout hangs shutdown on a wedged thread. Join
with a timeout, then log and move on.

**Shut down the producer before its consumers.** Tearing down a consumer while the producer is
still calling into it races the callback and leaves half-finished state behind.

## Files and durability

**Publish by rename.** Write `<name>.part`, close it, then rename to `<name>` on the same
filesystem. The rename is atomic, so a reader never sees a final-named file that is still
growing. A check-then-write on the final name has two failure modes: a second reader served a
truncated file, and two writers leaving a corrupt one cached for good.

**`shutil.move` across filesystems is copy-then-delete.** It exposes the final name the moment
the copy starts. Copy to a `.part` name on the destination filesystem and rename there.

**Write the metadata before renaming the data it describes.** If a sidecar, index entry or
manifest is written after its file takes the final name, a reader — or a crash — between the
two sees a file with no facts. Write the sidecar, then rename; ship the sidecar, then the file.

**Decide what happens to a file cut off mid-write.** A crash leaves `<name>.part`. On the next
start, handle it deliberately: recover it if it is usable, discard it if empty, never overwrite
a final name that already exists. Leaving it for someone to find is also a decision, and the
wrong one.

**SQLite never lives on a network share.** Its locking is unreliable over CIFS and NFS. Keep
the database on local disk and store paths to the media that lives on the share.

**Never hold a lock across network I/O.** A serialized database wrapper that also globs a
network share holds every other request behind a stalled mount — on a soft CIFS mount, one to
two minutes per failing operation. Read the network with no lock held; take the lock only to
write what was read.

**A soft mount fails; a hard mount blocks forever.** On CIFS `soft` is the default and is what
lets an `OSError` handler run at all. Pin it explicitly in fstab: switching to `hard` reads
like a robustness improvement and is the opposite.

**Key caches by an id that cannot change.** A cache keyed by an id that gets renumbered — a
group id after a regroup, a row id after a rebuild — serves the wrong entry silently. Key by
the immutable thing, and name entries so two schemes cannot collide.

**A file with a different layout is never appended to.** Appending new columns to an old CSV
corrupts it. Leave the old file alone, write to a timestamped sibling, log a warning.

## Process and environment

**SIGTERM takes the Ctrl-C path.** systemd and `kill` send SIGTERM, whose default action ends
the process on the spot: open files stay `.part`, queues are lost, nothing is flushed. Install a
handler that raises `SystemExit` on the main thread so the `finally` blocks run, and have it
ignore further SIGTERMs so a second one cannot interrupt the cleanup.

**Degrade at startup rather than die.** If one component cannot be constructed — a database that
will not open, a device that is busy — bring up the rest with a warning. The web page that
still comes up is often how you find out something is wrong.

**`print()` is block-buffered under a service manager.** Lines are lost when the process is
killed. Use `logging`; set the root at `WARNING` and raise only your own loggers to `INFO`, or
a chatty dependency buries your output.

**`load_dotenv()` does not override the environment.** `VAR=value python main.py` beats `.env`,
which is what lets a test run point every path at scratch without editing anything. Per-run
settings for a service go in a systemd drop-in (`systemctl edit`), not in `.env` — the test
suite reads that — and not in the tracked unit, which would publish one machine's experiment as
the default.

**A venv that needs apt packages needs system site packages.** For a compiled binding that is
not on PyPI: `uv venv --system-site-packages && uv sync`, with `python-preference =
"only-system"` in `[tool.uv]` so uv never downloads an interpreter that cannot see them.
Deleting `.venv` and running a bare `uv sync` recreates it without the flag, silently.

**An OS upgrade invalidates the venv silently.** `pyvenv.cfg` keeps the old version and the old
`site-packages` path while `bin/python` resolves to the new interpreter. Nothing raises; the
venv's own packages vanish from `sys.path`, and because system packages still resolve it looks
like a dependency problem. Rebuild the venv.

**After an unclean exit, hardware may stay busy.** A device the kernel has to reclaim — a
camera, a serial port — fails to open for some seconds after a crash. A service's `RestartSec`
must outlast that window or it crash-loops instead of recovering.

## A public repository

**Tracked files are written for a stranger.** Every file, comment and commit message may be read
by someone with none of your context. Opinions about the code, with their reasons, belong in;
facts about the owner, their machine and their workflow do not. Those go in gitignored files:
notes under `docs/`, or `CLAUDE.local.md` for what an agent needs to know about this
particular machine.

**Never a LAN address, share name, hostname or credential in anything tracked.** Before the
first push, grep every added line in history, not just the working tree. Rewriting unpushed
commits is free; rewriting pushed ones is not.

**Personal details are private too.** People's and pets' names, a personal email address, an
account name, an absolute home path. A pet's name is a common answer to account-recovery
questions, and knowing it lends a stranger false familiarity. Commit author lines are as public
as the files, so a personal address in `git config user.email` publishes itself on every commit.

**Enforce it with a check, not a habit.** Keep the private terms in a gitignored file and have
the project's gate script fail when one appears in a tracked or about-to-be-added file, or in
the message or author of a commit no remote has yet (`git log HEAD --not --remotes`). Without the
file, as on CI, the check passes and says nothing is configured. The doc-audit skill carries the
script to copy, and how a project adds terms of its own.

**Nothing tracked may depend on one person's settings.** A rule that holds because of how the
owner configured git, their shell, their paths or their hardware is false for the next
contributor. Make it a check the repository runs, or state it as a requirement for everyone.
Examples and tests use made-up names, never the installation's own.

**A design document that cites private documents is half a document.** If the design doc cites
the roadmap, publish the roadmap, scrubbed, or the reader has the conclusions and not the plan.

**Ship a LICENSE.** Without one nobody can legally fork or contribute, whatever the README says.
