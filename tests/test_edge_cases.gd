extends RefCounted

func run() -> Array[String]:
    var failures: Array[String] = []

    var pathfinding = load("res://scripts/pathfinding.gd").new()
    pathfinding.setup(Vector2i(20, 15), Vector2i.ZERO, Vector2i(19, 14))
    if not pathfinding.find_path(Vector2i(-1, 0), Vector2i(19, 14), false).is_empty():
        failures.append("out-of-bounds start should not produce a path")
    if pathfinding.can_place_tower(Vector2i(-1, -1)):
        failures.append("out-of-bounds tile should not be buildable")
    if not pathfinding.has_method("invalidate_cache"):
        failures.append("pathfinding.gd is missing invalidate_cache()")

    var level_manager_script = load("res://scripts/level_manager.gd")
    var level_manager = level_manager_script.new()
    level_manager.set_save_path("user://edge_progress.cfg")
    level_manager.current_level_index = 999
    level_manager.save_progress()
    var reloaded = level_manager_script.new()
    reloaded.set_save_path("user://edge_progress.cfg")
    reloaded.load_progress()
    if reloaded.current_level_index != reloaded.levels.size() - 1:
        failures.append("saved progress should clamp to the last available level")

    var game_manager = load("res://scripts/game_manager.gd").new()
    game_manager.reset()
    game_manager.finish_level()
    game_manager.set_paused(true)
    if game_manager.game_state != "WIN":
        failures.append("pausing after victory should not override the win state")

    var main_script = load("res://scripts/main.gd")
    if main_script == null:
        failures.append("main.gd did not load for optimization checks")
        return failures

    var main = main_script.new()
    if not main.has_method("build_projectile_pool"):
        failures.append("main.gd is missing build_projectile_pool()")
    if not main.has_method("get_pooled_projectile"):
        failures.append("main.gd is missing get_pooled_projectile()")
    if not main.has_method("release_projectile"):
        failures.append("main.gd is missing release_projectile()")

    var wave_spawner = load("res://scripts/wave_spawner.gd").new()
    if not wave_spawner.has_method("get_tower_balance"):
        failures.append("wave_spawner.gd is missing get_tower_balance()")
    if not wave_spawner.has_method("get_enemy_balance"):
        failures.append("wave_spawner.gd is missing get_enemy_balance()")
    elif failures.is_empty():
        var basic_tower = wave_spawner.get_tower_balance("basic")
        var tank_enemy = wave_spawner.get_enemy_balance("tank")
        if basic_tower.is_empty():
            failures.append("expected basic tower balance data")
        if tank_enemy.is_empty():
            failures.append("expected tank enemy balance data")

    return failures
