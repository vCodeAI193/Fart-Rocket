extends Node2D
class_name ParallaxStarfield
## ParallaxStarfield – Parallax-Hintergrund-Sterne
## =================================================
## FR-188: Sterne in Weltkoordinaten mit eigenem Parallax-Faktor.
## Bewegt sich langsamer als die Kamera → Tiefeneffekt.

@export var parallax_ratio: float = 0.2   # 0 = fest, 1 = mit Kamera
@export var star_count: int = 80
@export var field_width: float = 7000.0
@export var field_height: float = 3000.0

var _star_positions: Array[Vector2] = []
var _star_radii: Array[float] = []
var _star_alphas: Array[float] = []


func _ready() -> void:
	z_index = -200  # Hinter allem
	var rng := RandomNumberGenerator.new()
	rng.seed = 98765
	for _i in range(star_count):
		_star_positions.append(Vector2(
			rng.randf_range(-500.0, field_width),
			rng.randf_range(-field_height * 0.5, field_height * 0.5)
		))
		_star_radii.append(rng.randf_range(1.0, 3.5))
		_star_alphas.append(rng.randf_range(0.25, 0.85))
	queue_redraw()


func _draw() -> void:
	for i in range(_star_positions.size()):
		draw_circle(_star_positions[i], _star_radii[i],
			Color(0.85, 0.9, 1.0, _star_alphas[i]))
