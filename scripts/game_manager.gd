extends Node

signal gold_changed(new_gold: int)
signal health_changed(new_health: int)
signal wave_changed(new_wave: int)
signal game_state_changed(new_state: String)
signal game_over(won: bool)

const STARTING_GOLD := 500
const STARTING_HEALTH := 20
const TOTAL_WAVES := 10

var gold: int = STARTING_GOLD
var health: int = STARTING_HEALTH
var current_wave: int = 0
var game_state: String = "PLAYING"

func _ready() -> void:
    reset()

func reset() -> void:
    gold = STARTING_GOLD
    health = STARTING_HEALTH
    current_wave = 0
    game_state = "PLAYING"
    gold_changed.emit(gold)
    health_changed.emit(health)
    wave_changed.emit(current_wave)
    game_state_changed.emit(game_state)

func can_afford(cost: int) -> bool:
    return gold >= cost

func spend_gold(cost: int) -> bool:
    if not can_afford(cost):
        return false
    gold -= cost
    gold_changed.emit(gold)
    return true

func add_gold(amount: int) -> void:
    gold += max(amount, 0)
    gold_changed.emit(gold)

func damage_base(amount: int) -> void:
    if game_state != "PLAYING":
        return
    health = max(health - max(amount, 0), 0)
    health_changed.emit(health)
    if health == 0:
        game_state = "LOSE"
        game_state_changed.emit(game_state)
        game_over.emit(false)

func begin_wave(wave_number: int) -> void:
    current_wave = wave_number
    wave_changed.emit(current_wave)

func finish_level() -> void:
    if game_state != "PLAYING":
        return
    game_state = "WIN"
    game_state_changed.emit(game_state)
    game_over.emit(true)

func set_paused(paused: bool) -> void:
    if game_state in ["WIN", "LOSE"]:
        return
    game_state = "PAUSED" if paused else "PLAYING"
    get_tree().paused = paused
    game_state_changed.emit(game_state)
