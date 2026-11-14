class_name HeadLook
extends SkeletonModifier3D
## Turns the neck and head towards a target on top of the animation, keeping
## the head upright (mocap idles wander and tilt; a person you talk to looks
## at you). `weight` fades the effect in and out.

var target: Node3D
var weight := 0.0
var max_yaw := deg_to_rad(65.0)
var max_pitch := deg_to_rad(22.0)
var _head := -1
var _neck := -1


func _ready() -> void:
	var sk := get_skeleton()
	if sk:
		_head = sk.find_bone("head")
		_neck = sk.find_bone("neck_01")


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or _head < 0 or weight <= 0.001 or target == null or not is_instance_valid(target):
		return
	var inv := sk.global_transform.affine_inverse()
	var tgt := inv * target.global_position
	if _neck >= 0:
		_aim(sk, _neck, tgt, 0.4, 0.3)
	_aim(sk, _head, tgt, 1.0, 1.0)


func _aim(sk: Skeleton3D, bone: int, tgt: Vector3, yaw_k: float, pitch_k: float) -> void:
	var pose := sk.get_bone_global_pose(bone)
	var to := tgt - pose.origin
	var yaw := clampf(atan2(to.x, to.z), -max_yaw, max_yaw) * yaw_k
	var pitch := clampf(atan2(to.y, Vector2(to.x, to.z).length()), -max_pitch, max_pitch) * pitch_k
	var rest := sk.get_bone_global_rest(bone).basis.orthonormalized()
	var want := (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -pitch) * rest).get_rotation_quaternion()
	var have := pose.basis.orthonormalized().get_rotation_quaternion()
	var q := have.slerp(want, weight)
	sk.set_bone_global_pose(bone, Transform3D(Basis(q).scaled(pose.basis.get_scale()), pose.origin))
