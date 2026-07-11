shader_type canvas_item;
// FR-290: Tag-/Nacht-Verlauf-Shader — als Tint-Overlay über den Hintergrund
// gelegt (ColorRect), unabhängig von TEXTURE/UV des darunterliegenden Inhalts.

uniform vec4 night_tint : source_color = vec4(0.1, 0.12, 0.35, 0.35);
uniform float cycle_progress : hint_range(0.0, 1.0) = 0.0; // 0=Tag, 1=Nacht

void fragment() {
	COLOR = vec4(night_tint.rgb, night_tint.a * cycle_progress);
}
