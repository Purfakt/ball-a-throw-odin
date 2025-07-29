package game

import "core:fmt"
import rl "vendor:raylib"

UiContext :: struct {
	w:         f32,
	h:         f32,
	mouse_pos: rl.Vector2,
}

draw_total_score :: proc(score: i128, ui: UiContext) {
	total_score_text := fmt.ctprintf("Score: %v", score)
	rl.DrawText(total_score_text, 20, 20, 30, rl.WHITE)
}

draw_updating_score :: proc(chips, mult: i64, ui: UiContext) {
	score_text := fmt.ctprintf("%v x %v = %v", chips, mult, chips * mult)
	text_size := rl.MeasureText(score_text, 40)
	rl.DrawText(score_text, i32(ui.w / 2) - text_size / 2, i32(ui.h / 2) + 80, 40, rl.WHITE)
}

draw_hand_indicator :: proc(hand: HandType, ui: UiContext) {
	if hand != .None {
		hand_text := fmt.ctprint(HandString[hand])
		text_size := rl.MeasureText(hand_text, 30)
		rl.DrawText(hand_text, i32(ui.w / 2) - text_size / 2, 40, 30, rl.GOLD)
	}
}

draw_play_discard_buttons :: proc(ms: MS_Game, ui: UiContext) {
	button_w, button_h := 150, 50
	button_y := ui.h - f32(CARD_HEIGHT) - f32(button_h) - 40
	play_button_rect := rl.Rectangle{ui.w / 2 + 20, button_y, f32(button_w), f32(button_h)}
	discard_button_rect := rl.Rectangle {
		ui.w / 2 - f32(button_w) - 20,
		button_y,
		f32(button_w),
		f32(button_h),
	}

	mouse_pos := ui.mouse_pos

	play_color := rl.DARKBLUE
	if rl.CheckCollisionPointRec(mouse_pos, play_button_rect) {play_color = rl.BLUE}
	rl.DrawRectangleRec(play_button_rect, play_color)
	rl.DrawText("Play", i32(play_button_rect.x) + 50, i32(play_button_rect.y) + 15, 20, rl.WHITE)

	discard_color := rl.MAROON
	if rl.CheckCollisionPointRec(mouse_pos, discard_button_rect) {discard_color = rl.RED}
	rl.DrawRectangleRec(discard_button_rect, discard_color)
	rl.DrawText(
		"Discard",
		i32(discard_button_rect.x) + 35,
		i32(discard_button_rect.y) + 15,
		20,
		rl.WHITE,
	)
}

get_card_hand_target_layout :: proc(
	ms: ^MS_Game,
	i: i32,
) -> (
	layout: CardLayout,
	handle: CardHandle,
) {
	handle = ms.hand_pile[i]

	is_selected := handle_array_contains(ms.selected_cards[:], handle)

	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	hand_size := i32(len(ms.hand_pile))
	hand_w := (CARD_WIDTH * hand_size) + (CARD_MARGIN * (hand_size - 1))
	start_x := center_w - (hand_w / 2)

	base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
	base_y := h - CARD_MARGIN - CARD_HEIGHT

	final_x := f32(base_x)
	final_y := f32(base_y)
	if is_selected {
		final_y -= f32(CARD_HEIGHT) / 5.0
	}

	layout.target_rect = {final_x, final_y, f32(CARD_WIDTH), f32(CARD_HEIGHT)}
	layout.target_rotation = 0
	layout.font_size = CARD_FONT_SIZE
	layout.color = rl.LIGHTGRAY

	if ms.hovered_card == handle {
		layout.color = rl.WHITE
	}

	return
}

get_card_table_target_layout :: proc(
	ms: ^MS_Game,
	i: i32,
) -> (
	layout: CardLayout,
	handle: CardHandle,
) {
	handle = ms.played_pile[i]

	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	center_h := h / 2
	played_size := i32(len(ms.played_pile))
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

draw_card :: proc(card_instance: CardInstance) {
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

	rank_text := fmt.ctprintf("%v", RankString[card_instance.data.rank])
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
		rl.Color(SuiteColor[card_instance.data.suite]),
	)
}

draw_card_highlight :: proc(card_instance: CardInstance, is_scoring: bool) {
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
