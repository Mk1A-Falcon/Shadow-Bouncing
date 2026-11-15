extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const HEART_SCENE := preload("res://scenes/heart_pickup.tscn")
const MENU := "res://scenes/main_menu.tscn"
const MUSIC := "res://assets/Eclipzodiac -  RPG Maker Mix V1_375/OGG Looped/3- Ancient prisoner.ogg"
const CAVE := "res://assets/Run Like Hell assets/enviro/World 1/elements/background_seamless.png"
const FLOOR := "res://assets/Run Like Hell assets/enviro/World 1/props/rocks_floor.png"
const SIGN := "res://assets/Run Like Hell assets/enviro/World 1/props/sign_keep_out.png"
const WARN := "res://assets/Run Like Hell assets/enviro/World 1/props/sign_warning.png"
const LANTERN := "res://assets/Run Like Hell assets/enviro/World 1/cave walls and elements/lantern.png"
const BONES := "res://assets/Run Like Hell assets/enviro/World 1/props/bones_0.png"
const BONES_B := "res://assets/Run Like Hell assets/enviro/World 1/props/bones_3.png"
const BARREL := "res://assets/Run Like Hell assets/enviro/World 1/props/barrel0.png"

const LEVEL_W := 4800.0
const FLOOR_Y := 620.0
const GROUND_HEART_Y := FLOOR_Y - 36.0

var _player: CharacterBody2D
var _enemies_left := 0
var _ended := false
var _hud_hp: Label
var _hud_en: Label
var _overlay: Control
var _overlay_title: Label
var _overlay_body: Label


func _ready() -> void:
	_build_world()
	_spawn_player()
	_spawn_enemies()
	_spawn_hearts()
	_build_hud()
	_play_music()


func toggle_pause() -> void:
	if _ended:
		return
	_show_overlay("PAUSED", "Esc to resume  ·  click MENU to leave", true)


func _build_world() -> void:
	var bg := Sprite2D.new()
	bg.texture = load(CAVE)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.region_enabled = true
	bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	bg.region_rect = Rect2(0, 0, LEVEL_W, 720)
	bg.modulate = Color(0.55, 0.62, 0.78)
	bg.z_index = -20
	add_child(bg)

	var mist := ColorRect.new()
	mist.color = Color(0.05, 0.07, 0.14, 0.25)
	mist.size = Vector2(LEVEL_W, 720)
	mist.z_index = -19
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mist)

	_static_box(Vector2(LEVEL_W * 0.5, FLOOR_Y + 40), Vector2(LEVEL_W, 80))
	_tile_floor(0.0, LEVEL_W, FLOOR_Y)

	_static_box(Vector2(-20, 360), Vector2(40, 800))
	_static_box(Vector2(LEVEL_W + 20, 360), Vector2(40, 800))

	_deco(SIGN, Vector2(250, FLOOR_Y - 48), 2.4)
	_deco(WARN, Vector2(1680, FLOOR_Y - 46), 2.2)
	_deco(SIGN, Vector2(3320, FLOOR_Y - 48), 2.4)
	_deco(WARN, Vector2(4560, FLOOR_Y - 46), 2.2)

	for x in [620.0, 1240.0, 1960.0, 2680.0, 3400.0, 4120.0]:
		_deco(LANTERN, Vector2(x, 300.0), 2.6)

	_deco(BONES, Vector2(900, FLOOR_Y - 22), 1.6)
	_deco(BONES_B, Vector2(2140, FLOOR_Y - 20), 1.6)
	_deco(BONES, Vector2(2980, FLOOR_Y - 22), 1.5)
	_deco(BONES_B, Vector2(3900, FLOOR_Y - 20), 1.6)
	_deco(BARREL, Vector2(1505, FLOOR_Y - 36), 2.0)
	_deco(BARREL, Vector2(1548, FLOOR_Y - 36), 2.0)
	_deco(BARREL, Vector2(3720, FLOOR_Y - 36), 2.0)


func _tile_floor(start_x: float, width: float, y: float) -> void:
	var tex := load(FLOOR) as Texture2D
	if tex == null:
		return
	var tw := tex.get_width() * 0.7
	var step := tw * 0.78
	var x := start_x
	# Cover the whole span, including a final overlapping tile so the ground
	# reaches the right wall with no background gap.
	while x < start_x + width + step:
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(x + tw * 0.5, y + 18)
		s.scale = Vector2(0.7, 0.7)
		s.z_index = -2
		add_child(s)
		x += step


func _static_box(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	add_child(body)


func _deco(path: String, pos: Vector2, scale: float) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	s.scale = Vector2(scale, scale)
	s.z_index = -1
	add_child(s)


func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2(160, FLOOR_Y - 80)
	add_child(_player)
	_player.health_changed.connect(_on_health)
	_player.died.connect(_on_player_died)
	var cam := _player.get_node("Camera2D") as Camera2D
	cam.enabled = true
	cam.make_current()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(LEVEL_W)
	cam.limit_bottom = 720
	cam.zoom = Vector2(1.55, 1.55)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0


func _spawn_enemies() -> void:
	var spots: Array[Dictionary] = [
		{"kind": "gholum", "x": 720.0, "hp": 2, "speed": 64.0},
		{"kind": "gruby", "x": 1180.0, "hp": 3, "speed": 48.0},
		{"kind": "harpy", "x": 1640.0, "hp": 2, "speed": 78.0},
		{"kind": "voldo", "x": 2140.0, "hp": 3, "speed": 70.0},
		{"kind": "gholum", "x": 2620.0, "hp": 2, "speed": 64.0},
		{"kind": "gruby", "x": 3100.0, "hp": 3, "speed": 46.0},
		{"kind": "harpy", "x": 3560.0, "hp": 2, "speed": 80.0},
		{"kind": "voldo", "x": 4040.0, "hp": 3, "speed": 72.0},
		{"kind": "gholum", "x": 4480.0, "hp": 2, "speed": 66.0},
	]
	_enemies_left = spots.size()
	for spot in spots:
		var enemy: Node = ENEMY_SCENE.instantiate()
		enemy.kind = spot["kind"]
		enemy.position = Vector2(float(spot["x"]), FLOOR_Y - 48.0)
		enemy.max_health = int(spot["hp"])
		enemy.move_speed = float(spot["speed"])
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)


func _spawn_hearts() -> void:
	var xs: Array[float] = [460.0, 960.0, 1420.0, 1900.0, 2380.0, 2860.0, 3340.0, 3820.0, 4280.0]
	for x in xs:
		var heart: Node = HEART_SCENE.instantiate()
		heart.position = Vector2(x, GROUND_HEART_Y)
		add_child(heart)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	var bar := HBoxContainer.new()
	bar.position = Vector2(24, 18)
	bar.add_theme_constant_override("separation", 24)
	canvas.add_child(bar)

	_hud_hp = Label.new()
	_hud_hp.add_theme_font_size_override("font_size", 22)
	_hud_hp.add_theme_color_override("font_color", Color(0.95, 0.85, 0.7))
	_hud_hp.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	bar.add_child(_hud_hp)

	_hud_en = Label.new()
	_hud_en.add_theme_font_size_override("font_size", 22)
	_hud_en.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	_hud_en.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	bar.add_child(_hud_en)

	var hint := Label.new()
	hint.text = "Land to slam  ·  Shift / J to dash  ·  you bounce back"
	hint.position = Vector2(24, 48)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.8, 0.88, 0.95, 0.85))
	canvas.add_child(hint)

	_overlay = Control.new()
	_overlay.visible = false
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.07, 0.72)
	_overlay.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -220
	box.offset_top = -120
	box.offset_right = 220
	box.offset_bottom = 140
	box.add_theme_constant_override("separation", 14)
	_overlay.add_child(box)

	_overlay_title = Label.new()
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_title.add_theme_font_size_override("font_size", 42)
	_overlay_title.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0))
	box.add_child(_overlay_title)

	_overlay_body = Label.new()
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body.add_theme_font_size_override("font_size", 18)
	_overlay_body.add_theme_color_override("font_color", Color(0.8, 0.86, 0.94))
	box.add_child(_overlay_body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(140, 40)
	retry.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	row.add_child(retry)

	var menu := Button.new()
	menu.text = "MENU"
	menu.custom_minimum_size = Vector2(140, 40)
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU)
	)
	row.add_child(menu)

	_on_health(5, 5)
	_refresh_enemy_hud()


func _play_music() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load(MUSIC)
	player.autoplay = true
	add_child(player)
	if player.stream is AudioStreamOggVorbis:
		(player.stream as AudioStreamOggVorbis).loop = true
	player.play()


func _on_health(current: int, maximum: int) -> void:
	_hud_hp.text = "HP  %d / %d" % [current, maximum]


func _on_enemy_died() -> void:
	_enemies_left = maxi(_enemies_left - 1, 0)
	_refresh_enemy_hud()
	if _enemies_left <= 0 and not _ended:
		_ended = true
		await get_tree().create_timer(0.6).timeout
		_show_overlay("CLEARED", "You bounced back through all of them.", false)


func _refresh_enemy_hud() -> void:
	_hud_en.text = "ENEMIES  %d" % _enemies_left


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	await get_tree().create_timer(0.8).timeout
	_show_overlay("DOWN", "The landing is the weapon. Try again.", false)


func _show_overlay(title: String, body: String, togglable: bool) -> void:
	if togglable and _overlay.visible:
		_overlay.visible = false
		get_tree().paused = false
		return
	_overlay_title.text = title
	_overlay_body.text = body
	_overlay.visible = true
	if togglable:
		get_tree().paused = true
	else:
		get_tree().paused = false
