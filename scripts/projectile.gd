extends Area2D

enum Type { PULSE, SPREAD, BEAM, SPARK, ENEMY }

@export var projectile_type: Type = Type.PULSE
@export var speed: float = 650.0
@export var damage: int = 25
@export var is_player: bool = true

var direction: Vector2 = Vector2.RIGHT
var target_enemy: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("projectiles")
	setup_visuals()
	area_entered.connect(_on_area_entered)

func setup_visuals() -> void:
	if not sprite:
		return
	match projectile_type:
		Type.PULSE:
			sprite.texture = load("res://assets/sprites/laser_pulse.png")
			damage = 25
			speed = 700.0
		Type.SPREAD:
			sprite.texture = load("res://assets/sprites/laser_spread.png")
			damage = 18
			speed = 600.0
		Type.BEAM:
			sprite.texture = load("res://assets/sprites/laser_beam.png")
			damage = 45
			speed = 900.0
		Type.SPARK:
			sprite.texture = load("res://assets/sprites/laser_spark.png")
			damage = 22
			speed = 520.0
		Type.ENEMY:
			sprite.texture = load("res://assets/sprites/enemy_bullet.png")
			damage = 15
			speed = 320.0
			is_player = false

func _process(delta: float) -> void:
	if projectile_type == Type.SPARK and is_player:
		seek_target(delta)
	
	position += direction * speed * delta
	
	# Out of bounds check (Viewport 640x360 with margin)
	if position.x > 680 or position.x < -40 or position.y < -40 or position.y > 400:
		queue_free()

func seek_target(delta: float) -> void:
	if not is_instance_valid(target_enemy):
		# Find closest enemy in front of projectile
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_dist: float = 99999.0
		for e in enemies:
			if is_instance_valid(e) and e.global_position.x > global_position.x - 20:
				var dist = global_position.distance_to(e.global_position)
				if dist < closest_dist and dist < 350:
					closest_dist = dist
					target_enemy = e
	
	if is_instance_valid(target_enemy):
		var desired = (target_enemy.global_position - global_position).normalized()
		direction = direction.slerp(desired, 10.0 * delta).normalized()
		rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if is_player and area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		# Non-piercing beams vanish on impact
		if projectile_type != Type.BEAM:
			queue_free()
	elif not is_player and area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()
