shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.055, 0.065, 0.085, 1.0);
uniform vec4 line_color : source_color = vec4(0.12, 0.14, 0.18, 1.0);
uniform vec4 accent_color : source_color = vec4(0.16, 0.20, 0.26, 1.0);
uniform float cell_size = 64.0;
uniform float major_every = 4.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 coord = world_pos / cell_size;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float minor = 1.0 - min(min(grid.x, grid.y), 1.0);

	vec2 major_coord = world_pos / (cell_size * major_every);
	vec2 major_grid = abs(fract(major_coord - 0.5) - 0.5) / fwidth(major_coord);
	float major = 1.0 - min(min(major_grid.x, major_grid.y), 1.0);

	vec3 col = mix(base_color.rgb, line_color.rgb, minor * 0.7);
	col = mix(col, accent_color.rgb, major);
	COLOR = vec4(col, 1.0);
}
