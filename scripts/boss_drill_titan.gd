extends Area2D

@export var max_hp: int = 750
var current_hp: int = 750

enum State { ENTERING, HOVERING, CHARGING, RETREATING, DEFEATED }
var state: State = State.ENTERING

var hover_time: float = 0.0
var attack_timer: float = 0.0
var charge_start_pos: Vector2
var charge_target_x: float = 120.0

@onready var sprite: Sprite2D = $Sprite2D
var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	current_hp = max_hp
	position = Vector2(720, 180)
	
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.is_boss_active = true
		gm.emit_signal("boss_spawned", "DRILL TITAN", max_hp)
		gm.emit_signal("dialogue_triggered", "WARNING: Massive Drill Titan detected! Aim for its glowing core!", 4.0)
		
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	match state:
		State.ENTERING:
			position.x = move_toward(position.x, 520.0, 120.0 * delta)
			if position.x <= 522.0:
				state = State.HOVERING
				
		State.HOVERING:
			hover_time += delta
			position.y = 180.0 + sin(hover_time * 1.8) * 80.0
			attack_timer += delta
			
			if attack_timer >= 2.4:
				attack_timer = 0.0
				choose_attack()
				
		State.CHARGING:
			position.x = move_toward(position.x, charge_target_x, 480.0 * delta)
			if position.x <= charge_target_x + 5.0:
				state = State.RETREATING
				
		State.RETREATING:
			position.x = move_toward(position.x, 520.0, 200.0 * delta)
			if position.x >= 518.0:
				state = State.HOVERING

func choose_attack() -> void:
	var roll = randf()
	if roll < 0.45:
		fire_plasma_salvo()
	elif roll < 0.8:
		fire_radial_ring()
	else:
		start_drill_charge()

func fire_plasma_salvo() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var target = players[0].global_position
	var base_dir = (target - global_position).normalized()
	
	for offset in [-0.25, 0.0, 0.25]:
		var dir = base_dir.rotated(offset)
		var b = projectile_scene.instantiate()
		b.global_position = global_position + Vector2(-35, 0)
		b.direction = dir
		b.projectile_type = 4 # ENEMY
		b.is_player = false
		get_parent().add_child(b)

func fire_radial_ring() -> void:
	for i in range(8):
		var angle = (float(i) / 8.0) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		var b = projectile_scene.instantiate()
		b.global_position = global_position
		b.direction = dir
		b.projectile_type = 4
		b.is_player = false
		get_parent().add_child(b)

func start_drill_charge() -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.emit_signal("dialogue_triggered", "Drill Titan is revving its engines! Dodge out of the way!", 2.0)
	# Telegraph flash
	if sprite:
		sprite.modulate = Color(3.0, 0.5, 0.5, 1.0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.6)
		tween.tween_callback(func():
			state = State.CHARGING
		)

func take_damage(amount: int) -> void:
	if state == State.DEFEATED:
		return
	current_hp -= amount
	flash()
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.emit_signal("boss_health_changed", max(0, current_hp), max_hp)
	if current_hp <= 0:
		die()

func flash() -> void:
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.08)

func die() -> void:
	state = State.DEFEATED
	var gm = get_node_or_null("/root/Main/GameManager")
	var audio = get_node_or_null("/root/Main/AudioManager")
	
	if gm:
		gm.add_score(5000)
		gm.is_boss_active = false
		gm.emit_signal("boss_defeated")
		gm.emit_signal("dialogue_triggered", "Aria: \"Target destroyed! Nice shooting, partner~ Ready for the next sector?\"", 4.0)
		
	# Explosion sequence
	for i in range(6):
		get_tree().create_timer(i * 0.12).timeout.connect(func():
			if audio:
				audio.play("explosion", 0.7 + i * 0.1)
		)
		
	# Drop reward cache
	for i in range(5):
		var orb = pickup_scene.instantiate()
		orb.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		orb.type = 0
		get_parent().call_deferred("add_child", orb)
		
	var w = pickup_scene.instantiate()
	w.global_position = global_position
	w.type = 1
	get_parent().call_deferred("add_child", w)
	
	get_tree().create_timer(0.8).timeout.connect(queue_free)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(35)
