package game

import "core:fmt"
import "core:log"
import "core:math/linalg"
import "core:slice"
import "sds"
import rl "vendor:raylib"

MainState :: struct {
	ms:            MS,
	update:        proc(dt: f32),
	draw:          proc(dt: f32),
	in_transition: bool,
	transition:    Transition,
}

MS :: union {
	MS_Menu,
	MS_Game,
}

// ------------
//  TRANSITION
// ------------

TRANSITION_TIME :: 0.2

Transition :: struct {
	time_fade_out:   f32,
	time_fade_in:    f32,
	fade:            f32,
	fade_in_done:    bool,
	next_state_proc: proc() -> MainState,
}

update_transition :: proc(dt: f32) {
	transition := &gm.state.transition
	if transition.time_fade_in < TRANSITION_TIME {
		transition.time_fade_in += dt
		transition.fade = transition.time_fade_in / TRANSITION_TIME
	} else if !transition.fade_in_done {
		transition.fade_in_done = true
		new_game_state := transition.next_state_proc()
		new_game_state.in_transition = true
		new_game_state.transition = transition^
		gm.state = new_game_state
	} else if transition.time_fade_out < TRANSITION_TIME {
		transition.time_fade_out += dt
		transition.fade = 1 - (transition.time_fade_out / TRANSITION_TIME)
	} else {
		gm.state.in_transition = false
		transition.time_fade_out = 0
		transition.time_fade_in = 0
	}
}

draw_transition :: proc(fade: f32) {
	w := rl.GetScreenWidth()
	h := rl.GetScreenHeight()
	alpha := u8(fade * f32(255))
	rl.DrawRectangle(0, 0, w, h, rl.Color{0, 0, 0, alpha})
}


transition_to :: proc(next_state_proc: proc() -> MainState) {
	transition := Transition {
		time_fade_in    = 0,
		time_fade_out   = 0,
		fade_in_done    = false,
		next_state_proc = next_state_proc,
	}
	gm.state.transition = transition
	gm.state.in_transition = true
}

// ------------
//     MENU
// ------------

MS_Menu :: struct {}

init_MS_Menu :: proc() -> MainState {
	return MainState{ms = MS_Menu{}, draw = draw_MS_Menu, update = update_MS_Menu}
}

update_MS_Menu :: proc(dt: f32) {
	if rl.IsKeyPressed(.SPACE) {
		transition_to(proc() -> MainState {return init_MS_Game()})
	}
}

draw_MS_Menu :: proc(dt: f32) {
	w := rl.GetScreenWidth()
	h := rl.GetScreenHeight()
	rl.ClearBackground(rl.BLACK)
	title_text_font_size := i32(36)
	title_text := fmt.ctprintf("Ball-A-Throw")
	title_text_len := rl.MeasureText(title_text, title_text_font_size)
	subtext_font_size := i32(24)
	subtext := fmt.ctprintf("PRESS [SPACE] TO START")
	subtext_len := rl.MeasureText(subtext, subtext_font_size)
	rl.BeginMode2D(ui_camera())
	rl.DrawText(
		title_text,
		w / 4 - title_text_len / 2,
		h / 4 - title_text_font_size / 2,
		title_text_font_size,
		rl.WHITE,
	)
	rl.DrawText(
		subtext,
		w / 4 - subtext_len / 2,
		h / 4 + subtext_font_size / 2,
		subtext_font_size,
		rl.WHITE,
	)
	rl.EndMode2D()
}

// ------------
//     GAME
// ------------

MAX_SELECTED :: 5
BASE_DRAW_AMOUNT :: 8

MS_Game :: struct {
	gs:                           GameSate,
	deck:                         Deck,
	current_mult:                 i64,
	current_chip:                 i64,
	current_score:                i128,
	draw_pile:                    Pile,
	discard_pile:                 Pile,
	played_pile:                  Pile,
	hand_pile:                    Pile,
	selected_cards:               Pile,
	has_refreshed_selected_cards: bool,
	hovered_card:                 CardHandle,
	previous_hovered_card:        CardHandle,
	selected_hand:                HandType,
	scoring_cards_handles:        ScoringPile,
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

next_hand :: proc(ms: ^MS_Game) {
	hand_size := ms.hand_pile.len
	if hand_size < BASE_DRAW_AMOUNT {
		draw_cards_into(&ms.draw_pile, &ms.hand_pile, BASE_DRAW_AMOUNT - hand_size)
		for i := i32(0); i < ms.hand_pile.len; i += 1 {
			handle := sds.array_get(ms.hand_pile, i)
			card := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue
			card.position = DECK_POSITION
		}
	}


	ms.gs = GS_DrawingCards {
		deal_timer = 0,
		deal_index = 0,
	}
}

init_MS_Game :: proc() -> MainState {
	log.info("init_MS_Game")
	deck := init_deck()
	draw_pile := init_drawing_pile(&deck)

	state := MainState {
		ms = MS_Game{deck = deck, draw_pile = draw_pile},
		draw = draw_MS_Game,
		update = update_MS_Game,
	}

	next_hand(&state.ms.(MS_Game))

	return state
}

play_selected_cards :: proc(ms: ^MS_Game) {
	if ms.selected_cards.len == 0 {
		return
	}

	hand := ms.selected_hand
	base_chips := i64(HandChip[hand])
	base_mult := i64(HandMult[hand])

	for i := ms.hand_pile.len - 1; i >= 0; i -= 1 {
		handle := sds.array_get(ms.hand_pile, i)
		if handle_array_contains(&ms.selected_cards, handle) {
			sds.array_remove(&ms.hand_pile, i)
			sds.array_push(&ms.played_pile, handle)
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
	num_to_discard := ms.selected_cards.len
	if num_to_discard == 0 {
		return
	}

	for i := ms.hand_pile.len - 1; i >= 0; i -= 1 {
		handle := sds.array_get(ms.hand_pile, i)
		if handle_array_contains(&ms.selected_cards, handle) {
			sds.array_remove(&ms.hand_pile, i)
			sds.array_push(&ms.discard_pile, handle)
		}
	}

	empty_pile(&ms.selected_cards)

	draw_cards_into(&ms.draw_pile, &ms.hand_pile, i32(num_to_discard))

	for i := ms.hand_pile.len - num_to_discard; i < ms.hand_pile.len; i += 1 {
		handle := sds.array_get(ms.hand_pile, i)
		card := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue
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
	handle = sds.array_get(ms.hand_pile, i)

	is_selected := handle_array_contains(&ms.selected_cards, handle)


	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	hand_size := ms.hand_pile.len
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
	handle = sds.array_get(ms.played_pile, i)

	// is_selected := pile_contains(&ms.selected_cards, handle)

	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	center_h := h / 2
	played_size := ms.played_pile.len
	hand_w := (CARD_WIDTH * played_size) + (CARD_MARGIN * (played_size - 1))
	start_x := center_w - (hand_w / 2)

	base_x := start_x + i * (CARD_WIDTH + CARD_MARGIN)
	base_y := center_h - CARD_MARGIN - CARD_HEIGHT / 2

	final_x := f32(base_x)
	final_y := f32(base_y)
	// if is_selected {
	// 	final_y -= f32(CARD_HEIGHT) / 5.0
	// }

	layout.target_rect = {final_x, final_y, f32(CARD_WIDTH), f32(CARD_HEIGHT)}
	layout.target_rotation = 0
	layout.font_size = CARD_FONT_SIZE
	layout.color = rl.LIGHTGRAY

	if ms.hovered_card == handle {
		layout.color = rl.WHITE
	}

	return
}

draw_MS_Game :: proc(dt: f32) {
	ms := gm.state.ms.(MS_Game)

	rl.ClearBackground(rl.BLACK)

	for i := i32(0); i < ms.hand_pile.len; i += 1 {
		_, card_handle := get_card_hand_target_layout(&ms, i)
		card_instance := sds.pool_get_ptr_safe(&ms.deck, card_handle) or_continue

		card_width := f32(CARD_WIDTH)
		card_height := f32(CARD_HEIGHT)
		font_size := f32(CARD_FONT_SIZE)

		card_dest_rect := rl.Rectangle {
			x      = card_instance.position.x + card_width / 2,
			y      = card_instance.position.y + card_height / 2,
			width  = card_width,
			height = card_height,
		}

		card_origin := rl.Vector2{card_width / 2, card_height / 2}

		rl.DrawRectanglePro(card_dest_rect, card_origin, card_instance.rotation, rl.LIGHTGRAY)

		if font_size <= 1 {continue}

		card_center := rl.Vector2 {
			card_instance.position.x + card_width / 2,
			card_instance.position.y + card_height / 2,
		}

		rank_text := fmt.ctprintf("%v", RankString[card_instance.data.rank])
		text_size := rl.MeasureTextEx(rl.GetFontDefault(), rank_text, font_size, 1)

		text_position := rl.Vector2 {
			card_center.x - text_size.x / 2,
			card_center.y - text_size.y / 2,
		}

		rl.DrawTextPro(
			rl.GetFontDefault(),
			rank_text,
			text_position,
			{},
			card_instance.rotation,
			font_size,
			1.0,
			rl.Color(SuiteColor[card_instance.data.suite]),
		)
	}

	for i := i32(0); i < ms.played_pile.len; i += 1 {
		_, card_handle := get_card_table_target_layout(&ms, i)
		card_instance := sds.pool_get_ptr_safe(&ms.deck, card_handle) or_continue
		is_scoring := handle_array_contains(&ms.scoring_cards_handles, card_handle)

		card_width := f32(CARD_WIDTH)
		card_height := f32(CARD_HEIGHT)
		font_size := f32(CARD_FONT_SIZE)

		card_dest_rect := rl.Rectangle {
			x      = card_instance.position.x + card_width / 2,
			y      = card_instance.position.y + card_height / 2,
			width  = card_width,
			height = card_height,
		}

		card_origin := rl.Vector2{card_width / 2, card_height / 2}

		color := rl.DARKGRAY
		if is_scoring {
			color = rl.LIGHTGRAY
		}

		rl.DrawRectanglePro(card_dest_rect, card_origin, card_instance.rotation, color)


		if font_size <= 1 {continue}

		card_center := rl.Vector2 {
			card_instance.position.x + card_width / 2,
			card_instance.position.y + card_height / 2,
		}

		rank_text := fmt.ctprintf("%v", RankString[card_instance.data.rank])
		text_size := rl.MeasureTextEx(rl.GetFontDefault(), rank_text, font_size, 1)

		text_position := rl.Vector2 {
			card_center.x - text_size.x / 2,
			card_center.y - text_size.y / 2,
		}

		rl.DrawTextPro(
			rl.GetFontDefault(),
			rank_text,
			text_position,
			{},
			card_instance.rotation,
			font_size,
			1.0,
			rl.Color(SuiteColor[card_instance.data.suite]),
		)
		if state, ok := ms.gs.(GS_PlayingCards); ok && state.scoring_index == i {
			rect := rl.Rectangle {
				x      = card_instance.position.x,
				y      = card_instance.position.y,
				width  = card_width,
				height = card_height,
			}
			highlight_color := rl.DARKBROWN
			if is_scoring {
				highlight_color = rl.GOLD
			}
			rl.DrawRectangleLinesEx(rect, 4, highlight_color)
		}
	}

	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	if _, ok := ms.gs.(GS_SelectingCards); ok {
		if ms.selected_cards.len > 0 {
			hand_text := fmt.ctprint(HandString[ms.selected_hand])
			text_size := rl.MeasureText(hand_text, 30)
			rl.DrawText(hand_text, i32(w / 2) - text_size / 2, 40, 30, rl.GOLD)
		}

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

		play_color := rl.DARKGREEN
		if rl.CheckCollisionPointRec(mouse_pos, play_button_rect) {play_color = rl.GREEN}
		rl.DrawRectangleRec(play_button_rect, play_color)
		rl.DrawText(
			"Play",
			i32(play_button_rect.x) + 50,
			i32(play_button_rect.y) + 15,
			20,
			rl.WHITE,
		)

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

	if state, ok := ms.gs.(GS_PlayingCards); ok {
		score_text := fmt.ctprintf(
			"%v x %v = %v",
			state.current_chips,
			state.base_mult,
			state.current_chips * state.base_mult,
		)
		text_size := rl.MeasureText(score_text, 40)
		rl.DrawText(score_text, i32(w / 2) - text_size / 2, i32(h / 2) + 80, 40, rl.WHITE)
	}
	total_score_text := fmt.ctprintf("Score: %v", ms.current_score)
	rl.DrawText(total_score_text, 20, 20, 30, rl.WHITE)
}

update_MS_Game :: proc(dt: f32) {
	if gm.state.in_transition {
		return
	}
	ms := &gm.state.ms.(MS_Game)
	gs := &ms.gs

	mouse_pos := rl.GetMousePosition()

	switch &state in gs {
	case GS_DrawingCards:
		state.deal_timer -= dt

		if state.deal_timer <= 0 {
			state.deal_timer = DEAL_DELAY
			if state.deal_index < ms.hand_pile.len {
				state.deal_index += 1
			}
		}

		if ms.hand_pile.len > 0 && state.deal_index >= ms.hand_pile.len {
			last_card_handle := sds.array_get(ms.hand_pile, ms.hand_pile.len - 1)
			last_card_instance := sds.pool_get_ptr_safe(&ms.deck, last_card_handle) or_break

			target_layout, _ := get_card_hand_target_layout(ms, i32(ms.hand_pile.len - 1))
			target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

			if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
				ms.gs = GS_SelectingCards{}
			}
		}
	case GS_SelectingCards:
		ms.hovered_card = {}

		for i := ms.hand_pile.len - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_hand_target_layout(ms, i)

			if rl.CheckCollisionPointRec(mouse_pos, target_layout.target_rect) {
				ms.hovered_card = card_handle

				if rl.IsMouseButtonPressed(.LEFT) {
					if handle_array_contains(&ms.selected_cards, card_handle) {
						handle_array_remove_handle(&ms.selected_cards, card_handle)
					} else if ms.selected_cards.len < MAX_SELECTED {
						sds.array_push(&ms.selected_cards, card_handle)
					}
					ms.has_refreshed_selected_cards = true
				}
				break
			}
		}

		if ms.hovered_card != ms.previous_hovered_card && ms.hovered_card != {} {
			card := sds.pool_get_ptr_safe(&ms.deck, ms.hovered_card) or_break
			card.jiggle_timer = JIGGLE_DURATION
		}

		if ms.selected_cards.len > 0 && ms.has_refreshed_selected_cards {
			ms.has_refreshed_selected_cards = false
			selected_data := slice.mapper(
				sds.array_slice(&ms.selected_cards),
				proc(handle: CardHandle) -> CardInstance {
					ms := &gm.state.ms.(MS_Game)
					c := sds.pool_get(ms.deck, handle)
					return c
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

		if state.phase == .DealingToTable {
			last_card_handle := sds.array_get(ms.played_pile, ms.played_pile.len - 1)
			last_card_instance := sds.pool_get_ptr_safe(&ms.deck, last_card_handle) or_break
			target_layout, _ := get_card_table_target_layout(ms, i32(ms.played_pile.len - 1))
			target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

			if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
				state.phase = .ScoringHand
				state.animation_timer = 0.5
			}
		}

		if state.phase == .ScoringHand && state.animation_timer <= 0 {
			state.scoring_index += 1
			rank_chip := RankChip

			if state.scoring_index < ms.played_pile.len {
				card_handle := sds.array_get(ms.played_pile, state.scoring_index)
				contains := handle_array_contains(&ms.scoring_cards_handles, card_handle)
				log.info(state.scoring_index, &ms.scoring_cards_handles, card_handle)
				if contains {
					card_data := sds.pool_get(ms.deck, card_handle).data
					state.current_chips += i64(rank_chip[card_data.rank])
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

			draw_cards_into(&ms.played_pile, &ms.discard_pile, ms.played_pile.len)

			next_hand(ms)
		}
	}

	animation_speed: f32 = 10.0
	for i := i32(0); i < ms.hand_pile.len; i += 1 {
		handle := sds.array_get(ms.hand_pile, i)
		card_instance := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue

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

	for i := i32(0); i < ms.played_pile.len; i += 1 {
		handle := sds.array_get(ms.played_pile, i)
		card_instance := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue

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
