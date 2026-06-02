extends Area2D

## Data Cookie pickup — collectable currency dropped by defeated enemies.
## Auto-collected when the player enters the Area2D.

@export var value: int = 1
@export var bob_speed: float = 3.0
@export var bob_height: float = 6.0
@export var magnet_range: float = 80.0  # Auto-Fill upgrade radius

var _origin_y: float
var _time: float = 0.0
var _magnetized: bool = false

@onready var sprite = $Sprite

func _ready() -> void:
	_origin_y = global_position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta

	# Bobbing animation
	if not _magnetized:
		position.y = _origin_y + sin(_time * bob_speed) * bob_height
	else:
		# Fly to player
		var player = _find_player()
		if player:
			global_position = global_position.lerp(player.global_position, delta * 14.0)

	# Check Auto-Fill upgrade — magnetize if player is close enough
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.upgrades.get("auto_fill", false):
		var player = _find_player()
		if player and global_position.distance_to(player.global_position) <= magnet_range:
			_magnetized = true

func _find_player() -> Node:
	# Efficient: look for nodes in the group "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			game_state.data_cookies += value
		_collect()

func _collect() -> void:
	# Pop-scale animation then destroy
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.06)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)
