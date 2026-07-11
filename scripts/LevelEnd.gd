extends Area2D
class_name LevelEnd
## LevelEnd – die Ziel-Flagge
## =========================
## Eine Trigger-Zone mit Flaggen-Grafik. Erreicht der Player sie,
## wird das Level abgeschlossen (Signal "reached").

@export var win_sound: AudioStream         # Platzhalter-Sound beim Zielerreichen

signal reached                             # Level wurde abgeschlossen

var _done: bool = false

@onready var _audio: AudioStreamPlayer = $WinSound


func _ready() -> void:
	add_to_group("level_end")
	body_entered.connect(_on_body_entered)
	if win_sound != null:
		_audio.stream = win_sound
	_build_flag()


func _on_body_entered(body: Node) -> void:
	if _done:
		return
	if body.is_in_group("player"):
		_done = true
		if _audio.stream != null:
			_audio.play()
		reached.emit()


# --- Flaggen-Grafik (Mast + wehende Fahne) ----------------------
func _build_flag() -> void:
	# Mast
	var pole := Line2D.new()
	pole.width = 6.0
	pole.default_color = Color(0.85, 0.85, 0.9)
	pole.add_point(Vector2(0, -160))
	pole.add_point(Vector2(0, 80))
	add_child(pole)

	# Fahne (dreieckiges, kariertes Tuch in Grün)
	var flag := Polygon2D.new()
	flag.color = Color(0.3, 0.85, 0.4)
	flag.polygon = PackedVector2Array([
		Vector2(0, -160),
		Vector2(110, -125),
		Vector2(0, -90),
	])
	# FR-285: Explizites 0..1-UV-Mapping, damit der Outline-Shader
	# (rand-basierte Rim-Erkennung) korrekt funktioniert.
	flag.uv = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(1.0, 0.5), Vector2(0.0, 1.0),
	])
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = load("res://shaders/outline.gdshader")
	flag.material = outline_mat
	add_child(flag)
