extends CharacterBody2D

signal reached_goal
signal enemy_died(reward: int)

@export var max_health: float = 100.0
@export var move_speed: float = 100.0
@export var gold_reward: int = 10
@export var is_flying: bool = false
@export var enemy_color: Color = Color(0.2, 0.8, 0.2)
@export var enemy_size: Vector2 = Vector2(20, 20)
@export var regen_per_second: float = 0.0

var current_health: float = 100.0
var path: Array[Vector2i] = []
var path_index: int = 0
var map_ref: Node = null
var slow_multiplier: float = 1.0
var slow_time_left: float = 0.0

func _ready() -> void:
    current_health = max_health
    add_to_group("enemies")
    queue_redraw()

func setup_enemy(game_map: Node, enemy_data: Dictionary) -> void:
    map_ref = game_map
    max_health = enemy_data.get("health", max_health)
    move_speed = enemy_data.get("speed", move_speed)
    gold_reward = enemy_data.get("reward", gold_reward)
    is_flying = enemy_data.get("flying", is_flying)
    regen_per_second = enemy_data.get("regen", regen_per_second)
    enemy_color = enemy_data.get("color", enemy_color)
    current_health = max_health
    global_position = map_ref.cell_to_world(map_ref.start_cell)
    update_path()
    queue_redraw()

func update_path() -> void:
    if map_ref == null:
        return
    path = map_ref.get_air_path() if is_flying else map_ref.get_ground_path()
    path_index = 1

func apply_slow(multiplier: float, duration: float) -> void:
    slow_multiplier = min(slow_multiplier, multiplier)
    slow_time_left = max(slow_time_left, duration)

func take_damage(amount: float) -> void:
    current_health = max(current_health - amount, 0.0)
    queue_redraw()
    if current_health <= 0.0:
        enemy_died.emit(gold_reward)
        queue_free()

func _process(delta: float) -> void:
    if regen_per_second > 0.0 and current_health > 0.0:
        current_health = min(max_health, current_health + regen_per_second * delta)
        queue_redraw()
    if slow_time_left > 0.0:
        slow_time_left -= delta
        if slow_time_left <= 0.0:
            slow_multiplier = 1.0

func _physics_process(delta: float) -> void:
    if path.is_empty() or path_index >= path.size():
        if map_ref != null and global_position.distance_to(map_ref.cell_to_world(map_ref.end_cell)) <= 8.0:
            reached_goal.emit()
            queue_free()
        return
    var target_pos: Vector2 = map_ref.cell_to_world(path[path_index])
    var direction: Vector2 = global_position.direction_to(target_pos)
    velocity = direction * move_speed * slow_multiplier
    if global_position.distance_to(target_pos) <= max(4.0, velocity.length() * delta):
        global_position = target_pos
        path_index += 1
        if path_index >= path.size():
            reached_goal.emit()
            queue_free()
            return
    else:
        move_and_slide()

func _draw() -> void:
    draw_rect(Rect2(-enemy_size / 2.0, enemy_size), enemy_color, true)
    var ratio: float = 0.0 if max_health <= 0.0 else current_health / max_health
    draw_rect(Rect2(Vector2(-enemy_size.x / 2.0, -enemy_size.y / 2.0 - 6.0), Vector2(enemy_size.x, 4.0)), Color(0.2, 0.1, 0.1), true)
    draw_rect(Rect2(Vector2(-enemy_size.x / 2.0, -enemy_size.y / 2.0 - 6.0), Vector2(enemy_size.x * ratio, 4.0)), Color(0.2, 0.9, 0.3), true)
