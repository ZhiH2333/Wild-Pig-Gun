shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 5.0) = 3.4;
uniform float darken : hint_range(0.0, 0.92) = 0.78;

void fragment() {
	vec4 col = textureLod(screen_texture, SCREEN_UV, blur_lod);
	col.rgb *= (1.0 - darken);
	COLOR = vec4(col.rgb, 1.0);
}
