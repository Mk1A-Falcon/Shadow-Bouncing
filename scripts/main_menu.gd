extends Control

const ARENA := "res://scenes/arena.tscn"
const MENU_MUSIC := "res://assets/Eclipzodiac -  RPG Maker Mix V1_375/OGG Looped/1- Brave reaction.ogg"
const BG := "res://assets/GandalfHardcore FREE Platformer Assets/GandalfHardcore Background layers/Normal BG/"
const SKY := BG + "GandalfHardcore Background layers_layer 5.png"
const HILLS := BG + "GandalfHardcore Background layers_layer 4.png"
const TREES_FAR := BG + "GandalfHardcore Background layers_layer 3.png"
const TREES_MID := BG + "GandalfHardcore Background layers_layer 2.png"
const TREES_NEAR := BG + "GandalfHardcore Background layers_layer 1.png"
const CASTLE := BG + "Background Castle .png"
const BTN := "res://assets/labeled/"

var _how_to: Panel


func _ready() -> void:
	_build_ui()
	_play_music()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	add_child(_full_layer(SKY, Color.WHITE, TextureRect.STRETCH_SCALE))
	add_child(_full_layer(HILLS, Color(0.78, 0.86, 1.0), TextureRect.STRETCH_SCALE))
	add_child(_castle())
	add_child(_full_layer(TREES_FAR, Color(0.62, 0.7, 0.88), TextureRect.STRETCH_SCALE))
	add_child(_full_layer(TREES_MID, Color(0.5, 0.58, 0.78), TextureRect.STRETCH_SCALE))
	add_child(_full_layer(TREES_NEAR, Color(0.42, 0.5, 0.68), TextureRect.STRETCH_SCALE))

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.04, 0.1, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var title_col := VBoxContainer.new()
	title_col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_col.offset_left = -420
	title_col.offset_right = 420
	title_col.offset_top = 36
	title_col.offset_bottom = 200
	title_col.add_theme_constant_override("separation", 16)
	add_child(title_col)

	var title := Label.new()
	title.text = "SHADOW HORSING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color(0.78, 0.97, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.1, 0.35, 0.7, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 8)
	title_col.add_child(title)

	var btn_col := VBoxContainer.new()
	btn_col.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn_col.offset_left = -280
	btn_col.offset_right = 280
	btn_col.offset_top = -430
	btn_col.offset_bottom = -40
	btn_col.add_theme_constant_override("separation", 32)
	btn_col.alignment = BoxContainer.ALIGNMENT_END
	add_child(btn_col)

	btn_col.add_child(_tex_button("button_play", _on_play))
	btn_col.add_child(_tex_button("button_options", _on_how_to))
	btn_col.add_child(_tex_button("button_quit", _on_quit))

	_how_to = Panel.new()
	_how_to.visible = false
	_how_to.set_anchors_preset(Control.PRESET_CENTER)
	_how_to.offset_left = -380
	_how_to.offset_top = -250
	_how_to.offset_right = 380
	_how_to.offset_bottom = 250
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.94)
	sb.border_color = Color(1, 1, 1, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	_how_to.add_theme_stylebox_override("panel", sb)
	add_child(_how_to)

	var how_col := VBoxContainer.new()
	how_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	how_col.add_theme_constant_override("separation", 18)
	_how_to.add_child(how_col)

	var how_title := Label.new()
	how_title.text = "HOW TO BOUNCE BACK"
	how_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_title.add_theme_font_size_override("font_size", 32)
	how_title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	how_col.add_child(how_title)

	var body := Label.new()
	body.text = "A / D or arrows  —  walk\nSpace / W / Up  —  jump\nShift / J  —  dash\n\nLanding is your attack.\nHit the ground to slam a shockwave that\ndamages anything in the landing zone,\nthen dash backwards.\n\nClear every enemy. Don't get swarmed.\nEsc pauses in-game."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	body.add_theme_color_override("font_color", Color(0.86, 0.9, 0.96))
	how_col.add_child(body)

	var close := Button.new()
	close.text = "GOT IT"
	close.custom_minimum_size = Vector2(320, 58)
	close.add_theme_font_size_override("font_size", 24)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0, 0, 0, 0.92)
	n.border_color = Color.WHITE
	n.set_border_width_all(2)
	n.set_corner_radius_all(6)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color.WHITE
	close.add_theme_stylebox_override("normal", n)
	close.add_theme_stylebox_override("hover", h)
	close.add_theme_stylebox_override("pressed", h)
	close.add_theme_color_override("font_color", Color.WHITE)
	close.add_theme_color_override("font_hover_color", Color.BLACK)
	close.add_theme_color_override("font_pressed_color", Color.BLACK)
	close.pressed.connect(_hide_how_to)
	how_col.add_child(close)


func _full_layer(path: String, tint: Color, stretch: TextureRect.StretchMode) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = load(path)
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.stretch_mode = stretch
	layer.modulate = tint
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return layer


func _castle() -> TextureRect:
	var tex := load(CASTLE) as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	if tex:
		atlas.region = Rect2(0, 0, tex.get_width() * 0.42, tex.get_height() * 0.62)
	var castle := TextureRect.new()
	castle.texture = atlas
	castle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	castle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	castle.offset_left = -200
	castle.offset_right = 200
	castle.offset_top = 28
	castle.offset_bottom = 300
	castle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	castle.modulate = Color(0.82, 0.88, 1.0)
	castle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return castle


func _tex_button(stem: String, cb: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(BTN + stem + "_normal.png")
	button.texture_hover = load(BTN + stem + "_hover.png")
	button.texture_pressed = load(BTN + stem + "_pressed.png")
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(520, 100)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(cb)
	return button


func _play_music() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load(MENU_MUSIC)
	player.autoplay = true
	player.bus = "Master"
	add_child(player)
	if player.stream is AudioStreamOggVorbis:
		(player.stream as AudioStreamOggVorbis).loop = true
	player.play()


func _on_play() -> void:
	get_tree().change_scene_to_file(ARENA)


func _on_how_to() -> void:
	_how_to.visible = true


func _hide_how_to() -> void:
	_how_to.visible = false


func _on_quit() -> void:
	get_tree().quit()
