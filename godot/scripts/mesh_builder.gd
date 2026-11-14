class_name MeshBuilder
extends RefCounted
## Collects many boxes / cylinders per material and merges them into one
## MeshInstance3D per material (a whole facade is then a handful of draw calls).
## Materials use world-space triplanar mapping, so no UVs are needed.

var _tools := {}      # Material -> SurfaceTool
var xform := Transform3D.IDENTITY   # local -> parent space (e.g. one house)

static var _box_arrays: Array = []
static var _cyl_arrays := {}


static func _unit_box() -> Array:
	if _box_arrays.is_empty():
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE
		_box_arrays = bm.get_mesh_arrays()
	return _box_arrays


static func _unit_cyl(sides: int) -> Array:
	if not _cyl_arrays.has(sides):
		var cm := CylinderMesh.new()
		cm.top_radius = 0.5
		cm.bottom_radius = 0.5
		cm.height = 1.0
		cm.radial_segments = sides
		cm.rings = 1
		_cyl_arrays[sides] = cm.get_mesh_arrays()
	return _cyl_arrays[sides]


func _st(m: Material) -> SurfaceTool:
	if not _tools.has(m):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tools[m] = st
	return _tools[m]


func _append(arrays: Array, t: Transform3D, m: Material) -> void:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_st(m).append_from(am, 0, xform * t)


## Axis-aligned box (in builder space) from its min corner and size.
func box_min(p: Vector3, size: Vector3, m: Material) -> void:
	box(p + size * 0.5, size, m)


func box(center: Vector3, size: Vector3, m: Material, basis := Basis.IDENTITY) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
		return
	var t := Transform3D(basis * Basis.from_scale(size), center)
	_append(_unit_box(), t, m)


func cylinder(center: Vector3, radius: float, height: float, m: Material, sides := 12, basis := Basis.IDENTITY) -> void:
	var t := Transform3D(basis * Basis.from_scale(Vector3(radius * 2.0, height, radius * 2.0)), center)
	_append(_unit_cyl(sides), t, m)


func commit(parent: Node, shadows := true) -> Array:
	var out := []
	for m in _tools:
		var st: SurfaceTool = _tools[m]
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		out.append(mi)
	_tools.clear()
	return out
