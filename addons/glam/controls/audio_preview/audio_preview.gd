@tool
extends Control

@export var waveform_image_url: String
@export var preview_url: String: set = set_preview_url

@onready var _button: Button = find_child("Button")
@onready var _http_request: HTTPRequest = find_child("HTTPRequest")


func _ready():
	set_preview_url(preview_url)


func set_preview_url(value):
	preview_url = value
	_button.disabled = not preview_url


func _draw():
	# TODO: Draw line at current play location.
	pass


func _gui_input(event):
	# TODO: Move playhead based on click position
	#update()
	pass


func _on_Button_toggled(button_pressed):
	pass
