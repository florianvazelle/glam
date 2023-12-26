# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

var _cache := {}


func load_json(path: String):
	if _cache.has(path):
		return _cache[path]

	if path.is_rel_path():
		path = "%s/%s" % [get_script().get_path().get_base_dir(), path]
	
	var file := FileAccess.open(path, FileAccess.READ)
	assert(FileAccess.get_open_error() == OK)
	var result = JSON.parse(file.get_as_text()).result
	file.close()
	_cache[path] = result

	return result
