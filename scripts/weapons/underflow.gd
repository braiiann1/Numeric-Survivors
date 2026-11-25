class_name UnderflowWeapon
extends Weapon

## Underflow: cada partícula arranca con magnitud 1 y decae exponencialmente.
## El daño que inflige es proporcional a su magnitud actual, así que al final
## de su recorrido apenas roza a los enemigos antes de desaparecer.

const PARTICLE_SCENE := preload("res://scenes/effects/underflow_particle.tscn")

func _init() -> void:
	weapon_id = "underflow"

func _tick(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _find_nearest_enemy(620.0)
	if target == null:
		_cooldown = 0.15
		return
	_fire(target)
	_cooldown = _fire_interval()

func _fire_interval() -> float:
	return maxf(0.25, (1.35 - 0.07 * float(level - 1)) / attack_rate())

func _particle_count() -> int:
	var count := 3 + int(floorf(float(level) * 0.6)) + extra_projectiles()
	if is_maxed():
		count += 4
	return count

func _base_damage() -> float:
	return (4.0 + 1.2 * float(level - 1)) * damage_scale()

func _decay() -> float:
	var value := 1.7 - 0.13 * float(level - 1) - precision() * 0.35
	return maxf(0.22, value)

func _min_magnitude() -> float:
	return maxf(0.02, 0.18 - 0.02 * float(level))

func _pierce() -> int:
	var base := 0
	if is_maxed():
		base = 3
	elif level >= 5:
		base = 1
	return base + extra_pierce()

func _fire(target: Enemy) -> void:
	var base_dir := (target.global_position - global_position).normalized()
	var count := _particle_count()
	var spread := deg_to_rad(30.0)
	var container := _effects_container()
	Sfx.play("underflow", -19.0, randf_range(0.95, 1.1))
	for i in count:
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var offset := spread * (t - 0.5)
		var jitter := randf_range(-0.03, 0.03)
		var dir := base_dir.rotated(offset + jitter)
		var particle := PARTICLE_SCENE.instantiate() as UnderflowParticle
		if particle == null:
			continue
		container.add_child(particle)
		particle.global_position = global_position + dir * 16.0
		particle.setup(
			dir,
			260.0 + 12.0 * float(level),
			_base_damage(),
			1.0,
			_decay(),
			_min_magnitude(),
			2.0 + 0.12 * float(level),
			_pierce(),
			weapon_color()
		)
