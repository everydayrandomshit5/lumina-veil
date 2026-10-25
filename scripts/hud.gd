extends CanvasLayer

@onready var hp_bar: ProgressBar = $TopLeft/VBox/HPBar
@onready var shield_bar: ProgressBar = $TopLeft/VBox/ShieldBar
@onready var score_label: Label = $TopCenter/ScoreLabel
@onready var charm_bar: ProgressBar = $BottomCenter/CharmVBox/CharmBar
@onready var charm_status_label: Label = $BottomCenter/CharmVBox/StatusLabel
@onready var dialogue_box: PanelContainer = $DialogueContainer
@onready var dialogue_label: Label = $DialogueContainer/MarginContainer/DialogueLabel
@onready var portrait_rect: TextureRect = $PortraitBox/PortraitTexture

# Boss UI
@onready var boss_container: VBoxContainer = $BossContainer
@onready var boss_name_label: Label = $BossContainer/BossName
@onready var boss_hp_bar: ProgressBar = $BossContainer/BossHPBar

# Burst Cut-In Overlay
@onready var burst_overlay: Control = $BurstCutinOverlay
@onready var burst_portrait: TextureRect = $BurstCutinOverlay/BurstPortrait
@onready var burst_label: Label = $BurstCutinOverlay/BurstLabel

# Panels
@onready var game_over_panel: Control = $GameOverPanel
@onready var pause_panel: Control = $PausePanel
@onready var victory_panel: Control = $VictoryPanel
@onready var victory_score_label: Label = $VictoryPanel/ContentHBox/VBox/ScoreTally

var dialogue_hide_timer: float = 0.0
var neutral_portrait: Texture2D
var blush_portrait: Texture2D
var mood_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boss_container.visible = false
	burst_overlay.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false
	victory_panel.visible = false
	dialogue_box.visible = false
	
	neutral_portrait = load("res://assets/sprites/aria_hud_neutral.png")
	blush_portrait = load("res://assets/sprites/aria_hud_blush.png")
	if portrait_rect and neutral_portrait:
		portrait_rect.texture = neutral_portrait
	
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.score_changed.connect(_on_score_changed)
		gm.health_changed.connect(_on_health_changed)
		gm.charm_gauge_changed.connect(_on_charm_changed)
		gm.charm_burst_activated.connect(_on_charm_burst)
		gm.dialogue_triggered.connect(_on_dialogue)
		gm.boss_spawned.connect(_on_boss_spawned)
		gm.boss_health_changed.connect(_on_boss_hp_changed)
		gm.boss_defeated.connect(_on_boss_defeated)
		gm.game_over.connect(_on_game_over)
		
	# Initial welcome dialogue
	show_dialogue("Aria: \"Engines primed and ready, pilot! Let's clear these skies~\"", 4.0)

func _process(delta: float) -> void:
	# Pause toggle
	if Input.is_key_pressed(KEY_ESCAPE) or Input.is_key_pressed(KEY_P):
		if not game_over_panel.visible and not victory_panel.visible:
			toggle_pause()

	if dialogue_hide_timer > 0:
		dialogue_hide_timer -= delta
		if dialogue_hide_timer <= 0:
			dialogue_box.visible = false
			
	if mood_timer > 0:
		mood_timer -= delta
		if mood_timer <= 0 and portrait_rect and neutral_portrait:
			portrait_rect.texture = neutral_portrait

func toggle_pause() -> void:
	var new_paused = !get_tree().paused
	get_tree().paused = new_paused
	pause_panel.visible = new_paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_panel.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_title_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_menu.tscn")

func _on_victory_continue_pressed() -> void:
	victory_panel.visible = false
	get_tree().paused = false
	var spawner = get_node_or_null("/root/Main/EnemySpawner")
	if spawner:
		spawner._on_boss_defeated()

func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %07d" % new_score

func _on_health_changed(hp: int, max_hp: int, shield: int, max_shield: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	shield_bar.max_value = max_shield
	shield_bar.value = shield
	
	if hp < max_hp and hp > 0:
		if portrait_rect and blush_portrait:
			portrait_rect.texture = blush_portrait
			mood_timer = 2.0

func _on_charm_changed(current: float, max_val: float) -> void:
	charm_bar.max_value = max_val
	charm_bar.value = current
	if current >= max_val:
		charm_status_label.text = "★ CHARM BURST READY! [SHIFT] ★"
		charm_status_label.modulate = Color(1.0, 0.4, 0.8, 1.0)
	else:
		charm_status_label.text = "CHARM GAUGE: %d%%" % int((current / max_val) * 100)
		charm_status_label.modulate = Color(0.8, 0.8, 1.0, 0.9)

func _on_charm_burst() -> void:
	burst_overlay.visible = true
	burst_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(burst_overlay, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.1)
	tween.tween_property(burst_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		burst_overlay.visible = false
	)

func _on_dialogue(text: String, duration: float) -> void:
	show_dialogue(text, duration)

func show_dialogue(text: String, duration: float) -> void:
	dialogue_label.text = text
	dialogue_box.visible = true
	dialogue_hide_timer = duration

func _on_boss_spawned(b_name: String, max_hp: int) -> void:
	boss_container.visible = true
	boss_name_label.text = "WARNING: " + b_name
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = max_hp

func _on_boss_hp_changed(curr: int, max_hp: int) -> void:
	boss_hp_bar.value = curr

func _on_boss_defeated() -> void:
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(boss_container, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		boss_container.visible = false
		boss_container.modulate.a = 1.0
		
		# Trigger Victory Pinup Screen
		var gm = get_node_or_null("/root/Main/GameManager")
		var s = gm.score if gm else 5000
		victory_score_label.text = "SECTOR 1 DRILL TITAN DESTROYED\nMISSION SCORE: %07d\nCLEAR BONUS: +0005000" % s
		victory_panel.visible = true
	)

func _on_game_over() -> void:
	game_over_panel.visible = true
