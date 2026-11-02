extends CanvasLayer
## Browser-only touch controls. Desktop keyboard/gamepad mappings remain unchanged.

const ACTION_BUTTONS := {
	"LP": "p1_lp",
	"HP": "p1_hp",
	"LK": "p1_lk",
	"HK": "p1_hk",
	"STEP": "p1_sidestep",
	"PAUSE": "pause",
}
var _overlay: Control
var _buttons: Array[BaseButton] = []


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	layer = 100
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed(get_tree().current_scene)


func _on_scene_changed(scene: Node) -> void:
	if not OS.has_feature("web"):
		return
	if is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
	_buttons.clear()
	if scene == null or scene.scene_file_path != "res://scenes/fight.tscn":
		return
	_overlay = Control.new()
	_overlay.name = "TouchControls"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay)
	_add_button("◀", "p1_left", Vector2(22, -98), Vector2(72, 72), false)
	_add_button("▶", "p1_right", Vector2(166, -98), Vector2(72, 72), false)
	_add_button("▲", "p1_up", Vector2(94, -170), Vector2(72, 72), false)
	_add_button("▼", "p1_down", Vector2(94, -26), Vector2(72, 72), false)
	_add_button("LP", "p1_lp", Vector2(-174, -174), Vector2(70, 70), true)
	_add_button("HP", "p1_hp", Vector2(-94, -174), Vector2(70, 70), true)
	_add_button("LK", "p1_lk", Vector2(-174, -94), Vector2(70, 70), true)
	_add_button("HK", "p1_hk", Vector2(-94, -94), Vector2(70, 70), true)
	_add_button("STEP", "p1_sidestep", Vector2(-134, -254), Vector2(70, 54), true)
	_add_button("Ⅱ", "pause", Vector2(-76, 18), Vector2(54, 42), true)


func _add_button(label_text: String, action: String, offset: Vector2, size: Vector2, right_side: bool) -> void:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = size
	button.size = size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1, 1, 1, 0.82)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.075, 0.72)
	style.border_color = Color(0.95, 0.72, 0.25, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", style)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.65, 0.34, 0.08, 0.95)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_font_size_override("font_size", 16)
	if right_side:
		button.anchor_left = 1.0
		button.anchor_right = 1.0
	else:
		button.anchor_left = 0.0
		button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + size.x
	button.offset_bottom = offset.y + size.y
	_overlay.add_child(button)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	button.tree_exiting.connect(func() -> void: Input.action_release(action))
	_buttons.append(button)
