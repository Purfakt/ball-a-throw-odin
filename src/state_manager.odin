package game

import c "core_game"
import rl "vendor:raylib"

MainState :: struct {
	ms:            MS,
	update:        proc(ctx: ^GameContext, dt: f32),
	draw:          proc(ctx: ^GameContext, dt: f32, ui: UiContext),
	delete:        proc(ctx: ^GameContext),
	in_transition: bool,
	transition:    Transition,
}

RunData :: struct {
	deck:              c.Deck,
	hands_per_blind:   i8,
	discard_per_blind: i8,
}

MS :: union {
	^MS_MainMenu,
	^MS_GamePlay,
}

Transition :: struct {
	time_fade_out:   f32,
	time_fade_in:    f32,
	fade:            f32,
	fade_in_done:    bool,
	next_state_proc: proc(data: rawptr) -> MainState,
	user_data:       rawptr,
}

update_transition :: proc(ctx: ^GameContext, dt: f32) {
	transition := &ctx.state.transition
	if transition.time_fade_in < TRANSITION_TIME {
		transition.time_fade_in += dt
		transition.fade = transition.time_fade_in / TRANSITION_TIME
	} else if !transition.fade_in_done {
		transition.fade_in_done = true
		new_game_state := transition.next_state_proc(transition.user_data)
		new_game_state.in_transition = true
		new_game_state.transition = transition^
		ctx.state = new_game_state
	} else if transition.time_fade_out < TRANSITION_TIME {
		transition.time_fade_out += dt
		transition.fade = 1 - (transition.time_fade_out / TRANSITION_TIME)
	} else {
		ctx.state.in_transition = false
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


transition_to :: proc(
	ctx: ^GameContext,
	next_state_proc: proc(_: rawptr) -> MainState,
	user_data: rawptr,
) {
	transition := Transition {
		time_fade_in    = 0,
		time_fade_out   = 0,
		fade_in_done    = false,
		next_state_proc = next_state_proc,
		user_data       = user_data,
	}
	ctx.state.transition = transition
	ctx.state.in_transition = true
}

init_game_from_context :: proc(data: rawptr) -> MainState {
	ctx := (^GameContext)(data)
	return init_MS_Game(ctx.run_data)
}

transition_to_game_play :: proc(ctx: ^GameContext) {
	transition_to(ctx, init_game_from_context, ctx)
}
