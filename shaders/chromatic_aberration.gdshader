shader_type canvas_item;
// FR-288: Chromatische Aberration bei hohem Tempo (RGB-Kanal-Versatz)

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float aberration_strength : hint_range(0.0, 0.02) = 0.0;

void fragment() {
	vec2 dir = normalize(SCREEN_UV - vec2(0.5)) * aberration_strength;
	float r = texture(screen_texture, SCREEN_UV + dir).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV - dir).b;
	float a = texture(screen_texture, SCREEN_UV).a;
	COLOR = vec4(r, g, b, a);
}
