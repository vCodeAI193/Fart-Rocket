extends Node2D
## Starfield – einfacher Sternenhimmel
## ===================================
## Zeichnet einmalig zufällige weiße Punkte als Sterne über den
## Weltraum-Farbverlauf. Liegt auf einem CanvasLayer und bewegt
## sich daher nicht mit der Kamera.

@export var star_count: int = 90
@export var area: Vector2 = Vector2(1920, 1200)

var _stars: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(star_count):
		_stars.append({
			"pos": Vector2(rng.randf() * area.x, rng.randf() * area.y),
			"r": rng.randf_range(1.0, 3.0),
			"a": rng.randf_range(0.3, 1.0),
		})
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		draw_circle(s["pos"], s["r"], Color(1, 1, 1, s["a"]))
