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

	for handle in data.hand_pile {
		if card := hm.get(&data.run_data.deck, handle); card != nil {
			draw_card(card^)
		}
	}

	for card_handle, i in data.played_pile {
		card_instance := hm.get(&data.run_data.deck, card_handle)

		if card_instance == nil {
			continue
		}
		draw_card(card_instance^)
		if state, ok := data.phase.(PhasePlayingCards); ok && state.scoring_index >= i32(i) {
			is_scoring := c.handle_array_contains(data.scoring_cards_handles[:], card_handle)
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

		if data.selected_consumable_index != -1 {
			draw_use_tarot_button(data, layout)
		}
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

draw_use_tarot_button :: proc(data: ^GamePlayData, layout: Layout) {
	button_rect := get_use_tarot_button_rect(layout)
	button_color := rl.Color{0, 100, 200, 255}

	is_valid := false
	if data.selected_consumable_index < len(data.run_data.tarot_cards) {
		consumable := data.run_data.tarot_cards[data.selected_consumable_index]
		if tarot_data, ok := consumable.(c.TarotData); ok {
			is_valid = is_tarot_usage_valid(tarot_data, data.selected_cards)
		}
	}

	if !is_valid {
		button_color = rl.GRAY
	} else if is_hovered(button_rect) {
		button_color = rl.Color{50, 150, 255, 255}
	}
	rl.DrawRectangleRec(button_rect, button_color)
	center_text_in_rect("Use Tarot", button_rect, 20, rl.WHITE)
}

get_use_tarot_button_rect :: proc(layout: Layout) -> rl.Rectangle {
	w, h := 150, 50
	x := layout.joker_bar.x + layout.joker_bar.width - f32(w) - 20
	y := layout.joker_bar.y - f32(h) - 10
	return {x, y, f32(w), f32(h)}
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
