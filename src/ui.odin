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
