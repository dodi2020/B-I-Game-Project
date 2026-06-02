extends Area2D

## Upgrade Pickup - allows the player to pick up browser extension upgrades.

@export_enum("vpn_tunnel", "ad_blocker", "incognito_cloak", "auto_fill") var upgrade_id: String = "vpn_tunnel"
@export var bob_speed: float = 3.0
@export var bob_height: float = 6.0

var _origin_y: float
var _time: float = 0.0
var _collected: bool = false

@onready var sprite = $Sprite

func _ready() -> void:
	_origin_y = global_position.y
	body_entered.connect(_on_body_entered)
	_update_visuals()

func _process(delta: float) -> void:
	if _collected:
		return
		
	_time += delta
	position.y = _origin_y + sin(_time * bob_speed) * bob_height

func _update_visuals() -> void:
	if not is_inside_tree() or not sprite:
		return
		
	# Harmonious neon colors for different browser extension upgrades
	match upgrade_id:
		"vpn_tunnel":
			# Cyan/Neon Blue for VPN (Tunnel / Speed / Dash)
			sprite.modulate = Color(0.0, 1.0, 1.0, 1.0)
		"ad_blocker":
			# Neon Red/Coral for Ad Blocker (Shield / Stop / Block)
			sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
		"incognito_cloak":
			# Neon Purple/Magenta for Incognito (Stealth / Invisible)
			sprite.modulate = Color(0.8, 0.0, 1.0, 1.0)
		"auto_fill":
			# Neon Green/Lime for Auto Fill (Magnet / Data / Pull)
			sprite.modulate = Color(0.2, 1.0, 0.2, 1.0)

func _on_body_entered(body: Node) -> void:
	if _collected:
		return
		
	if body.is_in_group("player"):
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			game_state.unlock_upgrade(upgrade_id)
		_collect()

func _collect() -> void:
	_collected = true
	# Pop scale effect and fade
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.08)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)
