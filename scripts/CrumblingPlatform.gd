extends StaticBody2D
class_name CrumblingPlatform
## CrumblingPlatform – Zerbröckelnde Plattform (FR-068)
## =======================================================
## Eine Plattform, die zu wackeln beginnt, sobald der Spieler
## sie berührt, und nach kurzer Zeit zerbricht/verschwindet.

@export var platform_size: Vector2 = Vector2(140, 20)
@export var crumble_delay: float = 0.8   # Zeit bis zum Zerfall nach Berührung
@export var respawn_time: float = 3.0    # Zeit bis zur Wiederherstellung (0 = nie)
@export var color: Color = Color(0.65, 0.5, 0.35)

var _triggered: bool = false
var _platform_rect: Polygon2D
var _cshape: CollisionShape2D


func _ready() -> void:
	add_to_group("obstacles_neutral")
	_build_visual()


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	var player := body as Player
	if player == null:
		return
	_triggered = true
	_start_crumble()


func _start_crumble() -> void:
	# Wackel-Animation
	var shake_tween := create_tween()
	for i in range(6):
		var offset := Vector2(randf_range(-3, 3), randf_range(-2, 2))
		shake_tween.tween_property(_platform_rect, "position", offset, crumble_delay / 12.0)
		shake_tween.tween_property(_platform_rect, "position", Vector2.ZERO, crumble_delay / 12.0)

	await get_tree().create_timer(crumble_delay).timeout
	_crumble()


func _crumble() -> void:
	_cshape.disabled = true
	GameManager.vibrate(25)

	# Fragment-Partikel
	for i in range(6):
		var frag := ColorRect.new()
		frag.size = Vector2(15, 8)
		frag.color = color
		frag.position = Vector2(
			randf_range(-platform_size.x * 0.4, platform_size.x * 0.4),
			randf_range(-5, 5)
		)
		add_child(frag)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(frag, "position:y", frag.position.y + 100, 0.6)
		tween.tween_property(frag, "modulate:a", 0.0, 0.6)
		tween.tween_callback(frag.queue_free)

	_platform_rect.visible = false

	if respawn_time > 0.0:
		await get_tree().create_timer(respawn_time).timeout
		_respawn()


func _respawn() -> void:
	_triggered = false
	_cshape.disabled = false
	_platform_rect.visible = true
	_platform_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_platform_rect, "modulate:a", 1.0, 0.3)


func _build_visual() -> void:
	_platform_rect = Polygon2D.new()
	_platform_rect.color = color
	var pts := PackedVector2Array([
		Vector2(-platform_size.x * 0.5, -platform_size.y * 0.5),
		Vector2(platform_size.x * 0.5, -platform_size.y * 0.5),
		Vector2(platform_size.x * 0.5, platform_size.y * 0.5),
		Vector2(-platform_size.x * 0.5, platform_size.y * 0.5),
	])
	_platform_rect.polygon = pts
	add_child(_platform_rect)

	# Risse-Muster (Vorschau der Zerbrechlichkeit)
	for i in range(3):
		var x := -platform_size.x * 0.3 + i * platform_size.x * 0.3
		var crack := Line2D.new()
		crack.points = [Vector2(x, -platform_size.y * 0.4), Vector2(x + 5, platform_size.y * 0.4)]
		crack.width = 1.0
		crack.default_color = color.darkened(0.5)
		_platform_rect.add_child(crack)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = platform_size
	_cshape.shape = rect_shape
	add_child(_cshape)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	area_shape.shape = rect_shape.duplicate()
	area.add_child(area_shape)
	# Der Spieler ist ein RigidBody2D — area_entered feuert für ihn nie.
	area.body_entered.connect(_on_body_entered)
	add_child(area)
