extends Area2D
class_name MassPickup
## MassPickup – Trägheits-Pickup (FR-038)
## =====================================
## Ein Pickup, das die Masse des Spielers kurzzeitig erhöht.
## Dies macht den Spieler "schwerer" und schwächer beschleunigbar,
## aber auch träger bei Rotation.

@export var duration: float = 4.0
@export var mass_multiplier: float = 3.0
@export var size: float = 16.0

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
		_apply_mass_effect(body)
		GameManager.vibrate(30)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _apply_mass_effect(player: Player) -> void:
	var original_mass := player.mass
	var original_inertia := player.inertia
	player.mass = original_mass * mass_multiplier
	player.inertia = original_inertia * mass_multiplier

	await get_tree().create_timer(duration, false, false, true).timeout
	if is_instance_valid(player):
		player.mass = original_mass
		player.inertia = original_inertia


func _build_visual() -> void:
	var outer := Polygon2D.new()
	outer.color = Color(0.3, 0.2, 0.1, 0.8)
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	outer.polygon = pts
	add_child(outer)

	var inner := Polygon2D.new()
	inner.color = Color(0.6, 0.4, 0.2)
	pts = PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * (size * 0.6))
	inner.polygon = pts
	add_child(inner)

	# "M"-Symbol (Mass)
	var label := Label.new()
	label.text = "M"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	label.position = Vector2(-8, -10)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size + 2.0
	cshape.shape = circle
	add_child(cshape)
