shader_type canvas_item;
// FR-297: Schild-Energie-Shader — hexagonales Energiefeld-Muster mit Pulsieren

uniform vec4 shield_color : source_color = vec4(0.3, 0.7, 1.0, 0.5);
uniform float hex_scale : hint_range(1.0, 30.0) = 12.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;

float hex_dist(vec2 p) {
	p = abs(p);
	float c = dot(p, normalize(vec2(1.0, 1.73)));
	c = max(c, p.x);
	return c;
}

void fragment() {
	vec2 uv = (UV - 0.5) * hex_scale;
	vec2 cell = fract(uv) - 0.5;
	float d = hex_dist(cell);
	float hex_line = smoothstep(0.48, 0.5, d);

	float pulse = 0.6 + 0.4 * sin(TIME * pulse_speed);
	float edge_dist = distance(UV, vec2(0.5));
	float rim = smoothstep(0.35, 0.5, edge_dist);

	vec4 col = shield_color;
	col.a *= (0.3 + hex_line * 0.5 + rim * 0.4) * pulse;
	COLOR = col;
}
