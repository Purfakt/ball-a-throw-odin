package game

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
