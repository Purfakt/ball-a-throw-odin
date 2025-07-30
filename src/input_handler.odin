package game

import c "core_game"
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

handle_input :: proc(ctx: ^GameContext, ui: UiContext) {
	if ctx.state.in_transition {
		return
	}

	switch ms_ptr in ctx.state.ms {
	case ^MS_MainMenu:
		handle_main_menu_input(ctx, ui)
	case ^MS_GamePlay:
		handle_gameplay_input(ctx, ui)
	}
}

handle_main_menu_input :: proc(ctx: ^GameContext, ui: UiContext) {
	if rl.IsKeyPressed(.SPACE) {
		transition_to_game_play(ctx)
	}
}

handle_gameplay_input :: proc(ctx: ^GameContext, ui: UiContext) {
	if ctx.state.in_transition {
		return
	}

	ms, game_ok := ctx.state.ms.(^MS_GamePlay)
	gs := ms.gs

	if !game_ok {
		return
	}

	ms.hovered_card = {}

	if rl.IsMouseButtonPressed(.LEFT) {
		hand_size := i32(len(ms.hand_pile))
		for i := hand_size - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_hand_target_layout(ms, i)
			if rl.CheckCollisionPointRec(ui.mouse_pos, target_layout.target_rect) {
				if _, is_selecting_cards := gs.(GS_SelectingCards); is_selecting_cards {
					ms.is_potential_drag = true
					ms.potential_drag_handle = card_handle
					ms.click_start_pos = ui.mouse_pos
				}
				break
			}
		}
	}

	if ms.is_potential_drag {
		if rl.IsMouseButtonReleased(.LEFT) {
			append(
				&ctx.input_commands,
				Input_Command_Select_Card{handle = ms.potential_drag_handle},
			)
			ms.is_potential_drag = false
			ms.potential_drag_handle = {}
		} else {
			delta := rl.Vector2Distance(ui.mouse_pos, ms.click_start_pos)
			if delta > DRAG_THRESHOLD {
				append(
					&ctx.input_commands,
					Input_Command_Start_Drag{handle = ms.potential_drag_handle},
				)
				ms.is_potential_drag = false
				ms.potential_drag_handle = {}
			}
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if ms.is_dragging {
			append(&ctx.input_commands, Input_Command_End_Drag{})
		}
	}

	if !ms.is_dragging && !ms.is_potential_drag {
		hand_size := i32(len(ms.hand_pile))
		for i := hand_size - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_hand_target_layout(ms, i)
			if rl.CheckCollisionPointRec(ui.mouse_pos, target_layout.target_rect) {
				ms.hovered_card = card_handle
				break
			}
		}
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		play_button_rect := get_play_button_rect(ms, ui)
		discard_button_rect := get_discard_button_rect(ms, ui)
		rank_button_rect := get_sort_rank_button_rect(ui)
		suite_button_rect := get_sort_suite_button_rect(ui)

		if rl.CheckCollisionPointRec(ui.mouse_pos, play_button_rect) {
			append(&ctx.input_commands, Input_Command_Play_Hand{})
			return
		}
		if rl.CheckCollisionPointRec(ui.mouse_pos, discard_button_rect) {
			append(&ctx.input_commands, Input_Command_Discard_Hand{})
			return
		}
		if rl.CheckCollisionPointRec(ui.mouse_pos, rank_button_rect) {
			append(&ctx.input_commands, Input_Command_Sort_By_Rank{})
			return
		}
		if rl.CheckCollisionPointRec(ui.mouse_pos, suite_button_rect) {
			append(&ctx.input_commands, Input_Command_Sort_By_Suite{})
			return
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if ms.is_dragging {
			append(&ctx.input_commands, Input_Command_End_Drag{})
		}
	}

	if rl.IsKeyPressed(.R) {
		append(&ctx.input_commands, Input_Command_Next_Hand{})
		return
	}
}
