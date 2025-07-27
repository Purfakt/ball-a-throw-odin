package game

import "core:fmt"
import "core:log"
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

MS_Game :: struct {
	gs:             GameSate,
	deck:           Deck,
	draw_pile:      Pile,
	hand:           Pile,
	// UI
	selected_cards: Pile,
	hovered_card:   CardHandle,
}

GameSate :: union {
	GS_DrawingCards,
	GS_Playing,
}

GS_DrawingCards :: struct {}
GS_Playing :: struct {}

CardLayout :: struct {
	final_rect: rl.Rectangle,
	color:      rl.Color,
	font_size:  i32,
}

init_MS_Game :: proc() -> MainState {
	log.info("init_MS_Game")
	deck := init_deck()
	draw_pile := init_drawing_pile(&deck)

	return MainState {
		ms = MS_Game{deck = deck, draw_pile = draw_pile, gs = GS_DrawingCards{}},
		draw = draw_MS_Game,
		update = update_MS_Game,
	}
}

get_card_layout :: proc(ms: ^MS_Game, i: i32) -> (layout: CardLayout, handle: CardHandle) {
	handle = sds.array_get(ms.hand, i)

	is_selected := pile_contains(&ms.selected_cards, handle)
	is_hovered := ms.hovered_card == handle

	scale: f32 = 1.0
	if is_selected || is_hovered {
		scale = 1.3
	}

	scaled_w := f32(CardWidth) * scale
	scaled_h := f32(CardHeight) * scale

	w := i32(rl.GetScreenWidth())
	h := i32(rl.GetScreenHeight())
	center_w := w / 2
	hand_size := ms.hand.len
	hand_w := (CardWidth * hand_size) + (CardMargin * (hand_size - 1))
	start_x := center_w - (hand_w / 2)

	base_x := start_x + i * (CardWidth + CardMargin)
	base_y := h - CardMargin - CardHeight

	final_x := f32(base_x) - (scaled_w - f32(CardWidth)) / 2
	final_y := f32(base_y) - (scaled_h - f32(CardHeight))

	layout.final_rect = {final_x, final_y, scaled_w, scaled_h}
	layout.font_size = i32(scale * f32(CardRankFontSize))
	layout.color = rl.LIGHTGRAY
	if is_hovered {
		layout.color = rl.WHITE
	}

	return
}

draw_MS_Game :: proc(dt: f32) {
	ms := gm.state.ms.(MS_Game)
	gs := ms.gs

	rl.ClearBackground(rl.BLACK)
	rank_string := RankString
	suite_color := SuiteColor

	switch state in gs {
	case GS_DrawingCards:
		break
	case GS_Playing:
		for i := i32(0); i < ms.hand.len; i += 1 {
			layout, handle := get_card_layout(&ms, i)
			card := sds.pool_get_ptr_safe(&ms.deck, handle) or_continue

			rl.DrawRectangleRec(layout.final_rect, layout.color)

			rank_text := fmt.ctprintf("%v", rank_string[card.data.rank])
			rank_text_width := rl.MeasureText(rank_text, layout.font_size)

			rl.DrawText(
				rank_text,
				i32(layout.final_rect.x + layout.final_rect.width / 2) - rank_text_width / 2,
				i32(layout.final_rect.y + layout.final_rect.height / 2) - layout.font_size / 2,
				layout.font_size,
				rl.Color(suite_color[card.data.suite]),
			)
		}
	}
}

update_MS_Game :: proc(dt: f32) {
	if gm.state.in_transition {
		return
	}
	ms := &gm.state.ms.(MS_Game)
	gs := &ms.gs

	mouse_pos := rl.GetMousePosition()

	switch state in gs {
	case GS_DrawingCards:
		empty_pile(&ms.hand)
		empty_pile(&ms.selected_cards)
		ms.hovered_card = {}

		draw_cards_into(&ms.draw_pile, &ms.hand, 8)
		ms.gs = GS_Playing{}
		break
	case GS_Playing:
		if rl.IsKeyPressed(.R) {
			ms.gs = GS_DrawingCards{}
			return
		}

		ms.hovered_card = {}

		for i := ms.hand.len - 1; i >= 0; i -= 1 {
			layout, card_handle := get_card_layout(ms, i)

			if rl.CheckCollisionPointRec(mouse_pos, layout.final_rect) {
				ms.hovered_card = card_handle

				if rl.IsMouseButtonPressed(.LEFT) {
					if pile_contains(&ms.selected_cards, card_handle) {
						pile_remove_handle(&ms.selected_cards, card_handle)
					} else {
						sds.array_push(&ms.selected_cards, card_handle)
					}
				}
				break
			}
		}
		break
	}
}
