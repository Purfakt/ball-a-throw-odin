package game

import "core:log"
import "core:math"
import "core:math/linalg"
import "core:slice"
import hm "handle_map"
import rl "vendor:raylib"

MS_Game :: struct {
	gs:                           GameSate,
	deck:                         Deck,
	// Score
	current_mult:                 i64,
	current_chip:                 i64,
	current_score:                i128,
	selected_hand:                HandType,
	// Piles
	draw_pile:                    Pile,
	played_pile:                  Pile,
	hand_pile:                    Pile,
	selected_cards:               Pile,
	// User input
	scoring_cards_handles:        Selection,
	hovered_card:                 CardHandle,
	previous_hovered_card:        CardHandle,
	has_refreshed_selected_cards: bool,
	// Dragging
	is_potential_drag:            bool,
	potential_drag_handle:        CardHandle,
	click_start_pos:              rl.Vector2,
	is_dragging:                  bool,
	dragged_card_handle:          CardHandle,
	dragged_card_offset:          rl.Vector2,
	drag_start_index:             i32,
	drop_preview_index:           i32,
}

GameSate :: union {
	GS_DrawingCards,
	GS_SelectingCards,
	GS_PlayingCards,
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

CardLayout :: struct {
	target_rect:     rl.Rectangle,
	target_rotation: f32,
	color:           rl.Color,
	font_size:       i32,
}

init_MS_Game :: proc() -> MainState {
	log.info("init_MS_Game")
	deck := init_deck()
	draw_pile := make(Pile)
	played_pile := make(Pile)
	hand_pile := make(Pile)
	selected_cards := make(Pile)
	init_drawing_pile(&deck, &draw_pile)

	state := MainState {
		ms = MS_Game {
			deck = deck,
			draw_pile = draw_pile,
			played_pile = played_pile,
			hand_pile = hand_pile,
			selected_cards = selected_cards,
			drag_start_index = -1,
		},
		draw = draw_MS_Game,
		update = update_MS_Game,
		delete = delete_MS_Game,
	}

	next_hand(&state.ms.(MS_Game))

	return state
}

next_hand :: proc(ms: ^MS_Game) {
	empty_pile(&ms.played_pile)
	empty_pile(&ms.selected_cards)
	ms.selected_hand = .None
	replenish_hand_and_start_deal(ms)
}

play_selected_cards :: proc(ms: ^MS_Game) {
	if len(ms.selected_cards) == 0 {
		return
	}

	hand := ms.selected_hand
	base_chips := i64(HandChip[hand])
	base_mult := i64(HandMult[hand])

	hand_size := i32(len(ms.hand_pile))

	for i := hand_size - 1; i >= 0; i -= 1 {
		handle := ms.hand_pile[i]
		if handle_array_contains(ms.selected_cards[:], handle) {
			ordered_remove(&ms.hand_pile, i)
			append(&ms.played_pile, handle)
		}
	}
	empty_pile(&ms.selected_cards)

	ms.gs = GS_PlayingCards {
		phase           = .DealingToTable,
		animation_timer = 0.5,
		scoring_index   = -1,
		base_chips      = base_chips,
		base_mult       = base_mult,
		current_chips   = base_chips,
	}
}

discard_selected_cards :: proc(ms: ^MS_Game) {
	num_to_discard := len(ms.selected_cards)
	if num_to_discard == 0 {
		return
	}

	for i := len(ms.hand_pile) - 1; i >= 0; i -= 1 {
		handle := ms.hand_pile[i]
		if handle_array_contains(ms.selected_cards[:], handle) {
			ordered_remove(&ms.hand_pile, i)
		}
	}
	empty_pile(&ms.selected_cards)
	ms.selected_hand = .None

	replenish_hand_and_start_deal(ms)
}

replenish_hand_and_start_deal :: proc(ms: ^MS_Game) {
	hand_size_before_draw := i32(len(ms.hand_pile))

	if hand_size_before_draw < BASE_DRAW_AMOUNT {
		num_to_draw := BASE_DRAW_AMOUNT - hand_size_before_draw
		draw_cards_into(&ms.draw_pile, &ms.hand_pile, num_to_draw)

		for i := hand_size_before_draw; i < i32(len(ms.hand_pile)); i += 1 {
			handle := ms.hand_pile[i]
			card := hm.get(&ms.deck, handle)
			if card != nil {
				card.position = DECK_POSITION
			}
		}
	}

	ms.gs = GS_DrawingCards {
		deal_timer = 0,
		deal_index = hand_size_before_draw,
	}
}

draw_MS_Game :: proc(dt: f32) {
	ms, game_ok := gm.state.ms.(MS_Game)

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

		card_instance := hm.get(&ms.deck, card_handle)
		draw_card(card_instance^)
	}

	if ms.is_dragging {
		card_instance := hm.get(&ms.deck, ms.dragged_card_handle)
		if card_instance != nil {
			draw_card(card_instance^)
		}
	}

	played_size := i32(len(ms.played_pile))

	for i := i32(0); i < played_size; i += 1 {
		_, card_handle := get_card_table_target_layout(&ms, i)
		card_instance := hm.get(&ms.deck, card_handle)

		if card_instance == nil {
			continue
		}
		is_scoring := handle_array_contains(ms.scoring_cards_handles[:], card_handle)
		draw_card(card_instance^)
		if state, ok := ms.gs.(GS_PlayingCards); ok && state.scoring_index == i {
			draw_card_highlight(card_instance^, is_scoring)
		}
	}

	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())
	mouse_pos := rl.GetMousePosition()

	ui := UiContext{w, h, mouse_pos}

	if _, ok := ms.gs.(GS_SelectingCards); ok {
		draw_hand_indicator(ms.selected_hand, ui)
		draw_play_discard_buttons(ms, ui)
	}

	if state, ok := ms.gs.(GS_PlayingCards); ok {
		draw_updating_score(state.current_chips, state.base_mult, ui)
	}

	draw_total_score(ms.current_score, ui)
}

update_MS_Game :: proc(dt: f32) {
	if gm.state.in_transition {
		return
	}

	ms, game_ok := &gm.state.ms.(MS_Game)

	if !game_ok {return}

	for command in gm.input_commands {
		process_command(ms, command)
	}
	clear(&gm.input_commands)


	gs := &ms.gs


	switch &state in gs {
	case GS_DrawingCards:
		update_GS_drawing_cards(ms, &state, dt)
	case GS_SelectingCards:
		update_GS_selecting_cards(ms, &state, dt)
	case GS_PlayingCards:
		update_GS_playing_cards(ms, &state, dt)
	}

	animation_speed: f32 = 10.0
	hand_size := i32(len(ms.hand_pile))

	for i := i32(0); i < hand_size; i += 1 {
		handle := ms.hand_pile[i]
		card_instance := hm.get(&ms.deck, handle)
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
		card_instance := hm.get(&ms.deck, handle)
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

update_GS_drawing_cards :: proc(ms: ^MS_Game, gs: ^GS_DrawingCards, dt: f32) {
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
		last_card_instance := hm.get(&ms.deck, last_card_handle)

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
update_GS_selecting_cards :: proc(ms: ^MS_Game, gs: ^GS_SelectingCards, dt: f32) {
	if ms.hovered_card != ms.previous_hovered_card && ms.hovered_card != {} {
		card := hm.get(&ms.deck, ms.hovered_card)
		if card == nil {
			return
		}
		card.jiggle_timer = JIGGLE_DURATION
	}

	if len(ms.selected_cards) > 0 && ms.has_refreshed_selected_cards {
		ms.has_refreshed_selected_cards = false
		selected_data := slice.mapper(
			ms.selected_cards[:],
			proc(handle: CardHandle) -> CardInstance {
				ms := &gm.state.ms.(MS_Game)
				c := hm.get(&ms.deck, handle)
				return c^
			},
		)
		defer delete(selected_data)

		if hand, ok := evaluate_hand(selected_data); ok {
			ms.selected_hand = hand.hand_type
			ms.scoring_cards_handles = hand.scoring_handles
		}
	}
}

update_GS_playing_cards :: proc(ms: ^MS_Game, gs: ^GS_PlayingCards, dt: f32) {
	gs.animation_timer -= dt

	played_size := i32(len(ms.played_pile))

	if gs.phase == .DealingToTable {
		last_card_handle := ms.played_pile[played_size - 1]
		last_card_instance := hm.get(&ms.deck, last_card_handle)
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
		rank_chip := RankChip

		if gs.scoring_index < played_size {
			card_handle := ms.played_pile[gs.scoring_index]
			contains := handle_array_contains(ms.scoring_cards_handles[:], card_handle)
			if contains {
				card := hm.get(&ms.deck, card_handle)
				if card != nil {
					gs.current_chips += i64(rank_chip[card.data.rank])
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

		empty_pile(&ms.played_pile)
		ms.selected_hand = .None

		replenish_hand_and_start_deal(ms)
	}
}

process_command :: proc(ms: ^MS_Game, command: Input_Command) {
	gs := &ms.gs
	_, is_selecting_cards := gs.(GS_SelectingCards)
	switch c in command {
	case Input_Command_Select_Card:
		if !is_selecting_cards {break}
		if handle_array_contains(ms.selected_cards[:], c.handle) {
			handle_array_remove_handle(&ms.selected_cards, c.handle)
		} else if len(ms.selected_cards) < MAX_SELECTED {
			append(&ms.selected_cards, c.handle)
		}
		ms.has_refreshed_selected_cards = true

	case Input_Command_Play_Hand:
		if !is_selecting_cards {break}
		play_selected_cards(ms)

	case Input_Command_Discard_Hand:
		if !is_selecting_cards {break}
		discard_selected_cards(ms)

	case Input_Command_Next_Hand:
		next_hand(ms)
	case Input_Command_Start_Drag:
		if !is_selecting_cards {break}
		card_instance := hm.get(&ms.deck, c.handle)
		if card_instance != nil {
			ms.is_dragging = true
			ms.dragged_card_handle = c.handle
			mouse_pos := rl.GetMousePosition()
			ms.dragged_card_offset = {
				card_instance.position.x - mouse_pos.x,
				card_instance.position.y - mouse_pos.y,
			}
			ms.drag_start_index = -1
			for &handle, i in ms.hand_pile {
				if handle == c.handle {
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
				if handle_array_remove_handle(&ms.hand_pile, old_handle) {
					inject_at(&ms.hand_pile, drop_index, old_handle)
				}
			}
		}
		ms.is_dragging = false
		ms.dragged_card_handle = {}
		ms.drag_start_index = -1
		ms.drop_preview_index = -1
	}
}

delete_MS_Game :: proc() {
	state, ok := gm.state.ms.(MS_Game)
	if !ok {return}

	delete(state.draw_pile)
	delete(state.selected_cards)
	delete(state.hand_pile)
	delete(state.played_pile)
}
