package game

import c "core_game"

GamePlayData :: struct {
	phase:                        GamePlayPhase,
	run_data:                     ^RunData,

	// Current blind
	hands_played:                 i8,
	discards_used:                i8,
	blind_score:                  i64,
	// Score
	current_mult:                 i32,
	current_chip:                 i32,
	current_score:                i64,
	selected_hand:                c.HandType,
	// Piles
	draw_pile:                    c.CardPile,
	played_pile:                  c.CardPile,
	hand_pile:                    c.CardPile,
	selected_cards:               c.CardPile,
	// User input
	scoring_cards_handles:        c.CardSelection,
	hovered_card:                 c.CardHandle,
	previous_hovered_card:        c.CardHandle,
	selected_consumable_index:    int,
	has_refreshed_selected_cards: bool,
	sort_method:                  c.SortMethod,
	// Dragging
	is_potential_drag:            bool,
	potential_drag_handle:        c.CardHandle,
	click_start_pos:              [2]f32,
	is_dragging:                  bool,
	dragged_card_handle:          c.CardHandle,
	dragged_card_offset:          [2]f32,
	drag_start_index:             i32,
	drop_preview_index:           i32,
}

GamePlayPhase :: union {
	PhaseDrawingCards,
	PhaseSelectingCards,
	PhasePlayingCards,
	PhaseWinningBlind,
	PhaseGameOver,
}

PhaseDrawingCards :: struct {
	deal_timer:          f32,
	deal_index:          i32,
	is_finished_dealing: bool,
}

PhaseSelectingCards :: struct {}

PhasePlayingCards :: struct {
	step:            PlayingCardsStep,
	animation_timer: f32,
	scoring_index:   i32,
	base_chips:      i64,
	base_mult:       i64,
	current_chips:   i64,
}


PlayingCardsStep :: enum {
	DealingToTable,
	ScoringHand,
	Finishing,
}

PhaseGameOver :: struct {}
PhaseWinningBlind :: struct {}

init_game_play_screen :: proc(run_data: ^RunData) -> Screen {
	draw_pile := make(c.CardPile)
	played_pile := make(c.CardPile)
	hand_pile := make(c.CardPile)
	selected_cards := make(c.CardPile)
	c.init_drawing_pile(&run_data.deck, &draw_pile)

	data := new(GamePlayData)
	data.run_data = run_data
	data.draw_pile = draw_pile
	data.played_pile = played_pile
	data.hand_pile = hand_pile
	data.selected_cards = selected_cards
	data.selected_consumable_index = -1
	data.drag_start_index = -1
	data.blind_score = c.score_at_least(data.run_data.current_blind, data.run_data.current_ante)


	state := Screen {
		data     = data,
		draw     = draw_game_play_screen,
		update   = update_game_play_screen,
		delete   = delete_game_play_data,
		uses_hud = true,
	}

	next_hand(state.data.(^GamePlayData))

	return state
}

delete_game_play_data :: proc(ctx: ^GameContext) {
	data_ptr, ok := ctx.screen.data.(^GamePlayData)
	if !ok {return}

	delete(data_ptr.draw_pile)
	delete(data_ptr.selected_cards)
	delete(data_ptr.hand_pile)
	delete(data_ptr.played_pile)
	free(data_ptr)
}
