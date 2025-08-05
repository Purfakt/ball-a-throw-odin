package game

import c "core_game"
import hm "handle_map"
import rl "vendor:raylib"

Input_Command :: union {
	Input_Command_Select_Card,
	Input_Command_Play_Hand,
	Input_Command_Discard_Hand,
	Input_Command_Next_Hand,
	Input_Command_Start_Drag,
	Input_Command_End_Drag,
	Input_Command_Sort_By_Rank,
	Input_Command_Sort_By_Suite,
	Input_Command_Select_Blind,
}

Input_Command_Select_Card :: struct {
	handle: c.CardHandle,
}
Input_Command_Play_Hand :: struct {}
Input_Command_Discard_Hand :: struct {}
Input_Command_Next_Hand :: struct {}
Input_Command_Start_Drag :: struct {
	handle: c.CardHandle,
}
Input_Command_End_Drag :: struct {}
Input_Command_Sort_By_Rank :: struct {}
Input_Command_Sort_By_Suite :: struct {}
Input_Command_Select_Blind :: struct {
	blind: c.Blind,
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
				break
			}
		}
	}

	if data.is_potential_drag {
		if rl.IsMouseButtonReleased(.LEFT) {
			append(
				&ctx.input_commands,
				Input_Command_Select_Card{handle = data.potential_drag_handle},
			)
			data.is_potential_drag = false
			data.potential_drag_handle = {}
		} else {
			delta := rl.Vector2Distance(mouse_pos, data.click_start_pos)
			if delta > DRAG_THRESHOLD {
				append(
					&ctx.input_commands,
					Input_Command_Start_Drag{handle = data.potential_drag_handle},
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
			append(&ctx.input_commands, Input_Command_Play_Hand{})
			return
		}
		if is_hovered(discard_button_rect) {
			append(&ctx.input_commands, Input_Command_Discard_Hand{})
			return
		}
		if is_hovered(rank_button_rect) {
			append(&ctx.input_commands, Input_Command_Sort_By_Rank{})
			return
		}
		if is_hovered(suite_button_rect) {
			append(&ctx.input_commands, Input_Command_Sort_By_Suite{})
			return
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if data.is_dragging {
			append(&ctx.input_commands, Input_Command_End_Drag{})
		}
	}

	if rl.IsKeyPressed(.R) {
		append(&ctx.input_commands, Input_Command_Next_Hand{})
		return
	}
}
