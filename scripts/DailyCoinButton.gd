extends Button
class_name DailyCoinButton
## DailyCoinButton – Tagesmünze im Hauptmenü (FR-093)
## =======================================================
## Ein Button, der einmal pro Kalendertag eine Bonus-Münze
## vergibt. Zeigt an, ob die Tagesmünze bereits abgeholt wurde.

func _ready() -> void:
	custom_minimum_size = Vector2(260, 72)
	add_theme_font_size_override("font_size", 30)
	pressed.connect(_on_pressed)
	_refresh()


func _refresh() -> void:
	if GameManager.is_daily_coin_available():
		text = "🪙 Tagesbonus (+%d)" % GameManager.DAILY_COIN_REWARD
		disabled = false
		modulate = Color(1.0, 1.0, 1.0)
	else:
		text = "Tagesbonus abgeholt"
		disabled = true
		modulate = Color(0.6, 0.6, 0.6)


func _on_pressed() -> void:
	if GameManager.claim_daily_coin():
		GameManager.vibrate(60)
		_refresh()
