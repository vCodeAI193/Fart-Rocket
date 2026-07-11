shader_type canvas_item;
// FR-285: Outline-Shader für wichtige Objekte (Levelziel, Bosse, Schwachstellen).
// Da dieses Projekt rein prozedural aus Polygon2D/Line2D besteht (keine
// Textur-Sprites), funktioniert die klassische "Alpha-Nachbar"-Outline-
// Technik nicht (texturlose Polygone liefern konstante Textur-Alpha-Werte).
// Stattdessen wird ein pulsierender Rand-Glanz nahe der UV-Randzone der
// Bounding-Box erzeugt. COLOR wird dabei NICHT per texture(TEXTURE, UV)
// neu bestimmt, sondern die eingehende COLOR (bereits interpolierte
// Vertex-/Polygonfarbe) beibehalten — sonst würden texturlose Polygone
// zu Weiß statt ihrer eigentlichen Farbe (z.B. die grüne Zielflagge).

uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float outline_width : hint_range(0.0, 0.5) = 0.12;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	// Abstand zum nächsten UV-Rand (0 oder 1) je Achse
	float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float rim = 1.0 - smoothstep(0.0, outline_width, edge_dist);
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	COLOR.rgb = mix(COLOR.rgb, outline_color.rgb, rim * pulse * outline_color.a);
}
