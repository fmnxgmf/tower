class_name Pathfinding
extends RefCounted

const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

var grid_size: Vector2i = Vector2i(20, 15)
var start_cell: Vector2i = Vector2i.ZERO
var end_cell: Vector2i = Vector2i(19, 14)
var blocked_cells: Dictionary = {}
var reserved_cells: Dictionary = {}
var path_cache: Dictionary = {}

func invalidate_cache() -> void:
    path_cache.clear()

func setup(new_grid_size: Vector2i, new_start: Vector2i, new_end: Vector2i) -> void:
    grid_size = new_grid_size
    start_cell = new_start
    end_cell = new_end
    blocked_cells.clear()
    reserved_cells.clear()
    reserved_cells[start_cell] = true
    reserved_cells[end_cell] = true
    invalidate_cache()

func is_within_bounds(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func is_walkable(cell: Vector2i, is_flying: bool) -> bool:
    if not is_within_bounds(cell):
        return false
    if is_flying:
        return true
    return not blocked_cells.has(cell)

func heuristic(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = [current]
    while came_from.has(current):
        current = came_from[current]
        path.push_front(current)
    return path

func _cache_key(from_cell: Vector2i, to_cell: Vector2i, is_flying: bool) -> String:
    return "%s|%s|%s" % [from_cell, to_cell, is_flying]

func find_path(from_cell: Vector2i, to_cell: Vector2i, is_flying: bool) -> Array[Vector2i]:
    if not is_walkable(from_cell, is_flying) or not is_walkable(to_cell, is_flying):
        return []
    var key := _cache_key(from_cell, to_cell, is_flying)
    if path_cache.has(key):
        return path_cache[key].duplicate()
    var open: Array[Vector2i] = [from_cell]
    var came_from: Dictionary = {}
    var g_score: Dictionary = {from_cell: 0}
    var f_score: Dictionary = {from_cell: heuristic(from_cell, to_cell)}
    while not open.is_empty():
        var current: Vector2i = open[0]
        for candidate: Vector2i in open:
            if f_score.get(candidate, 999999) < f_score.get(current, 999999):
                current = candidate
        if current == to_cell:
            var resolved := reconstruct_path(came_from, current)
            path_cache[key] = resolved.duplicate()
            return resolved
        open.erase(current)
        for direction: Vector2i in CARDINAL_DIRECTIONS:
            var neighbor: Vector2i = current + direction
            if not is_walkable(neighbor, is_flying):
                continue
            var tentative_g: int = g_score.get(current, 999999) + 1
            if tentative_g < g_score.get(neighbor, 999999):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic(neighbor, to_cell)
                if not open.has(neighbor):
                    open.append(neighbor)
    path_cache[key] = []
    return []

func set_blocked(cell: Vector2i, blocked: bool) -> void:
    if blocked:
        blocked_cells[cell] = true
    else:
        blocked_cells.erase(cell)
    invalidate_cache()

func can_place_tower(cell: Vector2i) -> bool:
    if not is_within_bounds(cell):
        return false
    if reserved_cells.has(cell):
        return false
    if blocked_cells.has(cell):
        return false
    blocked_cells[cell] = true
    invalidate_cache()
    var valid: bool = not find_path(start_cell, end_cell, false).is_empty()
    blocked_cells.erase(cell)
    invalidate_cache()
    return valid
