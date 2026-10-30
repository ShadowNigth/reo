extends Node3D
var game: Node
var debris: Array[RigidBody3D] = []
var decals: Array[Node3D] = []
var emitters: Array[CPUParticles3D] = []
var emitter_cursor := 0
var decal_cursor := 0
var tracer_pool: Array[MeshInstance3D] = []
var tracer_cursor := 0
var blood_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var glass_material: StandardMaterial3D

func setup(g: Node) -> void:
	game = g
	blood_material = game.assets.material(Color(0.25,0.009,0.006),0.0,0.1)
	stone_material = game.assets.material(Color(0.36,0.38,0.34))
	glass_material = game.assets.material(Color(0.38,0.68,0.7,0.55),0.0,0.4)
	for i in range(18):
		var p := CPUParticles3D.new()
		p.emitting = false; p.one_shot = true; p.amount = 20; p.lifetime = 0.65
		p.explosiveness = 0.95; p.local_coords = false
		p.direction = Vector3.UP; p.spread = 85.0
		p.gravity = Vector3(0,-12,0); p.initial_velocity_min = 1.0; p.initial_velocity_max = 4.0
		p.scale_amount_min = 0.035; p.scale_amount_max = 0.11
		var q := QuadMesh.new(); q.size = Vector2.ONE; p.mesh = q
		var mat := StandardMaterial3D.new()
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_texture = game.assets.texture("res://assets/fx/circle_05.png")
		p.material_override = mat
		add_child(p); emitters.append(p)
	for i in range(20):
		var t := MeshInstance3D.new(); var m := BoxMesh.new(); m.size = Vector3.ONE
		t.mesh = m; t.material_override = game.assets.material(Color(1.0,0.68,0.28),3.0)
		t.visible = false; t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(t); tracer_pool.append(t)

func _process(delta: float) -> void:
	for t in tracer_pool:
		if t.visible:
			t.set_meta("life",float(t.get_meta("life",0.0))-delta)
			if float(t.get_meta("life"))<=0: t.visible=false

func burst(pos: Vector3, kind: String, amount: int = 14) -> void:
	var p := emitters[emitter_cursor]; emitter_cursor=(emitter_cursor+1)%emitters.size()
	p.emitting=false; p.global_position=pos
	p.amount = clampi(amount,1,48)
	var mat := p.material_override as StandardMaterial3D
	mat.albedo_texture = game.assets.texture("res://assets/fx/%s" % ("smoke_01.png" if kind == "smoke" else ("star_08.png" if kind=="spark" else "circle_05.png")))
	p.color = Color(0.38,0.012,0.008) if kind=="blood" else (Color(1.0,0.57,0.17) if kind=="spark" else Color(0.48,0.51,0.46,0.7))
	p.scale_amount_min = 0.06 if kind=="smoke" else 0.025
	p.scale_amount_max = 0.28 if kind=="smoke" else 0.09
	p.gravity = Vector3(0,1.0,0) if kind=="smoke" else Vector3(0,-12,0)
	p.lifetime = 1.5 if kind=="smoke" else 0.65
	p.initial_velocity_max = 2.0 if kind=="smoke" else 4.5
	p.emitting = true

func impact(pos: Vector3, normal: Vector3, kind: String) -> void:
	burst(pos, "spark" if kind=="metal" else kind, 7)
	game.audio.play_at(kind,pos,0.0,-10.0)
	if game.settings.gore and kind == "blood": add_decal(pos,normal)

func add_decal(pos: Vector3, normal: Vector3) -> void:
	if not game.settings.gore: return
	var d: MeshInstance3D
	if decals.size()<48:
		d=MeshInstance3D.new(); var q:=QuadMesh.new(); q.size=Vector2.ONE; d.mesh=q
		var mat:=StandardMaterial3D.new(); mat.albedo_texture=game.assets.texture("res://assets/fx/scorch_01.png")
		mat.albedo_color=Color(0.23,0.006,0.004,0.85)
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.render_priority=-1
		d.material_override=mat; d.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(d); decals.append(d)
	else:
		d=decals[decal_cursor]; decal_cursor=(decal_cursor+1)%decals.size()
	d.visible=true; d.global_position=pos+normal*0.018
	var n:=normal.normalized()
	if n.length_squared()<0.1: n=Vector3.UP
	d.look_at(d.global_position+n,Vector3.FORWARD if absf(n.dot(Vector3.UP))>0.95 else Vector3.UP)
	d.rotate_object_local(Vector3.FORWARD,randf()*TAU)
	d.scale=Vector3.ONE*randf_range(0.4,0.95)

func fragments(pos: Vector3, dimensions: Vector3, impulse: Vector3, kind: String, count: int) -> void:
	for i in range(count):
		var body:=RigidBody3D.new(); body.collision_layer=8; body.collision_mask=1
		body.mass=0.6 if kind=="glass" else 2.5
		body.linear_damp=0.4; body.angular_damp=0.7
		var mi:=MeshInstance3D.new(); var bm:=BoxMesh.new()
		bm.size=Vector3(randf_range(0.1,0.35),randf_range(0.08,0.25),0.035 if kind=="glass" else randf_range(0.1,0.3))
		mi.mesh=bm; mi.material_override=glass_material if kind=="glass" else stone_material
		body.add_child(mi)
		var col:=CollisionShape3D.new(); var bs:=BoxShape3D.new(); bs.size=bm.size; col.shape=bs; body.add_child(col)
		add_child(body); body.global_position=pos+Vector3(randf_range(-0.4,0.4),randf_range(-0.2,0.5),randf_range(-0.4,0.4)).clamp(-dimensions*0.4,dimensions*0.4)
		body.apply_central_impulse(impulse.limit_length(15.0)*0.35+Vector3(randf_range(-3,3),randf_range(2,6),randf_range(-3,3)))
		body.angular_velocity=Vector3(randf_range(-5,5),randf_range(-5,5),randf_range(-5,5))
		debris.append(body)
		var timer:=get_tree().create_timer(7.0+randf())
		timer.timeout.connect(_expire_body.bind(body))
	while debris.size()>72:
		var old:RigidBody3D=debris.pop_front()
		if is_instance_valid(old): old.queue_free()

func _expire_body(body: Node) -> void:
	if is_instance_valid(body): body.queue_free()

func tracer(from: Vector3,to: Vector3,color: Color = Color(1.0,0.68,0.28)) -> void:
	var t:=tracer_pool[tracer_cursor]; tracer_cursor=(tracer_cursor+1)%tracer_pool.size()
	var mat := t.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color=color
		mat.emission=color
	var length:=from.distance_to(to)
	if length<0.01: return
	t.visible=true; t.global_position=(from+to)*0.5
	t.look_at(to,Vector3.UP if absf((to-from).normalized().dot(Vector3.UP))<0.98 else Vector3.RIGHT)
	t.scale=Vector3(0.014,0.014,length)
	t.set_meta("life",0.045)

func explosion(pos: Vector3) -> void:
	burst(pos,"spark",40); burst(pos+Vector3.UP*0.3,"smoke",24)
	game.audio.play_at("explosion",pos,0.0,-1.0)
	var light:=OmniLight3D.new(); light.light_color=Color(1.0,0.36,0.08); light.light_energy=8.0; light.omni_range=9.0
	add_child(light); light.global_position=pos
	var tw:=create_tween(); tw.tween_property(light,"light_energy",0.0,0.28); tw.tween_callback(light.queue_free)
