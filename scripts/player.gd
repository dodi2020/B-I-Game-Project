extends CharacterBody2D

# ─── Exported Tuning Variables ────────────────────────────────────────────────
@export_group("Movement")
@export var speed: float = 250.0
@export var jump_velocity: float = 380.0  # Input standard positive value (e.g. 380.0)

@export_group("Dash (VPN Tunnel)")
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8

@export_group("Combat")
@export var attack_duration: float = 0.25
@export var bounce_velocity: float = 420.0  # Input standard positive value (e.g. 420.0)

@export_group("Shield (Ad Blocker)")
@export var shield_duration: float = 0.6
@export var shield_cooldown: float = 2.5

# ─── State Machine ─────────────────────────────────────────────────────────────
enum State { IDLE, RUN, JUMP, FALL, DASH, ATTACK, DOWN_STRIKE, SHIELD }
var current_state: State = State.IDLE

# ─── Movement vars ─────────────────────────────────────────────────────────────
var gravity               = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_facing_right: bool = true
var was_on_floor: bool    = true

# ─── Timers / Flags ────────────────────────────────────────────────────────────
var dash_timer:          float = 0.0
var dash_cooldown_timer: float = 0.0
var can_dash:            bool  = true

var attack_timer:        float = 0.0

# ─── Shield (Ad Blocker upgrade) vars ──────────────────────────────────────────
var shield_timer:          float = 0.0
var shield_cooldown_timer: float = 0.0

# ─── Cloak (Incognito Cloak upgrade) vars ──────────────────────────────────────
var is_cloaked:            bool = false

# ─── Look State vars ───────────────────────────────────────────────────────────
var is_looking_up:         bool = false
var is_looking_down:       bool = false

# ─── Juice vars ────────────────────────────────────────────────────────────────
var time_passed:         float   = 0.0
var target_scale:        Vector2 = Vector2.ONE
var target_rotation:     float   = 0.0

# ─── Hit-flash vars ────────────────────────────────────────────────────────────
var _flash_timer:        float   = 0.0
const FLASH_DURATION:    float   = 0.08

# ─── Node references ──────────────────────────────────────────────────────────
@onready var sprite:           Sprite2D        = $Sprite
@onready var hitbox:           Area2D          = $SwordHitbox
@onready var hurtbox:          Area2D          = $Hurtbox
@onready var health_component: Node            = $HealthComponent
@onready var down_ray:         RayCast2D       = $DownStrikeRay
@onready var game_state                        = get_node_or_null("/root/GameState")

# ─── Initialisation ──────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	# Connect our own hurtbox hit signal for flash VFX
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)

	# Bi-directional sync between player health component and global GameState
	if game_state:
		health_component.max_health = game_state.max_health
		health_component.current_health = game_state.player_health
		
		# Sync from local component changes to global GameState
		health_component.health_changed.connect(func(curr: int, max_hp: int) -> void:
			if game_state.player_health != curr or game_state.max_health != max_hp:
				game_state.max_health = max_hp
				game_state.player_health = curr
		)
		
		# Sync from global GameState changes to local component (e.g. from pickups)
		game_state.health_changed.connect(func(curr: int, max_hp: int) -> void:
			if health_component.current_health != curr or health_component.max_health != max_hp:
				health_component.max_health = max_hp
				health_component.current_health = curr
		)

# ─── Main Loop ────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	time_passed  += delta
	_tick_cooldowns(delta)
	_tick_flash(delta)

	match current_state:
		State.IDLE, State.RUN, State.JUMP, State.FALL:
			_handle_normal_movement(delta)
			_handle_attack_input()
		State.DASH:
			_handle_dash(delta)
		State.ATTACK:
			_handle_attack_active(delta)
		State.DOWN_STRIKE:
			_handle_down_strike(delta)
		State.SHIELD:
			_handle_shield(delta)

	move_and_slide()
	_apply_juice(delta)

# ─── Cooldown Ticks ───────────────────────────────────────────────────────────
func _tick_cooldowns(delta: float) -> void:
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	else:
		can_dash = true
		
	if shield_cooldown_timer > 0:
		shield_cooldown_timer -= delta

# ─── Normal Movement ──────────────────────────────────────────────────────────
func _handle_normal_movement(delta: float) -> void:
	var on_floor = is_on_floor()

	# Check looking up (W) and looking down (S) states
	is_looking_up = Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")
	is_looking_down = Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")

	# Incognito Cloak stealth mechanic (Hold S / Down on floor)
	if game_state and game_state.upgrades.get("incognito_cloak", false) and on_floor and is_looking_down:
		if not is_cloaked:
			is_cloaked = true
			hurtbox.collision_layer = 0  # Avoid all contact/projectile hits
			sprite.modulate = Color(1.0, 1.0, 1.0, 0.35)
		velocity.x = 0.0
		# Apply simple breathing/squish juice while crouching
		var breath = sin(time_passed * 3.0) * 0.02
		sprite.scale = Vector2(1.1 + breath, 0.8 - breath)
		return
	else:
		if is_cloaked:
			is_cloaked = false
			hurtbox.collision_layer = 4  # Restore vulnerability
			sprite.modulate = Color.WHITE

	# Landing squash
	if on_floor and not was_on_floor:
		sprite.scale = Vector2(1.35, 0.65)
	was_on_floor = on_floor

	# Gravity
	if not on_floor:
		velocity.y += gravity * delta
		current_state = State.FALL if velocity.y > 0 else State.JUMP
	else:
		current_state = State.IDLE if velocity.x == 0.0 else State.RUN

	# Jump (Space / ui_accept)
	var jump_pressed = Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept")
	if jump_pressed and on_floor:
		velocity.y    = -abs(jump_velocity)  # Always launch upward (-Y) regardless of positive/negative entry
		current_state = State.JUMP
		sprite.scale  = Vector2(0.75, 1.35)

	# Downward strike — press S / Down while airborne
	var down_just_pressed = Input.is_key_pressed(KEY_S) or Input.is_action_just_pressed("ui_down")
	if down_just_pressed and not on_floor:
		_start_down_strike()
		return

	# Horizontal movement (A/D or left/right arrow)
	var dir = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir += 1.0
		
	if dir != 0.0:
		velocity.x     = dir * speed
		is_facing_right = dir > 0
		sprite.flip_h   = not is_facing_right
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 0.2)

	# Dash (VPN Tunnel upgrade - Shift for ALL dashes)
	var dash_pressed = Input.is_key_pressed(KEY_SHIFT)
	if dash_pressed and can_dash \
	   and game_state and game_state.upgrades.get("vpn_tunnel", false):
		_start_dash()
		return

	# Shield (Ad Blocker upgrade - Tab or ui_focus_next)
	var shield_pressed = Input.is_key_pressed(KEY_TAB) or Input.is_action_just_pressed("ui_focus_next")
	if shield_pressed and shield_cooldown_timer <= 0.0 \
	   and game_state and game_state.upgrades.get("ad_blocker", false):
		_start_shield()
		return

# ─── Attack ───────────────────────────────────────────────────────────────────
func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("ui_text_backspace"):  # placeholder — replace with "attack" action
		_start_attack()

func _start_attack() -> void:
	current_state = State.ATTACK
	attack_timer  = attack_duration
	var dir = Vector2.RIGHT if is_facing_right else Vector2.LEFT
	hitbox.enable(dir)
	sprite.scale = Vector2(1.2, 0.8)

func _handle_attack_active(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0:
		hitbox.disable()
		current_state = State.IDLE

# ─── Downward Strike ─────────────────────────────────────────────────────────
func _start_down_strike() -> void:
	current_state = State.DOWN_STRIKE
	velocity.y    = 600.0  # Fast plummet
	velocity.x    = 0.0
	# Enable a downward hitbox so it can hit enemies on the way down
	hitbox.enable(Vector2.DOWN)

func _handle_down_strike(delta: float) -> void:
	velocity.y += gravity * delta

	# Check raycast for enemy below
	down_ray.force_raycast_update()
	if down_ray.is_colliding():
		var collider = down_ray.get_collider()
		# If we hit a Hurtbox, damage it and bounce
		if collider.is_in_group("hurtbox"):
			collider.receive_hit(hitbox.damage, Vector2.ZERO)
			_bounce()
			return

	# Land on floor naturally — end down strike
	if is_on_floor():
		hitbox.disable()
		current_state = State.IDLE

func _bounce() -> void:
	hitbox.disable()
	velocity.y    = -abs(bounce_velocity)  # Always launch upward (-Y) regardless of positive/negative entry
	current_state = State.JUMP
	sprite.scale  = Vector2(0.75, 1.4)  # Dramatic launch stretch

# ─── Dash ────────────────────────────────────────────────────────────────────
func _start_dash() -> void:
	current_state      = State.DASH
	dash_timer         = dash_duration
	can_dash           = false
	dash_cooldown_timer = dash_cooldown
	velocity.x         = dash_speed if is_facing_right else -dash_speed
	velocity.y         = 0.0
	sprite.scale       = Vector2(1.5, 0.6)

func _handle_dash(delta: float) -> void:
	dash_timer -= delta
	if dash_timer <= 0:
		current_state = State.IDLE
		velocity.x    = 0.0

# ─── Hit Flash VFX ───────────────────────────────────────────────────────────
func _on_hit_received(_damage: int, _knockback: Vector2) -> void:
	_flash_timer = FLASH_DURATION
	sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)

func _tick_flash(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0:
			sprite.modulate = Color.WHITE

# ─── Death ───────────────────────────────────────────────────────────────────
func _on_died() -> void:
	# Tell GameState to trigger offline mode
	if game_state:
		game_state.trigger_offline_mode()
	# Could queue_free() here or hand off to a death animation state

# ─── Shield ──────────────────────────────────────────────────────────────────
func _start_shield() -> void:
	current_state = State.SHIELD
	shield_timer = shield_duration
	shield_cooldown_timer = shield_cooldown
	health_component.is_invincible = true
	# Visual shield tint
	sprite.modulate = Color(0.2, 0.6, 1.0, 0.8)
	sprite.scale = Vector2(1.2, 1.2)
	velocity = Vector2.ZERO

func _handle_shield(delta: float) -> void:
	shield_timer -= delta
	health_component.is_invincible = true
	
	# Pulsing animation during shield hold
	var pulse = 1.2 + sin(time_passed * 25.0) * 0.06
	sprite.scale = Vector2(pulse, pulse)
	
	if shield_timer <= 0.0:
		health_component.is_invincible = false
		sprite.modulate = Color.WHITE
		current_state = State.IDLE

# ─── Procedural Juice ─────────────────────────────────────────────────────────
func _apply_juice(delta: float) -> void:
	match current_state:
		State.IDLE:
			var breath = sin(time_passed * 4.0) * 0.03
			target_scale    = Vector2(1.0 + breath, 1.0 - breath)
			target_rotation = 0.0
		State.RUN:
			var bob = sin(time_passed * 14.0) * 0.06
			target_scale    = Vector2(1.0 + bob, 1.0 - bob)
			target_rotation = (1.0 if velocity.x > 0 else -1.0) * 0.08
		State.JUMP:
			target_scale    = Vector2(0.85, 1.2)
			target_rotation = velocity.x * 0.0003
		State.FALL:
			target_scale    = Vector2(1.1, 0.9)
			target_rotation = velocity.x * 0.0002
		State.DOWN_STRIKE:
			target_scale    = Vector2(0.7, 1.4)
			target_rotation = 0.0
		State.DASH:
			target_scale    = Vector2(1.4, 0.7)
			target_rotation = 0.0
		State.ATTACK:
			target_scale    = Vector2(1.1, 0.9)
			target_rotation = 0.0
		State.SHIELD:
			# Visual scaling handled dynamically in _handle_shield
			return

	sprite.scale    = sprite.scale.lerp(target_scale, delta * 12.0)
	sprite.rotation = lerp(sprite.rotation, target_rotation, delta * 10.0)
