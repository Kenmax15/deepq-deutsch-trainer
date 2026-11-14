extends CharacterBody3D
## Third-person player avatar: keyboard movement relative to the camera,
## right-drag mouse orbit, wheel zoom, footsteps, interaction lookup.

signal interact_target_changed(target)

const WALK := 2.3
const RUN := 4.2
const GRAVITY := 9.8
const INTERACT_RANGE := 2.6

var can_move := true
var avatar: Node3D   # CharacterModel (fallback: Humanoid)
var cam_yaw := 0.0
var cam_pitch := -0.32
var cam_dist := 4.6
var camera: Camera3D
var _pivot: Node3D
var _arm: SpringArm3D
var _step_player: AudioStreamPlayer3D
var _step_accum := 0.0
var _target: Node = null
var _orbiting := false


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	col.shape = cap
	col.position.y = 0.875
	add_child(col)

	const MODEL := "res://assets/characters/player.glb"
	if ResourceLoader.exists(MODEL):
		avatar = CharacterModel.new()
		avatar.model_path = MODEL
	else:
		var h := Humanoid.new()
		h.shirt = Color(0.86, 0.42, 0.24)
		h.pants = Color(0.20, 0.27, 0.40)
		avatar = h
	add_child(avatar)
	var hm := Marker3D.new()
	hm.name = "HeadMarker"
	hm.position.y = 1.62
	add_child(hm)

	_pivot = Node3D.new()
	_pivot.position.y = 1.55
	_pivot.top_level = true
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.spring_length = cam_dist
	_arm.margin = 0.2
	_arm.collision_mask = 1
	_pivot.add_child(_arm)
	camera = Camera3D.new()
	camera.fov = 62
	camera.current = true
	_arm.add_child(camera)

	_step_player = AudioStreamPlayer3D.new()
	_step_player.stream = load("res://assets/audio/sfx/footstep.wav")
	_step_player.bus = "SFX"
	_step_player.volume_db = -10
	_step_player.unit_size = 3.0
	add_child(_step_player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_dist = max(2.2, cam_dist - 0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_dist = min(9.0, cam_dist + 0.4)
	elif event is InputEventMouseMotion and _orbiting:
		var k: float = 0.005 * float(GameState.get_setting("mouse_sensitivity"))
		cam_yaw -= event.relative.x * k
		cam_pitch = clamp(cam_pitch - event.relative.y * k, -1.1, 0.25)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis_yaw := Basis(Vector3.UP, cam_yaw)
	var dir := basis_yaw * Vector3(input.x, 0, input.y)
	var speed := RUN if Input.is_action_pressed("run") else WALK
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	var flat_speed := Vector2(velocity.x, velocity.z).length()
	avatar.set_walk_speed(flat_speed)
	if flat_speed > 0.2:
		var target_yaw := atan2(velocity.x, velocity.z)
		avatar.rotation.y = lerp_angle(avatar.rotation.y, target_yaw, delta * 10.0)
		_step_accum += flat_speed * delta
		if _step_accum > 0.75:
			_step_accum = 0.0
			_step_player.pitch_scale = randf_range(0.9, 1.1)
			_step_player.play()

	_pivot.global_position = global_position + Vector3(0, 1.55, 0)
	_pivot.rotation = Vector3(cam_pitch, cam_yaw, 0)
	_arm.spring_length = lerp(_arm.spring_length, cam_dist, delta * 6.0)
	_update_target()


func face_towards(p: Vector3) -> void:
	var d := p - global_position
	avatar.rotation.y = atan2(d.x, d.z)


func _update_target() -> void:
	var best: Node = null
	var best_d := INTERACT_RANGE
	if can_move:
		for n in get_tree().get_nodes_in_group("interactable"):
			if not n.has_method("can_interact") or not n.can_interact():
				continue
			var d: float = global_position.distance_to(n.global_position)
			if d < best_d:
				best_d = d
				best = n
	if best != _target:
		_target = best
		interact_target_changed.emit(_target)


func get_target() -> Node:
	return _target
