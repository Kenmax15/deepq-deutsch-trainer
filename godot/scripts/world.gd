extends Node3D
## Builds the pilot environment in code: a realistic German street
## ("Lindenstraße") lined with Gründerzeit apartment houses, and the
## "Bäckerei Becker" on the ground floor of one of them, with a furnished shop.
##
## Everything uses physically based materials (CC0 scans from ambientCG,
## world-space triplanar mapping) under an HDRI sky (Poly Haven, CC0); props
## come from Poly Haven (CC0). Façades are generated from a few parameters
## (width, floors, colour, ground-floor use) and merged into a handful of
## meshes per house.

signal player_entered_bakery
signal player_left_bakery

const STREET_HALF := 64.0
const FACADE_Z := 8.0          # façades at z = ±8
const ROAD_Z := 5.5            # carriageway incl. parking lanes: |z| < 5.5
const LANE_Z := 1.75           # driving lanes at z = ±1.75
const PARK_Z := 4.5            # parked cars at z = ±4.5
const CURB_W := 0.15
const WALK_Y := 0.12           # top of the pavement (walkable level)
const PBR := "res://assets/pbr/"
const PROPS := "res://assets/props/"

# Bakery shop (south side, ground floor of the house spanning x 2..16)
const BK_X0 := 4.0
const BK_X1 := 13.0
const BK_Z0 := 8.0
const BK_Z1 := 15.0
const DOOR_X := 5.3
const SHOP_H := 3.6            # interior ceiling height

var sun: DirectionalLight3D
var env: Environment
var we: WorldEnvironment
var seller_spot := Vector3(9.4, WALK_Y, 13.45)
var counter_front := Vector3(9.4, WALK_Y, 11.2)
var customer_spot := Vector3(11.9, WALK_Y, 10.4)
var player_spawn := Vector3(-30.0, 0.2, 6.6)
var radio: AudioStreamPlayer3D
var coffee: AudioStreamPlayer3D
var register: AudioStreamPlayer3D
var door_bell: AudioStreamPlayer3D
var inside := false
var shop_lights: Array[Light3D] = []

var _mats := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1871
	_environment()
	_ground_and_street()
	_houses()
	_bakery_interior()
	_street_furniture()


# =============================================================== materials
## PBR material from an ambientCG set, mapped in world space.
## `tile_m` is the real-world size (metres) covered by one texture repeat.
func pbr(id: String, tile_m: float, tint := Color.WHITE, rough := 1.0, key := "") -> StandardMaterial3D:
	var k := "%s|%.2f|%s|%.2f|%s" % [id, tile_m, tint.to_html(), rough, key]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	var base := PBR + id + "/"
	m.albedo_texture = load(base + "color.jpg")
	m.albedo_color = tint
	if ResourceLoader.exists(base + "normalgl.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "normalgl.jpg")
		m.normal_scale = 1.0
	if ResourceLoader.exists(base + "roughness.jpg"):
		m.roughness_texture = load(base + "roughness.jpg")
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = rough
	if ResourceLoader.exists(base + "ambientocclusion.jpg"):
		m.ao_enabled = true
		m.ao_texture = load(base + "ambientocclusion.jpg")
		m.ao_light_affect = 0.4
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 6.0
	m.uv1_scale = Vector3.ONE / tile_m
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[k] = m
	return m


func plain(c: Color, rough := 0.6, metal := 0.0, key := "") -> StandardMaterial3D:
	var k := "plain|%s|%.2f|%.2f|%s" % [c.to_html(), rough, metal, key]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		_mats[k] = m
	return _mats[k]


func glass(variant := 0) -> StandardMaterial3D:
	## Window glass seen from outside in daylight: dark, sharp reflections.
	var k := "glass|%d" % variant
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		var tints := [Color(0.035, 0.04, 0.045), Color(0.05, 0.05, 0.048), Color(0.11, 0.105, 0.095), Color(0.03, 0.035, 0.04)]
		m.albedo_color = tints[variant % tints.size()]
		m.roughness = 0.03
		m.metallic = 0.0
		m.metallic_specular = 0.9
		m.clearcoat_enabled = false
		_mats[k] = m
	return _mats[k]


func clear_glass() -> StandardMaterial3D:
	## Shop windows and the vitrine: see-through.
	if not _mats.has("clear_glass"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.85, 0.9, 0.92, 0.08)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.02
		m.metallic_specular = 0.9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats["clear_glass"] = m
	return _mats["clear_glass"]


func prop(id: String, pos: Vector3, rot_y := 0.0, scale_k := 1.0, parent: Node = self) -> Node3D:
	var path := PROPS + id + "/" + id + "_1k.gltf"
	if not ResourceLoader.exists(path):
		for f in DirAccess.get_files_at(PROPS + id):
			if f.ends_with(".gltf"):
				path = PROPS + id + "/" + f
	var scn: PackedScene = load(path)
	if scn == null:
		return null
	var n: Node3D = scn.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * scale_k
	parent.add_child(n)
	return n


func collider(size: Vector3, pos: Vector3, rot_y := 0.0) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos
	sb.rotation.y = rot_y
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	add_child(sb)


func sign_text(text: String, xf: Transform3D, size: int, color: Color, outline := 0, font_w := 700) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = outline
	l.outline_modulate = color.darkened(0.6)
	l.shaded = true
	l.double_sided = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["DejaVu Serif", "Georgia", "Times New Roman", "serif"])
	f.font_weight = font_w
	l.font = f
	l.transform = xf
	add_child(l)
	return l


# ============================================================ environment
func _environment() -> void:
	we = WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load("res://assets/sky/kloofendal_48d_partly_cloudy_puresky_2k.hdr")
	pano.energy_multiplier = 1.0
	sky.sky_material = pano
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.sky_rotation = Vector3(0, deg_to_rad(110), 0)
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_energy = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.tonemap_white = 12.0
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.72, 0.78, 0.86)
	env.fog_depth_begin = 40.0
	env.fog_depth_end = 260.0
	env.fog_depth_curve = 1.6
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.4
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.2
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.04
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssao_power = 1.4
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.8
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.1
	env.ssr_fade_out = 2.5
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.15
	env.sdfgi_energy = 0.9
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_albedo = Color(0.85, 0.88, 0.92)
	env.volumetric_fog_length = 80.0
	env.volumetric_fog_sky_affect = 0.0
	we.environment = env
	add_child(we)

	var attrs := CameraAttributesPractical.new()
	attrs.auto_exposure_enabled = true
	attrs.auto_exposure_min_sensitivity = 50.0
	attrs.auto_exposure_max_sensitivity = 400.0
	attrs.auto_exposure_speed = 0.8
	attrs.auto_exposure_scale = 0.4
	we.camera_attributes = attrs

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -128, 0)
	sun.light_energy = 2.6
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_angular_distance = 0.6
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_split_1 = 0.06
	sun.directional_shadow_split_2 = 0.18
	sun.directional_shadow_split_3 = 0.45
	sun.directional_shadow_blend_splits = true
	add_child(sun)


func apply_quality(q: String) -> void:
	var vp := get_viewport()
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	match q:
		"low":
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_max_distance = 45.0
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			vp.scaling_3d_scale = 0.8
			env.ssao_enabled = false
			env.ssil_enabled = false
			env.ssr_enabled = false
			env.sdfgi_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = false
		"high", "ultra":
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			sun.directional_shadow_max_distance = 90.0
			vp.msaa_3d = Viewport.MSAA_4X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			vp.use_taa = false
			vp.scaling_3d_scale = 1.0
			env.ssao_enabled = forward_plus
			env.ssil_enabled = forward_plus
			env.ssr_enabled = forward_plus
			# SDFGI (real-time global illumination) is the expensive part: ultra only
			env.sdfgi_enabled = forward_plus and q == "ultra"
			env.volumetric_fog_enabled = forward_plus and q == "ultra"
			env.glow_enabled = true
		_:
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			sun.directional_shadow_max_distance = 70.0
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			vp.scaling_3d_scale = 1.0
			env.ssao_enabled = forward_plus
			env.ssil_enabled = false
			env.ssr_enabled = forward_plus
			env.sdfgi_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = true
	for l in shop_lights:
		l.shadow_enabled = q == "high" or q == "ultra"


# ========================================================= street & ground
func _ground_and_street() -> void:
	# one flat walkable level (pavement height); the road is drawn 12 cm lower
	collider(Vector3(260, 1, 260), Vector3(0, WALK_Y - 0.5, 0))
	var mb := MeshBuilder.new()
	var L := STREET_HALF * 2.0 + 40.0
	var asphalt := pbr("Asphalt031", 4.0, Color(0.78, 0.78, 0.8), 1.0)
	var cobble := pbr("PavingStones150", 1.6, Color(0.92, 0.92, 0.92))
	var curb := pbr("Concrete031", 1.5, Color(0.86, 0.86, 0.85))
	var walk := pbr("PavingStones111", 2.4, Color(0.95, 0.95, 0.93))
	var paint := plain(Color(0.86, 0.86, 0.84), 0.7)
	# driving lanes
	mb.box(Vector3(0, -0.1, 0), Vector3(L, 0.2, 7.0), asphalt)
	for s in [-1.0, 1.0]:
		# parking lane (cobbles) and gutter
		mb.box(Vector3(0, -0.1, s * 4.5), Vector3(L, 0.2, 2.0), cobble)
		# kerb stones
		mb.box(Vector3(0, WALK_Y / 2.0 + 0.005, s * (ROAD_Z + CURB_W / 2.0)), Vector3(L, WALK_Y + 0.01, CURB_W), curb)
		# pavement
		var w := FACADE_Z - ROAD_Z - CURB_W + 0.6
		mb.box(Vector3(0, WALK_Y / 2.0, s * (ROAD_Z + CURB_W + w / 2.0)), Vector3(L, WALK_Y, w), walk)
		# parking-lane edge line
		mb.box(Vector3(0, 0.002, s * 3.5), Vector3(L, 0.004, 0.12), paint)
	# centre line, dashed (3 m line, 6 m gap)
	var x := -STREET_HALF - 18.0
	while x < STREET_HALF + 18.0:
		if abs(x + 1.5) > 4.0:   # not over the zebra crossing
			mb.box(Vector3(x + 1.5, 0.002, 0), Vector3(3.0, 0.004, 0.12), paint)
		x += 9.0
	# zebra crossing at x = 0
	var zz := -3.25
	while zz < 3.4:
		mb.box(Vector3(0.0, 0.003, zz + 0.25), Vector3(4.0, 0.006, 0.5), paint)
		zz += 1.0
	# beyond the houses: a plain grey city floor so the horizon is not empty
	mb.box(Vector3(0, -0.12, 0), Vector3(400, 0.1, 400), plain(Color(0.32, 0.32, 0.31), 0.95))
	mb.commit(self)
	# manholes on the road
	for p in [Vector3(-18, 0.0, 1.2), Vector3(14, 0.0, -1.6), Vector3(38, 0.0, 1.0)]:
		prop("water_manhole_cover", p + Vector3(0, 0.03, 0), _rng.randf() * TAU)


# ================================================================== houses
const PALETTE := [
	Color(0.88, 0.82, 0.70), Color(0.86, 0.74, 0.55), Color(0.80, 0.80, 0.78),
	Color(0.84, 0.70, 0.66), Color(0.72, 0.77, 0.70), Color(0.74, 0.78, 0.82),
	Color(0.92, 0.90, 0.86), Color(0.80, 0.66, 0.52), Color(0.70, 0.66, 0.62),
]
const SHOPS := ["Apotheke", "Blumen Krüger", "Friseur Salon Elif", "Buchhandlung", "Café Linde",
	"Optik Wagner", "Feinkost", "Schuhmacherei"]


func _houses() -> void:
	# south side (z = +8): the bakery house spans x 2..16
	_row(1.0, -STREET_HALF, 2.0, 1)
	_house(1, 2.0, 16.0, {"color": Color(0.90, 0.85, 0.74), "floors": 4, "ground": "bakery", "number": 12})
	_row(1.0, 16.0, STREET_HALF, 2)
	# north side
	_row(-1.0, -STREET_HALF, STREET_HALF, 3)


func _row(side: float, x0: float, x1: float, seed_k: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 * seed_k
	var x := x0
	var n := 0
	var shop_i := seed_k * 3
	while x < x1 - 0.5:
		var w: float = min(rng.randf_range(9.5, 13.5), x1 - x)
		if x1 - (x + w) < 6.0:
			w = x1 - x
		var p := {
			"color": PALETTE[rng.randi() % PALETTE.size()],
			"floors": rng.randi_range(3, 4),
			"ground": "shop" if rng.randf() < 0.5 else "entrance",
			"brick": rng.randf() < 0.18,
			"balcony": rng.randf() < 0.35,
			"number": 2 + n * 2 + (1 if side < 0 else 0),
			"shop": SHOPS[shop_i % SHOPS.size()],
			"roof": "dark" if rng.randf() < 0.35 else "red",
			"seed": rng.randi(),
		}
		if p.ground == "shop":
			shop_i += 1
		if side > 0:
			_house(1, x, x + w, p)
		else:
			_house(-1, x, x + w, p)
		x += w
		n += 1


## One Gründerzeit apartment house. Local frame: u along the façade,
## v up, d into the building (d = 0 is the façade plane, protrusions d < 0).
func _house(side: int, x0: float, x1: float, p: Dictionary) -> void:
	var W := x1 - x0
	var rng := RandomNumberGenerator.new()
	rng.seed = p.get("seed", 5)
	var xf: Transform3D
	if side > 0:
		xf = Transform3D(Basis.IDENTITY, Vector3(x0, 0, FACADE_Z))
	else:
		xf = Transform3D(Basis(Vector3.UP, PI), Vector3(x1, 0, -FACADE_Z))
	var mb := MeshBuilder.new()
	mb.xform = xf
	var col: Color = p.get("color", PALETTE[0])
	var wall: Material
	if p.get("brick", false):
		wall = pbr("Bricks105", 1.6, Color(1, 1, 1), 1.0)
	else:
		wall = pbr("Plaster001", 2.5, col, 1.0)
	var stone := pbr("Concrete034", 2.0, Color(0.86, 0.81, 0.71), 1.0)
	var base_stone := pbr("Concrete034", 2.2, Color(0.80, 0.75, 0.66), 1.0, "base")
	var frame := plain(Color(0.92, 0.92, 0.9), 0.45)
	var dark_frame := plain(Color(0.13, 0.14, 0.15), 0.4, 0.5)
	var roof_m := pbr("RoofingTiles006" if p.get("roof", "red") == "red" else "RoofingTiles013A", 1.6,
		Color(0.9, 0.85, 0.82) if p.get("roof", "red") == "red" else Color(0.8, 0.8, 0.82))
	var metal := plain(Color(0.36, 0.37, 0.38), 0.45, 0.7)
	var floors: int = p.get("floors", 4)
	var GH := 4.2
	var FH := 3.3
	var H := GH + floors * FH
	var T := 0.45                      # wall thickness
	var DEPTH := 12.0
	var ground: String = p.get("ground", "entrance")

	# ---- building core (sides, back); the shop interior is kept free
	if ground == "bakery":
		mb.box_min(Vector3(0, GH, T), Vector3(W, H - GH, DEPTH - T), wall)
		mb.box_min(Vector3(0, 0, T), Vector3(BK_X0 - x0 - 0.2, GH, DEPTH - T), wall)
		mb.box_min(Vector3(BK_X1 - x0 + 0.2, 0, T), Vector3(x1 - BK_X1 - 0.2, GH, DEPTH - T), wall)
		mb.box_min(Vector3(0, 0, BK_Z1 - FACADE_Z + 0.2), Vector3(W, GH, DEPTH - (BK_Z1 - FACADE_Z + 0.2)), wall)
	else:
		mb.box_min(Vector3(0, 0, T), Vector3(W, H, DEPTH - T), wall)

	# ---- upper floors: tall windows with frames, sills, cornices
	var n_win := maxi(2, int(floor((W - 1.2) / 2.5)))
	var bay := W / n_win
	var ww := 1.25
	var wh := 2.05
	var glass_v := rng.randi() % 4
	for f in range(floors):
		var v0 := GH + f * FH
		var sill := 0.9
		var holes := []
		for i in range(n_win):
			var uc := bay * (i + 0.5)
			holes.append([uc - ww / 2.0, uc + ww / 2.0, v0 + sill, v0 + sill + wh])
		_wall_with_holes(mb, wall, 0.0, W, v0, v0 + FH, T, holes)
		for h in holes:
			_window(mb, h, frame, stone, glass((glass_v + int(h[0])) % 4), f == 0, rng)
		# string course under each floor
		mb.box_min(Vector3(-0.02, v0 - 0.05, -0.08), Vector3(W + 0.04, 0.22 if f == 0 else 0.12, 0.08), stone)
		# balconies on the first floor
		if p.get("balcony", false) and f < floors - 1 and n_win >= 3:
			var mid := n_win / 2
			var uc := bay * (mid + 0.5)
			_balcony(mb, uc, v0 + FH, stone, metal)

	# ---- main cornice and roof
	mb.box_min(Vector3(-0.05, H - 0.55, -0.2), Vector3(W + 0.1, 0.3, 0.2), stone)
	mb.box_min(Vector3(-0.08, H - 0.25, -0.42), Vector3(W + 0.16, 0.25, 0.42), stone)
	var rise := 4.6
	var run := DEPTH / 2.0 + 0.5
	var slope := Vector2(run, rise).length()
	var ang := atan2(rise, run)
	for s in [-1.0, 1.0]:
		var d_mid: float = DEPTH / 2.0 - s * (run / 2.0) - (0.25 if s < 0 else -0.25)
		var b := Basis(Vector3.RIGHT, s * ang)
		mb.box(Vector3(W / 2.0, H + rise / 2.0 + 0.1, d_mid), Vector3(W + 0.1, 0.22, slope), roof_m, b)
	# roof core so gables do not show through
	mb.box_min(Vector3(0.02, H, 1.5), Vector3(W - 0.04, rise * 0.62, DEPTH - 3.0), wall)
	# gutter and down-pipe
	mb.box_min(Vector3(-0.05, H - 0.02, -0.62), Vector3(W + 0.1, 0.14, 0.16), metal)
	mb.cylinder(Vector3(W - 0.18, H / 2.0, -0.12), 0.055, H, metal, 10)
	# chimneys
	for c in range(rng.randi_range(1, 2)):
		var cu := rng.randf_range(1.0, W - 1.6)
		mb.box_min(Vector3(cu, H + 1.6, 4.2 + rng.randf() * 3.0), Vector3(0.6, 3.6, 0.8), pbr("Bricks105", 1.6, Color(0.75, 0.55, 0.45)))

	match ground:
		"bakery":
			_ground_bakery(mb, x0, W, GH, T, wall, stone, base_stone, frame, p)
		"shop":
			_ground_shop(mb, xf, W, GH, T, wall, base_stone, dark_frame, p, rng)
		_:
			_ground_entrance(mb, xf, W, GH, T, wall, base_stone, frame, stone, p, rng)

	mb.commit(self)
	# collision for the house front (the bakery keeps its door open)
	if ground != "bakery":
		var c := xf * Vector3(W / 2.0, H / 2.0, DEPTH / 2.0)
		collider(Vector3(W, H, DEPTH), c)
	# house number plate (blue enamel, white digits)
	var num_u := W - 0.5
	var plate := MeshBuilder.new()
	plate.xform = xf
	plate.box(Vector3(num_u, 2.55, -0.012), Vector3(0.24, 0.18, 0.012), plain(Color(0.08, 0.2, 0.55), 0.3))
	plate.commit(self, false)
	sign_text(str(p.get("number", 1)), xf * Transform3D(Basis(Vector3.UP, PI), Vector3(num_u, 2.55, -0.02)),
		48, Color(0.97, 0.97, 0.97))


## Rusticated ground floor: horizontal joints on the solid wall only.
func _joints(mb: MeshBuilder, holes: Array, W: float, GH: float) -> void:
	var joint := plain(Color(0.42, 0.39, 0.35), 0.9)
	var jv := 0.62
	while jv < GH - 0.35:
		var u := 0.0
		var hs := holes.duplicate()
		hs.sort_custom(func(a, b): return a[0] < b[0])
		for h in hs:
			var u0: float = h[0] - 0.16
			var u1: float = h[1] + 0.16
			if jv > h[2] - 0.1 and jv < h[3] + 0.2:
				if u0 > u:
					mb.box_min(Vector3(u, jv, -0.006), Vector3(u0 - u, 0.025, 0.006), joint)
				u = max(u, u1)
		if u < W:
			mb.box_min(Vector3(u, jv, -0.006), Vector3(W - u, 0.025, 0.006), joint)
		jv += 0.48


## Solid band between v0 and v1 with rectangular openings (u0,u1,va,vb).
func _wall_with_holes(mb: MeshBuilder, m: Material, u0: float, u1: float, v0: float, v1: float, t: float, holes: Array) -> void:
	holes.sort_custom(func(a, b): return a[0] < b[0])
	var u := u0
	for h in holes:
		if h[0] > u:
			mb.box_min(Vector3(u, v0, 0), Vector3(h[0] - u, v1 - v0, t), m)
		mb.box_min(Vector3(h[0], v0, 0), Vector3(h[1] - h[0], h[2] - v0, t), m)
		mb.box_min(Vector3(h[0], h[3], 0), Vector3(h[1] - h[0], v1 - h[3], t), m)
		u = h[1]
	if u < u1:
		mb.box_min(Vector3(u, v0, 0), Vector3(u1 - u, v1 - v0, t), m)


## A double casement window with transom, stone surround, sill and head.
func _window(mb: MeshBuilder, h: Array, frame: Material, stone: Material, g: Material, piano_nobile: bool, rng: RandomNumberGenerator) -> void:
	var u0: float = h[0]
	var u1: float = h[1]
	var va: float = h[2]
	var vb: float = h[3]
	var w := u1 - u0
	var R := 0.16          # frame set back from the façade
	var fw := 0.07         # frame member width
	var fd := 0.07
	# glass
	mb.box_min(Vector3(u0, va, R + fd * 0.5), Vector3(w, vb - va, 0.02), g)
	# outer frame
	mb.box_min(Vector3(u0, va, R), Vector3(w, fw, fd), frame)
	mb.box_min(Vector3(u0, vb - fw, R), Vector3(w, fw, fd), frame)
	mb.box_min(Vector3(u0, va, R), Vector3(fw, vb - va, fd), frame)
	mb.box_min(Vector3(u1 - fw, va, R), Vector3(fw, vb - va, fd), frame)
	# transom and mullion
	var vt := vb - (vb - va) * 0.27
	mb.box_min(Vector3(u0, vt - fw / 2.0, R - 0.01), Vector3(w, fw, fd + 0.01), frame)
	mb.box_min(Vector3(u0 + w / 2.0 - fw / 2.0, va, R - 0.01), Vector3(fw, vt - va, fd + 0.01), frame)
	# casement sash bars (thin)
	for k in [0.25, 0.75]:
		mb.box_min(Vector3(u0 + w * k - 0.015, va + fw, R + 0.005), Vector3(0.03, vt - va - fw, 0.04), frame)
	# stone surround (Faschen), sill and head
	var s := 0.14
	mb.box_min(Vector3(u0 - s, va - 0.02, -0.03), Vector3(s, vb - va + 0.04, 0.03), stone)
	mb.box_min(Vector3(u1, va - 0.02, -0.03), Vector3(s, vb - va + 0.04, 0.03), stone)
	mb.box_min(Vector3(u0 - s, vb, -0.03), Vector3(w + 2 * s, s, 0.03), stone)
	mb.box_min(Vector3(u0 - 0.1, va - 0.09, -0.1), Vector3(w + 0.2, 0.08, 0.1 + R), stone)
	if piano_nobile:
		# triangular-ish pediment: two stacked cornice slabs
		mb.box_min(Vector3(u0 - s - 0.06, vb + s, -0.14), Vector3(w + 2 * s + 0.12, 0.1, 0.14), stone)
		mb.box_min(Vector3(u0 - s + 0.12, vb + s + 0.1, -0.1), Vector3(w + 2 * s - 0.24, 0.12, 0.1), stone)
	else:
		mb.box_min(Vector3(u0 - s - 0.04, vb + s, -0.1), Vector3(w + 2 * s + 0.08, 0.08, 0.1), stone)
	# some windows have a pale curtain behind the glass
	if rng.randf() < 0.35:
		var side_u := u0 + 0.08 if rng.randf() < 0.5 else u1 - 0.08 - w * 0.3
		mb.box_min(Vector3(side_u, va + 0.08, R + fd * 0.5 + 0.01), Vector3(w * 0.3, vb - va - 0.16, 0.01),
			plain(Color(0.62, 0.6, 0.55), 0.9))


func _balcony(mb: MeshBuilder, uc: float, v: float, stone: Material, metal: Material) -> void:
	var bw := 3.0
	var bd := 1.1
	mb.box_min(Vector3(uc - bw / 2.0, v - 0.18, -bd), Vector3(bw, 0.18, bd), stone)
	# consoles
	for k in [-1.0, 1.0]:
		mb.box_min(Vector3(uc + k * (bw / 2.0 - 0.3) - 0.1, v - 0.55, -bd + 0.2), Vector3(0.2, 0.37, bd - 0.2), stone)
	# railing: top rail and balusters
	mb.box_min(Vector3(uc - bw / 2.0, v + 0.95, -bd), Vector3(bw, 0.04, 0.05), metal)
	mb.box_min(Vector3(uc - bw / 2.0, v + 0.95, -bd), Vector3(0.05, 0.04, bd), metal)
	mb.box_min(Vector3(uc + bw / 2.0 - 0.05, v + 0.95, -bd), Vector3(0.05, 0.04, bd), metal)
	var u := uc - bw / 2.0 + 0.06
	while u < uc + bw / 2.0 - 0.05:
		mb.box_min(Vector3(u, v, -bd + 0.01), Vector3(0.02, 0.95, 0.02), metal)
		u += 0.12
	for k in range(1, 9):
		var d := -bd + k * bd / 9.0
		mb.box_min(Vector3(uc - bw / 2.0 + 0.01, v, d), Vector3(0.02, 0.95, 0.02), metal)
		mb.box_min(Vector3(uc + bw / 2.0 - 0.03, v, d), Vector3(0.02, 0.95, 0.02), metal)


func _ground_entrance(mb: MeshBuilder, xf: Transform3D, W: float, GH: float, T: float, wall: Material,
		base_stone: Material, frame: Material, stone: Material, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var n := maxi(2, int(floor((W - 1.2) / 2.5)))
	var bay := W / n
	var door_i := clampi(int(round(n / 2.0 - 0.5)), 0, n - 1)
	var holes := []
	for i in range(n):
		var uc := bay * (i + 0.5)
		if i == door_i:
			holes.append([uc - 0.7, uc + 0.7, 0.27, 3.2])
		else:
			holes.append([uc - 0.62, uc + 0.62, 1.25, 3.2])
	_wall_with_holes(mb, base_stone, 0.0, W, 0.0, GH, T, holes)
	_joints(mb, holes, W, GH)
	for h in holes:
		if h[2] < 0.5:
			# recessed door: wood leaf with glazed upper part, stone steps
			var d_col: Color = [Color(0.25, 0.17, 0.11), Color(0.18, 0.25, 0.2), Color(0.32, 0.12, 0.1)][rng.randi() % 3]
			var wood := pbr("PaintedWood005", 1.2, d_col.lightened(0.6))
			mb.box_min(Vector3(h[0], h[2], 0.35), Vector3(h[1] - h[0], 2.35, 0.06), wood)
			mb.box_min(Vector3(h[0] + 0.15, h[2] + 1.35, 0.33), Vector3(h[1] - h[0] - 0.3, 0.8, 0.02), glass(1))
			mb.box_min(Vector3(h[0], h[2] + 2.35, 0.35), Vector3(h[1] - h[0], h[3] - h[2] - 2.35, 0.03), glass(0))
			mb.box_min(Vector3(h[0] - 0.2, WALK_Y, -0.35), Vector3(h[1] - h[0] + 0.4, 0.15, 0.35 + 0.35), stone)
		else:
			_window(mb, h, frame, stone, glass(rng.randi() % 4), false, rng)
	mb.box_min(Vector3(-0.02, 0.0, -0.04), Vector3(W + 0.04, 0.5, 0.04), base_stone)


func _ground_shop(mb: MeshBuilder, xf: Transform3D, W: float, GH: float, T: float, wall: Material,
		base_stone: Material, frame: Material, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var holes := []
	var u := 0.8
	var door_done := false
	while u < W - 1.6:
		var w: float = min(3.2, W - 0.8 - u)
		if w < 1.2:
			break
		holes.append([u, u + w, 0.55 if door_done or u > 1.0 else 0.12, 3.15])
		door_done = true
		u += w + 0.45
	_wall_with_holes(mb, base_stone, 0.0, W, 0.0, GH, T, holes)
	_joints(mb, holes, W, 3.25)
	var shop_g := glass(2)
	for h in holes:
		var w: float = h[1] - h[0]
		mb.box_min(Vector3(h[0], h[2], 0.3), Vector3(w, h[3] - h[2], 0.02), shop_g)
		mb.box_min(Vector3(h[0], h[2], 0.26), Vector3(w, 0.06, 0.08), frame)
		mb.box_min(Vector3(h[0], h[3] - 0.06, 0.26), Vector3(w, 0.06, 0.08), frame)
		mb.box_min(Vector3(h[0], h[2], 0.26), Vector3(0.06, h[3] - h[2], 0.08), frame)
		mb.box_min(Vector3(h[1] - 0.06, h[2], 0.26), Vector3(0.06, h[3] - h[2], 0.08), frame)
		mb.box_min(Vector3(h[0], h[3] - 0.7, 0.25), Vector3(w, 0.05, 0.08), frame)
		if h[2] < 0.3:
			mb.box_min(Vector3(h[0] + 0.9, h[2], 0.25), Vector3(0.05, h[3] - h[2] - 0.7, 0.08), frame)
	# fascia with the shop name
	var name_s: String = p.get("shop", "Laden")
	mb.box_min(Vector3(0.6, 3.3, -0.06), Vector3(W - 1.2, 0.6, 0.06), plain(Color(0.14, 0.15, 0.16), 0.5))
	sign_text(name_s, xf * Transform3D(Basis(Vector3.UP, PI), Vector3(W / 2.0, 3.6, -0.07)), 72,
		Color(0.93, 0.86, 0.66), 0, 600)


func _ground_bakery(mb: MeshBuilder, x0: float, W: float, GH: float, T: float, wall: Material,
		stone: Material, base_stone: Material, frame: Material, p: Dictionary) -> void:
	var u_door0 := DOOR_X - 0.6 - x0
	var u_door1 := DOOR_X + 0.6 - x0
	var u_win0 := 6.1 - x0
	var u_win1 := 12.7 - x0
	var u_hd := 14.4 - x0          # house entrance to the flats
	var holes := [[u_door0, u_door1, 0.12, 2.75], [u_win0, u_win1, 0.62, 3.0], [u_hd - 0.65, u_hd + 0.65, 0.27, 3.0]]
	_wall_with_holes(mb, base_stone, 0.0, W, 0.0, GH, 0.25, holes)
	var jh := holes.duplicate()
	jh.append([u_door0 - 0.3, u_win1 + 0.3, 0.0, 4.0])
	_joints(mb, jh, W, GH)
	var green := plain(Color(0.09, 0.2, 0.15), 0.45)
	var brass := plain(Color(0.78, 0.62, 0.34), 0.3, 1.0)
	# shopfront frame (painted dark green wood)
	for h in holes.slice(0, 2):
		mb.box_min(Vector3(h[0] - 0.12, h[2] - 0.05, -0.05), Vector3(0.12, h[3] - h[2] + 0.17, 0.3), green)
		mb.box_min(Vector3(h[1], h[2] - 0.05, -0.05), Vector3(0.12, h[3] - h[2] + 0.17, 0.3), green)
		mb.box_min(Vector3(h[0] - 0.12, h[3], -0.05), Vector3(h[1] - h[0] + 0.24, 0.12, 0.3), green)
	# shop window glass with glazing bars
	var h1: Array = holes[1]
	mb.box_min(Vector3(h1[0], h1[2], 0.12), Vector3(h1[1] - h1[0], h1[3] - h1[2], 0.02), clear_glass())
	mb.box_min(Vector3(h1[0], h1[2] - 0.08, -0.12), Vector3(h1[1] - h1[0], 0.08, 0.37), stone)
	for k in [1.0 / 3.0, 2.0 / 3.0]:
		mb.box_min(Vector3(h1[0] + (h1[1] - h1[0]) * k - 0.04, h1[2], 0.08), Vector3(0.08, h1[3] - h1[2], 0.08), green)
	mb.box_min(Vector3(h1[0], h1[3] - 0.55, 0.08), Vector3(h1[1] - h1[0], 0.06, 0.08), green)
	# shop door: open (people walk through), only its frame and a door leaf swung inward
	var h0: Array = holes[0]
	var leaf := MeshBuilder.new()
	leaf.xform = Transform3D(Basis.IDENTITY, Vector3(x0, 0, FACADE_Z))
	leaf.box_min(Vector3(h0[0] + 0.02, 0.14, 0.3), Vector3(0.06, 2.5, 1.0), green)
	leaf.box_min(Vector3(h0[0] + 0.03, 0.5, 0.38), Vector3(0.04, 1.9, 0.84), clear_glass())
	leaf.commit(self)
	# house entrance to the flats
	var h2: Array = holes[2]
	mb.box_min(Vector3(h2[0], h2[2], 0.22), Vector3(h2[1] - h2[0], 2.3, 0.06), pbr("PaintedWood005", 1.2, Color(0.75, 0.6, 0.5)))
	mb.box_min(Vector3(h2[0], h2[2] + 2.3, 0.22), Vector3(h2[1] - h2[0], h2[3] - h2[2] - 2.3, 0.03), glass(0))
	mb.box_min(Vector3(h2[0] - 0.2, WALK_Y, -0.3), Vector3(h2[1] - h2[0] + 0.4, 0.15, 0.55), stone)
	# fascia band with gilded lettering
	mb.box_min(Vector3(u_door0 - 0.3, 3.2, -0.08), Vector3(u_win1 - u_door0 + 0.6, 0.75, 0.08), green)
	mb.box_min(Vector3(u_door0 - 0.36, 3.95, -0.14), Vector3(u_win1 - u_door0 + 0.72, 0.08, 0.14), green)
	var xf := Transform3D(Basis.IDENTITY, Vector3(x0, 0, FACADE_Z))
	sign_text("Bäckerei Becker", xf * Transform3D(Basis(Vector3.UP, PI), Vector3((u_door0 + u_win1) / 2.0, 3.58, -0.09)),
		120, Color(0.95, 0.78, 0.42), 0, 700)
	sign_text("seit 1921", xf * Transform3D(Basis(Vector3.UP, PI), Vector3(u_win1 - 0.6, 3.33, -0.09)),
		40, Color(0.95, 0.78, 0.42), 0, 400)
	sign_text("Geöffnet", xf * Transform3D(Basis(Vector3.UP, PI), Vector3(u_door0 + 0.6, 2.35, 0.11)),
		36, Color(0.95, 0.95, 0.9), 0, 600)
	# awning (Markise) over the shop window
	var canvas := pbr("Plaster003", 0.8, Color(0.55, 0.12, 0.1), 1.0)
	var aw := Basis(Vector3.RIGHT, deg_to_rad(-22))
	mb.box(Vector3((u_win0 + u_win1) / 2.0, 3.0, -0.65), Vector3(u_win1 - u_win0 + 0.2, 0.03, 1.4), canvas, aw)
	mb.box(Vector3((u_win0 + u_win1) / 2.0, 2.62, -1.3), Vector3(u_win1 - u_win0 + 0.2, 0.25, 0.02), canvas)
	# hanging pretzel sign (bakers' guild emblem) on a wrought-iron bracket
	var iron := plain(Color(0.07, 0.07, 0.07), 0.5, 0.6)
	mb.box_min(Vector3(u_door0 - 0.55, 3.0, -1.0), Vector3(0.04, 0.04, 1.0), iron)
	mb.box(Vector3(u_door0 - 0.53, 2.75, -0.55), Vector3(0.03, 0.03, 0.75), iron, Basis(Vector3.RIGHT, deg_to_rad(40)))
	var pz := MeshInstance3D.new()
	pz.mesh = pretzel_mesh()
	pz.material_override = brass
	pz.transform = xf * Transform3D(Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3.ONE * 0.32),
		Vector3(u_door0 - 0.53, 2.5, -0.8))
	add_child(pz)
	# plinth under the shop window
	mb.box_min(Vector3(-0.02, 0.0, -0.04), Vector3(W + 0.04, 0.5, 0.04), base_stone)

	# collision: façade pieces either side of the door and the window wall
	collider(Vector3(DOOR_X - 0.6 - x0, GH, 0.6), Vector3(x0 + (DOOR_X - 0.6 - x0) / 2.0, GH / 2.0, FACADE_Z + 0.3))
	collider(Vector3(x0 + W - (DOOR_X + 0.6), GH, 0.6), Vector3((DOOR_X + 0.6 + x0 + W) / 2.0, GH / 2.0, FACADE_Z + 0.3))
	collider(Vector3(W, 30, 12), Vector3(x0 + W / 2.0, GH + 15.0, FACADE_Z + 6.0))
	collider(Vector3(BK_X0 - x0, GH, 12), Vector3(x0 + (BK_X0 - x0) / 2.0, GH / 2.0, FACADE_Z + 6.0))
	collider(Vector3(x0 + W - BK_X1, GH, 12), Vector3((BK_X1 + x0 + W) / 2.0, GH / 2.0, FACADE_Z + 6.0))
	collider(Vector3(W, GH, 12 - (BK_Z1 - FACADE_Z)), Vector3(x0 + W / 2.0, GH / 2.0, (BK_Z1 + FACADE_Z + 12) / 2.0))


# ========================================================== bakery inside
func _bakery_interior() -> void:
	var mb := MeshBuilder.new()
	var cx := (BK_X0 + BK_X1) / 2.0
	var floor_m := pbr("Tiles139", 1.2, Color(0.95, 0.93, 0.9), 0.9)
	var wall_m := pbr("Plaster001", 2.0, Color(0.95, 0.92, 0.86))
	var tiles := pbr("Tiles107", 0.9, Color(0.98, 0.98, 0.97), 0.6)
	var wood := pbr("WoodFloor043", 1.6, Color(0.95, 0.85, 0.75), 0.8)
	var light_wood := pbr("WoodFloor051", 1.4, Color(1, 1, 1), 0.8)
	var top := pbr("Concrete034", 1.0, Color(0.92, 0.9, 0.86), 0.35)
	var steel := plain(Color(0.78, 0.79, 0.8), 0.25, 1.0)
	var black := plain(Color(0.05, 0.05, 0.05), 0.35, 0.2)
	var z0 := FACADE_Z + 0.25
	# floor, ceiling, walls
	mb.box_min(Vector3(BK_X0, WALK_Y - 0.02, z0), Vector3(BK_X1 - BK_X0, 0.03, BK_Z1 - z0), floor_m)
	mb.box_min(Vector3(BK_X0, SHOP_H, z0), Vector3(BK_X1 - BK_X0, 0.3, BK_Z1 - z0), wall_m)
	mb.box_min(Vector3(BK_X0 - 0.2, 0, z0), Vector3(0.2, SHOP_H, BK_Z1 - z0), wall_m)
	mb.box_min(Vector3(BK_X1, 0, z0), Vector3(0.2, SHOP_H, BK_Z1 - z0), wall_m)
	mb.box_min(Vector3(BK_X0, 0, BK_Z1), Vector3(BK_X1 - BK_X0, SHOP_H, 0.2), wall_m)
	# tiled wall behind the counter + skirting
	mb.box_min(Vector3(BK_X0 + 1.6, WALK_Y, BK_Z1 - 0.02), Vector3(BK_X1 - BK_X0 - 1.6, 2.1, 0.02), tiles)
	mb.box_min(Vector3(BK_X0, WALK_Y, z0), Vector3(0.02, 0.1, BK_Z1 - z0), wood)
	mb.box_min(Vector3(BK_X1 - 0.02, WALK_Y, z0), Vector3(0.02, 0.1, BK_Z1 - z0), wood)
	# ceiling cornice
	mb.box_min(Vector3(BK_X0, SHOP_H - 0.12, BK_Z1 - 0.1), Vector3(BK_X1 - BK_X0, 0.12, 0.1), wall_m)

	# ---- sales counter (Theke) with a glass vitrine
	var c0 := Vector3(6.5, WALK_Y, 11.9)
	var cw := 6.1
	mb.box_min(c0, Vector3(cw, 0.93, 0.8), wood)
	mb.box_min(c0 + Vector3(-0.03, 0.0, -0.03), Vector3(cw + 0.06, 0.1, 0.86), black)
	mb.box_min(c0 + Vector3(-0.04, 0.93, -0.06), Vector3(cw + 0.08, 0.04, 0.9), top)
	# vitrine (left part)
	var vit0 := c0 + Vector3(0.1, 0.97, 0.05)
	var vw := 3.8
	mb.box_min(vit0 + Vector3(0, 0.0, 0.0), Vector3(vw, 0.02, 0.62), steel)
	mb.box_min(vit0 + Vector3(0, 0.42, 0.0), Vector3(vw, 0.015, 0.62), steel)
	for k in [0.0, vw - 0.02]:
		mb.box_min(vit0 + Vector3(k, 0, 0), Vector3(0.02, 0.43, 0.62), steel)
	collider(Vector3(cw + 0.1, 1.4, 0.9), c0 + Vector3(cw / 2.0, 0.7, 0.4))
	var vg := MeshBuilder.new()
	vg.box(vit0 + Vector3(vw / 2.0, 0.21, -0.02), Vector3(vw, 0.42, 0.012), clear_glass(),
		Basis(Vector3.RIGHT, deg_to_rad(-18)))
	vg.box(vit0 + Vector3(vw / 2.0, 0.43, 0.31), Vector3(vw, 0.012, 0.62), clear_glass())
	vg.commit(self, false)
	# pastries in the vitrine (Poly Haven croissants and buns on trays)
	for i in range(6):
		var px := vit0.x + 0.35 + i * 0.6
		mb.box_min(Vector3(px - 0.25, vit0.y + 0.02, vit0.z + 0.08), Vector3(0.5, 0.012, 0.42), plain(Color(0.85, 0.85, 0.84), 0.3, 0.8))
		if i % 2 == 0:
			for j in range(3):
				prop("croissant", Vector3(px - 0.12 + (j % 2) * 0.2, vit0.y + 0.035, vit0.z + 0.18 + j * 0.11), 0.3 * j, 1.0)
		else:
			prop("hamburger_buns", Vector3(px, vit0.y + 0.035, vit0.z + 0.29), 0.0, 1.0)
	# cash register and a cutting board on the right part
	prop("CashRegister_01", c0 + Vector3(cw - 0.7, 0.97, 0.35), PI, 0.75)
	prop("wooden_cutting_board", c0 + Vector3(cw - 1.6, 0.97, 0.45), 0.2)
	prop("wicker_basket_02", c0 + Vector3(cw - 2.1, 0.97, 0.3), 0.4)
	prop("hamburger_buns", c0 + Vector3(cw - 2.08, 1.05, 0.33), 0.4, 0.8)

	# ---- back counter with coffee machine and bread shelves
	var b0 := Vector3(6.2, WALK_Y, BK_Z1 - 0.62)
	mb.box_min(b0, Vector3(6.4, 0.9, 0.6), light_wood)
	mb.box_min(b0 + Vector3(-0.02, 0.9, -0.02), Vector3(6.44, 0.04, 0.64), top)
	collider(Vector3(6.4, 1.0, 0.6), b0 + Vector3(3.2, 0.5, 0.3))
	# bread shelves above the back counter (slanted boards)
	for row in range(3):
		var y := 1.35 + row * 0.42
		mb.box(Vector3(9.4, y, BK_Z1 - 0.25), Vector3(6.0, 0.03, 0.42), light_wood, Basis(Vector3.RIGHT, deg_to_rad(12)))
		mb.box_min(Vector3(6.4, y - 0.02, BK_Z1 - 0.48), Vector3(6.0, 0.07, 0.025), light_wood)
		_bread_row(Vector3(6.75, y + 0.06, BK_Z1 - 0.27), 11, row)
	for sx in [6.38, 9.4, 12.42]:
		mb.box_min(Vector3(sx - 0.02, 1.2, BK_Z1 - 0.48), Vector3(0.04, 1.2, 0.48), light_wood)
	# coffee machine (stainless) on the back counter
	var cm := Vector3(11.7, b0.y + 0.94, BK_Z1 - 0.35)
	mb.box(cm + Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 0.48), steel)
	mb.box(cm + Vector3(0, 0.53, 0.0), Vector3(0.66, 0.06, 0.44), black)
	for k in [-0.18, 0.18]:
		mb.cylinder(cm + Vector3(k, 0.18, -0.27), 0.035, 0.08, black, 12, Basis(Vector3.RIGHT, PI / 2.0))
	mb.box(cm + Vector3(0, 0.01, -0.22), Vector3(0.6, 0.02, 0.12), black)
	# baskets with rolls
	for i in range(3):
		var bp := Vector3(7.0 + i * 0.55, b0.y + 0.94, BK_Z1 - 0.32)
		prop("wicker_basket_01", bp, 0.2 * i)
		prop("hamburger_buns", bp + Vector3(0, 0.05, 0.0), 0.3 * i, 0.75)

	# ---- price board (chalkboard) on the left wall
	var board_c := Vector3(BK_X0 + 0.03, 2.25, 13.2)
	mb.box(board_c, Vector3(0.04, 1.05, 1.5), plain(Color(0.08, 0.09, 0.085), 0.95))
	mb.box(board_c + Vector3(0.0, 0.0, 0.0), Vector3(0.03, 1.13, 1.58), wood)
	var board_xf := Transform3D(Basis(Vector3.UP, PI / 2.0), board_c + Vector3(0.04, 0.0, 0.0))
	sign_text("Roggenbrot      2,60 €\nVollkornbrot    2,90 €\nWeißbrot          2,20 €\nBrötchen          0,40 €\nBrezel              0,90 €",
		board_xf, 24, Color(0.93, 0.93, 0.9), 0, 400).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# ---- café corner by the window
	prop("round_wooden_table_01", Vector3(11.9, WALK_Y, 9.4), 0.0, 0.55)
	prop("painted_wooden_chair_01", Vector3(11.3, WALK_Y, 9.5), PI / 2.0 + 0.2, 1.0)
	prop("painted_wooden_chair_01", Vector3(12.5, WALK_Y, 9.3), -PI / 2.0 - 0.1, 1.0)
	collider(Vector3(1.6, 1.0, 1.0), Vector3(11.9, 0.5, 9.4))
	prop("potted_plant_02", Vector3(4.5, WALK_Y, 9.0), 0.4, 1.0)
	prop("wall_clock", Vector3(BK_X1 - 0.03, 2.9, 10.8), -PI / 2.0, 1.0)
	mb.commit(self)

	# ---- light: pendant lamps over the counter + soft fill
	for lx in [7.4, 9.4, 11.4]:
		prop("hanging_industrial_lamp", Vector3(lx, SHOP_H, 12.3), 0.0, 0.8)
		var l := OmniLight3D.new()
		l.position = Vector3(lx, SHOP_H - 1.25, 12.3)
		l.light_color = Color(1.0, 0.82, 0.6)
		l.light_energy = 2.2
		l.omni_range = 6.0
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		add_child(l)
		shop_lights.append(l)
	for lz in [9.6, 13.8]:
		var f := OmniLight3D.new()
		f.position = Vector3(cx, SHOP_H - 0.4, lz)
		f.light_color = Color(1.0, 0.9, 0.78)
		f.light_energy = 1.1
		f.omni_range = 7.5
		add_child(f)
	# warm light over the bread shelves
	var sl := SpotLight3D.new()
	sl.position = Vector3(9.4, SHOP_H - 0.2, BK_Z1 - 1.6)
	sl.rotation_degrees = Vector3(-60, 0, 0)
	sl.light_color = Color(1.0, 0.8, 0.55)
	sl.light_energy = 3.0
	sl.spot_range = 4.0
	sl.spot_angle = 55.0
	add_child(sl)
	shop_lights.append(sl)
	# reflection probe so the glass and steel reflect the shop, not the sky
	var rp := ReflectionProbe.new()
	rp.position = Vector3(cx, SHOP_H / 2.0, (z0 + BK_Z1) / 2.0)
	rp.size = Vector3(BK_X1 - BK_X0, SHOP_H, BK_Z1 - z0)
	rp.box_projection = true
	rp.interior = true
	rp.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	rp.ambient_color = Color(0.55, 0.46, 0.38)
	rp.ambient_color_energy = 0.6
	add_child(rp)

	# ---- sounds of the shop
	radio = _sound3d("cafe_music_loop", Vector3(BK_X1 - 0.4, 2.6, 14.6), "Music", 2.0, -8.0)
	coffee = _sound3d("coffee_machine_loop", cm, "SFX", 2.5, -14.0)
	register = _sound3d("cash_register", c0 + Vector3(cw - 0.7, 1.1, 0.35), "SFX", 3.0, -4.0, false)
	door_bell = _sound3d("door_bell", Vector3(DOOR_X, 2.5, BK_Z0 + 0.4), "SFX", 4.0, -6.0, false)

	# trigger volume for "inside the shop"
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(BK_X1 - BK_X0 - 0.4, 3.0, BK_Z1 - BK_Z0 - 1.0)
	cs.shape = sh
	area.add_child(cs)
	area.position = Vector3(cx, 1.5, (BK_Z0 + BK_Z1) / 2.0 + 0.4)
	add_child(area)
	area.body_entered.connect(_on_inside_entered)
	area.body_exited.connect(_on_inside_exited)


func _bread_mat(kind: int) -> StandardMaterial3D:
	var cols := [Color(0.34, 0.2, 0.11), Color(0.47, 0.3, 0.15), Color(0.8, 0.58, 0.3), Color(0.55, 0.3, 0.12)]
	var k := "bread|%d" % kind
	if not _mats.has(k):
		var m := pbr("Plaster003", 0.35, cols[kind], 0.8, k)
		m.albedo_texture = null
		m.albedo_color = cols[kind]
		m.roughness = 0.72 if kind != 3 else 0.35
		m.normal_scale = 1.6
		_mats[k] = m
	return _mats[k]


var _pretzel: ArrayMesh


func pretzel_mesh() -> ArrayMesh:
	## A Brezel: one dough rope (thick belly, thin arms) along a Catmull-Rom path.
	if _pretzel:
		return _pretzel
	var P := [Vector2(-0.4, -0.55), Vector2(-0.15, -0.12), Vector2(0.1, 0.25), Vector2(0.4, 0.62),
		Vector2(0.8, 0.55), Vector2(0.97, 0.1), Vector2(0.8, -0.42), Vector2(0.4, -0.76), Vector2(0.0, -0.86),
		Vector2(-0.4, -0.76), Vector2(-0.8, -0.42), Vector2(-0.97, 0.1), Vector2(-0.8, 0.55), Vector2(-0.4, 0.62),
		Vector2(-0.1, 0.25), Vector2(0.15, -0.12), Vector2(0.4, -0.55)]
	var pts: Array[Vector3] = []
	var rad: Array[float] = []
	var steps := 10
	for i in range(P.size() - 1):
		var p0: Vector2 = P[max(i - 1, 0)]
		var p1: Vector2 = P[i]
		var p2: Vector2 = P[i + 1]
		var p3: Vector2 = P[min(i + 2, P.size() - 1)]
		for k in range(steps):
			var t := float(k) / steps
			var q := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)
			var u := (i + t) / (P.size() - 1)
			# arms cross over each other in the middle
			var h := 0.06 * sin(u * TAU * 2.0)
			pts.append(Vector3(q.x, h, q.y))
			# thick belly (middle of the rope), thin ends
			rad.append(lerpf(0.09, 0.17, sin(u * PI) ** 2.5))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := 10
	var rings: Array = []
	for i in range(pts.size()):
		var tan := (pts[min(i + 1, pts.size() - 1)] - pts[max(i - 1, 0)]).normalized()
		var side := tan.cross(Vector3.UP).normalized()
		var up := side.cross(tan).normalized()
		var r: Array[Vector3] = []
		for k in range(ring):
			var a := TAU * k / ring
			r.append(pts[i] + (side * cos(a) + up * sin(a) * 0.8) * rad[i])
		rings.append(r)
	for i in range(rings.size() - 1):
		for k in range(ring):
			var a: Vector3 = rings[i][k]
			var b: Vector3 = rings[i][(k + 1) % ring]
			var c: Vector3 = rings[i + 1][(k + 1) % ring]
			var d: Vector3 = rings[i + 1][k]
			for v in [a, b, c, a, c, d]:
				st.add_vertex(v)
	st.generate_normals()
	_pretzel = st.commit()
	return _pretzel


func _bread_row(start: Vector3, n: int, row: int) -> void:
	## Loaves on the slanted shelves: rye (dark), whole-grain, white; pretzels.
	for k in range(n):
		var kind := (k + row) % 4
		var p := start + Vector3(k * 0.52, 0, 0)
		var mi := MeshInstance3D.new()
		if kind == 3:
			mi.mesh = pretzel_mesh()
			mi.rotation = Vector3(-0.55, 0, 0)
			mi.scale = Vector3.ONE * 0.13
			mi.position = p + Vector3(0, 0.05, 0)
		else:
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 1.0
			sp.radial_segments = 24
			sp.rings = 12
			mi.mesh = sp
			var lens := [0.36, 0.3, 0.42]
			mi.scale = Vector3(lens[kind], 0.15, 0.2) * _rng.randf_range(0.92, 1.06)
			mi.position = p + Vector3(0, 0.06, 0)
			mi.rotation.y = _rng.randf_range(-0.15, 0.15)
		mi.material_override = _bread_mat(kind)
		add_child(mi)


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


# ========================================================= street furniture
func _street_furniture() -> void:
	var mb := MeshBuilder.new()
	var pole := plain(Color(0.3, 0.32, 0.33), 0.5, 0.6)
	var dark := plain(Color(0.16, 0.17, 0.18), 0.45, 0.4)
	# street lights: steel poles with LED heads, staggered on both sides
	var x := -STREET_HALF + 6.0
	var i := 0
	while x < STREET_HALF:
		var s := 1.0 if i % 2 == 0 else -1.0
		var z := s * (ROAD_Z + 0.55)
		mb.cylinder(Vector3(x, 3.0 + WALK_Y, z), 0.075, 6.0, pole, 14)
		mb.cylinder(Vector3(x, 0.45 + WALK_Y, z), 0.11, 0.9, pole, 14)
		mb.box(Vector3(x, 6.05, z - s * 0.6), Vector3(0.08, 0.08, 1.3), pole)
		mb.box(Vector3(x, 6.0, z - s * 1.25), Vector3(0.28, 0.1, 0.62), dark)
		mb.box(Vector3(x, 5.94, z - s * 1.25), Vector3(0.22, 0.02, 0.5), plain(Color(0.9, 0.9, 0.85), 0.2))
		collider(Vector3(0.25, 3, 0.25), Vector3(x, 1.5, z))
		x += 22.0
		i += 1
	# traffic sign for the zebra crossing (Zeichen 350): blue square, white triangle
	for s in [-1.0, 1.0]:
		var sz: float = s * (ROAD_Z + 0.45)
		mb.cylinder(Vector3(-2.4, 1.4, sz), 0.03, 2.8, pole, 10)
		mb.box(Vector3(-2.4, 2.55, sz), Vector3(0.02, 0.6, 0.6), plain(Color(0.05, 0.25, 0.65), 0.35))
		mb.box(Vector3(-2.39 - 0.01, 2.53, sz), Vector3(0.005, 0.4, 0.42), plain(Color(0.95, 0.95, 0.95), 0.4),
			Basis(Vector3.RIGHT, PI / 4.0))
	# bollards along the kerb near the crossing
	for bx in [-3.3, 3.3]:
		for s in [-1.0, 1.0]:
			mb.cylinder(Vector3(bx, WALK_Y + 0.45, s * (ROAD_Z + 0.35)), 0.06, 0.9, dark, 12)
	mb.commit(self)

	# benches, planters, utility box, the bakery's A-board
	prop("painted_wooden_bench", Vector3(-12, WALK_Y, 7.4), PI, 1.15)
	collider(Vector3(1.4, 0.9, 0.6), Vector3(-12, 0.45, 7.4))
	prop("painted_wooden_bench", Vector3(30, WALK_Y, -7.4), 0.0, 1.15)
	collider(Vector3(1.4, 0.9, 0.6), Vector3(30, 0.45, -7.4))
	prop("standing_chalkboard_01", Vector3(7.4, WALK_Y, 6.9), PI + 0.35, 0.9)
	collider(Vector3(0.8, 1.3, 0.6), Vector3(7.4, 0.65, 6.9))
	for pp in [Vector3(-5.5, WALK_Y, 7.55), Vector3(17.5, WALK_Y, 7.55), Vector3(-26, WALK_Y, -7.55), Vector3(21, WALK_Y, -7.55)]:
		prop("planter_box_01", pp, 0.0, 1.3)
	prop("utility_box_01", Vector3(-8.0, WALK_Y, -6.0), PI / 2.0, 1.2)
	collider(Vector3(0.7, 1.3, 0.6), Vector3(-8.0, 0.65, -6.0))
	prop("potted_plant_01", Vector3(3.3, WALK_Y, 7.55), 0.0, 0.9)
	# wall lanterns on a few houses
	for wl in [Vector3(-20.0, 3.4, 7.75), Vector3(24.0, 3.4, 7.75)]:
		prop("street_lamp_02", wl, PI, 0.55)
	# street name signs at the crossing
	var sign_c := Vector3(-2.4, 3.05, ROAD_Z + 0.45)
	var smb := MeshBuilder.new()
	smb.box(sign_c, Vector3(1.2, 0.26, 0.02), plain(Color(0.96, 0.96, 0.95), 0.4))
	smb.box(sign_c, Vector3(1.24, 0.3, 0.015), plain(Color(0.05, 0.05, 0.05), 0.4))
	smb.commit(self)
	for r in [0.0, PI]:
		var off := Vector3(0, 0, -0.012 if r == PI else 0.012)
		sign_text("Lindenstraße", Transform3D(Basis(Vector3.UP, r), sign_c + off), 46, Color(0.05, 0.05, 0.05), 0, 600)


func _on_inside_entered(body: Node) -> void:
	if body is CharacterBody3D:
		inside = true
		door_bell.play()
		player_entered_bakery.emit()


func _on_inside_exited(body: Node) -> void:
	if body is CharacterBody3D:
		inside = false
		player_left_bakery.emit()
