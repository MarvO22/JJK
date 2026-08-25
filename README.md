# JJK

A Jujutsu Kaisen-themed MUD built around one combat engine that serves both
PvE missions and PvP duels, so fighting curses actually trains you for
fighting other players, and vice versa.

Full design spec lives in [DESIGN.md](DESIGN.md) and is being written in the
open as decisions get made. It's explicit about what's locked in versus
genuinely undecided - if something's marked open, nothing should be built on
top of it yet.

## The core idea

Every combatant commits each combat tick to one of three channels:

- **Body** - sustain, reinforcement, absorbing damage
- **Hands** - offense and counters
- **Flow** - buildup toward cursed technique thresholds

They form a closed, intransitive loop - Hands beats Flow, Body beats Hands,
Flow beats Body - and each side wins *differently*: Hands denies, Body
reduces, Flow bypasses. No channel is strictly best, and the loop only holds
if each piece is tuned against the others rather than in isolation (see
DESIGN.md section 6 for the balance principles this runs on).

## Philosophy this is being built against

- **Reads over RNG.** Information is visible - cursed energy spikes, aura
  detail - but turning that information into the correct play is on the
  player, not a dice roll. Where there's still randomness (Black Flash), it's
  built on canon's own logic rather than being an arbitrary dial.
- **Payoff size shapes the meta more than raw strength does.** Buffing
  techniques pushes players *toward* Hands, not away from it, because in an
  intransitive system the counter gets picked more as the thing it counters
  gets scarier. The lever that looks backwards is often the right one.
- **Gate power behind setup, not nerfs.** Effects that would be a blowout
  (Domain Expansion, Black Flash) are supposed to earn their power through
  real structural cost or rarity, rather than existing at full strength and
  getting shaved down after the fact.
- **Continuous, timestamped input and an event queue, not lockstep rounds.**
  The design leans hard on sub-tick telegraph timing - a heavy attack is
  reactable, a light one isn't - which a classic tick-locked Diku engine
  would throw away by only reading input at tick boundaries.

## What's here right now

- `DESIGN.md` - the living spec.
- `engine/` - a first-draft combat engine in Odin: the Body/Hands/Flow
  triangle, cursed-energy allocation and drain, the gas-out/vulnerable-window
  state, an escalating-odds Black Flash mechanic, and a passive Read Curse
  vs. Curse Energy Control contest governing how legible a fighter's channel
  transitions are to an opponent. See `engine/README.md` for how to run it
  and what's intentionally not built yet (a real event queue, networking,
  player input).

## Status

Early. Most of the combat core is decided; progression, missions, the world,
and several headline mechanics (Domain Expansion authoring, binding vows,
multiple opponents) are still open or entirely undesigned. Check DESIGN.md
section 5 for the current open-question list before assuming anything not
covered above.
