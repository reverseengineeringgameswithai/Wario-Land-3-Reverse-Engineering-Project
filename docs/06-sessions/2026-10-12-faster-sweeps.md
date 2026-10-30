---
type: session
status: done
updated: 2026-10-12
tags: [session, tooling, validation]
---
# 2026-10-12: Faster regression sweeps

The owner asked whether the sweeps, which every change waits on, could run
queued one after another while work goes on, and be made faster; and
whether rewriting them in C would help.

## Outcomes

- Measured on `level-08-wander` (with other sweeps running): a Godot
  process starts in 0.74 s, reads and parses the 21 MB trace in 0.2 s,
  and checks it in about 1.8 s (step) or 1.9 s (run); a movie took two
  processes, 5.55 s in all. Python only launches the processes, so a
  rewrite in C would gain nothing there, and the GDScript doing the work
  is the port under test ([ADR-0001](../03-architecture/adr-0001-native-port-strategy.md)).
  The cost was the repeated starts and parses, and each of the 68 sweeps'
  idle cores at its end (25-movie sweeps on 14 cores).
- `wario_parity.gd --batch=FILE` runs several checks in one process, each
  from a clean state, with one result line each. `make sweeps` runs the 34
  regression sweeps from one pool, the longest traces first, six movies a
  process, each movie in both modes; it writes the same result files and
  summaries as `make sweep`, and fails on any difference. `SNAPSHOT=1`
  checks a copy of `game/` and the content in `build/snapshots/COMMIT`, so
  the next change can be made while it runs. Sweeps run one at a time;
  they share `local/reviews/sweeps`.

## Tests

- Equivalence: on the same game copy, the pooled, batched path and one
  process per check gave identical result files for all 90 compared
  (`wander` day 1's 25 movies and 20 of `right-attack` with power-ups'
  room starts, step and run); a batch of four checks took 8.2 s against
  about 11 s apart.
- `tests/test_sweep.py`: the 34 sweeps, the report and its failure, and
  the screens' counts. `make wario-parity` on `ootw-gray-key` (step and
  run) as before.
- The first `make sweeps` follows the commit; see
  [sweeps after the commit](#sweeps-after-the-commit).

## Sweeps after the commit

The first `make sweeps` (on a snapshot of `49a61a9`, which also contains
the native chain's and the pause menu's commits) took 27.8 minutes,
against about 73 before, with other checks sharing the CPU for part of it.
Step: all 34 sweeps (11,082 movies) unchanged: 12,965,952 Wario,
26,744,689 object, and 13,003,290 interaction updates, all identical,
nothing unported. Run: all 11,082 movies run whole frames to the end, and
no screen loop after a level differs. The next commit's sweeps took 31.2
minutes with the machine otherwise idle: about 2.3 times faster in all.

## Next action

Profiled on `level-08-wander`: the step check's six passes take 0.53 s
together (0.07-0.13 s each, objects and interactions the largest), the
trace's parse 0.12 s; the rest of a single check's 2.4 s was Godot's start
and compiling the port, now paid once a batch. No pass dominates, so a
further cut would come from measuring a batched process, not one pass.
