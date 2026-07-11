shader_type canvas_item;
// FR-270: Slow-Mo-Visualfilter — leichte Entsättigung + kühler Blauton
// + pulsierende Vignette, aktiv während Engine.time_scale < 1.0.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;  // 0=aus, 1=volle Wirkung
uniform vec4 tint : source_color = vec4(0.55, 0.7, 1.0, 1.0);

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(col.rgb, vec3(luma), strength * 0.6);
	vec3 tinted = mix(desaturated, desaturated * tint.rgb, strength);
	float vig = 1.0 - strength * 0.35 * distance(SCREEN_UV, vec2(0.5));
	COLOR = vec4(tinted * vig, col.a);
}
