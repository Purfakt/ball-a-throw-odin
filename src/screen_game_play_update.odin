package game

import "core:math/linalg"
import "core:slice"
import c "core_game"
import hm "handle_map"
import rl "vendor:raylib"

update_game_play_screen :: proc(ctx: ^GameContext, layout: Layout, dt: f32) {
	if ctx.screen.in_transition {
		return
	}

	data, data_ok := ctx.screen.data.(^GamePlayData)

	if !data_ok {return}

	handle_input(ctx, layout)

	for command in ctx.input_commands {
		process_command(data, command)
	}

	clear(&ctx.input_commands)

	switch &state in &data.phase {
	case PhaseDrawingCards:
		update_phase_drawing_cards(data, &state, dt)
	case PhaseSelectingCards:
		update_phase_selecting_cards(data, &state, dt)
	case PhasePlayingCards:
		update_phase_playing_cards(data, &state, dt)
	case PhaseGameOver:
		return
	case PhaseWinningBlind:
		current_blind := ctx.run_data.current_blind
		current_ante := ctx.run_data.current_ante

		earnings := i8(0)

		if current_blind == .Boss && current_ante != .Eight {
			ctx.run_data.current_blind = .Small
			earnings += 5
			ctx.run_data.current_ante = c.Ante(int(current_ante) + 1)
		} else if current_blind == .Small {
			ctx.run_data.current_blind = .Big
			earnings += 3
		} else if current_blind == .Big {
			ctx.run_data.current_blind = .Boss
			earnings += 4
		} else {
			// TODO: won the game
		}

		earnings += ctx.run_data.hands_per_blind - data.hands_played
		earnings += i8(max(5, ctx.run_data.money / 5))
		ctx.run_data.money += i32(earnings)
		transition_to_ante(ctx)
	}

	update_card_layouts(data, layout)

	animation_speed: f32 = 10.0

	iter := hm.make_iter(&data.run_data.deck)
	for card_instance, handle in hm.iter(&iter) {
		if data.is_dragging && handle == data.dragged_card_handle {
			mouse_pos := rl.GetMousePosition()
			card_instance.position = {
				mouse_pos.x + data.dragged_card_offset.x,
				mouse_pos.y + data.dragged_card_offset.y,
			}
		} else {
			card_instance.position = linalg.lerp(
				card_instance.position,
				card_instance.target_position,
				animation_speed * dt,
			)
			card_instance.rotation = linalg.lerp(
				card_instance.rotation,
				card_instance.target_rotation,
				animation_speed * dt,
			)
		}
	}
}


next_hand :: proc(data: ^GamePlayData) {
	c.empty_pile(&data.played_pile)
	c.empty_pile(&data.selected_cards)
	data.selected_hand = .None
	replenish_hand_and_start_deal(data)
}

play_selected_cards :: proc(data: ^GamePlayData) {
	if len(data.selected_cards) == 0 {
		return
	}

	hand := data.selected_hand
	base_chips := i64(c.HandChip[hand])
	base_mult := i64(c.HandMult[hand])

	hand_size := i32(len(data.hand_pile))

	for i := hand_size - 1; i >= 0; i -= 1 {
		handle := data.hand_pile[i]
		if c.handle_array_contains(data.selected_cards[:], handle) {
			ordered_remove(&data.hand_pile, i)
			append(&data.played_pile, handle)
		}
	}

	slice.reverse(data.played_pile[:])

	c.empty_pile(&data.selected_cards)
	data.hands_played += 1

	data.phase = PhasePlayingCards {
		step            = .DealingToTable,
		animation_timer = 0.5,
		scoring_index   = -1,
		base_chips      = base_chips,
		base_mult       = base_mult,
		current_chips   = base_chips,
	}
}

discard_selected_cards :: proc(data: ^GamePlayData) {
	num_to_discard := len(data.selected_cards)
	if num_to_discard == 0 {
		return
	}

	for i := len(data.hand_pile) - 1; i >= 0; i -= 1 {
		handle := data.hand_pile[i]
		if c.handle_array_contains(data.selected_cards[:], handle) {
			ordered_remove(&data.hand_pile, i)
		}
	}
	c.empty_pile(&data.selected_cards)
	data.selected_hand = .None
	data.discards_used += 1

	replenish_hand_and_start_deal(data)
}

replenish_hand_and_start_deal :: proc(data: ^GamePlayData) {
	hand_size_before_draw := i32(len(data.hand_pile))

	if hand_size_before_draw < BASE_DRAW_AMOUNT {
		num_to_draw := BASE_DRAW_AMOUNT - hand_size_before_draw
		c.draw_cards_into(&data.draw_pile, &data.hand_pile, num_to_draw)

		for i := hand_size_before_draw; i < i32(len(data.hand_pile)); i += 1 {
			handle := data.hand_pile[i]
			card := hm.get(&data.run_data.deck, handle)
			if card != nil {
				card.position = DECK_POSITION
			}
		}
	}

	sort_hand(data)

	data.phase = PhaseDrawingCards {
		deal_timer = 0,
		deal_index = hand_size_before_draw,
	}
}


update_phase_drawing_cards :: proc(data: ^GamePlayData, phase: ^PhaseDrawingCards, dt: f32) {
	hand_size := i32(len(data.hand_pile))

	phase.deal_timer -= dt
	if !phase.is_finished_dealing {

		if phase.deal_timer <= 0 {
			phase.deal_timer = DEAL_DELAY
			if phase.deal_index < hand_size {
				phase.deal_index += 1
			} else {
				phase.is_finished_dealing = true
				phase.deal_timer = 0.5
			}
		}
	} else {
		if phase.deal_timer <= 0 {
			data.phase = PhaseSelectingCards{}
		}
	}
}

update_phase_selecting_cards :: proc(data: ^GamePlayData, phase: ^PhaseSelectingCards, dt: f32) {
	if data.hovered_card != data.previous_hovered_card && data.hovered_card != {} {
		card := hm.get(&data.run_data.deck, data.hovered_card)
		if card == nil {
			return
		}
		card.jiggle_timer = JIGGLE_DURATION
	}

	if len(data.selected_cards) > 0 && data.has_refreshed_selected_cards {
		data.has_refreshed_selected_cards = false
		selected_data := make([dynamic]c.CardInstance)
		reserve(&selected_data, len(data.selected_cards))

		for handle in data.selected_cards {
			card_instance := hm.get(&data.run_data.deck, handle)
			if card_instance != nil {
				append(&selected_data, card_instance^)
			}
		}
		defer delete(selected_data)

		if hand, ok := c.evaluate_hand(selected_data[:]); ok {
			data.selected_hand = hand.hand_type
			data.scoring_cards_handles = hand.scoring_handles
		}
	}
}

update_phase_playing_cards :: proc(data: ^GamePlayData, phase: ^PhasePlayingCards, dt: f32) {
	phase.animation_timer -= dt

	played_size := i32(len(data.played_pile))

	if phase.step == .DealingToTable {
		if phase.animation_timer <= 0 {
			phase.step = .ScoringHand
			phase.animation_timer = 0.5
		}
	}

	if phase.step == .ScoringHand && phase.animation_timer <= 0 {
		phase.scoring_index += 1

		if phase.scoring_index < played_size {
			card_handle := data.played_pile[phase.scoring_index]
			contains := c.handle_array_contains(data.scoring_cards_handles[:], card_handle)
			if contains {
				card := hm.get(&data.run_data.deck, card_handle)
				if card != nil {
					phase.current_chips += i64(c.RankChip[card.data.rank])
				}
			}

			phase.animation_timer = 0.4
		} else {
			phase.step = .Finishing
			phase.animation_timer = 1.5
		}
	}

	if phase.step == .Finishing && phase.animation_timer <= 0 {
		final_score := phase.current_chips * phase.base_mult
		data.current_score += i64(final_score)

		c.empty_pile(&data.played_pile)
		data.selected_hand = .None

		if data.current_score >= data.blind_score {
			data.phase = PhaseWinningBlind{}
		} else if data.hands_played < data.run_data.hands_per_blind {
			replenish_hand_and_start_deal(data)
		} else {
			data.phase = PhaseGameOver{}
		}
	}
}

process_command :: proc(data: ^GamePlayData, command: Input_Command) {
	phase := &data.phase
	_, is_selecting_cards := phase.(PhaseSelectingCards)
	#partial switch type in command {
	case Input_Command_Select_Card:
		if !is_selecting_cards {break}
		if c.handle_array_contains(data.selected_cards[:], type.handle) {
			c.handle_array_remove_handle(&data.selected_cards, type.handle)
		} else if len(data.selected_cards) < MAX_SELECTED {
			append(&data.selected_cards, type.handle)
		}
		data.has_refreshed_selected_cards = true
	case Input_Command_Play_Hand:
		if !is_selecting_cards {break}
		if data.hands_played < data.run_data.hands_per_blind {
			play_selected_cards(data)
		}
	case Input_Command_Discard_Hand:
		if !is_selecting_cards {break}
		if data.discards_used < data.run_data.discard_per_blind {
			discard_selected_cards(data)
		}
	case Input_Command_Next_Hand:
		next_hand(data)
	case Input_Command_Start_Drag:
		if !is_selecting_cards {break}
		card_instance := hm.get(&data.run_data.deck, type.handle)
		if card_instance != nil {
			data.is_dragging = true
			data.dragged_card_handle = type.handle
			mouse_pos := rl.GetMousePosition()
			data.dragged_card_offset = {
				card_instance.position.x - mouse_pos.x,
				card_instance.position.y - mouse_pos.y,
			}
			data.drag_start_index = -1
			for &handle, i in data.hand_pile {
				if handle == type.handle {
					data.drag_start_index = i32(i)
					break
				}
			}
		}
	case Input_Command_End_Drag:
		if data.is_dragging {
			drop_index := data.drop_preview_index

			if drop_index != data.drag_start_index {
				old_handle := data.dragged_card_handle
				if c.handle_array_remove_handle(&data.hand_pile, old_handle) {
					inject_at(&data.hand_pile, drop_index, old_handle)
				}
			}
		}
		data.is_dragging = false
		data.dragged_card_handle = {}
		data.drag_start_index = -1
		data.drop_preview_index = -1
	case Input_Command_Sort_By_Rank:
		data.sort_method = .ByRank
		sort_hand(data)
	case Input_Command_Sort_By_Suite:
		data.sort_method = .BySuite
		sort_hand(data)
	}
}
