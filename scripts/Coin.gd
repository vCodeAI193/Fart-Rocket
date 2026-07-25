extends Area2D
## Coin – einsammelbare Münze
## ==========================
## Eine gelbe, rotierende Münze. Berührt der Player sie, wird sie
## eingesammelt (Sound + kleine Einsammel-Animation) und die Punkte
## werden über den GameManager verbucht.

@export var coin_value: int = 10           # Punktwert dieser Münze
@export var spin_speed: float = 3.0        # Rotationsgeschwindigkeit (rad/s)
@export var collect_sound: AudioStream     # Platzhalter-Sound (im Editor setzbar)

signal collected(value)                    # Signal beim Einsammeln

var _collected: bool = false

@onready var _visual: Node2D = $Visual
@onready var _audio: AudioStreamPlayer = $CollectSound


func _ready() -> void:
	add_to_group("coins")
	body_entered.connect(_on_body_entered)
	if collect_sound != null:
		_audio.stream = collect_sound
	_build_coin_visual()


func _process(delta: float) -> void:
	# Münze "rotiert" durch horizontales Stauchen (2D-Münzeffekt)
	if not _collected:
		var s := absf(sin(Time.get_ticks_msec() / 1000.0 * spin_speed))
		_visual.scale.x = lerpf(0.2, 1.0, s)


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collect()


## Sammelt die Münze ein: Punkte verbuchen, Sound + Animation, dann löschen.
func _collect() -> void:
	_collected = true
	GameManager.add_coin(coin_value)
	GameManager.record_coin_pickup()  # FR-099: Sammel-Fortschritt
	collected.emit(coin_value)
	GameManager.vibrate(20)
	# FR-243 (F19): Tonhöhe steigt mit der Combo-Serie
	SoundManager.play_coin_pickup(GameManager.combo_count)
	if _audio.stream != null:
		_audio.play()

	# FR-275: Schwebenden Punktetext anzeigen
	var effective := coin_value * (2 if GameManager.double_coins_active else 1)
	FloatingText.spawn(get_parent(), global_position, "+%d" % effective)
	# FR-261: Goldener Partikel-Burst beim Einsammeln
	_spawn_collect_particles()

	# Kleine Einsammel-Animation: nach oben schweben und ausblenden
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "position:y", _visual.position.y - 60.0, 0.4)
	tween.tween_property(_visual, "scale", Vector2(1.6, 1.6), 0.4)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()


## FR-261: Goldener Partikel-Burst, der beim Einsammeln entsteht.
## F15: Umfang und Farbe wachsen mit der aktuellen Combo-Stufe — der
## Burst war zuvor bei jeder Münze identisch und damit kein Feedback
## darüber, wie gut die Sammel-Serie gerade läuft.
func _spawn_collect_particles() -> void:
	var combo := clampi(GameManager.combo_count, 1, GameManager.COMBO_MAX_MULTIPLIER)
	var combo_ratio := float(combo - 1) / float(maxi(1, GameManager.COMBO_MAX_MULTIPLIER - 1))
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	# FR-466: Menge folgt der Qualitätsstufe, F15: und der Combo-Stufe
	p.amount = GameManager.scaled_particle_amount(20 + int(combo_ratio * 24.0))
	p.lifetime = 0.7
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 200.0 + combo_ratio * 120.0
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0 + combo_ratio * 4.0
	# Höhere Combo -> von Gold Richtung Weiß-Glühen
	p.color = Color(1.0, 0.85, 0.15).lerp(Color(1.0, 1.0, 0.85), combo_ratio)
	# Partikel nach Lebensdauer entfernen (fire-and-forget)
	var lifetime := p.lifetime
	get_tree().create_timer(lifetime + 0.1).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)


# --- FR-081: Münzgrafik (Bronze/Silber/Gold je nach Wert) -------
func _build_coin_visual() -> void:
	var outer_col: Color
	var inner_col: Color
	if coin_value >= 50:         # Gold
		outer_col = Color(1.0, 0.82, 0.15)
		inner_col = Color(1.0, 0.93, 0.5)
	elif coin_value >= 25:       # Silber
		outer_col = Color(0.72, 0.72, 0.80)
		inner_col = Color(0.90, 0.90, 0.98)
	else:                        # Bronze
		outer_col = Color(0.78, 0.50, 0.22)
		inner_col = Color(0.95, 0.68, 0.42)
	var outer := Polygon2D.new()
	outer.color = outer_col
	var inner := Polygon2D.new()
	inner.color = inner_col
	var pts_outer := PackedVector2Array()
	var pts_inner := PackedVector2Array()
	var segments := 20
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		var d := Vector2(cos(a), sin(a))
		pts_outer.append(d * 24.0)
		pts_inner.append(d * 16.0)
	outer.polygon = pts_outer
	inner.polygon = pts_inner
	_visual.add_child(outer)
	_visual.add_child(inner)
