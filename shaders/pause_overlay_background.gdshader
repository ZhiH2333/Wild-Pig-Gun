shader_type canvas_item;

/// 仅用 LOD0 + 多点采样，避免 WebGL 上 screen_texture 的 mipmap / textureLod 整片黑。
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_radius : hint_range(0.0, 16.0) = 4.5;
uniform float darken : hint_range(0.0, 0.92) = 0.78;

void fragment() {
	vec2 px = blur_radius * SCREEN_PIXEL_SIZE;
	vec4 acc = texture(screen_texture, SCREEN_UV) * 4.0;
	acc += texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0));
	acc += texture(screen_texture, SCREEN_UV - vec2(px.x, 0.0));
	acc += texture(screen_texture, SCREEN_UV + vec2(0.0, px.y));
	acc += texture(screen_texture, SCREEN_UV - vec2(0.0, px.y));
	acc += texture(screen_texture, SCREEN_UV + vec2(px.x, px.y));
	acc += texture(screen_texture, SCREEN_UV - vec2(px.x, px.y));
	acc += texture(screen_texture, SCREEN_UV + vec2(px.x, -px.y));
	acc += texture(screen_texture, SCREEN_UV - vec2(px.x, -px.y));
	vec3 rgb = (acc.rgb / 12.0) * (1.0 - darken);
	COLOR = vec4(rgb, 1.0);
}
