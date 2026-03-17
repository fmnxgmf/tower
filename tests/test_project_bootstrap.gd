extends RefCounted

func run() -> Array[String]:
    var failures: Array[String] = []
    var required_paths := [
        "res://project.godot",
        "res://scenes/main.tscn",
        "res://scripts/game_manager.gd",
        "res://scripts/pathfinding.gd",
        "res://scripts/game_map.gd",
        "res://scripts/enemy_base.gd",
        "res://scripts/tower_base.gd",
        "res://scripts/projectile.gd",
        "res://scripts/wave_spawner.gd"
    ]

    for path in required_paths:
        if not FileAccess.file_exists(path):
            failures.append("missing required file %s" % path)

    return failures

