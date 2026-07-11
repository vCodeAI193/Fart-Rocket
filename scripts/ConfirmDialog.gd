extends CanvasLayer
class_name ConfirmDialog
## ConfirmDialog – Wiederverwendbarer Bestätigungsdialog (FR-228)
## ====================================================================
## Zeigt eine Ja/Nein-Abfrage mit Titel und Nachricht. Wird für kritische
## Aktionen wie "Spiel beenden" oder "Fortschritt zurücksetzen" genutzt.

signal confirmed
signal cancelled

var _title_label: Label
var _message_label: Label


func _ready() -> void:
	layer = 120
	visible = false
	_build_ui()


## Zeigt den Dialog mit gegebenem Titel/Nachricht an.
func show_dialog(title: String, message: String) -> void:
	_title_label.text = title
	_message_label.text = message
	visible = true


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 340)
	panel.offset_left = -280.0
	panel.offset_top = -170.0
	panel.offset_right = 280.0
	panel.offset_bottom = 170.0
	bg.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_title_label)

	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 28)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_message_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "Abbrechen"
	cancel_btn.custom_minimum_size = Vector2(220, 76)
	cancel_btn.add_theme_font_size_override("font_size", 30)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	btn_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Bestätigen"
	confirm_btn.custom_minimum_size = Vector2(220, 76)
	confirm_btn.add_theme_font_size_override("font_size", 30)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	btn_row.add_child(confirm_btn)


func _on_confirm_pressed() -> void:
	GameManager.play_ui_click()
	GameManager.vibrate(20)
	visible = false
	confirmed.emit()


func _on_cancel_pressed() -> void:
	GameManager.play_ui_click()
	visible = false
	cancelled.emit()
