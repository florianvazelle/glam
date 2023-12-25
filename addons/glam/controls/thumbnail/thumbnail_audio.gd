@tool
extends "res://addons/glam/controls/thumbnail/thumbnail.gd"

var playing := false
var audio_stream_player := find_child("AudioStreamPlayer")

@onready var _button: Button = find_child("Button")


func _ready():
	_update_button_label()


func _update_button_label():
	pass
