shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float scanline_count : hint_range(0.0, 1080.0) = 180.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.3;
uniform float aberration : hint_range(0.0, 0.02) = 0.0015;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Chromatic aberration
	vec4 col_r = texture(screen_texture, uv + vec2(aberration, 0.0));
	vec4 col_g = texture(screen_texture, uv);
	vec4 col_b = texture(screen_texture, uv - vec2(aberration, 0.0));
	vec4 color = vec4(col_r.r, col_g.g, col_b.b, 1.0);
	
	// Scanlines
	float scanline = sin(uv.y * scanline_count * 3.14159 * 2.0) * 0.5 + 0.5;
	color.rgb -= scanline * scanline_intensity;
	
	// Vignette
	vec2 center = uv - 0.5;
	float dist = dot(center, center);
	color.rgb *= (1.0 - dist * vignette_intensity);
	
	COLOR = color;
}
