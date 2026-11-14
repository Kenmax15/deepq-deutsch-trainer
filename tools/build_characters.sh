#!/bin/bash
# Regenerates every MakeHuman character of the pilot (godot/assets/characters/*.glb).
#
# One-time setup (Linux or Windows with Python 3.13):
#   pip install bpy                                    # Blender as a Python module
#   git clone https://github.com/makehumancommunity/mpfb2
#   copy mpfb2/src/mpfb to  <bpy user extensions>/user_default/mpfb
#       (python -c "import bpy;print(bpy.utils.user_resource('EXTENSIONS'))")
#   unzip makehuman_system_assets_cc0.zip (static.makehumancommunity.org/asset_packs)
#       into <bpy user extensions>/.user/user_default/mpfb/data/
#   CMU mocap BVH files (github.com/sfd158/cmu-mocap, folder data/) -> CMU_DIR (default /tmp/cmu/data)
# Afterwards copy the per-clip speeds printed in *.clips.txt into
# godot/assets/characters/clips.json (used to keep feet from sliding).
set -e
cd "$(dirname "$0")/.."
OUT=godot/assets/characters
TMP=${TMP_DIR:-/tmp/mh_build}
mkdir -p "$OUT" "$TMP"
build() {  # name  json
  python3 tools/mh_build.py "$1" "$2" "$TMP/$1.blend" > "$TMP/$1.log" 2>&1
  python3 tools/mh_animate.py "$TMP/$1.blend" "$OUT/$1.glb" >> "$TMP/$1.log" 2>&1
  grep -E "EXPORTED|Error|Traceback" "$TMP/$1.log" || true
}
build player     '{"gender":1.0,"age":0.5,"weight":0.5,"muscle":0.55,"height":0.55,"skin":"young_caucasian_male","hair":"short02","eyebrows":"eyebrow001","clothes":["male_casualsuit05","shoes06"]}'
build seller     '{"gender":0.0,"age":0.72,"weight":0.6,"height":0.45,"skin":"middleage_caucasian_female","hair":"ponytail01","eyebrows":"eyebrow010","clothes":["female_elegantsuit01","shoes04"],"apron_on":"elegantsuit"}'
build man_suit   '{"gender":1.0,"age":0.7,"weight":0.55,"height":0.6,"skin":"middleage_caucasian_male","hair":"short04","eyebrows":"eyebrow002","clothes":["male_elegantsuit01","shoes04"]}'
build woman_sport '{"gender":0.0,"age":0.45,"weight":0.4,"height":0.55,"skin":"young_caucasian_female","hair":"bob02","eyebrows":"eyebrow011","clothes":["female_sportsuit01","shoes05"]}'
build man_casual '{"gender":1.0,"age":0.47,"weight":0.5,"muscle":0.6,"height":0.6,"african":0.9,"caucasian":0.1,"asian":0.0,"skin":"young_african_male","hair":"short01","eyebrows":"eyebrow003","clothes":["male_casualsuit03","shoes02"]}'
build woman_casual '{"gender":0.0,"age":0.6,"weight":0.5,"height":0.5,"asian":0.8,"caucasian":0.2,"african":0.0,"skin":"middleage_asian_female","hair":"long01","eyebrows":"eyebrow009","clothes":["female_casualsuit01","shoes01"]}'
build customer   '{"gender":1.0,"age":0.88,"weight":0.62,"height":0.45,"skin":"old_caucasian_male","hair":"short03","eyebrows":"eyebrow004","clothes":["male_worksuit01","shoes03","fedora01"]}'
build baker2     '{"gender":1.0,"age":0.42,"weight":0.48,"muscle":0.55,"height":0.55,"skin":"young_caucasian_male2","hair":"short02","eyebrows":"eyebrow001","clothes":["male_casualsuit02","shoes02"],"apron_on":"casualsuit02"}'
build old_woman  '{"gender":0.0,"age":0.9,"weight":0.6,"height":0.4,"skin":"old_caucasian_female","hair":"bob02","eyebrows":"eyebrow010","clothes":["female_elegantsuit01","shoes04"]}'
build cafe_guest '{"gender":0.0,"age":0.45,"weight":0.45,"height":0.5,"african":0.9,"caucasian":0.1,"asian":0.0,"skin":"young_african_female","hair":"braid01","eyebrows":"eyebrow011","clothes":["female_casualsuit01","shoes05"]}'
