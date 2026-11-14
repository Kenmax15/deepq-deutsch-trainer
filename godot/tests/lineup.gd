extends Node3D
## Debug scene: all characters side by side (used for screenshots).
func _ready():
	var clip := "Idle"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clip="): clip = a.substr(7)
	var names := ["player", "seller", "man_suit", "woman_sport", "man_casual", "woman_casual", "customer"]
	for i in names.size():
		var c := CharacterModel.new()
		c.model_path = "res://assets/characters/%s.glb" % names[i]
		c.idle_clip = clip
		c.position = Vector3((i - 3) * 0.9, 0, 0)
		add_child(c)
		if "--rest" in OS.get_cmdline_user_args():
			c.set_process(false)
			await get_tree().process_frame
			var ap: AnimationPlayer = c.find_child("AnimationPlayer", true, false)
			ap.stop()
			var sk: Skeleton3D = c.find_child("Skeleton3D", true, false)
			sk.reset_bone_poses()
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(20, 20)
	floor.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.5, 0.5, 0.5)
	floor.material_override = fm
	add_child(floor)
	var cam := Camera3D.new(); cam.position = Vector3(0, 1.1, 5.2); cam.fov = 50; add_child(cam)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 30, 0); sun.shadow_enabled = true; add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.3, 0.32, 0.35)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env; add_child(we)
