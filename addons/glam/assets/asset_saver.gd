@tool
class_name GLAMAssetSaver
extends ResourceFormatSaver


func get_recognized_extensions(resource) -> PackedStringArray:
	if resource == null or not resource is GLAMAsset:
		return PackedStringArray()

	return PackedStringArray(["glam"])


func recognize(resource: Resource) -> bool:
	return resource is GLAMAsset


func save(path: String, resource: Resource, flags: int) -> int:
	var glam_dir: String = ProjectSettings.get_meta("glam/directory")
	var tmp := "%s/tmp/%s_%s.tres" % [glam_dir, hash(path), path.get_file()]

	# Ensure file is not compressed.
	flags &= ~ResourceSaver.FLAG_COMPRESS

	# Save in a '.tres' file first using the regular ResourceSaver.
	var err := ResourceSaver.save(resource, tmp, flags)
	if err != OK:
		return err

	# Get the contents of the '.tres' file.
	var file := FileAccess.open(tmp, FileAccess.READ)
	err = FileAccess.get_open_error()
	if err != OK:
		DirAccess.remove_absolute(tmp)
		return err

	var body := file.get_buffer(file.get_len())
	file.close()
	DirAccess.remove_absolute(tmp)

	file = FileAccess.open(path, FileAccess.WRITE)
	err = FileAccess.get_open_error()
	if err != OK:
		return err

	# Prepend a REUSE compliant license header so we do not have to create a
	# separate '.license' file. The REUSE tool gets confused if it sees these
	# tag so use \u003a for ':' so it doesn't detect them.
	file.store_line("; SPDX-FileCopyrightText\u003a none")
	file.store_line(";")
	file.store_line("; SPDX-License-Identifier\u003a CC0-1.0")

	# Append the rest of the file.
	file.store_buffer(body)

	return OK
