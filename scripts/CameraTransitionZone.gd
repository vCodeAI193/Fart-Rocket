extends Area2D
class_name CameraTransitionZone
## CameraTransitionZone – Kamera-Übergänge zwischen Sektionen (FR-196)
## =========================================================================
## Betritt der Spieler diese Zone, wird die Kamera für eine kurze Zeit
## sanft auf einen festen Fokuspunkt (z.B. eine Übersicht über die
## nächste Sektion) gezogen, bevor sie wieder normal dem Spieler folgt.

@export var focus_point: Vector2 = Vector2.ZERO  # relativ zur Zonen-Position
@export var focus_zoom: float = 1.4
@export var transition_duration: float = 1.0
@export var hold_duration: float = 0.6
@export var one_shot: bool = true

var _triggered: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if _triggered and one_shot:
		return
	if area is Player or area.owner is Player:
		_triggered = true
		# Variant statt statischem Typ, da "main" nur per Duck-Typing angesprochen wird
		var main = get_tree().get_first_node_in_group("main_controller")
		if main != null and main.has_method("play_camera_transition"):
			main.play_camera_transition(global_position + focus_point, focus_zoom, transition_duration, hold_duration)
