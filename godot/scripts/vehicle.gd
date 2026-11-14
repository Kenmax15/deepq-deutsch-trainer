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
var _honked := false


func setup(model_path: String, scale_k: float) -> void:
	var scene: PackedScene = load(model_path)
	if scene:
		var m: Node3D = scene.instantiate()
		m.scale = Vector3.ONE * scale_k
		m.rotation.y = PI / 2 * direction
		m.position.y = 0.45 * scale_k
		add_child(m)
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
	position.x += direction * speed * delta
	if abs(position.x) < 4.0 and not _honked:
		_honked = true
		if randf() < horn_chance:
			horn.pitch_scale = randf_range(0.92, 1.08)
			horn.play()
	if position.x * direction > x_limit:
		position.x = -direction * x_limit
		_honked = false
		speed = randf_range(7.0, 11.0)
