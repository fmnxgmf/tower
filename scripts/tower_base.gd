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

func setup(projectiles_root: Node) -> void:
    projectile_container = projectiles_root
    if projectile_container != null and projectile_container.has_meta("pool_owner"):
        projectile_pool_owner = projectile_container.get_meta("pool_owner")

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
        var distance_sq := global_position.distance_squared_to(enemy.global_position)
        if distance_sq <= range_sq and distance_sq < best_distance_sq:
            best = enemy
            best_distance_sq = distance_sq
    return best

func _attack(target: Node2D) -> void:
    match tower_kind:
        "slow":
            target.take_damage(damage)
            target.apply_slow(0.5, 1.5)
        "aoe":
            var aoe_range_sq := 50.0 * 50.0
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if is_instance_valid(enemy) and enemy.global_position.distance_squared_to(target.global_position) <= aoe_range_sq:
                    enemy.take_damage(damage)
        _:
            if projectile_container != null:
                var projectile = null
                if projectile_pool_owner != null and projectile_pool_owner.has_method("get_pooled_projectile"):
                    projectile = projectile_pool_owner.get_pooled_projectile()
                elif projectile_scene != null:
                    projectile = projectile_scene.instantiate()
                    projectile_container.add_child(projectile)
                if projectile != null:
                    projectile.global_position = global_position
                    projectile.show()
                    projectile.launch(target, damage, 420.0 if tower_kind == "sniper" else 320.0, 1.0, 0.0)
                    return
            target.take_damage(damage)

func _draw() -> void:
    draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), tower_color, true)
