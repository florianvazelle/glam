# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
extends Node

const Request := preload("./request.gd")
const CachedResponse := preload("./cached_response.gd")

const DEFAULT_TTL := 86400

signal cache_size_updated(size)

var cache_size_bytes: int
var cache_dir := ProjectSettings.globalize_path(
	ProjectSettings.get_meta("glam/directory") + "/cache"
)

var _ttl_regex := RegEx.new()


func _ready():
	delete_expired()


func set_cache_dir(value: String):
	cache_dir = ProjectSettings.globalize_path(value)
	if not DirAccess.dir_exists_absolute(cache_dir):
		DirAccess.make_dir_recursive_absolute(cache_dir)


func get_response(request: Request) -> CachedResponse:
	var response: CachedResponse = get_resource(request)
	return response


func get_resource(request: Request) -> Resource:
	var file_path = get_file_path(request)

	if not FileAccess.file_exists(file_path):
		return null

	if is_expired(file_path):
		DirAccess.remove_absolute(file_path)
		return null

	return load(file_path)


func get_ttl(file_name: String) -> int:
	if not _ttl_regex.is_valid():
		_ttl_regex.compile(".*_.*_(?<ttl>[0-9]+).res")
	return _ttl_regex.search(file_name).get_string("ttl").to_int()


func is_expired(file_path: String) -> bool:
	var ttl = get_ttl(file_path)
	var age = Time.get_unix_time_from_system() - FileAccess.get_modified_time(file_path)
	return age >= ttl


func store(request: Request, result, response_code, headers, body):
	assert(
		[HTTPClient.METHOD_GET, HTTPClient.METHOD_HEAD].has(request.method),
		"Only GET and HEAD requests are supported by cache."
	)
	var response := CachedResponse.new(result, response_code, headers, body)
	store_resource(request, response)


func store_resource(request: Request, resource: Resource):
	var file_path := get_file_path(request)
	ResourceSaver.save(file_path, resource, ResourceSaver.FLAG_COMPRESS)
	var file := FileAccess.open(file_path, FileAccess.READ)
	cache_size_bytes += file.get_len()
	file.close()
	emit_signal("cache_size_updated", cache_size_bytes)


func delete_expired():
	var dir := DirAccess.open(cache_dir)
	cache_size_bytes = 0

	var err := DirAccess.get_open_error()
	if err == OK:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".res"):
				var file_path = "%s/%s" % [cache_dir, file_name]
				if is_expired(file_path):
					dir.remove(file_path)
				else:
					var file := FileAccess.open(file_path, FileAccess.READ)
					cache_size_bytes += file.get_len()
					file.close()
			file_name = dir.get_next()
		emit_signal("cache_size_updated", cache_size_bytes)


func get_file_path(request: Request) -> String:
	# TODO: Support configurable TTL.
	return (
		"%s/%s_%s_%s.res"
		% [cache_dir, request.get_hash(), request.url.get_file().hash(), DEFAULT_TTL]
	)
