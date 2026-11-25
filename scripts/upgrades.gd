class_name Upgrades
extends RefCounted

## Catálogo de mejoras. Combina estadísticas generales con las mejoras de
## cada arma numérica (subir de nivel o desbloquear un arma nueva).

const LIST := [
	{"id": "damage", "title": "Potencia +15%", "desc": "Las armas infligen un 15% más de daño.", "max_stacks": 8},
	{"id": "precision", "title": "Precisión +8%", "desc": "Reduce el error numérico de todas las armas.", "max_stacks": 6},
	{"id": "attack_speed", "title": "Cadencia +12%", "desc": "Las armas atacan un 12% más rápido.", "max_stacks": 8},
	{"id": "move_speed", "title": "Movilidad", "desc": "+12 de velocidad al moverte.", "max_stacks": 5},
	{"id": "max_health", "title": "Vitalidad", "desc": "+20 de vida máxima y cura 20.", "max_stacks": 8},
	{"id": "pickup", "title": "Magnetismo", "desc": "+25 de radio de recogida de XP.", "max_stacks": 5},
	{"id": "projectiles", "title": "Multidisparo", "desc": "+1 proyectil por ataque.", "max_stacks": 4},
	{"id": "pierce", "title": "Perforación", "desc": "Los proyectiles atraviesan +1 enemigo.", "max_stacks": 4},
	{"id": "regen", "title": "Regeneración", "desc": "+0.4 de vida por segundo.", "max_stacks": 5},
	{"id": "armor", "title": "Blindaje", "desc": "Reduce 1 el daño recibido por golpe.", "max_stacks": 5},
]

const STAT_WEIGHT := 1.0
const LEVEL_WEIGHT := 3.0
const NEW_WEAPON_WEIGHT := 4.0

## Texto corto que se dibuja dentro del icono circular de cada estadística.
const STAT_BADGES := {
	"damage": "DMG",
	"precision": "PRC",
	"attack_speed": "SPD",
	"move_speed": "MOV",
	"max_health": "HP",
	"pickup": "MAG",
	"projectiles": "PRJ",
	"pierce": "PEN",
	"regen": "REG",
	"armor": "ARM",
}

static func stat_badge(id: String) -> String:
	return String(STAT_BADGES.get(id, "UP"))

static func get_info(id: String) -> Dictionary:
	for entry in LIST:
		if entry.id == id:
			return entry
	return {}

static func build_choices(player: Player, count: int) -> Array[Dictionary]:
	var stat_pool: Array = []
	for entry in LIST:
		var stacks := int(player.upgrade_stacks.get(entry.id, 0))
		if stacks < int(entry.max_stacks):
			stat_pool.append({
				"kind": "stat",
				"id": String(entry.id),
				"title": String(entry.title),
				"desc": String(entry.desc),
				"weight": STAT_WEIGHT,
				"color": Color(0.45, 0.85, 1.0),
				"level": stacks + 1,
				"max_level": int(entry.max_stacks),
				"evolved": false,
				"stat_id": String(entry.id),
			})

	var level_pool: Array = []
	for weapon in player.weapons:
		if weapon.is_maxed():
			continue
		var next_level := weapon.level + 1
		var title := "%s  ·  Nv %d → %d" % [WeaponCatalog.display_name(weapon.weapon_id), weapon.level, next_level]
		if next_level >= Weapon.MAX_LEVEL:
			title = "EVOLUCIÓN · %s" % WeaponCatalog.evolution_name(weapon.weapon_id)
		level_pool.append({
			"kind": "weapon_level",
			"id": weapon.weapon_id,
			"title": title,
			"desc": WeaponCatalog.level_description(weapon.weapon_id, weapon.level),
			"weight": LEVEL_WEIGHT,
			"color": WeaponCatalog.color_of(weapon.weapon_id, next_level >= Weapon.MAX_LEVEL),
			"level": next_level,
			"max_level": Weapon.MAX_LEVEL,
			"evolved": next_level >= Weapon.MAX_LEVEL,
		})

	var new_pool: Array = []
	if player.weapons.size() < Player.MAX_WEAPONS:
		for id in WeaponCatalog.ids():
			if player.has_weapon(id):
				continue
			new_pool.append({
				"kind": "weapon_new",
				"id": id,
				"title": "NUEVA ARMA — %s" % WeaponCatalog.display_name(id),
				"desc": WeaponCatalog.new_weapon_description(id),
				"weight": NEW_WEAPON_WEIGHT,
				"color": WeaponCatalog.color_of(id),
				"level": 1,
				"max_level": Weapon.MAX_LEVEL,
				"evolved": false,
			})

	var pool: Array = []
	pool.append_array(stat_pool)
	pool.append_array(level_pool)
	pool.append_array(new_pool)

	var result: Array[Dictionary] = []

	# Garantiza un arma nueva mientras el jugador tenga menos de 3.
	if player.weapons.size() < 3 and not new_pool.is_empty():
		var forced: Dictionary = new_pool[randi() % new_pool.size()]
		result.append(forced)
		var filtered: Array = []
		for entry in pool:
			if entry.kind == "weapon_new" and entry.id == forced.id:
				continue
			filtered.append(entry)
		pool = filtered

	while result.size() < count and not pool.is_empty():
		var total := 0.0
		for entry in pool:
			total += float(entry.weight)
		var roll := randf() * total
		var chosen := pool.size() - 1
		for i in pool.size():
			roll -= float(pool[i].weight)
			if roll <= 0.0:
				chosen = i
				break
		result.append(pool[chosen])
		pool.remove_at(chosen)

	return result
