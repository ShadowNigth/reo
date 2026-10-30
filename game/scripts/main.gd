extends Node
const Catalog = preload("res://scripts/catalog.gd")
var catalog = Catalog
var assets: Node
var world: Node3D
var actors: Node3D
var player: CharacterBody3D
var director: Node
var fx: Node3D
var audio: Node
var hud: CanvasLayer
var state := "loading"
var settings := {"gore":true,"shake":true,"quality":"low" if OS.has_feature("web") else "medium","sensitivity":1.0,"volume":0.8}
var stats := {"kills":0,"shots":0,"hits":0,"time":0.0,"score":0,"waves_cleared":0,"spawned":0}
var record := {"wave":0,"kills":0}
var hitstop := 0.0
var nav_dirty := false
var nav_delay := 0.0
var debug_mode := false
var browser_callback: JavaScriptObject

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	randomize(); _load_data(); _bind_inputs()
	assets=preload("res://scripts/assets.gd").new(); assets.name="Assets"; add_child(assets)
	audio=preload("res://scripts/audio.gd").new(); audio.name="Audio"; add_child(audio); audio.setup(self)
	fx=preload("res://scripts/fx.gd").new(); fx.name="Effects"; add_child(fx); fx.setup(self)
	world=preload("res://scripts/world.gd").new(); world.name="Hangar"; add_child(world); world.build(self)
	actors=Node3D.new(); actors.name="Actors"; add_child(actors)
	player=preload("res://scripts/player.gd").new(); player.name="Player"; actors.add_child(player)
	player.global_position=Vector3(-9,0.2,5.5); player.setup(self)
	player.rotation.y=0.15
	director=preload("res://scripts/director.gd").new(); director.name="Director"; add_child(director); director.setup(self)
	hud=preload("res://scripts/hud.gd").new(); hud.name="HUD"; add_child(hud); hud.setup(self)
	apply_settings()
	state="menu"; hud.show_menu()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	debug_mode="--smoke-test" in OS.get_cmdline_user_args()
	if debug_mode: call_deferred("_smoke_test")
	if OS.has_feature("web") and "--browser-test" in OS.get_cmdline_user_args():
		JavaScriptBridge.eval("window.umbralTest = null;")
		browser_callback = JavaScriptBridge.create_callback(_browser_test)
		JavaScriptBridge.get_interface("window").umbralTest = browser_callback
		print("BROWSER_TEST_READY")

func _browser_test(args: Array) -> String:
	var command := str(args[0]) if not args.is_empty() else "state"
	match command:
		"start": start_run()
		"state": return _browser_reply(JSON.stringify({"state":state,"hp":player.hp,"wave":director.wave,"alive":director.alive,"kills":stats.kills,"shots":stats.shots,"hits":stats.hits,"slot":player.slot,"slots":player.slots,"pos":_v(player.global_position),"yaw":player.rotation.y,"pitch":player.pivot.rotation.x,"nodes":get_tree().get_node_count(),"fps":Engine.get_frames_per_second(),"ragdolls":get_tree().get_nodes_in_group("ragdolls").size()}))
		"equip": player.equip(int(args[1]))
		"give": player.replace_slot(int(args[1]),str(args[2]))
		"look": player.rotation.y=float(args[1]); player.pivot.rotation.x=float(args[2])
		"teleport": player.global_position=Vector3(float(args[1]),float(args[2]),float(args[3])); player.velocity=Vector3.ZERO
		"spawn":
			var e:Node=director.spawn_enemy(str(args[1]),Vector3(float(args[2]),float(args[3]),float(args[4])))
			return _browser_reply(JSON.stringify({"id":e.get_instance_id(),"hp":e.hp}))
		"kill_first":
			for e in get_tree().get_nodes_in_group("enemies"):
				if not e.dead: e.take_damage(99999,e.global_position+Vector3.UP,e.global_basis.z*20,"melee"); break
		"crate": director.spawn_crate()
		"interact": interact()
		"choose": hud._choose(int(args[1]))
		"ammo": director.spawn_ammo(player.global_position+Vector3(0,0,-0.5))
		"fire": player.fire()
		"reload": player.reload()
		"damage": player.invulnerable=0; player.take_damage(float(args[1]),player.global_position+Vector3.FORWARD)
		"pause": pause_game()
		"safe": player.invulnerable=9999.0; director.intermission=9999.0
		"nav":
			var path:=NavigationServer3D.map_get_path(world.nav.get_navigation_map(),player.global_position,Vector3(-24,0,-13),true)
			return _browser_reply(JSON.stringify({"points":path.size(),"last":_v(path[-1]) if not path.is_empty() else ""}))
	return _browser_reply("ok")

func _browser_reply(value: String) -> String:
	JavaScriptBridge.eval("window.umbralResult = " + JSON.stringify(value))
	return value

func _v(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func _bind_inputs() -> void:
	var keys={"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"reload":KEY_R,"interact":KEY_E,"flashlight":KEY_F,"grenade":KEY_G,"slot1":KEY_1,"slot2":KEY_2,"slot3":KEY_3,"quick_switch":KEY_Q,"pause":KEY_ESCAPE}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var e:=InputEventKey.new(); e.physical_keycode=keys[action]; InputMap.action_add_event(action,e)
	for action in ["fire","aim"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var e:=InputEventMouseButton.new(); e.button_index=MOUSE_BUTTON_LEFT if action=="fire" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action,e)

func _process(delta: float) -> void:
	if state=="playing":
		stats.time+=delta
		if hitstop>0.0:
			hitstop-=delta/maxf(Engine.time_scale,0.001)
			Engine.time_scale=0.12
		else: Engine.time_scale=1.0
		if nav_dirty:
			nav_delay-=delta
			if nav_delay<=0.0: _rebake_navigation()
	if state=="menu" and player:
		player.camera.fov=76.0
		player.pivot.rotation.x=-0.035
		player.rotation.y=0.30+sin(Time.get_ticks_msec()*0.0001)*0.10
	Engine.time_scale=1.0 if state!="playing" else Engine.time_scale

func is_playing() -> bool:
	return state=="playing"

func start_run() -> void:
	state="playing"; stats={"kills":0,"shots":0,"hits":0,"time":0.0,"score":0,"waves_cleared":0,"spawned":0}
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	hud.show_gameplay(); hud.banner("PROTOCOLO CERO","Sobreviví. Busá suministros. No dejes que te rodeen.",5.0)

func pause_game() -> void:
	if state=="playing":
		state="paused"; Input.mouse_mode=Input.MOUSE_MODE_VISIBLE; hud.show_pause()
	elif state=="paused":
		state="playing"; Input.mouse_mode=Input.MOUSE_MODE_CAPTURED; hud.hide_panels()

func open_loot() -> void:
	state="loot"; Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func close_loot() -> void:
	state="playing"; hud.hide_panels()
	if OS.has_feature("web"):
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE; hud.toast("Hacé clic en el juego para volver a capturar el ratón.")
	else: Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func game_over() -> void:
	state="dead"; Engine.time_scale=1.0; Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	save_record(); hud.show_death()

func restart() -> void:
	Engine.time_scale=1.0
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func to_menu() -> void:
	restart()

func interact() -> void:
	var obj: Node3D = director.nearest_interactable()
	if obj: obj.interact()

func spawn_projectile(pos: Vector3,velocity: Vector3,damage: float,grenade: bool) -> void:
	var p:=preload("res://scripts/projectile.gd").new()
	actors.add_child(p); p.global_position=pos; p.setup(self,velocity,damage,grenade)

func explode(pos: Vector3,radius: float,damage: float) -> void:
	var q:=PhysicsShapeQueryParameters3D.new(); var sphere:=SphereShape3D.new(); sphere.radius=radius
	q.shape=sphere; q.transform=Transform3D(Basis.IDENTITY,pos); q.collision_mask=1|2|4|8; q.exclude=[player.get_rid()]
	var hits:=get_tree().root.get_world_3d().direct_space_state.intersect_shape(q,96)
	var seen: Array[int] = []
	for hit in hits:
		var obj: Object = hit.collider
		if obj.get_instance_id() in seen: continue
		seen.append(obj.get_instance_id())
		var target_pos: Vector3=obj.global_position if obj is Node3D else pos
		var distance:=pos.distance_to(target_pos)
		var strength:=clampf(1.0-distance/radius,0.08,1.0)
		var direction:=(target_pos-pos).normalized()
		var ray:=PhysicsRayQueryParameters3D.create(pos,target_pos+Vector3.UP*0.6,1)
		var blocked:=get_tree().root.get_world_3d().direct_space_state.intersect_ray(ray)
		if not blocked.is_empty() and blocked.collider!=obj: strength*=0.2
		if obj.has_method("take_damage"): obj.take_damage(damage*strength,target_pos+Vector3.UP*0.5,direction*45.0*strength,"explosion")
		elif obj is RigidBody3D: obj.apply_central_impulse(direction*45.0*strength)
	if player.global_position.distance_to(pos)<radius: player.take_damage(damage*0.22*(1.0-player.global_position.distance_to(pos)/radius),pos)
	player.shake=maxf(player.shake,clampf(1.0-player.global_position.distance_to(pos)/22.0,0.0,0.6))

func world_changed() -> void:
	nav_dirty=true; nav_delay=1.2

func _rebake_navigation() -> void:
	nav_dirty=false
	var nm:NavigationMesh=world.nav.navigation_mesh
	var source:=NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm,source,world)
	NavigationServer3D.bake_from_source_geometry_data(nm,source)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and state=="playing" and not debug_mode: pause_game()
	if what==NOTIFICATION_WM_CLOSE_REQUEST: save_record()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state in ["playing","paused"]: pause_game()
		elif state=="loot": hud.cancel_loot()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and state=="playing" and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func apply_settings() -> void:
	var low:bool=settings.quality=="low"
	get_viewport().scaling_3d_scale=0.65 if low else 1.0
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.001,float(settings.volume))))
	if player: player.sensitivity=0.0022*float(settings.sensitivity)
	if world:
		for i in range(world.lights.size()): world.lights[i].visible=not low or i<2
		for n in world.get_children():
			if n is DirectionalLight3D: n.shadow_enabled=not low
	if player: player.flashlight.shadow_enabled=not low
	if fx:
		for em in fx.emitters: em.amount=mini(em.amount,12 if settings.quality=="low" else 48)
	_save_data()

func _load_data() -> void:
	var cfg:=ConfigFile.new()
	if cfg.load("user://umbral.cfg")==OK:
		for k in settings: settings[k]=cfg.get_value("settings",k,settings[k])
		record.wave=cfg.get_value("record","wave",0); record.kills=cfg.get_value("record","kills",0)

func _save_data() -> void:
	var cfg:=ConfigFile.new()
	for k in settings: cfg.set_value("settings",k,settings[k])
	cfg.set_value("record","wave",int(record.wave)); cfg.set_value("record","kills",int(record.kills))
	cfg.save("user://umbral.cfg")

func save_record() -> void:
	record.wave=maxi(int(record.wave),int(stats.waves_cleared)); record.kills=maxi(int(record.kills),int(stats.kills)); _save_data()

func _smoke_test() -> void:
	start_run()
	var test:=preload("res://tests/smoke.gd").new()
	add_child(test); test.run(self)
