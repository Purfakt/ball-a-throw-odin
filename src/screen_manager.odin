package game

import c "core_game"
import rl "vendor:raylib"

Screen :: struct {
	data:          ScreenData,
	update:        proc(_: ^GameContext, _: Layout, dt: f32),
	draw:          proc(_: ^GameContext, _: Layout, dt: f32),
	delete:        proc(_: ^GameContext),
	in_transition: bool,
	transition:    Transition,
	uses_hud:      bool,
}

RunData :: struct {
	deck:              c.Deck,
	hands_per_blind:   i8,
	discard_per_blind: i8,
	current_ante:      c.Ante,
	current_blind:     c.Blind,
	money:             i32,
	tarot_cards:       c.ConsumablePile,
}

ScreenData :: union {
	^MainMenuData,
	^AnteData,
	^GamePlayData,
	^ShopData,
}

Transition :: struct {
	time_fade_out:    f32,
	time_fade_in:     f32,
	fade:             f32,
	fade_in_done:     bool,
	next_screen_proc: proc(_: ^GameContext) -> Screen,
}

update_transition :: proc(ctx: ^GameContext, dt: f32) {
	transition := &ctx.screen.transition
	if transition.time_fade_in < TRANSITION_TIME {
		transition.time_fade_in += dt
		transition.fade = transition.time_fade_in / TRANSITION_TIME
	} else if !transition.fade_in_done {
		transition.fade_in_done = true
		new_game_state := transition.next_screen_proc(ctx)
		new_game_state.in_transition = true
		new_game_state.transition = transition^
		ctx.screen = new_game_state
	} else if transition.time_fade_out < TRANSITION_TIME {
		transition.time_fade_out += dt
		transition.fade = 1 - (transition.time_fade_out / TRANSITION_TIME)
	} else {
		ctx.screen.in_transition = false
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


transition_to :: proc(ctx: ^GameContext, next_screen_proc: proc(_: ^GameContext) -> Screen) {
	transition := Transition {
		time_fade_in     = 0,
		time_fade_out    = 0,
		fade_in_done     = false,
		next_screen_proc = next_screen_proc,
	}
	ctx.screen.transition = transition
	ctx.screen.in_transition = true
}

transition_to_game_play :: proc(ctx: ^GameContext) {
	transition_to(ctx, proc(ctx: ^GameContext) -> Screen {
		return init_game_play_screen(ctx.run_data)
	})
}

transition_to_ante :: proc(ctx: ^GameContext) {
	transition_to(ctx, proc(ctx: ^GameContext) -> Screen {
		return init_ante_screen(ctx.run_data)
	})
}

transition_to_shop :: proc(ctx: ^GameContext) {
	transition_to(ctx, proc(ctx: ^GameContext) -> Screen {
		return init_shop_screen(ctx.run_data)
	})
}
