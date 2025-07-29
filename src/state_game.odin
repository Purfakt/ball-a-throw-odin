package game

import "core:log"
import "core:math/linalg"
import "core:slice"
import hm "handle_map"
import rl "vendor:raylib"

MS_Game :: struct {
	gs:                           GameSate,
	deck:                         Deck,
	current_mult:                 i64,
	current_chip:                 i64,
	current_score:                i128,
	draw_pile:                    Pile,
	played_pile:                  Pile,
	scoring_cards_handles:        Selection,
	hand_pile:                    Pile,
	selected_cards:               Pile,
	has_refreshed_selected_cards: bool,
	hovered_card:                 CardHandle,
	previous_hovered_card:        CardHandle,
	selected_hand:                HandType,
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
		},
		draw = draw_MS_Game,
		update = update_MS_Game,
	}

	next_hand(&state.ms.(MS_Game))

	return state
}

next_hand :: proc(ms: ^MS_Game) {
	empty_pile(&ms.played_pile)
	hand_size := i32(len(ms.hand_pile))
	if hand_size < BASE_DRAW_AMOUNT {
		draw_cards_into(&ms.draw_pile, &ms.hand_pile, BASE_DRAW_AMOUNT - hand_size)
		for i := i32(0); i < hand_size; i += 1 {
			handle := ms.hand_pile[i]
			card := hm.get(&ms.deck, handle)
			if card == nil {
				continue
			}
			card.position = DECK_POSITION
		}
	}


	ms.gs = GS_DrawingCards {
		deal_timer = 0,
		deal_index = 0,
	}
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
	hand_size := len(ms.hand_pile)
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

	draw_cards_into(&ms.draw_pile, &ms.hand_pile, i32(num_to_discard))

	for i := hand_size - num_to_discard; i < hand_size; i += 1 {
		handle := ms.hand_pile[i]
		card := hm.get(&ms.deck, handle)
		if card == nil {
			continue
		}
		card.position = DECK_POSITION
	}

	ms.gs = GS_DrawingCards {
		deal_timer = 0,
		deal_index = 0,
	}
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

draw_MS_Game :: proc(dt: f32) {
	ms, game_ok := gm.state.ms.(MS_Game)

	if !game_ok {
		return
	}

	rl.ClearBackground(rl.DARKGREEN)

	hand_size := i32(len(ms.hand_pile))
	for i := i32(0); i < hand_size; i += 1 {
		_, card_handle := get_card_hand_target_layout(&ms, i)
		card_instance := hm.get(&ms.deck, card_handle)

		draw_card(card_instance^)
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


	if _, ok := ms.gs.(GS_SelectingCards); ok {
		draw_hand_indicator(ms.selected_hand, w, h)
		draw_play_discard_buttons(ms, w, h)
	}

	if state, ok := ms.gs.(GS_PlayingCards); ok {
		draw_updating_score(state.current_chips, state.base_mult, w, h)
	}

	draw_total_score(ms.current_score)
}

update_MS_Game :: proc(dt: f32) {
	if gm.state.in_transition {
		return
	}

	ms, game_ok := &gm.state.ms.(MS_Game)

	if !game_ok {
		return
	}

	gs := &ms.gs

	mouse_pos := rl.GetMousePosition()
	hand_size := i32(len(ms.hand_pile))

	switch &state in gs {
	case GS_DrawingCards:
		state.deal_timer -= dt


		if state.deal_timer <= 0 {
			state.deal_timer = DEAL_DELAY
			if state.deal_index < hand_size {
				state.deal_index += 1
			}
		}

		if hand_size > 0 && state.deal_index >= hand_size {
			last_card_handle := ms.hand_pile[hand_size - 1]
			last_card_instance := hm.get(&ms.deck, last_card_handle)

			if last_card_instance == nil {
				break
			}

			target_layout, _ := get_card_hand_target_layout(ms, hand_size - 1)
			target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

			if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
				ms.gs = GS_SelectingCards{}
			}
		}
	case GS_SelectingCards:
		ms.hovered_card = {}

		for i := hand_size - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_hand_target_layout(ms, i)

			if rl.CheckCollisionPointRec(mouse_pos, target_layout.target_rect) {
				ms.hovered_card = card_handle

				if rl.IsMouseButtonPressed(.LEFT) {
					if handle_array_contains(ms.selected_cards[:], card_handle) {
						handle_array_remove_handle(&ms.selected_cards, card_handle)
					} else if len(ms.selected_cards) < MAX_SELECTED {
						append(&ms.selected_cards, card_handle)
					}
					ms.has_refreshed_selected_cards = true
				}
				break
			}
		}

		if ms.hovered_card != ms.previous_hovered_card && ms.hovered_card != {} {
			card := hm.get(&ms.deck, ms.hovered_card)
			if card == nil {
				break
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

		if rl.IsMouseButtonPressed(.LEFT) {
			w, h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
			button_w, button_h := 150, 50
			button_y := h - f32(CARD_HEIGHT) - f32(button_h) - 40
			play_button_rect := rl.Rectangle{w / 2 + 20, button_y, f32(button_w), f32(button_h)}
			discard_button_rect := rl.Rectangle {
				w / 2 - f32(button_w) - 20,
				button_y,
				f32(button_w),
				f32(button_h),
			}

			if rl.CheckCollisionPointRec(mouse_pos, play_button_rect) {
				play_selected_cards(ms)
				return
			}
			if rl.CheckCollisionPointRec(mouse_pos, discard_button_rect) {
				discard_selected_cards(ms)
				return
			}
		}

		if rl.IsKeyPressed(.R) {
			next_hand(ms)
			return
		}
		break
	case GS_PlayingCards:
		state.animation_timer -= dt

		played_size := i32(len(ms.played_pile))

		if state.phase == .DealingToTable {
			last_card_handle := ms.played_pile[played_size - 1]
			last_card_instance := hm.get(&ms.deck, last_card_handle)
			if last_card_instance == nil {
				break
			}
			target_layout, _ := get_card_table_target_layout(ms, played_size - 1)
			target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

			if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
				state.phase = .ScoringHand
				state.animation_timer = 0.5
			}
		}

		if state.phase == .ScoringHand && state.animation_timer <= 0 {
			state.scoring_index += 1
			rank_chip := RankChip

			if state.scoring_index < played_size {
				card_handle := ms.played_pile[state.scoring_index]
				contains := handle_array_contains(ms.scoring_cards_handles[:], card_handle)
				if contains {
					card := hm.get(&ms.deck, card_handle)
					if card != nil {
						state.current_chips += i64(rank_chip[card.data.rank])
					}
				}

				state.animation_timer = 0.4
			} else {
				state.phase = .Finishing
				state.animation_timer = 1.5
			}
		}

		if state.phase == .Finishing && state.animation_timer <= 0 {
			final_score := state.current_chips * state.base_mult
			ms.current_score += i128(final_score)
			log.info("Final score for hand:", final_score, "Total score:", ms.current_score)
			next_hand(ms)
		}
	}

	animation_speed: f32 = 10.0
	for i := i32(0); i < hand_size; i += 1 {
		handle := ms.hand_pile[i]
		card_instance := hm.get(&ms.deck, handle)
		if card_instance == nil {
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
