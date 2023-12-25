@tool
class_name GLAMAudioStreamAsset
extends GLAMAsset

@export var duration: float
@export var preview_audio_url: String


func get_icon_name() -> String:
	return "AudioStreamSample"
