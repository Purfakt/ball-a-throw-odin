package game

import "core:fmt"
import c "core_game"
import hm "handle_map"
import rl "vendor:raylib"

draw_game_play_screen :: proc(ctx: ^GameContext, layout: Layout, dt: f32) {
	data, game_ok := ctx.screen.data.(^GamePlayData)

	if !game_ok {
		return
	}

	rl.ClearBackground(rl.DARKGREEN)

	hand_size := i32(len(data.hand_pile))
	for i := i32(0); i < hand_size; i += 1 {
		card_handle := data.hand_pile[i]

		if data.is_dragging && card_handle == data.dragged_card_handle {
			continue
		}

		card_instance := hm.get(&data.run_data.deck, card_handle)
		draw_card(card_instance^)
	}

	if data.is_dragging {
		card_instance := hm.get(&data.run_data.deck, data.dragged_card_handle)
		if card_instance != nil {
			draw_card(card_instance^)
		}
	}

	played_size := i32(len(data.played_pile))

	for i := i32(0); i < played_size; i += 1 {
		_, card_handle := get_card_table_target_layout(data, i, layout)
		card_instance := hm.get(&data.run_data.deck, card_handle)

		if card_instance == nil {
			continue
		}
		is_scoring := c.handle_array_contains(data.scoring_cards_handles[:], card_handle)
		draw_card(card_instance^)
		if state, ok := data.phase.(PhasePlayingCards); ok && state.scoring_index == i {
			draw_card_highlight(card_instance^, is_scoring)
		}
	}

	if _, ok := data.phase.(PhaseGameOver); ok {
		draw_game_over(data, layout)
		return
	}

	if _, ok := data.phase.(PhaseSelectingCards); ok {
		draw_hand_indicator(data.selected_hand, layout)
		draw_play_discard_buttons(layout)
		draw_sort_buttons(layout)
	}

	if state, ok := data.phase.(PhasePlayingCards); ok {
		draw_updating_score(state.current_chips, state.base_mult, layout)
	}

	draw_info(data.run_data, data, layout)
}

draw_updating_score :: proc(chips, mult: i64, layout: Layout) {
	score_text := fmt.ctprintf("%v x %v = %v", chips, mult, chips * mult)
	score_area := rl.Rectangle {
		layout.center_area.x,
		layout.center_area.y,
		layout.center_area.width,
		layout.center_area.height - (2 * CARD_HEIGHT_F),
	}
	center_text_in_rect(score_text, score_area, 40, rl.WHITE)
}

draw_hand_indicator :: proc(hand: c.HandType, layout: Layout) {
	if hand != .None {
		hand_text := fmt.ctprint(c.HandString[hand])
		indicator_area := rl.Rectangle{0, 40, layout.center_area.width, 30}
		center_text_in_rect(hand_text, indicator_area, 30, rl.GOLD)
	}
}

draw_sort_buttons :: proc(layout: Layout) {
	rank_button_rect := get_sort_rank_button_rect(layout)
	suite_button_rect := get_sort_suite_button_rect(layout)

	rank_color := rl.DARKPURPLE
	sort_text_font_size := i32(20)
	if is_hovered(rank_button_rect) {rank_color = rl.PURPLE}
	rl.DrawRectangleRec(rank_button_rect, rank_color)
	center_text_in_rect("Sort Rank", rank_button_rect, sort_text_font_size, rl.WHITE)


	suite_color := rl.DARKPURPLE
	if is_hovered(suite_button_rect) {suite_color = rl.PURPLE}
	rl.DrawRectangleRec(suite_button_rect, suite_color)
	center_text_in_rect("Sort Suite", suite_button_rect, sort_text_font_size, rl.WHITE)
}

draw_play_discard_buttons :: proc(layout: Layout) {
	play_button_rect := get_play_button_rect(layout)
	discard_button_rect := get_discard_button_rect(layout)

	play_color := rl.DARKBLUE
	text_font_size := i32(20)

	if is_hovered(play_button_rect) {play_color = rl.BLUE}
	rl.DrawRectangleRec(play_button_rect, play_color)
	center_text_in_rect("Play", play_button_rect, text_font_size, rl.WHITE)


	discard_color := rl.MAROON
	if is_hovered(discard_button_rect) {discard_color = rl.RED}
	rl.DrawRectangleRec(discard_button_rect, discard_color)
	center_text_in_rect("Discard", discard_button_rect, text_font_size, rl.WHITE)
}

draw_game_over :: proc(data: ^GamePlayData, layout: Layout) {
	w := i32(layout.full_screen.width)
	h := i32(layout.full_screen.height)
	rl.DrawRectangle(0, 0, w, h, {0, 0, 0, 100})

	game_over_font_size := i32(112)
	score_font_size := i32(60)

	margin := i32(20)
	total_height := f32(game_over_font_size + margin + score_font_size)
	game_over_area := rl.Rectangle{0, f32(h) / 2 - total_height / 2, f32(w), total_height}
	game_over_rects := vstack(game_over_area, 2, f32(margin), context.temp_allocator)
	defer delete(game_over_rects)

	center_text_in_rect("Game Over", game_over_rects[0], game_over_font_size, rl.WHITE)
	score_text := fmt.ctprintf("Score: %d", data.current_score)
	center_text_in_rect(score_text, game_over_rects[1], score_font_size, rl.WHITE)
}

get_sort_rank_button_rect :: proc(layout: Layout) -> rl.Rectangle {
	w, h := 150, 50
	x := layout.center_area.x + layout.center_area.width / 2 + 20
	y := layout.center_area.y + layout.center_area.height - f32(CARD_HEIGHT) - f32(h) - 60
	return {x, y, f32(w), f32(h)}
}

get_sort_suite_button_rect :: proc(layout: Layout) -> rl.Rectangle {
	w, h := 150, 50
	x := layout.center_area.x + layout.center_area.width / 2 - f32(w) - 20
	y := layout.center_area.y + layout.center_area.height - f32(CARD_HEIGHT) - f32(h) - 60
	return {x, y, f32(w), f32(h)}
}

get_play_button_rect :: proc(layout: Layout) -> rl.Rectangle {
	w, h := 150, 50
	y :=
		layout.center_area.y +
		layout.center_area.height -
		f32(CARD_HEIGHT) -
		f32(CARD_MARGIN) +
		f32(h)
	x := layout.center_area.x + layout.center_area.width - f32(w) - 20

	return {x, y, f32(w), f32(h)}
}

get_discard_button_rect :: proc(layout: Layout) -> rl.Rectangle {
	w, h := 150, 50
	y :=
		layout.center_area.y +
		layout.center_area.height -
		f32(CARD_HEIGHT) -
		f32(CARD_MARGIN) +
		f32(h)
	x := layout.center_area.x + layout.center_area.width - f32(w) - 20

	return {x, y - f32(h) - 10, f32(w), f32(h)}
}

get_card_hand_target_layout :: proc(
	data: ^GamePlayData,
	i: i32,
	layout: Layout,
) -> (
	card_layout: CardLayout,
	handle: c.CardHandle,
) {
	handle = data.hand_pile[i]

	is_selected := c.handle_array_contains(data.selected_cards[:], handle)

	w := layout.center_area.width
	h := layout.center_area.height
	center_w := w / 2
	hand_size := i32(len(data.hand_pile))
	hand_w := (CARD_WIDTH * hand_size) + (CARD_MARGIN * (hand_size - 1))
	start_x := i32(layout.center_area.x) + i32(center_w) - (hand_w / 2)

	base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
	base_y := i32(layout.center_area.y) + i32(h) - CARD_MARGIN - CARD_HEIGHT

	if data.is_dragging && handle != data.dragged_card_handle {
		logical_index := i
		if logical_index > data.drag_start_index {
			logical_index -= 1
		}

		effective_preview := data.drop_preview_index
		if effective_preview > data.drag_start_index {
			effective_preview -= 1
		}

		visual_index := logical_index
		if logical_index >= data.drop_preview_index {
			visual_index += 1
		}

		base_x = start_x + visual_index * (CARD_WIDTH + CARD_MARGIN)
	}

	final_x := f32(base_x)
	final_y := f32(base_y)
	if is_selected {
		final_y -= f32(CARD_HEIGHT) / 5.0
	}

	card_layout.target_rect = {final_x, final_y, f32(CARD_WIDTH), f32(CARD_HEIGHT)}
	card_layout.target_rotation = 0
	card_layout.font_size = CARD_FONT_SIZE
	card_layout.color = rl.LIGHTGRAY

	if data.hovered_card == handle {
		card_layout.color = rl.WHITE
	}

	return
}

get_card_table_target_layout :: proc(
	data: ^GamePlayData,
	i: i32,
	layout: Layout,
) -> (
	card_layout: CardLayout,
	handle: c.CardHandle,
) {
	handle = data.played_pile[i]

	w := i32(layout.center_area.width)
	h := i32(layout.center_area.height)
	x := i32(layout.center_area.x)
	y := i32(layout.center_area.y)
	center_w := w / 2
	center_h := h / 2
	played_size := i32(len(data.played_pile))
	hand_w := (CARD_WIDTH * played_size) + (CARD_MARGIN * (played_size - 1))
	start_x := x + center_w - (hand_w / 2)

	base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
	base_y := y + center_h - CARD_MARGIN - CARD_HEIGHT / 2

	final_x := f32(base_x)
	final_y := f32(base_y)

	card_layout.target_rect = {final_x, final_y, f32(CARD_WIDTH), f32(CARD_HEIGHT)}
	card_layout.target_rotation = 0
	card_layout.font_size = CARD_FONT_SIZE
	card_layout.color = rl.LIGHTGRAY

	return
}

draw_card :: proc(card_instance: c.CardInstance) {
	card_dest_rect := rl.Rectangle {
		x      = card_instance.position.x + CARD_WIDTH_F / 2,
		y      = card_instance.position.y + CARD_HEIGHT_F / 2,
		width  = CARD_WIDTH_F,
		height = CARD_HEIGHT_F,
	}

	card_origin := rl.Vector2{CARD_WIDTH_F / 2, CARD_HEIGHT_F / 2}

	rl.DrawRectanglePro(card_dest_rect, card_origin, card_instance.rotation, rl.LIGHTGRAY)

	card_center := rl.Vector2 {
		card_instance.position.x + CARD_WIDTH_F / 2,
		card_instance.position.y + CARD_HEIGHT_F / 2,
	}

	rank_text := fmt.ctprintf("%v", c.RankString[card_instance.data.rank])
	text_size := rl.MeasureTextEx(rl.GetFontDefault(), rank_text, CARD_FONT_SIZE_F, 1)

	text_position := rl.Vector2{card_center.x - text_size.x / 2, card_center.y - text_size.y / 2}

	rl.DrawTextPro(
		rl.GetFontDefault(),
		rank_text,
		text_position,
		{},
		card_instance.rotation,
		CARD_FONT_SIZE_F,
		1.0,
		rl.Color(c.SuiteColor[card_instance.data.suite]),
	)
}

draw_card_highlight :: proc(card_instance: c.CardInstance, is_scoring: bool) {
	rect := rl.Rectangle {
		x      = card_instance.position.x,
		y      = card_instance.position.y,
		width  = CARD_WIDTH_F,
		height = CARD_HEIGHT_F,
	}
	highlight_color := rl.DARKBROWN
	if is_scoring {
		highlight_color = rl.GOLD
	}
	rl.DrawRectangleLinesEx(rect, 4, highlight_color)
}
