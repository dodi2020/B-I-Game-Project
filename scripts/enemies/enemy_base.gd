extends CharacterBody2D

## Base enemy class. Inherit from this for specific enemy types.
## Handles: patrol AI, gravity, hurtbox hookup, death + cookie drop.

signal died(position: Vector2)

# ─── Export config (override in subclasses / editor) ──────────────────────────
@export var patrol_speed:    float = 80.0
@export var patrol_distance: float = 150.0  # Pixels to walk before turning
@export var cookie_drop_count: int = 1

# ─── Internal state ───────────────────────────────────────────────────────────
enum EnemyState { PATROL, HURT, DEAD }
var state: EnemyState = EnemyState.PATROL

var gravity          = ProjectSettings.get_setting("physics/2d/default_gravity")
var move_direction:  float = 1.0   # 1 = right, -1 = left
var patrol_origin:   Vector2
var _hurt_timer:     float = 0.0
const HURT_DURATION: float = 0.3

# Loaded at runtime to avoid parse-time preload errors
var DATA_COOKIE_SCENE: PackedScene = null

# ─── Node references ──────────────────────────────────────────────────────────
@onready var sprite:            Sprite2D        = $Sprite
@onready var health_component:  Node            = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var wall_ray:          RayCast2D       = $WallRay
@onready var ledge_ray:         RayCast2D       = $LedgeRay


func _ready() -> void:
	patrol_origin = global_position
	# Load cookie scene at runtime so parse-time preload is not needed
	DATA_COOKIE_SCENE = load("res://scenes/pickups/data_cookie.tscn")
	health_component.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	_set_ray_directions()

func _physics_process(delta: float) -> void:
	match state:
		EnemyState.PATROL:
			_patrol(delta)
		EnemyState.HURT:
			_hurt_tick(delta)
		EnemyState.DEAD:
			pass  # Waiting for death animation to finish

# ─── Patrol AI ────────────────────────────────────────────────────────────────
func _patrol(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Check for wall or ledge ahead — flip if hit
	wall_ray.force_raycast_update()
	ledge_ray.force_raycast_update()
	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		_flip()

	# Distance-based patrol turnaround
	var dist = global_position.x - patrol_origin.x
	if abs(dist) >= patrol_distance:
		_flip()

	velocity.x = patrol_speed * move_direction
	sprite.flip_h = move_direction < 0

	move_and_slide()

func _flip() -> void:
	move_direction *= -1.0
	_set_ray_directions()

func _set_ray_directions() -> void:
	var dir = Vector2(move_direction * 40.0, 0)
	if wall_ray:
		wall_ray.target_position = dir
	if ledge_ray:
		ledge_ray.target_position = Vector2(move_direction * 30.0, 50.0)

# ─── Hurt State ───────────────────────────────────────────────────────────────
func _on_hit_received(_damage: int, _knockback: Vector2) -> void:
	if state == EnemyState.DEAD:
		return
	state        = EnemyState.HURT
	_hurt_timer  = HURT_DURATION
	# Simple red flash
	sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)

func _hurt_tick(delta: float) -> void:
	_hurt_timer -= delta
	if _hurt_timer <= 0:
		sprite.modulate = Color.WHITE
		state = EnemyState.PATROL

# ─── Death ────────────────────────────────────────────────────────────────────
func _on_died() -> void:
	state = EnemyState.DEAD
	hurtbox.monitoring = false

	died.emit(global_position)
	_spawn_cookies()

	# Small death scale pop then remove
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.4), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)

func _spawn_cookies() -> void:
	for i in cookie_drop_count:
		var cookie = DATA_COOKIE_SCENE.instantiate()
		# Scatter cookies slightly
		cookie.global_position = global_position + Vector2(randf_range(-20, 20), -10)
		get_parent().add_child(cookie)
