extends Node2D
class_name FloatingText
## FloatingText – schwebender Punktetext
## =======================================
## FR-275: Zeigt kurz einen Text (z.B. "+50") an einer Weltposition,
## der nach oben schwebt und ausblendet.

var _display_text: String = ""
var _display_color: Color = Color.WHITE


## Erstellt und startet einen schwebenden Text an `world_pos`.
static func spawn(parent: Node, world_pos: Vector2, text: String,
		col: Color = Color(1.0, 0.9, 0.3)) -> void:
	var node := FloatingText.new()
	node._display_text = text
	node._display_color = col
	node.global_position = world_pos
	node.z_index = 20
	parent.add_child(node)
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "global_position:y", world_pos.y - 95.0, 0.75)
	tween.tween_property(node, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(node.queue_free)


func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(0, 0), _display_text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 38, _display_color)
