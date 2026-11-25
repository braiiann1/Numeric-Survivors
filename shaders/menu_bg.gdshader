shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.03, 0.04, 0.07, 1.0);
uniform vec4 grid_color : source_color = vec4(0.10, 0.35, 0.50, 1.0);
uniform vec4 glow_color : source_color = vec4(0.10, 0.30, 0.50, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * vec2(42.0, 26.0);
	p.y += TIME * 0.65;
	vec2 g = abs(fract(p) - 0.5);
	float line = smoothstep(0.46, 0.5, max(g.x, g.y));
	vec3 col = bg_color.rgb + grid_color.rgb * line * 0.18;

	float glow = smoothstep(0.95, 0.0, length((uv - vec2(0.5, 0.42)) * vec2(1.25, 1.0)));
	col += glow_color.rgb * glow * 0.22;

	float scan = sin(uv.y * 900.0 + TIME * 2.0) * 0.5 + 0.5;
	col += vec3(0.012) * scan;
	COLOR = vec4(col, 1.0);
}
