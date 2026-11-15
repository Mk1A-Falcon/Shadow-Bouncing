extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const HEART_SCENE := preload("res://scenes/heart_pickup.tscn")
const MENU := "res://scenes/main_menu.tscn"
const MUSIC := "res://assets/Eclipzodiac -  RPG Maker Mix V1_375/OGG Looped/13- Full Strength Unleashed.ogg"
const CAVE := "res://assets/Run Like Hell assets/enviro/World 1/elements/background_seamless.png"
const FLOOR := "res://assets/Run Like Hell assets/enviro/World 1/props/rocks_floor.png"
const SIGN := "res://assets/Run Like Hell assets/enviro/World 1/props/sign_keep_out.png"
const LANTERN := "res://assets/Run Like Hell assets/enviro/World 1/cave walls and elements/lantern.png"
const BONES := "res://assets/Run Like Hell assets/enviro/World 1/props/bones_0.png"
const WOOD := "res://assets/Run Like Hell assets/enviro/World 1/elements/platform.png"

const LEVEL_W := 3200.0
const FLOOR_Y := 620.0

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

	_platform(420, 470, 280)
	_platform(820, 380, 240)
	_platform(1280, 470, 260)
	_platform(1760, 360, 300)
	_platform(2280, 470, 280)
	_platform(2740, 390, 260)

	_static_box(Vector2(-20, 360), Vector2(40, 800))
	_static_box(Vector2(LEVEL_W + 20, 360), Vector2(40, 800))

	_deco(SIGN, Vector2(300, FLOOR_Y - 70), 1.4)
	_deco(LANTERN, Vector2(980, FLOOR_Y - 90), 1.6)
	_deco(BONES, Vector2(1500, FLOOR_Y - 28), 1.3)
	_deco(LANTERN, Vector2(2100, FLOOR_Y - 90), 1.6)
	_deco(BONES, Vector2(2550, FLOOR_Y - 28), 1.3)


func _tile_floor(start_x: float, width: float, y: float) -> void:
	var tex := load(FLOOR) as Texture2D
	if tex == null:
		return
	var tw := tex.get_width() * 0.7
	var x := start_x
	while x < start_x + width:
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(x + tw * 0.5, y + 18)
		s.scale = Vector2(0.7, 0.7)
		s.z_index = -2
		add_child(s)
		x += tw * 0.78


func _platform(x: float, y: float, w: float) -> void:
	_static_box(Vector2(x, y), Vector2(w, 28))
	var tex := load(WOOD) as Texture2D
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = Vector2(x, y)
	s.scale = Vector2(w / maxf(tex.get_width(), 1.0), 0.55)
	s.z_index = -1
	s.modulate = Color(0.75, 0.8, 0.9)
	add_child(s)


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
	var spots := [
		Vector2(520, FLOOR_Y - 80),
		Vector2(820, FLOOR_Y - 80),
		Vector2(1280, FLOOR_Y - 80),
		Vector2(1600, FLOOR_Y - 80),
		Vector2(1760, FLOOR_Y - 80),
		Vector2(2280, FLOOR_Y - 80),
		Vector2(2500, FLOOR_Y - 80),
		Vector2(2900, FLOOR_Y - 80),
	]
	_enemies_left = spots.size()
	for pos in spots:
		var enemy: Node = ENEMY_SCENE.instantiate()
		enemy.position = pos
		enemy.max_health = 2
		enemy.move_speed = 64
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)


func _spawn_hearts() -> void:
	var spots := [
		Vector2(420, 430),
		Vector2(820, 340),
		Vector2(1100, FLOOR_Y - 42),
		Vector2(1760, 320),
		Vector2(2100, FLOOR_Y - 42),
		Vector2(2740, 350),
	]
	for pos in spots:
		var heart: Node = HEART_SCENE.instantiate()
		heart.position = pos
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
