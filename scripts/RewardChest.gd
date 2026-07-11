extends Area2D
class_name RewardChest
## RewardChest – Truhe mit Zufallsbelohnung (FR-090)
## ====================================================
## Eine Truhe, die beim Öffnen eine zufällige Belohnung
## vergibt: Münzen, Ladung, oder Bonus-XP.

@export var chest_size: float = 28.0
@export var min_coin_reward: int = 20
@export var max_coin_reward: int = 100
@export var color: Color = Color(0.6, 0.4, 0.15)

var _opened: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if _opened:
		return
	if body is Player:
		_opened = true
		_open_chest()


func _open_chest() -> void:
	GameManager.vibrate(60)

	# Zufällige Belohnung würfeln
	var roll := randf()
	if roll < 0.6:
		# 60%: Münzen
		var amount := randi_range(min_coin_reward, max_coin_reward)
		GameManager.add_coin(amount)
		_show_reward_text("+%d" % amount, Color(1.0, 0.85, 0.2))
	elif roll < 0.85:
		# 25%: Extra-Ladung
		GameManager.add_charge()
		_show_reward_text("+1 Ladung", Color(0.4, 1.0, 0.5))
	else:
		# 15%: Bonus-XP
		GameManager.add_xp(50)
		_show_reward_text("+50 XP", Color(0.6, 0.6, 1.0))

	# Öffnen-Animation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 0.8), 0.15)
	tween.chain().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.6).timeout
	queue_free()


func _show_reward_text(text: String, color: Color) -> void:
	if FloatingText:
		FloatingText.spawn(get_parent(), global_position, text, color)


func _build_visual() -> void:
	# Truhen-Boden
	var base := Polygon2D.new()
	base.color = color
	base.polygon = PackedVector2Array([
		Vector2(-chest_size, chest_size * 0.7),
		Vector2(chest_size, chest_size * 0.7),
		Vector2(chest_size, -chest_size * 0.1),
		Vector2(-chest_size, -chest_size * 0.1),
	])
	add_child(base)

	# Truhen-Deckel (gewölbt angedeutet durch Trapez)
	var lid := Polygon2D.new()
	lid.color = color.lightened(0.15)
	lid.polygon = PackedVector2Array([
		Vector2(-chest_size * 0.9, -chest_size * 0.1),
		Vector2(chest_size * 0.9, -chest_size * 0.1),
		Vector2(chest_size * 0.7, -chest_size * 0.7),
		Vector2(-chest_size * 0.7, -chest_size * 0.7),
	])
	add_child(lid)

	# Goldenes Schloss
	var lock := Polygon2D.new()
	lock.color = Color(1.0, 0.85, 0.2)
	var lpts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		lpts.append(Vector2(cos(a), sin(a)) * chest_size * 0.15)
	lock.polygon = lpts
	lock.position = Vector2(0, -chest_size * 0.1)
	add_child(lock)

	# Goldene Beschläge (horizontale Streifen)
	for y_off in [-chest_size * 0.4, chest_size * 0.3]:
		var band := ColorRect.new()
		band.size = Vector2(chest_size * 2.0, 6)
		band.position = Vector2(-chest_size, y_off)
		band.color = Color(1.0, 0.85, 0.2, 0.8)
		add_child(band)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(chest_size * 2.0, chest_size * 1.6)
	cshape.shape = rect_shape
	add_child(cshape)
