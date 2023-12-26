# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
class_name GLAMAssetLoader
extends ResourceFormatLoader

const AssetFile := preload("./asset_file.gd")


func get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["glam"])


func get_resource_type(path: String) -> String:
	return "Resource" if path.ends_with("glam") else ""


func handles_type(typename: String) -> bool:
	return typename == "Resource"


func load(path: String, original_path: String):
	var tmp := path + ".tres"

	DirAccess.copy_absolute(path, tmp)
	var resource := ResourceLoader.load(tmp)
	DirAccess.remove_absolute(tmp)

	if not resource is GLAMAsset:
		return null

	if resource.files.is_empty():
		if FileAccess.file_exists(path.get_basename()):
			resource.files.append(AssetFile.new(path.get_basename()))

			if resource is GLAMAudioStreamAsset:
				var audio_stream: AudioStream = load(path.get_basename())

				if not resource.preview_audio_url:
					resource.preview_audio_url = path.get_basename()

				if resource.duration < 0:
					resource.duration = audio_stream.get_length()

	return resource
