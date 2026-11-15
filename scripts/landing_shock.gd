extends Node2D

const DAMAGE := 1
const LIFE := 0.28
const MAX_RADIUS := 78.0

var _age := 0.0
var _hit: Array[int] = []
var _source: Node = null

@onready var _area: Area2D = $Area2D
@onready var _shape: CircleShape2D = $Area2D/CollisionShape2D.shape


func setup(source: Node) -> void:
	_source = source


func _ready() -> void:
	_shape.radius = 24.0
	_area.body_entered.connect(_on_body_entered)
	# Catch bodies already overlapping this frame.
	await get_tree().physics_frame
	for body in _area.get_overlapping_bodies():
		_on_body_entered(body)


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / LIFE, 0.0, 1.0)
	_shape.radius = lerpf(24.0, MAX_RADIUS, t)
	queue_redraw()
	if _age >= LIFE:
		queue_free()


func _draw() -> void:
	var t := clampf(_age / LIFE, 0.0, 1.0)
	var radius := lerpf(18.0, MAX_RADIUS, t)
	var fade := 1.0 - t
	draw_circle(Vector2.ZERO, radius * 0.45, Color(0.45, 0.95, 1.0, 0.22 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.7, 1.0, 1.0, 0.95 * fade), 5.0, true)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.45 * fade), 2.0, true)


func _on_body_entered(body: Node) -> void:
	if body == _source:
		return
	if not body.has_method("take_hit"):
		return
	var id := body.get_instance_id()
	if id in _hit:
		return
	_hit.append(id)
	body.take_hit(DAMAGE, global_position)
	Sfx.play("plat_stomp", -9.0)
