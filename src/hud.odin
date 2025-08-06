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

	draw_player_cards_bar(ctx, layout)
}

draw_player_cards_bar :: proc(ctx: ^GameContext, layout: Layout) {
	bar_area := layout.joker_bar

	card_slot_width := f32(80)
	card_slot_height := f32(110)
	card_padding := f32(10)
	spacing_between_groups := f32(20)

	jokers_width := 5 * card_slot_width + 4 * card_padding
	consumables_width := 2 * card_slot_width + 1 * card_padding
	total_width := jokers_width + consumables_width + spacing_between_groups

	start_x := bar_area.x + (bar_area.width / 2) - (total_width / 2)
	slot_y := bar_area.y + (bar_area.height / 2) - (card_slot_height / 2)

	joker_start_x := start_x
	for i in 0 ..< 5 {
		slot_x := joker_start_x + f32(i) * (card_slot_width + card_padding)
		slot_rect := rl.Rectangle{slot_x, slot_y, card_slot_width, card_slot_height}
		rl.DrawRectangleRec(slot_rect, {30, 30, 40, 255})
		rl.DrawRectangleLinesEx(slot_rect, 1, rl.GRAY)
	}
	placeholder_rect := rl.Rectangle{joker_start_x, slot_y, jokers_width, card_slot_height}
	center_text_in_rect("Jokers Go Here", placeholder_rect, 20, rl.WHITE)

	consumable_start_x := joker_start_x + jokers_width + spacing_between_groups
	for i in 0 ..< len(ctx.run_data.tarot_cards) {
		slot_x := consumable_start_x + f32(i) * (card_slot_width + card_padding)
		slot_rect := rl.Rectangle{slot_x, slot_y, card_slot_width, card_slot_height}
		rl.DrawRectangleRec(slot_rect, {40, 30, 50, 255})
		rl.DrawRectangleLinesEx(slot_rect, 1, rl.GRAY)

		consumable := ctx.run_data.tarot_cards[i]
		if tarot_data, ok := consumable.(c.TarotData); ok {
			if tarot_data.tarot != .None {
				center_text_in_rect(fmt.ctprint(tarot_data.name), slot_rect, 14, rl.WHITE)
			}
		}
	}
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
