extends RefCounted

func run() -> Array[String]:
    var failures: Array[String] = []
    var game_manager_script = load("res://scripts/game_manager.gd")
    if game_manager_script == null:
        failures.append("game_manager.gd did not load")
        return failures

    var manager = game_manager_script.new()
    if manager == null:
        failures.append("game manager could not be instantiated")
        return failures

    if not manager.has_method("reset"):
        failures.append("GameManager is missing reset()")
    if not manager.has_method("can_afford"):
        failures.append("GameManager is missing can_afford()")
    if not manager.has_method("spend_gold"):
        failures.append("GameManager is missing spend_gold()")
    if not manager.has_method("damage_base"):
        failures.append("GameManager is missing damage_base()")

    var pathfinding_script = load("res://scripts/pathfinding.gd")
    if pathfinding_script == null:
        failures.append("pathfinding.gd did not load")
        return failures

    var pathfinding = pathfinding_script.new()
    if pathfinding == null:
        failures.append("Pathfinding could not be instantiated")
        return failures

    if not pathfinding.has_method("setup"):
        failures.append("Pathfinding is missing setup()")
    if not pathfinding.has_method("find_path"):
        failures.append("Pathfinding is missing find_path()")
    if not pathfinding.has_method("can_place_tower"):
        failures.append("Pathfinding is missing can_place_tower()")
    if not pathfinding.has_method("set_blocked"):
        failures.append("Pathfinding is missing set_blocked()")

    var wave_spawner_script = load("res://scripts/wave_spawner.gd")
    if wave_spawner_script == null:
        failures.append("wave_spawner.gd did not load")
        return failures

    var spawner = wave_spawner_script.new()
    if spawner == null:
        failures.append("WaveSpawner could not be instantiated")
        return failures

    if not spawner.has_method("build_default_waves"):
        failures.append("WaveSpawner is missing build_default_waves()")

    if failures.is_empty():
        manager.reset()
        if manager.gold != 500:
            failures.append("expected reset gold to be 500")
        if manager.health != 20:
            failures.append("expected reset health to be 20")
        if not manager.can_afford(100):
            failures.append("expected starting gold to afford 100")
        if manager.spend_gold(600):
            failures.append("should not spend more gold than available")
        manager.damage_base(3)
        if manager.health != 17:
            failures.append("damage_base should subtract health")

        pathfinding.setup(Vector2i(20, 15), Vector2i.ZERO, Vector2i(19, 14))
        var path: Array = pathfinding.find_path(Vector2i.ZERO, Vector2i(19, 14), false)
        if path.is_empty():
            failures.append("expected ground path on empty grid")
        if not pathfinding.can_place_tower(Vector2i(10, 7)):
            failures.append("expected open tile to be buildable")
        if pathfinding.can_place_tower(Vector2i.ZERO):
            failures.append("start tile should not be buildable")
        for y in range(15):
            if y == 14:
                continue
            pathfinding.set_blocked(Vector2i(1, y), true)
        if pathfinding.can_place_tower(Vector2i(1, 14)):
            failures.append("placing the final blocking tower should be rejected")

        var waves = spawner.build_default_waves()
        if waves.size() != 10:
            failures.append("expected exactly 10 default waves")
        elif waves[0].is_empty():
            failures.append("expected first wave to contain enemy definitions")

    return failures
