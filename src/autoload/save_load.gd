extends Node
#################################################
# SAVE / LOAD SCRIPT
# Handles all of our saving and loading files
#################################################
var file_paths: Dictionary = {
	"ban_list": "user://ban_list.pan",
	"config": "user://settings.cfg",
	"stats": "user://stats.pan"
	}


func check_save_files() -> void:
	for this_file in file_paths.keys():
		Logging.write(name, "Checking for %s file" % this_file)
		if not FileAccess.file_exists(file_paths[this_file]):
			Logging.write(name, "%s file does not exist, creating one" % this_file.capitalize())
			match this_file:
				"ban_list": save_ban_list()
				"config": save_config()
				"stats": save_stats()
		else:
			Logging.write(name, "%s file exists, loading it now" % this_file.capitalize())
			match this_file:
				"ban_list": load_ban_list()
				"config": load_config()
				"stats": load_stats()


# SAVING
##################################################
func save_ban_list() -> void:
	Logging.write(name, "Saving ban list data to file")
	var ban_file: FileAccess = FileAccess.open_compressed(file_paths['ban_list'], FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if not ban_file:
		Logging.write(name, "Failed to save ban list data to file")
	else:
		ban_file.store_var(Settings.ban_list)
		ban_file.close()
		Logging.write(name, "Saved stats successfully")


func save_config() -> void:
	var config_file: ConfigFile = ConfigFile.new()
	config_file.set_value("General", "debug_on", Settings.debug_mode)
	config_file.set_value("General", "skip_confirm", Settings.skip_confirm)
	config_file.set_value("General", "skip_confirm_reset", Settings.skip_confirm_reset)
	config_file.set_value("General", "version", Settings.version)
	config_file.set_value("Game", "can_shake", Settings.can_shake)
	config_file.set_value("Game", "game_mode", Settings.game_mode)
	config_file.set_value("Game", "player_customize", Settings.player_customize)
	config_file.set_value("Display", "display_mode", Settings.display_mode)
	config_file.set_value("Audio", "game_audio", Settings.game_audio)
	config_file.set_value("Multiplayer", "broadcasting_enabled", Settings.broadcasting_enabled)
	config_file.set_value("Multiplayer", "save_ban_lists", Settings.save_ban_lists)
	config_file.save(file_paths['config'])


func save_stats() -> void:
	Logging.write(name, "Saving stats data to file")
	var stats_file: FileAccess = FileAccess.open_compressed(file_paths['stats'], FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if not stats_file:
		Logging.write(name, "Failed to save stats data to file")
	else:
		var stat_data: Dictionary = {
			"version": Settings.version
			}
		stats_file.store_var(stat_data)
		stats_file.close()
		Logging.write(name, "Saved stats successfully")


# LOADING
##################################################
func load_ban_list() -> void:
	Logging.write(name, "Loading ban list")
	var ban_list_file: FileAccess = FileAccess.open_compressed(file_paths['ban_list'], FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if ban_list_file:
		Settings.ban_list = ban_list_file.get_var()
		Logging.write(name, "Ban list file loaded successfully")
	else:
		Logging.write(name, "Failed to load ban list file")


func load_config() -> void:
	var config_file = ConfigFile.new()
	if config_file.load(file_paths['config']) == OK:
		# General settings
		if config_file.has_section_key("General", "debug_on"):
			Settings.debug_mode = config_file.get_value("General", "debug_on")
		if config_file.has_section_key("General", "skip_confirm"):
			Settings.skip_confirm = config_file.get_value("General", "skip_confirm")
		if config_file.has_section_key("General", "skip_confirm_reset"):
			Settings.skip_confirm_reset = config_file.get_value("General", "skip_confirm_reset")
		if config_file.has_section_key("General", "skip_intro"):
			Settings.skip_intro = config_file.get_value("General", "skip_intro")
		if config_file.has_section_key("General", "version"):
			Settings.version = config_file.get_value("General", "version")
		# Game settings
		if config_file.has_section_key("Game", "can_shake"):
			Settings.can_shake = config_file.get_value("Game", "can_shake")
		if config_file.has_section_key("Game", "game_mode"):
			Settings.game_mode = config_file.get_value("Game", "game_mode")
		if config_file.has_section_key("Game", "player_customize"):
			Settings.player_customize = config_file.get_value("Game", "player_customize")
		# Display settings
		if config_file.has_section_key("Display", "display_mode"):
			Settings.display_mode = config_file.get_value("Display", "display_mode")
		# Audio settings
		if config_file.has_section_key("Audio", "game_audio"):
			Settings.game_audio = config_file.get_value("Audio", "game_audio")
			Music.set_audio_volume("master", Settings.game_audio['master'])
			Music.set_audio_volume("music", Settings.game_audio['music'])
			Music.set_audio_volume("sounds", Settings.game_audio['sounds'])
		# Multiplayer settings
		if config_file.has_section_key("Multiplayer", "broadcasting_enabled"):
			Settings.broadcasting_enabled = config_file.get_value("Multiplayer", "broadcasting_enabled")
		if config_file.has_section_key("Multiplayer", "save_ban_lists"):
			Settings.save_ban_lists = config_file.get_value("Multiplayer", "save_ban_lists")
		Logging.write(name, "Config file loaded successfully")


func load_stats() -> void:
	Logging.write(name, "Loading stats file")
	var stats_file: FileAccess = FileAccess.open_compressed(file_paths['stats'], FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if stats_file:
		var stats_data: Dictionary = stats_file.get_var()
		if stats_data.has("achievements"):
			Settings.achievements = stats_data['achievements']
		stats_file.close()
		Logging.write(name, "Stats file loaded successfully")
	else:
		Logging.write(name, "Failed to load stats file")
