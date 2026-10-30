# Example mods

Original, redistributable examples of data-only mods for the synthetic
testbed pack. A mod is a directory containing `mod.json` that matches
[`schemas/mod.v1.schema.json`](../../schemas/mod.v1.schema.json).

- [`low-gravity-ledge/`](low-gravity-ledge/mod.json) lowers gravity, shortens
  the jump impulse, and adds a one-way ledge to the `testbed` room. No ROM, ROM
  bank, or hardware budget is involved.

Try it:

```sh
make run MODS=mods/examples
```

Loading rules (ordering, limits, path containment) are in
[`docs/03-architecture/overview.md`](../../docs/03-architecture/overview.md).
