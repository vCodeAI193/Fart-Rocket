extends Area2D
class_name WaterZone
## WaterZone – Unterwasser-Zone mit Auftrieb (FR-014)
## ==================================================
## Eine Zone, die den Spieler ins Wasser "nimmt".
## Furz-Effekte ändern sich, Blasen-Partikel entstehen,
## und der Auftrieb wirkt sich aus.

@export var buoyancy: float = 300.0  # Auftriebs-Kraft
@export var drag_multiplier: float = 3.0  # Wasser-Widerstand
@export var color: Color = Color(0.2, 0.4, 0.8, 0.2)
@export var zone_size: Vector2 = Vector2(400, 300)

var _water_surface_y: float = 0.0
var _players_in_water: int = 0
var _original_gravity: float = 1.0
var _original_drag: float = 0.0


func _ready() -> void:
	add_to_group("hazards")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_water_surface_y = global_position.y - zone_size.y * 0.5
	_build_visual()


func _physics_process(delta: float) -> void:
	# Bubble-Partikel-Effekte
	if _players_in_water > 0 and randf() < 0.3:
		_spawn_bubble()


func _spawn_bubble() -> void:
	var bubble := ColorRect.new()
	bubble.size = Vector2(randf_range(2, 6), randf_range(2, 6))
	bubble.color = Color(0.7, 0.9, 1.0, 0.5)
	bubble.position = Vector2(
		global_position.x + randf_range(-zone_size.x * 0.4, zone_size.x * 0.4),
		global_position.y + randf_range(-zone_size.y * 0.3, zone_size.y * 0.3)
	)
	get_parent().add_child(bubble)

	var tween := create_tween()
	tween.tween_property(bubble, "position:y", bubble.position.y - 100, 1.0)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 1.0)
	tween.tween_callback(bubble.queue_free)


func _on_area_entered(area: Area2D) -> void:
	if area is Player or area.owner is Player:
		var player = area if area is Player else area.owner
		if _players_in_water == 0:
			_original_gravity = player.gravity_scale
			_original_drag = player.linear_damp
			player.gravity_scale = 0.1  # Schwerkraft reduzieren (Auftrieb)
			player.linear_damp = _original_drag * drag_multiplier
		_players_in_water += 1


func _on_area_exited(area: Area2D) -> void:
	if area is Player or area.owner is Player:
		var player = area if area is Player else area.owner
		_players_in_water -= 1
		if _players_in_water <= 0:
			_players_in_water = 0
			player.gravity_scale = _original_gravity
			player.linear_damp = _original_drag


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = zone_size
	rect.position = -zone_size * 0.5
	rect.color = color
	# FR-283: Wasser-Brechungs-Shader (verzerrt den Hintergrund wellenförmig)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water_refraction.gdshader")
	mat.set_shader_parameter("water_tint", color)
	rect.material = mat
	add_child(rect)

	# Wasser-Wellen-Pattern (oben)
	var waves := Line2D.new()
	var wave_points := []
	for i in range(20):
		var x := -zone_size.x * 0.5 + i * zone_size.x / 20.0
		var y := -zone_size.y * 0.5 + sin(i * 0.4) * 5.0
		wave_points.append(Vector2(x, y))
	waves.points = wave_points
	waves.width = 2.0
	waves.default_color = Color(0.3, 0.6, 1.0, 0.8)
	add_child(waves)

	# Vertikale Wasser-Linien (Fluss-Effekt)
	for i in range(5):
		var line := Line2D.new()
		var x := -zone_size.x * 0.4 + i * zone_size.x * 0.2
		line.points = [
			Vector2(x, -zone_size.y * 0.5),
			Vector2(x + 10, zone_size.y * 0.5)
		]
		line.width = 2.0
		line.default_color = Color(0.4, 0.7, 1.0, 0.4)
		add_child(line)

	# "WASSER" Label
	var label := Label.new()
	label.text = "WATER"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.8, 0.8))
	label.position = Vector2(-zone_size.x * 0.5 + 10, zone_size.y * 0.5 - 35)
	add_child(label)

	# Collision Shape
	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	cshape.shape = rect_shape
	add_child(cshape)
