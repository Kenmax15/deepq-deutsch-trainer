"""Write web/data/<mission>.js from web/data/<mission>.json.

The .js copy lets web/index.html run when opened directly from disk (file://),
where browsers block fetch() of local JSON files.
    python tools/web_data.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
for src in sorted((ROOT / "web/data").glob("*.json")):
    data = json.loads(src.read_text(encoding="utf-8"))
    out = src.parent
    js = "window.MISSIONS = window.MISSIONS || {};\nwindow.MISSIONS[%s] = %s;\n" % (
        json.dumps(data["id"]), json.dumps(data, ensure_ascii=False, indent=1))
    (out / (src.stem + ".js")).write_text(js, encoding="utf-8")
    print("wrote", src.stem)
