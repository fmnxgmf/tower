extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

const TOWER_BALANCE := {
    "basic": {"damage": 15.0, "range": 100.0, "speed": 1.0, "cost": 100, "info": "Balanced single-target tower."},
    "slow": {"damage": 5.0, "range": 80.0, "speed": 0.5, "cost": 150, "info": "Applies 50% slow for 1.5s."},
    "aoe": {"damage": 8.0, "range": 90.0, "speed": 1.5, "cost": 200, "info": "Damages enemies in a small blast radius."},
    "sniper": {"damage": 50.0, "range": 200.0, "speed": 0.33, "cost": 250, "info": "High damage, long range, slower fire rate."}
}

const ENEMY_BALANCE := {
    "fast": {"health": 50.0, "speed": 150.0, "reward": 10, "color": Color(0.2, 0.8, 0.2)},
    "tank": {"health": 300.0, "speed": 50.0, "reward": 30, "color": Color(0.45, 0.45, 0.45)},
    "flying": {"health": 80.0, "speed": 100.0, "reward": 20, "flying": true, "color": Color(0.25, 0.5, 0.95)},
    "regen": {"health": 150.0, "speed": 80.0, "reward": 25, "regen": 5.0, "color": Color(0.7, 0.3, 0.8)}
}

var waves: Array = []
var current_wave_index := -1
var pending_spawns: Array[String] = []
var spawn_interval := 0.6
var spawn_timer := 0.0
var active := false
var enemy_scenes := {}

func _ready() -> void:
    waves = build_default_waves()
    enemy_scenes = {
        "fast": preload("res://scenes/enemies/fast_enemy.tscn"),
        "tank": preload("res://scenes/enemies/tank_enemy.tscn"),
        "flying": preload("res://scenes/enemies/flying_enemy.tscn"),
        "regen": preload("res://scenes/enemies/regen_enemy.tscn")
    }

func get_tower_balance(tower_type: String) -> Dictionary:
    return TOWER_BALANCE.get(tower_type, {}).duplicate(true)

func get_enemy_balance(enemy_type: String) -> Dictionary:
    return ENEMY_BALANCE.get(enemy_type, {}).duplicate(true)

func build_default_waves() -> Array:
    return [
        [{"type": "fast", "count": 5}],
        [{"type": "fast", "count": 8}],
        [{"type": "tank", "count": 3}],
        [{"type": "fast", "count": 10}, {"type": "tank", "count": 2}],
        [{"type": "flying", "count": 5}],
        [{"type": "fast", "count": 12}, {"type": "tank", "count": 3}],
        [{"type": "flying", "count": 8}, {"type": "regen", "count": 2}],
        [{"type": "fast", "count": 15}, {"type": "tank", "count": 5}],
        [{"type": "flying", "count": 10}, {"type": "regen", "count": 5}],
        [{"type": "fast", "count": 20}, {"type": "tank", "count": 8}, {"type": "flying", "count": 5}, {"type": "regen", "count": 3}]
    ]

func start_next_wave() -> bool:
    if active:
        return false
    current_wave_index += 1
    if current_wave_index >= waves.size():
        all_waves_completed.emit()
        return false
    pending_spawns.clear()
    for group: Dictionary in waves[current_wave_index]:
        for _i in range(int(group["count"])):
            pending_spawns.append(String(group["type"]))
    spawn_timer = 0.0
    active = true
    wave_started.emit(current_wave_index + 1)
    return true

func _process(delta: float) -> void:
    if not active:
        return
    if pending_spawns.is_empty():
        if get_tree().get_nodes_in_group("enemies").is_empty():
            active = false
            wave_completed.emit(current_wave_index + 1)
            if current_wave_index == waves.size() - 1:
                all_waves_completed.emit()
        return
    spawn_timer -= delta
    if spawn_timer > 0.0:
        return
    spawn_timer = spawn_interval
    var enemy_type: String = pending_spawns.pop_front()
    if get_parent().has_method("spawn_enemy"):
        get_parent().spawn_enemy(enemy_type)
