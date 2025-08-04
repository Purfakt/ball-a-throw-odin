package game

import "core:fmt"
import rl "vendor:raylib"

MainMenuData :: struct {}

init_menu_screen :: proc() -> Screen {
	return Screen {
		data = new(MainMenuData),
		draw = draw_menu_screen,
		update = update_menu_screen,
		delete = delete_menu_screen,
		uses_hud = false,
	}
}

update_menu_screen :: proc(ctx: ^GameContext, ui: UiContext, dt: f32) {
	if rl.IsKeyPressed(.SPACE) {
		transition_to_ante(ctx)
	}
}

draw_menu_screen :: proc(ctx: ^GameContext, ui: UiContext, dt: f32) {
	w := i32(ui.layout.full_screen.width)
	h := i32(ui.layout.full_screen.height)
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

delete_menu_screen :: proc(ctx: ^GameContext) {
	if data_ptr, ok := ctx.screen.data.(^MainMenuData); ok {
		free(data_ptr)
	}
}
