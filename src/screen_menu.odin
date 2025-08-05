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

update_menu_screen :: proc(ctx: ^GameContext, _: Layout, _: f32) {
	if rl.IsKeyPressed(.SPACE) || rl.IsMouseButtonDown(.LEFT) {
		transition_to_ante(ctx)
	}
}

draw_menu_screen :: proc(ctx: ^GameContext, layout: Layout, dt: f32) {
	w := layout.full_screen.width
	h := layout.full_screen.height
	rl.ClearBackground(rl.BLACK)
	title_text_font_size := f32(110)
	title_text := fmt.ctprintf("Ball-A-Throw")
	subtext_font_size := f32(75)
	subtext := fmt.ctprintf("Press [SPACE] to start")
	center_text_in_rect(
		title_text,
		{x = 0, y = h / 2 - title_text_font_size / 2, width = w, height = title_text_font_size},
		i32(title_text_font_size),
		rl.WHITE,
	)
	center_text_in_rect(
		subtext,
		{x = 0, y = h / 2 + title_text_font_size / 2, width = w, height = subtext_font_size},
		i32(subtext_font_size),
		rl.WHITE,
	)
}

delete_menu_screen :: proc(ctx: ^GameContext) {
	if data_ptr, ok := ctx.screen.data.(^MainMenuData); ok {
		free(data_ptr)
	}
}
