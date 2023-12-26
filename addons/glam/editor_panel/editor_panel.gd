# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
extends Control
signal source_changed(new_source)

const FileScanner := preload("../util/file_scanner.gd")
const Markdown := preload("../credits/markdown.gd")

var sources := []

@onready var source_panels := $VBoxContainer/SourcePanels
@onready var source_select: OptionButton = $VBoxContainer/HBoxContainer/SourceSelect
@onready var _query_bar := find_child("QueryBar")
@onready var _menu_button := find_child("MenuButton")


func _ready():
	# Add sources to the OptionButton, clearing it first.
	source_select.clear()
	var sources_dir: String = "%s/../sources" % get_script().get_path().get_base_dir()  # ./sources
	var dir := DirAccess.open(sources_dir)
	dir.list_dir_begin()
	var source_dir: String = dir.get_next()
	while source_dir != "":
		if dir.current_is_dir():
			var source_script := "%s/%s/%s_source.gd" % [sources_dir, source_dir, source_dir]
			if dir.file_exists(source_script):
				var source = load(source_script).new()
				var panel = preload("../source_panel/source_panel.tscn").instance()
				panel.source = source
				panel.add_child(source)
				panel.visible = false
				source_panels.add_child(panel)
				source_select.add_icon_item(source.get_icon(), source.get_display_name())
				sources.append({source = source, panel = panel})
		source_dir = dir.get_next()

	# Trigger authentication in all panels, so we don't have to wait to authenticate
	# the first time we open the panel.
	for source in sources:
		source.panel.show()

	_menu_button.get_popup().clear()
	_menu_button.get_popup().add_item("Generate Licenses", 0)
	#_menu_button.get_popup().add_item("Generate credits.json", 1)
	_menu_button.get_popup().add_item("Generate CREDITS.md", 2)
	_menu_button.get_popup().id_pressed.connect(self._on_menu_id_pressed)

	select_source(0)


func select_panel(_index: int) -> void:
	pass


func _get_glam_directory() -> String:
	return ProjectSettings.globalize_path(ProjectSettings.get_meta("glam/directory"))


func select_source(index: int):
	for i in range(sources.size()):
		if i == index:
			sources[i].panel.show()
		else:
			sources[i].panel.hide()
	var source = sources[index].source
	if source:
		_query_bar.source = source
		emit_signal("source_changed", source)


func _on_menu_id_pressed(id: int):
	const COMMENT := (
		"File generate by GLAM. Do not modify!"
		+ " Edit the '.glam' files throughout the project instead."
	)
	var paths := _get_asset_paths_rec()

	match id:
		0:  # Generate Licenses.
			for path in paths:
				var asset: GLAMAsset = load(path)
				if FileAccess.file_exists(path.get_basename()):
					asset.create_license_file(path.get_basename())

		1:  # Generate credits.json.
			var file := FileAccess.open("credits.json", FileAccess.WRITE)

			if FileAccess.get_open_error() != OK:
				return

			file.store_line("""{\n\t"__comment": "%s",\n\t"credits": [""" % COMMENT)

			for i in paths.size():
				var path = paths[i]
				var asset: GLAMAsset = load(path)
				file.store_line('\t\t"%s"%s' % [path, "," if i < (paths.size() - 1) else ""])

			file.store_line("\t]\n}")
			file.close()

		2:  # Generate CREDITS.md.
			var file := FileAccess.open("res://CREDITS.md", FileAccess.WRITE)
			assert(file.get_open_error() == OK, "Couldn't open res://CREDITS.md file for writing.")
			file.store_string(Markdown.generate_credits("res://", self.sources))
			file.close()


static func _get_asset_paths_rec(root := "res://") -> Array:
	var paths := []

	for path in FileScanner.list_files_rec(root):
		if path is String:
			var asset: GLAMAsset = load(path)

			if asset == null:
				continue

			paths.append(path)

	return paths
