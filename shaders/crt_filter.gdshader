shader_type canvas_item;
// FR-282: Optionaler CRT-/Retro-Bildschirmfilter (Scanlines + Vignette + leichte Krümmung)

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float curvature : hint_range(0.0, 0.3) = 0.08;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec2 uv = SCREEN_UV;
	// Leichte Bildschirm-Krümmung
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + curvature * dot(centered, centered);
	uv = centered * 0.5 + 0.5;

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	vec4 col = texture(screen_texture, uv);

	// Scanlines
	float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
	col.rgb -= scanline * scanline_intensity * 0.15;

	// Vignette
	float vig = 1.0 - vignette_strength * dot(centered, centered) * 0.5;
	col.rgb *= vig;

	COLOR = col;
}
