extends Camera2D

## Custom Camera2D that smoothly tracks the player and respects level/room bounds.
## Place inside a level, and it will auto-target the player and configure limits.

@export var follow_speed: float = 6.0
@export var limit_margin: float = 32.0  # Extra boundary padding

func _ready() -> void:
	# Enable smoothing
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	
	# Auto-detect level limits
	_configure_limits()

func _physics_process(_delta: float) -> void:
	var player = _find_player()
	if player:
		# Directly set target position; Camera2D's built-in position_smoothing handles the interpolation
		global_position = player.global_position

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null

func _configure_limits() -> void:
	# 1. Check for a dedicated bounds Area2D/CollisionShape2D in the "level_bounds" group
	var bounds_nodes = get_tree().get_nodes_in_group("level_bounds")
	if bounds_nodes.size() > 0:
		var bounds = bounds_nodes[0]
		var col_shape = bounds.get_node_or_null("CollisionShape2D")
		if col_shape and col_shape.shape is RectangleShape2D:
			var rect = col_shape.shape.get_rect()
			var global_pos = col_shape.global_position
			limit_left = int(global_pos.x + rect.position.x)
			limit_right = int(global_pos.x + rect.position.x + rect.size.x)
			limit_top = int(global_pos.y + rect.position.y)
			limit_bottom = int(global_pos.y + rect.position.y + rect.size.y)
			return

	# 2. Fallback: Search for any TileMapLayer in the level to set boundaries based on used tiles
	var tilemap_layers = get_tree().get_nodes_in_group("tilemap_layer")
	if tilemap_layers.size() > 0:
		var layer = tilemap_layers[0] as TileMapLayer
		if layer:
			var used_rect = layer.get_used_rect()
			var cell_size = layer.tile_set.tile_size
			limit_left = int(layer.global_position.x + used_rect.position.x * cell_size.x) - int(limit_margin)
			limit_right = int(layer.global_position.x + (used_rect.position.x + used_rect.size.x) * cell_size.x) + int(limit_margin)
			limit_top = int(layer.global_position.y + used_rect.position.y * cell_size.y) - int(limit_margin)
			limit_bottom = int(layer.global_position.y + (used_rect.position.y + used_rect.size.y) * cell_size.y) + int(limit_margin)
			return
			
	# 3. Default fallback if no bounds found
	limit_left = -10000000
	limit_right = 10000000
	limit_top = -10000000
	limit_bottom = 10000000
