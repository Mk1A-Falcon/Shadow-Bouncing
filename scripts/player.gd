extends CharacterBody2D

signal died
signal health_changed(current: int, maximum: int)
signal landed_shock

const SPEED := 248.0
const ACCEL := 1900.0
const FRICTION := 2100.0
const AIR_ACCEL := 880.0
const JUMP_VELOCITY := -520.0
const JUMP_CUT := 0.42
const FALL_GRAVITY := 1.35
const COYOTE := 0.09
const JUMP_BUFFER := 0.12
const BOUNCE_SPEED := 340.0
const BOUNCE_UP := -160.0
const BOUNCE_TIME := 0.28
const MIN_LAND_SPEED := 70.0
const MAX_HEALTH := 5
const I_FRAMES := 0.8
const DASH_SPEED := 560.0
const DASH_TIME := 0.2
const DASH_COOLDOWN := 0.5

const SHOCK_SCENE := preload("res://scenes/landing_shock.tscn")
const SPRITE_DIR := "res://assets/ShadowTrooper/Sprites/"

var health := MAX_HEALTH
var facing := 1.0
var _airborne := false
var _air_facing := 1.0
var _peak_fall := 0.0
var _bounce_time := 0.0
var _hurt_time := 0.0
var _jump_armed := false
var _coyote := 0.0
var _jump_buf := 0.0
var _dead := false
var _anim := "idle"
var _dash_time := 0.0
var _dash_cd := 0.0
var _skip_land_sfx := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	_build_frames()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 24.0
	collision.shape = capsule
	collision.position = Vector2(0, 6)
	sprite.position = Vector2(0, 2)
	floor_snap_length = 6.0
	health_changed.emit(health, MAX_HEALTH)
	sprite.play("idle")


func _build_frames() -> void:
	var sheet := SpriteFrames.new()
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Idle.png", 8, "idle", 8.0, true)
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Run.png", 8, "run", 12.0, true)
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Charge.png", 6, "jump", 14.0, false)
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Charge.png", 6, "dash", 18.0, false)
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Attack.png", 5, "land", 16.0, false)
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Hurt.png", 2, "hurt", 10.0, false)
	SpriteStrip.add_strip(sheet, SPRITE_DIR + "ShadowTrooper-Death.png", 12, "death", 10.0, false)
	sprite.sprite_frames = sheet
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var match_scale := _scale_to_match_enemy()
	sprite.scale = Vector2(match_scale, match_scale)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		if not is_on_floor():
			velocity.y += _gravity() * FALL_GRAVITY * delta
		move_and_slide()
		return

	_hurt_time = maxf(_hurt_time - delta, 0.0)
	_bounce_time = maxf(_bounce_time - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_dash_time = maxf(_dash_time - delta, 0.0)
	sprite.modulate = Color.WHITE if int(_hurt_time * 16.0) % 2 == 0 or _hurt_time <= 0.0 else Color(1, 1, 1, 0.4)

	if is_on_floor():
		_coyote = COYOTE
	else:
		_coyote = maxf(_coyote - delta, 0.0)
		_airborne = true
		var grav := _gravity()
		if velocity.y > 0.0:
			grav *= FALL_GRAVITY
		velocity.y += grav * delta
		_peak_fall = maxf(_peak_fall, velocity.y)

	if Input.is_action_just_pressed("jump"):
		_jump_buf = JUMP_BUFFER
	else:
		_jump_buf = maxf(_jump_buf - delta, 0.0)

	if _dash_time <= 0.0 and _jump_buf > 0.0 and _coyote > 0.0 and _bounce_time <= 0.0:
		velocity.y = JUMP_VELOCITY
		_airborne = true
		_jump_armed = true
		_air_facing = facing
		_peak_fall = 0.0
		_coyote = 0.0
		_jump_buf = 0.0
		_play("jump")
		Sfx.play("plat_jump_heavy", -5.0)

	if not is_on_floor() and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	if Input.is_action_just_pressed("dash"):
		_try_dash()

	var axis := Input.get_axis("move_left", "move_right")
	if _dash_time > 0.0:
		velocity.x = facing * DASH_SPEED
	elif _bounce_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.45 * delta)
	elif axis != 0.0:
		facing = signf(axis)
		if is_on_floor():
			_air_facing = facing
		var accel := ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, axis * SPEED, accel * delta)
	else:
		var decel := FRICTION if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	sprite.flip_h = facing < 0.0

	move_and_slide()

	if _airborne and is_on_floor():
		_airborne = false
		if _jump_armed and _peak_fall >= MIN_LAND_SPEED:
			_bounce_back()
		else:
			if _skip_land_sfx:
				_skip_land_sfx = false
			else:
				Sfx.play("plat_land_soft", -9.0)
		_jump_armed = false
		_peak_fall = 0.0

	_update_anim()
	if global_position.y > 900.0:
		take_hit(MAX_HEALTH, global_position)


func _try_dash() -> void:
	if _dash_time > 0.0 or _dash_cd > 0.0 or _bounce_time > 0.0:
		return
	_dash_time = DASH_TIME
	_dash_cd = DASH_COOLDOWN
	_hurt_time = maxf(_hurt_time, 0.14)
	velocity.x = facing * DASH_SPEED
	velocity.y = minf(velocity.y, 40.0)
	_play("dash")
	Sfx.play("plat_dash_start", -9.0)
	_shake()


func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/2d/default_gravity"))


func _bounce_back() -> void:
	var shock := SHOCK_SCENE.instantiate()
	get_parent().add_child(shock)
	shock.global_position = global_position + Vector2(0, 18)
	if shock.has_method("setup"):
		shock.setup(self)
	velocity.x = -_air_facing * BOUNCE_SPEED
	velocity.y = BOUNCE_UP
	facing = -_air_facing
	_bounce_time = BOUNCE_TIME
	_hurt_time = maxf(_hurt_time, 0.18)
	_play("dash")
	Sfx.play("plat_land_heavy", -4.0)
	# The bounce pops us up off the floor; suppress the soft land on the
	# way back down so it doesn't stack with the heavy impact.
	_skip_land_sfx = true
	landed_shock.emit()
	_shake()


func _shake() -> void:
	var tween := create_tween()
	var origin := camera.offset
	tween.tween_property(camera, "offset", origin + Vector2(0, 4), 0.04)
	tween.tween_property(camera, "offset", origin, 0.1)


func _update_anim() -> void:
	if _anim in ["land", "hurt", "death", "dash"] and sprite.is_playing():
		return
	if not is_on_floor():
		_play("jump")
	elif absf(velocity.x) > 18.0:
		_play("run")
	else:
		_play("idle")


func _play(anim: String) -> void:
	if _anim == anim and sprite.is_playing():
		return
	_anim = anim
	sprite.play(anim)


func _scale_to_match_enemy() -> float:
	const ENEMY_SCALE := 1.85
	var enemy_tex := load("res://assets/Run Like Hell assets/enemies/gholum/gholum_idle_strip11.png") as Texture2D
	var player_tex := load(SPRITE_DIR + "ShadowTrooper-Idle.png") as Texture2D
	var enemy_h := _opaque_height(enemy_tex, 11)
	var player_h := _opaque_height(player_tex, 8)
	if player_h <= 1.0:
		return ENEMY_SCALE
	return ENEMY_SCALE * enemy_h / player_h


func _opaque_height(tex: Texture2D, frame_count: int) -> float:
	if tex == null or frame_count < 1:
		return 1.0
	var img := tex.get_image()
	if img == null:
		return float(tex.get_height())
	if img.is_compressed():
		img.decompress()
	var frame_w := img.get_width() / frame_count
	var h := img.get_height()
	var top := h
	var bottom := 0
	for y in h:
		var hit := false
		for x in frame_w:
			if img.get_pixel(x, y).a > 0.2:
				hit = true
				break
		if hit:
			top = mini(top, y)
			bottom = maxi(bottom, y)
	if bottom <= top:
		return float(h)
	return float(bottom - top + 1)


func heal(amount: int = 1) -> bool:
	if _dead or amount <= 0 or health >= MAX_HEALTH:
		return false
	health = mini(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	sprite.modulate = Color(0.85, 0.7, 1.2)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	return true


func take_hit(amount: int, from: Vector2) -> void:
	if _dead or _hurt_time > 0.0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	_hurt_time = I_FRAMES
	var dir := signf(global_position.x - from.x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(dir * 180.0, -120.0)
	_play("hurt")
	if health <= 0:
		_die()


func _die() -> void:
	_dead = true
	_play("death")
	collision.set_deferred("disabled", true)
	died.emit()
