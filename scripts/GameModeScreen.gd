extends CanvasLayer
class_name GameModeScreen
## GameModeScreen – Spielmodus-Auswahl (FR-342-360)
## ====================================================
## Listet alle verfügbaren Spielmodi mit Kurzbeschreibung und dem
## persönlichen Bestwert (falls vorhanden) auf. Ein Tippen aktiviert den
## Modus für den nächsten Levelstart.

var _list: VBoxContainer
var _active_label: Label


func _ready() -> void:
	layer = 94
	visible = false
	_build_ui()


func show_screen() -> void:
	_refresh()
	visible = true


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Spielmodus wählen"
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.offset_left = 40
	title.offset_top = 24
	title.add_theme_font_size_override("font_size", 34)
	bg.add_child(title)

	_active_label = Label.new()
	_active_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_active_label.offset_left = 40
	_active_label.offset_top = 70
	_active_label.add_theme_font_size_override("font_size", 24)
	_active_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	bg.add_child(_active_label)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40
	scroll.offset_top = 120
	scroll.offset_right = -40
	scroll.offset_bottom = -100
	bg.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(240, 70)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -260
	close_btn.offset_top = -90
	close_btn.offset_right = -20
	close_btn.offset_bottom = -20
	close_btn.pressed.connect(func(): GameManager.play_ui_click(); visible = false)
	bg.add_child(close_btn)


func _refresh() -> void:
	var active_info: Dictionary = GameManager.GAME_MODE_INFO[GameManager.active_game_mode]
	_active_label.text = "Aktiv: %s" % String(active_info["name"])

	for child in _list.get_children():
		child.queue_free()

	for mode in GameManager.GAME_MODE_INFO.keys():
		if mode == GameManager.GameMode.TIME_ATTACK:
			continue  # bereits über den bestehenden Zeitrennen-Umschalter erreichbar
		var info: Dictionary = GameManager.GAME_MODE_INFO[mode]
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var text_box := VBoxContainer.new()
		text_box.custom_minimum_size = Vector2(680, 0)
		hbox.add_child(text_box)
		var name_label := Label.new()
		name_label.text = String(info["name"])
		name_label.add_theme_font_size_override("font_size", 26)
		if mode == GameManager.active_game_mode:
			name_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		text_box.add_child(name_label)
		var desc_label := Label.new()
		desc_label.text = String(info["desc"]) + _best_score_suffix(mode)
		desc_label.add_theme_font_size_override("font_size", 20)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_box.add_child(desc_label)

		var select_btn := Button.new()
		select_btn.text = "Aktiv" if mode == GameManager.active_game_mode else "Wählen"
		select_btn.disabled = mode == GameManager.active_game_mode
		select_btn.custom_minimum_size = Vector2(160, 60)
		select_btn.add_theme_font_size_override("font_size", 22)
		select_btn.pressed.connect(func():
			GameManager.set_game_mode(mode)
			GameManager.play_ui_click()
			GameManager.vibrate(15)
			_refresh()
		)
		hbox.add_child(select_btn)

		_list.add_child(row)


## Hängt einen Bestwert-Hinweis an die Beschreibung an, falls vorhanden.
func _best_score_suffix(mode: int) -> String:
	match mode:
		GameManager.GameMode.ENDLESS:
			return "\nBeste Runden-Serie: %d" % GameManager.endless_best_loops
		GameManager.GameMode.SURVIVAL:
			return "\nLängste Überlebenszeit: %.1f s" % GameManager.survival_best_time
		GameManager.GameMode.COIN_HUNT:
			return "\nBeste Münzjagd: %d" % GameManager.coin_hunt_best_score
		_:
			return ""
