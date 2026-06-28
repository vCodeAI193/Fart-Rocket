extends Area2D
class_name Checkpoint
## Checkpoint – Kontrollpunkt
## ==========================
## FR-135: Speichert die Spielerposition. Bei Tod kehrt der Spieler hierher
## zurück, statt das ganze Level neu zu starten.

signal triggered(checkpoint_pos: Vector2)

var _activated: bool = false
var _flag: Polygon2D


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _on_body_entered(body: Node) -> void:
	if _activated:
		return
	if body.is_in_group("player"):
		_activated = true
		triggered.emit(global_position + Vector2(0, -60))  # etwas über dem Boden
		GameManager.vibrate(20)
		# Flagge grün einfärben
		if is_instance_valid(_flag):
			var tween := create_tween()
			tween.tween_property(_flag, "color", Color(0.25, 0.9, 0.25), 0.3)


func _build_visual() -> void:
	# Mast
	var pole := Line2D.new()
	pole.width = 5.0
	pole.default_color = Color(0.8, 0.8, 0.8)
	pole.add_point(Vector2(0, 0))
	pole.add_point(Vector2(0, -88))
	add_child(pole)
	# Flagge (grau bis aktiviert)
	_flag = Polygon2D.new()
	_flag.color = Color(0.6, 0.6, 0.6)
	_flag.polygon = PackedVector2Array([
		Vector2(0, -88), Vector2(48, -66), Vector2(0, -44)
	])
	add_child(_flag)
	# Basis
	var base := ColorRect.new()
	base.color = Color(0.5, 0.4, 0.3)
	base.size = Vector2(28, 10)
	base.position = Vector2(-14, -5)
	add_child(base)
