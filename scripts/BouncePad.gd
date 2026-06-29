extends Area2D
## BouncePad – Trampolin/Sprungfeder
## ===================================
## FR-026: Gibt dem Spieler beim Betreten einen starken Impuls in
## `bounce_direction`. Sieht aus wie ein grünes federndes Brett.

@export var bounce_force: float = 1400.0
@export var bounce_direction: Vector2 = Vector2.UP

var _on_cooldown: bool = false


func _ready() -> void:
	add_to_group("bounce_pads")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if _on_cooldown:
		return
	if body is Player:
		_on_cooldown = true
		body.apply_central_impulse(bounce_direction.normalized() * bounce_force)
		GameManager.vibrate(30)
		_play_squish()
		await get_tree().create_timer(0.3).timeout
		_on_cooldown = false


func _play_squish() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale:y", 0.5, 0.06)
	tween.tween_property(self, "scale:y", 1.2, 0.08)
	tween.tween_property(self, "scale:y", 1.0, 0.10)


func _build_visual() -> void:
	# Grüne Platte
	var plate := ColorRect.new()
	plate.color = Color(0.3, 0.85, 0.35)
	plate.size = Vector2(140, 22)
	plate.position = Vector2(-70, -11)
	add_child(plate)
	# Drei Spiralen als "Federn"
	for i in range(3):
		var spring := Line2D.new()
		spring.width = 4.0
		spring.default_color = Color(0.6, 1.0, 0.5)
		var x := -42.0 + i * 42.0
		spring.add_point(Vector2(x, -11))
		spring.add_point(Vector2(x - 6, -26))
		spring.add_point(Vector2(x + 6, -38))
		spring.add_point(Vector2(x, -52))
		add_child(spring)
