extends Area2D
## SlowMoPower – Zeitlupen-Power-up
## ==================================
## FR-085: Setzt Engine.time_scale für `slow_duration` Sekunden auf
## `slow_scale`, damit alles in Zeitlupe abläuft.

@export var slow_duration: float = 4.0   # Dauer in Echtzeit-Sekunden
@export var slow_scale: float = 0.35
@export var spin_speed: float = 1.2

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation += spin_speed * delta


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		# Zeitlupe aktivieren (unabhängig vom Time-Scale läuft der Timer)
		Engine.time_scale = slow_scale
		get_tree().create_timer(slow_duration, false, false, true).timeout.connect(
			func() -> void:
				Engine.time_scale = 1.0
		)
		GameManager.vibrate(50)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.15)
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Sanduhr-ähnliche Raute (blau-violett)
	var diamond := Polygon2D.new()
	diamond.color = Color(0.55, 0.3, 1.0, 0.9)
	diamond.polygon = PackedVector2Array([
		Vector2(0, -26), Vector2(18, 0), Vector2(0, 26), Vector2(-18, 0)
	])
	add_child(diamond)
	var inner := Polygon2D.new()
	inner.color = Color(0.8, 0.65, 1.0, 0.75)
	inner.polygon = PackedVector2Array([
		Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)
	])
	add_child(inner)
	# "⏱" andeuten: kleiner Kreis
	var lbl := Label.new()
	lbl.text = "Z"
	lbl.position = Vector2(-8, -12)
	lbl.add_theme_font_size_override("font_size", 20)
	add_child(lbl)
