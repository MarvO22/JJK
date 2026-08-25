# JJK MUD — Design Spec

**Status: early. Read the DECIDED / OPEN split carefully.**
Anything under OPEN is genuinely undecided — do not invent an answer and build on it.
Ask before implementing anything that depends on an open question.

---

## 1. Vision

A Jujutsu Kaisen themed MUD with both short-term (session-scale) and long-term
(character-scale) progression. Mission-based PvE and duel-based PvP run on the
same combat engine, so PvE genuinely trains PvP.

---

## 2. DECIDED — Combat core

### 2.1 The three channels

Every combatant commits each combat tick to one of three channels:

| Channel | Purpose |
|---|---|
| **Body** | Sustain — HP, cursed energy, stamina. Reinforcement. Absorbing damage. Disengaging. |
| **Hands** | Offense — martial arts, weaving signs, projectiles. Also counters. |
| **Flow** | Buildup toward cursed technique thresholds. |

### 2.2 The triangle

The three channels form a closed intransitive loop:

- **Hands beats Flow** — pressure denies buildup
- **Body beats Hands** — absorb it, keep your economy running
- **Flow beats Body** — turtling does not stop you reaching threshold; you out-scale

Each side wins *differently*: Hands **denies**, Body **reduces**, Flow **bypasses**.

**Load-bearing constraint:** techniques must out-scale sustained reinforcement.
If a fully-turtled Body player can tank a threshold technique, Flow stops beating
Body and the whole system stalemates. This is the first number to tune.

**Second constraint:** stamina must make sustained aggression impossible.
Hands costs stamina, Body restores it. If Hands is cheap enough to spam, both
players deny each other forever, nobody builds, and cursed techniques never
appear in high-level play. Stamina is what guarantees Flow windows exist.

### 2.3 Body vs Hands defense

- **Body** absorbs unconditionally. Always works, always mediocre. No read required.
- **Hands counter** works only on a correct read of an incoming attack. Large payoff
  when right, wasted beat when wrong.

Without this split, Hands does both jobs and nobody ever picks Body.

Note the internal split this creates:
- Hands-**attack** beats Flow (punish the builder)
- Hands-**counter** loses to Flow (you countered nothing; they built free)

### 2.4 Flow

Flow is a ramp mechanic, closer to MTG than Hearthstone: building costs you the
*beat itself*, not just a card. You are not attacking or defending while you build.

- Flow **decays on hit**. Required — "Hands beats Flow" has no teeth otherwise,
  and a permanent ratchet means whoever builds first simply wins.
- Flow denial from a blocked attack **scales with the attacker's commitment**.
  A read heavy still denies a lot; a blocked light denies almost nothing.
  This is what makes throwing a heavy at someone you know will read it still correct.
- Techniques draw primarily from a **fixed authored list**, with room for
  customization later.

### 2.5 Chanting / long commitments

Long weaves and chants break on damage **above a threshold**, not on any hit.
This makes them a bet — can they burst hard enough in the window to break me —
rather than something no one ever attempts. Obvious hook for a binding vow
("this technique cannot be interrupted; in exchange, X").

### 2.6 Removed / rejected

- **Range bands** — cut. Too much tracking load alongside CE, reinforcement, and
  aura reading. Speed decides whether projectiles land.
- **Flat evade chance for Flow builds** — rejected. A dice roll in a read-driven
  system breaks the learning loop, and 30% evade means the aggressor needs ~43%
  more successful pressure, which likely inverts Hands-beats-Flow.
  Kiting is already expressible as spending Body beats.
- **A fourth channel** — rejected. Three is the largest read a human holds under
  time pressure while still being winnable. Two is a coinflip.

### 2.7 Cursed Energy (CE)

CE is the character's overarching power resource — distinct from Flow. Body and
Flow are both *uses* of CE (Body spends it on reinforcement/sustain, Flow invests
it toward technique thresholds); Hands draws on stamina for pure martial arts but
draws on CE for technique-based attacks (signs, projectiles).

**Allocation.** At build/loadout time, a player splits their CE across Body /
Hands / Flow as a ratio. This is fixed for the fight, with one named exception:
blood-manipulation-type classes can shift their allocation mid-fight, at a cost
(lossy conversion — you get back less than you put in).

Allocation weight does two things:
- Sets the **power** of that channel when committed to. Heavy investment in one
  channel makes it hit harder / build faster / reinforce more; thin investment
  makes it weak. (Canon reference: Mahito's puppet vs. Toji — huge total CE, but
  dumped almost entirely into Hands, leaving Body paper-thin. Power level did not
  predict durability.)
- Sets the **CE drain rate**. Concentrated allocation drains fast — burst, gas
  out in a few ticks. Even allocation drains slow — longevity, more technique
  spam, but weaker per-channel. This is the burst-vs-attrition build tradeoff.

**Gas-out.** When CE hits 0: a 2-tick vulnerable window. No reinforcement during
this window — Body's CE-augmented toughness is gone. The player can still attempt
to block or evade, but at much reduced efficiency (raw stamina/HP only, no CE
backing it). After the window, CE reignites at a portion of the player's
*original* max — a stable floor, not a compounding spiral. (A burst build is
already behind a Flow or balanced Hands player once its window closes; a spiral
on top of that would be a double penalty.)

The vuln window is a counterplay space, not a free punish. The opponent can:
- Commit a multi-tick (2–3 tick) medium/heavy attack timed to resolve inside the
  window, or
- Spend the tempo on a self-buff or enemy-debuff instead — these are ordinary
  Flow-channel techniques (§2.4's authored list), fired by spending Flow like
  anything else. No new action category.

**CE visibility.** CE spikes are visible to everyone, every tick — this is the
concrete mechanism underneath §3.1's telegraph timing and §3.2's aura reading,
not a separate system:
- **Spike magnitude is always visible**, unconditional on skill. Bigger spike =
  stronger move coming = more reaction time, which is *why* §3.1's telegraph
  table works the way it does.
- **Spike location is gated by aura-reading fidelity** (§3.2). CE is physically
  denser around different regions depending on channel — body/hands/head for
  Body/Hands/Flow respectively. Low aura-reading skill sees only that energy is
  surging; high skill resolves where it's concentrated and therefore which
  channel and how strong.
- A player's **running CE total is not a persistent, visible number**. There is
  no bar to watch. Judging that an opponent is close to gassing out has to come
  from tracking their spikes over the course of the fight — a memory/read skill,
  not a UI-watching one.

**Presentation.** Planned: an inline ASCII body diagram using 256-color escape
codes, colorizing head/hands/torso regions by current CE intensity. Kept compact
and redrawn only during active fights, positioned as ambient/peripheral — a vibe
read that sits alongside the fight's text description, not a replacement for it.
Targets inline rendering for broad client compatibility (not a GMCP/Mudlet-only
widget).

### 2.8 Black Flash

An escalating, luck-gated comeback/momentum mechanic, not a timing-precision
check.

- **Odds climb over the course of a fight.** Base chance starts at .001 (0.1%)
  and increases by .001 per tick. Landing hits on a consecutive streak
  accelerates the climb to .005 per tick. This is deliberately built on canon's
  own logic — Black Flash is said to be more likely in intense, drawn-out
  moments — so a fight that runs long becomes a live threat for *both* sides,
  not just a reward for one player's aggression.
- **Trigger check happens on a landed Hands hit.** No roll without a connect.
- **On trigger:** CE fully restores, and reinforcement values get a balanced,
  **permanent-for-this-fight** boost (not a flat pool double — keeps it powerful
  without being an uncontrolled multiplicative snowball).
- **After a trigger, that fight's stacking climb rate is reduced** — chaining a
  second Black Flash in the same fight is harder than getting the first,
  preventing one lucky fight from being degenerate.
- **Each lifetime Black Flash permanently adds +.001 to the player's base chance
  in all future fights** — a genuine character-progression stat, not just an
  in-fight mechanic. Stronger/more experienced characters organically become
  more Black-Flash-prone over a career, mirroring the show. This needs an
  eventual soft cap so endgame characters don't approach a guaranteed per-tick
  trigger — deliberately left as a tuning problem, not a structural one, and a
  natural hook for the not-yet-designed progression/grade system (§7).

---

## 3. DECIDED — Tick and information architecture

### 3.1 Two clocks

- **Combat tick: 3 seconds.** Actions resolve here. May tune to 2s later —
  note this is NOT a free dial; it shortens every telegraph by a third.
- **Information stream: sub-tick.** Telegraphs, aura descriptions and windup
  flavor are emitted *between* resolutions.

The information clock running faster than the resolution clock is what restores
the reactable / unreactable split at a 3-second tick:

| Attack | Telegraph at | Resolves at | Window | Reactable? |
|---|---|---|---|---|
| Heavy | +0.5s | +3.0s | 2.5s | Yes |
| Medium | +1.5s | +3.0s | 1.5s | Marginal |
| Light | +2.5s | +3.0s | 0.5s | No — must pre-commit |

### 3.2 Aura reading

Not a channel and not a separate readout. Aura reading is the **resolution of the
description you receive**:

- Low: "Sukuna gathers himself."
- High: "Cursed energy pools in his right hand — heavy, coming low."

Same event, different fidelity. The canon flip side is **cursed energy
concealment**: suppress your aura to leak less information, at a cost.

Pure RPS with no information is a coinflip. Aura reading is what converts the
guess into a read.

### 3.3 Guard persistence

A player's defensive commitment **persists between ticks**. You do not type an
input every tick — you type when you want to *change*. Input must be short
(one or two keystrokes), not words. If defending costs a typed word, the clock
eats the player.

---

## 4. ARCHITECTURE REQUIREMENTS

**These two get built the wrong way by default and silently kill the design.**

### 4.1 Continuous input, not tick-boundary input

Classic Diku reads commands at the tick and resolves at the tick. If built that
way, a mid-tick telegraph is decoration — the player cannot act on it until the
next tick, by which point the attack already landed.

**Required:** the server accepts commands whenever they arrive, timestamps them,
and resolves at the tick boundary knowing *when* the player committed.

### 4.2 Event queue, not lockstep rounds

Actions have variable duration. A player mid-2-tick-heavy is desynced from an
opponent who has acted twice. "Everyone acts once per tick" is the default way
this gets built and it is wrong for this design.

**Required:** an event queue with per-action durations.

---

## 5. OPEN QUESTIONS — do not guess these

*Flow: threshold or spend? — Resolved: spend. See §2.7–2.8 for the full CE and
Black Flash system this grew into.*

1. **Flow denial duration.** How long does defending suppress Flow buildup? This
   number decides whether aggression is weak or dominant. **Not decided.**

2. **Threshold ladder.** Threshold ladder × tick length determines fight length.
   These cannot be set independently. **Not decided.**

3. **Loss penalty scope.** Losing costs 5–10% of curse level. Unclear whether this
   applies to PvP only, PvE deaths too, or both at different rates. **Not decided.**

4. **Domain Expansion authoring.** Players should be able to make their own domains
   in some form, tuned by the designer, boostable via binding vows.
   Recommended shape: players *assemble* from a bounded kit (authored sure-hit
   effect + environment + barrier type + size/duration) and write their own flavor
   text and vow terms. Free-form effect authoring is dangerous — a Domain's
   defining property is *sure-hit*, so a broken effect is a category problem, not
   a number you can tune down. **Not decided.**

5. **Domain Expansion as a state.** Flow presumably pays to open it, but once it is
   up and beats are still being traded inside it, the channel model does not
   describe what the domain *is*. This is a second layer over the combat loop, not
   a slot in it. **Not designed.**

6. **Multiple opponents.** Three channels assume a duel. Missions are PvE against
   multiple curses; PvP will have ganks. If two things attack and you have one
   Hands beat, what happens? For Honor's 1vX is the most-criticized part of that
   game and this is the same structural problem. **Not designed.**

7. **Second actors.** Ten Shadows, transfigured humans, cursed corpses. Does a
   shikigami spend the summoner's channels or act independently? Independently
   means summoners get double the beats; the summoner's channels means summoning
   is strictly worse than acting. **Not designed.**

8. **Reverse Cursed Technique.** Restoring economy (Body) or a technique (Flow)?
   Both readings are defensible, so decide it deliberately rather than arbitrarily.
   **Not decided.**

9. **Binding vows.** Player-authored, self-imposed constraints granting
    proportional power, permanently registered. Considered the headline original
    mechanic. Mid-fight vows are canon and dramatic but have no home in the
    channel model. **Not designed.**

---

## 6. Balance principles to build against

**Payoff size determines play frequency, not just strength.** In an intransitive
system, doubling one option's win payoff makes players pick its *counter* more.
Applied here: making techniques devastating causes players to pick **Hands** more,
not Flow. To see more Flow in the meta, buff **Body**. This runs opposite to
instinct and is a real dial.

**Watch for dominated strategies.** An option that does everything another option
does plus more makes the weaker one vanish. Hands is accumulating jobs — offense,
counters, and anything else added. Every job added to Hands is one more reason to
never pick Body.

**Gate power behind setup, not nerfs.** When something is oppressive, prefer making
the blowout require specific setup over shaving numbers.

**Measure with matchup charts from expert play, not telemetry.** Statistics lag the
metagame by months; strong players find the truth first. The balance process is
"get a few sharp players duelling and listen."

---

## 7. Not yet designed

Progression and grade system, missions and dispatch, the veil, factions and
curse-users, economy, cursed tools, world/zones, character creation, death and
respawn flow, technique dossiers (proposed in an earlier session, never confirmed).
