shader_type canvas_item;
// FR-293: Furz-Wolken-Verzerrungs-Shader — moduliert die Alpha der
// einzelnen Partikel-Quads wellenförmig für einen "gasigen" Wabber-Look.
// Nutzt die bereits interpolierte COLOR (Partikel-Tint/Farbverlauf) statt
// erneut TEXTURE zu samplen, da texturlose Partikel sonst ihre Farbe
// verlieren würden (COLOR enthält beim Eintritt in fragment() bereits
// Textur * Vertexfarbe * Modulate).

uniform float distortion_strength : hint_range(0.0, 1.0) = 0.4;
uniform float speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	float wobble = sin(UV.y * 20.0 + TIME * speed) * 0.5 + 0.5;
	wobble *= cos(UV.x * 15.0 + TIME * speed * 0.8) * 0.5 + 0.5;
	COLOR.a *= mix(1.0 - distortion_strength, 1.0, wobble);
}
