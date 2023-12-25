@tool
extends Resource
class_name AssetFile

@export var path := ""
@export var md5 := ""


func _init(p_path := "", p_md5 := ""):
	path = p_path
	md5 = p_md5
