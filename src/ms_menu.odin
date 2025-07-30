package game

import "core:fmt"
import rl "vendor:raylib"

MS_Menu :: struct {}

init_MS_Menu :: proc() -> MainState {
	return MainState{ms = MS_Menu{}, draw = draw_MS_Menu, update = update_MS_Menu}
}

update_MS_Menu :: proc(dt: f32) {
	if rl.IsKeyPressed(.SPACE) {
		transition_to(proc() -> MainState {return init_MS_Game()})
	}
}

draw_MS_Menu :: proc(dt: f32, ui: UiContext) {
	w := i32(ui.w)
	h := i32(ui.h)
	rl.ClearBackground(rl.BLACK)
	title_text_font_size := i32(36)
	title_text := fmt.ctprintf("Ball-A-Throw")
	title_text_len := rl.MeasureText(title_text, title_text_font_size)
	subtext_font_size := i32(24)
	subtext := fmt.ctprintf("PRESS [SPACE] TO START")
	subtext_len := rl.MeasureText(subtext, subtext_font_size)
	rl.BeginMode2D(ui_camera())
	rl.DrawText(
		title_text,
		w / 4 - title_text_len / 2,
		h / 4 - title_text_font_size / 2,
		title_text_font_size,
		rl.WHITE,
	)
	rl.DrawText(
		subtext,
		w / 4 - subtext_len / 2,
		h / 4 + subtext_font_size / 2,
		subtext_font_size,
		rl.WHITE,
	)
	rl.EndMode2D()
}
