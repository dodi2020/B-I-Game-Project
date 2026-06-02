extends Area2D

## Hurtbox — attached to entities that can receive damage (Player, Enemies).

## Looks up a sibling HealthComponent and forwards damage to it.
## Also applies knockback to a sibling CharacterBody2D if one exists.

signal hit_received(damage: int, knockback: Vector2)

var health_component: Node = null

func _ready() -> void:
	add_to_group("hurtbox")
	health_component = _find_health_component()

func _find_health_component() -> Node:
	# Search parent's children for a HealthComponent
	var parent = get_parent()
	for child in parent.get_children():
		if child.has_method("take_damage"):
			return child
	push_warning("Hurtbox on '%s' could not find a HealthComponent sibling!" % get_parent().name)
	return null

func receive_hit(damage: int, knockback: Vector2) -> void:
	if health_component and health_component.is_invincible:
		return

	hit_received.emit(damage, knockback)

	if health_component:
		health_component.take_damage(damage)

	# Apply knockback to the parent CharacterBody2D if it exists
	var parent = get_parent()
	if parent is CharacterBody2D:
		parent.velocity += knockback
