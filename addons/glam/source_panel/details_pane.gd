@tool
extends Panel

const Asset := preload("../assets/asset.gd")
const LicenseDB := preload("../licenses/license_db.gd")

signal tag_selected(tag)
signal download_requested(asset)

var asset: Asset: set = set_asset
var _popup_just_closed := false

@onready var _label := find_child("NoAssetLabel")
@onready var _preview_image := find_child("PreviewImage")
@onready var _display_name := find_child("DisplayName")
@onready var _scroll_container := find_child("ScrollContainer")
@onready var _details := find_child("Details")
@onready var _tooltip := find_child("Tooltip")
@onready var _spinner := find_child("Spinner")
@onready var _preview_popup := find_child("PreviewPopup")
@onready var _download_format_option_button := find_child("DownloadFormatOptionButton")


func _ready():
	_label.show()


func set_asset(value: Asset):
	asset = value

	if _scroll_container:
		_scroll_container.scroll_vertical = 0

	if not asset:
		_scroll_container.hide()
		_label.show()
		return

	if not asset.is_connected("download_format_changed", self._on_download_format_changed):
		asset.connect("download_format_changed", self._on_download_format_changed)

	_label.hide()
	_scroll_container.show()
	_preview_popup.hide()
	_preview_image.cancel()
	find_child("PreviewLarge").cancel()

	_display_name.text = asset.title

	_download_format_option_button.clear()
	for option in asset.download_formats:
		_download_format_option_button.add_item(option)

	_preview_image.texture = null
	_spinner.visible = true
	if asset.preview_image_lq:
		_preview_image.texture = asset.preview_image_lq
		_spinner.visible = false
	else:
		_preview_image.call_deferred(
			"load_image", asset.preview_image_url_lq, asset.preview_image_flags
		)
		await _preview_image.image_loaded
		asset.preview_image_lq = _preview_image.texture

	if asset.preview_image_url_hq:
		_spinner.visible = true
		_preview_image.load_image(asset.preview_image_url_hq, asset.preview_image_flags)

	_details.clear()
	_details.append_bbcode("Author: ")
	var authors := PackedStringArray()
	for author in asset.authors:
		if author is Asset.Author:
			if author.url:
				authors.append("[url=%s]%s[/url]" % [author.url, author.name])
			else:
				authors.append(author.name)
	_details.append_bbcode(", ".join(authors))
	_details.append_bbcode("\n\n")
	_details.append_bbcode("License: ")
	var licenses := PackedStringArray()
	for license in asset.licenses:
		if license is Asset.License:
			var details = LicenseDB.get_license(license.identifier)
			_details.append_bbcode("[url=%s]%s[/url]" % [license.identifier, license.identifier])
	_details.append_bbcode(", ".join(licenses))
	_details.append_bbcode("\n\n")
	_details.append_bbcode("Tags: ")
	var tags := PackedStringArray()
	for tag in asset.tags:
		tags.append("[url=%s]%s[/url]" % [tag, tag])
	_details.append_bbcode(", ".join(tags))


func _on_Download_pressed():
	emit_signal("download_requested", asset)


func _on_Details_meta_clicked(meta):
	# FIXME: Handle different meta types more robustly (e.g. license, tag, etc).
	if LicenseDB.has_license(meta):
		OS.shell_open(LicenseDB.get_license(meta).url)
	elif not meta.begins_with("http"):
		emit_signal("tag_selected", meta)


func _on_Details_meta_hover_ended(_meta):
	_tooltip.visible = false


func _on_Details_meta_hover_started(meta):
	if not _tooltip.visible:
		if LicenseDB.has_license(meta):
			_tooltip.get_node("Label").text = LicenseDB.get_license(meta).name
			_tooltip.visible = true  # Don't use popup() as it steals focus and causes the "hover_ended" signal to emit prematurely.
			_tooltip.set_position(get_global_mouse_position())


func _on_PreviewImage_image_loaded():
	_spinner.visible = false


func _on_PreviewImage_gui_input(event):
	if event is InputEventMouseButton:
		var popup = find_child("PreviewPopup")
		if event.button_index == BUTTON_LEFT:
			if event.button_pressed and not _popup_just_closed:
				find_child("PreviewLarge").load_image(asset.preview_image_url_hq)
				await find_child("PreviewLarge").image_loaded
				popup.set_as_toplevel(true)
				popup.popup_centered()


func _on_PreviewPopup_popup_hide():
	_popup_just_closed = true
	await get_tree().idle_frame
	_popup_just_closed = false


func _on_DownloadFormatOptionButton_item_selected(index):
	asset.download_format = asset.download_formats[index]


func _on_download_format_changed(new_format: String) -> void:
	if (
		_download_format_option_button.get_item_text(_download_format_option_button.selected)
		!= new_format
	):
		for i in range(_download_format_option_button.get_item_count()):
			if _download_format_option_button.get_item_text(i) == new_format:
				_download_format_option_button.select(i)
				break
