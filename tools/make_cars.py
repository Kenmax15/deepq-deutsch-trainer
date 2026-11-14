"""Procedural cars for the street (compact hatchback, saloon, delivery van).

    python3 tools/make_cars.py <out_dir>

Each body is lofted from cross-sections, smoothed with a subdivision surface,
given wheel arches (boolean), and split into materials by position: paint
(recoloured in Godot per car), glass, black plastic, head and tail lights,
chrome. Wheels are separate nodes (wheel_*) so the game can spin them.
German number plates are drawn with PIL. Everything is generated, so the
models belong to the project (no third-party licence).
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Matrix

OUT = sys.argv[-1] if len(sys.argv) > 1 else "/tmp"

# stations: (s from nose, z bottom, z belt line, z top, half width, half width at top)
MODELS = {
    "car_hatch": dict(L=4.25, wheel_s=(0.86, 3.50), r=0.31, track=0.76, glass_s=(1.3, 4.25), plate="B·DQ 2026", st=[
        (0.00, 0.32, 0.60, 0.64, 0.76, 0.66), (0.10, 0.22, 0.70, 0.75, 0.86, 0.80),
        (0.40, 0.20, 0.79, 0.83, 0.89, 0.84), (0.85, 0.20, 0.86, 0.89, 0.895, 0.85),
        (1.30, 0.20, 0.92, 0.95, 0.895, 0.86), (1.75, 0.20, 0.95, 1.22, 0.895, 0.75),
        (2.15, 0.20, 0.96, 1.44, 0.895, 0.70), (3.05, 0.20, 0.97, 1.46, 0.895, 0.71),
        (3.70, 0.22, 0.98, 1.42, 0.89, 0.70), (4.05, 0.26, 0.98, 1.20, 0.87, 0.72),
        (4.21, 0.32, 0.95, 1.02, 0.83, 0.74), (4.25, 0.40, 0.90, 0.95, 0.78, 0.70)]),
    "car_sedan": dict(L=4.70, wheel_s=(0.95, 3.75), r=0.32, track=0.78, glass_s=(1.45, 3.9), plate="M·LK 418", st=[
        (0.00, 0.32, 0.60, 0.64, 0.77, 0.68), (0.12, 0.22, 0.70, 0.75, 0.87, 0.81),
        (0.50, 0.20, 0.79, 0.83, 0.90, 0.85), (1.00, 0.20, 0.86, 0.89, 0.905, 0.86),
        (1.45, 0.20, 0.92, 0.95, 0.905, 0.86), (1.95, 0.20, 0.95, 1.20, 0.905, 0.76),
        (2.35, 0.20, 0.96, 1.42, 0.905, 0.71), (3.15, 0.20, 0.97, 1.44, 0.905, 0.71),
        (3.75, 0.22, 0.98, 1.17, 0.90, 0.76), (4.05, 0.25, 0.99, 1.03, 0.90, 0.86),
        (4.58, 0.32, 0.97, 1.00, 0.86, 0.80), (4.70, 0.42, 0.90, 0.95, 0.80, 0.72)]),
    "van": dict(L=5.30, wheel_s=(0.95, 4.25), r=0.36, track=0.86, glass_s=(0.9, 1.75), plate="HH·RT 207", st=[
        (0.00, 0.36, 0.72, 0.78, 0.90, 0.82), (0.10, 0.30, 0.84, 0.90, 0.98, 0.92),
        (0.55, 0.30, 0.96, 1.05, 1.00, 0.96), (0.95, 0.30, 1.05, 1.38, 1.00, 0.90),
        (1.40, 0.30, 1.10, 2.30, 1.00, 0.93), (1.65, 0.30, 1.10, 2.42, 1.00, 0.96),
        (5.20, 0.30, 1.10, 2.42, 1.00, 0.97), (5.30, 0.36, 1.00, 2.36, 0.98, 0.95)]),
}


def interp(st, s, k):
    if s <= st[0][0]:
        return st[0][k]
    for a, b in zip(st, st[1:]):
        if a[0] <= s <= b[0]:
            t = (s - a[0]) / max(1e-6, b[0] - a[0])
            return a[k] * (1 - t) + b[k] * t
    return st[-1][k]


def ring(zb, zbelt, ztop, w, wt):
    zbelt = min(zbelt, ztop - 0.03)
    return [(-w * 0.86, zb), (-w, zb + 0.13), (-w, zbelt - 0.05), (-w * 0.985, zbelt),
            (-wt, ztop - 0.06), (-wt * 0.86, ztop), (wt * 0.86, ztop), (wt, ztop - 0.06),
            (w * 0.985, zbelt), (w, zbelt - 0.05), (w, zb + 0.13), (w * 0.86, zb)]


def mat(name, color, metal=0.0, rough=0.5, emit=None, alpha=1.0, coat=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if coat:
        b.inputs["Coat Weight"].default_value = coat
        b.inputs["Coat Roughness"].default_value = 0.05
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = 1.5
    return m


def _obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    return o


def cyl(name, verts, radius, depth, loc, rot=(0, math.pi / 2, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=radius, radius2=radius, depth=depth)
    o = _obj(name, bm)
    o.location = loc
    o.rotation_euler = rot
    return o


def cube(name, loc):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    o = _obj(name, bm)
    o.location = loc
    return o


def apply_mod(o, name):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=name)


def build(name, d):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    L, st = d["L"], d["st"]
    paint = mat("paint", (0.6, 0.6, 0.62), 0.6, 0.28, coat=1.0)
    glass = mat("glass", (0.02, 0.025, 0.03), 0.0, 0.03)
    plastic = mat("plastic", (0.025, 0.025, 0.027), 0.0, 0.55)
    head = mat("headlight", (0.85, 0.87, 0.9), 0.4, 0.08, emit=(0.6, 0.6, 0.55))
    tail = mat("taillight", (0.45, 0.02, 0.02), 0.0, 0.15, emit=(0.5, 0.0, 0.0))
    rubber = mat("tyre", (0.03, 0.03, 0.03), 0.0, 0.85)
    rim = mat("rim", (0.62, 0.63, 0.65), 1.0, 0.25)
    liner = mat("liner", (0.01, 0.01, 0.01), 0.0, 0.9)

    # ---- loft
    bm = bmesh.new()
    rings = []
    for s, zb, zbelt, ztop, w, wt in st:
        y = -L / 2.0 + s
        rings.append([bm.verts.new((x, y, z)) for x, z in ring(zb, zbelt, ztop, w, wt)])
    n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    body = bpy.data.objects.new("body", me)
    bpy.context.scene.collection.objects.link(body)
    bpy.context.view_layer.objects.active = body
    body.select_set(True)
    sub = body.modifiers.new("sub", "SUBSURF")
    sub.levels = 3
    sub.render_levels = 3
    apply_mod(body, "sub")
    # normals outward
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")

    # ---- wheel arches
    r, track = d["r"], d["track"]
    cutters = []
    for ws in d["wheel_s"]:
        cutters.append(cyl("cut", 48, r + 0.06, 2.4, (0, -L / 2 + ws, r)))
    for c in cutters:
        bo = body.modifiers.new("arch", "BOOLEAN")
        bo.object = c
        bo.operation = "DIFFERENCE"
        bo.solver = "EXACT"
        apply_mod(body, bo.name)
        bpy.data.objects.remove(c, do_unlink=True)

    # ---- materials by position
    body.data.materials.clear()
    for m in (paint, glass, plastic, head, tail):
        body.data.materials.append(m)
    idx = {m.name: i for i, m in enumerate(body.data.materials)}
    gs0, gs1 = d["glass_s"]
    top_max = max(x[3] for x in st)
    roof_st = [x[0] for x in st if x[3] >= top_max - 0.05]
    roof_s0, roof_s1 = min(roof_st), max(roof_st)
    for f in body.data.polygons:
        c, nrm = f.center, f.normal
        s = c.y + L / 2.0
        zbelt = interp(st, s, 2)
        ztop = interp(st, s, 3)
        ax = abs(c.x)
        m = "paint"
        if c.z < 0.29 or (c.z < 0.36 and (s < 0.15 or s > L - 0.15)):
            m = "plastic"
        roof = roof_s0 - 0.08 <= s <= roof_s1 + 0.05 and nrm.z > 0.72
        side_top = c.z > ztop - 0.045 and abs(nrm.x) > 0.6
        if gs0 <= s <= gs1 and c.z > zbelt + 0.035 and not roof and not side_top and nrm.z < 0.97:
            m = "glass"
        if name == "van" and s < 1.75 and c.z > 1.12 and abs(nrm.z) < 0.9 and nrm.y < 0.2 and c.z < 2.25:
            m = "glass"
        if s < 0.14 and 0.38 < c.z < zbelt - 0.22 and ax < 0.48:
            m = "plastic"
        f.material_index = idx[m]
    for f in body.data.polygons:
        f.use_smooth = True
    if os.environ.get("CAR_DEBUG"):
        for f in body.data.polygons:
            sx = f.center.y + L / 2.0
            if 1.6 < sx < 1.9 and abs(f.center.x) < 0.1 and f.center.z > 0.9:
                print("DBG s=%.2f z=%.2f belt=%.2f top=%.2f n=%s mat=%d" % (sx, f.center.z, interp(st, sx, 2), interp(st, sx, 3), tuple(round(v, 2) for v in f.normal), f.material_index))

    # ---- head and tail lights: lens units fitted onto the body surface
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get()
    tree = BVHTree.FromObject(body, dg)
    z_front = interp(st, 0.15, 2) - 0.12
    z_rear = interp(st, L - 0.1, 2) - 0.08
    w_front = interp(st, 0.2, 4)
    w_rear = interp(st, L - 0.15, 4)
    for sx in (-1, 1):
        for front in (True, False):
            x = sx * ((w_front - 0.24) if front else (w_rear - 0.2))
            z = z_front if front else z_rear
            origin = Vector((x, -L if front else L, z))
            dirv = Vector((0, 1, 0)) if front else Vector((0, -1, 0))
            hit, nrm, _, _ = tree.ray_cast(origin, dirv)
            if hit is None:
                continue
            lamp = cube("lamp", hit - nrm * 0.012)
            lamp.scale = (0.34, 0.05, 0.1) if front else (0.3, 0.05, 0.09)
            q = nrm.to_track_quat("-Y", "Z")
            lamp.rotation_mode = "QUATERNION"
            lamp.rotation_quaternion = q
            bv = lamp.modifiers.new("b", "BEVEL")
            bv.width = 0.025
            bv.segments = 3
            apply_mod(lamp, "b")
            lamp.data.materials.append(head if front else tail)
            for p in lamp.data.polygons:
                p.use_smooth = True

    # ---- arch liners, wheels
    for k, ws in enumerate(d["wheel_s"]):
        lo = cyl("liner%d" % k, 40, r + 0.055, 2 * track - 0.05, (0, -L / 2 + ws, r))
        lo.data.materials.append(liner)
        for side, sx in (("l", -1), ("r", 1)):
            wname = "wheel_%s%s" % ("f" if k == 0 else "b", side)
            wheel = bpy.data.objects.new(wname, None)
            bpy.context.scene.collection.objects.link(wheel)
            wheel.location = (sx * track, -L / 2 + ws, r)
            ty = cyl(wname + "_tyre", 40, r, 0.21, (0, 0, 0))
            ty.data.materials.append(rubber)
            bev = ty.modifiers.new("bev", "BEVEL")
            bev.width = 0.05
            bev.segments = 4
            apply_mod(ty, "bev")
            for p in ty.data.polygons:
                p.use_smooth = True
            ty.parent = wheel
            ri = cyl(wname + "_rim", 32, r * 0.66, 0.215, (sx * 0.003, 0, 0))
            ri.data.materials.append(rim)
            ri.parent = wheel
            # five spokes (dark gaps between them)
            for q in range(5):
                a = q * 2 * math.pi / 5
                sp = cube(wname + "_spoke", (sx * 0.11, math.cos(a) * r * 0.36, math.sin(a) * r * 0.36))
                sp.scale = (0.012, r * 0.2, r * 0.13)
                sp.rotation_euler = (a + math.pi / 2, 0, 0)
                sp.data.materials.append(plastic)
                sp.parent = wheel

    # ---- mirrors, plates
    zb_m = interp(st, d["glass_s"][0] + 0.15, 2) + 0.06
    for sx in (-1, 1):
        mi = cube("mirror", (sx * (interp(st, gs0 + 0.15, 4) + 0.1), -L / 2 + gs0 + 0.15, zb_m))
        mi.scale = (0.16, 0.1, 0.1)
        bv = mi.modifiers.new("b", "BEVEL")
        bv.width = 0.03
        bv.segments = 3
        apply_mod(mi, "b")
        mi.data.materials.append(paint)
    plate_img = make_plate(d["plate"])
    pm = bpy.data.materials.new("plate")
    pm.use_nodes = True
    tex = pm.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(plate_img)
    bsdf = pm.node_tree.nodes["Principled BSDF"]
    pm.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.35
    for front in (True, False):
        s = 0.0 if front else L
        y = -L / 2 + s + (-0.012 if front else 0.012)
        z = 0.42 if front else interp(st, L - 0.05, 2) - 0.32
        bm = bmesh.new()
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
        pl = _obj("plate", bm)
        pl.location = (0, y, z)
        pl.rotation_euler = (math.pi / 2, 0, 0 if front else math.pi)
        pl.scale = (0.52, 0.11, 1)
        pl.data.materials.append(pm)

    # ---- export
    out = os.path.join(OUT, name + ".glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True,
                              export_image_format="WEBP", export_apply=True)
    print("CAR", out, os.path.getsize(out) // 1024, "KB", len(body.data.polygons), "faces")


def make_plate(text):
    from PIL import Image, ImageDraw, ImageFont
    W, H = 520, 110
    im = Image.new("RGB", (W, H), (245, 245, 242))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W - 1, H - 1], outline=(10, 10, 10), width=5)
    d.rectangle([5, 5, 58, H - 6], fill=(0, 51, 153))
    d.text((18, 70), "D", fill=(255, 255, 255), font=_font(30))
    for k in range(12):
        a = k * math.pi / 6
        d.ellipse([31 + 16 * math.cos(a) - 2, 32 + 16 * math.sin(a) - 2, 31 + 16 * math.cos(a) + 2, 32 + 16 * math.sin(a) + 2], fill=(255, 204, 0))
    d.text((78, 12), text.replace("·", " "), fill=(15, 15, 15), font=_font(78))
    p = "/tmp/plate_%s.png" % text.replace("·", "_").replace(" ", "_")
    im.save(p)
    return p


def _font(size):
    from PIL import ImageFont
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


if __name__ == "__main__":
    for nm, dd in MODELS.items():
        build(nm, dd)
