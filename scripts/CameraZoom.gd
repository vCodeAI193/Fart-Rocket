extends Camera2D
class_name CameraZoom
## CameraZoom – Zwei-Finger-Zoom für Kamera (FR-041)
## =================================================
## Erkenne Zwei-Finger-Geste zum Zoomen der Kamera. Der Nutzer-Zoom
## (Pinch-Geste) wird als Multiplikator `user_zoom_scale` gehalten,
## damit Main.gd ihn mit dynamischem Geschwindigkeits-/Zeitlupen-Zoom
## (FR-181/191) kombinieren kann, ohne sich gegenseitig zu überschreiben.

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 2.0

var user_zoom_scale: float = 1.0  # FR-041: vom Spieler per Pinch gesetzt

# --- FR-195: Foto-/Replay-Kameramodus -----------------------------
# Läuft auf PROCESS_MODE_ALWAYS, damit das Ein-Finger-Verschieben
# auch funktioniert, während das Spiel (und der Player) pausiert ist.
var photo_mode: bool = false
var _photo_pan_touch_index: int = -1
var _photo_pan_last_pos: Vector2 = Vector2.ZERO

var _finger_positions: Dictionary = {}
var _last_distance: float = 0.0

# --- FR-060: Geste zum Zurücksetzen der Kamera (schneller Zwei-Finger-Tipp)
var _two_finger_start_time: float = -1.0
var _two_finger_start_positions: Dictionary = {}
var _two_finger_moved: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	# FR-195: Im Foto-Modus steuert ein einzelner Finger das Verschieben
	if photo_mode:
		_handle_photo_pan(event)
		return

	# FR-426: Im Einhand-Modus sind Zwei-Finger-Gesten (Zoom/Reset) nicht
	# erreichbar — diese Verarbeitung komplett überspringen.
	if AccessibilityManager.one_handed_mode:
		return

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


## FR-195: Verschiebt die Kamera per Ein-Finger-Zug im Foto-Modus.
func _handle_photo_pan(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _photo_pan_touch_index == -1:
			_photo_pan_touch_index = event.index
			_photo_pan_last_pos = event.position
		elif not event.pressed and event.index == _photo_pan_touch_index:
			_photo_pan_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _photo_pan_touch_index:
		var delta_pos := event.position - _photo_pan_last_pos
		global_position -= delta_pos / zoom
		_photo_pan_last_pos = event.position


## FR-060: Setzt Zoom zurück, wenn beide Finger innerhalb 0.25s ohne
## nennenswerte Bewegung wieder losgelassen wurden (Zwei-Finger-Tipp).
func _try_reset_camera_gesture() -> void:
	if _two_finger_start_time < 0.0:
		return
	var elapsed := Time.get_ticks_msec() / 1000.0 - _two_finger_start_time
	if elapsed < 0.25:
		var tween := create_tween()
		tween.tween_property(self, "user_zoom_scale", 1.0, 0.25)
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

	# Zoom-Multiplikator basierend auf Finger-Abstand-Änderung
	var distance_ratio := current_distance / _last_distance
	user_zoom_scale = clampf(user_zoom_scale * distance_ratio, min_zoom, max_zoom)

	_last_distance = current_distance
