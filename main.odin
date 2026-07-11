package game

import "core:fmt"
import "core:mem"
import "core:slice"
import rl "vendor:raylib"

WINDOW_TITLE :: "Simple Sokoban"
WINDOW_WIDTH: int : 640
WINDOW_HEIGHT: int : 960

PLAYER_DOWN :: 0
PLAYER_LEFT :: 1
PLAYER_UP :: 2
PLAYER_RIGHT :: 3

TILE_SIZE: int : 64
MENU_COLS: int : 5
BTN_SIZE: int : 96

Game :: struct {
	// 現在のステージ
	current_stage:    [][][]int,
	// 現在のレベル
	current_level:    int,
	// 現在の状態(State)
	current_state:    Game_State,
	// 選択中のステージ(Title画面)
	selected_stage:   int,
	// プレイヤーの初期グリッド位置(例: 3マス目、3マス目)
	player_grid_x:    int,
	player_grid_y:    int,
	// プレイヤーのポジション(px)
	player_pos:       rl.Vector2,
	// 動いている最中かどうか
	is_moving:        bool,
	// 動く方向
	move_dir:         rl.Vector2,
	// 動いたピクセル
	moved_pixels:     int,
	// プレイヤーの向き
	player_dir_row:   int,

	// 荷物移動の管理用変数
	// 現在荷物を押しているか
	is_pushing:       bool,
	// 押している荷物の元のグリッド
	cargo_grid_x:     int,
	cargo_grid_y:     int,
	// 荷物の動的な描画座標
	cargo_render_pos: rl.Vector2,

	// 現在のフレームとアニメーションのタイマー
	current_frame:    int,
	anim_timer:       int,
	btn_up_bounds:    rl.Rectangle,
	btn_down_bounds:  rl.Rectangle,
	btn_left_bounds:  rl.Rectangle,
	btn_right_bounds: rl.Rectangle,
	btn_enter_bounds: rl.Rectangle,
	btn_retry_bounds: rl.Rectangle,

	// リソース
	block_tilemap:    rl.Texture2D,
	player_tilemap:   rl.Texture2D,
	up_texture:       rl.Texture2D,
	down_texture:     rl.Texture2D,
	left_texture:     rl.Texture2D,
	right_texture:    rl.Texture2D,
	enter_texture:    rl.Texture2D,
}


Game_State :: enum {
	Stage_Select,
	Gameplay,
	Clear,
}

Button :: enum {
	Up,
	Down,
	Left,
	Right,
	Enter,
	Retry,
}

game_init :: proc() -> Game {
	TWEAK_Y: f32 : 50
	btn_up_bounds := rl.Rectangle {
		x      = f32((WINDOW_WIDTH - BTN_SIZE * 3) / 2 + BTN_SIZE),
		y      = f32(WINDOW_HEIGHT - BTN_SIZE * 3) - TWEAK_Y,
		width  = f32(BTN_SIZE),
		height = f32(BTN_SIZE),
	}
	btn_down_bounds := rl.Rectangle {
		x      = f32((WINDOW_WIDTH - BTN_SIZE * 3) / 2 + BTN_SIZE),
		y      = f32(WINDOW_HEIGHT - BTN_SIZE * 1) - TWEAK_Y,
		width  = f32(BTN_SIZE),
		height = f32(BTN_SIZE),
	}
	btn_left_bounds := rl.Rectangle {
		x      = f32((WINDOW_WIDTH - BTN_SIZE * 3) / 2),
		y      = f32(WINDOW_HEIGHT - BTN_SIZE * 2) - TWEAK_Y,
		width  = f32(BTN_SIZE),
		height = f32(BTN_SIZE),
	}
	btn_right_bounds := rl.Rectangle {
		x      = f32((WINDOW_WIDTH - BTN_SIZE * 3) / 2 + BTN_SIZE * 2),
		y      = f32(WINDOW_HEIGHT - BTN_SIZE * 2) - TWEAK_Y,
		width  = f32(BTN_SIZE),
		height = f32(BTN_SIZE),
	}
	btn_enter_bounds := rl.Rectangle {
		x      = f32((WINDOW_WIDTH - BTN_SIZE * 1) / 2),
		y      = f32(WINDOW_HEIGHT - BTN_SIZE * 2) - TWEAK_Y,
		width  = f32(BTN_SIZE),
		height = f32(BTN_SIZE),
	}
	btn_retry_bounds := rl.Rectangle {
		x      = f32(WINDOW_WIDTH - 100),
		y      = f32(WINDOW_HEIGHT - 200),
		width  = f32(100),
		height = f32(25),
	}

	game := Game {
		current_level    = 0,
		current_state    = .Stage_Select,
		selected_stage   = 0,
		is_moving        = false,
		move_dir         = rl.Vector2{0, 0},
		moved_pixels     = 0,
		player_dir_row   = PLAYER_DOWN,
		is_pushing       = false,
		cargo_grid_x     = -1,
		cargo_grid_y     = -1,
		cargo_render_pos = rl.Vector2{0, 0},
		current_frame    = 0,
		anim_timer       = 0,
		btn_up_bounds    = btn_up_bounds,
		btn_down_bounds  = btn_down_bounds,
		btn_left_bounds  = btn_left_bounds,
		btn_right_bounds = btn_right_bounds,
		btn_enter_bounds = btn_enter_bounds,
		btn_retry_bounds = btn_retry_bounds,
		block_tilemap    = rl.LoadTexture("assets/block.png"),
		player_tilemap   = rl.LoadTexture("assets/player.png"),
		up_texture       = rl.LoadTexture("assets/button/up.png"),
		down_texture     = rl.LoadTexture("assets/button/down.png"),
		left_texture     = rl.LoadTexture("assets/button/left.png"),
		right_texture    = rl.LoadTexture("assets/button/right.png"),
		enter_texture    = rl.LoadTexture("assets/button/enter.png"),
	}

	start_grid := PLAYER_START_GRID[game.current_level]
	game.player_grid_x = int(start_grid.x)
	game.player_grid_y = int(start_grid.y)

	// ピクセル座標に変換し、マップのオフセットを足す(これでステージのマスと完璧に重なる)
	offset_x, offset_y := get_stage_offset(game.current_level)
	game.player_pos = rl.Vector2 {
		f32(game.player_grid_x * TILE_SIZE) + offset_x,
		f32(game.player_grid_y * TILE_SIZE) + offset_y,
	}

	return game
}

game_deinit :: proc(game: Game) {
	delete_3d_slice(game.current_stage)
	rl.UnloadTexture(game.block_tilemap)
	rl.UnloadTexture(game.player_tilemap)
	rl.UnloadTexture(game.up_texture)
	rl.UnloadTexture(game.down_texture)
	rl.UnloadTexture(game.left_texture)
	rl.UnloadTexture(game.right_texture)
	rl.UnloadTexture(game.enter_texture)
}

clone_3d_slice :: proc(src: [][][]int) -> [][][]int {
	// 最外層（1次元目）の配列を確保
	dst := make([][][]int, len(src))

	for x in 0 ..< len(src) {
		// 2次元目の配列を確保
		dst[x] = make([][]int, len(src[x]))

		for y in 0 ..< len(src[x]) {
			// 最内層（3次元目）をクローン
			dst[x][y] = slice.clone(src[x][y])
		}
	}
	return dst
}

delete_3d_slice :: proc(src: [][][]int) {
	for x in src {
		for y in x {
			delete(y)
		}
		delete(x)
	}
	delete(src)
}


prepare_stage :: proc(game: ^Game) {
	start_grid := PLAYER_START_GRID[game.current_level]
	game.player_grid_x = int(start_grid.x)
	game.player_grid_y = int(start_grid.y)

	offset_x, offset_y := get_stage_offset(game.current_level)
	game.player_pos = rl.Vector2 {
		f32(game.player_grid_x * TILE_SIZE) + offset_x,
		f32(game.player_grid_y * TILE_SIZE) + offset_y,
	}

	game.player_dir_row = PLAYER_DOWN
	game.move_dir = {0, 0}

	if game.current_stage != nil {
		delete_3d_slice(game.current_stage)
	}
	game.current_stage = clone_3d_slice(STAGES[game.current_level])
}

// すべてのゴールの上に荷物があるかチェックする
check_stage_clear :: proc(game: ^Game) -> bool {
	for i := 0; i < int(STAGE_SIZES[game.current_level].y); i += 1 {
		for j := 0; j < int(STAGE_SIZES[game.current_level].x); j += 1 {
			if game.current_stage[LAYER_GOAL_ID][i][j] == TILE_GOAL_ID {
				if game.current_stage[LAYER_CARGO_ID][i][j] != TILE_CARGO_ID {
					return false
				}
			}
		}
	}
	return true
}

show_stage :: proc(game: Game, skip_cargo_x: int, skip_cargo_y: int) {
	for layer, i in game.current_stage {
		for row, j in layer {
			for val, k in row {
				// 現在プレイヤーが押している最中の荷物は、ここでの描画をスキップする
				if i == LAYER_CARGO_ID && k == skip_cargo_x && j == skip_cargo_y do continue

				if val != TILE_NONE_ID {
					tile_id := val
					if i == LAYER_CARGO_ID && tile_id == TILE_CARGO_ID {
						if game.current_stage[LAYER_GOAL_ID][j][k] == TILE_GOAL_ID {
							// 暗い色の荷物のタイル
							tile_id = TILE_DARK_CARGO_ID
						}
					}

					source_rec := rl.Rectangle {
						x      = f32(tile_id * TILE_SIZE),
						y      = 0.0,
						width  = f32(TILE_SIZE),
						height = f32(TILE_SIZE),
					}
					offset_x, offset_y := get_stage_offset(game.current_level)
					pos := rl.Vector2{f32(k * TILE_SIZE) + offset_x, f32(j * TILE_SIZE) + offset_y}
					rl.DrawTextureRec(game.block_tilemap, source_rec, pos, rl.WHITE)
				}
			}
		}
	}
}

update_stage_select :: proc(game: ^Game) {

	// 総行数を計算(5ステージで2列なら 3行 になる)
	total_rows := (MAX_LEVELS + MENU_COLS - 1) / MENU_COLS

	// --- 右移動 ---
	if rl.IsKeyPressed(.RIGHT) || is_btn_pressed(game, .Right) {
		// 現在の行(0行目、1行目...)を特定
		current_row := game.selected_stage / MENU_COLS

		// 同一行内での次のインデックス
		next_in_row := game.selected_stage + 1

		// 次のインデックスが「次の行」に行く、または「最大ステージ数」を超える場合
		if (next_in_row / MENU_COLS != current_row) || (next_in_row >= MAX_LEVELS) {
			// 同じ行の左端(先頭)に戻す
			game.selected_stage = current_row * MENU_COLS
		} else {
			game.selected_stage = next_in_row
		}
	}

	// --- 左移動 ---
	if rl.IsKeyPressed(.LEFT) || is_btn_pressed(game, .Left) {
		current_row := game.selected_stage / MENU_COLS

		// 現在すでにその行の左端(先頭)にいる場合
		if game.selected_stage == current_row * MENU_COLS {
			// 同じ行の右端にループさせる
			right_end_in_row := (current_row * MENU_COLS) + (MENU_COLS - 1)

			// もし右端のステージデータが存在しない場合
			// (奇数総数で05を選択中の06など)は、存在する最後のステージにする
			if right_end_in_row >= MAX_LEVELS {
				game.selected_stage = MAX_LEVELS - 1
			} else {
				game.selected_stage = right_end_in_row
			}
		} else {
			game.selected_stage -= 1
		}
	}

	// --- 下移動 ---
	if rl.IsKeyPressed(.DOWN) || is_btn_pressed(game, .Down) {
		current_col := game.selected_stage % MENU_COLS
		next_in_col := game.selected_stage + MENU_COLS

		// 下に進むと最大数を超える、または完全に画面外に行く場合
		if next_in_col >= MAX_LEVELS {
			// 同じ列の最上段(0行目)に戻す
			game.selected_stage = current_col
		} else {
			game.selected_stage = next_in_col
		}
	}

	// --- 上移動 ---
	if rl.IsKeyPressed(.UP) || is_btn_pressed(game, .Up) {
		current_col := game.selected_stage % MENU_COLS

		// すでに最上段(0行目)にいる場合
		if game.selected_stage - MENU_COLS < 0 {
			// 同じ列の「最下段の行」を計算
			target_idx := current_col + ((total_rows - 1) * MENU_COLS)

			// 計算した最下段の要素が、最大ステージ数を超えて存在しない場合
			if target_idx >= MAX_LEVELS {
				// ひとつ上の行の同じ列に落とし込む
				game.selected_stage = target_idx - MENU_COLS
			} else {
				game.selected_stage = target_idx
			}
		} else {
			game.selected_stage -= MENU_COLS
		}
	}

	// --- 決定処理 ---
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) || is_btn_pressed(game, .Enter) {
		game.current_state = .Gameplay
		game.current_level = game.selected_stage
		prepare_stage(game)
	}

}

update_gameplay :: proc(game: ^Game) {
	if !game.is_moving {
		if rl.IsKeyDown(.LEFT) || is_btn_down(game, .Left) {
			game.move_dir = {-1, 0}
			game.player_dir_row = PLAYER_LEFT
		} else if rl.IsKeyDown(.RIGHT) || is_btn_down(game, .Right) {
			game.move_dir = {1, 0}
			game.player_dir_row = PLAYER_RIGHT
		} else if rl.IsKeyDown(.UP) || is_btn_down(game, .Up) {
			game.move_dir = {0, -1}
			game.player_dir_row = PLAYER_UP
		} else if rl.IsKeyDown(.DOWN) || is_btn_down(game, .Down) {
			game.move_dir = {0, 1}
			game.player_dir_row = PLAYER_DOWN
		} else if rl.IsKeyDown(.R) || is_btn_pressed(game, .Retry) {
			prepare_stage(game)
		}

		if game.move_dir != {0, 0} {
			next_x := game.player_grid_x + int(game.move_dir.x)
			next_y := game.player_grid_y + int(game.move_dir.y)

			if game.current_stage[LAYER_WALL_ID][next_y][next_x] == TILE_WALL_ID {
				// 進行先に壁がある場合
				game.move_dir = {0, 0}
			} else if game.current_stage[LAYER_CARGO_ID][next_y][next_x] == TILE_CARGO_ID {
				// 進行先に荷物がある場合
				cargo_next_x := next_x + int(game.move_dir.x)
				cargo_next_y := next_y + int(game.move_dir.y)

				// 荷物の先が「壁」でも「別の荷物」でもない場合のみ押せる
				if game.current_stage[LAYER_WALL_ID][cargo_next_y][cargo_next_x] != TILE_WALL_ID &&
				   game.current_stage[LAYER_CARGO_ID][cargo_next_y][cargo_next_x] !=
					   TILE_CARGO_ID {
					game.is_moving = true
					game.is_pushing = true
					game.cargo_grid_x = next_x
					game.cargo_grid_y = next_y

					offset_x, offset_y := get_stage_offset(game.current_level)
					game.cargo_render_pos = rl.Vector2 {
						f32(game.cargo_grid_x * TILE_SIZE) + offset_x,
						f32(game.cargo_grid_y * TILE_SIZE) + offset_y,
					}
					game.moved_pixels = 0
				} else {
					// 荷物の先が詰まっていて押せない
					game.move_dir = {0, 0}
				}
			} else {
				// 進行先が何もない空間(床)の場合
				game.is_moving = true
				game.is_pushing = false
				game.moved_pixels = 0
			}

			if !game.is_moving do game.current_frame = 0

		} else {
			game.current_frame = 0
		}
	}

	// 2. 移動中の処理(毎フレーム4ピクセルずつ完全に等速移動)
	if game.is_moving {
		game.player_pos += game.move_dir * 4

		// プレイヤーと一緒に荷物も4pxずつ滑らかに移動させる
		if game.is_pushing {
			game.cargo_render_pos += game.move_dir * 4
		}

		game.moved_pixels += 4

		game.anim_timer += 1
		if game.anim_timer >= 4 {
			game.anim_timer = 0
			game.current_frame = (game.current_frame + 1) % 3
		}

		// ちょうどTILE_SIZE分移動しきったら自動停止し、グリッド座標の内部データを更新
		if game.moved_pixels >= TILE_SIZE {
			// 荷物を押していた場合、移動完了した瞬間にマップデータを書き換える
			if game.is_pushing {
				next_cargo_x := game.cargo_grid_x + int(game.move_dir.x)
				next_cargo_y := game.cargo_grid_y + int(game.move_dir.y)
				// 元の位置を空に
				game.current_stage[LAYER_CARGO_ID][game.cargo_grid_y][game.cargo_grid_x] =
					TILE_NONE_ID
				// 新しい位置に荷物を配置
				game.current_stage[LAYER_CARGO_ID][next_cargo_y][next_cargo_x] = TILE_CARGO_ID

				// 荷物が動いたのでクリアチェックを行う
				if check_stage_clear(game) {
					fmt.printf("STAGE (LEVEL %d) CLEARED!\n", game.current_level)
					// 次のステージがあるか確認
					if game.current_level + 1 < MAX_LEVELS {
						game.current_level += 1
						prepare_stage(game)
					} else {
						// 全ステージクリア時の処理(フラグを立ててお祝い画面を出すなど)
						fmt.println("ALL STAGES CLEARED!")
					}
				}

			}

			game.player_grid_x += int(game.move_dir.x)
			game.player_grid_y += int(game.move_dir.y)
			game.is_moving = false
			game.is_pushing = false
			game.move_dir = {0, 0}
		}
	}
}

draw_stage_select :: proc(game: Game) {
	total_menu := 0
	x_pos := 150
	y_pos := 200

	item_width :: 70
	item_height :: 45
	spacing_x :: 40
	spacing_y :: 30

	// 2列分の総幅
	total_width := (MENU_COLS * item_width) + ((MENU_COLS - 1) * spacing_x)
	menu_start_x := (WINDOW_WIDTH - total_width) / 2
	menu_start_y := 250 // 任意の開始縦位置

	MENU_FONT_SIZE: i32 : 25

	for i := 0; i < MAX_LEVELS; i += 1 {
		// インデックスから「何列目」「何行目」かを算出する
		col := i % MENU_COLS
		row := i / MENU_COLS

		// グリッド座標の計算
		x_pos := i32(menu_start_x + (col * (item_width + spacing_x)))
		y_pos := i32(menu_start_y + (row * (item_height + spacing_y)))

		// あとはこの x_pos, y_pos を使って枠線や文字を描画するだけ
		is_selected := (i == game.selected_stage)
		color := is_selected ? rl.LIME : rl.DARKGRAY

		// 選択中の赤い枠線(画像のようなデザイン)
		if is_selected {
			rl.DrawRectangleLinesEx(
				rl.Rectangle{f32(x_pos), f32(y_pos), item_width, item_height},
				2,
				color,
			)
		}

		stage_str := fmt.ctprintf("%02d", i + 1)
		stage_width := rl.MeasureText(stage_str, MENU_FONT_SIZE)
		stage_x := (item_width - stage_width) / 2
		rl.DrawText(stage_str, i32(x_pos) + stage_x, i32(y_pos) + 12, MENU_FONT_SIZE, color)
	}

	// TITLE
	TITLE_TEXT :: "SIMPLE SOKOBAN"
	TITLE_FONT_SIZE: i32 : 30
	title_width := rl.MeasureText(fmt.ctprintf("%s", TITLE_TEXT), TITLE_FONT_SIZE)
	title_x := (i32(WINDOW_WIDTH) - title_width) / 2
	title_y := i32(100)
	rl.DrawText(cstring(TITLE_TEXT), title_x, title_y, TITLE_FONT_SIZE, rl.GRAY)

	// INFO
	INFO_TEXT :: "PRESS ENTER (SPACE) TO START"
	INFO_FONT_SIZE: i32 : 20
	info_width := rl.MeasureText(fmt.ctprintf("%s", INFO_TEXT), INFO_FONT_SIZE)
	info_x := (i32(WINDOW_WIDTH) - info_width) / 2
	info_y := i32(WINDOW_HEIGHT - 35)
	rl.DrawText(cstring(INFO_TEXT), info_x, info_y, INFO_FONT_SIZE, rl.GRAY)

	draw_ui(game)
}

draw_gameplay :: proc(game: Game) {
	// ステージを描画してから、その上にプレイヤーを描画する
	show_stage(
		game,
		game.is_pushing ? game.cargo_grid_x : -1,
		game.is_pushing ? game.cargo_grid_y : -1,
	)

	// 移動中の荷物があれば、アニメーション中の座標で個別に描画
	if game.is_pushing {
		cargo_src := rl.Rectangle {
			f32(TILE_CARGO_ID * TILE_SIZE),
			0,
			f32(TILE_SIZE),
			f32(TILE_SIZE),
		}
		rl.DrawTextureRec(game.block_tilemap, cargo_src, game.cargo_render_pos, rl.WHITE)
	}

	// スプライトシートから切り出すY座標を「player_dir_row * TILE_SIZE」で計算
	source_rec := rl.Rectangle {
		x      = f32(game.current_frame * TILE_SIZE),
		y      = f32(game.player_dir_row * TILE_SIZE), // 向きに合わせた行を切り出す
		width  = f32(TILE_SIZE),
		height = f32(TILE_SIZE),
	}
	rl.DrawTextureRec(game.player_tilemap, source_rec, game.player_pos, rl.WHITE)

	draw_ui(game)
}

draw_ui :: proc(game: Game) {
	// UP
	rl.DrawTextureRec(
		game.up_texture,
		rl.Rectangle{0, 0, f32(BTN_SIZE), f32(BTN_SIZE)},
		rl.Vector2{game.btn_up_bounds.x, game.btn_up_bounds.y},
		rl.WHITE,
	)
	// DOWN
	rl.DrawTextureRec(
		game.down_texture,
		rl.Rectangle{0, 0, f32(BTN_SIZE), f32(BTN_SIZE)},
		rl.Vector2{game.btn_down_bounds.x, game.btn_down_bounds.y},
		rl.WHITE,
	)
	// LEFT
	rl.DrawTextureRec(
		game.left_texture,
		rl.Rectangle{0, 0, f32(BTN_SIZE), f32(BTN_SIZE)},
		rl.Vector2{game.btn_left_bounds.x, game.btn_left_bounds.y},
		rl.WHITE,
	)
	// RIGHT
	rl.DrawTextureRec(
		game.right_texture,
		rl.Rectangle{0, 0, f32(BTN_SIZE), f32(BTN_SIZE)},
		rl.Vector2{game.btn_right_bounds.x, game.btn_right_bounds.y},
		rl.WHITE,
	)
	// ENTER
	rl.DrawTextureRec(
		game.enter_texture,
		rl.Rectangle{0, 0, f32(BTN_SIZE), f32(BTN_SIZE)},
		rl.Vector2{game.btn_enter_bounds.x, game.btn_enter_bounds.y},
		rl.WHITE,
	)

	// TODO
	if game.current_state == .Gameplay {

		rl.DrawRectangleLinesEx(game.btn_retry_bounds, 2, rl.WHITE)
	}
}

is_btn_pressed :: proc(game: ^Game, btn: Button) -> bool {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		bounds: rl.Rectangle
		switch btn {
		case .Up:
			bounds = game.btn_up_bounds
		case .Down:
			bounds = game.btn_down_bounds
		case .Left:
			bounds = game.btn_left_bounds
		case .Right:
			bounds = game.btn_right_bounds
		case .Enter:
			bounds = game.btn_enter_bounds
		case .Retry:
			bounds = game.btn_retry_bounds
		}
		mouse_pos := rl.GetMousePosition()
		if rl.CheckCollisionPointRec(mouse_pos, bounds) {
			return true
		}
	}
	return false
}

is_btn_down :: proc(game: ^Game, btn: Button) -> bool {
	if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
		bounds: rl.Rectangle
		switch btn {
		case .Up:
			bounds = game.btn_up_bounds
		case .Down:
			bounds = game.btn_down_bounds
		case .Left:
			bounds = game.btn_left_bounds
		case .Right:
			bounds = game.btn_right_bounds
		case .Enter:
			bounds = game.btn_enter_bounds
		case .Retry:
			bounds = game.btn_retry_bounds
		}
		mouse_pos := rl.GetMousePosition()
		if rl.CheckCollisionPointRec(mouse_pos, bounds) {
			return true
		}
	}
	return false
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

	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), WINDOW_TITLE)
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	game := game_init()
	defer game_deinit(game)

	for !rl.WindowShouldClose() {
		if game.current_state == .Stage_Select {
			update_stage_select(&game)
		} else if game.current_state == .Gameplay {
			update_gameplay(&game)
		}

		rl.BeginDrawing()
		rl.ClearBackground({30, 30, 45, 255})

		if game.current_state == .Stage_Select {
			draw_stage_select(game)
		} else if game.current_state == .Gameplay {
			draw_gameplay(game)
		}

		rl.EndDrawing()
	}
}
