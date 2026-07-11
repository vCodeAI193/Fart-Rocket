extends CanvasLayer
class_name ProgressionScreen
## ProgressionScreen – Fortschritts-Zentrale
## ==========================================
## FR-304/305: Skill-Baum / permanente Upgrades
## FR-306: Prestige-/New-Game+-Modus
## FR-310: Wöchentliche Ziele
## FR-311/312/320: Saison-Leiste, Freischalt-Roadmap, nächstes Ziel
## FR-313: Münz-Sparziel (Sparschwein)

var _tab_container: TabContainer
var _skills_list: VBoxContainer
var _goals_list: VBoxContainer
var _prestige_list: VBoxContainer
var _balance_label: Label


func _ready() -> void:
	layer = 93
	visible = false
	_build_ui()
	GameManager.persistent_coins_changed.connect(func(_v): _refresh_skills())
	GameManager.skill_unlocked.connect(func(_id): _refresh_skills())
	GameManager.prestige_changed.connect(func(_lvl): _refresh_prestige())


func show_screen() -> void:
	_refresh_skills()
	_refresh_goals()
	_refresh_prestige()
	visible = true


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_balance_label = Label.new()
	_balance_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_balance_label.offset_left = 40
	_balance_label.offset_top = 24
	_balance_label.add_theme_font_size_override("font_size", 30)
	_balance_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	bg.add_child(_balance_label)

	_tab_container = TabContainer.new()
	_tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tab_container.offset_left = 40
	_tab_container.offset_top = 80
	_tab_container.offset_right = -40
	_tab_container.offset_bottom = -110
	bg.add_child(_tab_container)

	# --- Tab 1: Skills (FR-304/305) -----------------------------------
	var skills_scroll := ScrollContainer.new()
	skills_scroll.name = "Skills"
	_tab_container.add_child(skills_scroll)
	_skills_list = VBoxContainer.new()
	_skills_list.add_theme_constant_override("separation", 10)
	skills_scroll.add_child(_skills_list)

	# --- Tab 2: Saison & Ziele (FR-310/311/312/313/320) -----------------
	var goals_scroll := ScrollContainer.new()
	goals_scroll.name = "Ziele"
	_tab_container.add_child(goals_scroll)
	_goals_list = VBoxContainer.new()
	_goals_list.add_theme_constant_override("separation", 14)
	goals_scroll.add_child(_goals_list)

	# --- Tab 3: Prestige (FR-306) ---------------------------------------
	var prestige_scroll := ScrollContainer.new()
	prestige_scroll.name = "Prestige"
	_tab_container.add_child(prestige_scroll)
	_prestige_list = VBoxContainer.new()
	_prestige_list.add_theme_constant_override("separation", 14)
	prestige_scroll.add_child(_prestige_list)

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


## FR-304/305: Skill-Baum-Liste mit Freischalt-Buttons.
func _refresh_skills() -> void:
	_balance_label.text = "%d Münzen" % GameManager.persistent_coins
	for child in _skills_list.get_children():
		child.queue_free()
	for id in GameManager.SKILL_CATALOG.keys():
		var data: Dictionary = GameManager.SKILL_CATALOG[id]
		var owned: bool = id in GameManager.unlocked_skills
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var name_label := Label.new()
		name_label.text = data["name"]
		name_label.custom_minimum_size = Vector2(420, 0)
		name_label.add_theme_font_size_override("font_size", 26)
		if owned:
			name_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		hbox.add_child(name_label)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 60)
		btn.add_theme_font_size_override("font_size", 24)
		if owned:
			btn.text = "Freigeschaltet"
			btn.disabled = true
		else:
			btn.text = "%d Münzen" % int(data["cost"])
			btn.disabled = not GameManager.can_unlock_skill(id)
			btn.pressed.connect(func():
				if GameManager.unlock_skill(id):
					GameManager.play_ui_click()
					GameManager.vibrate(20)
			)
		hbox.add_child(btn)
		_skills_list.add_child(row)


## FR-310/311/312/313/320: Wochenziele, Saison-Leiste, Sparschwein,
## nächstes Ziel als Textvorschau.
func _refresh_goals() -> void:
	for child in _goals_list.get_children():
		child.queue_free()

	var preview := Label.new()
	preview.text = "Nächstes Ziel: %s" % GameManager.get_next_goal_preview()  # FR-320
	preview.add_theme_font_size_override("font_size", 26)
	preview.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_goals_list.add_child(preview)

	# FR-311/312: Saison-Leiste
	var season_header := Label.new()
	season_header.text = "\nSaison-Fortschritt (Stufe %d / %d)" % [GameManager.get_season_tier(), GameManager.SEASON_TIER_REWARDS.size()]
	season_header.add_theme_font_size_override("font_size", 28)
	_goals_list.add_child(season_header)
	var season_claim_btn := Button.new()
	season_claim_btn.custom_minimum_size = Vector2(320, 64)
	season_claim_btn.add_theme_font_size_override("font_size", 24)
	season_claim_btn.text = "Saison-Belohnung abholen"
	season_claim_btn.pressed.connect(func():
		var reward := GameManager.claim_season_tier_reward()
		if reward > 0:
			GameManager.play_ui_click()
			GameManager.vibrate(30)
			_refresh_goals()
	)
	_goals_list.add_child(season_claim_btn)

	# FR-310: Wöchentliche Ziele
	var weekly_header := Label.new()
	weekly_header.text = "\nWöchentliche Ziele"
	weekly_header.add_theme_font_size_override("font_size", 28)
	_goals_list.add_child(weekly_header)
	for goal in GameManager.WEEKLY_GOALS:
		var progress: int = int(GameManager.weekly_progress.get(goal["id"], 0))
		var claimed: bool = GameManager.weekly_claimed.get(goal["id"], false)
		var row := HBoxContainer.new()
		var key_label := Label.new()
		key_label.text = str(goal["name"])
		key_label.custom_minimum_size = Vector2(360, 0)
		key_label.add_theme_font_size_override("font_size", 24)
		row.add_child(key_label)
		var value_label := Label.new()
		value_label.text = "✓ eingelöst" if claimed else "%d / %d" % [progress, int(goal["target"])]
		value_label.add_theme_font_size_override("font_size", 24)
		value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if claimed else Color.WHITE)
		row.add_child(value_label)
		_goals_list.add_child(row)

	# FR-313: Sparschwein
	var piggy_header := Label.new()
	piggy_header.text = "\nSparschwein"
	piggy_header.add_theme_font_size_override("font_size", 28)
	_goals_list.add_child(piggy_header)
	var piggy_row := HBoxContainer.new()
	var piggy_label := Label.new()
	piggy_label.text = "%d / %d Münzen" % [GameManager.piggy_bank_amount, GameManager.PIGGY_BANK_CAP]
	piggy_label.custom_minimum_size = Vector2(360, 0)
	piggy_label.add_theme_font_size_override("font_size", 24)
	piggy_row.add_child(piggy_label)
	var piggy_btn := Button.new()
	piggy_btn.text = "Aufbrechen"
	piggy_btn.custom_minimum_size = Vector2(200, 56)
	piggy_btn.add_theme_font_size_override("font_size", 22)
	piggy_btn.disabled = GameManager.piggy_bank_amount < GameManager.PIGGY_BANK_CAP
	piggy_btn.pressed.connect(func():
		var payout := GameManager.break_piggy_bank()
		if payout > 0:
			GameManager.play_ui_click()
			GameManager.vibrate(40)
			_refresh_goals()
	)
	piggy_row.add_child(piggy_btn)
	_goals_list.add_child(piggy_row)


## FR-306: Prestige-Übersicht mit Bestätigungs-Button.
func _refresh_prestige() -> void:
	for child in _prestige_list.get_children():
		child.queue_free()

	var info := Label.new()
	info.text = "Prestige-Stufe: %d\nMünz-Bonus: +%.0f%%" % [
		GameManager.prestige_level, (GameManager.get_prestige_coin_multiplier() - 1.0) * 100.0
	]
	info.add_theme_font_size_override("font_size", 28)
	_prestige_list.add_child(info)

	var explain := Label.new()
	explain.text = "Setzt Level-Sterne zurück, erhöht dauerhaft die Münz-Belohnung.\nSkills, Kosmetik und Guthaben bleiben erhalten.\nBenötigt: %d Sterne insgesamt." % GameManager.PRESTIGE_STAR_REQUIREMENT
	explain.add_theme_font_size_override("font_size", 22)
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD
	_prestige_list.add_child(explain)

	var prestige_btn := Button.new()
	prestige_btn.text = "Prestige starten"
	prestige_btn.custom_minimum_size = Vector2(320, 70)
	prestige_btn.add_theme_font_size_override("font_size", 26)
	prestige_btn.disabled = not GameManager.can_prestige()
	prestige_btn.pressed.connect(func():
		if GameManager.do_prestige():
			GameManager.play_ui_click()
			GameManager.vibrate(60)
			_refresh_prestige()
	)
	_prestige_list.add_child(prestige_btn)
