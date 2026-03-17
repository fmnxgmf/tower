extends Node2D

const GRID_SIZE: Vector2i = Vector2i(20, 15)
const CELL_SIZE := 32
const MAP_ORIGIN := Vector2(80, 72)

var pathfinding = preload("res://scripts/pathfinding.gd").new()
var tower_cells: Dictionary = {}
var start_cell: Vector2i = Vector2i.ZERO
var end_cell: Vector2i = Vector2i(19, 14)
var preview_cell: Vector2i = Vector2i(-1, -1)
var preview_valid: bool = false

func _ready() -> void:
    pathfinding.setup(GRID_SIZE, start_cell, end_cell)
    queue_redraw()

func cell_to_world(cell: Vector2i) -> Vector2:
    return MAP_ORIGIN + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2.0, cell.y * CELL_SIZE + CELL_SIZE / 2.0)

func world_to_cell(world_pos: Vector2) -> Vector2i:
    var local: Vector2 = world_pos - MAP_ORIGIN
    return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))

func is_inside_map(cell: Vector2i) -> bool:
    return pathfinding.is_within_bounds(cell)

func can_build_at(cell: Vector2i) -> bool:
    return pathfinding.can_place_tower(cell)

func occupy_cell(cell: Vector2i) -> void:
    tower_cells[cell] = true
    pathfinding.set_blocked(cell, true)
    queue_redraw()

func is_occupied(cell: Vector2i) -> bool:
    return tower_cells.has(cell)

func update_preview(cell: Vector2i, is_valid: bool) -> void:
    preview_cell = cell
    preview_valid = is_valid
    queue_redraw()

func clear_preview() -> void:
    preview_cell = Vector2i(-1, -1)
    queue_redraw()

func get_ground_path() -> Array[Vector2i]:
    return pathfinding.find_path(start_cell, end_cell, false)

func get_air_path() -> Array[Vector2i]:
    return pathfinding.find_path(start_cell, end_cell, true)

func _draw() -> void:
    for y: int in range(GRID_SIZE.y):
        for x: int in range(GRID_SIZE.x):
            var cell: Vector2i = Vector2i(x, y)
            var rect: Rect2 = Rect2(MAP_ORIGIN + Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE - 1, CELL_SIZE - 1))
            var color: Color = Color(0.16, 0.18, 0.2)
            if cell == start_cell:
                color = Color(0.2, 0.6, 0.2)
            elif cell == end_cell:
                color = Color(0.65, 0.2, 0.2)
            elif tower_cells.has(cell):
                color = Color(0.28, 0.3, 0.36)
            draw_rect(rect, color, true)
    if is_inside_map(preview_cell) and not tower_cells.has(preview_cell):
        var preview_rect: Rect2 = Rect2(MAP_ORIGIN + Vector2(preview_cell.x * CELL_SIZE, preview_cell.y * CELL_SIZE), Vector2(CELL_SIZE - 1, CELL_SIZE - 1))
        draw_rect(preview_rect, Color(0.2, 0.8, 0.4, 0.45) if preview_valid else Color(0.9, 0.2, 0.2, 0.45), true)
    var path: Array[Vector2i] = get_ground_path()
    for idx: int in range(path.size() - 1):
        draw_line(cell_to_world(path[idx]), cell_to_world(path[idx + 1]), Color(0.95, 0.85, 0.3), 3.0)
