extends Area2D
class_name FlameJet
## FlameJet – Feuerspeier-/Flammenwerfer-Düse (FR-066)
## ======================================================
## Eine Düse, die periodisch einen Feuerstoß in eine
## festgelegte Richtung ausstößt.

@export var direction: Vector2 = Vector2.UP
@export var flame_length: float = 200.0
@export var flame_width: float = 40.0
@export var active_time: float = 0.8
@export var inactive_time: float = 1.5
@export var warning_time: float = 0.3

var _is_active: bool = false
var _timer: float = 0.0
var _flame_node: Node2D
var _cshape: CollisionShape2D
var _particles: CPUParticles2D


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_timer = inactive_time
	_build_visual()
	_update_state()


func _process(delta: float) -> void:
	_timer -= delta

	if not _is_active and _timer <= warning_time and _timer > 0.0:
		# Vorwarnung: kleine Funken an der Düse
		if randf() < 0.3:
			_spawn_spark()

	if _timer <= 0.0:
		_is_active = not _is_active
		_timer = active_time if _is_active else inactive_time
		_update_state()
		GameManager.vibrate(20)


func _spawn_spark() -> void:
	var spark := ColorRect.new()
	spark.size = Vector2(4, 4)
	spark.color = Color(1.0, 0.6, 0.1, 0.8)
	spark.position = direction * 20.0 - Vector2(2, 2)
	add_child(spark)
	var tween := create_tween()
	tween.tween_property(spark, "position", spark.position + direction * 20.0, 0.2)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.2)
	tween.tween_callback(spark.queue_free)


func _update_state() -> void:
	_flame_node.visible = _is_active
	_cshape.disabled = not _is_active
	_particles.emitting = _is_active


func _on_body_entered(body: Node) -> void:
	if body is Player and _is_active:
		body._on_body_entered(self)


func _build_visual() -> void:
	_flame_node = Node2D.new()
	add_child(_flame_node)

	# Flammen-Kegel (mehrere überlappende Dreiecke für Feuer-Look)
	for i in range(3):
		var flame := Polygon2D.new()
		var offset := (i - 1) * 0.15
		var perp := Vector2(-direction.y, direction.x)
		var len_scale := 1.0 - abs(offset) * 0.5
		flame.polygon = PackedVector2Array([
			perp * flame_width * 0.3 * (1.0 - offset),
			-perp * flame_width * 0.3 * (1.0 + offset),
			direction * flame_length * len_scale,
		])
		flame.color = Color(1.0, 0.5 + i * 0.15, 0.1, 0.8 - i * 0.15)
		_flame_node.add_child(flame)

	# FR-284: Hitzeflimmer-Shader — als eigene Überlagerung ÜBER der Flamme
	# platziert (nicht als Material der Flammen-Polygone selbst, da der
	# Shader den kompletten Bildschirminhalt darunter samplet/verzerrt und
	# sonst die orangene Flammenfarbe unsichtbar machen würde). So verzerrt
	# die Überlagerung die bereits gezeichnete Flamme + Hintergrund darunter
	# und erzeugt den gewünschten Flimmer-Effekt, ohne die Flamme zu ersetzen.
	var shimmer_rect := Polygon2D.new()
	shimmer_rect.color = Color(1, 1, 1, 1)
	shimmer_rect.polygon = PackedVector2Array([
		Vector2(-direction.y, direction.x) * flame_width * 0.6,
		Vector2(direction.y, -direction.x) * flame_width * 0.6,
		direction * flame_length * 1.15 + Vector2(direction.y, -direction.x) * flame_width * 0.2,
		direction * flame_length * 1.15 + Vector2(-direction.y, direction.x) * flame_width * 0.2,
	])
	var shimmer_mat := ShaderMaterial.new()
	shimmer_mat.shader = load("res://shaders/heat_shimmer.gdshader")
	shimmer_rect.material = shimmer_mat
	_flame_node.add_child(shimmer_rect)

	# Partikel-Effekt
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.amount = 20
	_particles.lifetime = 0.4
	_particles.direction = direction
	_particles.spread = 15.0
	_particles.initial_velocity_min = 200.0
	_particles.initial_velocity_max = 350.0
	_particles.color = Color(1.0, 0.5, 0.1, 0.8)
	add_child(_particles)

	# Düsen-Basis
	var base := Polygon2D.new()
	base.color = Color(0.3, 0.3, 0.3)
	var bpts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		bpts.append(Vector2(cos(a), sin(a)) * 14.0)
	base.polygon = bpts
	add_child(base)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(flame_length, flame_width)
	_cshape.position = direction * flame_length * 0.5
	_cshape.rotation = direction.angle()
	_cshape.shape = rect_shape
	add_child(_cshape)
