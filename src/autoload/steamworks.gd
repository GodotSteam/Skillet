extends Node
#################################################
# STEAMWORKS SCRIPT
#################################################
var app_id: int = 3013040
var app_installed_depots: Array = []
var app_languages: String = ""
var app_owner: int = 0
var build_id: int = 0
var dlc_data: Array = []
var dlc_owned_count: int = 0
var dlc_owned_data: Dictionary = { # This dictionary's keys should be the DLC's ID
	}
var game_acquired: int = 0
var godot_promo_owned: Dictionary = { # This dictionary contains Godot and Godot-made games with unlocks in Skillet
	404790: false, 	# Godot Engine
	975150: false,	# Resolutiion
	1369320: false,	# Virtual Cottage
	1573390: false,	# Lila's Sky Ark
	1677360: false,	# Satryn Deluxe
	1942280: false,	# Brotato
	2159650: false,	# Drift
	2276930: false,	# Chillquarium
	2726450: false,	# WindowKill
	2807390: false,	# District Panic
	3013040: false, # Skillet
	}
var install_dir: Dictionary = {}
var is_low_violence: bool = false
var is_on_steam_deck: bool = false
var is_on_vr: bool = false
var is_parental_blocked: bool = false
var is_vac_banned: bool = false
var language_game: String = ""
var language_ui: String = "EN"
var launch_command_line: String = ""
var owns_skillet: bool = false
var steam_id: int = 0
var username: String = "Player"

signal steamworks_error


func check_promo_apps() -> void:
	# Add additional app checks for other Godot-made games to unlock cross-over skins, cosmetics,
	# stickers, etc.
	for this_game in godot_promo_owned.keys():
		godot_promo_owned[this_game] = Steam.isSubscribedApp(this_game)
	# Add all related promo Steam Inventory items
	Inventory.grant_promo_items()
	# Check what other promo items the player is eligible for
	Inventory.get_promo_eligibility()


func collect_build_data() -> void:
	build_id = Steam.getAppBuildId()
	Logging.write(name, "Steam build ID: %s" % build_id)
	install_dir = Steam.getAppInstallDir(app_id)
	Logging.write(name, "Steam install directory and size: %s" % install_dir)


func collect_dlc_data() -> void:
	Logging.write(name, "Gathering DLC data")
	# Get and index all DLC available
#	dlc_data = Steam.getDLCData()
	for this_dlc in dlc_data:
		Logging.write(name, "DLC %s / %s, available: %s" % [this_dlc['id'], this_dlc['name'], this_dlc['available']])
		dlc_owned_data[this_dlc['id']] = {"owned": false, "installed": false}

	# Is the DLC installed?
	dlc_owned_count = Steam.getDLCCount()
	if dlc_owned_count > 0:
		for this_dlc_id in dlc_owned_data.keys():
			dlc_owned_data[this_dlc_id]['installed'] = Steam.isDLCInstalled(this_dlc_id)
			# If it isn't installed, let's install it
			if not dlc_owned_data[this_dlc_id]['installed']:
				install_optional_dlc(this_dlc_id)
	Logging.write(name, "DLC checking finished")


func collect_skillet_data() -> void:
	app_owner = Steam.getAppOwner()
	app_languages = Steam.getAvailableGameLanguages()
	app_installed_depots = Steam.getInstalledDepots(app_id)
	launch_command_line = Steam.getLaunchCommandLine()
	is_low_violence = Steam.isLowViolence()
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_on_vr = Steam.isSteamRunningInVR()
	godot_promo_owned[app_id] = Steam.isSubscribed()

	if Settings.debug_mode:
		Logging.write(name, "App owner: %s" % app_owner)
		Logging.write(name, "App languages: %s" %  app_languages)
		Logging.write(name, "Installed depots: %s" % app_installed_depots)
		Logging.write(name, "Launch commands: %s" % launch_command_line)
		Logging.write(name, "Is low violence: %s" % is_low_violence)
		Logging.write(name, "Running on Steam Deck: %s" % is_on_steam_deck)
		Logging.write(name, "Running on VR: %s" % is_on_vr)
		Logging.write(name, "User owns Skillet: %s" % godot_promo_owned[app_id])


# We will get some general data about the user's setup from Steam. This will let us know if we need
# to change the in-game language (if that is possible), if we should try to block multiplayer due to
# VAC bans, etc. Oh, and the Steam ID!  Most important piece.
func collect_user_data() -> void:
	steam_id = Steam.getSteamID()
	language_game = Steam.getCurrentGameLanguage()
	language_ui = Steam.getSteamUILanguage()
	game_acquired = Steam.getEarliestPurchaseUnixTime(app_id)
	var acquired_dict: Dictionary = Time.get_date_dict_from_unix_time(game_acquired)
	is_vac_banned = Steam.isVACBanned()

	if Settings.debug_mode:
		Logging.write(name, "User Steam ID: %s" % steam_id)
		Logging.write(name, "Steam game language: %s" % language_game)
		Logging.write(name, "Steam UI language: %s" % language_ui)
		Logging.write(name, "Game acquired on: %s/%s/%s" % [acquired_dict['day'], acquired_dict['month'], acquired_dict['year']])
		Logging.write(name, "Is VAC banned: %s" % is_vac_banned)


func connect_steam_callbacks() -> void:
	steam_callback_wrapper("dlc_installed", "_on_dlc_installed")
	steam_callback_wrapper("current_stats_received", "_on_user_stats_received")
	steam_callback_wrapper("user_stats_received", "_on_user_stats_received")


func initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		if Steam.isSteamRunning():
			var initialize_data: Dictionary = Steam.steamInitEx(true, app_id, true)
			Logging.write(name, "Did Steam initialize: %s" % initialize_data)
			
			if initialize_data['status'] != Steam.STEAM_API_INIT_RESULT_OK:
				# Should trigger a pop-up in boot process to inform user the game is shutting down instead of just closing
				Logging.write(name, "Failed to initialize Steam. Reason: %s" % initialize_data['verbose'])
				steamworks_error.emit("Failed to initialized Steam! Skillet will now shut down. Check your log files to find out more.")
				return
 
			connect_steam_callbacks()
			# Collect data about everything
			collect_build_data()
			collect_user_data()
			collect_skillet_data()
			collect_dlc_data()
			# See if the player has any of the other Godot-made games
			check_promo_apps()
			Logging.write(name, "Finished Steam initialization process")

			print(Steam.get_godotsteam_version())
			print(Steam.current_steam_id)
			print(Steam.current_app_id)


# CALLBACKS / SIGNALS
#################################################
func _on_dlc_installed(this_dlc_id: int) -> void:
	Logging.write(name, "DLC %s installed" % this_dlc_id)


func _on_user_stats_received(user_id: int, result: int, app_id: int) -> void:
	Logging.write(name, "Received local player stats from Steam: %s / %s / %s" % [user_id, result, app_id])
	if user_id != Steamworks.steam_id:
		Logging.write(name, "Stats belong to %s instead; aborting Steam stat and achievement loading" % user_id)
		return

	if app_id != Steamworks.app_id:
		Logging.write(name, "Stats are for a different app ID: %s" % app_id)
		return

	if result != Steam.RESULT_OK:
		Logging.write(name, "Failed to get stats and achievements from Steam: %s" % result)
		return

	Settings.load_steam_stats()
	Settings.load_steam_achievements()


# PARENTAL SETTINGS
#################################################
# Checking various block list and app blocks
# Clean this up later.  :D
func check_parental_settings() -> void:
	if Steam.isAppBlocked(app_id):
		is_parental_blocked = true
	if Steam.isAppInBlockList(app_id):
		is_parental_blocked = true
	# Can check for features?
	# Need to check what features can be blocked and if they are used:
	# isFeatureBlocked
	# isFeatureInBlockList
	if Steam.isParentalLockEnabled():
		# Eh? Eh?
		pass
	if Steam.isParentalLockLocked():
		is_parental_blocked = true


func make_human(this_result: int) -> String:
	var result_message: String = "Got unexpected result (%s)" % this_result
	match this_result:
		Steam.RESULT_OK: result_message = "All good."
		Steam.RESULT_INSUFFICIENT_PRIVILEGE: result_message = "You are currently restricted from uploading content due to a hub ban, account lock, or community ban."
		Steam.RESULT_BANNED: result_message = "You do not have permission to upload content to this hub due to a VAC or game ban."
		Steam.RESULT_TIMEOUT: result_message = "This is taking longer than expected. Please retry."
		Steam.RESULT_NOT_LOGGED_ON: result_message = "You are not logged into Steam."
		Steam.RESULT_SERVICE_UNAVAILABLE: result_message = "The workshop server is having issues. Please retry."
		Steam.RESULT_INVALID_PARAM: result_message = "One of the submission fields contains something not accepted by that field."
		Steam.RESULT_ACCESS_DENIED: result_message = "There was a problem trying to save the title and description."
		Steam.RESULT_LIMIT_EXCEEDED: result_message = "You have exceeded your Steam Cloud quota."
		Steam.RESULT_FILE_NOT_FOUND: result_message = "The uploaded file cannot be found."
		Steam.RESULT_DUPLICATE_REQUEST: result_message = "You already have a Steam Workshop item with that name."
		Steam.RESULT_SERVICE_READ_ONLY: result_message = "Due to a recent password or e-mail change, you are not allowed to upload new content."
	return result_message


# STEAMWORKS HELPERS
#################################################
func install_optional_dlc(this_dlc_id: int) -> void:
	Logging.write(name, "Installing DLC: %s" % this_dlc_id)
	Steam.installDLC(this_dlc_id)


func set_rich_presence(this_presence: String) -> void:
	var was_success: bool = Steam.setRichPresence("steam_display",  this_presence)
	Logging.write(name, "Changing rich presence to %s. Success? %s" % [this_presence, was_success])


func set_statistic(this_stat: String, new_value: int = 0) -> void:
	if not Settings.statistics.has(this_stat):
		Logging.write(name, "This statistic does not exist locally: %s" % this_stat)
		return
	Settings.statistics[this_stat] = new_value

	if not Steam.setStatInt(this_stat, new_value):
		Logging.write(name, "Failed to set stat %s to: %s" % [this_stat, new_value])
		return

	if Settings.debug_mode:
		Logging.write(name, "Set statistics %s succesfully: %s" % [this_stat, new_value])


func steam_callback_wrapper(this_signal: String, this_function: String) -> void:
	var callback_connect: int = Steam.connect(this_signal, Callable(self, this_function))
	if callback_connect > OK:
		Logging.write(name, "Connecting callback %s to %s failed: %s" % [this_signal, this_function, callback_connect])


func store_steam_data() -> void:
	if not Steam.storeStats():
		Logging.write(name, "Failed to store data on Steam, should be stored locally")
	Logging.write(name, "Data successfully sent to Steam")


func trigger_achievement(this_achievement: int) -> void:
	if not Settings.achievements.has(this_achievement):
		Logging.write(name, "This achievement does not exist locally: %s" % this_achievement)
		return
	Settings.achievements[this_achievement] = true

	if not Steam.setAchievement("achieve%s" % this_achievement):
		Logging.write(name, "Failed to set achievement: %s" % this_achievement)
		return
	Logging.write(name, "Set achievement: %s" % this_achievement)
	# Let's pop that achievement, son
	store_steam_data()
