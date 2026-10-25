extends Control

@onready var main_menu: VBoxContainer = $MainMenu/ButtonsVBox
@onready var gallery_panel: Control = $GalleryPanel
@onready var options_panel: Control = $OptionsPanel

# Gallery UI
@onready var gallery_image: TextureRect = $GalleryPanel/ContentHBox/ImageFrame/GalleryTexture
@onready var gallery_title: Label = $GalleryPanel/ContentHBox/InfoVBox/ArtTitle
@onready var gallery_desc: Label = $GalleryPanel/ContentHBox/InfoVBox/ArtDesc
@onready var gallery_counter: Label = $GalleryPanel/ContentHBox/InfoVBox/CounterLabel

# Audio
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var current_art_idx: int = 0
var artworks = [
	{
		"path": "res://assets/sprites/aria_pilot_pinup.png",
		"title": "[ARIA SOLARA] Master Pilot Pinup",
		"desc": "Lead ace pilot of the Veil Fleet. Full-body uniform pose showcasing the white and magenta suit with strategic sideboob/underboob cutouts, exposed midriff, high-slit skirt, and thigh-high stockings with garter straps."
	},
	{
		"path": "res://assets/sprites/aria_action_ecchi.png",
		"title": "[ARIA SOLARA] Cockpit Action Battle Pose",
		"desc": "High-intensity cockpit battle illustration under neon planetary lighting. Used as the in-game Temptation Burst special attack cut-in."
	},
	{
		"path": "res://assets/sprites/aria_blush_clean.png",
		"title": "[ARIA SOLARA] Natural Anime Blush",
		"desc": "Flustered reactive expression with natural rosy cheeks and a bashful teasing smile. Appears in the HUD during near-misses and enemy impacts."
	},
	{
		"path": "res://assets/sprites/aria_victory_pinup.png",
		"title": "[ARIA SOLARA] Teasing Victory Pinup",
		"desc": "Celebration pinup with playful wink and peace sign, displayed upon clearing boss encounters and advancing to the next sector."
	},
	{
		"path": "res://assets/sprites/lyra_pilot_pinup.png",
		"title": "[LYRA VEX] Rival Ace Pinup",
		"desc": "The Crimson Phantom of Sector 3. Jet-black twin tails with crimson highlights, amber eyes, and form-fitting black latex pilot suit with cleavage window and garter thigh-highs."
	},
	{
		"path": "res://assets/sprites/selene_operator_pinup.png",
		"title": "[COMMANDER SELENE] Fleet Tactical Operator",
		"desc": "Voluptuous fleet commander and tactical bridge officer. Wavy blonde hair, slender glasses, unbuttoned white and gold naval pilot jacket showing deep cleavage, tight pencil skirt, and sheer pantyhose."
	},
	{
		"path": "res://assets/sprites/scene_cg_decompression.png",
		"title": "[STORY CG 1] Post-Battle Decompression",
		"desc": "Aria Solara relaxing in the orbital recovery lounge after mission completion. Half-unzipped pilot suit slipping off her shoulder with panoramic cosmic nebula views."
	},
	{
		"path": "res://assets/sprites/scene_cg_rivalry.png",
		"title": "[STORY CG 2] Rival Confrontation",
		"desc": "Pre-flight standoff between Aria Solara and rival ace Lyra Vex in the carrier hangar. Electric sparks of allure and rivalry before launching into the stars."
	}
]

func _ready() -> void:
	gallery_panel.visible = false
	options_panel.visible = false
	load_art(0)
	
	# Start title BGM
	if ResourceLoader.exists("res://assets/audio/bgm_space.wav"):
		bgm_player.stream = load("res://assets/audio/bgm_space.wav")
		bgm_player.volume_db = -6.0
		bgm_player.play()

func _on_start_pressed() -> void:
	play_click()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_gallery_pressed() -> void:
	play_click()
	gallery_panel.visible = true
	$MainMenu.visible = false

func _on_options_pressed() -> void:
	play_click()
	options_panel.visible = true
	$MainMenu.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_gallery_prev_pressed() -> void:
	play_click()
	current_art_idx = (current_art_idx - 1 + artworks.size()) % artworks.size()
	load_art(current_art_idx)

func _on_gallery_next_pressed() -> void:
	play_click()
	current_art_idx = (current_art_idx + 1) % artworks.size()
	load_art(current_art_idx)

func _on_gallery_back_pressed() -> void:
	play_click()
	gallery_panel.visible = false
	$MainMenu.visible = true

func _on_options_back_pressed() -> void:
	play_click()
	options_panel.visible = false
	$MainMenu.visible = true

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	play_click()
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_bgm_toggled(button_pressed: bool) -> void:
	play_click()
	bgm_player.stream_paused = !button_pressed

func load_art(idx: int) -> void:
	var art = artworks[idx]
	if ResourceLoader.exists(art["path"]):
		gallery_image.texture = load(art["path"])
	gallery_title.text = art["title"]
	gallery_desc.text = art["desc"]
	gallery_counter.text = "[ %d / %d ]" % [idx + 1, artworks.size()]

func play_click() -> void:
	if ResourceLoader.exists("res://assets/audio/pickup.wav"):
		sfx_player.stream = load("res://assets/audio/pickup.wav")
		sfx_player.pitch_scale = 1.4
		sfx_player.play()
