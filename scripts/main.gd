extends Node2D

@onready var gold_label: Label = $UI/Panel/TopBar/GoldLabel
@onready var health_label: Label = $UI/Panel/TopBar/HealthLabel
@onready var wave_label: Label = $UI/Panel/TopBar/WaveLabel
@onready var level_label: Label = $UI/Panel/TopBar/LevelLabel
@onready var status_label: Label = $UI/Panel/StatusLabel
@onready var start_wave_button: Button = $UI/Panel/BottomBar/StartWaveButton
@onready var pause_button: Button = $UI/Panel/BottomBar/PauseButton
@onready var tower_button_container: HBoxContainer = $UI/Panel/BottomBar/TowerButtons
@onready var tower_info_panel: Panel = $UI/Panel/TowerInfoPanel
@onready var tower_info_label: Label = $UI/Panel/TowerInfoPanel/TowerInfoLabel
@onready var start_overlay: Control = $UI/StartOverlay
@onready var start_title_label: Label = $UI/StartOverlay/Center/StartTitleLabel
@onready var start_level_label: Label = $UI/StartOverlay/Center/StartLevelLabel
@onready var start_game_button: Button = $UI/StartOverlay/Center/StartGameButton
@onready var result_overlay: Control = $UI/ResultOverlay
@onready var result_label: Label = $UI/ResultOverlay/Center/ResultLabel
@onready var next_level_button: Button = $UI/ResultOverlay/Center/NextLevelButton
@onready var restart_button: Button = $UI/ResultOverlay/Center/RestartButton
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var resume_button: Button = $UI/PauseOverlay/Center/ResumeButton
@onready var game_map: Node2D = $GameMap
@onready var tower_container: Node2D = $TowerContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var wave_spawner = $WaveSpawner

var selected_tower_type: String = "basic"
var tower_scenes := {
    "basic": preload("res://scenes/towers/basic_tower.tscn"),
    "slow": preload("res://scenes/towers/slow_tower.tscn"),
    "aoe": preload("res://scenes/towers/aoe_tower.tscn"),
    "sniper": preload("res://scenes/towers/sniper_tower.tscn")
}
var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var projectile_pool: Array[Node2D] = []
var level_manager = preload("res://scripts/level_manager.gd").new()
var game_started: bool = false
var active_level_index: int = 0

func _ready() -> void:
    level_manager.load_progress()
    active_level_index = level_manager.current_level_index
    projectile_container.set_meta("pool_owner", self)
    build_projectile_pool(24)
    _build_tower_buttons()
    _connect_game_manager()
    wave_spawner.wave_started.connect(_on_wave_started)
    wave_spawner.wave_completed.connect(_on_wave_completed)
    wave_spawner.all_waves_completed.connect(_on_all_waves_completed)
    start_wave_button.pressed.connect(_on_start_wave_pressed)
    pause_button.pressed.connect(_on_pause_pressed)
    start_game_button.pressed.connect(_on_start_game_pressed)
    restart_button.pressed.connect(_restart_current_level)
    next_level_button.pressed.connect(_on_next_level_pressed)
    resume_button.pressed.connect(_resume_from_overlay)
    _select_tower("basic")
    _show_start_overlay()

func build_projectile_pool(pool_size: int = 16) -> void:
    while projectile_pool.size() < pool_size:
        var projectile = projectile_scene.instantiate()
        projectile.pool_owner = self
        projectile_container.add_child(projectile)
        projectile.reset_projectile()
        projectile_pool.append(projectile)

func get_pooled_projectile() -> Node2D:
    for projectile: Node2D in projectile_pool:
        if not projectile.active:
            return projectile
    var extra = projectile_scene.instantiate()
    extra.pool_owner = self
    projectile_container.add_child(extra)
    extra.reset_projectile()
    projectile_pool.append(extra)
    return extra

func release_projectile(projectile: Node2D) -> void:
    if projectile == null:
        return
    projectile.reset_projectile()

func _tower_defs() -> Dictionary:
    var defs := {}
    for tower_type in tower_scenes.keys():
        var balance = wave_spawner.get_tower_balance(tower_type)
        defs[tower_type] = {
            "label": "%s $%d" % [tower_type.capitalize(), int(balance.get("cost", 0))],
            "cost": int(balance.get("cost", 0)),
            "info": String(balance.get("info", ""))
        }
    return defs

func _show_start_overlay() -> void:
    var level_data: Dictionary = level_manager.get_current_level()
    start_overlay.visible = true
    result_overlay.visible = false
    pause_overlay.visible = false
    next_level_button.visible = false
    start_title_label.text = "Tower Defense"
    start_level_label.text = "Level: %s" % level_data.get("name", "Unknown")
    status_label.text = "Press Start Game to begin."
    GameManager.set_paused(false)
    get_tree().paused = false
    _refresh_ui()

func _start_level(level_index: int = -1) -> void:
    if level_index >= 0:
        level_manager.current_level_index = clampi(level_index, 0, level_manager.levels.size() - 1)
    active_level_index = level_manager.current_level_index
    var level_data: Dictionary = level_manager.get_current_level()
    _clear_battlefield()
    GameManager.reset()
    GameManager.gold = int(level_data.get("starting_gold", GameManager.STARTING_GOLD))
    GameManager.health = int(level_data.get("starting_health", GameManager.STARTING_HEALTH))
    GameManager.current_wave = 0
    GameManager.gold_changed.emit(GameManager.gold)
    GameManager.health_changed.emit(GameManager.health)
    GameManager.wave_changed.emit(GameManager.current_wave)
    wave_spawner.waves = wave_spawner.build_default_waves()
    wave_spawner.current_wave_index = -1
    wave_spawner.pending_spawns.clear()
    wave_spawner.active = false
    start_overlay.visible = false
    result_overlay.visible = false
    pause_overlay.visible = false
    game_started = true
    start_wave_button.disabled = false
    _refresh_ui()
    status_label.text = "Build your defenses for %s." % level_data.get("name", "this level")

func _clear_battlefield() -> void:
    for node: Node in tower_container.get_children():
        node.queue_free()
    for node: Node in enemy_container.get_children():
        node.queue_free()
    for projectile: Node2D in projectile_pool:
        release_projectile(projectile)
    game_map.tower_cells.clear()
    game_map.pathfinding.setup(game_map.GRID_SIZE, game_map.start_cell, game_map.end_cell)
    game_map.clear_preview()
    game_map.queue_redraw()

func _build_tower_buttons() -> void:
    var defs = _tower_defs()
    for child: Node in tower_button_container.get_children():
        child.queue_free()
    for tower_type: String in defs.keys():
        var button := Button.new()
        button.text = defs[tower_type].label
        button.pressed.connect(func() -> void: _select_tower(tower_type))
        tower_button_container.add_child(button)

func _select_tower(tower_type: String) -> void:
    selected_tower_type = tower_type
    var defs = _tower_defs()
    tower_info_label.text = "%s\n%s" % [defs[tower_type].label, defs[tower_type].info]

func _connect_game_manager() -> void:
    GameManager.gold_changed.connect(func(_value: int) -> void: _refresh_ui())
    GameManager.health_changed.connect(func(_value: int) -> void: _refresh_ui())
    GameManager.wave_changed.connect(func(_value: int) -> void: _refresh_ui())
    GameManager.game_over.connect(_on_game_over)

func _refresh_ui() -> void:
    var level_data: Dictionary = level_manager.get_current_level()
    gold_label.text = "Gold: %d" % GameManager.gold
    health_label.text = "Health: %d" % GameManager.health
    wave_label.text = "Wave: %d/%d" % [GameManager.current_wave, GameManager.TOTAL_WAVES]
    level_label.text = "Level: %s" % level_data.get("name", "Unknown")
    pause_button.text = "Resume" if GameManager.game_state == "PAUSED" else "Pause"
    tower_info_panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
    var defs = _tower_defs()
    if not game_started or start_overlay.visible or result_overlay.visible or pause_overlay.visible:
        return
    if GameManager.game_state in ["WIN", "LOSE"]:
        return
    if event is InputEventMouseMotion:
        var cell: Vector2i = game_map.world_to_cell(event.position)
        var valid: bool = game_map.is_inside_map(cell) and game_map.can_build_at(cell) and GameManager.can_afford(defs[selected_tower_type].cost)
        game_map.update_preview(cell, valid)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _try_build_at(event.position)

func _try_build_at(world_pos: Vector2) -> void:
    var defs = _tower_defs()
    var cell: Vector2i = game_map.world_to_cell(world_pos)
    if not game_map.is_inside_map(cell):
        return
    var data: Dictionary = defs[selected_tower_type]
    if not GameManager.can_afford(int(data.cost)):
        status_label.text = "Not enough gold for %s." % selected_tower_type.capitalize()
        return
    if not game_map.can_build_at(cell):
        status_label.text = "That placement would block the path."
        return
    var tower = tower_scenes[selected_tower_type].instantiate()
    tower_container.add_child(tower)
    var balance = wave_spawner.get_tower_balance(selected_tower_type)
    tower.damage = float(balance.get("damage", tower.damage))
    tower.attack_range = float(balance.get("range", tower.attack_range))
    tower.attack_speed = float(balance.get("speed", tower.attack_speed))
    tower.cost = int(balance.get("cost", tower.cost))
    tower.global_position = game_map.cell_to_world(cell)
    tower.setup(projectile_container)
    game_map.occupy_cell(cell)
    GameManager.spend_gold(int(data.cost))
    for enemy: Node in get_tree().get_nodes_in_group("enemies"):
        if enemy.has_method("update_path"):
            enemy.update_path()
    status_label.text = "%s built." % selected_tower_type.capitalize()

func _on_start_game_pressed() -> void:
    _start_level(level_manager.current_level_index)

func _on_start_wave_pressed() -> void:
    if wave_spawner.start_next_wave():
        start_wave_button.disabled = true
        GameManager.begin_wave(wave_spawner.current_wave_index + 1)
        GameManager.add_gold(int(level_manager.get_current_level().get("wave_bonus", 50)))

func _on_pause_pressed() -> void:
    if not game_started or start_overlay.visible or result_overlay.visible:
        return
    if GameManager.game_state == "PAUSED":
        _resume_from_overlay()
        return
    GameManager.set_paused(true)
    pause_overlay.visible = true
    _refresh_ui()

func _resume_from_overlay() -> void:
    pause_overlay.visible = false
    GameManager.set_paused(false)
    _refresh_ui()

func spawn_enemy(enemy_type: String) -> void:
    if not wave_spawner.enemy_scenes.has(enemy_type):
        push_warning("Unknown enemy type requested: %s" % enemy_type)
        return
    var scene: PackedScene = wave_spawner.enemy_scenes[enemy_type]
    var enemy = scene.instantiate()
    enemy_container.add_child(enemy)
    enemy.setup_enemy(game_map, wave_spawner.get_enemy_balance(enemy_type))
    enemy.reached_goal.connect(func() -> void: GameManager.damage_base(1))
    enemy.enemy_died.connect(func(reward: int) -> void: GameManager.add_gold(reward))

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
    result_overlay.visible = true
    pause_overlay.visible = false
    next_level_button.visible = won and active_level_index < level_manager.levels.size() - 1
    result_label.text = "Victory!" if won else "Defeat!"
    status_label.text = result_label.text
    if won and active_level_index < level_manager.levels.size() - 1:
        level_manager.current_level_index = active_level_index + 1
        level_manager.save_progress()

func _on_next_level_pressed() -> void:
    result_overlay.visible = false
    _start_level(level_manager.current_level_index)

func _restart_current_level() -> void:
    result_overlay.visible = false
    _start_level(active_level_index)
