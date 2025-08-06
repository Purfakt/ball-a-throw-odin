package game

import c "core_game"
import hm "handle_map"
import rl "vendor:raylib"

InputCommand :: union {
	InputCommand_SelectCard,
	InputCommand_PlayHand,
	InputCommand_Discard_Hand,
	InputCommand_NextHand,
	InputCommand_StartDrag,
	InputCommand_EndDrag,
	InputCommand_SortByRank,
	InputCommand_SortBySuite,
	InputCommand_SelectBlind,
	InputCommand_UseTarot,
}

InputCommand_SelectCard :: struct {
	handle: c.CardHandle,
}
InputCommand_PlayHand :: struct {}
InputCommand_Discard_Hand :: struct {}
InputCommand_NextHand :: struct {}
InputCommand_StartDrag :: struct {
	handle: c.CardHandle,
}
InputCommand_EndDrag :: struct {}
InputCommand_SortByRank :: struct {}
InputCommand_SortBySuite :: struct {}
InputCommand_SelectBlind :: struct {
	blind: c.Blind,
}

InputCommand_UseTarot :: struct {
	index: int,
}

handle_input :: proc(ctx: ^GameContext, layout: Layout) {
	if ctx.screen.in_transition {
		return
	}

	data, game_ok := ctx.screen.data.(^GamePlayData)

	if !game_ok {
		return
	}
	phase := data.phase

	data.hovered_card = {}

	hand_size := i32(len(data.hand_pile))

	mouse_pos := rl.GetMousePosition()

	if rl.IsMouseButtonPressed(.LEFT) {
		for i := hand_size - 1; i >= 0; i -= 1 {
			card_handle := data.hand_pile[i]
			card_instance := hm.get(&data.run_data.deck, card_handle)
			if card_instance == nil {continue}

			card_rect := rl.Rectangle {
				card_instance.position.x,
				card_instance.position.y,
				CARD_WIDTH_F,
				CARD_HEIGHT_F,
			}

			if is_hovered(card_rect) {
				if _, is_selecting_cards := phase.(PhaseSelectingCards); is_selecting_cards {
					data.is_potential_drag = true
					data.potential_drag_handle = card_handle
					data.click_start_pos = mouse_pos
				}
				return
			}
		}
	}

	if data.is_potential_drag {
		if rl.IsMouseButtonReleased(.LEFT) {
			append(
				&ctx.input_commands,
				InputCommand_SelectCard{handle = data.potential_drag_handle},
			)
			data.is_potential_drag = false
			data.potential_drag_handle = {}
		} else {
			delta := rl.Vector2Distance(mouse_pos, data.click_start_pos)
			if delta > DRAG_THRESHOLD {
				append(
					&ctx.input_commands,
					InputCommand_StartDrag{handle = data.potential_drag_handle},
				)
				data.is_potential_drag = false
				data.potential_drag_handle = {}
			}
		}
	}

	if !data.is_dragging && !data.is_potential_drag {
		for i := hand_size - 1; i >= 0; i -= 1 {
			card_handle := data.hand_pile[i]
			card_instance := hm.get(&data.run_data.deck, card_handle)
			if card_instance == nil {continue}

			card_rect := rl.Rectangle {
				card_instance.position.x,
				card_instance.position.y,
				CARD_WIDTH_F,
				CARD_HEIGHT_F,
			}

			if is_hovered(card_rect) {
				data.hovered_card = card_handle
				break
			}
		}
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		play_button_rect := get_play_button_rect(layout)
		discard_button_rect := get_discard_button_rect(layout)
		rank_button_rect := get_sort_rank_button_rect(layout)
		suite_button_rect := get_sort_suite_button_rect(layout)

		if is_hovered(play_button_rect) {
			append(&ctx.input_commands, InputCommand_PlayHand{})
			return
		}
		if is_hovered(discard_button_rect) {
			append(&ctx.input_commands, InputCommand_Discard_Hand{})
			return
		}
		if is_hovered(rank_button_rect) {
			append(&ctx.input_commands, InputCommand_SortByRank{})
			return
		}
		if is_hovered(suite_button_rect) {
			append(&ctx.input_commands, InputCommand_SortBySuite{})
			return
		}

		consumable_rects := get_consumable_slot_rects(layout)
		for rect, i in consumable_rects {
			if is_hovered(rect) {
				if data.selected_consumable_index == i {
					data.selected_consumable_index = -1
				} else {
					data.selected_consumable_index = i
				}
				return
			}
		}

		if data.selected_consumable_index != -1 {
			use_button_rect := get_use_tarot_button_rect(layout)
			if is_hovered(use_button_rect) {
				append(
					&ctx.input_commands,
					InputCommand_UseTarot{index = data.selected_consumable_index},
				)
			}
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if data.is_dragging {
			append(&ctx.input_commands, InputCommand_EndDrag{})
		}
	}

	if rl.IsKeyPressed(.R) {
		append(&ctx.input_commands, InputCommand_NextHand{})
		return
	}
}
