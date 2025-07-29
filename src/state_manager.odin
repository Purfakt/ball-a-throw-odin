package game

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
