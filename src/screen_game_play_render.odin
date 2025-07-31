package game

import "core:fmt"
import c "core_game"
import hm "handle_map"
import rl "vendor:raylib"

draw_game_play_screen :: proc(ctx: ^GameContext, ui: UiContext, dt: f32) {
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
		_, card_handle := get_card_table_target_layout(data, i)
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
		draw_game_over(data, ui)
		return
	}

	if _, ok := data.phase.(PhaseSelectingCards); ok {
		draw_hand_indicator(data.selected_hand, ui)
		draw_play_discard_buttons(ui)
		draw_sort_buttons(ui)
	}

	if state, ok := data.phase.(PhasePlayingCards); ok {
		draw_updating_score(state.current_chips, state.base_mult, ui)
	}

	draw_blind_info(data, ui)
}

draw_blind_info :: proc(data: ^GamePlayData, ui: UiContext) {
	blind_score := c.score_at_least(data.run_data.current_blind, data.run_data.current_ante)
	current_score_text := fmt.ctprintf("Score: %v", data.current_score)
	blind_score_text := fmt.ctprintf("Blind: %v", blind_score)
	hands_text := fmt.ctprintf("Hands: %v", data.run_data.hands_per_blind - data.hands_played)
	discards_text := fmt.ctprintf(
		"Discards: %v",
		data.run_data.discard_per_blind - data.discards_used,
	)

	info_area := rl.Rectangle{20, 20, 250, 140}
	info_rects := vstack(info_area, 4, 5, context.temp_allocator)
	rl.DrawText(current_score_text, i32(info_rects[0].x), i32(info_rects[0].y), 30, rl.WHITE)
	rl.DrawText(blind_score_text, i32(info_rects[1].x), i32(info_rects[1].y), 30, rl.WHITE)
	rl.DrawText(hands_text, i32(info_rects[2].x), i32(info_rects[2].y), 30, rl.WHITE)
	rl.DrawText(discards_text, i32(info_rects[3].x), i32(info_rects[3].y), 30, rl.WHITE)

}

draw_updating_score :: proc(chips, mult: i64, ui: UiContext) {
	score_text := fmt.ctprintf("%v x %v = %v", chips, mult, chips * mult)
	score_area := rl.Rectangle{0, ui.h / 2 + 80, ui.w, 40}
	center_text_in_rect(score_text, score_area, 40, rl.WHITE)
}

draw_hand_indicator :: proc(hand: c.HandType, ui: UiContext) {
	if hand != .None {
		hand_text := fmt.ctprint(c.HandString[hand])
		indicator_area := rl.Rectangle{0, 40, ui.w, 30}
		center_text_in_rect(hand_text, indicator_area, 30, rl.GOLD)
	}
}

draw_sort_buttons :: proc(ui: UiContext) {
	rank_button_rect := get_sort_rank_button_rect(ui)
	suite_button_rect := get_sort_suite_button_rect(ui)

	rank_color := rl.DARKPURPLE
	sort_text_font_size := i32(20)
	if rl.CheckCollisionPointRec(ui.mouse_pos, rank_button_rect) {rank_color = rl.PURPLE}
	rl.DrawRectangleRec(rank_button_rect, rank_color)
	center_text_in_rect("Sort Rank", rank_button_rect, sort_text_font_size, rl.WHITE)


	suite_color := rl.DARKPURPLE
	if rl.CheckCollisionPointRec(ui.mouse_pos, suite_button_rect) {suite_color = rl.PURPLE}
	rl.DrawRectangleRec(suite_button_rect, suite_color)
	center_text_in_rect("Sort Suite", suite_button_rect, sort_text_font_size, rl.WHITE)
}

draw_play_discard_buttons :: proc(ui: UiContext) {
	play_button_rect := get_play_button_rect(ui)
	discard_button_rect := get_discard_button_rect(ui)

	mouse_pos := ui.mouse_pos

	play_color := rl.DARKBLUE
	text_font_size := i32(20)

	if rl.CheckCollisionPointRec(mouse_pos, play_button_rect) {play_color = rl.BLUE}
	rl.DrawRectangleRec(play_button_rect, play_color)
	center_text_in_rect("Play", play_button_rect, text_font_size, rl.WHITE)


	discard_color := rl.MAROON
	if rl.CheckCollisionPointRec(mouse_pos, discard_button_rect) {discard_color = rl.RED}
	rl.DrawRectangleRec(discard_button_rect, discard_color)
	center_text_in_rect("Discard", discard_button_rect, text_font_size, rl.WHITE)
}

draw_game_over :: proc(data: ^GamePlayData, ui: UiContext) {
	w := i32(ui.w)
	h := i32(ui.h)
	rl.DrawRectangle(0, 0, w, h, {0, 0, 0, 100})

	game_over_font_size := i32(112)
	score_font_size := i32(60)

	margin := i32(20)
	total_height := f32(game_over_font_size + margin + score_font_size)
	game_over_area := rl.Rectangle{0, ui.h / 2 - total_height / 2, ui.w, total_height}
	game_over_rects := vstack(game_over_area, 2, f32(margin), context.temp_allocator)
	defer delete(game_over_rects)

	center_text_in_rect("Game Over", game_over_rects[0], game_over_font_size, rl.WHITE)
	score_text := fmt.ctprintf("Score: %d", data.current_score)
	center_text_in_rect(score_text, game_over_rects[1], score_font_size, rl.WHITE)
}

get_sort_rank_button_rect :: proc(ui: UiContext) -> rl.Rectangle {
	button_w, button_h := 150, 50
	button_y := ui.h - f32(CARD_HEIGHT) - f32(button_h) - 60
	return {ui.w / 2 + 20, button_y, f32(button_w), f32(button_h)}
}

get_sort_suite_button_rect :: proc(ui: UiContext) -> rl.Rectangle {
	button_w, button_h := 150, 50
	button_y := ui.h - f32(CARD_HEIGHT) - f32(button_h) - 60
	return {ui.w / 2 - f32(button_w) - 20, button_y, f32(button_w), f32(button_h)}
}

get_play_button_rect :: proc(ui: UiContext) -> rl.Rectangle {
	button_w, button_h := 150, 50
	button_y := ui.h - f32(CARD_HEIGHT) - f32(CARD_MARGIN) + f32(button_h)
	button_x := ui.w - f32(button_w) - 20

	return {button_x, button_y, f32(button_w), f32(button_h)}
}

get_discard_button_rect :: proc(ui: UiContext) -> rl.Rectangle {
	button_w, button_h := 150, 50
	button_y := ui.h - f32(CARD_HEIGHT) - f32(CARD_MARGIN) + f32(button_h)

	button_x := ui.w - f32(button_w) - 20

	return {button_x, button_y - f32(button_h) - 10, f32(button_w), f32(button_h)}
}

get_card_hand_target_layout :: proc(
	data: ^GamePlayData,
	i: i32,
) -> (
	layout: CardLayout,
	handle: c.CardHandle,
) {
	handle = data.hand_pile[i]

	is_selected := c.handle_array_contains(data.selected_cards[:], handle)

	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	hand_size := i32(len(data.hand_pile))
	hand_w := (CARD_WIDTH * hand_size) + (CARD_MARGIN * (hand_size - 1))
	start_x := center_w - (hand_w / 2)

	base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
	base_y := h - CARD_MARGIN - CARD_HEIGHT

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
		if logical_index >= effective_preview {
			visual_index += 1
		}

		base_x = start_x + visual_index * (CARD_WIDTH + CARD_MARGIN)
	}

	final_x := f32(base_x)
	final_y := f32(base_y)
	if is_selected {
		final_y -= f32(CARD_HEIGHT) / 5.0
	}

	layout.target_rect = {final_x, final_y, f32(CARD_WIDTH), f32(CARD_HEIGHT)}
	layout.target_rotation = 0
	layout.font_size = CARD_FONT_SIZE
	layout.color = rl.LIGHTGRAY

	if data.hovered_card == handle {
		layout.color = rl.WHITE
	}

	return
}

get_card_table_target_layout :: proc(
	data: ^GamePlayData,
	i: i32,
) -> (
	layout: CardLayout,
	handle: c.CardHandle,
) {
	handle = data.played_pile[i]

	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	center_h := h / 2
	played_size := i32(len(data.played_pile))
	hand_w := (CARD_WIDTH * played_size) + (CARD_MARGIN * (played_size - 1))
	start_x := center_w - (hand_w / 2)

	base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
	base_y := center_h - CARD_MARGIN - CARD_HEIGHT / 2

	final_x := f32(base_x)
	final_y := f32(base_y)

	layout.target_rect = {final_x, final_y, f32(CARD_WIDTH), f32(CARD_HEIGHT)}
	layout.target_rotation = 0
	layout.font_size = CARD_FONT_SIZE
	layout.color = rl.LIGHTGRAY

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
