shader_type canvas_item;
// FR-421/433: Farbenblind-Assistenz — verschiebt schwer unterscheidbare
// Farbpaare (Rot/Grün bzw. Blau/Gelb) auseinander, damit Kontraste für
// Spieler mit Farbfehlsichtigkeit besser erkennbar werden.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform int mode : hint_range(0, 3) = 0;  // 0=aus, 1=Protanopia, 2=Deuteranopia, 3=Tritanopia

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	if (mode == 0) {
		COLOR = col;
		return;
	}
	vec3 c = col.rgb;
	vec3 result = c;
	if (mode == 1) {
		// Protanopia-Hilfe: Rot-Grün-Unterschiede in den Blaukanal spreizen
		result.r = c.r * 0.6 + c.g * 0.4;
		result.b = clamp(c.b + (c.r - c.g) * 0.35, 0.0, 1.0);
	} else if (mode == 2) {
		// Deuteranopia-Hilfe: analog, mit vertauschten Kanälen
		result.g = c.g * 0.6 + c.r * 0.4;
		result.b = clamp(c.b + (c.g - c.r) * 0.35, 0.0, 1.0);
	} else if (mode == 3) {
		// Tritanopia-Hilfe: Blau-Gelb-Unterschiede in den Rotkanal spreizen
		result.b = c.b * 0.5 + c.g * 0.5;
		result.r = clamp(c.r + (c.b - c.g) * 0.3, 0.0, 1.0);
	}
	COLOR = vec4(clamp(result, 0.0, 1.0), col.a);
}
