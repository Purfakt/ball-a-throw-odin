package game

import "core:fmt"
import c "core_game"
import rl "vendor:raylib"

UiContext :: struct {
	w:         f32,
	h:         f32,
	mouse_pos: rl.Vector2,
}

CardLayout :: struct {
	target_rect:     rl.Rectangle,
	target_rotation: f32,
	color:           rl.Color,
	font_size:       i32,
}

center_text_in_rect :: proc(text: cstring, rect: rl.Rectangle, font_size: i32, color: rl.Color) {
	text_len := rl.MeasureText(text, font_size)
	text_pos_x := i32(rect.x + (rect.width / 2) - f32(text_len / 2))
	text_pos_y := i32(rect.y + (rect.height / 2) - f32(font_size / 2))
	rl.DrawText(text, text_pos_x, text_pos_y, font_size, color)
}

vstack :: proc(
	parent_rect: rl.Rectangle,
	count: int,
	padding: f32,
	allocator := context.allocator,
) -> []rl.Rectangle {
	rects := make([]rl.Rectangle, count, allocator)

	total_padding := padding * f32(max(0, count - 1))
	item_height := (parent_rect.height - total_padding) / f32(count)

	for i in 0 ..< count {
		rects[i] = rl.Rectangle {
			x      = parent_rect.x,
			y      = parent_rect.y + (f32(i) * (item_height + padding)),
			width  = parent_rect.width,
			height = item_height,
		}
	}
	return rects
}

draw_info :: proc(run_data: ^RunData, data: ^GamePlayData, ui: UiContext) {
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
	info_rects := vstack(info_area, 5, 5, context.temp_allocator)
	rl.DrawText(current_score_text, i32(info_rects[0].x), i32(info_rects[0].y), 30, rl.WHITE)
	rl.DrawText(blind_score_text, i32(info_rects[1].x), i32(info_rects[1].y), 30, rl.WHITE)
	rl.DrawText(hands_text, i32(info_rects[2].x), i32(info_rects[2].y), 30, rl.WHITE)
	rl.DrawText(discards_text, i32(info_rects[3].x), i32(info_rects[3].y), 30, rl.WHITE)
	rl.DrawText(money_text, i32(info_rects[4].x), i32(info_rects[4].y), 30, rl.WHITE)
}
