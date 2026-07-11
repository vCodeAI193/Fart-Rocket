shader_type canvas_item;
// FR-294: Motion Blur (Geschwindigkeits-Unschärfe) — Screen-Space,
// Richtung/Stärke werden von Main.gd anhand der Spielergeschwindigkeit gesetzt.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec2 blur_direction = vec2(0.0, 0.0);  // normierte Richtung * Stärke
uniform int samples : hint_range(2, 12) = 6;

void fragment() {
	vec4 col = vec4(0.0);
	for (int i = 0; i < samples; i++) {
		float t = (float(i) / float(samples - 1)) - 0.5;
		col += texture(screen_texture, SCREEN_UV + blur_direction * t);
	}
	col /= float(samples);
	COLOR = col;
}
