extends Node2D

@export var damage: float = 10.0
@export var attack_range: float = 100.0
@export var attack_speed: float = 1.0
@export var cost: int = 100
@export var tower_color: Color = Color(0.4, 0.6, 0.9)
@export var tower_kind: String = "basic"
@export var projectile_scene: PackedScene

var cooldown: float = 0.0
var projectile_container: Node = null
var projectile_pool_owner: Node = null
var projectile_speed: float = 320.0
var slow_effect_multiplier: float = 1.0
var slow_effect_duration: float = 0.0
var splash_radius: float = 0.0
var use_projectile_attack: bool = true
var attack_count: int = 0

func _ready() -> void:
	configure_attack(tower_kind)
	queue_redraw()

func setup(projectiles_root: Node) -> void:
	projectile_container = projectiles_root
	if projectile_container != null and projectile_container.has_meta("pool_owner"):
		projectile_pool_owner = projectile_container.get_meta("pool_owner")

func configure_attack(new_tower_kind: String) -> void:
	tower_kind = new_tower_kind
	projectile_speed = 320.0
	slow_effect_multiplier = 1.0
	slow_effect_duration = 0.0
	splash_radius = 0.0
	use_projectile_attack = true
	match tower_kind:
		"slow":
			projectile_speed = 280.0
			slow_effect_multiplier = 0.5
			slow_effect_duration = 1.5
		"aoe":
			splash_radius = 50.0
			use_projectile_attack = false
		"sniper":
			projectile_speed = 420.0

func _process(delta: float) -> void:
	cooldown = max(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_attack(target)
	cooldown = 1.0 / max(attack_speed, 0.01)

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_distance_sq := INF
	var range_sq := attack_range * attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if bool(enemy.get("is_dying")):
			continue
		var distance_sq := global_position.distance_squared_to(enemy.global_position)
		if distance_sq <= range_sq and distance_sq < best_distance_sq:
			best = enemy
			best_distance_sq = distance_sq
	return best

func _attack(target: Node2D) -> void:
	attack_count += 1
	if splash_radius > 0.0:
		var aoe_range_sq := splash_radius * splash_radius
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and not bool(enemy.get("is_dying")) and enemy.global_position.distance_squared_to(target.global_position) <= aoe_range_sq:
				enemy.take_damage(damage)
		return

	if use_projectile_attack and _launch_projectile(target):
		return

	target.take_damage(damage)
	if slow_effect_duration > 0.0:
		target.apply_slow(slow_effect_multiplier, slow_effect_duration)

func _launch_projectile(target: Node2D) -> bool:
	if projectile_container == null:
		return false
	var projectile = null
	if projectile_pool_owner != null and projectile_pool_owner.has_method("get_pooled_projectile"):
		projectile = projectile_pool_owner.get_pooled_projectile()
	elif projectile_scene != null:
		projectile = projectile_scene.instantiate()
		projectile_container.add_child(projectile)
	if projectile == null:
		return false
	projectile.global_position = global_position
	projectile.show()
	projectile.launch(target, damage, projectile_speed, slow_effect_multiplier, slow_effect_duration)
	return true

func get_attack_debug_state() -> Dictionary:
	return {
		"tower_kind": tower_kind,
		"damage": damage,
		"attack_range": attack_range,
		"attack_speed": attack_speed,
		"projectile_speed": projectile_speed,
		"slow_effect_multiplier": slow_effect_multiplier,
		"slow_effect_duration": slow_effect_duration,
		"splash_radius": splash_radius,
		"use_projectile_attack": use_projectile_attack,
		"attack_count": attack_count,
		"has_projectile_container": projectile_container != null,
		"has_pool_owner": projectile_pool_owner != null,
		"target_found": _find_target() != null
	}

func _draw() -> void:
	draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), tower_color, true)
