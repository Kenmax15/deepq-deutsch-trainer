extends Node3D
## Builds the pilot environment in code: a German street (Kenney CC0 tiles,
## scaled to metres), pavements, buildings, and the "Bäckerei Becker" with a
## furnished interior. Keeping it in code makes the layout easy to read and
## to tweak; decor can later be moved to hand-made .tscn scenes.

signal player_entered_bakery
signal player_left_bakery

const TILE := 8.0
const CITY := "res://assets/kenney/city/"
const STREET_HALF := 56.0
# Bakery footprint (south side of the street)
const BK_X0 := 4.0
const BK_X1 := 20.0
const BK_Z0 := 8.0
const BK_Z1 := 18.0
const DOOR_X := 8.0

var sun: DirectionalLight3D
var env: Environment
var seller_spot := Vector3(11.0, 0.12, 16.3)
var counter_front := Vector3(11.0, 0.12, 13.6)
var player_spawn := Vector3(-30.0, 0.2, 6.0)
var radio: AudioStreamPlayer3D
var coffee: AudioStreamPlayer3D
var register: AudioStreamPlayer3D
var door_bell: AudioStreamPlayer3D
var inside := false

var _mats := {}


func _ready() -> void:
	_environment()
	_ground()
	_street()
	_buildings()
	_bakery()
	_street_props()


# ---------------------------------------------------------------- helpers
func mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f" % [c.to_html(), rough, metal]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]


func tile(file: String, pos: Vector3, rot_y := 0.0, scale_v := Vector3.ONE * TILE) -> Node3D:
	var scene: PackedScene = load(CITY + file + ".glb")
	var n: Node3D = scene.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = scale_v
	add_child(n)
	return n


func box(size: Vector3, pos: Vector3, m: Material, collide := false, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


func collider(size: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	add_child(sb)


func label(text: String, pos: Vector3, size: int, color: Color, rot_y := 0.0, outline := 8) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = outline
	l.outline_modulate = Color(0.12, 0.08, 0.05)
	l.position = pos
	l.rotation.y = rot_y
	l.double_sided = false
	add_child(l)
	return l


# ------------------------------------------------------------ environment
func _environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.56, 0.86)
	sm.sky_horizon_color = Color(0.78, 0.84, 0.9)
	sm.ground_horizon_color = Color(0.7, 0.72, 0.7)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.83, 0.88)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.2
	env.glow_enabled = false
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


func apply_quality(q: String) -> void:
	var vp := get_viewport()
	match q:
		"low":
			sun.shadow_enabled = false
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.75
			env.ssao_enabled = false
		"high":
			sun.shadow_enabled = true
			vp.msaa_3d = Viewport.MSAA_4X
			vp.scaling_3d_scale = 1.0
			env.ssao_enabled = true
		_:
			sun.shadow_enabled = true
			vp.msaa_3d = Viewport.MSAA_2X
			vp.scaling_3d_scale = 1.0
			env.ssao_enabled = false


# ------------------------------------------------------------ ground/road
func _ground() -> void:
	# One big collider for the walkable level; the visual tiles sit on it.
	collider(Vector3(200, 1, 200), Vector3(0, -0.38, 0))
	box(Vector3(300, 0.1, 300), Vector3(0, -0.05, 0), mat(Color(0.42, 0.55, 0.33)))


func _street() -> void:
	var flat := Vector3(TILE, 2.0, TILE)
	var x := -STREET_HALF
	var i := 0
	while x <= STREET_HALF:
		tile("road-straight-lightposts" if i % 2 == 0 else "road-straight", Vector3(x, 0, 0), PI / 2, flat)
		# pavements on both sides (half a tile deep each)
		tile("pavement", Vector3(x, 0, 6.0), 0.0, Vector3(TILE, 2.0, TILE * 0.5))
		tile("pavement", Vector3(x, 0, -6.0), 0.0, Vector3(TILE, 2.0, TILE * 0.5))
		x += TILE
		i += 1


func _buildings() -> void:
	var kinds := ["building-small-a", "building-small-b", "building-small-c", "building-small-d", "building-small-b", "building-small-c"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var x := -STREET_HALF
	var i := 0
	while x <= STREET_HALF:
		# north side, facing the street (+z)
		tile(kinds[i % kinds.size()], Vector3(x, 0, -12.0), 0.0)
		collider(Vector3(TILE, 12, TILE), Vector3(x, 6, -12.0))
		# south side, facing the street (-z); leave room for the bakery
		if x < BK_X0 - 2.0 or x > BK_X1 + 2.0:
			tile(kinds[(i + 3) % kinds.size()], Vector3(x, 0, 12.0), PI)
			collider(Vector3(TILE, 12, TILE), Vector3(x, 6, 12.0))
		x += TILE
		i += 1


# ------------------------------------------------------------------ bakery
func _bakery() -> void:
	var w := BK_X1 - BK_X0
	var d := BK_Z1 - BK_Z0
	var cx := (BK_X0 + BK_X1) / 2.0
	var cz := (BK_Z0 + BK_Z1) / 2.0
	var h := 7.0
	var plaster := mat(Color(0.93, 0.86, 0.72))
	var wood := mat(Color(0.55, 0.36, 0.2), 0.7)
	var dark_wood := mat(Color(0.33, 0.21, 0.12), 0.6)

	# Shell: outer box minus inner room, minus door and shop window.
	var shell := CSGCombiner3D.new()
	shell.use_collision = true
	add_child(shell)
	var outer := CSGBox3D.new()
	outer.size = Vector3(w, h, d)
	outer.position = Vector3(cx, h / 2.0, cz)
	outer.material = plaster
	shell.add_child(outer)
	var room := CSGBox3D.new()
	room.operation = CSGShape3D.OPERATION_SUBTRACTION
	room.size = Vector3(w - 0.5, 3.4, d - 0.5)
	room.position = Vector3(cx, 0.12 + 1.7, cz)
	room.material = mat(Color(0.97, 0.92, 0.82))
	shell.add_child(room)
	var door := CSGBox3D.new()
	door.operation = CSGShape3D.OPERATION_SUBTRACTION
	door.size = Vector3(1.8, 2.5, 1.0)
	door.position = Vector3(DOOR_X, 0.12 + 1.25, BK_Z0)
	shell.add_child(door)
	var window := CSGBox3D.new()
	window.operation = CSGShape3D.OPERATION_SUBTRACTION
	window.size = Vector3(7.5, 1.9, 1.0)
	window.position = Vector3(14.6, 0.12 + 1.75, BK_Z0)
	shell.add_child(window)

	# Upper-floor windows on the facade
	for wx in [6.0, 10.0, 14.0, 18.0]:
		box(Vector3(1.3, 1.5, 0.1), Vector3(wx, 5.2, BK_Z0 - 0.02), mat(Color(0.35, 0.45, 0.55), 0.2))
		box(Vector3(1.5, 0.12, 0.25), Vector3(wx, 4.4, BK_Z0 - 0.1), plaster)
	# Roof and cornice
	box(Vector3(w + 0.6, 0.4, d + 0.6), Vector3(cx, h + 0.2, cz), mat(Color(0.55, 0.25, 0.2)))
	box(Vector3(w + 0.2, 0.3, 0.3), Vector3(cx, 3.95, BK_Z0 - 0.1), dark_wood)

	# Glass in the shop window and the door frame
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.75, 0.88, 0.95, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.2
	box(Vector3(7.5, 1.9, 0.04), Vector3(14.6, 0.12 + 1.75, BK_Z0), glass)
	box(Vector3(0.12, 2.6, 0.3), Vector3(DOOR_X - 0.96, 1.4, BK_Z0), dark_wood)
	box(Vector3(0.12, 2.6, 0.3), Vector3(DOOR_X + 0.96, 1.4, BK_Z0), dark_wood)
	box(Vector3(2.0, 0.14, 0.3), Vector3(DOOR_X, 2.68, BK_Z0), dark_wood)

	# Striped awning over the window and door
	for k in range(14):
		var stripe := box(Vector3(0.9, 0.05, 1.6), Vector3(5.2 + k * 0.92, 3.55, BK_Z0 - 0.75),
			mat(Color(0.78, 0.16, 0.14) if k % 2 == 0 else Color(0.97, 0.95, 0.9)))
		stripe.rotation.x = deg_to_rad(-16)

	# Sign
	label("Bäckerei Becker", Vector3(cx, 4.6, BK_Z0 - 0.08), 150, Color(0.98, 0.84, 0.45), PI)
	label("Brot · Brötchen · Kaffee", Vector3(14.6, 1.25, BK_Z0 - 0.05), 52, Color(1, 1, 1), PI, 6)
	label("Geöffnet", Vector3(DOOR_X, 2.2, BK_Z0 - 0.2), 40, Color(0.7, 1.0, 0.7), PI, 6)

	# ---------------- interior
	box(Vector3(w - 0.5, 0.04, d - 0.5), Vector3(cx, 0.14, cz), mat(Color(0.62, 0.45, 0.3), 0.6))
	# checkerboard tiles in front of the counter
	for ix in range(8):
		for iz in range(3):
			if (ix + iz) % 2 == 0:
				box(Vector3(1.0, 0.01, 1.0), Vector3(6.5 + ix * 1.0, 0.165, 9.5 + iz * 1.0), mat(Color(0.9, 0.88, 0.84), 0.4))
	# counter with glass display
	box(Vector3(9.0, 1.05, 0.9), Vector3(11.5, 0.12 + 0.525, 15.0), wood, true)
	box(Vector3(9.0, 0.05, 1.0), Vector3(11.5, 1.2, 15.0), dark_wood)
	box(Vector3(8.6, 0.45, 0.7), Vector3(11.5, 1.45, 14.9), glass)
	# breads in the display
	_bread_row(Vector3(8.0, 1.32, 14.9), 7)
	# back shelves
	for sy in [1.0, 1.6, 2.2]:
		box(Vector3(7.0, 0.06, 0.5), Vector3(12.8, sy, 17.5), dark_wood)
		_bread_row(Vector3(9.7, sy + 0.12, 17.5), 7)
	box(Vector3(7.2, 2.6, 0.08), Vector3(12.8, 1.4, 17.78), wood)
	# cash register and coffee machine on the counter
	box(Vector3(0.45, 0.3, 0.4), Vector3(15.3, 1.38, 15.1), mat(Color(0.2, 0.22, 0.25), 0.4, 0.3))
	box(Vector3(0.7, 0.75, 0.55), Vector3(18.0, 1.6, 15.0), mat(Color(0.75, 0.76, 0.78), 0.25, 0.8))
	box(Vector3(0.12, 0.12, 0.12), Vector3(18.0, 1.35, 14.7), mat(Color(0.1, 0.1, 0.1)))
	# a small bistro table by the window
	box(Vector3(0.9, 0.05, 0.9), Vector3(16.5, 0.85, 9.6), dark_wood)
	box(Vector3(0.08, 0.7, 0.08), Vector3(16.5, 0.5, 9.6), mat(Color(0.15, 0.15, 0.15), 0.4, 0.6))
	collider(Vector3(1.0, 1.0, 1.0), Vector3(16.5, 0.5, 9.6))
	# price board
	label("Roggenbrot  2,60 €\nVollkornbrot  2,90 €\nWeißbrot  2,20 €\nBrötchen  0,40 €\nBrezel  0,90 €",
		Vector3(6.3, 2.35, 17.7), 20, Color(1, 1, 1), PI, 4)
	box(Vector3(2.6, 1.4, 0.05), Vector3(6.3, 2.35, 17.74), mat(Color(0.12, 0.14, 0.13), 0.9))

	# warm lights
	for lx in [7.0, 12.0, 17.0]:
		var l := OmniLight3D.new()
		l.position = Vector3(lx, 3.2, 13.0)
		l.light_color = Color(1.0, 0.84, 0.62)
		l.light_energy = 1.6
		l.omni_range = 9.0
		add_child(l)

	# sounds of the shop
	radio = _sound3d("cafe_music_loop", Vector3(6.0, 2.4, 17.4), "Music", 2.0, -6.0)
	coffee = _sound3d("coffee_machine_loop", Vector3(18.0, 1.6, 15.0), "SFX", 2.5, -14.0)
	register = _sound3d("cash_register", Vector3(15.3, 1.4, 15.1), "SFX", 3.0, -4.0, false)
	door_bell = _sound3d("door_bell", Vector3(DOOR_X, 2.4, BK_Z0 + 0.2), "SFX", 4.0, -6.0, false)

	# trigger volumes: door threshold and interior
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(w - 0.6, 3.0, d - 0.8)
	cs.shape = sh
	area.add_child(cs)
	area.position = Vector3(cx, 1.5, cz + 0.2)
	add_child(area)
	area.body_entered.connect(_on_inside_entered)
	area.body_exited.connect(_on_inside_exited)


func _sound3d(file: String, pos: Vector3, bus: String, unit: float, vol: float, autoplay := true) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = load("res://assets/audio/sfx/%s.wav" % file)
	p.bus = bus
	p.unit_size = unit
	p.volume_db = vol
	p.max_distance = 30.0
	p.position = pos
	add_child(p)
	if autoplay:
		p.play()
	return p


func _bread_row(start: Vector3, n: int) -> void:
	var crust := [Color(0.42, 0.24, 0.12), Color(0.62, 0.4, 0.2), Color(0.86, 0.66, 0.38), Color(0.74, 0.5, 0.25)]
	for k in range(n):
		var p := start + Vector3(k * 0.95, 0, 0)
		var kind := k % 4
		var mi := MeshInstance3D.new()
		if kind == 3:
			var tor := TorusMesh.new()          # a Brezel
			tor.inner_radius = 0.06
			tor.outer_radius = 0.16
			mi.mesh = tor
			mi.rotation.x = PI / 2
		elif kind == 2:
			var sp := SphereMesh.new()          # Brötchen
			sp.radius = 0.09
			sp.height = 0.12
			mi.mesh = sp
		else:
			var cap := CapsuleMesh.new()        # loaves
			cap.radius = 0.12
			cap.height = 0.5
			mi.mesh = cap
			mi.rotation.z = PI / 2
			mi.scale = Vector3(1, 1, 0.8)
		mi.material_override = mat(crust[kind], 0.75)
		mi.position = p
		add_child(mi)


# ----------------------------------------------------------- street props
func _street_props() -> void:
	tile("grass-trees", Vector3(-20, 0, -6), 0.0, Vector3(4, 4, 4))
	tile("grass-trees-tall", Vector3(28, 0, -6), 0.0, Vector3(4, 4, 4))
	tile("grass-trees", Vector3(36, 0, 6), 0.0, Vector3(4, 4, 4))
	tile("grass-trees-tall", Vector3(-44, 0, 6), 0.0, Vector3(4, 4, 4))
	# benches and bins
	for bx in [-12.0, 30.0]:
		box(Vector3(1.8, 0.08, 0.5), Vector3(bx, 0.55, 7.3), mat(Color(0.45, 0.3, 0.18)), true)
		box(Vector3(1.8, 0.5, 0.08), Vector3(bx, 0.85, 7.55), mat(Color(0.45, 0.3, 0.18)))
	box(Vector3(0.5, 0.9, 0.5), Vector3(-4.0, 0.57, 7.6), mat(Color(0.15, 0.4, 0.25)), true)
	# street name sign
	box(Vector3(0.08, 3.0, 0.08), Vector3(-2.0, 1.6, 4.4), mat(Color(0.3, 0.3, 0.32), 0.4, 0.7))
	box(Vector3(1.6, 0.35, 0.04), Vector3(-2.0, 3.0, 4.4), mat(Color(1, 1, 1)))
	label("Lindenstraße", Vector3(-2.0, 3.0, 4.37), 34, Color(0.1, 0.1, 0.12), PI, 0)
	label("Lindenstraße", Vector3(-2.0, 3.0, 4.43), 34, Color(0.1, 0.1, 0.12), 0.0, 0)


func _on_inside_entered(body: Node) -> void:
	if body is CharacterBody3D:
		inside = true
		door_bell.play()
		player_entered_bakery.emit()


func _on_inside_exited(body: Node) -> void:
	if body is CharacterBody3D:
		inside = false
		player_left_bakery.emit()
