extends Area2D

## Portal / Zone Transition — triggers transition to another level when entered by the player.

@export_file("*.tscn") var target_scene: String
@export var portal_color: Color = Color(0.8, 0.0, 1.0, 1.0) # Purple cyber portal

var _transitioning: bool = false

@onready var sprite = $Sprite

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.modulate = portal_color

func _process(delta: float) -> void:
	# Subtle spin animation for the cyber portal
	if sprite:
		sprite.rotation += delta * 1.5

func _on_body_entered(body: Node) -> void:
	if _transitioning:
		return
		
	if body.is_in_group("player"):
		if not target_scene or target_scene == "":
			push_error("Portal on '%s' has no target scene configured!" % name)
			return
			
		_transitioning = true
		_transition_to_scene()

func _transition_to_scene() -> void:
	# Pop scale juice before changing scene
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.1)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	
	# Optional: Sync zone info in global state
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		# Extract scene name for zone tracking
		var scene_name = target_scene.get_file().get_basename()
		game_state.current_zone = scene_name
		game_state.save_game()
		
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(target_scene)
	)
