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

    var localization_script = load("res://scripts/localization_manager.gd")
    if localization_script == null:
        failures.append("localization_manager.gd did not load for persistence test")
    else:
        var localization = localization_script.new()
        localization.current_language = "zh"
        localization.set_language("en", true)
        var localization_reloaded = localization_script.new()
        localization_reloaded.load_language()
        if localization_reloaded.get_language() != "en":
            failures.append("saved language should reload as English")
        localization_reloaded.set_language("zh", true)

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

    var tree := Engine.get_main_loop() as SceneTree
    var test_root := Node2D.new()
    tree.root.add_child(test_root)
    var aoe_tower_scene = load("res://scenes/towers/aoe_tower.tscn")
    var enemy_script = load("res://scripts/enemy_base.gd")
    if aoe_tower_scene == null:
        failures.append("aoe_tower.tscn did not load")
    elif enemy_script == null:
        failures.append("enemy_base.gd did not load for aoe test")
    else:
        var aoe_tower = aoe_tower_scene.instantiate()
        var primary_enemy = enemy_script.new()
        var splash_enemy = enemy_script.new()
        test_root.add_child(aoe_tower)
        test_root.add_child(primary_enemy)
        test_root.add_child(splash_enemy)

        aoe_tower.global_position = Vector2.ZERO
        aoe_tower.damage = 12.0
        aoe_tower.attack_range = 100.0
        aoe_tower.configure_attack("aoe")

        primary_enemy.max_health = 30.0
        primary_enemy.current_health = 30.0
        primary_enemy.global_position = Vector2(20, 0)
        primary_enemy.add_to_group("enemies")

        splash_enemy.max_health = 30.0
        splash_enemy.current_health = 30.0
        splash_enemy.global_position = Vector2(45, 0)
        splash_enemy.add_to_group("enemies")

        aoe_tower._attack(primary_enemy)
        var debug_state: Dictionary = aoe_tower.get_attack_debug_state()
        if primary_enemy.current_health >= 30.0:
            failures.append("aoe tower should damage its primary target")
        if splash_enemy.current_health >= 30.0:
            failures.append("aoe tower should damage nearby enemies in splash radius")
        if float(debug_state.get("effect_time_left", 0.0)) <= 0.0:
            failures.append("aoe tower should expose an active visual effect after attacking")

    if is_instance_valid(test_root):
        test_root.queue_free()

    return failures