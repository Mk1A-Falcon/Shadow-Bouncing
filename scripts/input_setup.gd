extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_bind("dash", [KEY_SHIFT, KEY_J])
	_bind("pause", [KEY_ESCAPE])


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("toggle_pause"):
		scene.toggle_pause()


func _bind(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key as Key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
