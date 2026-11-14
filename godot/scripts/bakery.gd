class_name Bakery
extends RefCounted
## "Bäckerei · Konditorei Becker": a modern German bakery (anthracite, light
## wood, warm light, lots of glass) on the ground floor of house no. 12.
## Façade and interior are built from code; breads come from BakeryGoods.
##
## World layout (south side of the street, façade plane z = 8):
##   shop interior x 4..13, z 8.25..15, ceiling 3.6 m
##   door x 4.5..6.1 (open double door), shop window x 6.35..12.7
##   counter with vitrine x 6.5..12.6 at z 11.9..12.7, seller behind it at z 13.45

const DOOR0 := 4.5
const DOOR1 := 6.1
const WIN0 := 6.35
const WIN1 := 12.7

static var w     # the World node (helpers: pbr, plain, glass, prop, collider, sign_text)
static var rng := RandomNumberGenerator.new()


static func _anthracite() -> StandardMaterial3D:
	return w.plain(Color(0.085, 0.09, 0.095), 0.55, 0.15, "anthr")


static func _gold() -> StandardMaterial3D:
	return w.plain(Color(0.86, 0.66, 0.3), 0.3, 1.0, "gold")


static func _emissive(c: Color, e: float) -> StandardMaterial3D:
	var k := "emi|%s|%.1f" % [c.to_html(), e]
	if not w._mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
		w._mats[k] = m
	return w._mats[k]


static func _label(text: String, xf: Transform3D, size: int, color: Color, font_w := 700, glow := false, serif := true) -> Label3D:
	var l: Label3D = w.sign_text(text, xf, size, color, 0, font_w)
	if glow:
		l.shaded = false
		l.modulate = color * 1.25
	if not serif:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["DejaVu Sans", "Segoe UI", "Arial", "sans-serif"])
		f.font_weight = font_w
		l.font = f
	return l


## Raised 3D letters (TextMesh) with a lit, slightly glowing face.
static func letters(text: String, xf: Transform3D, size: int, color: Color, depth: float, glow := 1.4, weight := 700) -> MeshInstance3D:
	var tm := TextMesh.new()
	tm.text = text
	tm.font_size = size
	tm.pixel_size = 0.004
	tm.depth = depth
	tm.curve_step = 1.0
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["DejaVu Serif", "Georgia", "Times New Roman", "serif"])
	f.font_weight = weight
	tm.font = f
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.35
	m.metallic = 0.3
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	mi.material_override = m
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(mi)
	return mi


## Wheat-ear emblem (stalk + two rows of grains), in the XY plane of `xf`.
static func wheat(mb: MeshBuilder, base: Vector3, height: float, m: Material, lean := 0.35) -> void:
	var dir := Vector3(sin(lean), cos(lean), 0).normalized()
	var side := Vector3(dir.y, -dir.x, 0)
	mb.box(base + dir * height * 0.3, Vector3(height * 0.035, height * 0.62, 0.012), m, Basis(Vector3.BACK, -lean))
	for i in range(6):
		var t := 0.45 + i * 0.1
		for s: float in [-1.0, 1.0]:
			var c := base + dir * height * t + side * s * height * 0.06
			var b := Basis(Vector3.BACK, -lean - s * 0.5) * Basis.from_scale(Vector3(height * 0.05, height * 0.11, 0.02))
			mb.box(c, Vector3.ONE, m, b)
	mb.box(base + dir * height * 1.06, Vector3(height * 0.05, height * 0.12, 0.02), m, Basis(Vector3.BACK, -lean))


# ================================================================ façade
## Ground floor of the bakery house. `mb` is in the house frame (u along the
## façade from x0, v up, d into the building), `x0` the house's left edge.
static func facade(world, mb: MeshBuilder, x0: float, W: float, GH: float, stone: Material, base_stone: Material) -> void:
	w = world
	rng.seed = 12
	var ud0 := DOOR0 - x0
	var ud1 := DOOR1 - x0
	var uw0 := WIN0 - x0
	var uw1 := WIN1 - x0
	var u_hd := 14.4 - x0          # entrance to the flats upstairs
	var holes := [[ud0, ud1, 0.12, 3.0], [uw0, uw1, 0.12, 3.0], [u_hd - 0.65, u_hd + 0.65, 0.27, 3.0]]
	w._wall_with_holes(mb, base_stone, 0.0, W, 0.0, GH, 0.25, holes)
	var jh := holes.duplicate()
	jh.append([ud0 - 0.6, uw1 + 0.6, 0.0, 4.2])
	w._joints(mb, jh, W, GH)
	var anth: StandardMaterial3D = _anthracite()
	var frame: StandardMaterial3D = w.plain(Color(0.06, 0.06, 0.065), 0.35, 0.6, "blackframe")
	var wood: StandardMaterial3D = w.pbr("WoodFloor051", 1.2, Color(0.95, 0.85, 0.72), 0.7, "clad")
	# anthracite shopfront cladding around the openings, wood strips at the ends
	for base_u in [ud0 - 0.45, uw1]:
		mb.box_min(Vector3(base_u, 0.0, -0.03), Vector3(0.45, 3.05, 0.03), anth)
		for k in range(5):
			mb.box_min(Vector3(base_u + 0.02 + k * 0.088, 0.0, -0.075), Vector3(0.065, 3.05, 0.05), wood)
	mb.box_min(Vector3(ud1, 0.0, -0.05), Vector3(uw0 - ud1, 3.05, 0.05), anth)
	mb.box_min(Vector3(ud0 - 0.45, 0.0, -0.07), Vector3(uw1 - ud0 + 0.9, 0.12, 0.07), anth)
	# fascia (Blende) with illuminated lettering
	mb.box_min(Vector3(ud0 - 0.5, 3.0, -0.16), Vector3(uw1 - ud0 + 1.0, 0.95, 0.16), anth)
	var xf := Transform3D(Basis.IDENTITY, Vector3(x0, 0, 8.0))
	var mid := (ud0 + uw1) / 2.0 + 0.45
	letters("Bäckerei · Konditorei", xf * Transform3D(Basis(Vector3.UP, PI), Vector3(mid, 3.47, -0.19)),
		150, Color(0.98, 0.88, 0.64), 0.04, 1.8)
	var gm := MeshBuilder.new()
	gm.xform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	wheat(gm, Vector3(-(ud0 + 0.35), 3.12, 0.175), 0.72, _emissive(Color(0.95, 0.72, 0.32), 1.6), 0.45)
	gm.commit(w, false)
	# spots under the fascia
	for k in range(6):
		var u := ud0 + 0.2 + k * (uw1 - ud0 - 0.4) / 5.0
		mb.cylinder(Vector3(u, 2.995, -0.1), 0.035, 0.012, _emissive(Color(1.0, 0.86, 0.62), 4.0), 12)
	for k in range(3):
		var sl := SpotLight3D.new()
		sl.position = Vector3(x0 + ud0 + 0.6 + k * (uw1 - ud0 - 1.2) / 2.0, 2.4, 8.0 - 1.5)
		sl.rotation_degrees = Vector3(-90, 0, 0)
		sl.light_color = Color(1.0, 0.85, 0.62)
		sl.light_energy = 1.2
		sl.spot_range = 3.2
		sl.spot_angle = 38.0
		w.add_child(sl)
	# glazing: full-height glass with slim black frames
	for h in holes.slice(0, 2):
		var u0: float = h[0]
		var u1: float = h[1]
		mb.box_min(Vector3(u0, 0.12, 0.0), Vector3(0.06, 2.88, 0.12), frame)
		mb.box_min(Vector3(u1 - 0.06, 0.12, 0.0), Vector3(0.06, 2.88, 0.12), frame)
		mb.box_min(Vector3(u0, 2.94, 0.0), Vector3(u1 - u0, 0.06, 0.12), frame)
	mb.box_min(Vector3(uw0, 0.12, 0.0), Vector3(uw1 - uw0, 0.08, 0.12), frame)
	mb.box_min(Vector3(uw0, 2.55, 0.0), Vector3(uw1 - uw0, 0.05, 0.12), frame)
	for k: float in [1.0 / 3.0, 2.0 / 3.0]:
		mb.box_min(Vector3(uw0 + (uw1 - uw0) * k - 0.03, 0.12, 0.0), Vector3(0.06, 2.88, 0.12), frame)
	var g: StandardMaterial3D = w.clear_glass()
	var glz := MeshBuilder.new()
	glz.xform = mb.xform
	glz.box_min(Vector3(uw0, 0.2, 0.05), Vector3(uw1 - uw0, 2.75, 0.015), g)
	glz.box_min(Vector3(ud0 + 0.06, 2.6, 0.05), Vector3(ud1 - ud0 - 0.12, 0.34, 0.015), g)
	# open double door: two glass leaves swung outwards onto the pavement
	for s: int in [0, 1]:
		var hinge := Vector3(ud0 + 0.06 if s == 0 else ud1 - 0.06, 0.13, -0.02)
		var ang := deg_to_rad(-75.0 if s == 0 else 75.0)
		var leaf_w := (ud1 - ud0 - 0.12) / 2.0
		var dirv := Vector3(cos(ang), 0, sin(ang)) * (1.0 if s == 0 else -1.0)
		var centre := hinge + dirv * leaf_w / 2.0
		var b := Basis(Vector3.UP, -ang)
		mb.box(centre + Vector3(0, 1.22, 0), Vector3(leaf_w, 2.45, 0.05), frame, b)
		glz.box(centre + Vector3(0, 1.22, 0), Vector3(leaf_w - 0.1, 2.3, 0.055), g, b)
	glz.commit(w, false)
	# window lettering (white on the glass) and an "open" sign on the door
	var lx := xf * Transform3D(Basis(Vector3.UP, PI), Vector3(uw0 + (uw1 - uw0) / 6.0, 0, 0.035))
	var lines := ["Frische Brötchen", "Kaffee", "Kuchen", "Snacks"]
	for i in lines.size():
		_label(lines[i], lx * Transform3D(Basis.IDENTITY, Vector3(0, 2.25 - i * 0.36, 0)), 50 if i == 0 else 56,
			Color(0.97, 0.97, 0.95), 600, false, false)
		var ul := MeshBuilder.new()
		ul.xform = mb.xform
		ul.box(Vector3(uw0 + (uw1 - uw0) / 6.0, 2.25 - i * 0.36 - 0.13, 0.04), Vector3(0.9, 0.012, 0.004), _gold())
		ul.commit(w, false)
	var cupm := MeshBuilder.new()
	cupm.xform = mb.xform
	wheat(cupm, Vector3(uw0 + (uw1 - uw0) * 0.5, 1.55, 0.04), 0.55, _gold(), -0.2)
	cupm.commit(w, false)
	_label("Geöffnet", xf * Transform3D(Basis(Vector3.UP, PI), Vector3(uw1 - 0.5, 1.55, 0.04)), 34,
		Color(0.97, 0.97, 0.95), 600, false, false)
	mb.box(Vector3(ud0 - 0.6, 1.5, -0.085), Vector3(0.82, 0.48, 0.01), anth)
	_label("Öffnungszeiten\nMo–Fr   6:00 – 18:30\nSa        6:30 – 13:00\nSo        7:30 – 11:00",
		xf * Transform3D(Basis(Vector3.UP, PI), Vector3(ud0 - 0.6, 1.5, -0.096)), 22, Color(0.95, 0.95, 0.92), 500, false, false)
	mb.box_min(Vector3(ud0 + 0.05, 0.121, -0.9), Vector3(ud1 - ud0 - 0.1, 0.012, 0.85), w.pbr("Plaster003", 0.3, Color(0.12, 0.12, 0.13), 1.0, "mat"))
	# awning (dark grey canvas) over window and door
	var canvas: StandardMaterial3D = w.pbr("Plaster003", 0.8, Color(0.2, 0.2, 0.21), 1.0, "awning")
	var aw := Basis(Vector3.RIGHT, deg_to_rad(-16))
	var aw_w := uw1 - ud0 + 0.3
	var amid := (ud0 + uw1) / 2.0
	mb.box(Vector3(amid, 2.98, -0.06), Vector3(aw_w + 0.1, 0.14, 0.14), anth)                 # cassette
	mb.box(Vector3(amid, 2.86, -0.75), Vector3(aw_w, 0.02, 1.45), canvas, aw)                  # canvas
	mb.box(Vector3(amid, 2.64, -1.45), Vector3(aw_w + 0.04, 0.05, 0.06), anth)                 # front bar
	mb.box(Vector3(amid, 2.52, -1.47), Vector3(aw_w, 0.2, 0.012), canvas)                      # valance
	for au in [ud0 + 0.2, amid, uw1 - 0.2]:                                                     # folding arms
		mb.box(Vector3(au, 2.8, -0.7), Vector3(0.035, 0.035, 1.42), anth, Basis(Vector3.RIGHT, deg_to_rad(-12)))
	var vx := xf * Transform3D(Basis(Vector3.UP, PI), Vector3(amid, 2.52, -1.48))
	_label("Bäckerei · Café · Frühstück", vx, 38, Color(0.95, 0.9, 0.8), 600, false, false)
	# projecting sign "Bäckerei" (lit box on a bracket)
	var sc := Vector3(ud0 - 1.0, 3.45, -0.55)
	mb.box(sc, Vector3(0.12, 0.78, 0.78), anth)
	mb.box(Vector3(ud0 - 1.0, 3.88, -0.3), Vector3(0.04, 0.04, 0.6), frame)
	for s: float in [-1.0, 1.0]:
		var face := xf * Transform3D(Basis(Vector3.UP, s * PI / 2.0), sc + Vector3(s * 0.065, -0.17, 0))
		letters("Bäckerei", face * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.006)), 46, Color(0.98, 0.88, 0.64), 0.01, 1.6)
		var wm := MeshBuilder.new()
		wm.xform = xf * Transform3D(Basis(Vector3.UP, s * PI / 2.0), sc + Vector3(s * 0.066, 0, 0))
		wheat(wm, Vector3(0, -0.02, 0), 0.3, _emissive(Color(0.95, 0.72, 0.32), 1.6), 0.3)
		wm.commit(w, false)
	# house entrance to the flats (wooden door, transom, step)
	var h2: Array = holes[2]
	mb.box_min(Vector3(h2[0], h2[2], 0.22), Vector3(h2[1] - h2[0], 2.3, 0.06), w.pbr("PaintedWood005", 1.2, Color(0.75, 0.6, 0.5)))
	mb.box_min(Vector3(h2[0], h2[2] + 2.3, 0.22), Vector3(h2[1] - h2[0], h2[3] - h2[2] - 2.3, 0.03), w.glass(0))
	mb.box_min(Vector3(h2[0] - 0.2, 0.12, -0.3), Vector3(h2[1] - h2[0] + 0.4, 0.15, 0.55), stone)

	# collision: façade either side of the door; the shop's walls
	w.collider(Vector3(DOOR0 - x0, GH, 0.6), Vector3(x0 + (DOOR0 - x0) / 2.0, GH / 2.0, 8.3))
	w.collider(Vector3(x0 + W - DOOR1, GH, 0.6), Vector3((DOOR1 + x0 + W) / 2.0, GH / 2.0, 8.3))
	w.collider(Vector3(W, 30, 12), Vector3(x0 + W / 2.0, GH + 15.0, 14.0))
	w.collider(Vector3(4.0 - x0, GH, 12), Vector3(x0 + (4.0 - x0) / 2.0, GH / 2.0, 14.0))
	w.collider(Vector3(x0 + W - 13.0, GH, 12), Vector3((13.0 + x0 + W) / 2.0, GH / 2.0, 14.0))
	w.collider(Vector3(W, GH, 5), Vector3(x0 + W / 2.0, GH / 2.0, 17.5))


## Things on the pavement in front of the shop (world coordinates).
static func pavement(world) -> void:
	w = world
	var mb := MeshBuilder.new()
	var anth: StandardMaterial3D = _anthracite()
	var wood: StandardMaterial3D = w.pbr("WoodFloor043", 1.0, Color(1.0, 0.82, 0.62), 0.7, "aboard")
	var slate: StandardMaterial3D = w.plain(Color(0.07, 0.075, 0.07), 0.9, 0.0, "slate")
	# A-board "Unser Angebot"
	var ab := Vector3(3.55, 0.12, 7.05)
	for s: float in [-1.0, 1.0]:
		var b := Basis(Vector3.RIGHT, s * 0.16)
		mb.box(ab + Vector3(0, 0.56, s * 0.1), Vector3(0.66, 1.08, 0.03), wood, b)
		mb.box(ab + Vector3(0, 0.6, s * 0.1 - s * 0.005), Vector3(0.56, 0.88, 0.032), slate, b)
	var board := Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, 0.16), ab + Vector3(0, 0.62, -0.122))
	_label("Unser Angebot", board * Transform3D(Basis.IDENTITY, Vector3(0, 0.32, 0)), 30, Color(0.96, 0.95, 0.9), 600)
	_label("Brötchen     0,40 €\nBrezel         0,90 €\nRoggenbrot  2,60 €\nVollkornbrot 2,90 €\nWeißbrot     2,20 €",
		board * Transform3D(Basis.IDENTITY, Vector3(0, -0.05, 0)), 19, Color(0.96, 0.95, 0.9), 400, false, false)
	w.collider(Vector3(0.7, 1.2, 0.5), ab + Vector3(0, 0.6, 0))
	# planters with hydrangeas and a box ball
	for pc: Vector3 in [Vector3(4.15, 0.12, 7.35), Vector3(13.3, 0.12, 7.35)]:
		mb.box(pc + Vector3(0, 0.3, 0), Vector3(0.55, 0.6, 0.55), anth)
		w.collider(Vector3(0.55, 0.6, 0.55), pc + Vector3(0, 0.3, 0))
	_hydrangea(Vector3(4.15, 0.72, 7.35))
	_boxball(Vector3(13.3, 0.95, 7.35))
	# small terrace: table and two chairs by the window
	for tc: Vector3 in [Vector3(10.6, 0.12, 7.3), Vector3(8.4, 0.12, 7.3)]:
		mb.box(tc + Vector3(0, 0.74, 0), Vector3(0.7, 0.035, 0.7), w.pbr("WoodFloor051", 1.0, Color(1, 0.92, 0.8), 0.6, "tabletop"))
		mb.cylinder(tc + Vector3(0, 0.37, 0), 0.03, 0.72, anth, 10)
		mb.box(tc + Vector3(0, 0.01, 0), Vector3(0.45, 0.02, 0.45), anth)
		w.collider(Vector3(0.75, 0.8, 0.75), tc + Vector3(0, 0.4, 0))
		for s: float in [-1.0, 1.0]:
			_chair(mb, tc + Vector3(s * 0.72, 0, 0), s * PI / 2.0 + PI)
		mb.cylinder(tc + Vector3(0.12, 0.83, 0.1), 0.05, 0.12, w.plain(Color(0.75, 0.76, 0.77), 0.3, 0.8, "zinc"), 12)
		_hydrangea_small(tc + Vector3(0.12, 0.92, 0.1))
	mb.commit(w)


static func _chair(mb: MeshBuilder, p: Vector3, rot: float) -> void:
	## black metal bistro chair with a grey cushion; faces +Z before rotation
	var m: StandardMaterial3D = w.plain(Color(0.05, 0.05, 0.055), 0.4, 0.7, "chairmetal")
	var cushion: StandardMaterial3D = w.plain(Color(0.42, 0.42, 0.42), 0.95, 0.0, "cushion")
	var b := Basis(Vector3.UP, rot)
	var f := func(v: Vector3) -> Vector3: return p + b * v
	for lx: float in [-0.2, 0.2]:
		for lz: float in [-0.2, 0.2]:
			mb.cylinder(f.call(Vector3(lx, 0.23, lz)), 0.012, 0.46, m, 6)
	mb.box(f.call(Vector3(0, 0.47, 0)), Vector3(0.44, 0.03, 0.44), m, b)
	mb.box(f.call(Vector3(0, 0.505, 0.0)), Vector3(0.4, 0.04, 0.4), cushion, b)
	for lx: float in [-0.2, 0.2]:
		mb.cylinder(f.call(Vector3(lx, 0.72, -0.2)), 0.012, 0.5, m, 6)
	mb.box(f.call(Vector3(0, 0.86, -0.21)), Vector3(0.42, 0.16, 0.02), m, b)
	mb.box(f.call(Vector3(0, 0.68, -0.21)), Vector3(0.42, 0.02, 0.015), m, b)


static func _hydrangea(c: Vector3) -> void:
	var leaf: StandardMaterial3D = w.plain(Color(0.12, 0.26, 0.1), 0.7, 0.0, "leaf")
	var cols := [Color(0.86, 0.45, 0.66), Color(0.78, 0.5, 0.82), Color(0.62, 0.8, 0.45), Color(0.9, 0.6, 0.75)]
	for i in range(14):
		var mi := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.11
		sp.height = 0.2
		sp.radial_segments = 10
		sp.rings = 6
		mi.mesh = sp
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, 0.2)
		mi.position = c + Vector3(cos(a) * r, rng.randf_range(0.0, 0.18), sin(a) * r)
		if i < 8:
			mi.material_override = w.pbr("Plaster003", 0.12, cols[i % 4], 0.9, "flower%d" % (i % 4))
			mi.scale = Vector3.ONE * rng.randf_range(0.8, 1.05)
			mi.position.y += 0.12
		else:
			mi.material_override = leaf
			mi.scale = Vector3(1.3, 0.5, 1.0)
		w.add_child(mi)


static func _hydrangea_small(c: Vector3) -> void:
	for i in range(5):
		var mi := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.04
		sp.height = 0.07
		sp.radial_segments = 8
		sp.rings = 4
		mi.mesh = sp
		mi.position = c + Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(0.0, 0.04), rng.randf_range(-0.04, 0.04))
		mi.material_override = w.pbr("Plaster003", 0.12, [Color(0.86, 0.45, 0.66), Color(0.78, 0.5, 0.82)][i % 2], 0.9, "flower%d" % (i % 2))
		w.add_child(mi)


static func _boxball(c: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.36
	sp.height = 0.7
	mi.mesh = sp
	mi.position = c
	mi.material_override = w.pbr("Plaster003", 0.09, Color(0.16, 0.3, 0.12), 1.0, "boxwood")
	w.add_child(mi)


# ============================================================== interior
static func interior(world) -> void:
	w = world
	rng.seed = 2026
	var mb := MeshBuilder.new()
	var X0 := 4.0
	var X1 := 13.0
	var Z0 := 8.25
	var Z1 := 15.0
	var H := 3.6
	var floor_m: StandardMaterial3D = w.pbr("WoodFloor051", 1.6, Color(1.0, 0.93, 0.84), 0.7, "shopfloor")
	var wall_m: StandardMaterial3D = w.pbr("Plaster001", 2.0, Color(0.96, 0.93, 0.88), 1.0, "shopwall")
	var dark_wall: StandardMaterial3D = w.pbr("Plaster001", 2.0, Color(0.13, 0.13, 0.14), 1.0, "darkwall")
	var light_wood: StandardMaterial3D = w.pbr("WoodFloor051", 1.2, Color(1.0, 0.9, 0.76), 0.65, "lightwood")
	var anth: StandardMaterial3D = _anthracite()
	var steel: StandardMaterial3D = w.plain(Color(0.8, 0.81, 0.82), 0.22, 1.0, "steel")
	var black: StandardMaterial3D = w.plain(Color(0.03, 0.03, 0.03), 0.4, 0.2, "black")
	var led := _emissive(Color(1.0, 0.82, 0.55), 3.0)

	# shell
	mb.box_min(Vector3(X0, 0.1, Z0), Vector3(X1 - X0, 0.03, Z1 - Z0), floor_m)
	mb.box_min(Vector3(X0, H, Z0), Vector3(X1 - X0, 0.3, Z1 - Z0), wall_m)
	mb.box_min(Vector3(X0 - 0.2, 0, Z0), Vector3(0.2, H, Z1 - Z0), wall_m)
	mb.box_min(Vector3(X1, 0, Z0), Vector3(0.2, H, Z1 - Z0), wall_m)
	mb.box_min(Vector3(X0, 0, Z1), Vector3(X1 - X0, H, 0.2), dark_wall)
	# recessed ceiling spots
	for sx: float in [5.0, 7.2, 9.4, 11.6]:
		for sz: float in [9.3, 11.0, 14.0]:
			mb.cylinder(Vector3(sx, H - 0.004, sz), 0.05, 0.01, _emissive(Color(1, 0.9, 0.75), 5.0), 12)

	# ---- back wall: black steel shelving with light-wood shelves, LED, breads
	var s0 := 5.0
	var s1 := 11.2
	for px: float in [s0, (s0 + s1) / 2.0, s1]:
		mb.box_min(Vector3(px - 0.025, 0.12, Z1 - 0.5), Vector3(0.05, 2.55, 0.05), anth)
		mb.box_min(Vector3(px - 0.025, 0.12, Z1 - 0.05), Vector3(0.05, 2.55, 0.05), anth)
	var kinds := [["landbrot", "bauernbrot", "landbrot", "kasten"], ["bauernbrot", "kasten", "landbrot", "weiss"],
		["weiss", "landbrot", "kasten", "bauernbrot"], ["broetchen", "koerner", "broetchen", "koerner"]]
	for row in range(4):
		var y := 1.12 + row * 0.38
		mb.box_min(Vector3(s0, y, Z1 - 0.5), Vector3(s1 - s0, 0.035, 0.48), light_wood)
		mb.box_min(Vector3(s0, y - 0.012, Z1 - 0.48), Vector3(s1 - s0, 0.012, 0.025), led)
		_fill_shelf(Vector3(s0 + 0.05, y + 0.035, Z1 - 0.27), s1 - s0 - 0.1, kinds[3 - row])
		# white price tags on the shelf edge
		var tx := s0 + 0.3
		while tx < s1 - 0.2:
			mb.box(Vector3(tx, y + 0.012, Z1 - 0.505), Vector3(0.09, 0.05, 0.004), w.plain(Color(0.95, 0.95, 0.93), 0.6, 0.0, "tag"))
			tx += 0.75
	# baskets of rolls on the lowest shelf level
	mb.box_min(Vector3(s0, 0.78, Z1 - 0.5), Vector3(s1 - s0, 0.035, 0.48), light_wood)
	for i in range(4):
		var bp := Vector3(s0 + 0.5 + i * 1.5, 0.82, Z1 - 0.28)
		w.prop("wicker_basket_01", bp, rng.randf() * 0.4)
		for j in range(5):
			var r := BakeryGoods.make("broetchen" if i % 2 == 0 else "koerner", rng)
			r.position = bp + Vector3(rng.randf_range(-0.12, 0.12), 0.08 + j * 0.012, rng.randf_range(-0.08, 0.08))
			w.add_child(r)
	# big chalkboard sign "Bäckerei Konditorei" above the shelves
	var sign_c := Vector3(8.1, 3.0, Z1 - 0.03)
	mb.box(sign_c, Vector3(2.9, 0.95, 0.04), w.plain(Color(0.09, 0.095, 0.09), 0.92, 0.0, "slate"))
	var sx := Transform3D(Basis(Vector3.UP, PI), sign_c + Vector3(0, 0, -0.025))
	_label("Bäckerei", sx * Transform3D(Basis.IDENTITY, Vector3(0.25, 0.14, 0)), 110, Color(0.92, 0.74, 0.42), 600)
	_label("Konditorei", sx * Transform3D(Basis.IDENTITY, Vector3(0.35, -0.2, 0)), 80, Color(0.96, 0.95, 0.9), 400)
	var wm := MeshBuilder.new()
	wm.xform = sx
	wheat(wm, Vector3(-1.05, -0.32, 0.0), 0.62, _gold(), 0.4)
	wm.commit(w, false)
	# price board "Unser Angebot" (wood frame), mission prices
	var pb := Vector3(11.95, 2.55, Z1 - 0.04)
	mb.box(pb, Vector3(1.55, 1.35, 0.03), w.plain(Color(0.08, 0.085, 0.08), 0.92, 0.0, "slate"))
	mb.box(pb + Vector3(0, 0, 0.012), Vector3(1.65, 1.45, 0.03), w.pbr("WoodFloor043", 1.0, Color(1.0, 0.8, 0.6), 0.7, "frame"))
	var px := Transform3D(Basis(Vector3.UP, PI), pb + Vector3(0, 0, -0.02))
	_label("Unser Angebot", px * Transform3D(Basis.IDENTITY, Vector3(0, 0.48, 0)), 44, Color(0.97, 0.96, 0.92), 600)
	_label("Brötchen\nBrezel\nCroissant\nRoggenbrot\nVollkornbrot\nWeißbrot",
		px * Transform3D(Basis.IDENTITY, Vector3(-0.22, -0.1, 0)), 30, Color(0.97, 0.96, 0.92), 400, false, false).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label("0,40 €\n0,90 €\n1,30 €\n2,60 €\n2,90 €\n2,20 €",
		px * Transform3D(Basis.IDENTITY, Vector3(0.48, -0.1, 0)), 30, Color(0.97, 0.96, 0.92), 400, false, false).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ---- coffee station on the back counter (right)
	var b0 := Vector3(11.3, 0.12, Z1 - 0.62)
	mb.box_min(b0, Vector3(1.65, 0.9, 0.6), light_wood)
	mb.box_min(b0 + Vector3(-0.02, 0.9, -0.02), Vector3(1.69, 0.04, 0.64), w.pbr("Concrete034", 1.0, Color(0.95, 0.93, 0.9), 0.3, "worktop"))
	w.collider(Vector3(1.65, 1.0, 0.6), b0 + Vector3(0.83, 0.5, 0.3))
	_espresso(mb, Vector3(12.0, 1.06, Z1 - 0.32), steel, black)
	_grinder(mb, Vector3(11.5, 1.06, Z1 - 0.3), steel, black)
	# menu screens above the coffee station? (the price board is there) -> one screen on the right wall
	var scr := Vector3(X1 - 0.03, 2.35, 13.3)
	mb.box(scr, Vector3(0.03, 0.62, 1.05), black)
	mb.box(scr + Vector3(-0.017, 0, 0), Vector3(0.005, 0.56, 0.99), _emissive(Color(0.09, 0.07, 0.06), 1.0))
	var sxf := Transform3D(Basis(Vector3.UP, -PI / 2.0), scr + Vector3(-0.022, 0, 0))
	_label("Kaffee & Heißgetränke", sxf * Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0)), 21, Color(0.95, 0.78, 0.45), 600, true, false)
	_label("Kaffee  2,20 €\nCappuccino  2,90 €\nLatte Macchiato  3,30 €\nHeiße Schokolade  2,80 €",
		sxf * Transform3D(Basis.IDENTITY, Vector3(0, -0.07, 0)), 22, Color(0.97, 0.96, 0.92), 400, true, false)

	# ---- sales counter: light wood, LED plinth, long glass vitrine
	var c0 := Vector3(6.5, 0.12, 11.9)
	var cw := 6.1
	mb.box_min(c0, Vector3(cw, 0.92, 0.8), light_wood)
	mb.box_min(c0 + Vector3(0, 0.0, -0.06), Vector3(cw, 0.1, 0.06), anth)
	mb.box_min(c0 + Vector3(0, 0.1, -0.065), Vector3(cw, 0.012, 0.012), led)
	mb.box_min(c0 + Vector3(-0.03, 0.92, -0.05), Vector3(cw + 0.06, 0.04, 0.88), w.pbr("Concrete034", 1.0, Color(0.95, 0.93, 0.9), 0.3, "worktop"))
	w.collider(Vector3(cw + 0.1, 1.45, 0.9), c0 + Vector3(cw / 2.0, 0.72, 0.4))
	var vit := c0 + Vector3(0.05, 0.96, 0.02)
	var vw := 4.3
	var vg := MeshBuilder.new()
	vg.box(vit + Vector3(vw / 2.0, 0.25, -0.02), Vector3(vw, 0.5, 0.012), w.clear_glass(), Basis(Vector3.RIGHT, deg_to_rad(-10)))
	vg.box(vit + Vector3(vw / 2.0, 0.5, 0.32), Vector3(vw, 0.012, 0.66), w.clear_glass())
	vg.box(vit + Vector3(vw / 2.0, 0.27, 0.35), Vector3(vw, 0.01, 0.5), w.clear_glass())
	vg.commit(w, false)
	for k: float in [0.0, vw - 0.02]:
		mb.box_min(vit + Vector3(k, 0, 0), Vector3(0.02, 0.51, 0.66), steel)
	mb.box_min(vit + Vector3(0, 0.49, 0.6), Vector3(vw, 0.008, 0.02), led)
	# trays with pastries (lower level) and on the glass shelf
	var tray: StandardMaterial3D = w.plain(Color(0.7, 0.71, 0.72), 0.3, 0.9, "tray")
	var goods := ["pretzel", "croissant", "laugen", "plunder", "berliner", "schnecke", "puder"]
	for i in range(goods.size()):
		var tx := vit.x + 0.32 + i * 0.6
		mb.box_min(Vector3(tx - 0.27, vit.y + 0.01, vit.z + 0.06), Vector3(0.54, 0.01, 0.5), tray)
		for j in range(6):
			var p := Vector3(tx - 0.15 + (j % 2) * 0.28, vit.y + 0.02, vit.z + 0.15 + (j / 2) * 0.15)
			_good(goods[i], p)
	# glass shelf: cakes, filled rolls and pretzel sticks, each with a price tag
	var upper := ["schwarzwald", "erdbeer", "kaese", "roll", "roll", "laugenstange", "schwarzwald"]
	for i in range(upper.size()):
		var tx := vit.x + 0.32 + i * 0.6
		var y := vit.y + 0.28
		for j in range(3):
			var p := Vector3(tx - 0.16 + j * 0.16, y, vit.z + 0.32)
			match upper[i]:
				"roll":
					var r := BakeryGoods.filled_roll(rng)
					r.position = p
					w.add_child(r)
				"laugenstange":
					var g := BakeryGoods.make("laugenstange", rng)
					g.position = p + Vector3(0.06, 0, (j - 1) * 0.06)
					g.rotation.y = PI / 2.0 + rng.randf_range(-0.1, 0.1)
					w.add_child(g)
				_:
					var c := BakeryGoods.cake_slice(upper[i])
					c.position = p
					c.rotation.y = -PI / 2.0 + rng.randf_range(-0.2, 0.2)
					w.add_child(c)
		mb.box(Vector3(tx, y + 0.02, vit.z + 0.08), Vector3(0.07, 0.04, 0.004), w.plain(Color(0.95, 0.95, 0.93), 0.6, 0.0, "tag"),
			Basis(Vector3.RIGHT, -0.5))
	# right part of the counter: till, card terminal, paper bags, tip jar
	w.prop("CashRegister_01", c0 + Vector3(cw - 0.6, 0.96, 0.4), PI, 0.75)
	mb.box(c0 + Vector3(cw - 1.15, 1.0, 0.25), Vector3(0.08, 0.04, 0.16), black, Basis(Vector3.RIGHT, -0.4))
	for i in range(5):
		mb.box(c0 + Vector3(cw - 1.6, 0.97 + i * 0.006, 0.45), Vector3(0.24, 0.006, 0.36), w.plain(Color(0.66, 0.5, 0.32), 0.9, 0.0, "paperbag"))
	var jar := MeshBuilder.new()
	jar.cylinder(c0 + Vector3(cw - 1.95, 1.04, 0.15), 0.055, 0.15, w.clear_glass(), 16)
	jar.commit(w, false)
	mb.cylinder(c0 + Vector3(cw - 1.95, 0.985, 0.15), 0.05, 0.03, _gold(), 12)
	# a little plant on the counter
	w.prop("potted_plant_02", c0 + Vector3(cw - 0.15, 0.96, 0.55), 0.3, 0.45)

	# ---- window display (Schaufensterauslage) seen from the street
	var wd := Vector3(6.5, 0.12, Z0 + 0.12)
	mb.box_min(wd, Vector3(3.8, 0.7, 0.5), light_wood)
	mb.box_min(wd + Vector3(0, 0.7, 0), Vector3(3.8, 0.03, 0.5), w.pbr("Concrete034", 1.0, Color(0.95, 0.93, 0.9), 0.3, "worktop"))
	w.collider(Vector3(3.8, 0.8, 0.5), wd + Vector3(1.9, 0.4, 0.25))
	for i in range(4):
		var bp := wd + Vector3(0.45 + i * 0.95, 0.73, 0.25)
		w.prop("wicker_basket_01", bp, rng.randf() * 0.5, 1.3)
		var kinds_w := ["landbrot", "bauernbrot", "kasten", "weiss"]
		for j in range(3):
			var g := BakeryGoods.make(kinds_w[i], rng)
			g.position = bp + Vector3(-0.08 + j * 0.08, 0.07 + (j % 2) * 0.03, rng.randf_range(-0.04, 0.04))
			g.rotation.y = rng.randf_range(-0.6, 0.6)
			w.add_child(g)

	# ---- side counter closing the staff area, with a bread slicer and bag dispenser
	var sc0 := Vector3(X0 + 0.02, 0.12, 11.9)
	mb.box_min(sc0, Vector3(6.5 - sc0.x, 0.92, 0.8), light_wood)
	mb.box_min(sc0 + Vector3(0, 0.0, -0.06), Vector3(6.5 - sc0.x, 0.1, 0.06), anth)
	mb.box_min(sc0 + Vector3(0, 0.1, -0.065), Vector3(6.5 - sc0.x, 0.012, 0.012), led)
	mb.box_min(sc0 + Vector3(0, 0.92, -0.05), Vector3(6.5 - sc0.x, 0.04, 0.88), w.pbr("Concrete034", 1.0, Color(0.95, 0.93, 0.9), 0.3, "worktop"))
	w.collider(Vector3(6.5 - sc0.x, 1.2, 0.9), sc0 + Vector3((6.5 - sc0.x) / 2.0, 0.6, 0.4))
	_slicer(mb, Vector3(5.45, 1.08, 12.35), steel, black)
	for i in range(4):      # paper bread bags on a hook rail
		mb.box(Vector3(4.55 + i * 0.12, 1.25, 12.62), Vector3(0.1, 0.3, 0.012), w.plain(Color(0.78, 0.66, 0.48), 0.9, 0.0, "kraft"),
			Basis(Vector3.UP, 0.1 * i))
	mb.box(Vector3(4.73, 1.42, 12.62), Vector3(0.5, 0.012, 0.03), steel)
	# deck oven against the left wall: two baking decks with glass doors, warm light inside
	_oven(mb, Vector3(X0 + 0.48, 0.12, 13.8), steel, black)
	# flour sacks stacked by the oven
	for i in range(3):
		var sack := Vector3(4.42, 0.12 + 0.11 + (0.2 if i == 2 else 0.0), 14.7 - (0.42 * (i % 2)))
		mb.box(sack, Vector3(0.55, 0.2, 0.38), w.pbr("Plaster003", 0.3, Color(0.88, 0.83, 0.72), 1.0, "sack"), Basis(Vector3.UP, 0.15 * i))
	# drinks fridge on the right wall (glass door, lit, bottles)
	_fridge(mb, Vector3(X1 - 0.34, 0.12, 10.95), steel, black)
	# coffee to go: paper cups and lids next to the espresso machine
	for i in range(3):
		mb.cylinder(Vector3(12.65, 1.1 + i * 0.075, 14.72), 0.042, 0.11, w.plain(Color(0.93, 0.92, 0.9), 0.7, 0.0, "papercup"), 14)
	mb.cylinder(Vector3(12.65, 1.34, 14.72), 0.045, 0.012, black, 14)
	# napkins and a sugar jar on the counter
	mb.box(c0 + Vector3(cw - 2.35, 1.03, 0.2), Vector3(0.14, 0.12, 0.09), steel)
	var sj := MeshBuilder.new()
	sj.cylinder(c0 + Vector3(cw - 2.6, 1.04, 0.2), 0.04, 0.14, w.clear_glass(), 14)
	sj.commit(w, false)
	for i in range(8):
		mb.box(c0 + Vector3(cw - 2.6 + rng.randf_range(-0.02, 0.02), 1.06, 0.2 + rng.randf_range(-0.02, 0.02)), Vector3(0.006, 0.1, 0.006),
			w.plain(Color(0.92, 0.88, 0.75), 0.8, 0.0, "sugar"), Basis(Vector3.FORWARD, rng.randf_range(-0.3, 0.3)))
	# framed pictures on the left wall
	for i in range(2):
		var fp := Vector3(X0 + 0.025, 2.0, 9.4 + i * 1.2)
		mb.box(fp, Vector3(0.03, 0.62, 0.82), anth)
		mb.box(fp + Vector3(0.017, 0, 0), Vector3(0.005, 0.54, 0.74), w.pbr("WoodFloor051" if i == 0 else "Plaster003", 0.5,
			Color(0.95, 0.8, 0.45) if i == 0 else Color(0.85, 0.7, 0.45), 0.9, "pic%d" % i))
	_label("Seit 1921 in Regensburg", Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(X0 + 0.05, 1.55, 10.0)), 30, Color(0.3, 0.3, 0.32), 400, false, true)

	# ---- pendant lamps (black domes) over the counter and café, and their light
	for lp: Vector3 in [Vector3(7.4, 0, 12.3), Vector3(9.4, 0, 12.3), Vector3(11.4, 0, 12.3), Vector3(11.3, 0, 9.6)]:
		_pendant(mb, Vector3(lp.x, H, lp.z), 1.3)
		var l := OmniLight3D.new()
		l.position = Vector3(lp.x, H - 1.45, lp.z)
		l.light_color = Color(1.0, 0.8, 0.56)
		l.light_energy = 1.8
		l.omni_range = 5.5
		l.omni_attenuation = 1.4
		w.add_child(l)
		w.shop_lights.append(l)
	for lz: float in [9.6, 13.6]:
		var f := OmniLight3D.new()
		f.position = Vector3((X0 + X1) / 2.0, H - 0.3, lz)
		f.light_color = Color(1.0, 0.88, 0.72)
		f.light_energy = 1.0
		f.omni_range = 8.0
		w.add_child(f)
	var sl := SpotLight3D.new()     # warm light raking the bread shelves
	sl.position = Vector3(8.1, H - 0.15, Z1 - 1.8)
	sl.rotation_degrees = Vector3(-55, 0, 0)
	sl.light_color = Color(1.0, 0.8, 0.55)
	sl.light_energy = 3.5
	sl.spot_range = 4.5
	sl.spot_angle = 60.0
	w.add_child(sl)
	w.shop_lights.append(sl)

	# ---- hanging plants from the top of the shelving and a tall plant
	for vx: float in [5.2, 6.4, 9.8, 11.0]:
		_vine(Vector3(vx, 2.68, Z1 - 0.3), rng.randf_range(0.8, 1.4))
	w.prop("potted_plant_01", Vector3(4.6, 0.12, 9.0), 0.4, 0.9)

	# ---- café corner by the window
	var tbl := Vector3(11.4, 0.12, 9.6)
	mb.box(tbl + Vector3(0, 0.74, 0), Vector3(0.8, 0.035, 0.8), w.pbr("WoodFloor051", 1.0, Color(1, 0.92, 0.8), 0.6, "tabletop"))
	mb.cylinder(tbl + Vector3(0, 0.37, 0), 0.035, 0.72, anth, 10)
	mb.box(tbl + Vector3(0, 0.01, 0), Vector3(0.5, 0.02, 0.5), anth)
	for s: float in [-1.0, 1.0]:
		_chair(mb, tbl + Vector3(s * 0.75, 0, 0), s * PI / 2.0 + PI)
	w.collider(Vector3(2.2, 1.0, 1.0), tbl + Vector3(0, 0.5, 0))
	_good("croissant", tbl + Vector3(0.12, 0.76, 0.1))
	mb.cylinder(tbl + Vector3(-0.15, 0.8, -0.05), 0.045, 0.09, w.plain(Color(0.95, 0.95, 0.94), 0.25, 0.0, "porcelain"), 16)
	w.prop("wall_clock", Vector3(X0 + 0.03, 2.8, 11.0), PI / 2.0, 1.0)
	mb.commit(w)

	# reflection probe and the shop's sounds
	var rp := ReflectionProbe.new()
	rp.position = Vector3((X0 + X1) / 2.0, H / 2.0, (Z0 + Z1) / 2.0)
	rp.size = Vector3(X1 - X0, H, Z1 - Z0)
	rp.box_projection = true
	rp.interior = true
	rp.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	rp.ambient_color = Color(0.55, 0.46, 0.38)
	rp.ambient_color_energy = 0.6
	w.add_child(rp)
	w.radio = w._sound3d("cafe_music_loop", Vector3(X1 - 0.4, 2.6, 14.6), "Music", 2.0, -8.0)
	w.coffee = w._sound3d("coffee_machine_loop", Vector3(12.0, 1.3, Z1 - 0.32), "SFX", 2.5, -14.0)
	w.register = w._sound3d("cash_register", c0 + Vector3(cw - 0.6, 1.1, 0.4), "SFX", 3.0, -4.0, false)
	w.door_bell = w._sound3d("door_bell", Vector3((DOOR0 + DOOR1) / 2.0, 2.5, 8.4), "SFX", 4.0, -6.0, false)


static func _fill_shelf(start: Vector3, length: float, kinds: Array) -> void:
	var x := 0.0
	var i := 0
	while x < length - 0.12:
		var k: String = kinds[(i / 3) % kinds.size()]
		var size := {"landbrot": 0.24, "bauernbrot": 0.32, "kasten": 0.28, "weiss": 0.36, "broetchen": 0.11, "koerner": 0.11}
		var step: float = size.get(k, 0.2) + 0.02
		if x + step > length:
			break
		var g := BakeryGoods.make(k, rng)
		g.position = start + Vector3(x + step / 2.0, 0, rng.randf_range(-0.04, 0.04))
		if k in ["bauernbrot", "weiss", "kasten"]:
			g.rotation.y = rng.randf_range(-0.12, 0.12)
		w.add_child(g)
		# a second row behind for the small rolls
		if k in ["broetchen", "koerner"]:
			for back in [0.11, -0.11]:
				var g2 := BakeryGoods.make(k, rng)
				g2.position = g.position + Vector3(0, 0, back)
				w.add_child(g2)
		x += step
		i += 1


static func _good(kind: String, p: Vector3) -> void:
	match kind:
		"croissant":
			w.prop("croissant", p, rng.randf() * TAU, 1.0)
		"pretzel":
			var mi := MeshInstance3D.new()
			mi.mesh = w.pretzel_mesh()
			mi.material_override = w.plain(Color(0.42, 0.2, 0.07), 0.32, 0.0, "lye")
			mi.scale = Vector3.ONE * 0.12
			mi.rotation.y = rng.randf_range(-0.4, 0.4)
			mi.position = p + Vector3(0, 0.015, 0)
			w.add_child(mi)
		_:
			var g := BakeryGoods.make(kind, rng)
			g.position = p
			w.add_child(g)


static func _pendant(mb: MeshBuilder, top: Vector3, drop: float) -> void:
	var dome: StandardMaterial3D = w.plain(Color(0.12, 0.12, 0.12), 0.45, 0.5, "dome")
	mb.cylinder(top - Vector3(0, drop / 2.0, 0), 0.004, drop, w.plain(Color(0.02, 0.02, 0.02), 0.6), 6)
	var c := top - Vector3(0, drop + 0.12, 0)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.24
	cm.height = 0.22
	cm.cap_bottom = false
	cm.radial_segments = 24
	mi.mesh = cm
	mi.position = c
	var m: StandardMaterial3D = dome.duplicate()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	w.add_child(mi)
	mb.cylinder(c + Vector3(0, -0.09, 0), 0.09, 0.02, _emissive(Color(1.0, 0.85, 0.6), 6.0), 16)


static func _vine(top: Vector3, length: float) -> void:
	## trailing pothos: leaves along a few drooping strands
	var leaf_m: StandardMaterial3D = w.plain(Color(0.1, 0.26, 0.07), 0.5, 0.0, "pothos")
	leaf_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mb := MeshBuilder.new()
	mb.cylinder(top + Vector3(0, 0.08, 0), 0.1, 0.16, w.plain(Color(0.88, 0.86, 0.82), 0.7, 0.0, "pot"), 14)
	for s in range(4):
		var a := rng.randf() * TAU
		var p := top + Vector3(cos(a) * 0.08, 0.1, sin(a) * 0.08)
		var dir := Vector3(cos(a), 0, sin(a)) * 0.05
		var n := int(length * 22)
		for i in range(n):
			p += Vector3(dir.x, -length / n, dir.z) + Vector3(rng.randf_range(-0.01, 0.01), 0, rng.randf_range(-0.01, 0.01))
			dir *= 0.85
			var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.3, 1.2))
			mb.box(p, Vector3(0.05, 0.003, 0.065) * rng.randf_range(0.7, 1.2), leaf_m, b)
	mb.commit(w, false)


static func _espresso(mb: MeshBuilder, c: Vector3, steel: Material, black: Material) -> void:
	## two-group espresso machine: steel body, black side panels, group heads with
	## portafilters, steam wand, drip tray, cups warming on top
	mb.box(c + Vector3(0, 0.24, 0), Vector3(0.74, 0.48, 0.5), steel)
	for s: float in [-1.0, 1.0]:
		mb.box(c + Vector3(s * 0.38, 0.24, 0), Vector3(0.02, 0.5, 0.52), black)
	mb.box(c + Vector3(0, 0.49, 0), Vector3(0.78, 0.02, 0.54), steel)
	mb.box(c + Vector3(0, 0.0, -0.18), Vector3(0.7, 0.03, 0.18), black)
	mb.box(c + Vector3(0, 0.017, -0.18), Vector3(0.66, 0.006, 0.16), steel)
	for gx: float in [-0.17, 0.17]:
		mb.cylinder(c + Vector3(gx, 0.31, -0.27), 0.045, 0.08, steel, 16)
		mb.cylinder(c + Vector3(gx, 0.25, -0.29), 0.04, 0.04, steel, 16)
		mb.box(c + Vector3(gx, 0.25, -0.4), Vector3(0.03, 0.03, 0.18), black, Basis(Vector3.RIGHT, 0.15))
		mb.cylinder(c + Vector3(gx, 0.06, -0.29), 0.035, 0.07, w.plain(Color(0.96, 0.96, 0.95), 0.25, 0.0, "porcelain"), 14)
	mb.cylinder(c + Vector3(0.33, 0.27, -0.27), 0.007, 0.28, steel, 8, Basis(Vector3.RIGHT, 0.2))
	mb.box(c + Vector3(0, 0.4, -0.255), Vector3(0.5, 0.06, 0.01), black)
	for i in range(6):
		mb.cylinder(c + Vector3(-0.27 + i * 0.11, 0.54, 0.05), 0.035, 0.07, w.plain(Color(0.96, 0.96, 0.95), 0.25, 0.0, "porcelain"), 14)


static func _slicer(mb: MeshBuilder, c: Vector3, steel: Material, black: Material) -> void:
	## bread slicing machine: steel body, clear hood over the blades, crank wheel
	mb.box(c + Vector3(0, 0.12, 0), Vector3(0.62, 0.24, 0.42), steel)
	mb.box(c + Vector3(0, 0.3, 0.02), Vector3(0.58, 0.12, 0.36), black)
	var hood := MeshBuilder.new()
	hood.box(c + Vector3(-0.05, 0.47, 0), Vector3(0.4, 0.22, 0.34), w.clear_glass())
	hood.commit(w, false)
	mb.cylinder(c + Vector3(0.33, 0.3, 0), 0.07, 0.03, black, 16, Basis(Vector3.FORWARD, PI / 2.0))
	var loaf := BakeryGoods.make("bauernbrot", rng)
	loaf.position = c + Vector3(-0.05, 0.37, 0)
	loaf.rotation.y = PI / 2.0
	w.add_child(loaf)


static func _oven(mb: MeshBuilder, c: Vector3, steel: Material, black: Material) -> void:
	## two-deck baking oven (front faces +x, into the shop)
	mb.box(c + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 1.5), steel)                    # stand
	for d in range(2):
		var y := 0.62 + d * 0.5
		mb.box(c + Vector3(0, y + 0.22, 0), Vector3(0.9, 0.46, 1.6), steel)
		mb.box(c + Vector3(0.452, y + 0.22, 0), Vector3(0.01, 0.3, 1.2), _emissive(Color(1.0, 0.55, 0.22), 1.6))   # glowing window
		mb.box(c + Vector3(0.47, y + 0.4, 0), Vector3(0.03, 0.03, 1.1), black)        # handle
	mb.box(c + Vector3(0, 1.72, 0), Vector3(0.9, 0.22, 1.6), black)                    # control panel / hood
	mb.box(c + Vector3(0.452, 1.72, 0.45), Vector3(0.005, 0.07, 0.22), _emissive(Color(0.3, 0.9, 0.6), 2.0))
	w.collider(Vector3(0.95, 1.9, 1.65), c + Vector3(0, 0.95, 0))
	var glow := OmniLight3D.new()
	glow.position = c + Vector3(0.7, 1.0, 0)
	glow.light_color = Color(1.0, 0.6, 0.3)
	glow.light_energy = 0.6
	glow.omni_range = 1.8
	w.add_child(glow)


static func _fridge(mb: MeshBuilder, c: Vector3, steel: Material, black: Material) -> void:
	## upright drinks cooler, door facing -x, bottles on four shelves
	# hollow cabinet: back, sides, plinth and top (the front stays open)
	mb.box(c + Vector3(0.3, 0.98, 0), Vector3(0.02, 1.96, 0.74), black)
	for sz: float in [-0.36, 0.36]:
		mb.box(c + Vector3(0, 0.98, sz), Vector3(0.62, 1.96, 0.02), black)
	mb.box(c + Vector3(0, 0.08, 0), Vector3(0.62, 0.16, 0.74), black)
	mb.box(c + Vector3(0, 1.94, 0), Vector3(0.62, 0.04, 0.74), black)
	mb.box(c + Vector3(0.296, 1.05, 0), Vector3(0.01, 1.6, 0.62), _emissive(Color(0.86, 0.92, 1.0), 0.35))     # lit back panel
	mb.box(c + Vector3(0, 1.88, 0), Vector3(0.64, 0.14, 0.76), _emissive(Color(0.95, 0.97, 1.0), 1.2))          # header
	var cols := [Color(0.85, 0.25, 0.08), Color(0.15, 0.45, 0.2), Color(0.95, 0.8, 0.2), Color(0.85, 0.85, 0.9), Color(0.5, 0.1, 0.12)]
	for sh in range(4):
		var y := 0.38 + sh * 0.38
		mb.box(c + Vector3(-0.05, y, 0), Vector3(0.48, 0.012, 0.6), w.plain(Color(0.85, 0.87, 0.9), 0.3, 0.6, "fridgeshelf"))
		for k in range(6):
			var bc: Color = cols[(sh * 2 + k) % cols.size()]
			mb.cylinder(c + Vector3(-0.18, y + 0.13, -0.24 + k * 0.095), 0.03, 0.24, w.plain(bc, 0.2, 0.0, "bottle%d" % ((sh * 2 + k) % cols.size())), 10)
	# open-front door frame (no glass pane: it rendered as a dark mirror)
	for dz: float in [-0.34, 0.34]:
		mb.box(c + Vector3(-0.32, 1.0, dz), Vector3(0.03, 1.72, 0.03), black)
	for dy: float in [0.15, 1.85]:
		mb.box(c + Vector3(-0.32, dy, 0), Vector3(0.03, 0.04, 0.7), black)
	var lt := OmniLight3D.new()
	lt.position = c + Vector3(-0.05, 1.6, 0)
	lt.light_color = Color(0.9, 0.95, 1.0)
	lt.light_energy = 0.6
	lt.omni_range = 0.9
	w.add_child(lt)
	mb.box(c + Vector3(-0.34, 1.0, 0.31), Vector3(0.03, 0.5, 0.025), steel)
	w.collider(Vector3(0.66, 2.0, 0.78), c + Vector3(0, 1.0, 0))


static func _grinder(mb: MeshBuilder, c: Vector3, steel: Material, black: Material) -> void:
	mb.box(c + Vector3(0, 0.2, 0), Vector3(0.18, 0.4, 0.24), black)
	mb.box(c + Vector3(0, 0.02, -0.06), Vector3(0.16, 0.03, 0.14), steel)
	mb.cylinder(c + Vector3(0, 0.5, 0), 0.08, 0.2, w.plain(Color(0.25, 0.14, 0.07), 0.8, 0.0, "beans"), 14)
	var hop := MeshBuilder.new()
	hop.cylinder(c + Vector3(0, 0.52, 0), 0.095, 0.26, w.clear_glass(), 16)
	hop.commit(w, false)
