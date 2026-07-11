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

# --- FR-060: Geste zum Zurücksetzen der Kamera (schneller Zwei-Finger-Tipp)
var _two_finger_start_time: float = -1.0
var _two_finger_start_positions: Dictionary = {}
var _two_finger_moved: bool = false


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_finger_positions[event.index] = event.position
			if _finger_positions.size() == 2:
				_two_finger_start_time = Time.get_ticks_msec() / 1000.0
				_two_finger_start_positions = _finger_positions.duplicate()
				_two_finger_moved = false
		else:
			# FR-060: Prüfen, ob dies ein schneller Zwei-Finger-Tipp war
			if _finger_positions.size() == 2 and not _two_finger_moved:
				_try_reset_camera_gesture()
			_finger_positions.erase(event.index)
			_last_distance = 0.0

	elif event is InputEventScreenDrag and _finger_positions.size() >= 2:
		_finger_positions[event.index] = event.position
		# Merken, falls sich die Finger nennenswert bewegt haben (kein Tipp mehr)
		if _two_finger_start_positions.has(event.index):
			var moved := _two_finger_start_positions[event.index].distance_to(event.position)
			if moved > 24.0:
				_two_finger_moved = true
		_update_zoom()
		get_tree().root.set_input_as_handled()


## FR-060: Setzt Zoom zurück, wenn beide Finger innerhalb 0.25s ohne
## nennenswerte Bewegung wieder losgelassen wurden (Zwei-Finger-Tipp).
func _try_reset_camera_gesture() -> void:
	if _two_finger_start_time < 0.0:
		return
	var elapsed := Time.get_ticks_msec() / 1000.0 - _two_finger_start_time
	if elapsed < 0.25:
		var tween := create_tween()
		tween.tween_property(self, "zoom", Vector2.ONE, 0.25)
		GameManager.camera_reset_requested.emit()
	_two_finger_start_time = -1.0


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
