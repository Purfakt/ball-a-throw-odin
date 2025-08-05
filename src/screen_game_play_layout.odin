package game

import c "core_game"
import hm "handle_map"

update_card_layouts :: proc(data: ^GamePlayData, layout: Layout) {
	update_hand_pile_layout(data, layout)
	update_played_pile_layout(data, layout)
}

update_hand_pile_layout :: proc(data: ^GamePlayData, layout: Layout) {
	hand_size := i32(len(data.hand_pile))
	hand_w := (CARD_WIDTH * hand_size) + (CARD_MARGIN * (hand_size - 1))
	start_x := i32(layout.center_area.x) + i32(layout.center_area.width / 2) - (hand_w / 2)

	drawing_phase, is_drawing := data.phase.(PhaseDrawingCards)

	for i := i32(0); i < hand_size; i += 1 {
		handle := data.hand_pile[i]
		card_instance := hm.get(&data.run_data.deck, handle)
		if card_instance == nil {continue}

		if is_drawing && i >= drawing_phase.deal_index {
			card_instance.target_position = DECK_POSITION
			continue
		}

		base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
		base_y :=
			i32(layout.center_area.y) + i32(layout.center_area.height) - CARD_MARGIN - CARD_HEIGHT

		card_instance.target_position.x = f32(base_x)
		card_instance.target_position.y = f32(base_y)

		if c.handle_array_contains(data.selected_cards[:], handle) {
			card_instance.target_position.y -= f32(CARD_HEIGHT) / 5.0
		}
	}
}

update_played_pile_layout :: proc(data: ^GamePlayData, layout: Layout) {
	played_size := i32(len(data.played_pile))
	hand_w := (CARD_WIDTH * played_size) + (CARD_MARGIN * (played_size - 1))
	start_x := i32(layout.center_area.x) + i32(layout.center_area.width / 2) - (hand_w / 2)

	for i := i32(0); i < played_size; i += 1 {
		handle := data.played_pile[i]
		card_instance := hm.get(&data.run_data.deck, handle)
		if card_instance == nil {continue}

		base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
		base_y :=
			i32(layout.center_area.y) +
			i32(layout.center_area.height / 2) -
			CARD_MARGIN -
			CARD_HEIGHT / 2

		card_instance.target_position.x = f32(base_x)
		card_instance.target_position.y = f32(base_y)
	}
}
