extends Node

signal score_changed(new_score: int)
signal health_changed(hp: int, max_hp: int, shield: int, max_shield: int)
signal charm_gauge_changed(current: float, max_val: float)
signal charm_burst_activated()
signal dialogue_triggered(text: String, duration: float)
signal boss_spawned(boss_name: String, max_hp: int)
signal boss_health_changed(current_hp: int, max_hp: int)
signal boss_defeated()
signal game_over()

var score: int = 0
var max_health: int = 100
var health: int = 100
var max_shield: int = 50
var shield: int = 50

var max_charm: float = 100.0
var charm_gauge: float = 0.0

var current_stage: int = 1
var is_game_over: bool = false
var is_boss_active: bool = false

@onready var audio: Node = get_node_or_null("/root/Main/AudioManager")

func _ready() -> void:
	reset_game()

func reset_game() -> void:
	score = 0
	health = max_health
	shield = max_shield
	charm_gauge = 0.0
	is_game_over = false
	is_boss_active = false
	emit_signal("score_changed", score)
	emit_signal("health_changed", health, max_health, shield, max_shield)
	emit_signal("charm_gauge_changed", charm_gauge, max_charm)

func add_score(amount: int) -> void:
	score += amount
	emit_signal("score_changed", score)

func add_charm(amount: float) -> void:
	charm_gauge = clamp(charm_gauge + amount, 0.0, max_charm)
	emit_signal("charm_gauge_changed", charm_gauge, max_charm)
	if charm_gauge >= max_charm:
		emit_signal("dialogue_triggered", "Charm Gauge fully charged! Press SHIFT for Temptation Burst~", 3.0)

func can_activate_charm_burst() -> bool:
	return charm_gauge >= max_charm

func activate_charm_burst() -> bool:
	if not can_activate_charm_burst():
		return false
	charm_gauge = 0.0
	emit_signal("charm_gauge_changed", charm_gauge, max_charm)
	emit_signal("charm_burst_activated")
	emit_signal("dialogue_triggered", "Aria: \"Take this... Temptation Burst! All eyes on me~\"", 2.5)
	return true

func damage_player(amount: int) -> void:
	if is_game_over:
		return
	if shield > 0:
		var absorbed = min(shield, amount)
		shield -= absorbed
		amount -= absorbed
	if amount > 0:
		health -= amount
	health = max(0, health)
	emit_signal("health_changed", health, max_health, shield, max_shield)
	
	if health <= 0:
		is_game_over = true
		emit_signal("game_over")
		emit_signal("dialogue_triggered", "Aria: \"N-no way... we can't let it end like this...\"", 3.0)

func heal_player(amount: int) -> void:
	health = clamp(health + amount, 0, max_health)
	shield = clamp(shield + int(amount * 0.5), 0, max_shield)
	emit_signal("health_changed", health, max_health, shield, max_shield)
