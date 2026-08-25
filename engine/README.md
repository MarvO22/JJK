# Combat engine draft

Run: `odin run engine` from the repo root.

Not compiled locally - this was written in a sandbox with no Odin toolchain
installed, so treat it as a first pass. If it doesn't build, the errors are
almost certainly small syntax slips (Odin's compiler messages are usually
precise about the line/fix) - send them back and they're a fast patch.

## What's here

- `combat.odin` - the systems: the Body/Hands/Flow triangle, CE allocation
  and drain, gas-out, Black Flash, and Read Curse vs. Curse Energy Control
  spike legibility. Each section is commented with the DESIGN.md section it
  implements.
- `main.odin` - a scripted two-fighter demo that drives the systems above for
  12 ticks and prints a log, so you can see the mechanics run without a
  server or real input yet.

## What's deliberately NOT here

- The variable-duration event queue for overlapping multi-tick actions
  (DESIGN.md 4.2). Everything currently resolves in a single tick as a
  placeholder - this is the next real piece of engine work.
- Any networking/telnet layer or real player input (4.1 requires
  timestamped continuous input, not turn input - not built yet).
- Domain Expansion, binding vows, multiple opponents, second actors -
  all still open/undesigned per DESIGN.md sections 5 and 7.
