extends Node

## Reusable health component. Attach as a child to any entity (Player, Enemy, Boss).
## Emits signals that the parent or HUD can connect to.

signal health_changed(current_hp: int, max_hp: int)
signal died

@export var max_health: int = 100
@export var invincibility_duration: float = 0.6  # Seconds of i-frames after hit

var current_health: int
var is_invincible: bool = false
var _invincibility_timer: float = 0.0

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false

func take_damage(amount: int) -> void:
	if is_invincible or current_health <= 0:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		died.emit()
	else:
		# Grant i-frames after being hit
		is_invincible = true
		_invincibility_timer = invincibility_duration

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func set_max_health(new_max: int, also_heal: bool = false) -> void:
	max_health = new_max
	if also_heal:
		current_health = max_health
	else:
		current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
