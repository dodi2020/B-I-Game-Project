extends Area2D

## Health Restore Pickup - heals the player when collected.

@export var heal_amount: int = 25
@export var bob_speed: float = 3.0
@export var bob_height: float = 6.0

var _origin_y: float
var _time: float = 0.0
var _collected: bool = false

@onready var sprite = $Sprite

func _ready() -> void:
	_origin_y = global_position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _collected:
		return
		
	_time += delta
	position.y = _origin_y + sin(_time * bob_speed) * bob_height

func _on_body_entered(body: Node) -> void:
	if _collected:
		return
		
	if body.is_in_group("player"):
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			# Check if player needs healing
			if game_state.player_health < game_state.max_health:
				game_state.player_health += heal_amount
				_collect()
			else:
				# Optional: play a "full health" mini-feedback or let them pick it up anyway
				game_state.player_health += heal_amount
				_collect()

func _collect() -> void:
	_collected = true
	# Pop scale effect and fade
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.08)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)
