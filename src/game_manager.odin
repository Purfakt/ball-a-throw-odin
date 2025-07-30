package game

import "core:log"
import c "core_game"
import rl "vendor:raylib"

GameContext :: struct {
	state:          MainState,
	run_data:       ^RunData,
	input_commands: [dynamic]Input_Command,
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	zoom := f32(2)

	return {zoom = zoom, target = {0, 0}, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

update :: proc(ctx: ^GameContext, dt: f32, ui: UiContext) {
	if ctx.state.in_transition {
		update_transition(ctx, dt)
		return
	}
	handle_input(ctx, ui)
	ctx.state.update(ctx, dt)
}


draw :: proc(ctx: ^GameContext, dt: f32, ui: UiContext) {
	rl.BeginDrawing()

	ctx.state.draw(ctx, dt, ui)
	if ctx.state.in_transition {draw_transition(ctx.state.transition.fade)}
	rl.EndDrawing()
}

@(export)
game_update :: proc(ctx: ^GameContext) {
	dt := rl.GetFrameTime()
	ui := UiContext{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()), rl.GetMousePosition()}

	update(ctx, dt, ui)
	draw(ctx, dt, ui)
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "Ball-A-Throw")
	rl.SetWindowPosition(600, 200)
	rl.SetTargetFPS(60)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() -> ^GameContext {
	rl.InitAudioDevice()
	rl.SetAudioStreamBufferSizeDefault(4096)

	gm := new(GameContext)

	run_data := new(RunData)

	run_data.deck = c.init_deck()
	run_data.discard_per_blind = 3
	run_data.hands_per_blind = 3

	gm^ = GameContext {
		run_data = run_data,
		state    = init_MS_Menu(),
		// state    = init_MS_Game(run_data),
	}
	log.info("game_init")
	game_hot_reloaded(gm)
	return gm
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return true
}

@(export)
game_shutdown :: proc(ctx: ^GameContext) {
	rl.CloseAudioDevice()
	if ctx.state.delete != nil {
		ctx.state.delete(ctx)
	}
	delete(ctx.input_commands)
	free(ctx)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc(ctx: ^GameContext) -> rawptr {
	return ctx
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(GameContext)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside
	// `gm`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
