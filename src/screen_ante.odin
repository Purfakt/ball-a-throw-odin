package game

import "core:fmt"
import c "core_game"
import rl "vendor:raylib"


BlindData :: struct {
	type:   c.Blind,
	status: c.BlindStatus,
	score:  i64,
}

AnteData :: struct {
	blinds: [3]BlindData,
}

init_ante_screen :: proc(run_data: ^RunData) -> Screen {
	ante_data := new(AnteData)

	for blind, i in c.Blind {
		status: c.BlindStatus

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
		uses_hud = true,
	}
}

update_ante_screen :: proc(ctx: ^GameContext, _: Layout, dt: f32) {
	_, ok := ctx.screen.data.(^AnteData)

	if !ok {return}

	for command in ctx.input_commands {
		#partial switch cmd in command {
		case InputCommand_SelectBlind:
			ctx.run_data.current_blind = cmd.blind
			transition_to_game_play(ctx)
		}
	}

	clear(&ctx.input_commands)
}

draw_blind_panel :: proc(ctx: ^GameContext, blind_data: ^BlindData, area: rl.Rectangle) {
	button_color: rl.Color
	panel_rects := vstack(area, 5, 2, context.temp_allocator)
	status_text := fmt.ctprint(c.BlindStatusText[blind_data.status])
	blind_text := fmt.ctprint(c.BlindText[blind_data.type])
	score_text := fmt.ctprintf("%v", blind_data.score)
	rect := panel_rects[0]

	switch blind_data.status {
	case .Selectable:
		button_color = {230, 130, 30, 255}
		if is_hovered(rect) {
			button_color = {250, 170, 70, 255}
		}
		if is_clicked(rect) {
			append(&ctx.input_commands, InputCommand_SelectBlind{blind = blind_data.type})
		}
	case .Upcoming:
		button_color = rl.DARKGRAY
	case .Defeated:
		button_color = rl.DARKBLUE
	}

	rl.DrawRectangleRec(area, {50, 50, 60, 255})
	rl.DrawRectangleLinesEx(area, 2, rl.GRAY)
	rl.DrawRectangleRec(rect, button_color)

	center_text_in_rect(status_text, rect, 24, rl.WHITE)
	center_text_in_rect(blind_text, panel_rects[1], 28, rl.WHITE)
	center_text_in_rect("Score at least", panel_rects[2], 20, rl.LIGHTGRAY)
	center_text_in_rect(score_text, panel_rects[3], 36, {255, 80, 80, 255})
}


draw_ante_screen :: proc(ctx: ^GameContext, layout: Layout, dt: f32) {
	data, ok := ctx.screen.data.(^AnteData)
	if !ok {return}

	x := layout.center_area.x
	y := layout.center_area.y
	w := layout.center_area.width
	h := layout.center_area.height

	panel_width := w / 4
	panel_height := h * 0.7
	padding := f32(20.0)
	start_x := x + (w / 2) - (panel_width * 1.5) - padding

	for i in 0 ..< 3 {
		panel_x := start_x + (f32(i) * (panel_width + padding))
		panel_y := y + (h / 2) - (panel_height / 2)
		panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, panel_height}

		draw_blind_panel(ctx, &data.blinds[i], panel_rect)
	}
}

delete_ante_screen :: proc(ctx: ^GameContext) {
	if data_ptr, ok := ctx.screen.data.(^AnteData); ok {
		free(data_ptr)
	}
}
