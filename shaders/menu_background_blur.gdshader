shader_type canvas_item;

uniform float blur_strength : hint_range(0.5, 8.0) = 2.4;

void fragment() {
	vec2 px = blur_strength * TEXTURE_PIXEL_SIZE;
	vec4 acc = texture(TEXTURE, UV) * 4.0;
	acc += texture(TEXTURE, UV + vec2(px.x, 0.0));
	acc += texture(TEXTURE, UV - vec2(px.x, 0.0));
	acc += texture(TEXTURE, UV + vec2(0.0, px.y));
	acc += texture(TEXTURE, UV - vec2(0.0, px.y));
	acc += texture(TEXTURE, UV + vec2(px.x, px.y));
	acc += texture(TEXTURE, UV - vec2(px.x, px.y));
	acc += texture(TEXTURE, UV + vec2(px.x, -px.y));
	acc += texture(TEXTURE, UV - vec2(px.x, -px.y));
	COLOR = acc / 12.0;
}
