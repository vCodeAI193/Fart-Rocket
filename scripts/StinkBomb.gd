extends Area2D
class_name StinkBomb
## StinkBomb – Negatives Objekt, zieht Punkte ab (FR-098)
## ============================================================
## Ein unerwünschtes Sammelobjekt: berührt der Spieler es,
## werden Münzen abgezogen statt hinzugefügt (Risiko im Level-Design,
## z.B. absichtlich zwischen echten Münzen platziert).

@export var penalty: int = 20
@export var color: Color = Color(0.4, 0.6, 0.15)

var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	if not _collected:
		rotation += 0.8 * delta
		position.y += sin(Time.get_ticks_msec() * 0.004) * 0.15


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		var actual_penalty := mini(penalty, GameManager.total_coins)
		GameManager.total_coins -= actual_penalty
		GameManager.coins_changed.emit(GameManager.total_coins)
		GameManager.vibrate(50)
		if FloatingText:
			FloatingText.spawn(get_parent(), global_position, "-%d" % actual_penalty, Color(0.8, 0.3, 0.9))

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		await tween.finished
		queue_free()


func _build_visual() -> void:
	var body := Polygon2D.new()
	body.color = color
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var r := 16.0 if i % 2 == 0 else 12.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	body.polygon = pts
	add_child(body)

	# Stink-Wellen (kleine geschwungene Linien)
	for i in range(3):
		var wave := Line2D.new()
		var x := -10.0 + i * 10.0
		wave.points = [Vector2(x, -20), Vector2(x - 3, -28), Vector2(x + 3, -34)]
		wave.width = 2.0
		wave.default_color = Color(0.5, 0.7, 0.2, 0.6)
		add_child(wave)

	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	cshape.shape = circle
	add_child(cshape)
