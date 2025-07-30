package game

import rl "vendor:raylib"

Input_Command :: union {
	Input_Command_Select_Card,
	Input_Command_Play_Hand,
	Input_Command_Discard_Hand,
	Input_Command_Next_Hand,
	Input_Command_Start_Drag,
	Input_Command_End_Drag,
}

Input_Command_Select_Card :: struct {
	handle: CardHandle,
}
Input_Command_Play_Hand :: struct {}
Input_Command_Discard_Hand :: struct {}
Input_Command_Next_Hand :: struct {}
Input_Command_Start_Drag :: struct {
	handle: CardHandle,
}
Input_Command_End_Drag :: struct {}

handle_input :: proc() {
	if gm.state.in_transition {
		return
	}

	ms, game_ok := &gm.state.ms.(MS_Game)
	gs := ms.gs

	if !game_ok {
		return
	}

	ms.hovered_card = {}

	mouse_pos := rl.GetMousePosition()

	if rl.IsMouseButtonPressed(.LEFT) {
		hand_size := i32(len(ms.hand_pile))
		for i := hand_size - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_hand_target_layout(ms, i)
			if rl.CheckCollisionPointRec(mouse_pos, target_layout.target_rect) {
				if _, is_selecting_cards := gs.(GS_SelectingCards); is_selecting_cards {
					ms.is_potential_drag = true
					ms.potential_drag_handle = card_handle
					ms.click_start_pos = mouse_pos
				}
				break
			}
		}
	}

	if ms.is_potential_drag {
		if rl.IsMouseButtonReleased(.LEFT) {
			append(
				&gm.input_commands,
				Input_Command_Select_Card{handle = ms.potential_drag_handle},
			)
			ms.is_potential_drag = false
			ms.potential_drag_handle = {}
		} else {
			delta := rl.Vector2Distance(mouse_pos, ms.click_start_pos)
			if delta > DRAG_THRESHOLD {
				append(
					&gm.input_commands,
					Input_Command_Start_Drag{handle = ms.potential_drag_handle},
				)
				ms.is_potential_drag = false
				ms.potential_drag_handle = {}
			}
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if ms.is_dragging {
			append(&gm.input_commands, Input_Command_End_Drag{})
		}
	}

	if !ms.is_dragging && !ms.is_potential_drag {
		hand_size := i32(len(ms.hand_pile))
		for i := hand_size - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_hand_target_layout(ms, i)
			if rl.CheckCollisionPointRec(mouse_pos, target_layout.target_rect) {
				ms.hovered_card = card_handle
				break
			}
		}
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		w, h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
		button_w, button_h := 150, 50
		button_y := h - f32(CARD_HEIGHT) - f32(button_h) - 40
		play_button_rect := rl.Rectangle{w / 2 + 20, button_y, f32(button_w), f32(button_h)}
		discard_button_rect := rl.Rectangle {
			w / 2 - f32(button_w) - 20,
			button_y,
			f32(button_w),
			f32(button_h),
		}

		if rl.CheckCollisionPointRec(mouse_pos, play_button_rect) {
			append(&gm.input_commands, Input_Command_Play_Hand{})
			return
		}
		if rl.CheckCollisionPointRec(mouse_pos, discard_button_rect) {
			append(&gm.input_commands, Input_Command_Discard_Hand{})
			return
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if ms.is_dragging {
			append(&gm.input_commands, Input_Command_End_Drag{})
		}
	}

	if rl.IsKeyPressed(.R) {
		append(&gm.input_commands, Input_Command_Next_Hand{})
		return
	}
}
