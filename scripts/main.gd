extends Node2D

const TOWER_DEFS := {
    "basic": {"label": "Basic $100", "cost": 100},
    "slow": {"label": "Slow $150", "cost": 150},
    "aoe": {"label": "AOE $200", "cost": 200},
    "sniper": {"label": "Sniper $250", "cost": 250}
}

@onready var gold_label: Label = $UI/Panel/TopBar/GoldLabel
@onready var health_label: Label = $UI/Panel/TopBar/HealthLabel
@onready var wave_label: Label = $UI/Panel/TopBar/WaveLabel
@onready var status_label: Label = $UI/Panel/StatusLabel
@onready var start_wave_button: Button = $UI/Panel/BottomBar/StartWaveButton
@onready var pause_button: Button = $UI/Panel/BottomBar/PauseButton
@onready var tower_button_container: HBoxContainer = $UI/Panel/BottomBar/TowerButtons
@onready var game_map: Node2D = $GameMap
@onready var tower_container: Node2D = $TowerContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var wave_spawner: Node = $WaveSpawner

var selected_tower_type: String = "basic"
var tower_scenes := {
    "basic": preload("res://scenes/towers/basic_tower.tscn"),
    "slow": preload("res://scenes/towers/slow_tower.tscn"),
    "aoe": preload("res://scenes/towers/aoe_tower.tscn"),
    "sniper": preload("res://scenes/towers/sniper_tower.tscn")
}

func _ready() -> void:
    GameManager.reset()
    _build_tower_buttons()
    _connect_game_manager()
    wave_spawner.wave_started.connect(_on_wave_started)
    wave_spawner.wave_completed.connect(_on_wave_completed)
    wave_spawner.all_waves_completed.connect(_on_all_waves_completed)
    start_wave_button.pressed.connect(_on_start_wave_pressed)
    pause_button.pressed.connect(_on_pause_pressed)
    _refresh_ui()
    status_label.text = "Select a tower, build on the grid, then start the wave."

func _build_tower_buttons() -> void:
    for child: Node in tower_button_container.get_children():
        child.queue_free()
    for tower_type: String in TOWER_DEFS.keys():
        var button := Button.new()
        button.text = TOWER_DEFS[tower_type].label
        button.pressed.connect(func() -> void: selected_tower_type = tower_type)
        tower_button_container.add_child(button)

func _connect_game_manager() -> void:
    GameManager.gold_changed.connect(func(_value: int) -> void: _refresh_ui())
    GameManager.health_changed.connect(func(_value: int) -> void: _refresh_ui())
    GameManager.wave_changed.connect(func(_value: int) -> void: _refresh_ui())
    GameManager.game_over.connect(_on_game_over)

func _refresh_ui() -> void:
    gold_label.text = "Gold: %d" % GameManager.gold
    health_label.text = "Health: %d" % GameManager.health
    wave_label.text = "Wave: %d/%d" % [GameManager.current_wave, GameManager.TOTAL_WAVES]
    pause_button.text = "Resume" if GameManager.game_state == "PAUSED" else "Pause"

func _unhandled_input(event: InputEvent) -> void:
    if GameManager.game_state in ["WIN", "LOSE"]:
        return
    if event is InputEventMouseMotion:
        var cell: Vector2i = game_map.world_to_cell(event.position)
        var valid: bool = game_map.is_inside_map(cell) and game_map.can_build_at(cell) and GameManager.can_afford(TOWER_DEFS[selected_tower_type].cost)
        game_map.update_preview(cell, valid)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _try_build_at(event.position)

func _try_build_at(world_pos: Vector2) -> void:
    var cell: Vector2i = game_map.world_to_cell(world_pos)
    if not game_map.is_inside_map(cell):
        return
    var data: Dictionary = TOWER_DEFS[selected_tower_type]
    if not GameManager.can_afford(int(data.cost)):
        status_label.text = "Not enough gold for %s." % selected_tower_type.capitalize()
        return
    if not game_map.can_build_at(cell):
        status_label.text = "That placement would block the path."
        return
    var tower = tower_scenes[selected_tower_type].instantiate()
    tower_container.add_child(tower)
    tower.global_position = game_map.cell_to_world(cell)
    tower.setup(projectile_container)
    game_map.occupy_cell(cell)
    GameManager.spend_gold(int(data.cost))
    for enemy: Node in get_tree().get_nodes_in_group("enemies"):
        if enemy.has_method("update_path"):
            enemy.update_path()
    status_label.text = "%s built." % selected_tower_type.capitalize()

func _on_start_wave_pressed() -> void:
    if wave_spawner.start_next_wave():
        start_wave_button.disabled = true
        GameManager.begin_wave(wave_spawner.current_wave_index + 1)
        GameManager.add_gold(50)

func _on_pause_pressed() -> void:
    var paused: bool = GameManager.game_state != "PAUSED"
    GameManager.set_paused(paused)
    _refresh_ui()

func spawn_enemy(enemy_type: String) -> void:
    var scene: PackedScene = wave_spawner.enemy_scenes[enemy_type]
    var enemy = scene.instantiate()
    enemy_container.add_child(enemy)
    enemy.setup_enemy(game_map, _enemy_data(enemy_type))
    enemy.reached_goal.connect(func() -> void: GameManager.damage_base(1))
    enemy.enemy_died.connect(func(reward: int) -> void: GameManager.add_gold(reward))

func _enemy_data(enemy_type: String) -> Dictionary:
    match enemy_type:
        "tank":
            return {"health": 300.0, "speed": 50.0, "reward": 30, "color": Color(0.45, 0.45, 0.45)}
        "flying":
            return {"health": 80.0, "speed": 100.0, "reward": 20, "flying": true, "color": Color(0.25, 0.5, 0.95)}
        "regen":
            return {"health": 150.0, "speed": 80.0, "reward": 25, "regen": 5.0, "color": Color(0.7, 0.3, 0.8)}
        _:
            return {"health": 50.0, "speed": 150.0, "reward": 10, "color": Color(0.2, 0.8, 0.2)}

func _on_wave_started(wave_number: int) -> void:
    status_label.text = "Wave %d started." % wave_number

func _on_wave_completed(wave_number: int) -> void:
    status_label.text = "Wave %d cleared." % wave_number
    start_wave_button.disabled = false

func _on_all_waves_completed() -> void:
    if get_tree().get_nodes_in_group("enemies").is_empty():
        GameManager.finish_level()

func _on_game_over(won: bool) -> void:
    start_wave_button.disabled = true
    status_label.text = "Victory!" if won else "Defeat!"
