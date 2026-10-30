extends Node3D
var game: Node
var a: Node
var meshes: Dictionary = {}
var nav: NavigationRegion3D
var crate_anchor := Vector3(-8.0, 0.0, 5.5)
var spawn_points: Array[Vector3] = []
var bounds := Rect2(-29, -18, 37, 27)
var breakable_script = preload("res://scripts/breakable.gd")
var lights: Array[Light3D] = []

func build(owner_game: Node) -> void:
	game = owner_game
	a = game.assets
	_setup_environment()
	var hangar: Node3D = a.instance("res://assets/world/SpaceCraftHangar.glb")
	add_child(hangar)
	_apply_materials(hangar)
	_make_static(hangar)
	meshes = a.mesh_library("res://assets/world/Objects.glb")
	_place_original_props()
	_make_gameplay_partitions()
	_make_lights()
	_make_navmesh()
	for p in [Vector3(-26,0,6),Vector3(-20,0,-15),Vector3(-8,0,-16),Vector3(5,0,-15),Vector3(6,0,5),Vector3(-3,0,7),Vector3(-26,0,-7),Vector3(-15,0,7),Vector3(5,0,-3),Vector3(-18,0,-5),Vector3(-5,0,-10),Vector3(-24,0,-13)]:
		spawn_points.append(p)

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.039, 0.043)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.52, 0.53)
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.15, 0.15)
	env.fog_density = 0.013
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.13
	env.adjustment_saturation = 0.76
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, -28, 0)
	moon.light_color = Color(0.54, 0.69, 0.74)
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 48.0
	add_child(moon)

func _apply_materials(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.mesh: continue
		var key := "metal" if String(n.name).begins_with("Ship") or String(n.name).begins_with("Landing") or String(n.name).begins_with("Piston") or String(n.name).begins_with("Ramp") else "concrete"
		for s in range(mi.mesh.get_surface_count()):
			mi.set_surface_override_material(s, a.materials[key])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _make_static(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.mesh: continue
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		mi.add_child(body)
		var collision := CollisionShape3D.new()
		if String(mi.name).begins_with("Ground"):
			var box := BoxShape3D.new()
			box.size = Vector3(40, 1, 30)
			collision.shape = box
			collision.position = Vector3(-10.1, -0.52, -5.34)
		else:
			collision.shape = mi.mesh.create_trimesh_shape()
		body.add_child(collision)

func _t(arr: Array) -> Transform3D:
	return Transform3D(Vector3(arr[0],arr[1],arr[2]),Vector3(arr[3],arr[4],arr[5]),Vector3(arr[6],arr[7],arr[8]),Vector3(arr[9],arr[10],arr[11]))

func _place_original_props() -> void:
	var layout: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/layout.json"))
	var nodes := {}
	var index := 0
	for item in layout:
		var mesh_name: String = item.mesh
		if not meshes.has(mesh_name): continue
		var mi := MeshInstance3D.new()
		mi.name = "Prop_%d" % index
		index += 1
		mi.mesh = meshes[mesh_name]
		var key := "vegetation" if mesh_name.begins_with("Ivy") or mesh_name == "Fern" else "concrete"
		for s in range(mi.mesh.get_surface_count()):
			var orig := mi.mesh.surface_get_material(s)
			if orig and (String(orig.resource_name).contains("SpaceShip") or String(orig.resource_name).contains("Ship")): key = "metal"
		if key != "vegetation":
			if not mesh_name.begins_with("Ivy") and mesh_name not in ["CinderBlocks","BrokenPillar","BrokenChunks","BrokenSlab","Rubble_large","Rubble_medium","Rubble_pile","Rubble_small","Rubble_small_wide","DoorLeft","DoorRight","Doorway","OuterWall","OuterWall_Small"]: key="metal"
			mi.material_override = a.materials[key]
		else:
			for s in range(mi.mesh.get_surface_count()): mi.set_surface_override_material(s, a.materials.vegetation)
		var parent: Node = self
		if nodes.has(item.parent): parent = nodes[item.parent]
		parent.add_child(mi)
		mi.transform = _t(item.transform)
		nodes[item.name] = mi
		if key == "vegetation": continue
		if mesh_name == "Barrel" and item.parent == ".":
			var breakable = breakable_script.new()
			breakable.kind = "barrel"
			breakable.hp = 42.0
			breakable.size = Vector3(0.75, 1.0, 0.75)
			breakable.position = Vector3(0, 0.5, 0)
			mi.add_child(breakable)
			breakable.setup(game, mi, Vector3(0,0.5,0))
		elif mesh_name in ["Container","LargeContainer","CinderBlocks","BrokenPillar"]:
			_add_mesh_collision(mi)

func _add_mesh_collision(mi: MeshInstance3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	mi.add_child(body)
	var col := CollisionShape3D.new()
	col.shape = mi.mesh.create_trimesh_shape()
	body.add_child(col)

func _panel(pos: Vector3, size: Vector3, kind: String, rot: float = 0.0) -> Node3D:
	var b := breakable_script.new()
	b.kind = kind
	b.size = size
	b.hp = 35.0 if kind == "glass" else (110.0 if kind == "wall" else 42.0)
	add_child(b)
	b.position = pos
	b.rotation.y = rot
	b.setup(game)
	return b

func _make_gameplay_partitions() -> void:
	# Destructible maintenance booths are added to the original, non-destructible shell.
	for origin in [Vector3(-19,0,-9), Vector3(-18,0,2)]:
		for x in [-1.5, 0.0, 1.5]:
			_panel(origin + Vector3(x,1.3,-2), Vector3(1.48,2.6,0.22), "wall")
			_panel(origin + Vector3(x,3.15,-2), Vector3(1.48,1.1,0.12), "glass")
		_panel(origin + Vector3(-2.25,1.3,-0.5), Vector3(1.48,2.6,0.22), "wall", PI/2)
		_panel(origin + Vector3(-2.25,3.15,-0.5), Vector3(1.48,1.1,0.12), "glass", PI/2)
	for p in [Vector3(-12,0.65,-7),Vector3(-12,0.65,-5.5),Vector3(-4,0.65,3),Vector3(-23,0.65,-2)]:
		_panel(p,Vector3(1.3,1.3,1.3),"crate")
	# A single fixed supply-crate pad. The director never spawns enemies here.
	var pad := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = Vector3(2.4,0.06,2.4)
	pad.mesh = box; pad.material_override = a.material(Color(0.13,0.21,0.20),0.1,0.6)
	add_child(pad); pad.position = crate_anchor + Vector3(0,0.03,0)
	for x in [-1.15,1.15]:
		var stripe := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.045,0.025,2.3)
		stripe.mesh = bm; stripe.material_override = a.material(Color(0.25,0.8,0.68),1.5)
		add_child(stripe); stripe.position = crate_anchor + Vector3(x,0.08,0)

func _make_lights() -> void:
	for item in [Vector3(-7,5,4),Vector3(-21,5,-8),Vector3(3,6,-12),Vector3(-12,7,-15)]:
		var light := OmniLight3D.new()
		light.position = item
		light.light_color = Color(0.60,0.77,0.77) if lights.size()%2 == 0 else Color(0.95,0.25,0.12)
		light.light_energy = 2.2
		light.omni_range = 13.0
		add_child(light)
		lights.append(light)
		var fixture := MeshInstance3D.new(); var m := BoxMesh.new(); m.size = Vector3(0.65,0.08,0.18)
		fixture.mesh = m; fixture.material_override = a.material(light.light_color,3.0)
		add_child(fixture); fixture.position = item

func _make_navmesh() -> void:
	nav = NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.agent_height = 1.8
	nm.agent_radius = 0.5
	nm.agent_max_climb = 0.4
	nm.agent_max_slope = 42.0
	nm.cell_size = 0.25
	nm.cell_height = 0.2
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav.navigation_mesh = nm
	add_child(nav)
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, source, self)
	NavigationServer3D.bake_from_source_geometry_data(nm, source)
	nav.bake_finished.connect(func(): pass)

func random_spawn(player_pos: Vector3, previous: Array, rng: RandomNumberGenerator) -> Dictionary:
	var candidates := []
	for i in range(spawn_points.size()):
		if i in previous: continue
		var p := spawn_points[i]
		if p.distance_to(player_pos) < 8.0: continue
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := SphereShape3D.new(); shape.radius = 0.55
		query.shape = shape; query.transform = Transform3D(Basis.IDENTITY,p+Vector3.UP)
		query.collision_mask = 1
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): candidates.append(i)
	if candidates.is_empty():
		for i in range(spawn_points.size()):
			if spawn_points[i].distance_to(player_pos)>10.0: candidates.append(i)
	var index: int = candidates[rng.randi_range(0,candidates.size()-1)] if not candidates.is_empty() else 0
	var pos := spawn_points[index] + Vector3(rng.randf_range(-0.45,0.45),0.15,rng.randf_range(-0.45,0.45))
	return {"index":index,"position":pos}
