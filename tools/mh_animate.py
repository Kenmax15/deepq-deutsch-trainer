"""Retarget CMU motion-capture clips (BVH) onto a MakeHuman "game_engine" rig
and export the finished character as a binary glTF (.glb) for Godot.

    python3 tools/mh_animate.py <character.blend> <out.glb> [--preview out.png]

The motion data comes from the CMU Graphics Lab Motion Capture Database
(mocap.cs.cmu.edu), BVH conversion by B. Hahne (cgspeed.com). CMU: "This data
is free for use in research and commercial projects worldwide."

Method, per frame and per mapped bone:
    R_target = R_src(t) · R_src_rest⁻¹ · Q · R_target_rest
where all rotations are in world space and Q is the swing that turns the target
rest bone onto the source rest bone (this absorbs A-pose vs T-pose). World
rotations are then converted back to local pose rotations down the hierarchy.
Hip translation is scaled by the ratio of leg lengths. Loops are cut on the
best-matching pair of frames and closed with a smooth correction.
"""
import bpy, sys, math, os
from mathutils import Matrix, Quaternion, Vector

CMU = os.environ.get("CMU_DIR", "/tmp/cmu/data")
FPS = 30
HEAD_PITCH = {"Idle": -3.0, "Wait": -4.0, "Talk": -2.0, "Wave": 0.0, "Walk": -6.0, "Run": -6.0, "Sit": -8.0}
# target forward lean of the chest (degrees): upright standing, slight lean when moving
CHEST_PITCH = {"Idle": 13.0, "Wait": 14.0, "Talk": 14.0, "Wave": 13.0, "Walk": 14.0, "Run": 20.0, "Sit": 24.0}
# whole-body lean (neck over mid-ankle, degrees) for the standing clips
BODY_LEAN = {"Idle": 1.0, "Wait": 1.0, "Talk": 1.5, "Wave": 1.0}
CURL_SIGN = float(os.environ.get("CURL_SIGN", "1"))
SRC_FPS = 120

# CMU (MotionBuilder-friendly BVH) -> MakeHuman game_engine rig
MAP = {
    "Hips": "pelvis", "LowerBack": "spine_01", "Spine": "spine_02", "Spine1": "spine_03",
    "Neck": "neck_01", "Head": "head",
    "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l", "LeftHand": "hand_l",
    "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r", "RightHand": "hand_r",
    "LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
    "RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r",
}
# Clavicles are deliberately not mapped: the CMU actors' shrugged shoulders
# looked tense on the characters; the rig's relaxed rest clavicles look natural.
# Bones whose BVH tail is a stub: aim them at another bone's tail instead.
SRC_AIM = {"LeftHand": "LeftFingerBase", "RightHand": "RightFingerBase",
           "Spine1": "Neck", "Hips": "LowerBack", "Neck": "Neck1", "Head": "Head"}
TGT_AIM = {}

# name, file, start s, end s (None = auto cycle), loop, in-place, (cycle window s)
CLIPS = [
    ("Idle", "077/77_02.bvh", 1.0, 7.0, True, True, None),
    ("Walk", "035/35_01.bvh", 0.4, None, True, True, (0.9, 1.3)),
    ("Run", "035/35_17.bvh", 0.2, None, True, True, (0.55, 0.85)),
    ("Talk", "018/18_08.bvh", 4.0, 10.0, True, True, None),
    ("Wave", "143/143_25.bvh", 0.5, 3.5, False, True, None),
    ("Wait", "040/40_10.bvh", 2.0, 10.0, True, True, None),
    ("Sit", "018/18_12.bvh", 1.0, 10.0, True, True, "calm"),
]


def world_rest(obj, bone):
    return (obj.matrix_world @ bone.matrix_local).to_quaternion()


def aim_dir(obj, bones, name, aim):
    b = bones[name]
    head = obj.matrix_world @ b.head_local
    tgt = aim.get(name)
    if tgt and tgt != name and tgt in bones:
        tail = obj.matrix_world @ bones[tgt].tail_local
    else:
        tail = obj.matrix_world @ b.tail_local
    return (tail - head).normalized()


def sample_source(src, t0, t1):
    """Return list of dicts {bone: world quaternion} and hip world positions."""
    scn = bpy.context.scene
    frames, hips = [], []
    n = int(round((t1 - t0) * FPS))
    for i in range(n + 1):
        f = 1 + (t0 + i / FPS) * SRC_FPS
        scn.frame_set(int(f), subframe=f - int(f))
        rec = {}
        for sb in MAP:
            pb = src.pose.bones[sb]
            rec[sb] = (src.matrix_world @ pb.matrix).to_quaternion()
        frames.append(rec)
        hips.append((src.matrix_world @ src.pose.bones["Hips"].matrix).translation.copy())
        for fb in ("LeftFoot", "RightFoot"):
            z = (src.matrix_world @ src.pose.bones[fb].matrix).translation.z
            sample_source.foot_min = min(sample_source.foot_min, z)
    return frames, hips


def feature(src, f):
    scn = bpy.context.scene
    scn.frame_set(int(f), subframe=f - int(f))
    v = []
    for n in ("LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg", "LeftArm", "RightArm", "LeftFoot", "RightFoot"):
        q = src.pose.bones[n].matrix_basis.to_quaternion()
        v.extend(q)
    return v


def find_cycle(src, t0, win, total):
    """Best loop [a, b] with period in win, starting near t0."""
    best = None
    step = 1.0 / FPS
    feats = {}
    def F(t):
        k = round(t * FPS)
        if k not in feats:
            feats[k] = feature(src, 1 + k / FPS * SRC_FPS)
        return feats[k]
    a = t0
    while a < min(t0 + 0.6, total - win[1]):
        b = a + win[0]
        while b <= a + win[1] and b < total:
            fa, fb = F(a), F(b)
            d = 0.0
            for i in range(0, len(fa), 4):
                dot = abs(sum(fa[i + j] * fb[i + j] for j in range(4)))
                d += 1.0 - min(1.0, dot)
            if best is None or d < best[0]:
                best = (d, a, b)
            b += step
        a += step
    return best[1], best[2]


def find_calm(src, a, b, length):
    """Window of `length` s with the least hand movement and the hands low
    (resting on the lap), for a quiet seated idle."""
    scn = bpy.context.scene
    step = 0.1
    samples = []
    t = a
    while t <= b:
        f = 1 + t * SRC_FPS
        scn.frame_set(int(f), subframe=f - int(f))
        hips = (src.matrix_world @ src.pose.bones["Hips"].matrix).translation
        hands = [(src.matrix_world @ src.pose.bones[n].matrix).translation - hips for n in ("LeftHand", "RightHand")]
        samples.append((t, hands))
        t += step
    best = None
    n = int(length / step)
    for i in range(len(samples) - n):
        move = sum((samples[j + 1][1][k] - samples[j][1][k]).length for j in range(i, i + n) for k in (0, 1))
        height = sum(max(0.0, h.z) for j in range(i, i + n) for h in samples[j][1])
        score = move + 0.05 * height
        if best is None or score < best[0]:
            best = (score, samples[i][0])
    return best[1], best[1] + length


def build_action(tgt, src, clip):
    name, fn, t0, t1, loop, inplace, win = clip
    for o in list(bpy.data.objects):
        if o.type == "ARMATURE" and o is not tgt:
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.import_anim.bvh(filepath=os.path.join(CMU, fn), global_scale=1.0,
                            update_scene_fps=False, update_scene_duration=False)
    src = bpy.context.active_object
    act = src.animation_data.action
    total = (act.frame_range[1] - 1) / SRC_FPS
    if win == "calm":
        t0, t1 = find_calm(src, t0, min(t1, total), 3.0)
    elif t1 is None:
        t0, t1 = find_cycle(src, t0, win, total)
    t1 = min(t1, total)
    print(f"  {name}: {fn} {t0:.2f}-{t1:.2f}s")

    # rest data
    sb_bones, tb_bones = src.data.bones, tgt.data.bones
    corr = {}
    for s, t in MAP.items():
        ds = aim_dir(src, sb_bones, s, SRC_AIM)
        dt = aim_dir(tgt, tb_bones, t, TGT_AIM)
        q_swing = dt.rotation_difference(ds)
        corr[t] = (s, world_rest(src, sb_bones[s]).inverted() @ q_swing @ world_rest(tgt, tb_bones[t]))

    # scale from leg length
    def leg(obj, bones, up, low, foot):
        return ((bones[up].head_local - bones[low].head_local).length +
                (bones[low].head_local - bones[foot].head_local).length)
    scale = leg(tgt, tb_bones, "thigh_l", "calf_l", "foot_l") / leg(src, sb_bones, "LeftUpLeg", "LeftLeg", "LeftFoot")
    scale *= tgt.matrix_world.to_scale()[0] ** -1

    sample_source.foot_min = 1e9
    frames, hips = sample_source(src, t0, t1)
    n = len(frames)
    # ground: the lowest ankle of the clip sits where the target's ankle rests
    src_leg = ((src.matrix_world @ sb_bones["Hips"].head_local).z -
               (src.matrix_world @ sb_bones["LeftFoot"].head_local).z)
    stand_z = sample_source.foot_min + src_leg
    # face the camera: turn the clip so the average hip heading is the rest heading
    r0 = world_rest(src, sb_bones["Hips"])
    fwd0 = Vector((0, -1, 0))
    sx = sy = 0.0
    for rec in frames:
        f = (rec["Hips"] @ r0.inverted()) @ fwd0
        sx += f.x
        sy += f.y
    yaw = math.atan2(sx, -sy)
    rc = Quaternion(Vector((0, 0, 1)), -yaw)
    piv = hips[0].copy()
    for rec in frames:
        for k in rec:
            rec[k] = rc @ rec[k]
    hips = [piv + rc @ (h - piv) for h in hips]
    hip0 = (src.matrix_world @ sb_bones["Hips"].head_local)
    # in-place: remove the mean horizontal travel (keep the bob and sway)
    travel = hips[-1] - hips[0]
    speed = Vector((travel.x, travel.y, 0)).length * scale / max(1e-6, (t1 - t0))
    disp = []
    for i, h in enumerate(hips):
        d = (h - hip0)
        d.z = h.z - stand_z
        if inplace:
            lin = hips[0] + travel * (i / max(1, n - 1)) if loop else hips[0]
            d = h - lin
            d.z = h.z - stand_z
            d.x += 0.0
        disp.append(d * scale)
    if inplace:
        mx = sum(d.x for d in disp) / n
        my = sum(d.y for d in disp) / n
        for d in disp:
            d.x -= mx
            d.y -= my

    # local rotations, parent first
    order = [b.name for b in tgt.data.bones]
    tw_inv = tgt.matrix_world.to_quaternion().inverted()
    rest_local = {b.name: b.matrix_local.to_quaternion() for b in tgt.data.bones}
    all_q = []
    for i, rec in enumerate(frames):
        arm_q = {}
        for bn in order:
            b = tgt.data.bones[bn]
            if bn in corr:
                s, c = corr[bn]
                arm_q[bn] = tw_inv @ rec[s] @ c
            else:
                parent_pose = arm_q.get(b.parent.name) if b.parent else Quaternion()
                parent_rest = rest_local[b.parent.name] if b.parent else Quaternion()
                arm_q[bn] = parent_pose @ parent_rest.inverted() @ rest_local[bn]
        all_q.append(arm_q)

    # upright back: the CMU actors stand and walk slightly hunched; measure the
    # mean forward lean of the chest and straighten it, spread over the spine
    def chest_pitch(arm_q):
        u = arm_q["spine_03"] @ rest_local["spine_03"].inverted() @ Vector((0, 0, 1))
        f = arm_q["pelvis"] @ rest_local["pelvis"].inverted() @ Vector((0, -1, 0))
        f.z = 0.0
        f.normalize()
        return math.atan2(u.dot(f), u.z), f
    if "spine_03" in corr and "pelvis" in corr:
        lean = sum(chest_pitch(q)[0] for q in all_q) / len(all_q)
        c = math.radians(CHEST_PITCH.get(name, 0.0)) - lean
        for arm_q in all_q:
            _, f = chest_pitch(arm_q)
            axis = Vector((0, 0, 1)).cross(f).normalized()
            for bn, k in (("spine_01", 0.1), ("spine_02", 0.5), ("spine_03", 1.0), ("neck_01", 1.0), ("head", 1.0)):
                if bn in arm_q:
                    arm_q[bn] = Quaternion(axis, c * k) @ arm_q[bn]
        after = sum(chest_pitch(q)[0] for q in all_q) / len(all_q)
        print(f"    chest lean {math.degrees(lean):.1f} -> {math.degrees(after):.1f}")

    # whole-body balance: when standing, the neck should sit above the ankles.
    # The CMU actors lean forward from the ankles; tilt the pelvis subtree back
    # about the mid-ankle point and move the pelvis so the feet stay planted.
    if name in BODY_LEAN and "pelvis" in corr and "foot_l" in corr:
        sub = [bn for bn in order if bn == "pelvis" or any(p.name == "pelvis" for p in tb_bones[bn].parent_recursive)]
        def fk(arm_q):
            pos = {}
            for bn in order:
                b = tb_bones[bn]
                if b.parent is None:
                    pos[bn] = b.head_local.copy()
                else:
                    p = b.parent.name
                    pos[bn] = pos[p] + (arm_q[p] @ rest_local[p].inverted()) @ (b.head_local - b.parent.head_local)
            return pos
        def body_lean(arm_q):
            pos = fk(arm_q)
            a = (pos["foot_l"] + pos["foot_r"]) / 2.0
            v = pos["neck_01"] - a
            f = arm_q["pelvis"] @ rest_local["pelvis"].inverted() @ Vector((0, -1, 0))
            f.z = 0.0
            f.normalize()
            return math.atan2(v.dot(f), v.z), f, pos, a
        lean = sum(body_lean(q)[0] for q in all_q) / len(all_q)
        c = math.radians(BODY_LEAN[name]) - lean
        m3 = tgt.matrix_world.to_3x3()
        for i, arm_q in enumerate(all_q):
            _, f, pos, a = body_lean(arm_q)
            q = Quaternion(Vector((0, 0, 1)).cross(f).normalized(), c)
            for bn in sub:
                arm_q[bn] = q @ arm_q[bn]
            pa = pos["pelvis"] - a
            disp[i] = disp[i] + m3 @ (q @ pa - pa)
        after = sum(body_lean(q)[0] for q in all_q) / len(all_q)
        print(f"    body lean {math.degrees(lean):.1f} -> {math.degrees(after):.1f}")

    # keep the gaze level: the mocap actors tend to look at the floor
    if "head" in corr:
        r0 = rest_local["head"]
        pitch = 0.0
        for arm_q in all_q:
            f = arm_q["head"] @ r0.inverted() @ Vector((0, -1, 0))
            pitch += math.atan2(f.z, Vector((f.x, f.y)).length)
        pitch /= len(all_q)
        target = math.radians(HEAD_PITCH.get(name, 0.0))
        corr_ang = target - pitch
        for arm_q in all_q:
            f = arm_q["head"] @ r0.inverted() @ Vector((0, -1, 0))
            axis = Vector((f.y, -f.x, 0.0))
            if axis.length < 1e-4:
                continue
            axis.normalize()
            for bn, k in (("neck_01", 0.5), ("head", 1.0)):
                if bn in arm_q:
                    arm_q[bn] = Quaternion(axis, corr_ang * k) @ arm_q[bn]
        print(f"    head pitch {math.degrees(pitch):.1f} -> {HEAD_PITCH.get(name, 0.0)}")

    locs = []
    for arm_q in all_q:
        local = {}
        for bn in order:
            b = tgt.data.bones[bn]
            pq = arm_q[b.parent.name] if b.parent else Quaternion()
            pr = rest_local[b.parent.name] if b.parent else Quaternion()
            local[bn] = (pr.inverted() @ rest_local[bn]).inverted() @ pq.inverted() @ arm_q[bn]
        locs.append(local)

    # relaxed hands: the mocap has no finger data
    for bn in order:
        a = None
        if any(bn.startswith(f) for f in ("index_", "middle_", "ring_", "pinky_")):
            a = {"01": 18, "02": 28, "03": 18}.get(bn.split("_")[1], 0)
            a += {"index": -4, "middle": 0, "ring": 4, "pinky": 8}[bn.split("_")[0]]
        elif bn.startswith("thumb_"):
            a = 10
        if a:
            q = Quaternion(Vector((1, 0, 0)), math.radians(a * CURL_SIGN))
            for i in range(n):
                locs[i][bn] = locs[i][bn] @ q

    if loop:  # close the loop smoothly
        for bn in order:
            qa, qb = locs[0][bn], locs[-1][bn]
            fix = qb.inverted() @ qa
            if fix.w < 0:
                fix.negate()
            for i in range(n):
                locs[i][bn] = locs[i][bn] @ Quaternion().slerp(fix, i / (n - 1))
        dz = disp[-1] - disp[0]
        for i in range(n):
            disp[i] = disp[i] - dz * (i / (n - 1))

    # write the action on the target
    tgt.animation_data_create()
    new = bpy.data.actions.new(name)
    tgt.animation_data.action = new
    pel = tgt.data.bones["pelvis"]
    pel_rest = pel.matrix_local
    for pb in tgt.pose.bones:
        pb.rotation_mode = "QUATERNION"
    for i in range(n):
        fr = i + 1
        for bn in order:
            pb = tgt.pose.bones[bn]
            q = locs[i][bn]
            if i and q.dot(locs[i - 1][bn]) < 0:
                q.negate()
                locs[i][bn] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=fr, group=bn)
        # pelvis translation, expressed in its rest frame
        dw = tgt.matrix_world.inverted().to_3x3() @ disp[i]
        loc = pel_rest.to_3x3().inverted() @ dw
        tp = tgt.pose.bones["pelvis"]
        tp.location = loc
        tp.keyframe_insert("location", frame=fr, group="pelvis")
    new.use_fake_user = True
    trk = tgt.animation_data.nla_tracks.new()
    trk.name = name
    st = trk.strips.new(name, 1, new)
    st.name = name
    tgt.animation_data.action = None
    for pb in tgt.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()
    bpy.data.objects.remove(src, do_unlink=True)
    return name, (t1 - t0), speed


def export(out):
    # keep the download small: skin 2048 px, everything else 1024 px
    for img in bpy.data.images:
        if img.size[0] == 0:
            continue
        nm = img.name.lower()
        lim = 1024
        if "skinned" in nm or "skin" in nm:
            lim = 2048
        elif any(k in nm for k in ("teeth", "tongue", "eye")):
            lim = 256
        if max(img.size) > lim:
            f = lim / max(img.size)
            img.scale(int(img.size[0] * f), int(img.size[1] * f))
    # bake MakeHuman's modelling shape keys into the meshes (Godot would ignore them)
    for o in bpy.data.objects:
        if o.type == "MESH" and o.data.shape_keys:
            bpy.ops.object.select_all(action="DESELECT")
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=False,
                              export_animation_mode="NLA_TRACKS", export_image_format="WEBP",
                              export_image_quality=82, export_yup=True, export_apply=False,
                              export_force_sampling=True, export_frame_step=1)
    print("EXPORTED", out, os.path.getsize(out) // 1024, "KB")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    blend, out = argv[0], argv[1]
    bpy.ops.wm.open_mainfile(filepath=blend)
    bpy.context.scene.render.fps = FPS
    tgt = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    info = []
    for c in CLIPS:
        info.append(build_action(tgt, None, c))
    for nm, dur, sp in info:
        print(f"CLIP {nm} {dur:.2f}s speed {sp:.2f} m/s")
    bpy.ops.wm.save_as_mainfile(filepath=blend.replace(".blend", "_anim.blend"))
    export(out)
    with open(out + ".clips.txt", "w") as f:
        for nm, dur, sp in info:
            f.write(f"{nm} {dur:.3f} {sp:.3f}\n")


if __name__ == "__main__":
    main()
