extends Node3D
## A car driving along one lane of the street, looping back off-screen.
## Its engine is a spatialised AudioStreamPlayer3D with Doppler, so a car
## that approaches gets louder and then fades away.

@export var lane_z := 2.0
@export var direction := 1.0            # +1 drives towards +x, -1 towards -x
@export var speed := 9.0
@export var x_limit := 60.0
@export var horn_chance := 0.15         # chance per pass to honk near the middle

var engine: AudioStreamPlayer3D
var horn: AudioStreamPlayer3D
var parked := false
var _honked := false
var _wheels: Array[Node3D] = []
var _wheel_r := 0.31

## Typical German car colours (silver, grey, black, white, dark blue, red...)
const PAINTS := [Color(0.62, 0.63, 0.64), Color(0.32, 0.33, 0.35), Color(0.03, 0.03, 0.035),
	Color(0.86, 0.86, 0.85), Color(0.06, 0.12, 0.28), Color(0.45, 0.05, 0.04),
	Color(0.18, 0.22, 0.2), Color(0.5, 0.52, 0.55), Color(0.72, 0.7, 0.66)]


static func make_model(model_path: String, paint: Color) -> Node3D:
	var scene: PackedScene = load(model_path)
	if scene == null:
		return null
	var m: Node3D = scene.instantiate()
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i) as StandardMaterial3D
			if src == null:
				continue
			var n := str(src.resource_name)
			if n.begins_with("paint"):
				var pm: StandardMaterial3D = src.duplicate()
				pm.albedo_color = paint
				pm.metallic = 0.55
				pm.roughness = 0.32
				pm.clearcoat_enabled = true
				pm.clearcoat = 1.0
				pm.clearcoat_roughness = 0.05
				mi.set_surface_override_material(i, pm)
			elif n.begins_with("glass"):
				var g: StandardMaterial3D = src.duplicate()
				g.roughness = 0.03
				g.metallic_specular = 0.9
				mi.set_surface_override_material(i, g)
	return m


func setup(model_path: String, scale_k: float) -> void:
	var m: Node3D
	if model_path.contains("/vehicles/") and not model_path.contains("kenney"):
		m = make_model(model_path, PAINTS[randi() % PAINTS.size()])
		m.rotation.y = PI / 2 * direction
		add_child(m)
		for w in m.find_children("wheel_*", "Node3D", true, false):
			_wheels.append(w)
		if model_path.contains("van"):
			_wheel_r = 0.36
	else:
		var scene: PackedScene = load(model_path)
		if scene:
			m = scene.instantiate()
			m.scale = Vector3.ONE * scale_k
			m.rotation.y = PI / 2 * direction
			m.position.y = 0.45 * scale_k
			add_child(m)
	if parked:
		return
	engine = AudioStreamPlayer3D.new()
	engine.stream = load("res://assets/audio/sfx/engine_loop.wav")   # loops via its WAV 'smpl' chunk
	engine.bus = "SFX"
	engine.unit_size = 6.0
	engine.max_distance = 70.0
	engine.volume_db = -4.0
	engine.pitch_scale = randf_range(0.85, 1.2)
	engine.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_IDLE_STEP
	engine.attenuation_filter_cutoff_hz = 3000
	engine.position.y = 0.6
	add_child(engine)
	horn = AudioStreamPlayer3D.new()
	horn.stream = load("res://assets/audio/sfx/horn.wav")
	horn.bus = "SFX"
	horn.unit_size = 10.0
	horn.max_distance = 90.0
	add_child(horn)
	position = Vector3(randf_range(-x_limit, x_limit), 0, lane_z)
	engine.play()


func _process(delta: float) -> void:
	if parked:
		return
	position.x += direction * speed * delta
	for w in _wheels:
		w.rotate_object_local(Vector3.RIGHT, speed * delta / _wheel_r)
	if abs(position.x) < 4.0 and not _honked:
		_honked = true
		if randf() < horn_chance:
			horn.pitch_scale = randf_range(0.92, 1.08)
			horn.play()
	if position.x * direction > x_limit:
		position.x = -direction * x_limit
		_honked = false
		speed = randf_range(7.0, 11.0)
