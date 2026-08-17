shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.008, 0.047, 0.086, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.003, 0.019, 0.037, 1.0);
uniform vec4 grid_color : source_color = vec4(0.02, 0.31, 0.56, 0.12);
uniform float scanline_count = 360.0;
uniform float grid_size = 54.0;
uniform float vignette_strength = 0.48;

float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 base = mix(color_bottom.rgb, color_top.rgb, 1.0 - uv.y);
	float scanline = smoothstep(0.78, 1.0, fract(uv.y * scanline_count));
	float grid_x = smoothstep(0.965, 1.0, fract(uv.x * grid_size));
	float grid_y = smoothstep(0.965, 1.0, fract(uv.y * grid_size * 0.56));
	float noise = hash21(floor(uv * vec2(480.0, 270.0))) * 0.018;
	float vignette = 1.0 - smoothstep(0.22, 0.78, distance(uv, vec2(0.5)));
	vec2 data_cell = floor(uv * vec2(112.0, 64.0));
	float data_bit = step(0.986, hash21(data_cell));
	float side_field = smoothstep(0.18, 0.48, abs(uv.x - 0.5));
	float center_haze = 1.0 - smoothstep(0.0, 0.62, distance(uv, vec2(0.52, 0.46)));
	base += grid_color.rgb * (grid_x + grid_y) * grid_color.a;
	base += vec3(0.015, 0.25, 0.48) * data_bit * side_field * 0.32;
	base += vec3(0.0, 0.055, 0.11) * center_haze;
	base += vec3(noise);
	base *= 1.0 - scanline * 0.055;
	base *= mix(1.0 - vignette_strength, 1.0, vignette);
	COLOR = vec4(base, 1.0);
}
