class_name BakeryGoods
extends RefCounted
## Procedural breads and pastries for the shop, with vertex-coloured crusts:
## scoring cuts with paler crumb, flour dusting, seeds, sugar glaze, fruit.
## Each kind is generated once and shared by all instances.

const KINDS := ["landbrot", "bauernbrot", "kasten", "weiss", "broetchen", "koerner",
	"schnecke", "plunder", "puder"]

static var _cache := {}
static var _mat: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.vertex_color_is_srgb = true
		_mat.roughness = 0.78
		_mat.normal_enabled = true
		_mat.normal_texture = load("res://assets/pbr/Plaster003/normalgl.jpg")
		_mat.normal_scale = 0.9
		_mat.uv1_triplanar = true
		_mat.uv1_scale = Vector3.ONE * 9.0
	return _mat


static func _h(x: float, y: float, z: float) -> float:
	## cheap hash noise in 0..1
	var v := sin(x * 127.1 + y * 311.7 + z * 74.7) * 43758.5453
	return v - floor(v)


static func _vn(p: Vector3, f: float) -> float:
	## smooth value noise (trilinear) used for flour patches and crust tone
	var q := p * f
	var i := q.floor()
	var t := q - i
	t = t * t * (Vector3.ONE * 3.0 - 2.0 * t)
	var r := 0.0
	for dx in 2:
		for dy in 2:
			for dz in 2:
				var w := (t.x if dx else 1.0 - t.x) * (t.y if dy else 1.0 - t.y) * (t.z if dz else 1.0 - t.z)
				r += w * _h(i.x + dx, i.y + dy, i.z + dz)
	return r


static func mesh(kind: String) -> ArrayMesh:
	if _cache.has(kind):
		return _cache[kind]
	var P := {
		# a = half length, b = half width, h = height, crust colour, flour amount
		"landbrot": {"a": 0.11, "b": 0.11, "h": 0.1, "c": Color(0.33, 0.19, 0.09), "flour": 0.45, "cuts": "cross"},
		"bauernbrot": {"a": 0.15, "b": 0.085, "h": 0.095, "c": Color(0.3, 0.17, 0.08), "flour": 0.3, "cuts": "diag"},
		"kasten": {"a": 0.13, "b": 0.065, "h": 0.1, "c": Color(0.26, 0.15, 0.08), "flour": 0.0, "cuts": "none", "box": true, "seeds": 0.5},
		"weiss": {"a": 0.17, "b": 0.06, "h": 0.07, "c": Color(0.72, 0.47, 0.2), "flour": 0.1, "cuts": "slash"},
		"broetchen": {"a": 0.05, "b": 0.042, "h": 0.042, "c": Color(0.74, 0.48, 0.2), "flour": 0.05, "cuts": "slit"},
		"koerner": {"a": 0.05, "b": 0.042, "h": 0.042, "c": Color(0.52, 0.34, 0.17), "flour": 0.0, "cuts": "slit", "seeds": 1.0},
		"schnecke": {"a": 0.055, "b": 0.055, "h": 0.022, "c": Color(0.76, 0.52, 0.26), "flour": 0.0, "cuts": "spiral", "glaze": true},
		"plunder": {"a": 0.05, "b": 0.05, "h": 0.022, "c": Color(0.82, 0.58, 0.3), "flour": 0.0, "cuts": "none", "fruit": true, "box": true},
		"puder": {"a": 0.075, "b": 0.045, "h": 0.035, "c": Color(0.80, 0.56, 0.3), "flour": 1.0, "cuts": "none"},
	}
	var p: Dictionary = P.get(kind, P["broetchen"])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var LAT := 18
	var LON := 36
	var verts := []
	var cols := []
	var a: float = p.a
	var b: float = p.b
	var h: float = p.h
	var crust: Color = p.c
	for i in range(LAT + 1):
		var th := PI * i / LAT
		var row := []
		var crow := []
		for j in range(LON):
			var ph := TAU * j / LON
			var sx := sin(th) * cos(ph)
			var sz := sin(th) * sin(ph)
			var sy := cos(th)
			if p.get("box", false):
				# squarer footprint (tin loaf, Danish)
				sx = sign(sx) * pow(abs(sx), 0.45)
				sz = sign(sz) * pow(abs(sz), 0.45)
			var y := sy * h
			if y < 0.0:
				y *= 0.18           # flat base
			var v := Vector3(sx * a, y + h * 0.18, sz * b)
			var u := Vector2(sx, sz)   # normalised top coordinates
			var top := clampf(sy, 0.0, 1.0)
			var groove := 0.0
			match p.cuts:
				"cross":
					for c in [-0.35, 0.35]:
						groove = max(groove, exp(-pow((u.x - c) / 0.07, 2.0)))
						groove = max(groove, exp(-pow((u.y - c) / 0.07, 2.0)))
				"diag":
					for c in [-0.5, 0.0, 0.5]:
						groove = max(groove, exp(-pow((u.x * 0.8 + u.y * 0.6 - c) / 0.08, 2.0)))
				"slash":
					for c in [-0.6, -0.2, 0.2, 0.6]:
						groove = max(groove, exp(-pow((u.x * 0.95 + u.y * 0.3 - c) / 0.06, 2.0)) * float(abs(u.y) < 0.6))
				"slit":
					groove = exp(-pow(u.y / 0.12, 2.0)) * float(abs(u.x) < 0.7)
				"spiral":
					var r := u.length()
					var ang := atan2(u.y, u.x)
					groove = pow(0.5 + 0.5 * cos(ang - r * 18.0), 6.0)
			groove *= smoothstep(0.25, 0.6, top)
			v.y -= groove * h * 0.18
			v.x *= 1.0 + groove * 0.05
			# colour: crust tone, darker shoulders, paler crumb in the cuts, flour on top
			var n1 := _vn(v * 30.0, 1.0)
			var col := crust.lerp(crust.darkened(0.35), smoothstep(0.2, 0.9, top) * 0.5 + (n1 - 0.5) * 0.3)
			if sy < 0.0:
				col = crust.darkened(0.15)
			col = col.lerp(Color(0.86, 0.72, 0.5), groove * 0.85)
			var flour: float = p.flour
			if flour > 0.0:
				var fl := smoothstep(0.45, 0.75, _vn(v * 22.0, 1.0) + top * 0.35) * flour * smoothstep(0.1, 0.5, top)
				col = col.lerp(Color(0.93, 0.91, 0.86), clampf(fl * (1.0 - groove * 0.6), 0.0, 0.92))
			if p.get("seeds", 0.0) > 0.0 and top > 0.15:
				var s := _h(round(v.x * 260.0), round(v.y * 260.0), round(v.z * 260.0))
				if s > 1.0 - 0.32 * float(p.seeds):
					col = Color(0.88, 0.8, 0.6) if s > 0.93 else Color(0.18, 0.13, 0.09)
			if p.get("glaze", false) and top > 0.3:
				col = col.lerp(Color(0.95, 0.93, 0.88), 0.55 * smoothstep(0.55, 0.8, _vn(v * 40.0, 1.0)))
			if p.get("fruit", false) and u.length() < 0.55 and top > 0.3:
				var f := _vn(v * 55.0, 1.0)
				col = Color(0.45, 0.04, 0.1) if f > 0.55 else (Color(0.2, 0.05, 0.22) if f < 0.4 else Color(0.62, 0.1, 0.12))
				v.y += 0.004
			row.append(v)
			crow.append(col)
		verts.append(row)
		cols.append(crow)
	for i in range(LAT):
		for j in range(LON):
			var j2 := (j + 1) % LON
			var quad := [[i, j], [i + 1, j], [i + 1, j2], [i, j], [i + 1, j2], [i, j2]]
			for q in quad:
				st.set_color(cols[q[0]][q[1]])
				st.add_vertex(verts[q[0]][q[1]])
	st.generate_normals()
	var m := st.commit()
	_cache[kind] = m
	return m


## Convenience: a MeshInstance3D of a kind with a little random variation.
static func make(kind: String, rng: RandomNumberGenerator) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(kind)
	mi.material_override = material()
	var k := rng.randf_range(0.92, 1.08)
	mi.scale = Vector3(k, rng.randf_range(0.92, 1.08), k * rng.randf_range(0.95, 1.05))
	mi.rotation.y = rng.randf_range(-0.25, 0.25)
	return mi
