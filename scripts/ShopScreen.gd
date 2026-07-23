extends CanvasLayer
class_name ShopScreen
## ShopScreen – Shop-Bildschirm (FR-224) mit vollständigem Kosmetik-System
## ============================================================================
## Kauf/Ausrüstung von: Skin-Farbe, Helm (FR-161), Kostüm (FR-163),
## Hut (FR-166), Pfeil-Design (FR-175), Tod-Animation (FR-176),
## Sieges-Pose (FR-177), Furz-Wolken-Farbe (FR-164) und Furz-Sound (FR-165).
## FR-169/170: Freischaltung per Guthaben mit Seltenheitsstufen.
## FR-171: Text-/Farb-Vorschau der aktuellen Ausrüstung.
## FR-172: Saisonale Items werden außerhalb ihrer Saison ausgegraut.
## FR-174: Skin-des-Tages-Button.
## FR-178: Sammlungs-Fortschrittsanzeige.
## FR-179: Mix&Match — jeder Slot ist unabhängig wählbar.
## FR-180: Eigener Farb-Editor für den Standard-Skin.

const SKIN_OFFERS := [
	{"id": "default", "name": "Standard", "color": Color(0.95, 0.95, 0.95), "cost": 0},
	{"id": "gold", "name": "Gold", "color": Color(1.0, 0.85, 0.2), "cost": 200},
	{"id": "toxic", "name": "Toxisch", "color": Color(0.4, 1.0, 0.3), "cost": 300},
	{"id": "royal", "name": "Königsblau", "color": Color(0.25, 0.4, 1.0), "cost": 300},
	{"id": "magma", "name": "Magma", "color": Color(1.0, 0.3, 0.1), "cost": 450},
	{"id": "shadow", "name": "Schatten", "color": Color(0.25, 0.2, 0.3), "cost": 500},
]

const RARITY_COLORS := {
	0: Color(0.75, 0.75, 0.75),   # COMMON
	1: Color(0.4, 0.7, 1.0),      # RARE
	2: Color(0.7, 0.3, 1.0),      # EPIC
	3: Color(1.0, 0.75, 0.1),     # LEGENDARY
}
const SLOT_TABS := [
	["helmet", "Helme"], ["outfit", "Kostüme"], ["hat", "Hüte"],
	["arrow", "Pfeile"], ["death", "Tod-Anim."], ["pose", "Sieges-Pose"],
	["fartcolor", "Furz-Farbe"], ["fartsound", "Furz-Sound"],
]

var _tab_container: TabContainer
var _balance_label: Label
var _progress_label: Label
var _preview_label: Label
var _color_tab: VBoxContainer
var _daily_skin_btn: Button
var _custom_color_picker: ColorPickerButton  # FR-180


func _ready() -> void:
	layer = 91
	visible = false
	_build_ui()


func show_shop() -> void:
	_refresh()
	visible = true
	AccessibilityManager.apply_menu_ui_scale(self, get_viewport().get_visible_rect().size)  # FR-424


func _refresh() -> void:
	_balance_label.text = "Guthaben: %d Münzen" % GameManager.persistent_coins
	var progress := CosmeticsManager.get_cosmetics_collection_progress()
	_progress_label.text = "Sammlung: %d / %d freigeschaltet" % [progress.x, progress.y]  # FR-178
	_refresh_preview()  # FR-171
	_refresh_color_tab()
	_refresh_daily_skin_button()
	for slot_entry in SLOT_TABS:
		_refresh_slot_tab(slot_entry[0])


## FR-171: Text-/Farbvorschau der aktuell ausgerüsteten Kosmetik.
func _refresh_preview() -> void:
	var parts := []
	for id in [
		CosmeticsManager.equipped_helmet, CosmeticsManager.equipped_outfit, CosmeticsManager.equipped_hat,
		CosmeticsManager.equipped_arrow_style, CosmeticsManager.equipped_death_anim,
		CosmeticsManager.equipped_victory_pose, CosmeticsManager.equipped_fart_color_style,
		CosmeticsManager.equipped_fart_sound,
	]:
		var info: Dictionary = CosmeticsManager.COSMETIC_CATALOG.get(id, {})
		if not info.is_empty():
			parts.append(info["name"])
	_preview_label.text = "Ausgerüstet: " + " · ".join(parts)


## FR-174: Skin-des-Tages-Button aktualisieren.
func _refresh_daily_skin_button() -> void:
	if CosmeticsManager.is_daily_skin_available():
		var id := CosmeticsManager.get_daily_skin_id()
		var info: Dictionary = CosmeticsManager.COSMETIC_CATALOG.get(id, {})
		_daily_skin_btn.text = "🎁 Skin des Tages: %s (gratis!)" % info.get("name", "?")
		_daily_skin_btn.disabled = false
	else:
		_daily_skin_btn.text = "Skin des Tages bereits abgeholt"
		_daily_skin_btn.disabled = true


func _on_daily_skin_pressed() -> void:
	GameManager.play_ui_click()
	if CosmeticsManager.claim_daily_skin():
		GameManager.vibrate(60)
	_refresh()


## FR-180: Aktualisiert den Farb-Editor-Tab (Standard-Skin-Swatches + Picker).
func _refresh_color_tab() -> void:
	for child in _color_tab.get_children():
		child.queue_free()

	for offer in SKIN_OFFERS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(50, 50)
		swatch.color = offer["color"]
		row.add_child(swatch)
		var name_label := Label.new()
		name_label.text = offer["name"]
		name_label.custom_minimum_size = Vector2(220, 0)
		name_label.add_theme_font_size_override("font_size", 30)
		row.add_child(name_label)
		var owned: bool = offer["id"] in CosmeticsManager.unlocked_skin_colors
		var active: bool = CosmeticsManager.active_skin_color == offer["id"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 64)
		btn.add_theme_font_size_override("font_size", 26)
		if active:
			btn.text = "Aktiv"
			btn.disabled = true
		elif owned:
			btn.text = "Ausrüsten"
			btn.pressed.connect(_on_equip_skin_pressed.bind(offer["id"]))
		else:
			btn.text = "Kaufen (%d)" % offer["cost"]
			btn.disabled = GameManager.persistent_coins < offer["cost"]
			btn.pressed.connect(_on_buy_skin_pressed.bind(offer["id"], offer["cost"]))
		row.add_child(btn)
		_color_tab.add_child(row)

	# FR-180: Eigener Farb-Editor (freies RGB) für den Standard-Skin
	var custom_row := HBoxContainer.new()
	custom_row.add_theme_constant_override("separation", 20)
	var custom_label := Label.new()
	custom_label.text = "Eigene Farbe"
	custom_label.custom_minimum_size = Vector2(220, 0)
	custom_label.add_theme_font_size_override("font_size", 30)
	custom_row.add_child(custom_label)
	_custom_color_picker = ColorPickerButton.new()
	_custom_color_picker.custom_minimum_size = Vector2(220, 64)
	_custom_color_picker.color = CosmeticsManager.custom_skin_color
	_custom_color_picker.color_changed.connect(_on_custom_color_changed)
	custom_row.add_child(_custom_color_picker)
	_color_tab.add_child(custom_row)


func _on_custom_color_changed(color: Color) -> void:
	CosmeticsManager.set_custom_skin_color(color)


func _on_buy_skin_pressed(id: String, cost: int) -> void:
	GameManager.play_ui_click()
	if CosmeticsManager.unlock_skin_color(id, cost):
		GameManager.vibrate(40)
		_refresh()


func _on_equip_skin_pressed(id: String) -> void:
	GameManager.play_ui_click()
	CosmeticsManager.active_skin_color = id
	GameManager.vibrate(20)
	_refresh()


## Baut/aktualisiert den Inhalt eines Kosmetik-Slot-Tabs (Helm/Kostüm/...).
func _refresh_slot_tab(slot: String) -> void:
	var tab_name := slot.capitalize().replace(" ", "")
	var scroll := _tab_container.get_node(tab_name)
	var list: VBoxContainer = scroll.get_node("list")
	for child in list.get_children():
		child.queue_free()

	for id in CosmeticsManager.COSMETIC_CATALOG.keys():
		var info: Dictionary = CosmeticsManager.COSMETIC_CATALOG[id]
		if info["slot"] != slot:
			continue
		# FR-334: Erfolgs-exklusive Items werden nicht im Shop gelistet
		if info.get("achievement_only", false) and not (id in CosmeticsManager.unlocked_cosmetics):
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		# FR-170: Seltenheits-Farbstreifen
		var rarity_bar := ColorRect.new()
		rarity_bar.custom_minimum_size = Vector2(10, 50)
		rarity_bar.color = RARITY_COLORS.get(info["rarity"], Color.WHITE)
		row.add_child(rarity_bar)

		var name_label := Label.new()
		name_label.text = info["name"]
		name_label.custom_minimum_size = Vector2(280, 0)
		name_label.add_theme_font_size_override("font_size", 28)
		row.add_child(name_label)

		var seasonal_ok := CosmeticsManager.is_cosmetic_seasonally_available(id)  # FR-172
		var owned: bool = id in CosmeticsManager.unlocked_cosmetics
		var active: bool = _is_equipped(id, slot)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 60)
		btn.add_theme_font_size_override("font_size", 24)
		if not seasonal_ok and not owned:
			btn.text = "Saisonal nicht verfügbar"
			btn.disabled = true
		elif active:
			btn.text = "Aktiv"
			btn.disabled = true
		elif owned:
			btn.text = "Ausrüsten"
			btn.pressed.connect(_on_equip_cosmetic_pressed.bind(id))
		else:
			btn.text = "Kaufen (%d)" % info["cost"]
			btn.disabled = GameManager.persistent_coins < info["cost"]
			btn.pressed.connect(_on_buy_cosmetic_pressed.bind(id))
		row.add_child(btn)

		list.add_child(row)


func _is_equipped(id: String, slot: String) -> bool:
	match slot:
		"helmet": return CosmeticsManager.equipped_helmet == id
		"outfit": return CosmeticsManager.equipped_outfit == id
		"hat": return CosmeticsManager.equipped_hat == id
		"arrow": return CosmeticsManager.equipped_arrow_style == id
		"death": return CosmeticsManager.equipped_death_anim == id
		"pose": return CosmeticsManager.equipped_victory_pose == id
		"fartcolor": return CosmeticsManager.equipped_fart_color_style == id
		"fartsound": return CosmeticsManager.equipped_fart_sound == id
	return false


func _on_buy_cosmetic_pressed(id: String) -> void:
	GameManager.play_ui_click()
	if CosmeticsManager.unlock_cosmetic(id):
		GameManager.vibrate(40)
		_refresh()


func _on_equip_cosmetic_pressed(id: String) -> void:
	GameManager.play_ui_click()
	CosmeticsManager.equip_cosmetic(id)
	GameManager.vibrate(20)
	_refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 48)
	title.position = Vector2(60, 30)
	bg.add_child(title)

	_balance_label = Label.new()
	_balance_label.add_theme_font_size_override("font_size", 28)
	_balance_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_balance_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_balance_label.offset_left = -420.0
	_balance_label.offset_top = 30.0
	_balance_label.offset_right = -40.0
	_balance_label.offset_bottom = 65.0
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bg.add_child(_balance_label)

	_progress_label = Label.new()  # FR-178
	_progress_label.add_theme_font_size_override("font_size", 22)
	_progress_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_progress_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_progress_label.offset_left = -420.0
	_progress_label.offset_top = 68.0
	_progress_label.offset_right = -40.0
	_progress_label.offset_bottom = 96.0
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bg.add_child(_progress_label)

	_preview_label = Label.new()  # FR-171
	_preview_label.add_theme_font_size_override("font_size", 20)
	_preview_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_preview_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_preview_label.offset_left = 240.0
	_preview_label.offset_top = 30.0
	_preview_label.offset_right = 1000.0
	_preview_label.offset_bottom = 90.0
	bg.add_child(_preview_label)

	_daily_skin_btn = Button.new()  # FR-174
	_daily_skin_btn.custom_minimum_size = Vector2(480, 56)
	_daily_skin_btn.add_theme_font_size_override("font_size", 24)
	_daily_skin_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_daily_skin_btn.offset_left = 60.0
	_daily_skin_btn.offset_top = 95.0
	_daily_skin_btn.offset_right = 540.0
	_daily_skin_btn.offset_bottom = 151.0
	_daily_skin_btn.pressed.connect(_on_daily_skin_pressed)
	bg.add_child(_daily_skin_btn)

	_tab_container = TabContainer.new()
	_tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tab_container.offset_left = 40
	_tab_container.offset_top = 160
	_tab_container.offset_right = -40
	_tab_container.offset_bottom = -100
	bg.add_child(_tab_container)
	_tab_container.tab_changed.connect(func(_i): GameManager.play_ui_click())

	# Tab 0: Farbe (bestehendes Skin-Farb-System + FR-180 Farb-Editor)
	var color_scroll := ScrollContainer.new()
	color_scroll.name = "Farbe"
	_tab_container.add_child(color_scroll)
	_color_tab = VBoxContainer.new()
	_color_tab.add_theme_constant_override("separation", 16)
	color_scroll.add_child(_color_tab)

	# Tabs 1..N: je ein Kosmetik-Slot
	for slot_entry in SLOT_TABS:
		var scroll := ScrollContainer.new()
		scroll.name = slot_entry[0].capitalize().replace(" ", "")
		_tab_container.add_child(scroll)
		var list := VBoxContainer.new()
		list.name = "list"
		list.add_theme_constant_override("separation", 10)
		scroll.add_child(list)
		# Tab-Titel (sichtbarer Name) separat setzen
		_tab_container.set_tab_title(_tab_container.get_tab_count() - 1, slot_entry[1])

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
