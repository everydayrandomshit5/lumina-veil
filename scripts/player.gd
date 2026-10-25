extends Area2D

@export var speed: float = 300.0
@export var fire_rate: float = 0.14

var fire_timer: float = 0.0
var weapon_type: int = 0 # 0: Pulse, 1: Spread, 2: Beam, 3: Spark
var weapon_level: int = 1 # 1 to 3
var invulnerable_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

func _ready() -> void:
	add_to_group("player")
	setup_input_actions()
	position = Vector2(80, 180)

func setup_input_actions() -> void:
	var mappings = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"shoot": [KEY_SPACE],
		"charm_burst": [KEY_SHIFT]
	}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in mappings[action]:
				var ev = InputEventKey.new()
				ev.physical_keycode = key
				InputMap.action_add_event(action, ev)


func _process(delta: float) -> void:
	handle_movement(delta)
	handle_shooting(delta)
	handle_special_attack()
	
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		# Flash sprite
		sprite.modulate.a = 0.4 if fmod(invulnerable_timer * 20.0, 2.0) > 1.0 else 1.0
	else:
		sprite.modulate.a = 1.0

func handle_movement(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
		
	if dir.length() > 0:
		dir = dir.normalized()
		position += dir * speed * delta
		
	# Smooth subtle bank / tilt when climbing or descending
	sprite.rotation = lerp_angle(sprite.rotation, dir.y * 0.15, 12.0 * delta)
	
	# Clamp to left 60% of 640x360 screen per GDD requirement
	position.x = clamp(position.x, 24.0, 384.0)
	position.y = clamp(position.y, 24.0, 336.0)

func handle_shooting(delta: float) -> void:
	fire_timer += delta
	var wants_to_shoot = (
		Input.is_action_pressed("shoot") or 
		Input.is_key_pressed(KEY_SPACE) or 
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	)
	
	var effective_rate = fire_rate
	if weapon_type == 2: # Beam
		effective_rate = 0.22
	elif weapon_type == 3: # Spark
		effective_rate = 0.18
		
	if wants_to_shoot and fire_timer >= effective_rate:
		fire_timer = 0.0
		spawn_projectiles()

func spawn_projectiles() -> void:
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio:
		if weapon_type == 1 or weapon_type == 2:
			audio.play("spread", 1.1)
		else:
			audio.play("laser", 1.0 + randf() * 0.1)

	var spawn_pos = global_position + Vector2(18, 0)
	
	match weapon_type:
		0: # Pulse Laser
			if weapon_level == 1:
				fire_bullet(spawn_pos, Vector2.RIGHT, 0)
			elif weapon_level == 2:
				fire_bullet(spawn_pos + Vector2(0, -6), Vector2.RIGHT, 0)
				fire_bullet(spawn_pos + Vector2(0, 6), Vector2.RIGHT, 0)
			else: # Level 3: Triple stream
				fire_bullet(spawn_pos, Vector2.RIGHT, 0)
				fire_bullet(spawn_pos + Vector2(-4, -10), Vector2.RIGHT, 0)
				fire_bullet(spawn_pos + Vector2(-4, 10), Vector2.RIGHT, 0)
				
		1: # Spread Shot
			if weapon_level == 1:
				fire_bullet(spawn_pos, Vector2.RIGHT, 1)
				fire_bullet(spawn_pos, Vector2(1.0, -0.2).normalized(), 1)
				fire_bullet(spawn_pos, Vector2(1.0, 0.2).normalized(), 1)
			elif weapon_level == 2:
				for angle in [-0.35, -0.15, 0.15, 0.35]:
					fire_bullet(spawn_pos, Vector2(1.0, angle).normalized(), 1)
			else: # Level 3: 5-way fan
				for angle in [-0.45, -0.22, 0.0, 0.22, 0.45]:
					fire_bullet(spawn_pos, Vector2(1.0, angle).normalized(), 1)
					
		2: # Piercing Beam
			fire_bullet(spawn_pos, Vector2.RIGHT, 2)
			if weapon_level >= 2:
				fire_bullet(spawn_pos + Vector2(0, -8), Vector2.RIGHT, 2)
			if weapon_level >= 3:
				fire_bullet(spawn_pos + Vector2(0, 8), Vector2.RIGHT, 2)
				
		3: # Homing Sparks
			fire_bullet(spawn_pos + Vector2(0, -10), Vector2(1.0, -0.4).normalized(), 3)
			fire_bullet(spawn_pos + Vector2(0, 10), Vector2(1.0, 0.4).normalized(), 3)
			if weapon_level >= 2:
				fire_bullet(spawn_pos, Vector2.RIGHT, 3)
			if weapon_level >= 3:
				fire_bullet(spawn_pos + Vector2(-8, -16), Vector2(0.8, -0.6).normalized(), 3)
				fire_bullet(spawn_pos + Vector2(-8, 16), Vector2(0.8, 0.6).normalized(), 3)

func fire_bullet(pos: Vector2, dir: Vector2, p_type: int) -> void:
	var b = projectile_scene.instantiate()
	b.global_position = pos
	b.direction = dir
	b.projectile_type = p_type
	b.is_player = true
	get_parent().add_child(b)

func handle_special_attack() -> void:
	var wants_burst = (
		Input.is_action_just_pressed("charm_burst") or 
		Input.is_key_pressed(KEY_SHIFT) or 
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	)
	if wants_burst:
		var gm = get_node_or_null("/root/Main/GameManager")
		if gm and gm.can_activate_charm_burst():
			trigger_temptation_burst()

func trigger_temptation_burst() -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if gm:
		gm.activate_charm_burst()
	if audio:
		audio.play("charm_burst")
		
	# Screen-clearing wave: destroy all enemy bullets and deal massive damage to enemies
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if is_instance_valid(p) and not p.is_player:
			p.queue_free()
			
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(250)

func upgrade_weapon() -> void:
	if weapon_level < 3:
		weapon_level += 1
	else:
		weapon_level = 1
		weapon_type = (weapon_type + 1) % 4
		
	var names = ["Pulse Laser", "Spread Shot", "Piercing Beam", "Homing Sparks"]
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.emit_signal("dialogue_triggered", "Weapon upgraded: " + names[weapon_type] + " Lv." + str(weapon_level) + "!", 2.0)

func take_damage(amount: int) -> void:
	if invulnerable_timer > 0:
		return
	invulnerable_timer = 1.2
	var gm = get_node_or_null("/root/Main/GameManager")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio:
		audio.play("hit")
	if gm:
		gm.damage_player(amount)
