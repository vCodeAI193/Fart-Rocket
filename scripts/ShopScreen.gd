extends CanvasLayer
class_name ShopScreen
## ShopScreen – Shop-Bildschirm (FR-224)
## ===========================================
## Erlaubt den Kauf kosmetischer Skin-Farben mit dem dauerhaften
## Guthaben (GameManager.persistent_coins), das beim Levelabschluss
## eingezahlt wird.

const SKIN_OFFERS := [
	{"id": "default", "name": "Standard", "color": Color(0.95, 0.95, 0.95), "cost": 0},
	{"id": "gold", "name": "Gold", "color": Color(1.0, 0.85, 0.2), "cost": 200},
	{"id": "toxic", "name": "Toxisch", "color": Color(0.4, 1.0, 0.3), "cost": 300},
	{"id": "royal", "name": "Königsblau", "color": Color(0.25, 0.4, 1.0), "cost": 300},
	{"id": "magma", "name": "Magma", "color": Color(1.0, 0.3, 0.1), "cost": 450},
	{"id": "shadow", "name": "Schatten", "color": Color(0.25, 0.2, 0.3), "cost": 500},
]

var _list: VBoxContainer
var _balance_label: Label


func _ready() -> void:
	layer = 91
	visible = false
	_build_ui()


func show_shop() -> void:
	_refresh()
	visible = true


func _refresh() -> void:
	_balance_label.text = "Guthaben: %d Münzen" % GameManager.persistent_coins
	for child in _list.get_children():
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

		var owned: bool = offer["id"] in GameManager.unlocked_skin_colors
		var active: bool = GameManager.active_skin_color == offer["id"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 64)
		btn.add_theme_font_size_override("font_size", 26)
		if active:
			btn.text = "Aktiv"
			btn.disabled = true
		elif owned:
			btn.text = "Ausrüsten"
			btn.pressed.connect(_on_equip_pressed.bind(offer["id"]))
		else:
			btn.text = "Kaufen (%d)" % offer["cost"]
			btn.disabled = GameManager.persistent_coins < offer["cost"]
			btn.pressed.connect(_on_buy_pressed.bind(offer["id"], offer["cost"]))
		row.add_child(btn)

		_list.add_child(row)


func _on_buy_pressed(id: String, cost: int) -> void:
	GameManager.play_ui_click()
	if GameManager.unlock_skin_color(id, cost):
		GameManager.vibrate(40)
		_refresh()


func _on_equip_pressed(id: String) -> void:
	GameManager.play_ui_click()
	GameManager.active_skin_color = id
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
	title.position = Vector2(60, 40)
	bg.add_child(title)

	_balance_label = Label.new()
	_balance_label.add_theme_font_size_override("font_size", 32)
	_balance_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_balance_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_balance_label.offset_left = -420.0
	_balance_label.offset_top = 40.0
	_balance_label.offset_right = -40.0
	_balance_label.offset_bottom = 90.0
	bg.add_child(_balance_label)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 120
	scroll.offset_left = 60
	scroll.offset_right = -60
	scroll.offset_bottom = -100
	bg.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16)
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
