extends Node
#################################################
# SETTINGS SCRIPT
#################################################
enum GameModes { FIRE_WATER_SPONGE, GUMBO, HOT_POTATO, PASS_THE_TORCH, TRIAL_BY_FIRE }

# General
var debug_mode: bool = true
var skip_confirm: bool = false
var skip_confirm_reset: bool = false
var skip_intro: bool = true
var version: String = "0.1.0"
# Game
var achievements: Dictionary = { 1: false, 2: false, 3: false, 4: false, 5: false, 6: false, 7: false, 8: false, 9: false, 10: false, 11: false, 12: false }
var bot_names: Array = [
	'bot2trot', 'cold_or_bot', 'bottom', 'botman', 'botris', 'charles', 'bottersby', 'bot_stickers',
	'botgun', 'hotbot', 'gobot', 'chicken bot pie'
	]
var can_shake: bool = true
var game_bots: int = 7
var game_mode: GameModes = GameModes.TRIAL_BY_FIRE
var player_customize: Dictionary = {
	"body": 701,
	"face": 801,
	"cosmetic": 0
	}
# Display
@export var display_mode: int = Window.MODE_MAXIMIZED: set = update_display_mode
# Audio
var game_audio: Dictionary = {
	"last_track":"Menu",
	"master": -20,
	"music": -20,
	"sounds": -20,
	"voice": -20
	}
# Multiplayer
var ban_list: PackedInt64Array = []
var broadcasting_enabled: bool = true
var save_ban_lists: bool = true
var statistics: Dictionary = {
	"win_water": 0,
	"win_sponge": 0,
	"win_fire": 0,
	"win_matches": 0,
	"win_trials": 0,
	"win_potatoes": 0,
	}


func get_random_name() -> String:
	return bot_names.pick_random()


# There is probably a way better way to do this but for now...
func reset_defaults() -> void:
	Logging.write(name, "Restoring default values for all settings")
	broadcasting_enabled = true
	can_shake = true
	debug_mode = false
	display_mode = Window.MODE_MAXIMIZED
	game_audio = {
		"last_track":"Menu",
		"master": -20,
		"music": -20,
		"sounds": -20,
		"voice": -20
		}
	save_ban_lists = true
	skip_confirm = false
	skip_intro = true


# Update the saved ban list then save it to file. Needs a better way of storing the banned users so
# players can go in and manually change this list if they want to.
func update_ban_list(lobby_ban_list: Array) -> void:
	for banned_player in lobby_ban_list:
		if not ban_list.has(banned_player):
			ban_list.append(banned_player)
	SaveLoad.save_data("ban_list")


func update_display_mode(new_display_mode: int) -> void:
	if Steamworks.is_on_steam_deck:
		Logging.write(name, "User is on Steam Deck, ignoring display changes")
		get_tree().get_root().call_deferred("set_mode", Window.MODE_EXCLUSIVE_FULLSCREEN)
	else:
		display_mode = new_display_mode
		Logging.write(name, "Setting display to: %s" % display_mode)
		get_tree().get_root().call_deferred("set_mode", display_mode)


# STATS AND ACHIEVEMENTS
#################################################
func load_steam_stats() -> void:
	for this_stat in statistics.keys():
		var steam_stat: int = Steam.getStatInt(this_stat)

		if statistics[this_stat] > steam_stat:
			if Settings.debug_mode:
				Logging.write(name, "Stat mismatch; local value is higher (%s), replacing Steam value (%s)" % [statistics[this_stat], steam_stat])
			Steamworks.set_statistic(this_stat, statistics[this_stat])
		elif statistics[this_stat] < steam_stat:
			if Settings.debug_mode:
				Logging.write(name, "Stat mismatch; local value is lower (%s), repliacing with Steam value (%s)" % [statistics[this_stat], steam_stat])
			Steamworks.set_statistic(this_stat, steam_stat)
		else:
			if Settings.debug_mode:
				Logging.write(name, "Steam stat matches local file: %s" % this_stat)
	Logging.write(name, "Steam statistics loaded")


func load_steam_achievements() -> void:
	for this_achievement in achievements.keys():
		var steam_achievement: Dictionary = Steam.getAchievement("achieve%s" % this_achievement)

		if not steam_achievement['ret']:
			Logging.write(name, "Steam does not have this achievement, defaulting to local value: achieve%s" % this_achievement)
			break

		if achievements[this_achievement] == steam_achievement['achieved']:
			if Settings.debug_mode:
				Logging.write(name, "Steam achievements match local file, skipping: %s" % this_achievement)
			break

		Steamworks.trigger_achievement(this_achievement)
	Logging.write(name, "Steam achievements loaded")


# HELPERS
#################################################
func write_debug(this_script: String, this_message: String) -> void:
	if debug_mode:
		Logging.write(this_script, this_message)
