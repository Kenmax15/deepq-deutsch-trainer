"""Copy the mission JSON into web/data/ as both .json and .js.

The .js copy lets web/index.html run when opened directly from disk (file://),
where browsers block fetch() of local JSON files.
    python tools/web_data.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
for src in sorted((ROOT / "godot/data/missions").glob("*.json")):
    data = json.loads(src.read_text(encoding="utf-8"))
    out = ROOT / "web/data"
    (out / src.name).write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    js = "window.MISSIONS = window.MISSIONS || {};\nwindow.MISSIONS[%s] = %s;\n" % (
        json.dumps(data["id"]), json.dumps(data, ensure_ascii=False, indent=1))
    (out / (src.stem + ".js")).write_text(js, encoding="utf-8")
    print("wrote", src.stem)
