extends Area2D

enum PickupType { LUMINA_ORB, WEAPON_UPGRADE }

@export var type: PickupType = PickupType.LUMINA_ORB
@export var speed: float = 75.0

var time_elapsed: float = 0.0
var base_y: float = 0.0
var player_ref: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("pickups")
	base_y = position.y
	time_elapsed = randf() * 10.0
	setup_visuals()
	area_entered.connect(_on_area_entered)

func setup_visuals() -> void:
	if not sprite:
		return
	if type == PickupType.LUMINA_ORB:
		sprite.texture = load("res://assets/sprites/pickup_lumina_orb.png")
	else:
		sprite.texture = load("res://assets/sprites/pickup_weapon.png")

func _process(delta: float) -> void:
	time_elapsed += delta * 4.0
	
	# Magnetic attraction to player
	if not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
			
	if is_instance_valid(player_ref):
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < 120.0:
			var pull_dir = (player_ref.global_position - global_position).normalized()
			position += pull_dir * (260.0 - dist * 1.2) * delta
			return
			
	# Regular floating drift
	position.x -= speed * delta
	position.y = base_y + sin(time_elapsed) * 12.0
	
	if position.x < -30:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		collect(area)

func collect(player: Area2D) -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	var audio = get_node_or_null("/root/Main/AudioManager")
	
	if audio:
		audio.play("pickup", 1.0 + randf() * 0.2)
		
	if type == PickupType.LUMINA_ORB:
		if gm:
			gm.add_score(150)
			gm.add_charm(12.0)
	else:
		if gm:
			gm.add_score(300)
		if player.has_method("upgrade_weapon"):
			player.upgrade_weapon()
			
	queue_free()
