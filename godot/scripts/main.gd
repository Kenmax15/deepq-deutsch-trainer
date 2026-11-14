extends Node3D
## Pilot orchestrator: builds the world, spawns the player, the shop
## assistant, passers-by and traffic, and connects the mission logic to the
## HUD, the voices and the soundscape.

const MISSION_PATH := "res://data/missions/brot_kaufen.json"
const VOICE_DIR := "res://assets/audio/voice/brot_kaufen/"
const VEHICLES := ["vehicle-truck-red", "vehicle-truck-yellow", "vehicle-truck-green",
	"vehicle-truck-purple", "vehicle-motorcycle", "vehicle-truck-red"]

var world
var player
var hud
var audio
var mission: MissionRunner
var seller
var passersby: Array = []
var cars: Array = []
var voice: AudioStreamPlayer
var sfx: AudioStreamPlayer
var _queue: Array = []
var _last_line := ""
var _in_dialogue := false
var _started := false
var _welcomed := false


func _ready() -> void:
	world = preload("res://scripts/world.gd").new()
	add_child(world)

	audio = preload("res://scripts/audio_director.gd").new()
	add_child(audio)

	voice = AudioStreamPlayer.new()
	voice.bus = "Voice"
	voice.finished.connect(_on_voice_finished)
	add_child(voice)
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	add_child(sfx)

	player = preload("res://scripts/player.gd").new()
	player.position = world.player_spawn
	add_child(player)
	player.cam_yaw = -PI / 2           # look down the street (+x)
	player.can_move = false

	_spawn_seller()
	_spawn_passersby()
	_spawn_cars()

	mission = MissionRunner.new()
	add_child(mission)
	mission.load_mission(MISSION_PATH)
	mission.reset()
	mission.npc_line.connect(_on_npc_line)
	mission.choices_ready.connect(_on_choices)
	mission.answer_evaluated.connect(_on_answer)
	mission.objective_completed.connect(_on_objective)
	mission.hint_shown.connect(_on_hint)
	mission.mission_finished.connect(_on_finished)

	world.player_entered_bakery.connect(_on_enter_bakery)
	world.player_left_bakery.connect(func(): audio.set_inside(false))
	player.interact_target_changed.connect(_on_target_changed)
	GameState.settings_changed.connect(_apply_settings)

	_build_hud()
	_apply_settings()
	_handle_demo_args()


# --------------------------------------------------------------- spawning
func _human(params: Dictionary) -> Humanoid:
	var h := Humanoid.new()
	for k in params:
		h.set(k, params[k])
	return h


func _spawn_seller() -> void:
	seller = preload("res://scripts/npc.gd").new()
	seller.role = "seller"
	seller.interactable = true
	seller.position = world.seller_spot
	add_child(seller)
	seller.setup(_human({"shirt": Color(0.86, 0.36, 0.4), "pants": Color(0.25, 0.22, 0.3),
		"hair": Color(0.55, 0.32, 0.16), "skin": Color(0.93, 0.76, 0.64), "long_hair": true,
		"apron": true, "height": 1.66}), player)
	seller.avatar.rotation.y = PI    # faces the door / customers


func _spawn_passersby() -> void:
	var looks := [
		{"shirt": Color(0.2, 0.5, 0.35), "pants": Color(0.2, 0.2, 0.25), "hair": Color(0.9, 0.82, 0.6), "skin": Color(0.95, 0.8, 0.7), "height": 1.82},
		{"shirt": Color(0.95, 0.85, 0.3), "pants": Color(0.15, 0.3, 0.55), "hair": Color(0.08, 0.06, 0.05), "skin": Color(0.42, 0.28, 0.2), "long_hair": true, "height": 1.68},
		{"shirt": Color(0.4, 0.4, 0.45), "pants": Color(0.12, 0.12, 0.14), "hair": Color(0.6, 0.6, 0.6), "skin": Color(0.88, 0.7, 0.58), "height": 1.74},
		{"shirt": Color(0.55, 0.25, 0.6), "pants": Color(0.3, 0.25, 0.2), "hair": Color(0.35, 0.2, 0.1), "skin": Color(0.78, 0.58, 0.44), "long_hair": true, "height": 1.62},
	]
	var routes := [
		[Vector3(-40, 0.12, 6.8), Vector3(-8, 0.12, 6.8)],
		[Vector3(30, 0.12, -6.5), Vector3(-30, 0.12, -6.5)],
		[Vector3(-20, 0.12, -5.6), Vector3(10, 0.12, -5.6), Vector3(10, 0.12, -7.0)],
		[Vector3(24, 0.12, 5.4), Vector3(40, 0.12, 5.4)],
	]
	for i in range(looks.size()):
		var n = preload("res://scripts/npc.gd").new()
		n.role = "passerby"
		n.interactable = i == 0          # the first passer-by can be asked the way
		var wps: Array[Vector3] = []
		for p in routes[i]:
			wps.append(p)
		n.waypoints = wps
		n.speed = randf_range(1.0, 1.4)
		n.greet_line = "p_hello" if i % 2 == 0 else "p_hallo"
		n.position = routes[i][0]
		add_child(n)
		n.setup(_human(looks[i]), player)
		passersby.append(n)
	# a customer browsing inside the shop
	var c = preload("res://scripts/npc.gd").new()
	c.role = "customer"
	c.position = Vector3(17.2, 0.12, 12.0)
	add_child(c)
	c.setup(_human({"shirt": Color(0.3, 0.55, 0.75), "pants": Color(0.2, 0.2, 0.2), "hair": Color(0.2, 0.12, 0.08), "skin": Color(0.7, 0.5, 0.38)}), null)
	c.avatar.rotation.y = 0.0


func _spawn_cars() -> void:
	for i in range(VEHICLES.size()):
		var car = preload("res://scripts/vehicle.gd").new()
		car.lane_z = 2.0 if i % 2 == 0 else -2.0
		car.direction = 1.0 if i % 2 == 0 else -1.0
		car.speed = randf_range(7.0, 11.0)
		add_child(car)
		car.setup("res://assets/kenney/vehicles/%s.glb" % VEHICLES[i], 1.6)
		cars.append(car)


# ----------------------------------------------------------------- HUD
func _build_hud() -> void:
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	hud.start_pressed.connect(_on_start)
	hud.option_chosen.connect(func(i): _player_answer(); mission.choose_option(i))
	hud.payment_chosen.connect(func(l): _player_answer(); mission.choose_payment(l))
	hud.free_submitted.connect(func(t): _player_answer(); mission.submit_free(t))
	hud.replay_requested.connect(_replay)
	hud.hint_requested.connect(func(): mission.request_hint())
	hud.model_requested.connect(_on_model_requested)
	hud.replay_mission_requested.connect(_replay_mission)
	hud.set_mission(mission.data, mission.done_objectives)
	if _started:
		hud.set_qubi_visible(GameState.get_setting("mode") != "real")
	else:
		hud.show_start(mission.data, mission.has_checkpoint())


func _on_model_requested(line_id: String) -> void:
	if line_id != "":
		_queue.clear()
		_play_line(line_id, false, true)


func rebuild_hud() -> void:
	hud.queue_free()
	_build_hud()


func _apply_settings() -> void:
	world.apply_quality(GameState.get_setting("quality"))
	var mode: String = GameState.get_setting("mode")
	var preset: String = "dense" if mode == "real" else GameState.get_setting("immersion")
	var p: Dictionary = audio.apply_preset(preset)
	for i in range(cars.size()):
		var on: bool = i < int(p.cars)
		cars[i].visible = on
		cars[i].process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		if on and not cars[i].engine.playing:
			cars[i].engine.play()
		elif not on:
			cars[i].engine.stop()
		cars[i].horn_chance = p.horn
	if hud and _started:
		hud.set_qubi_visible(mode != "real")


# ------------------------------------------------------------- game flow
func _on_start(resume: bool) -> void:
	_started = true
	if resume and mission.restore_checkpoint():
		pass
	else:
		mission.reset()
		GameState.mission_record(mission.mission_id).checkpoint = {}
	hud.set_mission(mission.data, mission.done_objectives)
	player.can_move = true
	hud.set_qubi_visible(GameState.get_setting("mode") != "real")
	if not _welcomed:
		_welcomed = true
		hud.qubi_say(I18n.t("qubi_welcome"), "happy", 9.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _started:
		return
	if event.is_action_pressed("pause"):
		hud.show_settings(not get_tree().paused)
	elif event.is_action_pressed("interact") and not _in_dialogue:
		var t = player.get_target()
		if t == seller:
			_start_dialogue()
		elif t != null and t.role == "passerby":
			_ask_way(t)
	elif event.is_action_pressed("hint") and _in_dialogue:
		mission.request_hint()
	elif event.is_action_pressed("repeat") and _in_dialogue:
		_replay(false)


func _on_target_changed(t) -> void:
	if t == null or _in_dialogue:
		hud.show_prompt("")
	else:
		hud.show_prompt(I18n.t(t.prompt_key()))


func _on_enter_bakery() -> void:
	audio.set_inside(true)
	if not _started or mission.finished:
		return
	mission.complete_objective("enter")
	if GameState.get_setting("mode") != "real":
		hud.qubi_say(I18n.t("qubi_enter"), "happy", 8.0)


func _start_dialogue() -> void:
	if mission.finished:
		_play_line("s_closing")
		return
	_in_dialogue = true
	hud.show_prompt("")
	player.can_move = false
	var tw := create_tween()
	tw.tween_property(player, "global_position", world.counter_front, 0.5)
	player.face_towards(seller.global_position)
	player.cam_yaw = PI
	hud.reset_translation_default()
	mission.begin_dialogue()


func _ask_way(npc) -> void:
	hud.show_line(I18n.t("you"), I18n.t("ask_way"), "")
	hud.end_dialogue_ui()
	await get_tree().create_timer(1.6).timeout
	var len: float = npc.say("p_way")
	var line: Dictionary = mission.line_text("p_way")
	hud.show_line(I18n.t("passerby"), line.de, I18n.pick(line) if GameState.get_setting("translation") else "")
	await get_tree().create_timer(len + 2.5).timeout
	if not _in_dialogue:
		hud.hide_dialogue()


# ----------------------------------------------------------------- voices
func _on_npc_line(line_id: String, _line: Dictionary) -> void:
	_queue.append(line_id)
	if not voice.playing:
		_next_in_queue()


func _next_in_queue() -> void:
	if _queue.is_empty():
		audio.duck(false)
		return
	var id: String = _queue.pop_front()
	_play_line(id)


func _play_line(line_id: String, slow := false, model := false) -> void:
	var stream = load(VOICE_DIR + line_id + ("_slow" if slow else "") + ".wav")
	if stream == null:
		return
	var line: Dictionary = mission.line_text(line_id)
	if not model:
		_last_line = line_id
		seller.avatar.talk(stream.get_length())
	voice.stream = stream
	voice.play()
	audio.duck(true)
	var speaker := I18n.t("seller")
	if model:
		speaker = I18n.t("you") + (" (modèle)" if I18n.lang() == "fr" else " (model)")
	hud.show_line(speaker, line.get("de", ""), I18n.pick(line) if line.has("fr") else "")
	if line_id.begins_with("s_total") and GameState.get_setting("mode") == "learning":
		hud.qubi_say(I18n.t("qubi_pay"), "think", 5.0)


func _on_voice_finished() -> void:
	_next_in_queue()


func _replay(slow: bool) -> void:
	if _last_line != "":
		_queue.clear()
		_play_line(_last_line, slow)


func _player_answer() -> void:
	sfx.stream = load("res://assets/audio/sfx/ui_click.wav")
	sfx.play()


# --------------------------------------------------------- mission events
func _on_choices(_node_id: String, options: Array, kind: String) -> void:
	hud.show_answers(options, kind)
	if GameState.get_setting("mode") == "learning":
		var h := I18n.pick(mission.current_node().get("hint", {}))
		if h != "":
			hud.qubi_say(h, "think", 12.0)


func _on_answer(result: String, fb: String, model_line: String, answer: String) -> void:
	hud.show_feedback(result, fb, answer, model_line)
	var mode: String = GameState.get_setting("mode")
	match result:
		"correct":
			_sfx("success")
			if mode != "real":
				hud.qubi_say(I18n.t("qubi_cheer"), "cheer", 2.5)
		"partial":
			_sfx("hint")
		_:
			_sfx("wrong")
			if mode != "real":
				hud.qubi_say(I18n.t("qubi_oops"), "oops", 3.0)
	if result == "correct" and mission.node_id == "bag":
		world.register.play()


func _sfx(name: String) -> void:
	sfx.stream = load("res://assets/audio/sfx/%s.wav" % name)
	sfx.play()


func _on_objective(id: String) -> void:
	hud.mark_objective(id, true)


func _on_hint(text: String) -> void:
	hud.qubi_say(I18n.t("qubi_hint_cost") + "\n" + text, "think", 12.0)


func _on_finished(summary: Dictionary) -> void:
	hud.end_dialogue_ui()
	await get_tree().create_timer(2.6).timeout
	_in_dialogue = false
	player.can_move = true
	hud.hide_dialogue()
	if GameState.get_setting("mode") != "real":
		hud.qubi_say(I18n.t("qubi_done"), "cheer", 6.0)
	hud.show_results(summary)


func _replay_mission() -> void:
	mission.reset()
	GameState.mission_record(mission.mission_id).checkpoint = {}
	hud.set_mission(mission.data, mission.done_objectives)
	player.global_position = world.player_spawn
	player.cam_yaw = -PI / 2
	_welcomed = false
	_on_start(false)


# ------------------------------------------------- screenshots / recording
func _handle_demo_args() -> void:
	## --demo=street|bakery|dialogue|results places the camera for
	## automated screenshots (used by tests/screenshots.sh).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--demo="):
			_demo(a.substr(7))


func _demo(which: String) -> void:
	if hud.start_panel:
		hud._start(false)
	match which:
		"street":
			player.global_position = Vector3(-16, 0.2, 5.5)
			player.cam_yaw = -PI / 2 - 0.25
			player.cam_pitch = -0.22
			player.cam_dist = 7.5
		"bakery":
			player.global_position = Vector3(9.0, 0.2, 10.0)
			player.cam_yaw = PI - 0.2
			player.cam_pitch = -0.2
			player.cam_dist = 3.0
			_on_enter_bakery()
		"dialogue":
			player.global_position = Vector3(9.0, 0.2, 10.0)
			await get_tree().create_timer(0.3).timeout
			_start_dialogue()
			await get_tree().create_timer(1.0).timeout
			player.cam_dist = 3.4
		"results":
			_start_dialogue()
			await get_tree().create_timer(0.5).timeout
			mission.choose_option(0)
			mission.choose_option(1)
			mission.submit_free("ja zwei brötchens")
			mission.choose_option(0)
			mission.choose_payment(MissionRunner.format_eur(mission.total_cents()))
			mission.choose_option(0)
			mission.choose_option(0)
