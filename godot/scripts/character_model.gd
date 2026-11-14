class_name CharacterModel
extends Node3D
## Rigged, animated character (Quaternius "Ultimate Modular" CC0 models).
## Same interface as the procedural Humanoid (set_walk_speed, talk, wave),
## so NPC, player and dialogue code work with either.

@export var model_path := ""
@export var apron := false
@export var apron_color := Color(0.95, 0.93, 0.88)

var walk_speed := 0.0
var _anim: AnimationPlayer
var _state := ""
var _talk_time := 0.0
var _wave_time := 0.0
var _skel: Skeleton3D

const LOOPING := ["Idle", "Idle_Neutral", "Walk", "Run"]


func _ready() -> void:
	var scene: PackedScene = load(model_path)
	if scene == null:
		push_error("Character model not found: " + model_path)
		return
	var inst: Node3D = scene.instantiate()
	add_child(inst)
	_anim = inst.find_child("AnimationPlayer", true, false)
	_skel = inst.find_child("Skeleton3D", true, false)
	if _anim:
		for n in LOOPING:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_anim.playback_default_blend_time = 0.25
	if _skel and apron:
		_add_apron()
	_play("Idle")


func _add_apron() -> void:
	## A simple apron mesh following the chest bone.
	var chest := _skel.find_bone("Chest")
	if chest < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = "Chest"
	_skel.add_child(att)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.36, 0.62, 0.02)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = apron_color
	m.roughness = 0.9
	mi.material_override = m
	mi.position = Vector3(0, -0.22, 0.13)
	att.add_child(mi)


func set_walk_speed(v: float) -> void:
	walk_speed = v


func talk(seconds: float) -> void:
	## A short hand gesture when starting to speak (no lip-sync yet).
	if _talk_time <= 0.0 and walk_speed < 0.15 and _anim and _anim.has_animation("Interact"):
		_wave_time = min(_anim.get_animation("Interact").length, 1.2)
		_play("Interact", true)
	_talk_time = max(_talk_time, seconds)


func wave(seconds := 1.6) -> void:
	_wave_time = seconds
	_play("Wave", true)


func _play(name: String, force := false) -> void:
	if _anim == null or (_state == name and not force):
		return
	if not _anim.has_animation(name):
		return
	_state = name
	_anim.play(name)


func _process(delta: float) -> void:
	if _wave_time > 0.0:
		_wave_time -= delta
		return
	if walk_speed > 3.0:
		_play("Run")
		_anim.speed_scale = clamp(walk_speed / 4.5, 0.7, 1.4)
	elif walk_speed > 0.15:
		_play("Walk")
		_anim.speed_scale = clamp(walk_speed / 1.5, 0.6, 1.6)
	else:
		_play("Idle")
		_anim.speed_scale = 1.0
	if _talk_time > 0.0:
		_talk_time -= delta

