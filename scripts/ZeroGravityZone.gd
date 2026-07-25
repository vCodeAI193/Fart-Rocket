extends Area2D
class_name ZeroGravityZone
## ZeroGravityZone – Schwerelosigkeits-Zone (FR-015)
## ================================================
## Eine Zone ohne Schwerkraft. Furz-Effekte sind
## gleichmäßiger ohne Gravitations-Bremsung.

@export var color: Color = Color(1.0, 0.8, 0.2, 0.25)
@export var zone_size: Vector2 = Vector2(350, 250)
@export var fart_power_multiplier: float = 1.3

var _original_gravity: float = 1.0
var _players_in_zone: int = 0
var _player_ref: Player = null


func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _physics_process(delta: float) -> void:
	# Floating-Partikel-Effekt in der Zone
	if _players_in_zone > 0 and randf() < 0.2:
		_spawn_float_particle()


func _spawn_float_particle() -> void:
	var particle := ColorRect.new()
	particle.size = Vector2(randf_range(3, 8), randf_range(3, 8))
	particle.color = Color(1.0, 0.85, 0.3, 0.6)
	particle.position = Vector2(
		global_position.x + randf_range(-zone_size.x * 0.4, zone_size.x * 0.4),
		global_position.y + randf_range(-zone_size.y * 0.4, zone_size.y * 0.4)
	)
	get_parent().add_child(particle)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(particle, "position:y", particle.position.y - randf_range(30, 60), randf_range(1.0, 2.0))
	tween.parallel().tween_property(particle, "modulate:a", 0.0, randf_range(1.0, 2.0))
	tween.tween_callback(particle.queue_free)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	_player_ref = player
	if _players_in_zone == 0:
		_original_gravity = player.gravity_scale
		player.gravity_scale = 0.0  # Schwerelosigkeit
	_players_in_zone += 1


func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	_players_in_zone -= 1
	if _players_in_zone <= 0:
		_players_in_zone = 0
		player.gravity_scale = _original_gravity


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = zone_size
	rect.position = -zone_size * 0.5
	rect.color = color
	add_child(rect)

	# Schwerelosigkeits-Symbol: Pfeile nach oben
	for i in range(4):
		var arrow := Line2D.new()
		var x := -zone_size.x * 0.3 + i * zone_size.x * 0.2
		var y := -zone_size.y * 0.2
		arrow.points = [
			Vector2(x, y + 15),
			Vector2(x, y),
			Vector2(x - 5, y + 7),
		]
		arrow.width = 2.0
		arrow.default_color = Color(1.0, 0.8, 0.2, 0.8)
		add_child(arrow)

	# Spirale/Wirbel-Effekt
	var spiral := Line2D.new()
	var s_points := []
	for i in range(20):
		var t := float(i) / 20.0
		var angle := TAU * t * 2.0
		var radius := zone_size.x * 0.15 * t
		s_points.append(Vector2(cos(angle), sin(angle)) * radius)
	spiral.points = s_points
	spiral.width = 2.0
	spiral.default_color = Color(1.0, 0.9, 0.4, 0.6)
	add_child(spiral)

	# "ZERO-G" Label
	var label := Label.new()
	label.text = "0-G"
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 0.9))
	label.position = Vector2(-zone_size.x * 0.5 + 10, zone_size.y * 0.5 - 35)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	cshape.shape = rect_shape
	add_child(cshape)
