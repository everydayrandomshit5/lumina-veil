extends Area2D

enum EnemyType { DRONE, KAMIKAZE, TURRET }

@export var enemy_type: EnemyType = EnemyType.DRONE
@export var max_hp: int = 30
@export var speed: float = 140.0
@export var score_value: int = 100

var current_hp: int = 30
var time_alive: float = 0.0
var base_y: float = 0.0
var shoot_timer: float = 0.0
var has_targeted: bool = false
var target_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")

func _ready() -> void:
	add_to_group("enemies")
	base_y = position.y
	current_hp = max_hp
	time_alive = randf() * 5.0
	setup_type()
	area_entered.connect(_on_area_entered)

func setup_type() -> void:
	match enemy_type:
		EnemyType.DRONE:
			max_hp = 30
			speed = 150.0
			score_value = 100
			if sprite:
				sprite.texture = load("res://assets/sprites/enemy_drone.png")
		EnemyType.KAMIKAZE:
			max_hp = 20
			speed = 220.0
			score_value = 150
			if sprite:
				sprite.texture = load("res://assets/sprites/enemy_kamikaze.png")
		EnemyType.TURRET:
			max_hp = 70
			speed = 90.0
			score_value = 250
			if sprite:
				sprite.texture = load("res://assets/sprites/enemy_turret.png")
	current_hp = max_hp

func _process(delta: float) -> void:
	time_alive += delta
	
	match enemy_type:
		EnemyType.DRONE:
			# Sine weave
			position.x -= speed * delta
			position.y = base_y + sin(time_alive * 3.5) * 25.0
		EnemyType.KAMIKAZE:
			# Dive towards player
			if not has_targeted:
				var players = get_tree().get_nodes_in_group("player")
				if players.size() > 0:
					target_y = players[0].global_position.y
					has_targeted = true
			position.x -= speed * delta
			position.y = move_toward(position.y, target_y, 160.0 * delta)
		EnemyType.TURRET:
			# Cruise in, shoot bursts, then continue
			position.x -= speed * delta
			shoot_timer += delta
			if shoot_timer >= 1.6 and position.x > 100:
				shoot_timer = 0.0
				fire_at_player()
				
	if position.x < -60:
		queue_free()

func fire_at_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var target = players[0].global_position
	var dir = (target - global_position).normalized()
	
	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position - Vector2(16, 0)
	bullet.direction = dir
	bullet.projectile_type = 4 # ENEMY
	bullet.is_player = false
	get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	current_hp -= amount
	flash()
	if current_hp <= 0:
		die()

func flash() -> void:
	if sprite:
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)

func die() -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	var audio = get_node_or_null("/root/Main/AudioManager")
	
	if audio:
		audio.play("explosion", 1.0 + randf() * 0.2)
	if gm:
		gm.add_score(score_value)
		
	# Chance to drop Lumina Orb or Weapon
	spawn_drop()
	queue_free()

func spawn_drop() -> void:
	var roll = randf()
	if roll < 0.65:
		var orb = pickup_scene.instantiate()
		orb.global_position = global_position
		orb.type = 0 # LUMINA_ORB
		get_parent().call_deferred("add_child", orb)
	elif roll < 0.85:
		var w = pickup_scene.instantiate()
		w.global_position = global_position
		w.type = 1 # WEAPON_UPGRADE
		get_parent().call_deferred("add_child", w)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(20)
		die()
