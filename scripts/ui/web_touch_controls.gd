extends CanvasLayer
## Browser touch layout: analog movement stick + clearly named attack buttons.

const ATTACK_BUTTONS := [
	{"label": "LIGHT\nPUNCH", "action": "p1_lp"},
	{"label": "HEAVY\nPUNCH", "action": "p1_hp"},
	{"label": "LIGHT\nKICK", "action": "p1_lk"},
	{"label": "HEAVY\nKICK", "action": "p1_hk"},
]
const MOVE_ACTIONS := ["p1_left", "p1_right", "p1_up", "p1_down"]

var _overlay: Control
var _held_actions: Array[String] = []


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	layer = 100
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed(get_tree().current_scene)


func _on_scene_changed(scene: Node) -> void:
	if not OS.has_feature("web"):
		return
	_release_all()
	if is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
	if scene == null or scene.scene_file_path != "res://scenes/fight.tscn":
		return

	_overlay = Control.new()
	_overlay.name = "MobileFightControls"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay)

	_add_joystick()
	_add_attack_button("LIGHT\nPUNCH", "p1_lp", -256, -132)
	_add_attack_button("HEAVY\nPUNCH", "p1_hp", -128, -132)
	_add_attack_button("LIGHT\nKICK", "p1_lk", -256, -68)
	_add_attack_button("HEAVY\nKICK", "p1_hk", -128, -68)
	_add_action_button("SIDESTEP", "p1_sidestep", -256, -194, 120, 48)
	_add_action_button("PAUSE", "pause", -128, -194, 120, 48)


func _add_joystick() -> void:
	var stick := Panel.new()
	stick.name = "MovementJoystick"
	stick.custom_minimum_size = Vector2(164, 164)
	stick.mouse_filter = Control.MOUSE_FILTER_STOP
	stick.anchor_left = 0.0
	stick.anchor_right = 0.0
	stick.anchor_top = 1.0
	stick.anchor_bottom = 1.0
	stick.offset_left = 20
	stick.offset_top = -184
	stick.offset_right = 184
	stick.offset_bottom = -20
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.035, 0.045, 0.075, 0.58)
	base_style.border_color = Color(0.95, 0.72, 0.25, 0.85)
	base_style.set_border_width_all(3)
	base_style.set_corner_radius_all(82)
	stick.add_theme_stylebox_override("panel", base_style)
	_overlay.add_child(stick)

	var knob := Panel.new()
	knob.name = "Knob"
	knob.size = Vector2(62, 62)
	knob.position = (stick.custom_minimum_size - knob.size) * 0.5
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.9, 0.66, 0.22, 0.9)
	knob_style.border_color = Color(1, 0.9, 0.6, 0.95)
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(31)
	knob.add_theme_stylebox_override("panel", knob_style)
	stick.add_child(knob)
	stick.gui_input.connect(_on_joystick_input.bind(stick, knob))


func _on_joystick_input(event: InputEvent, stick: Control, knob: Control) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_update_joystick(event.position, stick, knob)
		else:
			_reset_joystick(stick, knob)
	elif event is InputEventScreenDrag:
		_update_joystick(event.position, stick, knob)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_joystick(event.position, stick, knob)
		else:
			_reset_joystick(stick, knob)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_joystick(event.position, stick, knob)


func _update_joystick(position: Vector2, stick: Control, knob: Control) -> void:
	var center := stick.size * 0.5
	var radius := minf(stick.size.x, stick.size.y) * 0.34
	var offset := (position - center).limit_length(radius)
	knob.position = center + offset - knob.size * 0.5
	var direction := offset / radius
	var next_actions: Array[String] = []
	if direction.x < -0.28:
		next_actions.append("p1_left")
	elif direction.x > 0.28:
		next_actions.append("p1_right")
	if direction.y < -0.28:
		next_actions.append("p1_up")
	elif direction.y > 0.28:
		next_actions.append("p1_down")
	_set_held_actions(next_actions)


func _reset_joystick(stick: Control, knob: Control) -> void:
	knob.position = (stick.size - knob.size) * 0.5
	_set_held_actions([])


func _set_held_actions(next_actions: Array[String]) -> void:
	for action in _held_actions:
		if action not in next_actions:
			Input.action_release(action)
	for action in next_actions:
		if action not in _held_actions:
			Input.action_press(action)
	_held_actions = next_actions.duplicate()


func _add_attack_button(label_text: String, action: String, x: float, y: float) -> void:
	_add_action_button(label_text, action, x, y, 120, 56)


func _add_action_button(label_text: String, action: String, x: float, y: float, width: float, height: float) -> void:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(width, height)
	button.size = button.custom_minimum_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 12 if "\n" in label_text else 11)
	button.add_theme_color_override("font_color", Color(1, 0.94, 0.8, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.075, 0.82)
	style.border_color = Color(0.95, 0.72, 0.25, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	button.add_theme_stylebox_override("normal", style)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.65, 0.34, 0.08, 0.96)
	button.add_theme_stylebox_override("pressed", pressed)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = x
	button.offset_top = y
	button.offset_right = x + width
	button.offset_bottom = y + height
	_overlay.add_child(button)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	button.tree_exiting.connect(func() -> void: Input.action_release(action))


func _release_all() -> void:
	for action in _held_actions:
		Input.action_release(action)
	_held_actions.clear()
