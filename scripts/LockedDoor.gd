extends StaticBody2D
class_name LockedDoor
## LockedDoor – Verschlossene Tür (FR-091)
## =============================================
## Blockiert den Weg, bis der Spieler den passenden Schlüssel
## (gleiche key_id) eingesammelt hat. Öffnet sich dann dauerhaft.

@export var key_id: String = "gold"
@export var door_size: Vector2 = Vector2(30, 220)
@export var door_color: Color = Color(0.55, 0.4, 0.2)

var _is_open: bool = false
var _cshape: CollisionShape2D
var _door_visual: Node2D


func _ready() -> void:
	add_to_group("obstacles_neutral")  # blockiert physisch, ist aber nicht "tödlich"
	_build_visual()
	# Bereits vorher eingesammelt (z.B. nach Checkpoint-Respawn)?
	if GameManager.has_key(key_id):
		_open_door()


func _process(_delta: float) -> void:
	if not _is_open and GameManager.has_key(key_id):
		_open_door()


func _open_door() -> void:
	_is_open = true
	_cshape.disabled = true
	GameManager.vibrate(30)
	var tween := create_tween()
	tween.tween_property(_door_visual, "modulate:a", 0.15, 0.3)


func _build_visual() -> void:
	_door_visual = Node2D.new()
	add_child(_door_visual)

	var plank_count := int(door_size.y / 30.0)
	for i in range(plank_count):
		var y := -door_size.y * 0.5 + i * 30.0
		var plank := ColorRect.new()
		plank.size = Vector2(door_size.x, 26)
		plank.position = Vector2(-door_size.x * 0.5, y)
		plank.color = door_color
		_door_visual.add_child(plank)

	# Schloss-Symbol in der Mitte
	var lock := Polygon2D.new()
	lock.color = Color(1.0, 0.85, 0.2)
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	lock.polygon = pts
	_door_visual.add_child(lock)

	_cshape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = door_size
	_cshape.shape = rect_shape
	add_child(_cshape)
