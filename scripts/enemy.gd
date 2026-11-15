extends CharacterBody2D

signal died

@export var kind := "gholum"
@export var patrol_range := 110.0
@export var max_health := 2
@export var move_speed := 70.0
@export var contact_damage := 1

var health := 2
var facing := -1.0
var _origin_x := 0.0
var _dead := false
var _hurt_time := 0.0
var _hit_cooldown := 0.0
var _anim := ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var touch: Area2D = $Touch
@onready var touch_shape: CollisionShape2D = $Touch/CollisionShape2D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_origin_x = global_position.x
	_build_frames()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 24.0
	collision.position = Vector2(0, 6)
	collision.shape = capsule
	var box := RectangleShape2D.new()
	box.size = Vector2(22, 28)
	touch_shape.shape = box
	touch_shape.position = collision.position
	touch.body_entered.connect(_on_touch_body)
	sprite.play("idle")
	_anim = "idle"


func _build_frames() -> void:
	var sheet := SpriteFrames.new()
	var root := "res://assets/Run Like Hell assets/enemies/"
	var scale := 1.85
	match kind:
		"gruby":
			SpriteStrip.add_strip(sheet, root + "gruby/gruby_idle_strip10.png", 10, "idle", 8.0, true)
			SpriteStrip.add_strip(sheet, root + "gruby/gruby_walk_strip14.png", 14, "move", 10.0, true)
			SpriteStrip.add_strip(sheet, root + "gruby/gruby_fall_n_standup_strip22.png", 22, "hurt", 20.0, false)
			SpriteStrip.add_strip(sheet, root + "gruby/gruby_death_strip17.png", 17, "death", 12.0, false)
			scale = 1.69
		"harpy":
			SpriteStrip.add_strip(sheet, root + "harpy/harpy_idle_ground_strip8.png", 8, "idle", 8.0, true)
			SpriteStrip.add_strip(sheet, root + "harpy/harpy_walk_strip13.png", 13, "move", 11.0, true)
			SpriteStrip.add_strip(sheet, root + "harpy/harpy_hit_strip13.png", 13, "hurt", 16.0, false)
			SpriteStrip.add_strip(sheet, root + "harpy/harpy_death_strip16.png", 16, "death", 12.0, false)
			scale = 1.49
		"voldo":
			SpriteStrip.add_still(sheet, root + "voldo/voldo_walk_strip18.png", 18, 0, "idle")
			SpriteStrip.add_strip(sheet, root + "voldo/voldo_run_strip18.png", 18, "move", 12.0, true)
			SpriteStrip.add_strip(sheet, root + "voldo/voldo_jump_strip20.png", 20, "hurt", 18.0, false)
			SpriteStrip.add_strip(sheet, root + "voldo/voldo_attack_strip14.png", 14, "death", 14.0, false)
			scale = 1.33
		_:
			SpriteStrip.add_strip(sheet, root + "gholum/gholum_idle_strip11.png", 11, "idle", 8.0, true)
			SpriteStrip.add_strip(sheet, root + "gholum/gholum_walk_strip13.png", 13, "move", 10.0, true)
			SpriteStrip.add_strip(sheet, root + "gholum/gholum_fall_strip11.png", 11, "hurt", 14.0, false)
			SpriteStrip.add_strip(sheet, root + "gholum/gholum_death_strip10.png", 10, "death", 11.0, false)
			scale = 1.85
	sprite.sprite_frames = sheet
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(scale, scale)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity.y += _gravity() * delta
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return

	_hurt_time = maxf(_hurt_time - delta, 0.0)
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	_walk(delta, player)

	sprite.flip_h = facing > 0.0
	move_and_slide()
	_update_anim()


func _walk(delta: float, player: Node2D) -> void:
	if not is_on_floor():
		velocity.y += _gravity() * delta
	if _hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		return
	if player and is_instance_valid(player) and absf(player.global_position.x - global_position.x) < 220.0 and absf(player.global_position.y - global_position.y) < 90.0:
		facing = signf(player.global_position.x - global_position.x)
		if facing == 0.0:
			facing = -1.0
		velocity.x = facing * move_speed * 1.35
	else:
		if absf(global_position.x - _origin_x) > patrol_range:
			facing = -signf(global_position.x - _origin_x)
		velocity.x = facing * move_speed


func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/2d/default_gravity"))


func _update_anim() -> void:
	if _anim in ["hurt", "death"] and sprite.is_playing():
		return
	if absf(velocity.x) > 12.0:
		_play("move")
	else:
		_play("idle")


func _play(anim: String) -> void:
	if _anim == anim and sprite.is_playing():
		return
	_anim = anim
	sprite.play(anim)


func take_hit(amount: int, from: Vector2) -> void:
	if _dead:
		return
	health -= amount
	_hurt_time = 0.22
	var dir := signf(global_position.x - from.x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(dir * 220.0, -140.0)
	_play("hurt")
	sprite.modulate = Color(1.4, 0.7, 0.7)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if health <= 0:
		_die()


func _die() -> void:
	_dead = true
	collision.set_deferred("disabled", true)
	touch.monitoring = false
	_play("death")
	died.emit()
	await sprite.animation_finished
	queue_free()


func _on_touch_body(body: Node) -> void:
	if _dead or _hit_cooldown > 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(contact_damage, global_position)
		_hit_cooldown = 0.7
