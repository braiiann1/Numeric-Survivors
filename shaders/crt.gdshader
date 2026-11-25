shader_type canvas_item;

// Filtro CRT: curvatura de pantalla, aberración cromática, scanlines,
// viñeta, grano y un parpadeo muy leve. Se dibuja como overlay encima de
// todo (mundo + HUD) y muestrea el frame ya renderizado.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float curvature : hint_range(0.0, 0.25) = 0.05;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.16;
uniform float aberration : hint_range(0.0, 4.0) = 0.9;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.55;
uniform float grain : hint_range(0.0, 0.15) = 0.022;
uniform float flicker : hint_range(0.0, 0.1) = 0.01;
uniform float brightness : hint_range(0.5, 1.5) = 1.05;
uniform vec4 tint : source_color = vec4(0.95, 1.0, 1.04, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 curve_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
	uv += uv * offset * offset * curvature * 10.0;
	return uv * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(UV);
	vec3 col = vec3(0.0);

	// Fuera de la pantalla curvada: negro (bordes del tubo).
	bool inside = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;

	if (inside) {
		vec2 px = SCREEN_PIXEL_SIZE;
		col.r = texture(screen_tex, uv + vec2(aberration * px.x, 0.0)).r;
		col.g = texture(screen_tex, uv).g;
		col.b = texture(screen_tex, uv - vec2(aberration * px.x, 0.0)).b;

		// Scanlines: una línea oscura cada dos píxeles verticales.
		float screen_h = 1.0 / max(px.y, 0.000001);
		float lines = 0.5 + 0.5 * sin(uv.y * screen_h * 3.14159265);
		col *= 1.0 - scanline_strength * (1.0 - lines);

		// Viñeta.
		float dist = length(uv - vec2(0.5));
		float vig = smoothstep(0.86, 0.28, dist);
		col *= mix(1.0, vig, vignette_strength);

		// Grano animado.
		float n = hash(uv * vec2(1920.0, 1080.0) + fract(TIME) * 97.0);
		col += (n - 0.5) * grain;

		// Parpadeo y tinte frío de fósforo.
		col *= 1.0 + flicker * sin(TIME * 47.0);
		col *= brightness;
		col *= tint.rgb;
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
