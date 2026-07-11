shader_type canvas_item;
// FR-276: Diagonaler Wischeffekt beim Szenenwechsel — deckt den
// Bildschirm ab bzw. gibt ihn wieder frei, gesteuert über wipe_progress.

uniform float wipe_progress : hint_range(-0.1, 1.15) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);

void fragment() {
	float diag = (UV.x + UV.y) * 0.5;
	float alpha = wipe_color.a * (1.0 - smoothstep(wipe_progress - 0.08, wipe_progress, diag));
	COLOR = vec4(wipe_color.rgb, alpha);
}
