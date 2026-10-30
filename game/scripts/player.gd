extends CharacterBody3D
var game: Node
var camera: Camera3D
var pivot: Node3D
var weapon_root: Node3D
var weapon_visual: Node3D
var flashlight: SpotLight3D
var muzzle_light: OmniLight3D
var hp := 100.0
var stamina := 100.0
var grenades := 2
var slots := [{"id":"bat","mag":0,"reserve":0},{"id":"pistol","mag":8,"reserve":16},{"id":"","mag":0,"reserve":0}]
var slot := 0
var previous_slot := 1
var cooldown := 0.0
var reload_left := 0.0
var reload_total := 0.0
var swing_left := 0.0
var swing_hit := false
var swing_targets := {}
var recoil := 0.0
var shake := 0.0
var hurt_flash := 0.0
var hit_flash := 0.0
var bob := 0.0
var step_timer := 0.0
var invulnerable := 0.0
var aiming := false
var mouse_delta := Vector2.ZERO
var sensitivity := 0.0022
var melee_serial := 0
var last_damage_time := 0.0
var weapon_cache := {}
var magazine_texture: Texture2D

func setup(g: Node) -> void:
	game=g
	collision_layer=4; collision_mask=1
	floor_snap_length=0.35
	var col:=CollisionShape3D.new(); var shape:=CapsuleShape3D.new(); shape.radius=0.32; shape.height=1.75
	col.shape=shape; col.position.y=0.88; add_child(col)
	pivot=Node3D.new(); pivot.position.y=1.62; add_child(pivot)
	camera=Camera3D.new(); camera.fov=82.0; camera.near=0.045; camera.far=110.0
	pivot.add_child(camera); camera.make_current()
	weapon_root=Node3D.new(); camera.add_child(weapon_root)
	weapon_root.position=Vector3(0.28,-0.28,-0.48)
	flashlight=SpotLight3D.new(); flashlight.position=Vector3(0.12,-0.1,-0.15)
	flashlight.light_color=Color(0.88,0.92,0.80); flashlight.light_energy=3.4
	flashlight.spot_range=25.0; flashlight.spot_angle=31.0; flashlight.spot_angle_attenuation=1.4
	flashlight.shadow_enabled=true; camera.add_child(flashlight)
	muzzle_light=OmniLight3D.new(); muzzle_light.light_color=Color(1.0,0.57,0.2); muzzle_light.light_energy=0.0; muzzle_light.omni_range=5.0
	camera.add_child(muzzle_light); muzzle_light.position=Vector3(0.2,-0.15,-1.1)

func current() -> Dictionary:
	return slots[slot]
func weapon() -> Dictionary:
	return game.catalog.weapon(current().id)
func empty() -> bool:
	return String(current().id).is_empty()

func equip(index: int, force: bool = false) -> void:
	if index<0 or index>2 or String(slots[index].id).is_empty(): return
	if index==slot and not force: return
	if not force and (reload_left>0.0 or swing_left>0.0): return
	previous_slot=slot; slot=index; reload_left=0.0; swing_left=0.0; cooldown=0.22
	if weapon_visual: weapon_visual.queue_free(); weapon_visual=null
	if empty(): return
	var w:=weapon()
	weapon_visual=game.assets.instance(game.catalog.model_path(w.id))
	weapon_root.add_child(weapon_visual)
	_normalize_weapon(weapon_visual,w)
	game.audio.play_ui("switch",-15.0)
	if is_instance_valid(game.hud): game.hud.refresh_inventory()

func _normalize_weapon(root: Node3D,w: Dictionary) -> void:
	var box:=AABB(); var first:=true
	for n in root.find_children("*","MeshInstance3D",true,false):
		var mi:=n as MeshInstance3D
		if not mi.mesh: continue
		var b:=(root.global_transform.affine_inverse()*mi.global_transform)*mi.get_aabb()
		if first: box=b; first=false
		else: box=box.merge(b)
		for s in range(mi.mesh.get_surface_count()):
			var orig:=mi.mesh.surface_get_material(s)
			var m: StandardMaterial3D = orig.duplicate() if orig is StandardMaterial3D else game.assets.material(Color(0.21,0.24,0.23),0.0,0.65)
			m.metallic=0.6; m.roughness=0.43
			mi.set_surface_override_material(s,m)
		mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var target:=0.9 if w.kind=="melee" else (0.65 if w.kind=="pistol" else 0.95)
	var s:=target/maxf(box.size.z,box.size.y)
	root.scale=Vector3.ONE*s
	root.position=-box.get_center()*s
	if w.kind=="melee":
		root.rotation=Vector3(-0.35,0.0,-0.32)
		root.position+=Vector3(0.05,-0.16,0.0)
	else:
		# Downloaded weapons have different authoring axes. Orient the long axis forward.
		if box.size.x>box.size.z*1.4: root.rotation.y=PI/2
		root.position+=Vector3(0.0,0.0,-0.1)

func _unhandled_input(event: InputEvent) -> void:
	if not game or not game.is_playing(): return
	if event is InputEventMouseMotion:
		var motion:=event as InputEventMouseMotion
		var drag_fallback:=OS.has_feature("web") and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
		if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED or drag_fallback:
			rotation.y-=motion.relative.x*sensitivity
			pivot.rotation.x=clampf(pivot.rotation.x-motion.relative.y*sensitivity,-1.42,1.42)
	if event is InputEventMouseButton:
		var mb:=event as InputEventMouseButton
		if mb.pressed and mb.button_index==MOUSE_BUTTON_WHEEL_UP: equip((slot+2)%3)
		if mb.pressed and mb.button_index==MOUSE_BUTTON_WHEEL_DOWN: equip((slot+1)%3)
	if event.is_action_pressed("slot1"): equip(0)
	if event.is_action_pressed("slot2"): equip(1)
	if event.is_action_pressed("slot3"): equip(2)
	if event.is_action_pressed("quick_switch"): equip(previous_slot)
	if event.is_action_pressed("reload"): reload()
	if event.is_action_pressed("interact"): game.interact()
	if event.is_action_pressed("flashlight"): flashlight.visible=not flashlight.visible
	if event.is_action_pressed("grenade"): throw_grenade()

func _physics_process(delta: float) -> void:
	if not game or not game.is_playing(): return
	cooldown=maxf(0.0,cooldown-delta)
	invulnerable=maxf(0.0,invulnerable-delta)
	var input:=Input.get_vector("left","right","forward","back")
	var sprint:=Input.is_action_pressed("sprint") and stamina>1.0 and input.y<0.0 and not aiming
	var speed:=6.4 if sprint else (2.3 if aiming else 4.2)
	if reload_left>0.0: speed*=0.75
	if swing_left>0.0: speed*=0.72
	if sprint: stamina=maxf(0.0,stamina-delta*21.0)
	else: stamina=minf(100.0,stamina+delta*15.0)
	var dir:=(transform.basis*Vector3(input.x,0,input.y)).normalized()
	velocity.x=move_toward(velocity.x,dir.x*speed,delta*24.0)
	velocity.z=move_toward(velocity.z,dir.z*speed,delta*24.0)
	if not is_on_floor(): velocity.y-=18.0*delta
	elif Input.is_action_just_pressed("jump"): velocity.y=6.3
	else: velocity.y=-0.5
	move_and_slide()
	if global_position.y < -6.0: global_position=Vector3(-9,0.3,5)
	aiming=Input.is_action_pressed("aim") and weapon().kind!="melee" and reload_left<=0.0
	camera.fov=lerp(camera.fov,57.0 if aiming else (87.0 if sprint else 82.0),delta*11.0)
	var move_amount:=Vector2(velocity.x,velocity.z).length()
	bob+=delta*move_amount*1.8
	if move_amount>0.8 and is_on_floor():
		step_timer-=delta
		if step_timer<=0.0: game.audio.play_at("step",global_position,0.0,-19.0); step_timer=0.32 if sprint else 0.47
	if Input.is_action_pressed("fire") and cooldown<=0.0 and reload_left<=0.0: fire()
	if reload_left>0.0:
		reload_left-=delta
		if reload_left<=0.0: finish_reload()
	if swing_left>0.0:
		swing_left-=delta
		var duration:=float(weapon().rate)
		var progress:=1.0-swing_left/duration
		if progress>0.25 and progress<0.70 and not swing_hit: melee_sweep()
		if swing_left<=0.0: swing_hit=false
	_update_viewmodel(delta,move_amount)

func _update_viewmodel(delta: float, movement: float) -> void:
	recoil=move_toward(recoil,0.0,delta*0.8)
	shake=move_toward(shake,0.0,delta*1.9)
	hurt_flash=move_toward(hurt_flash,0.0,delta*1.5)
	hit_flash=move_toward(hit_flash,0.0,delta*4.0)
	muzzle_light.light_energy=move_toward(muzzle_light.light_energy,0.0,delta*90.0)
	var target:=Vector3(0.28,-0.28,-0.48)
	if aiming: target=Vector3(0.0,-0.19,-0.42)
	target.y+=sin(bob)*0.012*minf(movement,1.0)
	target.x+=cos(bob*0.5)*0.008*minf(movement,1.0)
	target.z+=recoil
	if reload_left>0.0:
		var f:=sin((1.0-reload_left/reload_total)*PI)
		target.y-=f*0.28; target.x+=f*0.08
	if swing_left>0.0:
		var f:=sin((1.0-swing_left/float(weapon().rate))*PI)
		target.x-=f*0.52; target.z-=f*0.27; target.y+=f*0.13
		weapon_root.rotation=Vector3(-f*0.5,-f*0.7,f*0.85)
	else: weapon_root.rotation=weapon_root.rotation.lerp(Vector3(recoil*1.5,0,0),delta*13.0)
	if game.settings.shake:
		pivot.position=Vector3(0,1.62,0)
		pivot.position.y=1.62+randf_range(-shake,shake)*0.14
		pivot.position.x=randf_range(-shake,shake)*0.12
	else: pivot.position=Vector3(0,1.62,0)
	weapon_root.position=weapon_root.position.lerp(target,delta*18.0)

func fire() -> void:
	if empty(): return
	var w:=weapon()
	if w.kind=="melee":
		if stamina<12.0: return
		stamina-=12.0; cooldown=w.rate; swing_left=w.rate; swing_hit=false; swing_targets.clear(); melee_serial+=1
		game.audio.play_at("swing",global_position,0.0,-8.0)
		return
	if int(current().mag)<=0:
		cooldown=0.35; game.audio.play_ui("empty",-12.0)
		if int(current().reserve)>0: reload()
		else: game.hud.toast("Sin munición. Usá el melee [1] o buscá suministros.")
		return
	current().mag=int(current().mag)-1
	cooldown=w.rate; recoil+=w.kick; shake=maxf(shake,w.kick*2.0)
	if game.settings.shake: pivot.rotation.x=clampf(pivot.rotation.x+w.kick*0.11,-1.42,1.42)
	game.audio.play_at(w.kind,camera.global_position,0.0,-5.0)
	muzzle_light.light_energy=2.8 if w.kind!="sniper" else 4.0
	game.stats.shots+=1
	if w.kind=="launcher":
		game.spawn_projectile(camera.global_position-camera.global_basis.z*0.5,-camera.global_basis.z,w.damage,false)
		return
	var pellets:=int(w.pellets)
	for i in range(maxi(1,pellets)):
		var spread:float=w.spread*(0.3 if aiming else 1.0)
		var direction:=-camera.global_basis.z+camera.global_basis.x*randf_range(-spread,spread)+camera.global_basis.y*randf_range(-spread,spread)
		direction=direction.normalized()
		var from:=camera.global_position
		var to: Vector3 = from+direction*w.range
		var query:=PhysicsRayQueryParameters3D.create(from,to,1|2,[self.get_rid()])
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			to=hit.position
			var collider: Object = hit.collider
			if collider.has_method("take_damage"):
				var damage:float=w.damage
				if w.kind=="shotgun": damage*=clampf(1.0-from.distance_to(to)/float(w.range),0.25,1.0)
				collider.take_damage(damage,to,direction*(18.0 if w.kind=="shotgun" else 13.0),w.kind)
				game.stats.hits+=1
			elif collider is RigidBody3D:
				collider.apply_impulse(direction*18.0,to-collider.global_position)
			if not collider.is_in_group("enemies"): game.fx.impact(to,hit.normal,"metal" if collider.is_in_group("metal") else "stone")
		if i==0 or pellets<4: game.fx.tracer(camera.global_position+Vector3(0,-0.12,0)+-camera.global_basis.z*0.6,to,Color(0.4,0.85,1.0) if w.kind=="energy" else Color(1.0,0.7,0.35))
		if w.kind=="flame": game.fx.burst(to,"smoke",4); game.fx.burst(to.lerp(from,0.5),"spark",3)

func melee_sweep() -> void:
	var w:=weapon(); var hit_any:=false
	# Nine overlapping sphere sweeps across the active blade arc; each target hit once.
	for step in range(9):
		var angle:=lerpf(-0.62,0.62,float(step)/8.0)
		var direction:=-camera.global_basis.z.rotated(Vector3.UP,angle)
		var from:=camera.global_position-camera.global_basis.y*0.12
		var to: Vector3 = from+direction*w.range
		var wall:=PhysicsRayQueryParameters3D.create(from,to,1,[self.get_rid()])
		var obstruction:=get_world_3d().direct_space_state.intersect_ray(wall)
		if not obstruction.is_empty(): to=obstruction.position
		var q:=PhysicsShapeQueryParameters3D.new(); var shape:=SphereShape3D.new(); shape.radius=0.27 if w.id=="bat" else 0.19
		q.shape=shape; q.motion=to-from; q.transform=Transform3D(Basis.IDENTITY,from); q.collision_mask=1|2|8; q.exclude=[self.get_rid()]
		var hits:=get_world_3d().direct_space_state.cast_motion(q)
		var end:=from.lerp(to,clampf(hits[0] if not hits.is_empty() else 1.0,0.0,1.0))
		q.motion=Vector3.ZERO; q.transform=Transform3D(Basis.IDENTITY,end)
		for result in get_world_3d().direct_space_state.intersect_shape(q,8):
			var obj: Object = result.collider
			if swing_targets.has(obj.get_instance_id()): continue
			if obj.has_method("take_damage"):
				swing_targets[obj.get_instance_id()]=true
				obj.take_damage(w.damage,end,direction*float(w.mass)*6.0+Vector3.UP*2.0,"melee")
				hit_any=true
			elif obj is RigidBody3D:
				obj.apply_impulse(direction*float(w.mass)*5.0,end-obj.global_position)
				hit_any=true
	if hit_any and not swing_hit:
		swing_hit=true; shake=0.17; recoil=0.07
		game.hitstop=0.045 if w.id=="bat" else 0.025
		game.audio.play_at("flesh",camera.global_position,0.8,-3.0)

func reload() -> void:
	var w: Dictionary = weapon()
	if reload_left>0.0 or w.kind=="melee" or int(current().mag)>=int(w.mag) or int(current().reserve)<=0: return
	reload_total=w.reload; reload_left=w.reload
	game.audio.play_ui("reload",-8.0)

func finish_reload() -> void:
	var amount:=mini(int(weapon().mag)-int(current().mag),int(current().reserve))
	current().mag=int(current().mag)+amount; current().reserve=int(current().reserve)-amount
	game.audio.play_ui("switch",-16.0)

func take_damage(amount: float, source: Vector3) -> void:
	if invulnerable>0.0 or not game.is_playing(): return
	hp=maxf(0.0,hp-amount); invulnerable=0.32; hurt_flash=0.7; shake=0.28
	last_damage_time=game.stats.time
	game.audio.play_ui("hurt",-4.0)
	var dir:=(global_position-source).normalized()
	velocity+=dir*2.0
	if hp<=0.0: game.game_over()

func hit_confirm(headshot: bool) -> void:
	hit_flash=0.22; game.hud.headshot=headshot

func add_ammo() -> void:
	var target:=slot
	if weapon().kind=="melee":
		target=1 if not String(slots[1].id).is_empty() else 2
	if target==0 or String(slots[target].id).is_empty(): target=1
	if String(slots[target].id).is_empty(): return
	var w: Dictionary = game.catalog.weapon(slots[target].id)
	var amount:=maxi(int(w.mag),int(int(w.reserve)*0.22))
	slots[target].reserve=mini(int(slots[target].reserve)+amount,int(w.reserve)*2)
	game.hud.toast("+%d municiones · %s" % [amount,w.name])
	game.audio.play_ui("pickup")

func offer_weapon(id: String) -> void:
	game.hud.show_loot(id)

func replace_slot(index: int,id: String) -> bool:
	if not game.catalog.compatible(index,id): return false
	var w: Dictionary = game.catalog.weapon(id)
	slots[index]={"id":id,"mag":int(w.mag),"reserve":int(w.reserve)}
	reload_left=0.0; swing_left=0.0
	equip(index,true)
	if is_instance_valid(game.hud): game.hud.refresh_inventory()
	return true

func throw_grenade() -> void:
	if grenades<=0 or cooldown>0.0: return
	grenades-=1; cooldown=0.6
	game.spawn_projectile(camera.global_position-camera.global_basis.z*0.6,-camera.global_basis.z*11.0+Vector3.UP*3.5,165.0,true)
	game.audio.play_ui("switch")
