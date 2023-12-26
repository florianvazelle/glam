# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
extends TextureRect

signal icon_changed(new_icon)

@export var spinning := false:
	set = set_spinning

var _icons := []
var _current_icon := 0

@onready var _timer := $Timer


func _ready():
	_timer.wait_time = 0.1
	self.spinning = visible


func _load_icons():
	for i in range(1, 9):
		var base_dir = get_script().resource_path.get_base_dir()
		var icon: Texture = load("%s/../../icons/icon_progress_%d.svg" % [base_dir, i])
		_icons.append(icon)


func set_spinning(value: bool) -> void:
	spinning = value
	if _timer:
		if spinning:
			_timer.start()
		else:
			_timer.stop()


func _set(property: StringName, value) -> bool:
	match property:
		"visible":
			assert(value is bool)
			visible = value
			spinning = visible
			return true
		_:
			return false


func _on_Timer_timeout():
	if _icons.is_empty():
		_load_icons()

	_current_icon = (_current_icon + 1) % _icons.size()
	texture = _icons[_current_icon]
	emit_signal("icon_changed", texture)
