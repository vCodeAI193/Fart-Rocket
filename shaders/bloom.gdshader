shader_type canvas_item;
// FR-287: Vereinfachter Bloom-Effekt (Bright-Pass + weiche Streuung)

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float threshold : hint_range(0.0, 1.0) = 0.65;
uniform float intensity : hint_range(0.0, 3.0) = 0.8;
uniform float spread : hint_range(0.0, 0.01) = 0.003;

void fragment() {
	vec4 base = texture(screen_texture, SCREEN_UV);
	vec3 glow = vec3(0.0);
	// 8 Abtastpunkte im Kreis für weichen Streu-Effekt
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.7854; // TAU/8
		vec2 offset = vec2(cos(angle), sin(angle)) * spread;
		vec4 sample_col = texture(screen_texture, SCREEN_UV + offset);
		float lum = dot(sample_col.rgb, vec3(0.299, 0.587, 0.114));
		if (lum > threshold) {
			glow += sample_col.rgb * (lum - threshold);
		}
	}
	glow *= intensity / 8.0;
	COLOR = vec4(base.rgb + glow, base.a);
}
