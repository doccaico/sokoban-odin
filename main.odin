package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

show_stage :: proc(tilemap: rl.Texture2D, level: int, skip_cargo_x: int, skip_cargo_y: int) {
	for layer, i in STAGES[level] {
		for row, j in layer {
			for val, k in row {
				// 現在プレイヤーが押している最中の荷物は、ここでの描画をスキップする
				if i == LAYER_CARGO_ID && k == skip_cargo_x && j == skip_cargo_y do continue

				if val != 0 {
					tile_id := val
					// 同じマスの「ゴール（レイヤー3）」に 5 が入っているかチェックする
					if i == LAYER_CARGO_ID && val == TILE_CARGO_ID {
						if STAGES[level][LAYER_GOAL_ID][j][k] == TILE_GOAL_ID {
							tile_id = TILE_DARK_CARGO_ID // 暗い色の荷物のタイルID（画像に合わせて適宜変更してください）
						}
					}

					source_rec := rl.Rectangle {
						x      = f32(tile_id * TILE_SIZE),
						y      = 0.0,
						width  = f32(TILE_SIZE),
						height = f32(TILE_SIZE),
					}
					offset_x, offset_y := get_stage_offset(level)
					pos := rl.Vector2{f32(k * TILE_SIZE) + offset_x, f32(j * TILE_SIZE) + offset_y}
					rl.DrawTextureRec(tilemap, source_rec, pos, rl.WHITE)
				}
			}
		}
	}
}

main :: proc() {
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Sokoban")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	block_tilemap := rl.LoadTexture("assets/block.png")
	defer rl.UnloadTexture(block_tilemap)

	player_tilemap := rl.LoadTexture("assets/player.png")
	defer rl.UnloadTexture(player_tilemap)

	// 現在のステージ
	current_level := 0

	// プレイヤーの初期グリッド位置（3マス目、3マス目）
	start_grid := PLAYER_START_GRID[current_level]
	p_grid_x := int(start_grid.x)
	p_grid_y := int(start_grid.y)

	// ピクセル座標に変換し、マップのオフセットを足す（これでステージのマスと完璧に重なります）
	offset_x, offset_y := get_stage_offset(current_level)
	player_pos := rl.Vector2 {
		f32(p_grid_x * TILE_SIZE) + offset_x,
		f32(p_grid_y * TILE_SIZE) + offset_y,
	}

	is_moving := false
	move_dir := rl.Vector2{0, 0}
	moved_pixels := 0

	current_frame := 0
	anim_timer := 0

	// プレイヤーの向き
	player_dir_row := PLAYER_DOWN

	// ★ 荷物移動の管理用変数
	is_pushing := false // 現在荷物を押しているか
	cargo_grid_x := -1 // 押している荷物の元のXグリッド
	cargo_grid_y := -1 // 押している荷物の元のYグリッド
	cargo_render_pos := rl.Vector2{0, 0} // 荷物の動的な描画座標

	for !rl.WindowShouldClose() {
		if !is_moving {
			if rl.IsKeyDown(.LEFT) {
				move_dir = {-1, 0}
				player_dir_row = PLAYER_LEFT
			} else if rl.IsKeyDown(.RIGHT) {
				move_dir = {1, 0}
				player_dir_row = PLAYER_RIGHT
			} else if rl.IsKeyDown(.UP) {
				move_dir = {0, -1}
				player_dir_row = PLAYER_UP
			} else if rl.IsKeyDown(.DOWN) {
				move_dir = {0, 1}
				player_dir_row = PLAYER_DOWN
			}

			if move_dir != {0, 0} {
				next_x := p_grid_x + int(move_dir.x)
				next_y := p_grid_y + int(move_dir.y)

				// レイヤー1（壁）のデータが 1（壁ID）でないかチェック
				// ★ 条件分岐の整理：壁 -> 荷物 -> 床 の順番にきれいに流します
				if STAGES[current_level][LAYER_WALL_ID][next_y][next_x] == TILE_WALL_ID {
					// 進行先に壁がある場合
					move_dir = {0, 0}
				} else if STAGES[current_level][LAYER_CARGO_ID][next_y][next_x] == TILE_CARGO_ID {
					// 進行先に荷物（ID: 3）がある場合
					cargo_next_x := next_x + int(move_dir.x)
					cargo_next_y := next_y + int(move_dir.y)

					// 荷物の先が「壁」でも「別の荷物」でもない場合のみ押せる
					if STAGES[current_level][LAYER_WALL_ID][cargo_next_y][cargo_next_x] !=
						   TILE_WALL_ID &&
					   STAGES[current_level][LAYER_CARGO_ID][cargo_next_y][cargo_next_x] !=
						   TILE_CARGO_ID &&
					   STAGES[current_level][LAYER_CARGO_ID][cargo_next_y][cargo_next_x] !=
						   TILE_DARK_CARGO_ID {
						is_moving = true
						is_pushing = true
						cargo_grid_x = next_x
						cargo_grid_y = next_y

						offset_x, offset_y := get_stage_offset(current_level)
						cargo_render_pos = rl.Vector2 {
							f32(cargo_grid_x * TILE_SIZE) + offset_x,
							f32(cargo_grid_y * TILE_SIZE) + offset_y,
						}
						moved_pixels = 0
					} else {
						// 荷物の先が詰まっていて押せない
						move_dir = {0, 0}
					}
				} else {
					// 進行先が何もない空間（床）の場合
					is_moving = true
					is_pushing = false
					moved_pixels = 0
				}

				if !is_moving do current_frame = 0

			} else {
				current_frame = 0
			}
		}

		// 2. 移動中の処理（毎フレーム4ピクセルずつ完全に等速移動）
		if is_moving {
			player_pos += move_dir * 4

			// プレイヤーと一緒に荷物も4pxずつ滑らかに移動させる
			if is_pushing {
				cargo_render_pos += move_dir * 4
			}

			moved_pixels += 4

			anim_timer += 1
			if anim_timer >= 4 {
				anim_timer = 0
				current_frame = (current_frame + 1) % 3
			}

			// ちょうど64px移動しきったら自動停止し、グリッド座標の内部データを更新
			if moved_pixels >= TILE_SIZE {
				// 荷物を押していた場合、移動完了した瞬間にマップデータを書き換える
				if is_pushing {
					next_cargo_x := cargo_grid_x + int(move_dir.x)
					next_cargo_y := cargo_grid_y + int(move_dir.y)

					STAGES[current_level][LAYER_CARGO_ID][cargo_grid_y][cargo_grid_x] =
						TILE_NONE_ID // 元の位置を空に
					STAGES[current_level][LAYER_CARGO_ID][next_cargo_y][next_cargo_x] =
						TILE_CARGO_ID // 新しい位置に荷物を配置
				}

				p_grid_x += int(move_dir.x)
				p_grid_y += int(move_dir.y)
				is_moving = false
				is_pushing = false // 荷物移動フラグをリセット
				move_dir = {0, 0}
			}
		}

		// Render pass
		rl.BeginDrawing()
		rl.ClearBackground({30, 30, 45, 255})

		// 3. ステージを描画してから、その上にプレイヤーを描画する
		show_stage(
			block_tilemap,
			current_level,
			is_pushing ? cargo_grid_x : -1,
			is_pushing ? cargo_grid_y : -1,
		)

		// 4. 移動中の荷物があれば、アニメーション中の座標で個別に描画
		if is_pushing {
			cargo_src := rl.Rectangle {
				f32(TILE_CARGO_ID * TILE_SIZE),
				0,
				f32(TILE_SIZE),
				f32(TILE_SIZE),
			}
			rl.DrawTextureRec(block_tilemap, cargo_src, cargo_render_pos, rl.WHITE)
		}

		// 5. スプライトシートから切り出すY座標を「player_dir_row * TILE_SIZE」で計算
		source_rec := rl.Rectangle {
			x      = f32(current_frame * TILE_SIZE),
			y      = f32(player_dir_row * TILE_SIZE), // 向きに合わせた行を切り出す
			width  = f32(TILE_SIZE),
			height = f32(TILE_SIZE),
		}
		rl.DrawTextureRec(player_tilemap, source_rec, player_pos, rl.WHITE)

		rl.EndDrawing()
	}
}
