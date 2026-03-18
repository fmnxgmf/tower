extends RefCounted

var levels: Array[Dictionary] = [
    {
        "name_key": "level.grassland_gate",
        "starting_gold": 500,
        "starting_health": 20,
        "wave_bonus": 50,
        "waves": 10
    },
    {
        "name_key": "level.iron_crossroads",
        "starting_gold": 650,
        "starting_health": 18,
        "wave_bonus": 60,
        "waves": 10
    }
]
var current_level_index: int = 0
var save_path: String = "user://tower_progress.cfg"

func set_save_path(path: String) -> void:
    save_path = path

func get_current_level() -> Dictionary:
    if levels.is_empty():
        return {}
    return levels[clampi(current_level_index, 0, levels.size() - 1)].duplicate(true)

func advance_level() -> void:
    if current_level_index < levels.size() - 1:
        current_level_index += 1

func save_progress() -> void:
    var config := ConfigFile.new()
    config.set_value("progress", "current_level_index", current_level_index)
    config.save(save_path)

func load_progress() -> void:
    var config := ConfigFile.new()
    if config.load(save_path) == OK:
        current_level_index = int(config.get_value("progress", "current_level_index", 0))
    current_level_index = clampi(current_level_index, 0, max(levels.size() - 1, 0))