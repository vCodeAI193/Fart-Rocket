shader_type canvas_item;
// FR-279: Gravitationslinsen-Verzerrung um ein schwarzes Loch — verwirbelt
// den bereits gezeichneten Bildschirminhalt (Hintergrund + Loch selbst)
// radial um den Node-Mittelpunkt.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float swirl_strength : hint_range(0.0, 15.0) = 6.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = clamp(length(centered) * 2.0, 0.0, 1.0);
	float angle = swirl_strength * (1.0 - dist) * (1.0 - dist);
	float s = sin(angle);
	float c = cos(angle);
	vec2 rotated = vec2(centered.x * c - centered.y * s, centered.x * s + centered.y * c);
	vec2 offset = (rotated - centered) * 0.05;
	COLOR = texture(screen_texture, SCREEN_UV + offset);
}
