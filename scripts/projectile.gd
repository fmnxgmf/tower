extends Node2D

var target: Node2D = null
var damage: float = 0.0
var speed: float = 320.0
var slow_multiplier: float = 1.0
var slow_duration: float = 0.0
var pool_owner: Node = null
var active: bool = false

func launch(new_target: Node2D, new_damage: float, new_speed: float, new_slow_multiplier: float, new_slow_duration: float) -> void:
    target = new_target
    damage = new_damage
    speed = new_speed
    slow_multiplier = new_slow_multiplier
    slow_duration = new_slow_duration
    active = true
    visible = true
    process_mode = Node.PROCESS_MODE_INHERIT

func reset_projectile() -> void:
    target = null
    damage = 0.0
    speed = 320.0
    slow_multiplier = 1.0
    slow_duration = 0.0
    active = false
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED
    global_position = Vector2.ZERO

func release() -> void:
    if pool_owner != null and pool_owner.has_method("release_projectile"):
        pool_owner.release_projectile(self)
    else:
        queue_free()

func _process(delta: float) -> void:
    if not active:
        return
    if not is_instance_valid(target):
        release()
        return
    global_position = global_position.move_toward(target.global_position, speed * delta)
    if global_position.distance_to(target.global_position) <= 8.0:
        target.take_damage(damage)
        if slow_duration > 0.0:
            target.apply_slow(slow_multiplier, slow_duration)
        release()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.85, 0.2))
