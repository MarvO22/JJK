package main

import "core:fmt"
import "core:math/rand"

// ---------------------------------------------------------------------------
// Draft combat engine, reflects DESIGN.md 2.1-2.8 and 3.1-3.3.
// Not compiled/run in the sandbox this was written in - no Odin toolchain
// available there. Build with: odin run engine
//
// Covered here:
//   - the Body/Hands/Flow triangle                              (2.1-2.2)
//   - CE allocation, drain-by-concentration, gas-out, reignite   (2.7)
//   - Black Flash escalating odds + effects                      (2.8)
//   - Read Curse / Curse Energy Control spike legibility          (this
//     session's decision: transitions are masked by Control,
//     magnitude always stays visible per 2.7)
//
// Deliberately stubbed / not designed yet (see DESIGN.md 5 and 7):
//   - variable-duration event queue for overlapping actions (4.2) -
//     everything here resolves in a single tick as a placeholder
//   - networking, telnet, real player input
//   - Domain Expansion, binding vows, multiple opponents, second actors
// ---------------------------------------------------------------------------

Channel :: enum {
	Body,
	Hands,
	Flow,
}

Tier :: enum {
	Light,
	Medium,
	Heavy,
}

Allocation :: struct {
	body:  f64, // 0..1, the three should sum to 1.0
	hands: f64,
	flow:  f64,
}

Fighter :: struct {
	name: string,

	hp:      f64,
	stamina: f64,

	// CE - the top-level power resource, allocated across the three channels (2.7)
	ce_max: f64,
	ce:     f64,
	alloc:  Allocation,

	gassed_ticks_left: int,

	flow_meter: f64, // the spendable technique-buildup pool (5.1 resolved -> spend)

	// Black Flash (2.8)
	bf_tick_chance:   f64, // this fight's current per-tick odds
	bf_streak:        int, // consecutive landed-hit streak
	bf_lifetime_base: f64, // permanent, carries between fights

	// Read Curse / Curse Energy Control - passive stats
	read_curse: f64, // 0..1, how well this fighter reads others
	ce_control: f64, // 0..1, how well this fighter masks its own channel transitions

	last_channel:     Channel,
	has_last_channel: bool,
}

new_fighter :: proc(name: string, alloc: Allocation, ce_max: f64, read_curse: f64, ce_control: f64) -> Fighter {
	return Fighter{
		name       = name,
		hp         = 100,
		stamina    = 100,
		ce_max     = ce_max,
		ce         = ce_max,
		alloc      = alloc,
		bf_tick_chance = 0.001,
		read_curse = read_curse,
		ce_control = ce_control,
	}
}

// --- allocation -> power / drain --------------------------------------------

// 0 for an even 1/3-1/3-1/3 split (slow drain, long fight), 1 for everything
// dumped into one channel (fast drain, burst).
allocation_concentration :: proc(a: Allocation) -> f64 {
	even := 1.0 / 3.0
	dev := abs(a.body - even) + abs(a.hands - even) + abs(a.flow - even)
	max_dev := (1.0 - even) * 2
	return dev / max_dev
}

channel_weight :: proc(a: Allocation, c: Channel) -> f64 {
	switch c {
	case .Body:
		return a.body
	case .Hands:
		return a.hands
	case .Flow:
		return a.flow
	}
	return 0
}

// --- per-tick CE drain (2.7) -------------------------------------------------

CE_DRAIN_BASE :: 2.0        // idle upkeep - even a fully spread build burns something
CE_DRAIN_BURST_MULT :: 14.0 // scales drain toward "gassed in a few ticks" for a full dump

tick_ce_drain :: proc(f: ^Fighter) -> f64 {
	c := allocation_concentration(f.alloc)
	return CE_DRAIN_BASE + c * CE_DRAIN_BURST_MULT
}

// --- gas-out (2.7) ------------------------------------------------------------

GASSED_TICKS :: 2
REIGNITE_FLOOR :: 0.35 // stable floor - portion of ORIGINAL max, does not compound

apply_ce_drain :: proc(f: ^Fighter) {
	if f.gassed_ticks_left > 0 {
		f.gassed_ticks_left -= 1
		if f.gassed_ticks_left == 0 {
			f.ce = f.ce_max * REIGNITE_FLOOR
			fmt.printf("  [%s] CE reignites at %.0f%% of original max.\n", f.name, REIGNITE_FLOOR * 100)
		}
		return
	}

	f.ce -= tick_ce_drain(f)
	if f.ce <= 0 {
		f.ce = 0
		f.gassed_ticks_left = GASSED_TICKS
		fmt.printf("  [%s] GASSED OUT - %d ticks, no reinforcement.\n", f.name, GASSED_TICKS)
	}
}

is_gassed :: proc(f: ^Fighter) -> bool {
	return f.gassed_ticks_left > 0
}

// --- Black Flash (2.8) ---------------------------------------------------------

BF_TICK_CLIMB :: 0.001
BF_STREAK_CLIMB :: 0.005
BF_LIFETIME_GAIN :: 0.001
BF_INTRAFIGHT_DECAY :: 0.5 // this fight's climb rate is halved after a trigger

// call once per tick, before resolving whether a Hands hit lands
bf_advance_odds :: proc(f: ^Fighter) {
	climb := BF_STREAK_CLIMB if f.bf_streak > 0 else BF_TICK_CLIMB
	f.bf_tick_chance += climb
}

// call when this fighter LANDS a hands hit this tick
bf_roll_on_landed_hit :: proc(f: ^Fighter) -> bool {
	f.bf_streak += 1
	roll := rand.float64()
	if roll < f.bf_tick_chance + f.bf_lifetime_base {
		bf_trigger(f)
		return true
	}
	return false
}

bf_break_streak :: proc(f: ^Fighter) {
	f.bf_streak = 0
}

bf_trigger :: proc(f: ^Fighter) {
	f.ce = f.ce_max
	f.gassed_ticks_left = 0
	f.ce_max *= 1.15 // balanced, permanent-for-this-fight reinforcement bump

	f.bf_tick_chance *= BF_INTRAFIGHT_DECAY // chaining a 2nd one this fight gets harder...
	f.bf_lifetime_base += BF_LIFETIME_GAIN  // ...but lifetime odds permanently rise

	fmt.printf("  *** [%s] BLACK FLASH - CE restored, reinforcement permanently boosted this fight. ***\n", f.name)
}

// --- Read Curse / Curse Energy Control spike legibility -------------------------

Spike_Read :: struct {
	channel:            Channel,
	magnitude:          f64,  // always visible per 2.7 - never gated by skill
	is_transition:      bool, // differs from the target's last committed channel
	transition_visible: bool, // gated by reader's Read Curse vs target's CE Control
}

spike_magnitude :: proc(f: ^Fighter, c: Channel, tier: Tier) -> f64 {
	tier_mult: f64
	switch tier {
	case .Light:
		tier_mult = 0.4
	case .Medium:
		tier_mult = 0.7
	case .Heavy:
		tier_mult = 1.0
	}
	return channel_weight(f.alloc, c) * tier_mult
}

read_spike :: proc(reader: ^Fighter, target: ^Fighter, c: Channel, tier: Tier) -> Spike_Read {
	is_transition := true
	if target.has_last_channel {
		is_transition = target.last_channel != c
	}

	visible := true
	if is_transition {
		// contested: reader's Read Curse vs target's CE Control. Magnitude
		// itself is never hidden - only whether the PIVOT moment is legible.
		edge := reader.read_curse - target.ce_control
		chance := clampf(0.5 + edge, 0.05, 0.95)
		visible = rand.float64() < chance
	}

	return Spike_Read{
		channel            = c,
		magnitude          = spike_magnitude(target, c, tier),
		is_transition      = is_transition,
		transition_visible = visible,
	}
}

clampf :: proc(v, lo, hi: f64) -> f64 {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}
