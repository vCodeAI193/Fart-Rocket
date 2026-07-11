extends Area2D
class_name LavaPool
## LavaPool – glühender Lava-Tümpel
## ==================================
## FR-273: Ein statisches, tödliches Lava-Becken mit pulsierendem
## Glühen und Hitzeflimmern über der Oberfläche.

@export var pool_size: Vector2 = Vector2(360, 90)
@export var glow_color: Color = Color(1.0, 0.35, 0.05, 0.9)

var _glow_layers: Array[Polygon2D] = []
var _elapsed: float = 0.0


func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_build_visual()


func _process(delta: float) -> void:
	_elapsed += delta
	# FR-273: Pulsierendes Glühen der Lava-Oberfläche
	var pulse := 0.75 + 0.25 * sin(_elapsed * 2.2)
	for layer in _glow_layers:
		if is_instance_valid(layer):
			layer.modulate.a = pulse


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body._on_body_entered(self)


func _build_visual() -> void:
	# Lava-Becken-Grundfläche
	var base := Polygon2D.new()
	base.color = Color(0.55, 0.1, 0.02, 1.0)
	base.polygon = PackedVector2Array([
		Vector2(-pool_size.x * 0.5, -pool_size.y * 0.5),
		Vector2(pool_size.x * 0.5, -pool_size.y * 0.5),
		Vector2(pool_size.x * 0.5, pool_size.y * 0.5),
		Vector2(-pool_size.x * 0.5, pool_size.y * 0.5),
	])
	add_child(base)

	# Glühende Oberfläche (mehrere überlappende, pulsierende Blasen)
	for i in range(5):
		var glow := Polygon2D.new()
		glow.color = glow_color
		var cx := randf_range(-pool_size.x * 0.4, pool_size.x * 0.4)
		var r := randf_range(18.0, 34.0)
		var pts := PackedVector2Array()
		for j in range(10):
			var a := TAU * float(j) / 10.0
			pts.append(Vector2(cx + cos(a) * r, -pool_size.y * 0.35 + sin(a) * r * 0.5))
		glow.polygon = pts
		add_child(glow)
		_glow_layers.append(glow)

	# FR-273/284: Hitzeflimmer-Überlagerung über dem Becken (eigene Ebene,
	# damit die Lava selbst sichtbar bleibt statt vom Screen-Sample ersetzt
	# zu werden — gleiches Prinzip wie bei FlameJet).
	var shimmer_rect := Polygon2D.new()
	shimmer_rect.color = Color(1, 1, 1, 1)
	shimmer_rect.polygon = PackedVector2Array([
		Vector2(-pool_size.x * 0.5, -pool_size.y * 1.4),
		Vector2(pool_size.x * 0.5, -pool_size.y * 1.4),
		Vector2(pool_size.x * 0.5, -pool_size.y * 0.3),
		Vector2(-pool_size.x * 0.5, -pool_size.y * 0.3),
	])
	var shimmer_mat := ShaderMaterial.new()
	shimmer_mat.shader = load("res://shaders/heat_shimmer.gdshader")
	shimmer_rect.material = shimmer_mat
	add_child(shimmer_rect)

	# Kollisionsform
	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = pool_size
	cshape.shape = rect_shape
	add_child(cshape)
