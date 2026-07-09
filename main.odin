package main


import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

WINDOW_WIDTH: int : 640
WINDOW_HEIGHT: int : 960
TILE_SIZE: int : 64

// ID_NONE: int : 0
// ID_WALL: int : 1
// ID_FLOOR: int : 2
// ID_CARGO: int : 3
// ID_GOAL: int : 5

show_stage :: proc(tilemap: rl.Texture2D) {
	layers := [][][]int {
		// floor
		{
			{0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 2, 0, 0, 0},
			{0, 0, 0, 2, 0, 0, 0},
			{0, 2, 2, 2, 2, 2, 0},
			{0, 0, 0, 2, 0, 0, 0},
			{0, 0, 0, 2, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0},
		},
		// wall
		{
			{0, 0, 1, 1, 1, 0, 0},
			{0, 0, 1, 0, 1, 0, 0},
			{1, 1, 1, 0, 1, 1, 1},
			{1, 0, 0, 0, 0, 0, 1},
			{1, 1, 1, 0, 1, 1, 1},
			{0, 0, 1, 0, 1, 0, 0},
			{0, 0, 1, 1, 1, 0, 0},
		},
		// cargo
		{
			{0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 3, 0, 0, 0},
			{0, 0, 3, 0, 3, 0, 0},
			{0, 0, 0, 3, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0},
		},
		// goal
		{
			{0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 5, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0},
			{0, 5, 0, 0, 0, 5, 0},
			{0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 5, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0},
		},
	}

	for layer in layers {
		for y, i in layer {
			for x, j in y {
				if (x != 0) {
					source_rec := rl.Rectangle {
						x      = f32(x * TILE_SIZE),
						y      = 0.0,
						width  = f32(TILE_SIZE),
						height = f32(TILE_SIZE),
					}
					offset_x := f32(WINDOW_WIDTH - (len(y) * TILE_SIZE)) / 2.0
					offset_y := f32(WINDOW_HEIGHT - (len(layer) * TILE_SIZE)) / 2.0 - 150.0
					pos := rl.Vector2{f32(j * TILE_SIZE) + offset_x, f32(i * TILE_SIZE) + offset_y}
					rl.DrawTextureRec(tilemap, source_rec, pos, rl.WHITE)
				}
			}
		}
	}
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Odin + Raylib Interactive Example")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	block_tilemap := rl.LoadTexture("assets/block.png")
	defer rl.UnloadTexture(block_tilemap)


	// Main game loop
	for !rl.WindowShouldClose() {
		// Delta time keeps movement smooth regardless of framerate
		dt := rl.GetFrameTime()
		// rl.DrawGrid(10, 50.0)
		// キー入力による移動
		// if rl.IsKeyDown(.LEFT) do player_pos.x -= player_speed * dt
		// if rl.IsKeyDown(.RIGHT) do player_pos.x += player_speed * dt
		// if rl.IsKeyDown(.UP) do player_pos.y -= player_speed * dt
		// if rl.IsKeyDown(.DOWN) do player_pos.y += player_speed * dt

		// Render pass
		rl.BeginDrawing()
		rl.ClearBackground({30, 30, 45, 255}) // Dark slate background

		show_stage(block_tilemap)
		// Draw instructions
		// rl.DrawText("Use ARROW KEYS to move", 20, 20, 20, rl.LIGHTGRAY)
		// rl.DrawTextureV(player_texture, player_pos - texture_center, rl.WHITE)

		rl.EndDrawing()
	}
}
