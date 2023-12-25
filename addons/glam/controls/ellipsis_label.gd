@tool
extends Label

const ELLIPSIS = "…"
const PADDING = 2

var full_text: String


func _ready():
	mouse_filter = MOUSE_FILTER_PASS  # Required to show tooltip.
	_update_text()


func _set(property: StringName, value) -> bool:
	match property:
		"text":
			assert(value is String)
			full_text = value
			tooltip_text = full_text
			_update_text()
			return true
		_:
			return false


func _update_text():
	var value = full_text
	var font := EditorInterface.get_editor_theme().get_font("", "Editor")
	var max_width = clamp(max(size.x, custom_minimum_size.x) - PADDING, 0, INF)
	var width = font.get_string_size(value).x

	if width > max_width:
		while not value.is_empty() and width > (max_width):
			value = value.substr(0, value.length() - 2) + ELLIPSIS
			width = font.get_string_size(value).x

	text = value


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			_update_text()
