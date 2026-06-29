extends StaticBody2D
## Obstacle – Hindernisse
## ======================
## Ein konfigurierbares Hindernis mit drei Formen:
##  - BALKEN  : rechteckiger Balken
##  - STACHELN: eine Reihe spitzer Stacheln
##  - SAEGE   : rotierendes Sägeblatt
## Visuals und Kollisionsform werden passend zum Typ im Code erzeugt.
## Alle Hindernisse sind in der Gruppe "obstacles" (Player stirbt bei Kontakt).

enum ObstacleType { BALKEN, STACHELN, SAEGE }

# --- Export-Variablen -------------------------------------------
@export var type: ObstacleType = ObstacleType.BALKEN
@export var obstacle_size: Vector2 = Vector2(200, 40)  # Größe für Balken/Stacheln
@export var saw_radius: float = 70.0                    # Radius für Sägeblatt
@export var rotation_speed: float = 3.0                 # Drehgeschwindigkeit der Säge (rad/s)
@export var obstacle_color: Color = Color(0.55, 0.55, 0.6)  # graue Färbung


func _ready() -> void:
	add_to_group("obstacles")
	match type:
		ObstacleType.BALKEN:
			_build_bar()
		ObstacleType.STACHELN:
			_build_spikes()
		ObstacleType.SAEGE:
			_build_saw()


func _physics_process(delta: float) -> void:
	# Nur das Sägeblatt dreht sich
	if type == ObstacleType.SAEGE:
		rotation += rotation_speed * delta


# --- Balken -----------------------------------------------------
func _build_bar() -> void:
	var half := obstacle_size * 0.5
	# Sichtbares Rechteck
	var poly := Polygon2D.new()
	poly.color = obstacle_color
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	add_child(poly)
	# Kollisionsform
	var shape := RectangleShape2D.new()
	shape.size = obstacle_size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


# --- Stacheln ---------------------------------------------------
func _build_spikes() -> void:
	var half := obstacle_size * 0.5
	var spike_count := int(maxf(2.0, obstacle_size.x / 40.0))
	var spike_w := obstacle_size.x / float(spike_count)
	var points := PackedVector2Array()
	# Untere Kante von links nach rechts ...
	points.append(Vector2(-half.x, half.y))
	# ... mit nach oben gerichteten Zacken
	for i in range(spike_count):
		var base_x := -half.x + spike_w * i
		points.append(Vector2(base_x, half.y))
		points.append(Vector2(base_x + spike_w * 0.5, -half.y))  # Spitze
		points.append(Vector2(base_x + spike_w, half.y))
	points.append(Vector2(half.x, half.y))

	var poly := Polygon2D.new()
	poly.color = obstacle_color
	poly.polygon = points
	add_child(poly)

	# Kollisionsform folgt exakt der Zacken-Form
	var col := CollisionPolygon2D.new()
	col.polygon = points
	add_child(col)


# --- Sägeblatt --------------------------------------------------
func _build_saw() -> void:
	var teeth := 12
	var points := PackedVector2Array()
	for i in range(teeth * 2):
		var a := TAU * float(i) / float(teeth * 2)
		# abwechselnd äußerer und innerer Radius -> Sägezähne
		var r := saw_radius if i % 2 == 0 else saw_radius * 0.78
		points.append(Vector2(cos(a), sin(a)) * r)

	var poly := Polygon2D.new()
	poly.color = obstacle_color
	poly.polygon = points
	add_child(poly)

	# Mittelpunkt (dunkler Kreis) als Deko
	var hub := Polygon2D.new()
	hub.color = obstacle_color.darkened(0.3)
	var hub_pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		hub_pts.append(Vector2(cos(a), sin(a)) * (saw_radius * 0.25))
	hub.polygon = hub_pts
	add_child(hub)

	# Runde Kollisionsform
	var shape := CircleShape2D.new()
	shape.radius = saw_radius * 0.92
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
