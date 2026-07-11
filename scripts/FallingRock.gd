extends RigidBody2D
class_name FallingRock
## FallingRock – Fallender Felsbrocken (FR-067)
## ===============================================
## Ein Felsbrocken, der ausgelöst wird (Trigger-Zone oder Timer)
## und dann herabfällt. Trifft er den Spieler, ist es ein Treffer.

@export var size: float = 24.0
@export var color: Color = Color(0.45, 0.35, 0.3)
@export var trigger_delay: float = 0.0  # Verzögerung vor dem Fall
@export var auto_trigger: bool = true   # Fällt automatisch nach delay

var _triggered: bool = false
var _shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("obstacles")
	freeze = true  # Startet eingefroren (hängt in der Luft)
	body_entered.connect(_on_body_entered)
	_build_visual()

	if auto_trigger:
		await get_tree().create_timer(trigger_delay).timeout
		_trigger_fall()


func _physics_process(delta: float) -> void:
	if not _triggered and trigger_delay <= 0.0:
		return
	if _triggered:
		# Rotation während des Falls für realistischen Look
		rotation += delta * 3.0


func trigger() -> void:
	if not _triggered:
		_trigger_fall()


func _trigger_fall() -> void:
	if _triggered:
		return
	_triggered = true
	freeze = false
	GameManager.vibrate(20)


func _on_body_entered(body: Node) -> void:
	if body is Player and _triggered:
		# Treffer verursacht Tod
		pass  # Player._on_body_entered übernimmt via Gruppe "obstacles"
	elif body.is_in_group("obstacles") or body is StaticBody2D:
		# Aufprall auf Boden -> Felsbrocken bleibt liegen / zerbricht nach Zeit
		if _triggered:
			await get_tree().create_timer(2.0).timeout
			if is_instance_valid(self):
				var tween := create_tween()
				tween.tween_property(self, "modulate:a", 0.0, 0.5)
				tween.tween_callback(queue_free)


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var r := size * rng.randf_range(0.8, 1.1)
		pts.append(Vector2(cos(a), sin(a)) * r)
	body.polygon = pts
	add_child(body)

	# Risse-Textur (dunklere Linien)
	for i in range(3):
		var crack := Line2D.new()
		var angle := rng.randf_range(0, TAU)
		crack.points = [Vector2.ZERO, Vector2(cos(angle), sin(angle)) * size * 0.7]
		crack.width = 1.5
		crack.default_color = color.darkened(0.4)
		add_child(crack)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	cshape.shape = circle
	add_child(cshape)
