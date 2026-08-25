package main

import "core:fmt"

main :: proc() {
	fmt.println("=== JJK MUD - combat engine draft ===")
	fmt.println("Sae (Hands-heavy burst) vs Ren (balanced/Flow-lean sustain)")
	fmt.println()

	sae := new_fighter("Sae", Allocation{body = 0.15, hands = 0.70, flow = 0.15}, 100, 0.6, 0.3)
	ren := new_fighter("Ren", Allocation{body = 0.30, hands = 0.30, flow = 0.40}, 100, 0.4, 0.7)

	// Scripted channel choices per tick, just to exercise the systems below -
	// a real driver would come from timestamped player input (4.1), not a script.
	sae_script := []Channel{.Hands, .Hands, .Hands, .Body, .Hands, .Hands, .Flow, .Hands, .Hands, .Hands, .Hands, .Hands}
	ren_script := []Channel{.Body, .Flow, .Flow, .Flow, .Body, .Hands, .Hands, .Body, .Flow, .Flow, .Body, .Hands}

	for tick := 0; tick < len(sae_script); tick += 1 {
		fmt.printf("--- tick %d ---\n", tick + 1)

		sae_ch := sae_script[tick]
		ren_ch := ren_script[tick]

		resolve_triangle(&sae, &ren, sae_ch, ren_ch)

		bf_advance_odds(&sae)
		bf_advance_odds(&ren)

		apply_ce_drain(&sae)
		apply_ce_drain(&ren)

		report_spike(&ren, &sae, sae_ch) // Ren reading Sae
		report_spike(&sae, &ren, ren_ch) // Sae reading Ren

		sae.last_channel, sae.has_last_channel = sae_ch, true
		ren.last_channel, ren.has_last_channel = ren_ch, true

		fmt.printf("  Sae: CE %.0f/%.0f  HP %.0f  |  Ren: CE %.0f/%.0f  HP %.0f\n\n",
			sae.ce, sae.ce_max, sae.hp, ren.ce, ren.ce_max, ren.hp)
	}
}

// Body beats Hands, Hands beats Flow, Flow beats Body (2.2)
resolve_triangle :: proc(a: ^Fighter, b: ^Fighter, ca: Channel, cb: Channel) {
	fmt.printf("  %s commits %v, %s commits %v\n", a.name, ca, b.name, cb)

	if beats(ca, cb) {
		fmt.printf("  -> %s's %v beats %s's %v\n", a.name, ca, b.name, cb)
		on_win(a, b, ca)
	} else if beats(cb, ca) {
		fmt.printf("  -> %s's %v beats %s's %v\n", b.name, cb, a.name, ca)
		on_win(b, a, cb)
	} else {
		fmt.println("  -> mirrored channels, no clean beat this tick")
	}
}

beats :: proc(x: Channel, y: Channel) -> bool {
	switch x {
	case .Hands:
		return y == .Flow
	case .Body:
		return y == .Hands
	case .Flow:
		return y == .Body
	}
	return false
}

// draft simplification: a winning Hands beat always connects and costs a
// flat 8 HP. Gas-out's "much weaker block/evade" (2.7) isn't modeled yet.
on_win :: proc(winner: ^Fighter, loser: ^Fighter, c: Channel) {
	if c == .Hands && !is_gassed(winner) {
		bf_roll_on_landed_hit(winner)
		loser.hp -= 8
	} else {
		bf_break_streak(winner)
	}
}

report_spike :: proc(reader: ^Fighter, target: ^Fighter, ch: Channel) {
	sr := read_spike(reader, target, ch, .Medium)
	if sr.is_transition {
		if sr.transition_visible {
			fmt.printf("  [%s reads] %s just pivoted into %v (mag %.2f)\n", reader.name, target.name, sr.channel, sr.magnitude)
		} else {
			fmt.printf("  [%s reads] %s is doing... something (magnitude %.2f, pivot masked)\n", reader.name, target.name, sr.magnitude)
		}
	} else {
		fmt.printf("  [%s reads] %s holding %v (mag %.2f)\n", reader.name, target.name, sr.channel, sr.magnitude)
	}
}
