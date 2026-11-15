extends Area2D

const HEART := preload("res://assets/hp-bars/heart-purple-16x16.png")

var _taken := false
var _base_y := 0.0
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("pickups")
	_base_y = position.y
	_setup_sprite()
	body_entered.connect(_on_body_entered)


func _setup_sprite() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = HEART
	atlas.filter_clip = true
	atlas.region = Rect2(0, 0, 16, 16)
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2.75, 2.75)


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.2) * 5.0


func _on_body_entered(body: Node) -> void:
	if _taken:
		return
	if body.is_in_group("player") and body.has_method("heal"):
		if body.heal(1):
			_taken = true
			queue_free()
