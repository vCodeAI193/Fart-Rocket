extends Area2D
class_name InventoryPowerUp
## InventoryPowerUp – Power-up für manuelles Inventar (FR-100)
## ===================================================================
## Anders als die direkten Power-up-Pickups (Schild, Zeitlupe, ...)
## wird dieses Power-up beim Einsammeln nur im Inventar gespeichert
## und muss vom Spieler manuell über den HUD-Button ausgelöst werden.

@export var powerup_type: String = "shield"  # shield | slowmo | double_coins
@export var icon_color: Color = Color(0.3, 0.8, 0.9)

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation += 1.0 * delta


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		GameManager.store_powerup(powerup_type)
		GameManager.vibrate(30)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	var pouch := Polygon2D.new()
	pouch.color = icon_color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 18.0)
	pouch.polygon = pts
	add_child(pouch)

	var label := Label.new()
	label.text = "+"
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-8, -16)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	cshape.shape = circle
	add_child(cshape)
