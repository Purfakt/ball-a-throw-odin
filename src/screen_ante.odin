package game

import "core:fmt"
import c "core_game"
import rl "vendor:raylib"


BlindStatus :: enum {
	Selectable,
	Upcoming,
	Defeated,
}

BlindData :: struct {
	type:   c.Blind,
	status: BlindStatus,
	score:  i64,
}

AnteData :: struct {
	blinds: [3]BlindData,
}

init_ante_screen :: proc(run_data: ^RunData) -> Screen {
	ante_data := new(AnteData)

	for blind, i in c.Blind {
		status: BlindStatus

		if i < int(run_data.current_blind) {
			status = .Defeated
		} else if i == int(run_data.current_blind) {
			status = .Selectable
		} else {
			status = .Upcoming
		}

		ante_data.blinds[i] = BlindData {
			type   = blind,
			status = status,
			score  = c.score_at_least(blind, run_data.current_ante),
		}
	}

	return Screen {
		data = ante_data,
		draw = draw_ante_screen,
		update = update_ante_screen,
		delete = delete_ante_screen,
	}
}

process_ante_command :: proc(ctx: ^GameContext, data: ^AnteData, command: Input_Command) {
	#partial switch cmd in command {
	case Input_Command_Select_Blind:
		ctx.run_data.current_blind = cmd.blind
		transition_to_game_play(ctx)
	}
}

update_ante_screen :: proc(ctx: ^GameContext, ui: UiContext, dt: f32) {
	data, ok := ctx.screen.data.(^AnteData)
	if !ok {return}

	panel_width := ui.w / 4
	padding := f32(20.0)
	start_x := (ui.w / 2) - (panel_width * 1.5) - padding

	for _, i in c.Blind {
		blind_data := &data.blinds[i]
		if blind_data.status == .Selectable {
			panel_x := start_x + (f32(i) * (panel_width + padding))
			panel_y := (ui.h / 2) - ((ui.h * 0.7) / 2)
			panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, ui.h * 0.7}
			button_rect := vstack(panel_rect, 5, 10, context.temp_allocator)[0]

			if do_status_button(ctx, ui, "Select", blind_data.status, button_rect) {
				append(&ctx.input_commands, Input_Command_Select_Blind{blind = blind_data.type})
			}
		}
	}

	for command in ctx.input_commands {
		process_ante_command(ctx, data, command)
	}
	clear(&ctx.input_commands)
}

do_status_button :: proc(
	ctx: ^GameContext,
	ui: UiContext,
	text: cstring,
	status: BlindStatus,
	rect: rl.Rectangle,
) -> bool {
	is_clicked := false

	color: rl.Color
	switch status {
	case .Selectable:
		is_hovered := rl.CheckCollisionPointRec(ui.mouse_pos, rect)
		color = {230, 130, 30, 255}
		if is_hovered {
			color = {250, 170, 70, 255}
			if rl.IsMouseButtonReleased(.LEFT) {
				is_clicked = true
			}
		}
	case .Upcoming:
		color = rl.DARKGRAY
	case .Defeated:
		color = rl.DARKBLUE
	}

	rl.DrawRectangleRec(rect, color)
	center_text_in_rect(text, rect, 24, rl.WHITE)

	return is_clicked
}

draw_blind_panel :: proc(
	ctx: ^GameContext,
	ui: UiContext,
	blind_data: ^BlindData,
	area: rl.Rectangle,
) {
	rl.DrawRectangleRec(area, {50, 50, 60, 255})
	rl.DrawRectangleLinesEx(area, 2, rl.GRAY)

	panel_rects := vstack(area, 5, 2, context.temp_allocator)

	status_text: cstring
	switch blind_data.status {
	case .Selectable:
		status_text = "Select"
	case .Upcoming:
		status_text = "Upcoming"
	case .Defeated:
		status_text = "Defeated"
	}
	if do_status_button(ctx, ui, status_text, blind_data.status, panel_rects[0]) {
		ctx.run_data.current_blind = blind_data.type
	}

	blind_name: cstring
	switch blind_data.type {
	case .Little:
		blind_name = "Small Blind"
	case .Big:
		blind_name = "Big Blind"
	case .Boss:
		blind_name = "Boss Blind"
	}

	_ = do_status_button(ctx, ui, status_text, blind_data.status, panel_rects[0])

	center_text_in_rect(blind_name, panel_rects[1], 28, rl.WHITE)

	center_text_in_rect("Score at least", panel_rects[2], 20, rl.LIGHTGRAY)

	score_text := fmt.ctprintf("%v", blind_data.score)
	center_text_in_rect(score_text, panel_rects[3], 36, {255, 80, 80, 255})
}


draw_ante_screen :: proc(ctx: ^GameContext, ui: UiContext, dt: f32) {
	data, ok := ctx.screen.data.(^AnteData)
	if !ok {return}

	rl.ClearBackground(rl.DARKGREEN)

	panel_width := ui.w / 4
	panel_height := ui.h * 0.7
	padding := f32(20.0)
	start_x := (ui.w / 2) - (panel_width * 1.5) - padding

	for i in 0 ..< 3 {
		panel_x := start_x + (f32(i) * (panel_width + padding))
		panel_y := (ui.h / 2) - (panel_height / 2)
		panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, panel_height}

		draw_blind_panel(ctx, ui, &data.blinds[i], panel_rect)
	}
}

delete_ante_screen :: proc(ctx: ^GameContext) {
	if data_ptr, ok := ctx.screen.data.(^AnteData); ok {
		free(data_ptr)
	}
}
