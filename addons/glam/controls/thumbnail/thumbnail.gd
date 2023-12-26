# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
extends Button

const Asset := preload("../../assets/asset.gd")
const AudioStreamAsset := preload("../../assets/audio_stream_asset.gd")
const PreviewImage := preload("../preview_image.gd")

const DEFAULT_WIDTH = 120
const DEFAULT_HEIGHT = 156

signal download_requested(asset)
signal selected

var asset: Asset: set = set_asset
var selected = false: set = set_selected

@onready var _preview_image: PreviewImage = find_child("PreviewImage")
@onready var _type_icon = find_child("Icon")
@onready var _status_icon = find_child("Status")
@onready var _download_button = find_child("DownloadButton")
@onready var _display_name = find_child("DisplayName")
@onready var _focused_stylebox := EditorInterface.get_editor_theme().get_stylebox("panel", "Editor")
@onready var _unfocused_stylebox := StyleBoxEmpty.new()
@onready var _http_request: HTTPRequest = find_child("CacheableHTTPRequest")
@onready var _spinner := _preview_image.find_child("Spinner")
@onready var _download_spinner := find_child("DownloadSpinner")
@onready var _glam = get_tree().get_meta("glam")
@onready var _format_option_button := find_child("FormatOptionButton")
@onready var _audio_preview := find_child("AudioStreamEditor")

var _dragging := false
var _drag_data = null

#func _ready():
#	item_rect_changed.connect(self._on_size_changed)


func set_asset(value: Asset) -> void:
	assert(not asset, "Thumbnail already has asset. Create a new thumbnail instead.")
	asset = value

	_display_name.text = asset.title
	_type_icon.texture = get_tree().get_meta("glam").get_editor_icon(asset.get_icon_name())

	_update_downloaded_status()

	if asset is AudioStreamAsset:
		_preview_image.queue_free()
		_audio_preview.visible = true
		_audio_preview.thumbnail = self
		_audio_preview.asset = asset
	else:
		_audio_preview.queue_free()
		_preview_image.visible = true
		if asset.preview_image_lq:
			_preview_image.texture = asset.preview_image_lq
			_spinner.visible = false
		else:
			_spinner.visible = true
			_preview_image.load_image(asset.preview_image_url_lq)
			yield(_preview_image, "image_loaded")
			_spinner.visible = false

	asset.download_started.connect(self._update_downloaded_status)
	asset.download_completed.connect(self._update_downloaded_status)
	asset.download_status_changed.connect(self._update_downloaded_status)
	asset.download_format_changed.connect(self._on_download_format_changed)


func set_selected(value):
	if selected:
		add_stylebox_override("panel", _focused_stylebox)
		emit_signal("selected")
	else:
		add_stylebox_override("panel", _unfocused_stylebox)


func _update_downloaded_status(is_downloaded: bool = asset.downloaded) -> void:
	if asset.downloading:
		_status_icon.visible = false
		_download_button.visible = false
		_download_spinner.visible = true
	else:
		_download_spinner.visible = false
		if is_downloaded:
			_download_button.visible = false
			_status_icon.texture = _glam.get_editor_icon("StatusSuccess")
			_status_icon.visible = true
		else:
			_status_icon.visible = false
			_download_button.icon = _glam.get_editor_icon("AssetLib")
			_download_button.visible = true

	_format_option_button.clear()
	for i in range(asset.download_formats.size()):
		var option = asset.download_formats[i]
		_format_option_button.add_item(option)
		if asset.download_format == option:
			_format_option_button.select(i)


func get_drag_data(_position):
	var preview = preload("../drag_preview/drag_preview.tscn").instance()

	if asset.downloaded:
		preview.asset = asset
		set_drag_preview(preview)
		return {files = [asset.filepath], type = "files"}
	else:
		set_drag_preview(preview)
		return {files = [], type = "files"}


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			var x = size.x
			var y = size.x * 1.3
			var min_y = size.x * 1.3
			if size != Vector2(x, y):
				size = Vector2(x, y)
			if custom_minimum_size.y != min_y:
				custom_minimum_size.y = min_y


func _on_DownloadButton_pressed():
	emit_signal("download_requested", asset)


func _on_download_format_changed(new_format: String) -> void:
	if _format_option_button.get_item_text(_format_option_button.selected) != new_format:
		for i in range(_format_option_button.get_item_count()):
			if _format_option_button.get_item_text(i) == new_format:
				_format_option_button.select(i)
				break


func _on_FormatOptionButton_item_selected(index):
	asset.download_format = _format_option_button.get_item_text(index)
