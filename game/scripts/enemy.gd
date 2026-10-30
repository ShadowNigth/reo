extends CharacterBody3D
var game: Node
var data: Dictionary
var hp := 90.0
var max_hp := 90.0
var dead := false
var model: Node3D
var anim: AnimationPlayer
var skeleton: Skeleton3D
var agent: NavigationAgent3D
var collision: CollisionShape3D
var height := 1.8
var attack_timer := 0.0
var attack_windup := -1.0
var stagger := 0.0
var repath := 0.0
var vocal_timer := 0.0
var death_timer := 0.0
var knockback := Vector3.ZERO
var gore_meshes: Array[MeshInstance3D] = []
var last_hit_point := Vector3.ZERO
var serial := 0
var counted := true
var ragdoll: PhysicalBoneSimulator3D
var ragdoll_bones: Array[PhysicalBone3D] = []
var ragdoll_active := false

func setup(g: Node, kind: String, wave: int) -> void:
	game = g; data = game.catalog.enemy(kind)
	var difficulty := 1.0 + minf(float(wave-1)*0.065, 3.5)
	max_hp = data.hp * difficulty; hp = max_hp
	height = 1.8 * float(data.scale)
	if kind == "crawler": height = 0.72
	collision_layer = 2; collision_mask = 1
	floor_snap_length = 0.4
	add_to_group("enemies"); add_to_group("damageable")
	collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = data.radius; capsule.height = maxf(height, data.radius*2.1)
	collision.shape = capsule; collision.position.y = height*0.5
	add_child(collision)
	model = game.assets.instance("res://assets/models/%s.glb" % data.model)
	add_child(model)
	model.rotation.y = PI
	var bounds := _bounds(model)
	var s := height / maxf(bounds.size.y,0.1)
	if kind == "crawler": s = 1.15
	model.scale = Vector3.ONE*s
	model.position.y = -bounds.position.y*s if kind != "crawler" else 0.15
	for node in model.find_children("*","MeshInstance3D",true,false):
		var mi := node as MeshInstance3D
		for surf in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.mesh.surface_get_material(surf)
			if mat is StandardMaterial3D:
				var skin := ShaderMaterial.new()
				var shader := Shader.new()
				shader.code="shader_type spatial; render_mode diffuse_burley, specular_schlick_ggx; uniform sampler2D skin_tex : source_color, filter_linear_mipmap; uniform vec3 tint : source_color = vec3(0.7); void fragment(){ vec4 t=texture(skin_tex,UV); float l=dot(t.rgb,vec3(0.299,0.587,0.114)); vec3 c=mix(t.rgb,vec3(l),0.88)*tint; float n=fract(sin(dot(floor(UV*220.0),vec2(12.9898,78.233)))*43758.5453); c*=mix(0.76,1.08,n); ALBEDO=c; ROUGHNESS=0.88; SPECULAR=0.22; }"
				skin.shader=shader
				skin.set_shader_parameter("skin_tex",mat.albedo_texture)
				skin.set_shader_parameter("tint",data.color)
				mi.set_surface_override_material(surf,skin)
		if "Zombie" in String(mi.name): gore_meshes.append(mi)
	for node in model.find_children("*","AnimationPlayer",true,false): anim = node as AnimationPlayer
	for node in model.find_children("*","Skeleton3D",true,false): skeleton = node as Skeleton3D
	_play("Crawl" if kind == "crawler" else ("Run" if kind in ["runner","stalker"] else "Walk"),0.15)
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 0.65; agent.target_desired_distance = 0.4
	agent.radius = data.radius
	agent.avoidance_enabled = false
	agent.max_speed = data.speed
	add_child(agent)
	repath = randf_range(0.0,0.3)
	vocal_timer = randf_range(2.0,7.0)
	attack_timer = 0.7

func _bounds(root: Node) -> AABB:
	var result := AABB()
	var first := true
	for n in root.find_children("*","MeshInstance3D",true,false):
		var mi := n as MeshInstance3D
		if not mi.mesh: continue
		var box: AABB = (root.global_transform.affine_inverse()*mi.global_transform) * mi.get_aabb()
		if first: result = box; first = false
		else: result = result.merge(box)
	return result

func _play(anim_name: String, blend: float = 0.12) -> void:
	if anim and anim.has_animation(anim_name):
		anim.play(anim_name,blend)

func _physics_process(delta: float) -> void:
	if not game or not game.is_playing(): return
	if dead:
		if ragdoll_active and is_instance_valid(ragdoll):
			var inverse := skeleton.global_transform.affine_inverse()
			for bone in ragdoll_bones:
				skeleton.set_bone_global_pose(bone.get_bone_id(),inverse*bone.global_transform*bone.body_offset.affine_inverse())
		death_timer += delta
		if death_timer > 9.0: queue_free()
		return
	attack_timer -= delta; stagger -= delta; vocal_timer -= delta
	if vocal_timer <= 0.0:
		game.audio.play_at("growl",global_position,0.0,-12.0)
		vocal_timer = randf_range(5.0,10.0)
	var target: Vector3 = game.player.global_position
	var to := target-global_position; to.y=0
	var distance := to.length()
	if attack_windup >= 0.0:
		attack_windup -= delta
		velocity.x = move_toward(velocity.x,0.0,delta*12.0)
		velocity.z = move_toward(velocity.z,0.0,delta*12.0)
		if attack_windup <= 0.0:
			attack_windup = -1.0
			if distance <= float(data.reach)+0.35 and absf(target.y-global_position.y)<2.0:
				var q := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*height*0.6,target+Vector3.UP*1.2,1,[self.get_rid()])
				if get_world_3d().direct_space_state.intersect_ray(q).is_empty(): game.player.take_damage(data.damage,global_position)
			_play("Crawl" if data.id=="crawler" else ("Run" if data.id in ["runner","stalker"] else "Walk"))
	elif distance < float(data.reach) and attack_timer<=0.0 and stagger<=0.0:
		attack_timer = data.cooldown
		attack_windup = 0.32 if data.id=="brute" else 0.22
		_play("Punch",0.07)
	elif stagger <= 0.0:
		repath -= delta
		if repath<=0.0:
			agent.target_position = target
			repath = randf_range(0.35,0.65)
		var direction := Vector3.ZERO
		if distance>0.1:
			var next := agent.get_next_path_position()
			direction = next-global_position; direction.y=0
			direction = direction.normalized()
			# Local separation, without an O(n²) navigation-avoidance simulation.
			for other in get_tree().get_nodes_in_group("enemies"):
				if other==self or other.dead: continue
				var diff: Vector3 = global_position-other.global_position; diff.y=0
				var d := diff.length()
				if d>0.01 and d<0.95: direction += diff/d*(0.95-d)*1.4
			direction = direction.normalized()
		var speed: float = data.speed * (1.0+minf(game.director.wave*0.009,0.35))
		velocity.x = direction.x*speed; velocity.z=direction.z*speed
		if direction.length_squared()>0.01:
			var yaw := atan2(-direction.x,-direction.z)
			rotation.y = lerp_angle(rotation.y,yaw,delta*7.0)
	knockback = knockback.move_toward(Vector3.ZERO,delta*12.0)
	velocity.x += knockback.x; velocity.z += knockback.z
	if not is_on_floor(): velocity.y -= 18.0*delta
	else: velocity.y = -0.5
	move_and_slide()
	if global_position.y < -8.0: queue_free(); game.director.enemy_removed(self)

func take_damage(amount: float, point: Vector3, impulse: Vector3, hit_kind: String = "bullet") -> void:
	if dead: return
	var headshot := point.y-global_position.y > height*0.77
	if headshot: amount *= 1.7
	hp -= amount; last_hit_point=point
	game.fx.impact(point,-impulse.normalized(),"blood")
	game.audio.play_at("flesh",point,0.0,-6.0)
	game.player.hit_confirm(headshot)
	var resistance := 80.0/float(data.mass)
	knockback += impulse.limit_length(20.0)*resistance
	stagger = 0.16 if hit_kind=="melee" else 0.065
	if hp<=0.0:
		die(impulse,headshot)
	elif hit_kind=="melee" or headshot:
		_play("HitReact",0.04)

func die(impulse: Vector3, headshot: bool = false) -> void:
	if dead: return
	dead=true
	collision_layer=0
	collision.set_deferred("disabled",true)
	agent.queue_free(); agent=null
	_play("Death",0.06)
	if anim: anim.speed_scale=0.85
	_begin_ragdoll.call_deferred(impulse)
	if game.settings.gore:
		game.fx.burst(last_hit_point,"blood",28 if headshot else 16)
		game.fx.add_decal(Vector3(global_position.x,0.025,global_position.z),Vector3.UP)
	game.director.enemy_killed(self)

func _begin_ragdoll(impulse: Vector3) -> void:
	if not skeleton or not is_instance_valid(self): return
	if anim: anim.stop(); anim.active=false
	skeleton.modifier_callback_mode_process=Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
	# Twelve articulated bodies, never one per finger. At most six corpses simulate.
	var old: Array = get_tree().get_nodes_in_group("ragdolls")
	old.sort_custom(func(x,y): return x.serial < y.serial)
	while old.size() >= 6:
		var victim: Node = old.pop_front()
		if is_instance_valid(victim): victim.queue_free()
	add_to_group("ragdolls")
	ragdoll = PhysicalBoneSimulator3D.new(); ragdoll.name="ArticulatedRagdoll"
	skeleton.add_child(ragdoll); ragdoll.active=false
	var weights := {"Body":3.0,"Hips":2.0,"Abdomen":2.0,"Torso":3.0,"Head":1.0,"UpperArm.L":0.7,"LowerArm.L":0.6,"UpperArm.R":0.7,"LowerArm.R":0.6,"UpperLeg.L":1.5,"LowerLeg.L":1.0,"UpperLeg.R":1.5,"LowerLeg.R":1.0}
	var total := 0.0
	for key in weights: total += float(weights[key])
	for key in weights:
		var index := skeleton.find_bone(key)
		if index < 0: continue
		var bone := PhysicalBone3D.new(); bone.name=key.replace(".","_")
		bone.bone_name=key
		bone.collision_layer=8; bone.collision_mask=1
		bone.mass=float(data.mass)*float(weights[key])/total
		bone.friction=0.8; bone.bounce=0.03; bone.linear_damp=1.3; bone.angular_damp=2.8
		bone.can_sleep=true
		var pose := skeleton.get_bone_global_pose(index)
		var child := -1
		for c in skeleton.get_bone_children(index):
			var cname := skeleton.get_bone_name(c)
			if cname.begins_with("Lower") or cname in ["Torso","Abdomen","Head","Neck"]:
				child=c; break
		var endpoint := skeleton.get_bone_global_pose(child).origin if child>=0 else pose.origin+pose.basis.y*0.16
		var axis := endpoint-pose.origin
		var length := maxf(axis.length()*float(model.scale.y),0.12)
		var radius := clampf(length*0.23,0.055*float(model.scale.y),0.15*float(model.scale.y))
		if key in ["Body","Torso","Hips"]: radius *= 1.35
		var center := pose.origin.lerp(endpoint,0.45) if child>=0 else pose.origin+pose.basis.y*0.08
		var up := axis.normalized() if child>=0 and axis.length()>0.01 else pose.basis.y.normalized()
		var right := pose.basis.x.normalized()
		if absf(right.dot(up))>0.95: right=pose.basis.z.normalized()
		var forward := right.cross(up).normalized(); right=up.cross(forward).normalized()
		var bone_basis := Basis(right,up,forward)
		var col := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new(); capsule.radius=radius; capsule.height=maxf(length+radius*0.6,radius*2.1)
		col.shape=capsule; bone.add_child(col)
		bone.body_offset=Transform3D(bone_basis,center)
		bone.transform=bone.body_offset
		bone.joint_type=PhysicalBone3D.JOINT_TYPE_CONE if key!="Body" else PhysicalBone3D.JOINT_TYPE_NONE
		bone.set("joint_constraints/swing_span",35.0 if "Leg" in key else 55.0)
		bone.set("joint_constraints/twist_span",25.0)
		bone.set("joint_constraints/bias",0.65)
		ragdoll.add_child(bone); ragdoll_bones.append(bone)
	if ragdoll_bones.is_empty(): ragdoll.queue_free(); ragdoll=null; return
	ragdoll.active=true
	ragdoll.physical_bones_start_simulation()
	for bone in ragdoll_bones:
		ragdoll.physical_bones_add_collision_exception(bone.get_rid())
	ragdoll_active=true
	var push := impulse.limit_length(18.0)
	for bone in ragdoll_bones:
		bone.apply_central_impulse(push*bone.mass/float(data.mass)*1.8)
		if bone.bone_name in ["Torso","Head"]:
			bone.apply_impulse(push*0.12,Vector3(0,0.08,0.04))

func _exit_tree() -> void:
	if ragdoll_active and is_instance_valid(ragdoll): ragdoll.physical_bones_stop_simulation()
	if game and is_instance_valid(game.director): game.director.enemy_removed(self)

