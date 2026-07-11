shader_type canvas_item;
// FR-284: Hitzeflimmer-Shader für Lava/Flammen-Objekte

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float shimmer_strength : hint_range(0.0, 0.03) = 0.01;
uniform float shimmer_speed : hint_range(0.0, 10.0) = 4.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float offset_x = sin(uv.y * 40.0 + TIME * shimmer_speed) * shimmer_strength;
	float offset_y = sin(uv.x * 25.0 + TIME * shimmer_speed * 0.8) * shimmer_strength * 0.3;
	vec2 distorted_uv = uv + vec2(offset_x, offset_y);
	COLOR = texture(screen_texture, distorted_uv);
}
