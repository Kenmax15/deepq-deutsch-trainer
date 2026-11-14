extends Node
## Global state (autoload "GameState"): settings, local save file, error
## journal, vocabulary, input actions and audio buses.
## Everything is stored locally in user://deepq_save.json (no cloud).

signal settings_changed

const SAVE_PATH := "user://deepq_save.json"
const SAVE_VERSION := 1
const BUSES := ["Voice", "SFX", "Ambience", "Music"]

const DEFAULT_SETTINGS := {
	"ui_lang": "fr",          # fr | en
	"mode": "learning",       # learning | mission | real
	"immersion": "normal",    # easy | normal | dense
	"subtitles": true,
	"translation": true,
	"vol_master": 1.0,
	"vol_voice": 1.0,
	"vol_sfx": 0.8,
	"vol_ambience": 0.7,
	"vol_music": 0.45,
	"quality": "high",        # low | medium | high | ultra
	"mouse_sensitivity": 1.0,
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var progress: Dictionary = {"missions": {}, "errors": [], "vocab": {}}


func _ready() -> void:
	_setup_input()
	_setup_buses()
	load_game()
	apply_audio_settings()


# ------------------------------------------------------------------ settings
func get_setting(key: String):
	return settings.get(key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value) -> void:
	settings[key] = value
	if key.begins_with("vol_"):
		apply_audio_settings()
	settings_changed.emit()
	save_game()


func apply_audio_settings() -> void:
	_set_bus_linear("Master", settings.vol_master)
	_set_bus_linear("Voice", settings.vol_voice)
	_set_bus_linear("SFX", settings.vol_sfx)
	_set_bus_linear("Ambience", settings.vol_ambience)
	_set_bus_linear("Music", settings.vol_music)


func _set_bus_linear(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(idx, value <= 0.001)


func _setup_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	# A gentle limiter on the master bus keeps the mix safe.
	if AudioServer.get_bus_effect_count(0) == 0:
		AudioServer.add_bus_effect(0, AudioEffectLimiter.new())


func _setup_input() -> void:
	var keys := {
		# Physical key positions: W/A/S/D here are Z/Q/S/D on an AZERTY keyboard.
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT],
		"interact": [KEY_E, KEY_SPACE],
		"hint": [KEY_H],
		"repeat": [KEY_R],
		"pause": [KEY_ESCAPE],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- save/load
func save_game() -> void:
	var data := {"version": SAVE_VERSION, "settings": settings, "progress": progress,
		"saved_at": Time.get_datetime_string_from_system()}
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Save failed: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var dir := DirAccess.open("user://")
	if dir.file_exists(SAVE_PATH.get_file()):
		dir.remove(SAVE_PATH.get_file())
	dir.rename(tmp.get_file(), SAVE_PATH.get_file())


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable, starting fresh.")
		return
	for k in parsed.get("settings", {}):
		if DEFAULT_SETTINGS.has(k):
			settings[k] = parsed.settings[k]
	var p = parsed.get("progress", {})
	if typeof(p) == TYPE_DICTIONARY:
		for k in ["missions", "errors", "vocab"]:
			if p.has(k):
				progress[k] = p[k]


func reset_progress() -> void:
	progress = {"missions": {}, "errors": [], "vocab": {}}
	save_game()


# --------------------------------------------------------- mission progress
func mission_record(mission_id: String) -> Dictionary:
	if not progress.missions.has(mission_id):
		progress.missions[mission_id] = {"completed": false, "best_score": 0, "attempts": 0, "checkpoint": {}}
	return progress.missions[mission_id]


func log_error(entry: Dictionary) -> void:
	entry["time"] = Time.get_datetime_string_from_system()
	progress.errors.append(entry)
	if progress.errors.size() > 500:
		progress.errors = progress.errors.slice(-500)


func add_vocab(item: Dictionary) -> void:
	var key: String = item.get("de", "")
	if key == "":
		return
	var v: Dictionary = progress.vocab.get(key, {"status": "new", "seen": 0})
	v.merge(item, true)
	v.seen = int(v.get("seen", 0)) + 1
	if v.seen >= 3 and v.status == "new":
		v.status = "learning"
	progress.vocab[key] = v
