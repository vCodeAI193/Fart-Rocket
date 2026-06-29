extends Area2D
class_name IceZone
## IceZone – Glattzonen mit reduzierter Reibung (FR-029)
## =======================================================
## Eine rutschige Zone, die den linearen_damp reduziert,
## so dass der Spieler rutschig/glatt wird.

@export var ice_friction: float = 0.1
@export var color: Color = Color(0.7, 0.95, 1.0, 0.25)
@export var zone_size: Vector2 = Vector2(300, 200)

var _original_damp: float = 0.0
var _players_in_zone: int = 0


func _ready() -> void:
	add_to_group("hazards")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_visual()


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.size = zone_size
	rect.position = -zone_size * 0.5
	rect.color = color
	add_child(rect)

	var border := Line2D.new()
	var points := [
		Vector2(-zone_size.x * 0.5, -zone_size.y * 0.5),
		Vector2(zone_size.x * 0.5, -zone_size.y * 0.5),
		Vector2(zone_size.x * 0.5, zone_size.y * 0.5),
		Vector2(-zone_size.x * 0.5, zone_size.y * 0.5),
		Vector2(-zone_size.x * 0.5, -zone_size.y * 0.5),
	]
	border.points = points
	border.width = 3.0
	border.default_color = Color(0.4, 0.8, 1.0, 0.8)
	add_child(border)

	# Eis-Kristall-Muster
	for i in range(5):
		var x := -zone_size.x * 0.35 + (i + 1) * zone_size.x * 0.17
		var crystal := _draw_ice_crystal(x, -zone_size.y * 0.25, 10)
		add_child(crystal)

	var label := Label.new()
	label.text = "EIS"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 0.8))
	label.position = Vector2(-zone_size.x * 0.5 + 10, zone_size.y * 0.5 - 40)
	add_child(label)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = zone_size
	cshape.shape = rect_shape
	add_child(cshape)


func _draw_ice_crystal(cx: float, cy: float, size: float) -> Line2D:
	var crystal := Line2D.new()
	crystal.width = 2.0
	crystal.default_color = Color(0.8, 0.95, 1.0, 0.6)
	var points := []
	for i in range(6):
		var angle := TAU * i / 6.0
		points.append(Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * size)
	# Zurück zum Start für geschlossene Form
	points.append(points[0])
	crystal.points = points
	return crystal


func _on_area_entered(area: Area2D) -> void:
	if area is Player or area.owner is Player:
		if _players_in_zone == 0:
			_original_damp = area.linear_damp if area is RigidBody2D else area.owner.linear_damp
			if area is RigidBody2D:
				area.linear_damp = ice_friction
			else:
				area.owner.linear_damp = ice_friction
		_players_in_zone += 1


func _on_area_exited(area: Area2D) -> void:
	if area is Player or area.owner is Player:
		_players_in_zone -= 1
		if _players_in_zone <= 0:
			_players_in_zone = 0
			if area is RigidBody2D:
				area.linear_damp = _original_damp
			else:
				area.owner.linear_damp = _original_damp
