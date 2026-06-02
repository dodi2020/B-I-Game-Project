extends Node

# Signal declarations
signal health_changed(new_health, max_health)
signal cookies_changed(new_cookies)
signal upgrade_unlocked(upgrade_name)
signal zone_changed(new_zone)
signal glitch_state_changed(is_active)
signal game_saved
signal game_loaded

# Game Stats
var max_health: int = 100
var player_health: int = 100:
	set(value):
		player_health = clamp(value, 0, max_health)
		health_changed.emit(player_health, max_health)
		if player_health <= 0:
			trigger_offline_mode()

var data_cookies: int = 0:
	set(value):
		data_cookies = max(0, value)
		cookies_changed.emit(data_cookies)

# Upgrades (Browser Extensions)
var upgrades = {
	"vpn_tunnel": false,       # Dash
	"ad_blocker": false,       # Invincibility shield
	"incognito_cloak": false,  # Enemy avoidance
	"auto_fill": false         # Magnet pull items
}

# Quest & Story flags
var alt_f2_glitch_active: bool = false:
	set(value):
		alt_f2_glitch_active = value
		glitch_state_changed.emit(alt_f2_glitch_active)

var current_zone: String = "social_media_feed"
var bosses_defeated = {
	"algorithmic_overlord": false
}
var unlocked_logs = []

const SAVE_PATH = "user://savegame.json"

func unlock_upgrade(upgrade_name: String) -> void:
	if upgrades.has(upgrade_name) and not upgrades[upgrade_name]:
		upgrades[upgrade_name] = true
		upgrade_unlocked.emit(upgrade_name)

func trigger_offline_mode() -> void:
	print("No Internet Connection detected! Triggering Offline Protocol...")
	# Save the game state before offline runner begins
	save_game()
	# Transition directly to the offline mini-game scene
	get_tree().change_scene_to_file("res://scenes/offline/offline_game.tscn")

func reconnect_to_internet() -> void:
	player_health = max_health
	print("Connection re-established. Welcome back!")
	# Return the player to the active zone (defaults to social_media_feed or tutorial)
	var target = "res://scenes/levels/" + current_zone + ".tscn"
	# Safe fallback check
	if not ResourceLoader.exists(target):
		target = "res://scenes/levels/tutorial.tscn"
	get_tree().change_scene_to_file(target)

# Save & Load Systems
func save_game() -> void:
	var save_data = {
		"player_health": player_health,
		"max_health": max_health,
		"data_cookies": data_cookies,
		"upgrades": upgrades,
		"alt_f2_glitch_active": alt_f2_glitch_active,
		"current_zone": current_zone,
		"bosses_defeated": bosses_defeated,
		"unlocked_logs": unlocked_logs
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		game_saved.emit()
		print("Game saved successfully.")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_err = json.parse(json_string)
		if parse_err == OK:
			var save_data = json.get_data()
			if save_data is Dictionary:
				player_health = save_data.get("player_health", 100)
				max_health = save_data.get("max_health", 100)
				data_cookies = save_data.get("data_cookies", 0)
				
				var loaded_upgrades = save_data.get("upgrades", {})
				for k in upgrades.keys():
					if loaded_upgrades.has(k):
						upgrades[k] = loaded_upgrades[k]
						
				alt_f2_glitch_active = save_data.get("alt_f2_glitch_active", false)
				current_zone = save_data.get("current_zone", "social_media_feed")
				
				var loaded_bosses = save_data.get("bosses_defeated", {})
				for k in bosses_defeated.keys():
					if loaded_bosses.has(k):
						bosses_defeated[k] = loaded_bosses[k]
						
				unlocked_logs = save_data.get("unlocked_logs", [])
				game_loaded.emit()
				print("Game loaded successfully.")
