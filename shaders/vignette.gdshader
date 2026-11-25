shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 1.3));
	float v = smoothstep(0.28, 0.82, d);
	COLOR = vec4(tint.rgb, v * intensity);
}
