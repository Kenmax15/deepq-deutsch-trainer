extends Node3D
## Non-player character. Walks a loop of waypoints (or stands still), greets
## the player once when they come close, and can answer when spoken to.

signal said(speaker_key: String, line_id: String)

@export var role := "passerby"          # passerby | seller
@export var waypoints: Array[Vector3] = []
@export var speed := 1.25
@export var greet_line := "p_hello"
@export var answer_line := "p_way"

var avatar: Node3D   # Humanoid or CharacterModel
var voice: AudioStreamPlayer3D
var interactable := false
var _wp := 0
var _pause := 0.0
var _greeted_cooldown := 0.0
var _player: Node3D
var _voice_dir := "res://assets/audio/voice/brot_kaufen/"


func setup(h: Node3D, player: Node3D) -> void:
	avatar = h
	add_child(avatar)
	_player = player
	voice = AudioStreamPlayer3D.new()
	voice.bus = "Voice"
	voice.unit_size = 4.0
	voice.max_db = 3.0
	voice.position.y = 1.6
	add_child(voice)
	if interactable:
		add_to_group("interactable")


func can_interact() -> bool:
	return interactable and not voice.playing


func prompt_key() -> String:
	return "talk_seller" if role == "seller" else "talk_passerby"


func say(line_id: String) -> float:
	var stream = load(_voice_dir + line_id + ".wav")
	if stream == null:
		return 0.0
	voice.stream = stream
	voice.play()
	var len: float = stream.get_length()
	avatar.talk(len)
	said.emit(role, line_id)
	return len


func _process(delta: float) -> void:
	if avatar == null:
		return
	_greeted_cooldown = max(0.0, _greeted_cooldown - delta)
	var near := _player != null and global_position.distance_to(_player.global_position) < 3.2
	if near and role == "passerby":
		# stop, look at the player and greet once in a while
		avatar.set_walk_speed(0.0)
		var d := _player.global_position - global_position
		avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(d.x, d.z), delta * 5.0)
		if _greeted_cooldown <= 0.0 and not voice.playing:
			_greeted_cooldown = 25.0
			avatar.wave()
			say(greet_line)
		return
	if waypoints.is_empty():
		avatar.set_walk_speed(0.0)
		return
	if _pause > 0.0:
		_pause -= delta
		avatar.set_walk_speed(0.0)
		return
	var target: Vector3 = waypoints[_wp]
	var to := target - global_position
	to.y = 0
	if to.length() < 0.2:
		_wp = (_wp + 1) % waypoints.size()
		_pause = randf_range(0.0, 2.5)
		return
	var step: Vector3 = to.normalized() * speed * delta
	global_position += step
	avatar.set_walk_speed(speed)
	avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(to.x, to.z), delta * 6.0)
