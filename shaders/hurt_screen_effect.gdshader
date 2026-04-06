shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float radius = intensity * 5.0 * length(SCREEN_PIXEL_SIZE);
	vec4 acc = vec4(0.0);
	acc += texture(screen_texture, uv + vec2(-radius, -radius));
	acc += texture(screen_texture, uv + vec2(0.0, -radius));
	acc += texture(screen_texture, uv + vec2(radius, -radius));
	acc += texture(screen_texture, uv + vec2(-radius, 0.0));
	acc += texture(screen_texture, uv) * 2.0;
	acc += texture(screen_texture, uv + vec2(radius, 0.0));
	acc += texture(screen_texture, uv + vec2(-radius, radius));
	acc += texture(screen_texture, uv + vec2(0.0, radius));
	acc += texture(screen_texture, uv + vec2(radius, radius));
	acc /= 10.0;
	vec3 hurt_rgb = vec3(0.92, 0.1, 0.08);
	acc.rgb = mix(acc.rgb, hurt_rgb, intensity * 0.58);
	COLOR = vec4(acc.rgb, 1.0);
}
