shader_type canvas_item;
// FR-295: Sterne-Parallax-Shader — mehrschichtige, funkelnde Sterne
// direkt im Shader erzeugt (Ergänzung zur node-basierten ParallaxStarfield).

uniform vec2 camera_offset = vec2(0.0, 0.0);
uniform float layer_count : hint_range(1.0, 5.0) = 3.0;

float star_hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 12345.6);
}

void fragment() {
	vec3 col = vec3(0.0);
	for (float layer = 1.0; layer <= layer_count; layer += 1.0) {
		float parallax_factor = 0.15 * layer;
		vec2 uv = UV * (10.0 * layer) + camera_offset * parallax_factor * 0.001;
		vec2 cell = floor(uv);
		float star_val = star_hash(cell);
		if (star_val > 0.93) {
			vec2 local = fract(uv) - 0.5;
			float d = length(local);
			float twinkle = 0.5 + 0.5 * sin(TIME * (2.0 + star_val * 3.0) + star_val * 50.0);
			float glow = smoothstep(0.2, 0.0, d) * twinkle / layer;
			col += vec3(glow);
		}
	}
	COLOR = vec4(col, min(1.0, length(col)));
}
