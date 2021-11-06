# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
class_name GlamAssetResourceFormatSaver
extends ResourceFormatSaver

const Asset = preload("./assets/asset.gd")


func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["glam"])


func recognize(resource: Resource) -> bool:
	var isit = resource is Asset
	return true


func save(path: String, resource: Resource, flags: int) -> int:
	var file := File.new()
	file.open(path, File.WRITE)
	file.store_string(
		"""; Do not modify this file! It was generated by GLAM and may be overwritten.
; Please make changes to the GLAM asset instead, or delete this file and
; create a custom license file.
;
"""
	)
	file.store_string("; SPDX-FileCopyrightText: none\n;\n")
	file.store_string("; SPDX-License-Identifier: CC0-1.0 OR MIT\n\n[glam]\ngenerated = true\n")
	file.close()
	return OK
