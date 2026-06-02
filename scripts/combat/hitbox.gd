extends Area2D

## Hitbox — attached to weapons, projectiles, or attack areas.
## When it overlaps a Hurtbox, it deals damage to that entity.

@export var damage: int = 10
@export var knockback_force: float = 200.0

@export var enabled_by_default: bool = false

# Direction the knockback should push the target (set by the attacker before enabling)
var knockback_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if not enabled_by_default:
		monitoring = false
		monitorable = false
	else:
		monitoring = true
		monitorable = true
	area_entered.connect(_on_area_entered)

func enable(direction: Vector2 = Vector2.RIGHT) -> void:
	knockback_direction = direction.normalized()
	monitoring = true
	monitorable = true

func disable() -> void:
	monitoring = false
	monitorable = false

func _on_area_entered(area: Area2D) -> void:
	# Check by group tag to avoid cross-file class_name dependency
	if area.is_in_group("hurtbox"):
		area.receive_hit(damage, knockback_direction * knockback_force)
