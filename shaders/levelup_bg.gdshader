shader_type canvas_item;

// Fondo del menú de subida de nivel: degradado radial, anillos tenues,
// scanlines y grano. Se mantiene oscuro para que las cartas destaquen.

uniform vec4 base_color : source_color = vec4(0.025, 0.035, 0.07, 1.0);
uniform vec4 glow_color : source_color = vec4(0.16, 0.34, 0.62, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.55;
uniform float rings : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 c = (uv - vec2(0.5, 0.47)) * vec2(1.18, 1.0);
	float d = length(c);

	float glow = smoothstep(0.85, 0.0, d);
	float pulse = 0.5 + 0.5 * sin(TIME * 0.7);

	vec3 col = base_color.rgb;
	col += glow_color.rgb * glow * glow_strength * (0.75 + 0.25 * pulse);

	// Anillos concéntricos muy suaves.
	float ring = 0.5 + 0.5 * sin(d * 30.0 - TIME * 1.1);
	col += glow_color.rgb * ring * 0.02 * rings;

	// Scanlines y grano.
	col *= 0.965 + 0.035 * sin(uv.y * 460.0);
	float n = hash(uv * vec2(1280.0, 720.0) + fract(TIME) * 53.0);
	col += (n - 0.5) * 0.012;

	COLOR = vec4(col, 1.0);
}
