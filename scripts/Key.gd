extends Area2D
class_name Key
## Key – Schlüssel für Tür-Mechanik (FR-091)
## ==============================================
## Ein Schlüssel mit einer Key-ID. Wird im GameManager für das
## laufende Level gespeichert; passende LockedDoor-Instanzen prüfen
## beim Kontakt, ob der Spieler den Schlüssel bereits hat.

@export var key_id: String = "gold"
@export var key_color: Color = Color(1.0, 0.85, 0.2)

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation += 1.2 * delta
		position.y += sin(Time.get_ticks_msec() * 0.003) * 0.2


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		GameManager.collect_key(key_id)
		GameManager.vibrate(35)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	# Ring
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in range(13):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0 + Vector2(-6, 0))
	ring.points = pts
	ring.width = 4.0
	ring.default_color = key_color
	add_child(ring)

	# Schaft
	var shaft := Line2D.new()
	shaft.points = [Vector2(4, 0), Vector2(20, 0)]
	shaft.width = 4.0
	shaft.default_color = key_color
	add_child(shaft)

	# Zähne
	var teeth := Line2D.new()
	teeth.points = [Vector2(16, 0), Vector2(16, 6), Vector2(20, 6), Vector2(20, 0)]
	teeth.width = 3.0
	teeth.default_color = key_color
	add_child(teeth)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	cshape.shape = circle
	add_child(cshape)
