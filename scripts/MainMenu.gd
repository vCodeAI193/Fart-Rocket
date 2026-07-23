extends Control
## MainMenu – Hauptmenü mit Level-Auswahl
## ======================================
## Zeigt die drei Starter-Level zur Auswahl an, inklusive der bisher
## erreichten Stern-Bewertung. Ein Tippen auf ein Level startet es.

@onready var _level_buttons: HBoxContainer = $LevelButtons

var _settings_screen: SettingsScreen
var _onboarding: OnboardingScreen
var _bestiary_screen: BestiaryScreen      # FR-118
var _shop_screen: ShopScreen              # FR-224
var _collection_screen: CollectionScreen  # FR-225/226/227/234
var _progression_screen: ProgressionScreen  # FR-304/305/306/310/311/312/313
var _game_mode_screen: GameModeScreen       # FR-342-360
var _confirm_dialog: ConfirmDialog        # FR-228
var _level_detail_popup: PanelContainer   # FR-232
var _progress_label: Label                # FR-237
var _continue_btn: Button                 # FR-238
var _filter_bar: HBoxContainer            # FR-235
var _path_node: Node2D                    # FR-221: Weltkarten-Pfad
var _level_boxes: Array[Control] = []
var _current_filter: String = "all"       # FR-235: all | favorites | completed

var _bg_node: Node2D  # FR-231: animierter Hintergrund


func _ready() -> void:
	# FR-256: Menü-Musik
	SoundManager.play_menu_music()

	# FR-231: Animierter Sternenhintergrund im Hauptmenü
	_bg_node = Node2D.new()
	_bg_node.z_index = -10
	add_child(_bg_node)
	_build_menu_bg()

	# FR-221: Pfad-Ebene für die Weltkarten-Optik (hinter den Level-Buttons)
	_path_node = Node2D.new()
	_path_node.z_index = -1
	add_child(_path_node)

	# Overlay-Bildschirme erstellen
	_settings_screen = preload("res://scenes/SettingsScreen.tscn").instantiate()
	add_child(_settings_screen)
	_onboarding = preload("res://scenes/OnboardingScreen.tscn").instantiate()
	add_child(_onboarding)
	_onboarding.show_if_needed()
	_bestiary_screen = preload("res://scenes/BestiaryScreen.tscn").instantiate()
	add_child(_bestiary_screen)
	_shop_screen = preload("res://scenes/ShopScreen.tscn").instantiate()  # FR-224
	add_child(_shop_screen)
	_collection_screen = preload("res://scenes/CollectionScreen.tscn").instantiate()  # FR-225/226/227
	add_child(_collection_screen)
	_progression_screen = preload("res://scenes/ProgressionScreen.tscn").instantiate()  # FR-304/305/306/310/311/312/313
	add_child(_progression_screen)
	_game_mode_screen = preload("res://scenes/GameModeScreen.tscn").instantiate()  # FR-342-360
	add_child(_game_mode_screen)
	_confirm_dialog = preload("res://scenes/ConfirmDialog.tscn").instantiate()  # FR-228
	add_child(_confirm_dialog)

	_build_filter_bar()      # FR-235
	_build_level_buttons()
	call_deferred("_draw_world_map_path")  # FR-221 (nach Layout-Pass)
	_build_settings_button()
	_build_bestiary_button()
	_build_shop_button()
	_build_collection_button()
	_build_daily_coin_button()
	_build_progress_label()  # FR-237
	_build_continue_button() # FR-238
	_build_quit_button()     # FR-228
	_build_level_detail_popup()  # FR-232
	_build_progression_button()  # FR-304/305/306/310/311/312/313
	_build_game_mode_button()    # FR-342-360
	_show_daily_login_reward()   # FR-309


## FR-231: Prozeduraler Sternenhintergrund mit Drift-Animation.
func _build_menu_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_node.add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(60):
		var star := ColorRect.new()
		var sz := rng.randf_range(2.0, 5.0)
		star.custom_minimum_size = Vector2(sz, sz)
		star.color = Color(0.8, 0.85, 1.0, rng.randf_range(0.3, 0.9))
		star.position = Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1200))
		_bg_node.add_child(star)
		# Langsam nach rechts driften lassen
		var drift_x := rng.randf_range(8.0, 28.0)
		var tween := star.create_tween()
		tween.set_loops()
		tween.tween_property(star, "position:x", star.position.x + 1920.0, 1920.0 / drift_x)
		tween.tween_callback(func() -> void: star.position.x = -8.0)


## FR-233: Android-Zurück-Taste schließt Einstellungen oder beendet das Spiel.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings_screen.visible:
			_settings_screen.visible = false
		elif _shop_screen.visible:
			_shop_screen.visible = false
		elif _collection_screen.visible:
			_collection_screen.visible = false
		elif _bestiary_screen.visible:
			_bestiary_screen.visible = false
		else:
			_on_quit_pressed()


## FR-235: Filterleiste (Alle/Favoriten/Abgeschlossen) über der Levelauswahl.
func _build_filter_bar() -> void:
	_filter_bar = HBoxContainer.new()
	_filter_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_filter_bar.add_theme_constant_override("separation", 16)
	_filter_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_filter_bar.offset_top = 130.0
	_filter_bar.offset_left = -260.0
	_filter_bar.offset_right = 260.0
	add_child(_filter_bar)

	for entry in [["all", "Alle"], ["favorites", "★ Favoriten"], ["completed", "Abgeschlossen"]]:
		var btn := Button.new()
		btn.text = entry[1]
		btn.custom_minimum_size = Vector2(160, 56)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_filter_pressed.bind(entry[0]))
		_filter_bar.add_child(btn)


func _on_filter_pressed(filter_id: String) -> void:
	GameManager.play_ui_click()
	_current_filter = filter_id
	_apply_filter()


## FR-235: Blendet Level-Boxen abhängig vom aktiven Filter aus/ein.
func _apply_filter() -> void:
	for box in _level_boxes:
		var i: int = box.get_meta("level_index")
		var visible_now := true
		match _current_filter:
			"favorites":
				visible_now = i in GameManager.favorite_levels
			"completed":
				visible_now = GameManager.level_stars.get(i, 0) > 0
		box.visible = visible_now


## Erzeugt für jedes Level einen Button samt Stern-Anzeige, Favoriten-
## Umschalter (FR-236) und Info-Button für das Detail-Popup (FR-232).
func _build_level_buttons() -> void:
	_level_boxes.clear()
	for i in range(1, GameManager.TOTAL_LEVELS + 1):
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 8)
		box.set_meta("level_index", i)

		# Kopfzeile: Favoriten-Stern + Info-Button
		var header := HBoxContainer.new()
		header.alignment = BoxContainer.ALIGNMENT_CENTER
		var fav_btn := Button.new()
		fav_btn.text = "★" if i in GameManager.favorite_levels else "☆"
		fav_btn.custom_minimum_size = Vector2(56, 56)
		fav_btn.add_theme_font_size_override("font_size", 30)
		fav_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		fav_btn.pressed.connect(_on_favorite_pressed.bind(i, fav_btn))
		header.add_child(fav_btn)
		var info_btn := Button.new()
		info_btn.text = "ⓘ"
		info_btn.custom_minimum_size = Vector2(56, 56)
		info_btn.add_theme_font_size_override("font_size", 26)
		info_btn.pressed.connect(_on_level_info_pressed.bind(i))
		header.add_child(info_btn)
		box.add_child(header)

		# Level-Button
		var button := Button.new()
		button.text = "Level %d" % i
		button.custom_minimum_size = Vector2(280, 180)
		button.add_theme_font_size_override("font_size", 52)
		button.pressed.connect(_on_level_selected.bind(i))
		box.add_child(button)

		# Stern-Anzeige unter dem Button
		var stars_label := Label.new()
		var stars: int = GameManager.level_stars.get(i, 0)
		stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		stars_label.add_theme_font_size_override("font_size", 48)
		stars_label.add_theme_color_override("font_color", Color(1, 0.82, 0.15))
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(stars_label)

		_level_buttons.add_child(box)
		_level_boxes.append(box)


func _on_favorite_pressed(level_index: int, btn: Button) -> void:
	GameManager.play_ui_click()
	GameManager.toggle_favorite_level(level_index)
	btn.text = "★" if level_index in GameManager.favorite_levels else "☆"
	GameManager.vibrate(15)
	if _current_filter == "favorites":
		_apply_filter()


## FR-221: Zeichnet eine gestrichelte "Weltkarten"-Verbindungslinie
## zwischen den Level-Boxen, nachdem der Layout-Pass abgeschlossen ist.
func _draw_world_map_path() -> void:
	for child in _path_node.get_children():
		child.queue_free()
	if _level_boxes.size() < 2:
		return
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(0.5, 0.55, 0.8, 0.5)
	var points := PackedVector2Array()
	for box in _level_boxes:
		var center: Vector2 = box.global_position + box.size * 0.5
		points.append(center)
	line.points = points
	_path_node.add_child(line)
	# Kleine Wegpunkt-Kreise
	for p in points:
		var dot := Line2D.new()
		var pts := PackedVector2Array()
		for a_i in range(13):
			var a := TAU * float(a_i) / 12.0
			pts.append(p + Vector2(cos(a), sin(a)) * 8.0)
		dot.points = pts
		dot.width = 2.0
		dot.default_color = Color(0.6, 0.65, 0.9, 0.6)
		_path_node.add_child(dot)


## FR-232: Level-Detail-Popup mit Sternen, Bestzeit und Rang.
func _build_level_detail_popup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 93
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	layer.add_child(bg)

	_level_detail_popup = PanelContainer.new()
	_level_detail_popup.set_anchors_preset(Control.PRESET_CENTER)
	_level_detail_popup.custom_minimum_size = Vector2(480, 320)
	_level_detail_popup.offset_left = -240.0
	_level_detail_popup.offset_top = -160.0
	_level_detail_popup.offset_right = 240.0
	_level_detail_popup.offset_bottom = 160.0
	bg.add_child(_level_detail_popup)
	_level_detail_popup.set_meta("bg", bg)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_detail_popup.add_child(vbox)
	_level_detail_popup.set_meta("vbox", vbox)


func _on_level_info_pressed(level_index: int) -> void:
	GameManager.play_ui_click()
	var bg: ColorRect = _level_detail_popup.get_meta("bg")
	var vbox: VBoxContainer = _level_detail_popup.get_meta("vbox")
	for child in vbox.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Level %d" % level_index
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var stars: int = GameManager.level_stars.get(level_index, 0)
	var stars_label := Label.new()
	stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	stars_label.add_theme_font_size_override("font_size", 40)
	stars_label.add_theme_color_override("font_color", Color(1, 0.82, 0.15))
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stars_label)

	var best_time := GameModeManager.get_best_time(level_index)
	var time_label := Label.new()
	time_label.text = "Bestzeit: %.1fs" % best_time if best_time != INF else "Bestzeit: —"
	time_label.add_theme_font_size_override("font_size", 28)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_label)

	var attempts: int = GameManager.level_attempt_times.get(level_index, []).size()
	var attempts_label := Label.new()
	attempts_label.text = "Versuche: %d" % attempts
	attempts_label.add_theme_font_size_override("font_size", 28)
	attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(attempts_label)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(200, 64)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.pressed.connect(func(): GameManager.play_ui_click(); bg.visible = false)
	vbox.add_child(close_btn)

	bg.visible = true


## FR-222: Einstellungs-Button oben rechts hinzufügen.
func _build_settings_button() -> void:
	var btn := Button.new()
	btn.text = "Einstellungen"
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 20.0
	btn.offset_right = -20.0
	btn.offset_bottom = 92.0
	btn.pressed.connect(_on_settings_pressed)
	add_child(btn)


func _on_settings_pressed() -> void:
	GameManager.play_ui_click()  # FR-239
	GameManager.vibrate(15)      # FR-247: UI-Feedback
	_settings_screen.show_settings()


## FR-118: Bestiarium-Button hinzufügen.
func _build_bestiary_button() -> void:
	var btn := Button.new()
	btn.text = "Bestiarium"
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 100.0
	btn.offset_right = -20.0
	btn.offset_bottom = 172.0
	btn.pressed.connect(_on_bestiary_pressed)
	add_child(btn)


func _on_bestiary_pressed() -> void:
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_bestiary_screen.show_bestiary()


## FR-224: Shop-Button hinzufügen.
func _build_shop_button() -> void:
	var btn := Button.new()
	btn.text = tr("menu_shop")
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 180.0
	btn.offset_right = -20.0
	btn.offset_bottom = 252.0
	btn.pressed.connect(_on_shop_pressed)
	add_child(btn)


func _on_shop_pressed() -> void:
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_shop_screen.show_shop()


## FR-225/226/227: Sammlung-Button (Sticker/Statistik/Credits).
func _build_collection_button() -> void:
	var btn := Button.new()
	btn.text = tr("menu_collection")
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 260.0
	btn.offset_right = -20.0
	btn.offset_bottom = 332.0
	btn.pressed.connect(_on_collection_pressed)
	add_child(btn)


func _on_collection_pressed() -> void:
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_collection_screen.show_screen()


## FR-304/305/306/310/311/312/313: Fortschritts-Button (Skills, Saison,
## Wochenziele, Sparschwein, Prestige).
func _build_progression_button() -> void:
	var btn := Button.new()
	btn.text = tr("menu_progression")
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 340.0
	btn.offset_right = -20.0
	btn.offset_bottom = 412.0
	btn.pressed.connect(_on_progression_pressed)
	add_child(btn)


func _on_progression_pressed() -> void:
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_progression_screen.show_screen()


## FR-342-360: Spielmodus-Button (Endlos, Überleben, Hardcore, Zen, ...).
func _build_game_mode_button() -> void:
	var btn := Button.new()
	btn.text = tr("menu_game_mode")
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 420.0
	btn.offset_right = -20.0
	btn.offset_bottom = 492.0
	btn.pressed.connect(_on_game_mode_pressed)
	add_child(btn)


func _on_game_mode_pressed() -> void:
	GameManager.play_ui_click()
	GameManager.vibrate(15)
	_game_mode_screen.show_screen()


## FR-309: Zeigt beim Menü-Start eine kurze Meldung, falls die tägliche
## Login-Belohnung noch nicht abgeholt wurde, und schaltet sie frei.
func _show_daily_login_reward() -> void:
	if not GameManager.has_unclaimed_daily_login():
		return
	var reward := GameManager.claim_daily_login_reward()
	if reward <= 0:
		return
	var popup := Label.new()
	popup.text = tr("daily_login_bonus") % [GameManager.login_streak_day, reward]
	popup.add_theme_font_size_override("font_size", 32)
	popup.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	popup.offset_top = 40.0
	popup.offset_left = -300.0
	popup.offset_right = 300.0
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.modulate.a = 0.0
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.5)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)


## FR-093: Tagesmünzen-Button links oben hinzufügen.
func _build_daily_coin_button() -> void:
	var btn := DailyCoinButton.new()
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left = 20.0
	btn.offset_top = 20.0
	btn.offset_right = 300.0
	btn.offset_bottom = 92.0
	add_child(btn)


## FR-237: Gesamtfortschritt in Prozent, unter der Tagesmünze.
func _build_progress_label() -> void:
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 26)
	_progress_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
	_progress_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_progress_label.offset_left = 20.0
	_progress_label.offset_top = 100.0
	_progress_label.offset_right = 320.0
	_progress_label.offset_bottom = 140.0
	_progress_label.text = "Fortschritt: %.0f%%" % GameManager.get_overall_progress_percent()
	add_child(_progress_label)


## FR-238: Schnellstart-Button für das zuletzt gespielte Level.
func _build_continue_button() -> void:
	if GameManager.last_played_level <= 0:
		return
	_continue_btn = Button.new()
	_continue_btn.text = "Weiter (Level %d)" % GameManager.last_played_level
	_continue_btn.custom_minimum_size = Vector2(320, 76)
	_continue_btn.add_theme_font_size_override("font_size", 30)
	_continue_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_continue_btn.offset_left = 20.0
	_continue_btn.offset_top = 150.0
	_continue_btn.offset_right = 340.0
	_continue_btn.offset_bottom = 226.0
	_continue_btn.pressed.connect(_on_continue_pressed)
	add_child(_continue_btn)


func _on_continue_pressed() -> void:
	GameManager.play_ui_click()
	_on_level_selected(GameManager.last_played_level)


## FR-228: Beenden-Button mit Bestätigungsdialog unten links.
func _build_quit_button() -> void:
	var btn := Button.new()
	btn.text = tr("menu_quit")
	btn.custom_minimum_size = Vector2(220, 64)
	btn.add_theme_font_size_override("font_size", 26)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn.offset_left = 20.0
	btn.offset_top = -84.0
	btn.offset_right = 240.0
	btn.offset_bottom = -20.0
	btn.pressed.connect(_on_quit_pressed)
	add_child(btn)


func _on_quit_pressed() -> void:
	GameManager.play_ui_click()
	_confirm_dialog.confirmed.connect(func(): get_tree().quit(), CONNECT_ONE_SHOT)
	_confirm_dialog.show_dialog("Spiel beenden?", "Möchtest du Fart Rocket wirklich beenden?")


## Startet das gewählte Level: Auswahl merken und zur Main-Szene wechseln.
## FR-229: Kurzer Lade-Bildschirm mit Tipp vor dem Szenenwechsel.
func _on_level_selected(level_index: int) -> void:
	GameManager.play_ui_click()
	GameManager.current_level = level_index
	LoadingScreen.show_and_call(get_tree().root, 0.9, func():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
