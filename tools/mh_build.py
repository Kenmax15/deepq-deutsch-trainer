"""Build one MakeHuman (MPFB2) character and save it as a .blend for later steps.

Run with Blender's Python module (pip package `bpy`) after installing MPFB2 as an
extension and the CC0 "makehuman_system_assets" pack (setup: see the header of
tools/build_characters.sh).

    python3 tools/mh_build.py <name> '<json spec>' <out.blend>
"""
import bpy, sys, json, importlib, addon_utils

addon_utils.enable("bl_ext.user_default.mpfb", default_set=True, persistent=True)


def di(p, k):
    for m in list(sys.modules):
        if m.endswith(p):
            return getattr(importlib.import_module(m), k)
    raise ImportError(p)


HumanService = di("mpfb.services.humanservice", "HumanService")
AssetService = di("mpfb.services.assetservice", "AssetService")
TargetService = di("mpfb.services.targetservice", "TargetService")
HOP = di("mpfb.entities.objectproperties", "HumanObjectProperties")

name, spec, out = sys.argv[1], json.loads(sys.argv[2]), sys.argv[3]

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

bm = HumanService.create_human()
bm.name = name
for k in ("gender", "age", "muscle", "weight", "height", "proportions",
          "african", "asian", "caucasian", "cupsize", "firmness"):
    if k in spec:
        HOP.set_value(k, spec[k], entity_reference=bm)
TargetService.reapply_macro_details(bm)

skin = AssetService.find_asset_absolute_path(spec["skin"] + ".mhmat", asset_subdir="skins")
HumanService.set_character_skin(skin, bm, skin_type="GAMEENGINE")
HumanService.add_builtin_rig(bm, "game_engine")

parts = [("eyes", "low-poly.mhclo", "Eyes"),
         ("eyebrows", spec.get("eyebrows", "eyebrow001") + ".mhclo", "Eyebrows"),
         ("eyelashes", "eyelashes01.mhclo", "Eyelashes"),
         ("teeth", "teeth_base.mhclo", "Teeth"),
         ("tongue", "tongue01.mhclo", "Tongue")]
if spec.get("hair"):
    parts.append(("hair", spec["hair"] + ".mhclo", "Hair"))
for c in spec.get("clothes", []):
    parts.append(("clothes", c + ".mhclo", "Clothes"))
for sub, fn, kind in parts:
    p = AssetService.find_asset_absolute_path(fn, asset_subdir=sub)
    if p is None:
        print("MISSING", sub, fn)
        continue
    HumanService.add_mhclo_asset(p, bm, asset_type=kind, material_type="GAMEENGINE")

# Bake clothing masks (removes skin hidden under clothes) and drop helper geometry
ExportService = di("mpfb.services.exportservice", "ExportService")
ExportService.bake_modifiers_remove_helpers(bm, bake_masks=True, bake_subdiv=False,
                                            remove_helpers=True, also_proxy=True)
# Optional bakery apron: front panel of the given garment, copied (keeps the
# skin weights, so it moves with the body), pushed outwards, dark brown cloth.
if spec.get("apron_on"):
    import bmesh
    src = [o for o in bpy.data.objects if o.type == "MESH" and spec["apron_on"] in o.name.lower()][0]
    me = src.data.copy()
    ap = src.copy()
    ap.data = me
    ap.name = "apron"
    bpy.context.scene.collection.objects.link(ap)
    bmx = bmesh.new()
    bmx.from_mesh(me)
    zmin = min(v.co.z for v in bmx.verts)
    zmax = max(v.co.z for v in bmx.verts)
    def keep(f):
        c, n = f.calc_center_median(), f.normal
        h = c.z
        width = 0.085 if h > 1.1 else (0.13 if h > 1.02 else 0.22)
        return n.y < -0.25 and 0.62 < h < 1.31 and abs(c.x) < width
    bmesh.ops.delete(bmx, geom=[f for f in bmx.faces if not keep(f)], context="FACES")
    bmesh.ops.delete(bmx, geom=[v for v in bmx.verts if not v.link_faces], context="VERTS")
    bmx.normal_update()
    for v in bmx.verts:
        v.co += v.normal * 0.009
    bmx.to_mesh(me)
    bmx.free()
    am = bpy.data.materials.new("apron_cloth")
    am.use_nodes = True
    b = am.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.11, 0.075, 0.055, 1)
    b.inputs["Roughness"].default_value = 0.85
    me.materials.clear()
    me.materials.append(am)
    for poly in me.polygons:
        poly.material_index = 0
        poly.use_smooth = True
    print("APRON faces", len(me.polygons))

for o in bpy.data.objects:
    if o.type == "ARMATURE":
        o.name = "Armature"
        o.data.name = "Armature"
bpy.ops.wm.save_as_mainfile(filepath=out)
print("SAVED", out)
