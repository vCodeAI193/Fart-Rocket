shader_type canvas_item;
// FR-298: Dissolve-Effekt bei Tod — Objekt löst sich per Noise-Schwelle
// auf, mit glühendem Rand. Nutzt FRAGCOORD (Bildschirm-Pixel) statt UV,
// damit das Muster über mehrere unterschiedlich geformte, texturlose
// Körperteile (Polygon2D/Line2D ohne eigenes UV-Mapping) hinweg
// zusammenhängend wirkt, und behält die eingehende COLOR (bereits
// interpolierte Vertexfarbe) statt sie durch eine Textur-Abtastung zu
// ersetzen, da sonst getönte/farbige Teile weiß würden.

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;  // 0=sichtbar, 1=weg
uniform vec4 edge_color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;

float dissolve_noise(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float n = dissolve_noise(floor(FRAGCOORD.xy * 0.15));
	float threshold = dissolve_amount;
	if (n < threshold) {
		discard;
	}
	float edge = smoothstep(threshold, threshold + edge_width, n);
	COLOR.rgb = mix(edge_color.rgb, COLOR.rgb, edge);
}
