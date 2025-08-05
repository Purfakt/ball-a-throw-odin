package game

import "core:fmt"
import c "core_game"
import rl "vendor:raylib"

draw_hud :: proc(ctx: ^GameContext, layout: Layout) {
	rl.DrawRectangleRec(layout.left_panel, {20, 20, 30, 255})

	game_play_data, ok := ctx.screen.data.(^GamePlayData)
	if (!ok) {
		game_play_data = nil
	}
	draw_info(ctx.run_data, game_play_data, layout)

	rl.DrawRectangleRec(layout.joker_bar, {30, 30, 40, 255})
	center_text_in_rect("Jokers Go Here", layout.joker_bar, 30, rl.WHITE)
}


draw_info :: proc(run_data: ^RunData, data: ^GamePlayData, layout: Layout) {
	to_beat := run_data.current_blind
	blind_score := c.score_at_least(to_beat, run_data.current_ante)
	current_score := i64(0)
	hands_played := i8(0)
	discards_used := i8(0)
	if data != nil {
		current_score = data.current_score
		hands_played = data.hands_played
		discards_used = data.discards_used
	}

	current_score_text := fmt.ctprintf("Score: %v", current_score)
	blind_score_text := fmt.ctprintf("Blind: %v", blind_score)
	hands_text := fmt.ctprintf("Hands: %v", run_data.hands_per_blind - hands_played)
	discards_text := fmt.ctprintf("Discards: %v", run_data.discard_per_blind - discards_used)
	money_text := fmt.ctprintf("Money: %v", run_data.money)

	info_area := rl.Rectangle{20, 20, 250, 140}
	font_size := i32(30)
	color := rl.WHITE
	info_rects := vstack(info_area, 5, 5, context.temp_allocator)
	left_text_in_rect(current_score_text, info_rects[0], font_size, color)
	left_text_in_rect(blind_score_text, info_rects[1], font_size, color)
	left_text_in_rect(hands_text, info_rects[2], font_size, color)
	left_text_in_rect(discards_text, info_rects[3], font_size, color)
	left_text_in_rect(money_text, info_rects[4], font_size, color)
}
