package game

import "core:fmt"
import rl "vendor:raylib"

draw_total_score :: proc(score: i128) {
	total_score_text := fmt.ctprintf("Score: %v", score)
	rl.DrawText(total_score_text, 20, 20, 30, rl.WHITE)
}

draw_updating_score :: proc(chips, mult: i64, w, h: f32) {
	score_text := fmt.ctprintf("%v x %v = %v", chips, mult, chips * mult)
	text_size := rl.MeasureText(score_text, 40)
	rl.DrawText(score_text, i32(w / 2) - text_size / 2, i32(h / 2) + 80, 40, rl.WHITE)
}

draw_hand_indicator :: proc(hand: HandType, w, h: f32) {
	if hand != .None {
		hand_text := fmt.ctprint(HandString[hand])
		text_size := rl.MeasureText(hand_text, 30)
		rl.DrawText(hand_text, i32(w / 2) - text_size / 2, 40, 30, rl.GOLD)
	}
}

draw_play_discard_buttons :: proc(ms: MS_Game, w, h: f32) {
	button_w, button_h := 150, 50
	button_y := h - f32(CARD_HEIGHT) - f32(button_h) - 40
	play_button_rect := rl.Rectangle{w / 2 + 20, button_y, f32(button_w), f32(button_h)}
	discard_button_rect := rl.Rectangle {
		w / 2 - f32(button_w) - 20,
		button_y,
		f32(button_w),
		f32(button_h),
	}

	mouse_pos := rl.GetMousePosition()

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
