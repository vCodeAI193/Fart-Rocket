extends Area2D
## GemCollectible – Edelstein
## ==========================
## FR-082: Wertvolles Sammelobjekt. Zählt als Münze mit hohem Punktwert
## und glitzert in wechselnden Farben.

@export var gem_value: int = 100
@export var gem_color: Color = Color(0.4, 0.8, 1.0)  # Türkis als Standard

var _collected: bool = false
var _inner: Polygon2D


func _ready() -> void:
	add_to_group("coins")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected and is_instance_valid(_inner):
		# Glitzereffekt: Helligkeit pulsiert
		var t := Time.get_ticks_msec() / 600.0
		var brightness := 0.7 + 0.3 * sin(t)
		_inner.color = gem_color.lightened(brightness * 0.4)


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		GameManager.add_coin(gem_value)
		GameManager.vibrate(40)
		_spawn_sparkle()
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()


func _spawn_sparkle() -> void:
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 24
	p.lifetime = 0.8
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 250.0
	p.gravity = Vector2(0, 100)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	p.color = gem_color
	var lt := p.lifetime
	get_tree().create_timer(lt + 0.1).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)


func _build_visual() -> void:
	# Diamantform (8 Ecken)
	var outer := Polygon2D.new()
	outer.color = gem_color
	var pts := PackedVector2Array([
		Vector2(0, -28), Vector2(18, -10),
		Vector2(28, 0), Vector2(18, 14),
		Vector2(0, 24), Vector2(-18, 14),
		Vector2(-28, 0), Vector2(-18, -10),
	])
	outer.polygon = pts
	add_child(outer)
	_inner = Polygon2D.new()
	_inner.color = gem_color.lightened(0.3)
	var ipts := PackedVector2Array([
		Vector2(0, -16), Vector2(10, -5),
		Vector2(16, 0), Vector2(10, 8),
		Vector2(0, 14), Vector2(-10, 8),
		Vector2(-16, 0), Vector2(-10, -5),
	])
	_inner.polygon = ipts
	add_child(_inner)
