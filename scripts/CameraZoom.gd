extends Camera2D
class_name CameraZoom
## CameraZoom – Zwei-Finger-Zoom für Kamera (FR-041)
## =================================================
## Erkenne Zwei-Finger-Geste zum Zoomen der Kamera.

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 2.0

var _finger_positions: Dictionary = {}
var _last_distance: float = 0.0


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_finger_positions[event.index] = event.position
		else:
			_finger_positions.erase(event.index)
			_last_distance = 0.0

	elif event is InputEventScreenDrag and _finger_positions.size() >= 2:
		_finger_positions[event.index] = event.position
		_update_zoom()
		get_tree().root.set_input_as_handled()


func _update_zoom() -> void:
	if _finger_positions.size() < 2:
		return

	var positions := _finger_positions.values()
	var finger1 := positions[0]
	var finger2 := positions[1]
	var current_distance := finger1.distance_to(finger2)

	if _last_distance <= 0.0:
		_last_distance = current_distance
		return

	# Zoom basierend auf Finger-Abstand-Änderung
	var distance_ratio := current_distance / _last_distance
	var zoom_factor := zoom.x * distance_ratio
	zoom = Vector2.ONE * clampf(zoom_factor, min_zoom, max_zoom)

	_last_distance = current_distance
