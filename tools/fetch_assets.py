"""Download the CC0 PBR textures, HDRI sky and props used by the realistic street.

Sources (all CC0 1.0): ambientCG (ambientcg.com) and Poly Haven (polyhaven.com).
    python3 tools/fetch_assets.py
"""
import io, json, os, subprocess, sys, zipfile, urllib.request

ROOT = os.path.join(os.path.dirname(__file__), "..", "godot", "assets")
UA = {"User-Agent": "Mozilla/5.0 (DeepQ asset fetch)"}

# ambientCG materials: id -> resolution
TEXTURES = {
    "Asphalt031": "2K", "PavingStones111": "2K", "PavingStones150": "1K", "Concrete031": "1K",
    "Concrete034": "1K", "Plaster001": "1K", "Plaster003": "1K", "Bricks105": "1K",
    "RoofingTiles006": "1K", "RoofingTiles013A": "1K",
    "WoodFloor043": "1K", "WoodFloor051": "1K", "Tiles139": "1K", "Tiles107": "1K",
    "PaintedWood005": "1K",
}
KEEP = ("_Color", "_NormalGL", "_Roughness", "_AmbientOcclusion")

HDRI = ("kloofendal_48d_partly_cloudy_puresky", "2k")

# Poly Haven models (glTF, 1k textures)
MODELS = ["street_lamp_02", "painted_wooden_bench", "utility_box_01",
          "water_manhole_cover", "standing_chalkboard_01", "CashRegister_01",
          "wicker_basket_01", "wicker_basket_02", "hamburger_buns",
          "croissant", "potted_plant_01", "potted_plant_02", "round_wooden_table_01",
          "painted_wooden_chair_01", "wall_clock", "hanging_industrial_lamp", "planter_box_01",
          "wooden_cutting_board"]


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA)).read()


def textures():
    for tid, res in TEXTURES.items():
        out = os.path.join(ROOT, "pbr", tid)
        if os.path.isdir(out):
            continue
        os.makedirs(out)
        z = zipfile.ZipFile(io.BytesIO(get(f"https://ambientcg.com/get?file={tid}_{res}-JPG.zip")))
        for n in z.namelist():
            if n.endswith(".jpg") and any(k in n for k in KEEP):
                short = [k for k in KEEP if k in n][0][1:].lower()
                open(os.path.join(out, short + ".jpg"), "wb").write(z.read(n))
        print("texture", tid)


def hdri():
    name, res = HDRI
    out = os.path.join(ROOT, "sky", f"{name}_{res}.hdr")
    if os.path.exists(out):
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    files = json.loads(get(f"https://api.polyhaven.com/files/{name}"))
    open(out, "wb").write(get(files["hdri"][res]["hdr"]["url"]))
    print("hdri", name)


def models():
    for mid in MODELS:
        out = os.path.join(ROOT, "props", mid)
        if os.path.isdir(out):
            continue
        files = json.loads(get(f"https://api.polyhaven.com/files/{mid}"))
        g = files["gltf"].get("1k") or list(files["gltf"].values())[0]
        g = g["gltf"]
        os.makedirs(out)
        open(os.path.join(out, os.path.basename(g["url"])), "wb").write(get(g["url"]))
        for rel, inc in g.get("include", {}).items():
            p = os.path.join(out, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "wb").write(get(inc["url"]))
        print("model", mid)


if __name__ == "__main__":
    textures()
    hdri()
    models()
