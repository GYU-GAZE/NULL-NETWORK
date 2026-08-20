shader_type canvas_item;

uniform vec2 reveal_center = vec2(0.5, 0.5);
uniform float reveal_radius : hint_range(0.0, 3.0, 0.001) = 0.0;
uniform float reveal_feather : hint_range(0.001, 0.1, 0.001) = 0.012;
uniform float aspect_ratio : hint_range(0.1, 4.0, 0.001) = 1.7777778;
uniform vec4 mask_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 delta = UV - reveal_center;
	delta.x *= aspect_ratio;
	float distance_from_center = length(delta);
	float outside_alpha = smoothstep(
		reveal_radius - reveal_feather,
		reveal_radius + reveal_feather,
		distance_from_center
	);
	COLOR = vec4(mask_color.rgb, mask_color.a * outside_alpha);
}
