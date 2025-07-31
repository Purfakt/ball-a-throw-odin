package game

import "core:log"
import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:sort"
import c "core_game"
import hm "handle_map"
import rl "vendor:raylib"

MS_GamePlay :: struct {
	gs:                           GamePlaySate,
	run_data:                     ^RunData,

	// Current blind
	blind_score:                  i128,
	hands_played:                 i8,
	discards_used:                i8,
	// Score
	current_mult:                 i64,
	current_chip:                 i64,
	current_score:                i128,
	selected_hand:                c.HandType,
	// Piles
	draw_pile:                    c.Pile,
	played_pile:                  c.Pile,
	hand_pile:                    c.Pile,
	selected_cards:               c.Pile,
	// User input
	scoring_cards_handles:        c.Selection,
	hovered_card:                 c.CardHandle,
	previous_hovered_card:        c.CardHandle,
	has_refreshed_selected_cards: bool,
	sort_method:                  c.SortMethod,
	// Dragging
	is_potential_drag:            bool,
	potential_drag_handle:        c.CardHandle,
	click_start_pos:              rl.Vector2,
	is_dragging:                  bool,
	dragged_card_handle:          c.CardHandle,
	dragged_card_offset:          rl.Vector2,
	drag_start_index:             i32,
	drop_preview_index:           i32,
}

GamePlaySate :: union {
	GS_DrawingCards,
	GS_SelectingCards,
	GS_PlayingCards,
	GS_WinningBlind,
	GS_GameOver,
}

GS_DrawingCards :: struct {
	deal_timer: f32,
	deal_index: i32,
}

GS_SelectingCards :: struct {}

PlayingCardsPhase :: enum {
	DealingToTable,
	ScoringHand,
	Finishing,
}

GS_PlayingCards :: struct {
	phase:           PlayingCardsPhase,
	animation_timer: f32,
	scoring_index:   i32,
	base_chips:      i64,
	base_mult:       i64,
	current_chips:   i64,
}

GS_GameOver :: struct {}
GS_WinningBlind :: struct {}

init_MS_Game :: proc(run_data: ^RunData) -> MainState {
	log.info("init_MS_Game")
	draw_pile := make(c.Pile)
	played_pile := make(c.Pile)
	hand_pile := make(c.Pile)
	selected_cards := make(c.Pile)
	c.init_drawing_pile(&run_data.deck, &draw_pile)

	ms := new(MS_GamePlay)
	ms.run_data = run_data
	ms.draw_pile = draw_pile
	ms.played_pile = played_pile
	ms.hand_pile = hand_pile
	ms.selected_cards = selected_cards
	ms.drag_start_index = -1
	ms.blind_score = 450


	state := MainState {
		ms     = ms,
		draw   = draw_MS_Game,
		update = update_MS_Game,
		delete = delete_MS_Game,
	}

	next_hand(state.ms.(^MS_GamePlay))

	return state
}

next_hand :: proc(ms: ^MS_GamePlay) {
	c.empty_pile(&ms.played_pile)
	c.empty_pile(&ms.selected_cards)
	ms.selected_hand = .None
	replenish_hand_and_start_deal(ms)
}

play_selected_cards :: proc(ms: ^MS_GamePlay) {
	if len(ms.selected_cards) == 0 {
		return
	}

	hand := ms.selected_hand
	base_chips := i64(c.HandChip[hand])
	base_mult := i64(c.HandMult[hand])

	hand_size := i32(len(ms.hand_pile))

	for i := hand_size - 1; i >= 0; i -= 1 {
		handle := ms.hand_pile[i]
		if c.handle_array_contains(ms.selected_cards[:], handle) {
			ordered_remove(&ms.hand_pile, i)
			append(&ms.played_pile, handle)
		}
	}

	slice.reverse(ms.played_pile[:])

	c.empty_pile(&ms.selected_cards)
	ms.hands_played += 1

	ms.gs = GS_PlayingCards {
		phase           = .DealingToTable,
		animation_timer = 0.5,
		scoring_index   = -1,
		base_chips      = base_chips,
		base_mult       = base_mult,
		current_chips   = base_chips,
	}
}

discard_selected_cards :: proc(ms: ^MS_GamePlay) {
	num_to_discard := len(ms.selected_cards)
	if num_to_discard == 0 {
		return
	}

	for i := len(ms.hand_pile) - 1; i >= 0; i -= 1 {
		handle := ms.hand_pile[i]
		if c.handle_array_contains(ms.selected_cards[:], handle) {
			ordered_remove(&ms.hand_pile, i)
		}
	}
	c.empty_pile(&ms.selected_cards)
	ms.selected_hand = .None
	ms.discards_used += 1

	replenish_hand_and_start_deal(ms)
}

replenish_hand_and_start_deal :: proc(ms: ^MS_GamePlay) {
	hand_size_before_draw := i32(len(ms.hand_pile))

	if hand_size_before_draw < BASE_DRAW_AMOUNT {
		num_to_draw := BASE_DRAW_AMOUNT - hand_size_before_draw
		c.draw_cards_into(&ms.draw_pile, &ms.hand_pile, num_to_draw)

		for i := hand_size_before_draw; i < i32(len(ms.hand_pile)); i += 1 {
			handle := ms.hand_pile[i]
			card := hm.get(&ms.run_data.deck, handle)
			if card != nil {
				card.position = DECK_POSITION
			}
		}
	}

	sort_hand(ms)

	ms.gs = GS_DrawingCards {
		deal_timer = 0,
		deal_index = hand_size_before_draw,
	}
}

HandSortContext :: struct {
	pile: []c.CardHandle,
	deck: ^c.Deck,
}

hand_sort_len :: proc(it: sort.Interface) -> int {
	ctx := (^HandSortContext)(it.collection)
	return len(ctx.pile)
}


hand_sort_swap :: proc(it: sort.Interface, i, j: int) {
	ctx := (^HandSortContext)(it.collection)
	ctx.pile[i], ctx.pile[j] = ctx.pile[j], ctx.pile[i]
}

hand_sort_less_by_rank :: proc(it: sort.Interface, i, j: int) -> bool {
	ctx := (^HandSortContext)(it.collection)

	card_a := hm.get(ctx.deck, ctx.pile[i])
	card_b := hm.get(ctx.deck, ctx.pile[j])

	return card_a.data.rank > card_b.data.rank
}

hand_sort_less_by_suite :: proc(it: sort.Interface, i, j: int) -> bool {
	ctx := (^HandSortContext)(it.collection)

	card_a := hm.get(ctx.deck, ctx.pile[i])
	card_b := hm.get(ctx.deck, ctx.pile[j])

	if card_a.data.suite != card_b.data.suite {
		return card_a.data.suite < card_b.data.suite
	}
	return card_a.data.rank > card_b.data.rank
}

sort_hand :: proc(ms: ^MS_GamePlay) {
	ctx := HandSortContext {
		pile = ms.hand_pile[:],
		deck = &ms.run_data.deck,
	}

	sorter: sort.Interface
	sorter.collection = &ctx
	sorter.len = hand_sort_len
	sorter.swap = hand_sort_swap

	switch ms.sort_method {
	case .ByRank:
		sorter.less = hand_sort_less_by_rank
		sort.sort(sorter)
	case .BySuite:
		sorter.less = hand_sort_less_by_suite
		sort.sort(sorter)
	}
}

draw_MS_Game :: proc(ctx: ^GameContext, dt: f32, ui: UiContext) {
	ms, game_ok := ctx.state.ms.(^MS_GamePlay)

	if !game_ok {
		return
	}

	rl.ClearBackground(rl.DARKGREEN)

	hand_size := i32(len(ms.hand_pile))
	for i := i32(0); i < hand_size; i += 1 {
		card_handle := ms.hand_pile[i]

		if ms.is_dragging && card_handle == ms.dragged_card_handle {
			continue
		}

		card_instance := hm.get(&ms.run_data.deck, card_handle)
		draw_card(card_instance^)
	}

	if ms.is_dragging {
		card_instance := hm.get(&ms.run_data.deck, ms.dragged_card_handle)
		if card_instance != nil {
			draw_card(card_instance^)
		}
	}

	played_size := i32(len(ms.played_pile))

	for i := i32(0); i < played_size; i += 1 {
		_, card_handle := get_card_table_target_layout(ms, i)
		card_instance := hm.get(&ms.run_data.deck, card_handle)

		if card_instance == nil {
			continue
		}
		is_scoring := c.handle_array_contains(ms.scoring_cards_handles[:], card_handle)
		draw_card(card_instance^)
		if state, ok := ms.gs.(GS_PlayingCards); ok && state.scoring_index == i {
			draw_card_highlight(card_instance^, is_scoring)
		}
	}

	if _, ok := ms.gs.(GS_GameOver); ok {
		draw_game_over(ms, ui)
		return
	}

	if _, ok := ms.gs.(GS_SelectingCards); ok {
		draw_hand_indicator(ms.selected_hand, ui)
		draw_play_discard_buttons(ms, ui)
		draw_sort_buttons(ms, ui)
	}

	if state, ok := ms.gs.(GS_PlayingCards); ok {
		draw_updating_score(state.current_chips, state.base_mult, ui)
	}

	draw_blind_info(ms, ui)
}

update_MS_Game :: proc(ctx: ^GameContext, dt: f32) {
	if ctx.state.in_transition {
		return
	}

	ms, game_ok := ctx.state.ms.(^MS_GamePlay)

	if !game_ok {return}

	for command in ctx.input_commands {
		process_command(ms, command)
	}
	clear(&ctx.input_commands)


	gs := &ms.gs


	switch &state in gs {
	case GS_DrawingCards:
		update_GS_drawing_cards(ms, &state, dt)
	case GS_SelectingCards:
		update_GS_selecting_cards(ctx, ms, &state, dt)
	case GS_PlayingCards:
		update_GS_playing_cards(ms, &state, dt)
	case GS_GameOver:
		return
	case GS_WinningBlind:
		return
	}

	animation_speed: f32 = 10.0
	hand_size := i32(len(ms.hand_pile))

	for i := i32(0); i < hand_size; i += 1 {
		handle := ms.hand_pile[i]
		card_instance := hm.get(&ms.run_data.deck, handle)
		if card_instance == nil {
			continue
		}

		if ms.is_dragging {
			w := i32(rl.GetScreenWidth())
			center_w := w / 2
			hand_w_calc := (CARD_WIDTH * hand_size) + (CARD_MARGIN * (hand_size - 1))
			start_x := f32(center_w - (hand_w_calc / 2))
			slot_width := f32(CARD_WIDTH + CARD_MARGIN)

			mouse_pos := rl.GetMousePosition()
			relative_x := mouse_pos.x - start_x
			preview_index := i32(math.round(relative_x / slot_width))

			if preview_index < 0 {preview_index = 0}
			if preview_index > hand_size {preview_index = hand_size}
			ms.drop_preview_index = preview_index
		}

		if ms.is_dragging && handle == ms.dragged_card_handle {
			mouse_pos := rl.GetMousePosition()
			card_instance.position = {
				mouse_pos.x + ms.dragged_card_offset.x,
				mouse_pos.y + ms.dragged_card_offset.y,
			}
			continue
		}

		target_layout, _ := get_card_hand_target_layout(ms, i)
		target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

		current_target_pos := target_pos
		if state, ok := &gs.(GS_DrawingCards); ok && i >= state.deal_index {
			current_target_pos = DECK_POSITION
		}

		target_rot: f32 = 0
		if card_instance.jiggle_timer > 0 {
			card_instance.jiggle_timer -= dt

			jiggle_phase := (JIGGLE_DURATION - card_instance.jiggle_timer) * JIGGLE_FREQUENCY
			target_rot = linalg.sin(jiggle_phase) * JIGGLE_STRENGTH

			target_rot *= (card_instance.jiggle_timer / JIGGLE_DURATION)
		}

		card_instance.position = linalg.lerp(
			card_instance.position,
			current_target_pos,
			animation_speed * dt,
		)
		card_instance.rotation = linalg.lerp(
			card_instance.rotation,
			target_rot,
			animation_speed * dt,
		)
	}


	played_size := i32(len(ms.played_pile))

	for i := i32(0); i < played_size; i += 1 {
		handle := ms.played_pile[i]
		card_instance := hm.get(&ms.run_data.deck, handle)
		if card_instance == nil {
			continue
		}

		target_layout, _ := get_card_table_target_layout(ms, i)
		target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

		card_instance.position = linalg.lerp(
			card_instance.position,
			target_pos,
			animation_speed * dt,
		)
		card_instance.rotation = linalg.lerp(card_instance.rotation, 0, animation_speed * dt)
	}
}

update_GS_drawing_cards :: proc(ms: ^MS_GamePlay, gs: ^GS_DrawingCards, dt: f32) {
	gs.deal_timer -= dt
	hand_size := i32(len(ms.hand_pile))

	if gs.deal_timer <= 0 {
		gs.deal_timer = DEAL_DELAY
		if gs.deal_index < hand_size {
			gs.deal_index += 1
		}
	}

	if hand_size > 0 && gs.deal_index >= hand_size {
		last_card_handle := ms.hand_pile[hand_size - 1]
		last_card_instance := hm.get(&ms.run_data.deck, last_card_handle)

		if last_card_instance == nil {
			return
		}
		target_layout, _ := get_card_hand_target_layout(ms, hand_size - 1)
		target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

		if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
			ms.gs = GS_SelectingCards{}
		}
	}
}

update_GS_selecting_cards :: proc(
	ctx: ^GameContext,
	ms: ^MS_GamePlay,
	gs: ^GS_SelectingCards,
	dt: f32,
) {
	if ms.hovered_card != ms.previous_hovered_card && ms.hovered_card != {} {
		card := hm.get(&ms.run_data.deck, ms.hovered_card)
		if card == nil {
			return
		}
		card.jiggle_timer = JIGGLE_DURATION
	}

	if len(ms.selected_cards) > 0 && ms.has_refreshed_selected_cards {
		ms.has_refreshed_selected_cards = false
		selected_data := make([dynamic]c.CardInstance)
		reserve(&selected_data, len(ms.selected_cards))

		for handle in ms.selected_cards {
			card_instance := hm.get(&ms.run_data.deck, handle)
			if card_instance != nil {
				append(&selected_data, card_instance^)
			}
		}
		defer delete(selected_data)

		if hand, ok := c.evaluate_hand(selected_data[:]); ok {
			ms.selected_hand = hand.hand_type
			ms.scoring_cards_handles = hand.scoring_handles
		}
	}
}

update_GS_playing_cards :: proc(ms: ^MS_GamePlay, gs: ^GS_PlayingCards, dt: f32) {
	gs.animation_timer -= dt

	played_size := i32(len(ms.played_pile))

	if gs.phase == .DealingToTable {
		last_card_handle := ms.played_pile[played_size - 1]
		last_card_instance := hm.get(&ms.run_data.deck, last_card_handle)
		if last_card_instance == nil {
			return
		}
		target_layout, _ := get_card_table_target_layout(ms, played_size - 1)
		target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

		if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
			gs.phase = .ScoringHand
			gs.animation_timer = 0.5
		}
	}

	if gs.phase == .ScoringHand && gs.animation_timer <= 0 {
		gs.scoring_index += 1

		if gs.scoring_index < played_size {
			card_handle := ms.played_pile[gs.scoring_index]
			contains := c.handle_array_contains(ms.scoring_cards_handles[:], card_handle)
			if contains {
				card := hm.get(&ms.run_data.deck, card_handle)
				if card != nil {
					gs.current_chips += i64(c.RankChip[card.data.rank])
				}
			}

			gs.animation_timer = 0.4
		} else {
			gs.phase = .Finishing
			gs.animation_timer = 1.5
		}
	}

	if gs.phase == .Finishing && gs.animation_timer <= 0 {
		final_score := gs.current_chips * gs.base_mult
		ms.current_score += i128(final_score)

		c.empty_pile(&ms.played_pile)
		ms.selected_hand = .None

		if ms.hands_played < ms.run_data.hands_per_blind {
			replenish_hand_and_start_deal(ms)
		} else if ms.current_score < ms.blind_score {
			ms.gs = GS_GameOver{}
		} else {
			ms.gs = GS_WinningBlind{}
		}
	}
}

process_command :: proc(ms: ^MS_GamePlay, command: Input_Command) {
	gs := &ms.gs
	_, is_selecting_cards := gs.(GS_SelectingCards)
	switch type in command {
	case Input_Command_Select_Card:
		if !is_selecting_cards {break}
		if c.handle_array_contains(ms.selected_cards[:], type.handle) {
			c.handle_array_remove_handle(&ms.selected_cards, type.handle)
		} else if len(ms.selected_cards) < MAX_SELECTED {
			append(&ms.selected_cards, type.handle)
		}
		ms.has_refreshed_selected_cards = true

	case Input_Command_Play_Hand:
		if !is_selecting_cards {break}
		if ms.hands_played < ms.run_data.hands_per_blind {
			play_selected_cards(ms)
		}

	case Input_Command_Discard_Hand:
		if !is_selecting_cards {break}
		if ms.discards_used < ms.run_data.discard_per_blind {
			discard_selected_cards(ms)
		}

	case Input_Command_Next_Hand:
		next_hand(ms)
	case Input_Command_Start_Drag:
		if !is_selecting_cards {break}
		card_instance := hm.get(&ms.run_data.deck, type.handle)
		if card_instance != nil {
			ms.is_dragging = true
			ms.dragged_card_handle = type.handle
			mouse_pos := rl.GetMousePosition()
			ms.dragged_card_offset = {
				card_instance.position.x - mouse_pos.x,
				card_instance.position.y - mouse_pos.y,
			}
			ms.drag_start_index = -1
			for &handle, i in ms.hand_pile {
				if handle == type.handle {
					ms.drag_start_index = i32(i)
					break
				}
			}
		}

	case Input_Command_End_Drag:
		if ms.is_dragging {
			drop_index := ms.drop_preview_index

			if drop_index > ms.drag_start_index {
				drop_index -= 1
			}

			if drop_index != ms.drag_start_index {
				old_handle := ms.dragged_card_handle
				if c.handle_array_remove_handle(&ms.hand_pile, old_handle) {
					inject_at(&ms.hand_pile, drop_index, old_handle)
				}
			}
		}
		ms.is_dragging = false
		ms.dragged_card_handle = {}
		ms.drag_start_index = -1
		ms.drop_preview_index = -1
	case Input_Command_Sort_By_Rank:
		ms.sort_method = .ByRank
		sort_hand(ms)

	case Input_Command_Sort_By_Suite:
		ms.sort_method = .BySuite
		sort_hand(ms)
	}

}

delete_MS_Game :: proc(ctx: ^GameContext) {
	state, ok := ctx.state.ms.(^MS_GamePlay)
	if !ok {return}

	delete(state.draw_pile)
	delete(state.selected_cards)
	delete(state.hand_pile)
	delete(state.played_pile)
}
