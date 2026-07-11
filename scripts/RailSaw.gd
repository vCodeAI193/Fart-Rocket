extends Area2D
class_name RailSaw
## RailSaw – Kreissäge auf Schienen (FR-074)
## =============================================
## Eine Kreissäge, die einer festen Bahn aus mehreren Wegpunkten folgt
## (im Gegensatz zu SpikeRoller, der nur linear zwischen 2 Punkten fährt).

@export var waypoints: Array[Vector2] = [Vector2(0, 0), Vector2(300, 0), Vector2(300, 200), Vector2(0, 200)]
@export var move_speed: float = 140.0
@export var loop: bool = true
@export var saw_radius: float = 32.0
@export var color: Color = Color(0.6, 0.6, 0.62)

var _current_index: int = 0
var _saw_visual: Node2D
var _base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	# Der Platzierungspunkt im Editor dient als Ursprung (0,0) der Wegpunkte.
	_base_position = global_position
	if waypoints.size() > 0:
		global_position = _base_position + waypoints[0]
	_build_visual()


func _physics_process(delta: float) -> void:
	if waypoints.size() < 2:
		return

	var target := _base_position + waypoints[(_current_index + 1) % waypoints.size()]
	var to_target := target - global_position
	var step := move_speed * delta

	if to_target.length() <= step:
		global_position = target
		_current_index = (_current_index + 1) % waypoints.size()
		if not loop and _current_index == 0:
			_current_index = waypoints.size() - 2  # am Ende umkehren
	else:
		global_position += to_target.normalized() * step

	_saw_visual.rotation += (move_speed / saw_radius) * delta


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body._on_body_entered(self)


func _build_visual() -> void:
	_saw_visual = Node2D.new()
	add_child(_saw_visual)

	var teeth := 12
	var pts := PackedVector2Array()
	for i in range(teeth * 2):
		var a := TAU * float(i) / float(teeth * 2)
		var r := saw_radius if i % 2 == 0 else saw_radius * 0.75
		pts.append(Vector2(cos(a), sin(a)) * r)

	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = pts
	_saw_visual.add_child(poly)

	var hub := Polygon2D.new()
	hub.color = color.darkened(0.3)
	var hub_pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		hub_pts.append(Vector2(cos(a), sin(a)) * saw_radius * 0.25)
	hub.polygon = hub_pts
	_saw_visual.add_child(hub)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = saw_radius * 0.9
	cshape.shape = circle
	add_child(cshape)
