package game

import "core:fmt"
import "core:log"
import "core:math/linalg"
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

MS_Game :: struct {
	gs:                    GameSate,
	deck:                  Deck,
	draw_pile:             Pile,
	hand:                  Pile,
	selected_cards:        Pile,
	hovered_card:          CardHandle,
	previous_hovered_card: CardHandle,
}

GameSate :: union {
	GS_DrawingCards,
	GS_Playing,
}

GS_DrawingCards :: struct {
	deal_timer: f32,
	deal_index: i32,
}

GS_Playing :: struct {}

CardLayout :: struct {
	target_rect:     rl.Rectangle,
	target_rotation: f32,
	color:           rl.Color,
	font_size:       i32,
}

next_hand :: proc(ms: ^MS_Game) {
	empty_pile(&ms.hand)
	empty_pile(&ms.selected_cards)
	draw_cards_into(&ms.draw_pile, &ms.hand, 8)

	for i := i32(0); i < ms.hand.len; i += 1 {
		handle := sds.array_get(ms.hand, i)
		card := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue
		card.position = DECK_POSITION
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
		ms = MS_Game{deck = deck, draw_pile = draw_pile, gs = GS_DrawingCards{}},
		draw = draw_MS_Game,
		update = update_MS_Game,
	}

	next_hand(&state.ms.(MS_Game))

	return state
}

get_card_target_layout :: proc(ms: ^MS_Game, i: i32) -> (layout: CardLayout, handle: CardHandle) {
	handle = sds.array_get(ms.hand, i)

	is_selected := pile_contains(&ms.selected_cards, handle)


	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	hand_size := ms.hand.len
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

draw_MS_Game :: proc(dt: f32) {
	ms := gm.state.ms.(MS_Game)

	rl.ClearBackground(rl.BLACK)
	rank_string := RankString
	suite_color := SuiteColor

	for i := i32(0); i < ms.hand.len; i += 1 {
		_, card_handle := get_card_target_layout(&ms, i)
		card_instance := sds.pool_get_ptr_safe(&ms.deck, card_handle) or_continue

		scaled_w := f32(CARD_WIDTH)
		scaled_h := f32(CARD_HEIGHT)
		font_size := f32(CARD_FONT_SIZE)

		card_dest_rect := rl.Rectangle {
			x      = card_instance.position.x + scaled_w / 2,
			y      = card_instance.position.y + scaled_h / 2,
			width  = scaled_w,
			height = scaled_h,
		}

		card_origin := rl.Vector2{scaled_w / 2, scaled_h / 2}

		rl.DrawRectanglePro(card_dest_rect, card_origin, card_instance.rotation, rl.LIGHTGRAY)


		if font_size <= 1 {continue}

		card_center := rl.Vector2 {
			card_instance.position.x + scaled_w / 2,
			card_instance.position.y + scaled_h / 2,
		}

		rank_text := fmt.ctprintf("%v", rank_string[card_instance.data.rank])
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
			rl.Color(suite_color[card_instance.data.suite]),
		)
	}
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
			if state.deal_index < ms.hand.len {
				state.deal_index += 1
			}
		}

		if ms.hand.len > 0 && state.deal_index >= ms.hand.len {
			last_card_handle := sds.array_get(ms.hand, ms.hand.len - 1)
			last_card_instance := sds.pool_get_ptr_safe(&ms.deck, last_card_handle) or_break

			target_layout, _ := get_card_target_layout(ms, i32(ms.hand.len - 1))
			target_pos := rl.Vector2{target_layout.target_rect.x, target_layout.target_rect.y}

			if rl.Vector2Distance(last_card_instance.position, target_pos) < 1.0 {
				ms.gs = GS_Playing{}
			}
		}
	case GS_Playing:
		ms.hovered_card = {}

		for i := ms.hand.len - 1; i >= 0; i -= 1 {
			target_layout, card_handle := get_card_target_layout(ms, i)

			if rl.CheckCollisionPointRec(mouse_pos, target_layout.target_rect) {
				ms.hovered_card = card_handle

				if rl.IsMouseButtonPressed(.LEFT) {
					if pile_contains(&ms.selected_cards, card_handle) {
						pile_remove_handle(&ms.selected_cards, card_handle)
					} else if ms.selected_cards.len < MAX_SELECTED {
						sds.array_push(&ms.selected_cards, card_handle)
					}
				}
				break
			}
		}

		if ms.hovered_card != ms.previous_hovered_card && ms.hovered_card != {} {
			card := sds.pool_get_ptr_safe(&ms.deck, ms.hovered_card) or_break
			card.jiggle_timer = JIGGLE_DURATION
		}

		if rl.IsKeyPressed(.R) {
			next_hand(ms)
			return
		}
		break
	}

	animation_speed: f32 = 10.0
	for i := i32(0); i < ms.hand.len; i += 1 {
		handle := sds.array_get(ms.hand, i)
		card_instance := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue

		target_layout, _ := get_card_target_layout(ms, i)
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
}
