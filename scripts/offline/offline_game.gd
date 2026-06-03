extends Node2D

## Offline Dino Runner Mini Game - "No Internet Protocol"
## Plays like the classic Chrome dinosaur game with a neon cyber aesthetic.

@export_group("Runner Tuning")
@export var scroll_speed: float = 380.0
@export var speed_increase: float = 8.0
@export var gravity: float = 1600.0
@export var jump_force: float = -600.0
@export var spawn_interval: float = 1.6  # Seconds between cactus spawns
@export var cookie_spawn_chance: float = 0.45  # Chance to spawn a cookie with a cactus
@export var win_score: float = 300.0  # Meters to survive before WiFi Password spawns

@export_group("Parallax Background")
@export var far_scroll_factor: float = 0.15
@export var near_scroll_factor: float = 0.5
@export var far_color: Color = Color(0.12, 0.4, 0.6, 0.2)  # Dim blue-cyan drift
@export var near_color: Color = Color(1.0, 0.2, 0.6, 0.35)  # Brighter pink panels
@export var far_elements_count: int = 15
@export var near_elements_count: int = 6

@export_group("Hazard Settings")
@export var restart_on_hit: bool = true  # If true, resets metric score to 0 and reboots game.
@export var hit_distance_penalty: float = 50.0  # Meter deduction penalty if restart_on_hit is false.
@export var hit_cooldown: float = 1.0  # Invincibility frame duration after being hit.

var _score: float = 0.0
var _spawn_timer: float = 0.0
var _is_game_over: bool = false
var _password_spawned: bool = false
var _croc_velocity: Vector2 = Vector2.ZERO
var _hit_cooldown_timer: float = 0.0

# Loaded at runtime
var DATA_COOKIE_SCENE: PackedScene = null

@onready var croc = $Croc
@onready var score_label = $UI/ScoreLabel
@onready var guide_label = $UI/GuideLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var cacti_container = $CactiContainer
@onready var items_container = $ItemsContainer
@onready var far_bg_container = $FarBgContainer
@onready var near_bg_container = $NearBgContainer

func _ready() -> void:
	DATA_COOKIE_SCENE = load("res://scenes/pickups/data_cookie.tscn")
	game_over_panel.hide()
	# Put croc at start ground level
	croc.position = Vector2(150, 480)
	_croc_velocity = Vector2.ZERO
	_setup_parallax_background()

func _physics_process(delta: float) -> void:
	if _is_game_over:
		if Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept"):
			_restart_game()
		return

	# Handle invincibility cooldown tick
	if _hit_cooldown_timer > 0.0:
		_hit_cooldown_timer -= delta
		# Flickering visual effect during hit cooldown
		croc.modulate.a = 0.4 if Engine.get_physics_frames() % 6 < 3 else 0.9
		if _hit_cooldown_timer <= 0.0:
			croc.modulate = Color(0.2, 1.0, 0.2, 1.0) # Reset mod color

	# 1. Update Score
	_score += delta * 12.0
	score_label.text = "SIGNAL RANGE: %d / %d Meters" % [int(_score), int(win_score)]
	
	# Increase scroll speed gradually
	scroll_speed += speed_increase * delta

	# 2. Crocodile physics & jump
	var on_ground = croc.position.y >= 480.0
	if not on_ground:
		_croc_velocity.y += gravity * delta
		croc.position.y += _croc_velocity.y * delta
	else:
		croc.position.y = 480.0
		_croc_velocity.y = 0.0

	var jump_pressed = Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept")
	if jump_pressed and on_ground:
		_croc_velocity.y = jump_force
		croc.position.y += _croc_velocity.y * delta  # Jump start

	# Apply simple rotation juice based on jump velocity
	croc.rotation = clamp(_croc_velocity.y * 0.001, -0.2, 0.2)

	# 3. Spawning Obstacles & Cookies
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		# Randomize spawn delay slightly
		spawn_interval = randf_range(1.2, 2.2)
		_spawn_cactus()

	# 4. Spawning WiFi Password
	if _score >= win_score and not _password_spawned:
		_password_spawned = true
		_spawn_wifi_password()

	# 5. Move obstacles and check collisions
	_scroll_objects(delta)

	# 6. Scroll Parallax Backgrounds
	_scroll_parallax(delta)

func _spawn_cactus() -> void:
	var cactus = Area2D.new()
	cactus.collision_layer = 0
	cactus.collision_mask = 0  # We check manually or using overlap
	cactus.add_to_group("cactus")
	
	# Visual sprite for the cactus
	var sprite = Sprite2D.new()
	sprite.texture = load("res://icon.svg")
	sprite.modulate = Color(1.0, 0.2, 0.2, 1.0) # Red hazard
	sprite.scale = Vector2(0.4, randf_range(0.5, 0.8)) # random height
	cactus.add_child(sprite)
	
	# Collision shape
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(25, 64)
	col.shape = shape
	cactus.add_child(col)
	
	cactus.position = Vector2(1000, 480) # Spawn right
	cacti_container.add_child(cactus)
	
	# Spawn a Cookie in the air sometimes!
	if randf() < cookie_spawn_chance and DATA_COOKIE_SCENE:
		var cookie = DATA_COOKIE_SCENE.instantiate()
		cookie.position = Vector2(1000, randf_range(300, 400))
		# Set its script process to false; we will scroll it ourselves in items_container
		cookie.set_process(false)
		items_container.add_child(cookie)

func _spawn_wifi_password() -> void:
	# The legendary WiFi Password - collect to win!
	var password = Area2D.new()
	password.add_to_group("wifi_password")
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://icon.svg")
	sprite.modulate = Color(0.0, 1.0, 0.8, 1.0) # Glowing neon cyan
	sprite.scale = Vector2(0.5, 0.5)
	password.add_child(sprite)
	
	var label = Label.new()
	label.text = "PASSWORD"
	label.scale = Vector2(0.8, 0.8)
	label.position = Vector2(-40, -45)
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	password.add_child(label)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	password.add_child(col)
	
	password.position = Vector2(1050, 360) # Spawns high in air
	items_container.add_child(password)

func _scroll_objects(delta: float) -> void:
	# Scroll Cacti
	for cactus in cacti_container.get_children():
		cactus.position.x -= scroll_speed * delta
		if cactus.position.x < -100:
			cactus.queue_free()
			continue
			
		# Check overlap with Croc
		if _hit_cooldown_timer <= 0.0 and _check_overlap(croc, cactus):
			if restart_on_hit:
				_trigger_game_over()
				return
			else:
				# Subtract meters as a penalty instead of restarting
				_score = max(0.0, _score - hit_distance_penalty)
				_hit_cooldown_timer = hit_cooldown
				# Visual impact squeeze effect
				var tween = create_tween()
				tween.tween_property(croc, "scale", Vector2(0.8, 0.8), 0.08)
				tween.tween_property(croc, "scale", Vector2(0.5, 0.5), 0.1)
				# Delete the cactus so they don't hit it again
				cactus.queue_free()
				continue

	# Scroll Items (Cookies and Password)
	for item in items_container.get_children():
		item.position.x -= scroll_speed * delta
		if item.position.x < -100:
			item.queue_free()
			continue
			
		# Check overlap with Croc
		if _check_overlap(croc, item):
			if item.is_in_group("wifi_password"):
				_trigger_win()
			else:
				# It's a cookie!
				var game_state = get_node_or_null("/root/GameState")
				if game_state:
					game_state.data_cookies += 1
				item.queue_free()

func _check_overlap(node1: Node2D, node2: Node2D) -> bool:
	# Simple circle/AABB bounding box distance overlap check for retro robust script-based physics
	var dist = node1.global_position.distance_to(node2.global_position)
	return dist < 45.0

func _trigger_game_over() -> void:
	_is_game_over = true
	game_over_panel.show()
	croc.modulate = Color(0.4, 0.4, 0.4, 1.0) # Grey out

func _restart_game() -> void:
	# Clear obstacles
	for child in cacti_container.get_children():
		child.queue_free()
	for child in items_container.get_children():
		child.queue_free()
		
	_score = 0.0
	_spawn_timer = 0.0
	scroll_speed = 380.0
	_is_game_over = false
	_password_spawned = false
	croc.position = Vector2(150, 480)
	_croc_velocity = Vector2.ZERO
	croc.modulate = Color(0.2, 1.0, 0.2, 1.0) # Deep neon green croc
	game_over_panel.hide()

func _trigger_win() -> void:
	_is_game_over = true
	guide_label.text = "RECONNECTED! RESTORING SYSTEM..."
	guide_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	
	# Scale croc up as visual win effect
	var tween = create_tween()
	tween.tween_property(croc, "scale", Vector2(2.0, 2.0), 0.15)
	tween.tween_property(croc, "scale", Vector2.ZERO, 0.2)
	
	# Reconnect in global state
	var game_state = get_node_or_null("/root/GameState")
	tween.tween_callback(func() -> void:
		if game_state:
			game_state.reconnect_to_internet()
	)

# ─── Parallax Background Methods ──────────────────────────────────────────────
func _setup_parallax_background() -> void:
	# Clear any old children
	for child in far_bg_container.get_children():
		child.queue_free()
	for child in near_bg_container.get_children():
		child.queue_free()
		
	# Spawn Far Background elements (tiny drifting cyber-stars)
	for i in far_elements_count:
		var element = Sprite2D.new()
		element.texture = load("res://icon.svg")
		element.modulate = far_color
		element.position = Vector2(randf_range(0, 1100), randf_range(50, 420))
		element.scale = Vector2(randf_range(0.08, 0.15), randf_range(0.08, 0.15))
		far_bg_container.add_child(element)
		
	# Spawn Near Background elements (medium floating panels)
	for i in near_elements_count:
		var element = Sprite2D.new()
		element.texture = load("res://icon.svg")
		element.modulate = near_color
		element.position = Vector2(randf_range(0, 1100), randf_range(80, 400))
		element.scale = Vector2(randf_range(0.25, 0.4), randf_range(0.25, 0.4))
		element.rotation = randf_range(0, PI)
		near_bg_container.add_child(element)

func _scroll_parallax(delta: float) -> void:
	if _is_game_over:
		return
		
	# Scroll Far Background (Slowly)
	for child in far_bg_container.get_children():
		child.position.x -= scroll_speed * far_scroll_factor * delta
		if child.position.x < -150:
			child.position.x = 1150
			child.position.y = randf_range(50, 420)
			
	# Scroll Near Background (Faster)
	for child in near_bg_container.get_children():
		child.position.x -= scroll_speed * near_scroll_factor * delta
		if child.position.x < -150:
			child.position.x = 1150
			child.position.y = randf_range(80, 400)
