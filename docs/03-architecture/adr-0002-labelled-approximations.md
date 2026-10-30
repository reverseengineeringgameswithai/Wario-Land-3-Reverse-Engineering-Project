---
type: adr
status: accepted
updated: 2026-10-01
tags: [architecture, decision, content]
---
# ADR-0002: Labelled approximations in content packs

- **Status:** accepted (2026-10-01)
- **Supersedes:** none
- **Related:** [ADR-0001](adr-0001-native-port-strategy.md), WL3-013

## Context

The first extracted room (`ROOM_001`, Out of the Woods, day 1) contains
blocks whose original behaviour the runtime cannot reproduce yet: cracked,
non-cracked, and enemy blocks that break, two room-transition blocks, and
platforms that Zombie Wario falls through
([level block maps](../02-research/level-block-maps.md),
[block handlers](../02-research/block-handlers.md)). The runtime
implements only `empty`, `solid`, and `platform`. The pack's start
position also converts the original's spawn point into the prototype's body
box, which is an interpretation. The `room.v1` and `content-pack.v1`
formats can only say *what* a cell is, not that it is a stand-in. The rules
forbid silently mapping unknown behaviour to `empty`, and a screenshot or a
loading room proves nothing about parity.

## Options

1. **Refuse the room** until every behaviour is implemented. This is honest,
   but blocks M2 behind breakables, transitions, and transformations.
2. **Silent stand-ins**: write breakables as `solid` and say nothing. This is
   rejected by the evidence rules.
3. **Room format v2**, where a legend value may be an object
   `{material, approximates}`. This keeps the label next to the cell, but
   changes the format mods patch, and cannot label pack-level choices such
   as the start position.
4. **Content-pack format v2** with a required `approximations` list. Each
   entry names a subject (`start`, `movement`, or
   `room/<id>/legend/<char>`), what it `behaves_as`, the `original`
   behaviour, and optionally the task that will remove it.

## Decision

Option 4. Version 2 packs must carry `approximations`; an empty list states
that the pack claims no known approximation. Both loaders enforce the same
rules:

- Subjects are unique.
- A room subject must name an existing legend entry, and `behaves_as` must
  equal that entry's runtime material.
- Version 1 packs may not contain the field. They keep loading unchanged,
  and their content hash is unchanged.

The runtime prints every approximation at startup and lists the subjects in
the selftest output. Extraction tools must refuse, not approximate, any
`unknown` material and any material the runtime does not implement. Only
behaviour layered on an implemented material (breaking, transitions,
state-dependent pass-through) may be approximated, and only with a label.

## Consequences

- An `original-extracted` pack can load before every behaviour exists, and
  each gap is visible in the data, in the logs, and in the parity matrix.
- A mod that patches rows reuses legend characters, so a patched cell keeps
  its label.
- The loaders cannot prove that a pack lists every approximation it
  contains. The extraction tool is responsible for that, and its tests check
  it.

## Revisit when

- The runtime implements per-probe block logic. Labels then shrink, and a
  pack whose list is empty may be checked against oracle traces.
- Mods need to declare their own approximations.
