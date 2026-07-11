extends Node2D
class_name CoinPath
## CoinPath – Schwebende Münz-Pfade als Wegweiser (FR-096)
## ==============================================================
## Erzeugt eine Reihe von Münzen entlang einer Kurve zwischen zwei
## Punkten, die dem Spieler visuell den empfohlenen Weg zeigen
## (z.B. durch enge Passagen oder zu einem versteckten Bereich).

@export var coin_scene: PackedScene
@export var start_point: Vector2 = Vector2.ZERO
@export var end_point: Vector2 = Vector2(400, -150)
@export var curve_height: float = 80.0  # Wölbung nach oben (Bogen-Pfad)
@export var coin_count: int = 6
@export var coin_value: int = 5


func _ready() -> void:
	if coin_scene == null:
		return
	for i in range(coin_count):
		var t := float(i) / float(maxi(1, coin_count - 1))
		var base := start_point.lerp(end_point, t)
		# Bogenförmiger Versatz (parabolisch, größte Wölbung in der Mitte)
		var arc_offset := -curve_height * 4.0 * t * (1.0 - t)
		var coin = coin_scene.instantiate()
		coin.position = base + Vector2(0, arc_offset)
		coin.coin_value = coin_value
		add_child(coin)
