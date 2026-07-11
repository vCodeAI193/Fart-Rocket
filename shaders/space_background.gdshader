shader_type canvas_item;
// FR-281: Prozeduraler Weltraum-Hintergrund (Nebel + funkelnde Sterne)

uniform vec4 nebula_color_a : source_color = vec4(0.15, 0.05, 0.35, 1.0);
uniform vec4 nebula_color_b : source_color = vec4(0.02, 0.05, 0.15, 1.0);
uniform float star_density : hint_range(0.0, 1.0) = 0.5;
uniform float time_scale : hint_range(0.0, 2.0) = 0.15;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV * 3.0;
	float t = TIME * time_scale;

	// Wolkiger Nebel aus mehreren Noise-Oktaven
	float n = noise(uv + t) * 0.5 + noise(uv * 2.1 - t * 0.5) * 0.3 + noise(uv * 4.3 + t * 0.2) * 0.2;
	vec4 col = mix(nebula_color_b, nebula_color_a, clamp(n, 0.0, 1.0));

	// Funkelnde Sterne
	vec2 star_uv = UV * 40.0;
	vec2 star_id = floor(star_uv);
	float star_val = hash(star_id);
	if (star_val > (1.0 - star_density * 0.05)) {
		float twinkle = 0.5 + 0.5 * sin(TIME * 3.0 + star_val * 30.0);
		vec2 local = fract(star_uv) - 0.5;
		float d = length(local);
		float star_glow = smoothstep(0.15, 0.0, d) * twinkle;
		col.rgb += vec3(star_glow);
	}

	COLOR = col;
}
