shader_type canvas_item;
// FR-283: Wasser-Brechungs-Shader für Wasserzonen (verzerrter Hintergrund + Wellen)

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float wave_strength : hint_range(0.0, 0.05) = 0.015;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec4 water_tint : source_color = vec4(0.2, 0.5, 0.9, 0.25);

void fragment() {
	vec2 uv = SCREEN_UV;
	float wave = sin(uv.y * 30.0 + TIME * wave_speed) * wave_strength;
	wave += sin(uv.x * 20.0 - TIME * wave_speed * 0.7) * wave_strength * 0.6;
	vec2 distorted_uv = uv + vec2(wave, wave * 0.5);
	vec4 refracted = texture(screen_texture, distorted_uv);
	COLOR = mix(refracted, water_tint, water_tint.a);
}
