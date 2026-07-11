shader_type canvas_item;
// FR-289: Dunkelheits-/Sichtkegel-Shader — als abdunkelndes Overlay über
// ein ColorRect gelegt. Nur ein Radius um light_center bleibt hell.

uniform vec2 light_center = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 1.0) = 0.3;
uniform float softness : hint_range(0.0, 0.5) = 0.15;
uniform float darkness : hint_range(0.0, 1.0) = 0.92;

void fragment() {
	float dist = distance(SCREEN_UV, light_center);
	float visibility = 1.0 - smoothstep(radius - softness, radius, dist);
	float alpha = mix(darkness, 0.0, visibility);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
