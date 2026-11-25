class_name WeaponCatalog
extends RefCounted

## Catálogo de las 6 armas numéricas.
## Cada arma tiene 8 niveles: los 7 primeros son mejoras y el 8 es la evolución.

const ORDER := ["truncation", "absorption", "underflow", "overflow", "cancellation", "nan"]

const WEAPONS := {
	"truncation": {
		"name": "Truncamiento",
		"full_name": "Truncamiento y redondeo",
		"phenomenon": "Aproximación de reales a números representables",
		"summary": "Proyectiles con desvío de redondeo que la precisión corrige.",
		"color": Color(0.45, 0.85, 1.0),
		"evolved_color": Color(0.55, 1.0, 0.95),
		"scene": "res://scenes/weapons/truncation.tscn",
		"evolution": "Doble Precisión",
		"levels": [
			"Proyectiles con desvío de redondeo; la precisión reduce el error.",
			"Precisión de representación: menos desvío angular.",
			"Cadencia mejorada y proyectiles más rápidos.",
			"Un proyectil adicional por ataque.",
			"Mayor precisión y daño por proyectil.",
			"Cadencia y velocidad aumentadas.",
			"Tercer proyectil y error de cuantización menor.",
			"Evolución — Doble Precisión: error despreciable, proyectiles perforantes y disparo extra.",
		],
	},
	"absorption": {
		"name": "Absorción",
		"full_name": "Absorción numérica",
		"phenomenon": "Pérdida de contribuciones pequeñas al sumarlas con grandes",
		"summary": "Acumula energía y libera ondas; las aportaciones pequeñas se pierden.",
		"color": Color(0.45, 0.95, 0.6),
		"evolved_color": Color(0.78, 1.0, 0.36),
		"scene": "res://scenes/weapons/absorption.tscn",
		"evolution": "Acumulador Compensado",
		"levels": [
			"Acumula contribuciones y libera una onda; las pequeñas se pierden.",
			"Mayor mantisa: conserva contribuciones más pequeñas.",
			"Acumulación más rápida y ondas más amplias.",
			"Más daño por contribución.",
			"Suma compensada: recupera parte de lo absorbido.",
			"Mayor precisión y radio de liberación.",
			"El acumulador conserva casi todas las contribuciones.",
			"Evolución — Acumulador Compensado: Kahan conserva todo; la onda crece sin pérdida.",
		],
	},
	"underflow": {
		"name": "Underflow",
		"full_name": "Underflow",
		"phenomenon": "Desbordamiento por debajo del rango representable",
		"summary": "Partículas que se encogen hasta desaparecer.",
		"color": Color(0.5, 0.72, 1.0),
		"evolved_color": Color(0.68, 0.55, 1.0),
		"scene": "res://scenes/weapons/underflow.tscn",
		"evolution": "Lluvia Subnormal",
		"levels": [
			"Partículas que se encogen: cuanto menor su magnitud, menos daño hacen.",
			"Mayor rango: tardan más en desaparecer.",
			"Partículas más rápidas y numerosas.",
			"Conservación de subnormales: más daño al final del recorrido.",
			"Mayor vida media y daño inicial.",
			"Más partículas por disparo.",
			"Las partículas atraviesan un enemigo.",
			"Evolución — Lluvia Subnormal: muchas partículas mínimas que persisten y perforan.",
		],
	},
	"overflow": {
		"name": "Overflow",
		"full_name": "Overflow",
		"phenomenon": "Desbordamiento por encima del rango representable",
		"summary": "Explosiones que crecen hasta desbordar.",
		"color": Color(1.0, 0.6, 0.25),
		"evolved_color": Color(1.0, 0.36, 0.48),
		"scene": "res://scenes/weapons/overflow.tscn",
		"evolution": "Exponencial Escalada",
		"levels": [
			"Explosiones que duplican su daño; al desbordar, pierden fuerza.",
			"Escalado numérico: sube el umbral de desbordamiento.",
			"Más daño base y radio.",
			"El desbordamiento tarda más en aparecer.",
			"Explosiones más frecuentes y escaladas.",
			"Mayor umbral y daño; el residuo duele más.",
			"Casi nunca desborda; el crecimiento se mantiene.",
			"Evolución — Exponencial Escalada: daño enorme sin desbordar y radio devastador.",
		],
	},
	"cancellation": {
		"name": "Cancelación",
		"full_name": "Cancelación catastrófica",
		"phenomenon": "Pérdida de cifras significativas al restar números muy próximos",
		"summary": "Dos ondas que se cancelan y dejan un residuo.",
		"color": Color(0.95, 0.55, 0.6),
		"evolved_color": Color(1.0, 0.9, 0.55),
		"scene": "res://scenes/weapons/cancellation.tscn",
		"evolution": "Diferencia Estable",
		"levels": [
			"Dos ondas casi iguales se restan; el residuo es mínimo e inestable.",
			"Más bits: el residuo deja de redondearse a cero.",
			"Haz más ancho y residuo mayor.",
			"Cálculo más frecuente y estable.",
			"La diferencia conserva más cifras.",
			"Órbitas más rápidas y haz letal.",
			"Residuo casi estable; el ruido disminuye.",
			"Evolución — Diferencia Estable: reformulación exacta; haz limpio y devastador.",
		],
	},
	"nan": {
		"name": "NaN",
		"full_name": "NaN",
		"phenomenon": "Aparición de un valor no numérico",
		"summary": "Zonas de distorsión con efectos impredecibles.",
		"color": Color(0.75, 0.4, 1.0),
		"evolved_color": Color(0.45, 1.0, 0.9),
		"scene": "res://scenes/weapons/nan.tscn",
		"evolution": "Dominio Definido",
		"levels": [
			"Zonas de distorsión impredecibles: a veces no dañan, a veces mucho.",
			"Detección de operaciones inválidas: más tiradas válidas.",
			"Zonas más grandes y duraderas.",
			"Daño válido más alto y mejor control.",
			"Las zonas ralentizan con más fuerza.",
			"Mayor control y frecuencia.",
			"Casi todas las operaciones están definidas.",
			"Evolución — Dominio Definido: zonas estables, amplias y daño predecible.",
		],
	},
}

static func ids() -> Array[String]:
	var result: Array[String] = []
	for id in ORDER:
		result.append(String(id))
	return result

static func get_data(id: String) -> Dictionary:
	return WEAPONS.get(id, {})

static func display_name(id: String) -> String:
	var data := get_data(id)
	return String(data.get("name", id))

static func evolution_name(id: String) -> String:
	var data := get_data(id)
	return String(data.get("evolution", ""))

## Color base del arma o color de evolución si `evolved` es true.
static func color_of(id: String, evolved := false) -> Color:
	var data := get_data(id)
	if data.is_empty():
		return Color.WHITE
	if evolved:
		return data.get("evolved_color", data.get("color", Color.WHITE))
	return data.get("color", Color.WHITE)

static func new_weapon_description(id: String) -> String:
	var data := get_data(id)
	if data.is_empty():
		return ""
	return "%s.\n%s" % [data.phenomenon, data.summary]

static func level_description(id: String, current_level: int) -> String:
	var data := get_data(id)
	var levels: Array = data.get("levels", [])
	if current_level >= 0 and current_level < levels.size():
		return String(levels[current_level])
	return ""

static func create_weapon(id: String) -> Node2D:
	var data := get_data(id)
	if data.is_empty():
		return null
	var packed := load(String(data.scene)) as PackedScene
	if packed == null:
		return null
	return packed.instantiate() as Node2D
