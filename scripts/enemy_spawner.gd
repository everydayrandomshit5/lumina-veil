extends Node2D

@export var spawn_enabled: bool = true

var wave_number: int = 1
var wave_timer: float = 0.0
var spawn_cooldown: float = 2.0
var enemies_killed_in_wave: int = 0
var boss_spawned: bool = false

var drone_scene: PackedScene = preload("res://scenes/enemy_drone.tscn")
var kamikaze_scene: PackedScene = preload("res://scenes/enemy_kamikaze.tscn")
var turret_scene: PackedScene = preload("res://scenes/enemy_turret.tscn")
var boss_scene: PackedScene = preload("res://scenes/boss_drill_titan.tscn")

func _ready() -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.boss_defeated.connect(_on_boss_defeated)

func _process(delta: float) -> void:
	if not spawn_enabled or boss_spawned:
		return
		
	wave_timer += delta
	
	if wave_timer >= spawn_cooldown:
		wave_timer = 0.0
		execute_wave_spawn()

func execute_wave_spawn() -> void:
	wave_number += 1
	
	if wave_number >= 12 and not boss_spawned:
		spawn_boss_sequence()
		return
		
	# Determine spawn patterns based on wave
	if wave_number < 4:
		# Drone V-formation or staggered line
		spawn_drone_line(3, 70.0)
		spawn_cooldown = 2.8
	elif wave_number < 8:
		# Mixed drones + kamikaze
		spawn_drone_line(2, 90.0)
		get_tree().create_timer(0.6).timeout.connect(func():
			spawn_kamikaze_pair()
		)
		spawn_cooldown = 3.2
	else:
		# Turret with escorts
		spawn_turret_wave()
		spawn_cooldown = 4.0

func spawn_drone_line(count: int, spacing: float) -> void:
	var start_y = randf_range(60.0, 300.0 - (count * spacing))
	for i in range(count):
		get_tree().create_timer(i * 0.25).timeout.connect(func():
			var drone = drone_scene.instantiate()
			drone.position = Vector2(680, start_y + i * spacing)
			get_parent().add_child(drone)
		)

func spawn_kamikaze_pair() -> void:
	for y_pos in [randf_range(50, 150), randf_range(210, 310)]:
		var k = kamikaze_scene.instantiate()
		k.position = Vector2(680, y_pos)
		get_parent().add_child(k)

func spawn_turret_wave() -> void:
	var t = turret_scene.instantiate()
	t.position = Vector2(680, randf_range(80, 280))
	get_parent().add_child(t)
	
	var d1 = drone_scene.instantiate()
	d1.position = Vector2(720, t.position.y - 45)
	get_parent().add_child(d1)
	
	var d2 = drone_scene.instantiate()
	d2.position = Vector2(720, t.position.y + 45)
	get_parent().add_child(d2)

func spawn_boss_sequence() -> void:
	boss_spawned = true
	var boss = boss_scene.instantiate()
	get_parent().add_child(boss)

func _on_boss_defeated() -> void:
	# After boss defeated, wait 6 seconds and begin Sector 2 / looped harder stage
	get_tree().create_timer(6.0).timeout.connect(func():
		boss_spawned = false
		wave_number = 1
		var gm = get_node_or_null("/root/Main/GameManager")
		if gm:
			gm.current_stage += 1
			gm.emit_signal("dialogue_triggered", "Entering Sector " + str(gm.current_stage) + "! Enemy density increasing~", 3.5)
	)
