extends CanvasLayer
class_name CollectionScreen
## CollectionScreen – Sammlung, Statistik & Credits mit Tab-Navigation
## =======================================================================
## FR-225: Sammlungs-/Galerie-Bildschirm (Sticker-Karten)
## FR-226: Statistik-Bildschirm
## FR-227: Credits-Bildschirm
## FR-234: Tab-Navigation zwischen den drei Unterseiten

var _tab_container: TabContainer
var _sticker_grid: GridContainer
var _stats_list: VBoxContainer


func _ready() -> void:
	layer = 92
	visible = false
	_build_ui()


func show_screen() -> void:
	_refresh_stickers()
	_refresh_stats()
	visible = true


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_tab_container = TabContainer.new()
	_tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tab_container.offset_left = 40
	_tab_container.offset_top = 40
	_tab_container.offset_right = -40
	_tab_container.offset_bottom = -110
	bg.add_child(_tab_container)

	# --- Tab 1: Sammlung (Sticker) ---------------------------------
	var sticker_scroll := ScrollContainer.new()
	sticker_scroll.name = "Sammlung"
	_tab_container.add_child(sticker_scroll)
	_sticker_grid = GridContainer.new()
	_sticker_grid.columns = 4
	_sticker_grid.add_theme_constant_override("h_separation", 16)
	_sticker_grid.add_theme_constant_override("v_separation", 16)
	sticker_scroll.add_child(_sticker_grid)

	# --- Tab 2: Statistik --------------------------------------------
	var stats_scroll := ScrollContainer.new()
	stats_scroll.name = "Statistik"
	_tab_container.add_child(stats_scroll)
	_stats_list = VBoxContainer.new()
	_stats_list.add_theme_constant_override("separation", 14)
	stats_scroll.add_child(_stats_list)

	# --- Tab 3: Credits ------------------------------------------------
	var credits_scroll := ScrollContainer.new()
	credits_scroll.name = "Credits"
	_tab_container.add_child(credits_scroll)
	var credits_label := Label.new()
	credits_label.text = "\nFart Rocket\n\nEin Godot-4-Arcade-Spiel\nEntwickelt mit prozeduraler Grafik —\nkeine externen Assets.\n\nDanke fürs Spielen! 🚀"
	credits_label.add_theme_font_size_override("font_size", 30)
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_scroll.add_child(credits_label)

	_tab_container.tab_changed.connect(func(_i): GameManager.play_ui_click())

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


## FR-225: Sticker-Sammlung als Karten-Raster mit "???" für unentdeckte.
func _refresh_stickers() -> void:
	for child in _sticker_grid.get_children():
		child.queue_free()
	for sticker_name in GameManager.STICKER_SET:
		var owned: bool = sticker_name in GameManager.collected_stickers
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(180, 120)
		var label := Label.new()
		label.text = sticker_name if owned else "???"
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color.WHITE if owned else Color(0.4, 0.4, 0.4))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(label)
		_sticker_grid.add_child(card)


## FR-226: Zeigt gesammelte Lebenszeit-Statistiken an.
func _refresh_stats() -> void:
	for child in _stats_list.get_children():
		child.queue_free()
	var entries := [
		["Spieler-Level", str(GameManager.player_level)],
		["Gesamt-XP", str(GameManager.total_xp)],
		["Fürze abgegeben", str(GameManager.stat_total_farts)],
		["Tode", str(GameManager.stat_total_deaths)],
		["Entdeckte Gegner", "%d / %d" % [GameManager.discovered_enemies.size(), GameManager.ENEMY_BESTIARY.size()]],
		["Sticker-Karten", "%d / %d" % [GameManager.collected_stickers.size(), GameManager.STICKER_SET.size()]],
		["Gesamtfortschritt", "%.0f%%" % GameManager.get_overall_progress_percent()],
		["Guthaben", "%d Münzen" % GameManager.persistent_coins],
	]
	for entry in entries:
		var row := HBoxContainer.new()
		var key_label := Label.new()
		key_label.text = entry[0]
		key_label.custom_minimum_size = Vector2(360, 0)
		key_label.add_theme_font_size_override("font_size", 28)
		row.add_child(key_label)
		var value_label := Label.new()
		value_label.text = entry[1]
		value_label.add_theme_font_size_override("font_size", 28)
		value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		row.add_child(value_label)
		_stats_list.add_child(row)
