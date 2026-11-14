class_name Humanoid
extends Node3D
## Placeholder human built from primitive meshes, animated by code (idle,
## walk, talk, wave). It exposes a tiny interface (set_walk_speed, talk,
## wave) so it can later be swapped for a rigged realistic model.

@export var skin := Color(0.87, 0.69, 0.56)
@export var hair := Color(0.25, 0.17, 0.10)
@export var shirt := Color(0.25, 0.45, 0.70)
@export var pants := Color(0.18, 0.20, 0.26)
@export var shoes := Color(0.12, 0.10, 0.09)
@export var height := 1.75
@export var long_hair := false
@export var apron := false
@export var apron_color := Color(0.95, 0.93, 0.88)

var walk_speed := 0.0         # metres per second, drives the gait
var _phase := 0.0
var _talk_time := 0.0
var _wave_time := 0.0
var _t := 0.0

var _hips: Node3D
var _torso: Node3D
var _head: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D


func _ready() -> void:
	_build()


func set_walk_speed(v: float) -> void:
	walk_speed = v


func talk(seconds: float) -> void:
	_talk_time = max(_talk_time, seconds)


func wave(seconds := 1.6) -> void:
	_wave_time = seconds


func _mat(c: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _capsule(r: float, h: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 16
	m.rings = 6
	mi.mesh = m
	mi.material_override = _mat(c)
	return mi


func _sphere(r: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2
	m.radial_segments = 20
	m.rings = 10
	mi.mesh = m
	mi.material_override = _mat(c, 0.6)
	return mi


func _box(size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = _mat(c)
	return mi


func _build() -> void:
	var s := height / 1.75
	_hips = Node3D.new()
	_hips.position.y = 0.92 * s
	add_child(_hips)

	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(0.1 * side * s, 0, 0)
		_hips.add_child(leg)
		var thigh := _capsule(0.085 * s, 0.9 * s, pants)
		thigh.position.y = -0.43 * s
		leg.add_child(thigh)
		var shoe := _box(Vector3(0.12, 0.08, 0.26) * s, shoes)
		shoe.position = Vector3(0, -0.88 * s, 0.05 * s)
		leg.add_child(shoe)
		if side < 0:
			_leg_l = leg
		else:
			_leg_r = leg

	_torso = Node3D.new()
	_hips.add_child(_torso)
	var body := _capsule(0.2 * s, 0.72 * s, shirt)
	body.scale = Vector3(1.0, 1.0, 0.68)
	body.position.y = 0.32 * s
	_torso.add_child(body)
	if apron:
		var ap := _box(Vector3(0.34, 0.62, 0.02) * s, apron_color)
		ap.position = Vector3(0, 0.12 * s, 0.145 * s)
		_torso.add_child(ap)

	for side in [-1, 1]:
		var arm := Node3D.new()
		arm.position = Vector3(0.245 * side * s, 0.58 * s, 0)
		_torso.add_child(arm)
		var sleeve := _capsule(0.062 * s, 0.6 * s, shirt.darkened(0.08))
		sleeve.position.y = -0.27 * s
		arm.add_child(sleeve)
		var hand := _sphere(0.055 * s, skin)
		hand.position.y = -0.6 * s
		arm.add_child(hand)
		if side < 0:
			_arm_l = arm
		else:
			_arm_r = arm

	var neck := _capsule(0.05 * s, 0.14 * s, skin)
	neck.position.y = 0.72 * s
	_torso.add_child(neck)
	_head = Node3D.new()
	_head.position.y = 0.88 * s
	_torso.add_child(_head)
	var skull := _sphere(0.115 * s, skin)
	skull.scale = Vector3(0.92, 1.08, 1.0)
	_head.add_child(skull)
	var hair_cap := _sphere(0.122 * s, hair)
	hair_cap.scale = Vector3(0.95, 0.75, 1.0)
	hair_cap.position = Vector3(0, 0.045 * s, -0.018 * s)
	_head.add_child(hair_cap)
	if long_hair:
		var back := _capsule(0.1 * s, 0.32 * s, hair)
		back.position = Vector3(0, -0.07 * s, -0.07 * s)
		back.scale = Vector3(1.15, 1.0, 0.6)
		_head.add_child(back)
	for side in [-1, 1]:
		var eye := _sphere(0.016 * s, Color(0.08, 0.07, 0.07))
		eye.position = Vector3(0.042 * side * s, 0.012 * s, 0.105 * s)
		_head.add_child(eye)
	var nose := _sphere(0.02 * s, skin.darkened(0.06))
	nose.position = Vector3(0, -0.015 * s, 0.118 * s)
	_head.add_child(nose)


func _process(delta: float) -> void:
	if _hips == null:
		return
	_t += delta
	var moving: float = clamp(walk_speed / 1.4, 0.0, 1.6)
	_phase += delta * (2.0 + walk_speed * 3.4)
	var swing: float = sin(_phase) * 0.55 * min(moving, 1.0)
	_leg_l.rotation.x = swing
	_leg_r.rotation.x = -swing
	_arm_l.rotation.x = -swing * 0.8
	_arm_r.rotation.x = swing * 0.8
	_arm_l.rotation.z = -0.06
	_arm_r.rotation.z = 0.06
	var bob: float = abs(sin(_phase)) * 0.03 * min(moving, 1.0)
	var breathe: float = sin(_t * 1.6) * 0.006
	_hips.position.y = 0.92 * height / 1.75 + bob
	_torso.scale = Vector3(1, 1.0 + breathe, 1)
	_torso.rotation.x = 0.05 * min(moving, 1.0)

	if _talk_time > 0.0:
		_talk_time -= delta
		_head.rotation.x = sin(_t * 9.0) * 0.06
		_head.rotation.y = sin(_t * 2.3) * 0.08
		_arm_r.rotation.x = -0.35 + sin(_t * 3.0) * 0.15
	else:
		_head.rotation.x = lerp(_head.rotation.x, 0.0, delta * 4.0)
		_head.rotation.y = lerp(_head.rotation.y, sin(_t * 0.4) * 0.15, delta * 2.0)

	if _wave_time > 0.0:
		_wave_time -= delta
		_arm_r.rotation.x = -2.6
		_arm_r.rotation.z = 0.25 + sin(_t * 10.0) * 0.35
