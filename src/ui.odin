package game

import rl "vendor:raylib"

Layout :: struct {
	full_screen:    rl.Rectangle,
	left_panel:     rl.Rectangle,
	center_area:    rl.Rectangle,
	joker_bar:      rl.Rectangle,
	consumable_bar: rl.Rectangle,
	deck_area:      rl.Rectangle,
}

calculate_main_layout :: proc(width, height: f32) -> Layout {
	layout: Layout

	left_panel_width := f32(250.0)
	top_bar_height := f32(120.0)

	layout.full_screen = {0, 0, width, height}

	layout.left_panel = {0, 0, left_panel_width, height}

	layout.joker_bar = {left_panel_width, 0, width - left_panel_width, top_bar_height}

	layout.center_area = {
		left_panel_width,
		top_bar_height,
		width - left_panel_width,
		height - top_bar_height,
	}

	return layout
}

vsplit :: proc(
	rect: rl.Rectangle,
	allocator := context.allocator,
	proportions: ..f32,
) -> []rl.Rectangle {
	total_proportion := f32(0)
	for p in proportions {total_proportion += p}

	results := make([]rl.Rectangle, len(proportions), allocator)
	current_y := rect.y

	for p, i in proportions {
		slice_height := (p / total_proportion) * rect.height
		results[i] = {rect.x, current_y, rect.width, slice_height}
		current_y += slice_height
	}
	return results
}

hsplit :: proc(
	rect: rl.Rectangle,
	allocator := context.allocator,
	proportions: ..f32,
) -> []rl.Rectangle {
	total_proportion := f32(0)
	for p in proportions {total_proportion += p}

	results := make([]rl.Rectangle, len(proportions), allocator)
	current_x := rect.x

	for p, i in proportions {
		slice_width := (p / total_proportion) * rect.width
		results[i] = {current_x, rect.y, slice_width, rect.height}
		current_x += slice_width
	}
	return results
}

inset :: proc(rect: rl.Rectangle, padding: f32) -> rl.Rectangle {
	return {
		rect.x + padding,
		rect.y + padding,
		rect.width - 2 * padding,
		rect.height - 2 * padding,
	}
}

cut_top :: proc(rect: ^rl.Rectangle, amount: f32) -> rl.Rectangle {
	slice := rl.Rectangle{rect.x, rect.y, rect.width, amount}
	rect.y += amount
	rect.height -= amount
	return slice
}

cut_bottom :: proc(rect: ^rl.Rectangle, amount: f32) -> rl.Rectangle {
	slice := rl.Rectangle{rect.x, rect.y, rect.width, amount}
	rect.y -= amount
	rect.height -= amount
	return slice
}

cut_left :: proc(rect: ^rl.Rectangle, amount: f32) -> rl.Rectangle {
	slice := rl.Rectangle{rect.x, rect.y, rect.width, amount}
	rect.x += amount
	rect.width -= amount
	return slice
}

cut_right :: proc(rect: ^rl.Rectangle, amount: f32) -> rl.Rectangle {
	slice := rl.Rectangle{rect.x, rect.y, rect.width, amount}
	rect.x -= amount
	rect.width -= amount
	return slice
}

left_text_in_rect :: proc(text: cstring, rect: rl.Rectangle, font_size: i32, color: rl.Color) {
	text_pos_x := i32(rect.x)
	text_pos_y := i32(rect.y + (rect.height / 2) - f32(font_size / 2))
	rl.DrawText(text, text_pos_x, text_pos_y, font_size, color)
}

center_text_in_rect :: proc(text: cstring, rect: rl.Rectangle, font_size: i32, color: rl.Color) {
	text_len := rl.MeasureText(text, font_size)
	text_pos_x := i32(rect.x + (rect.width / 2) - f32(text_len / 2))
	text_pos_y := i32(rect.y + (rect.height / 2) - f32(font_size / 2))
	rl.DrawText(text, text_pos_x, text_pos_y, font_size, color)
}

right_text_in_rect :: proc(text: cstring, rect: rl.Rectangle, font_size: i32, color: rl.Color) {
	text_len := rl.MeasureText(text, font_size)
	text_pos_x := i32(rect.x + rect.height - f32(text_len))
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

CardLayout :: struct {
	target_rect:     rl.Rectangle,
	target_rotation: f32,
	color:           rl.Color,
	font_size:       i32,
}

is_hovered :: proc(area: rl.Rectangle) -> bool {
	return rl.CheckCollisionPointRec(rl.GetMousePosition(), area)
}

is_clicked :: proc(area: rl.Rectangle) -> bool {
	return is_hovered(area) && rl.IsMouseButtonPressed(.LEFT)
}
