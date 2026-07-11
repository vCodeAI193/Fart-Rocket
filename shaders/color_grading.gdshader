shader_type canvas_item;
// FR-292: Farb-Grading pro Welt — Screen-Space-Farbkorrektur

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec3 color_balance = vec3(1.0, 1.0, 1.0);  // RGB-Multiplikator
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	col.rgb *= color_balance;
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(vec3(luma), col.rgb, saturation);
	col.rgb = (col.rgb - 0.5) * contrast + 0.5;
	COLOR = col;
}
