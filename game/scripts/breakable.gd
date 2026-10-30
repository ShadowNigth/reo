extends StaticBody3D
var game: Node
var kind := "wall"
var hp := 110.0
var max_hp := 110.0
var size := Vector3.ONE
var broken := false
var mesh: MeshInstance3D
var collision: CollisionShape3D
var attached := false
var source_mesh: MeshInstance3D

func setup(owner_game: Node, visual_source: MeshInstance3D = null, offset: Vector3 = Vector3.ZERO) -> void:
	game = owner_game
	max_hp = hp
	collision_layer = 1
	collision_mask = 0
	add_to_group("damageable")
	source_mesh = visual_source
	attached = source_mesh != null
	if attached:
		mesh = source_mesh
	else:
		mesh = MeshInstance3D.new()
		var box := BoxMesh.new(); box.size = size
		mesh.mesh = box
		var mat: StandardMaterial3D
		if kind == "glass":
			mat = game.assets.material(Color(0.28,0.56,0.58,0.28))
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.metallic = 0.35; mat.roughness = 0.15
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		elif kind == "barrel":
			mat = game.assets.material(Color(0.45,0.12,0.07),0.0,0.6)
		else:
			mat = game.assets.materials.concrete.duplicate()
			mat.albedo_color = Color(0.67,0.64,0.56) if kind == "crate" else Color(0.64,0.69,0.67)
		mesh.material_override = mat
		add_child(mesh)
		collision = CollisionShape3D.new()
		var boxshape := BoxShape3D.new(); boxshape.size = size
		collision.shape = boxshape
		add_child(collision)
	if attached:
		collision = CollisionShape3D.new()
		var barrel_shape := BoxShape3D.new(); barrel_shape.size=size
		collision.shape=barrel_shape; collision.position=offset; add_child(collision)
	if kind == "barrel":
		var band := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.76,0.14,0.76)
		band.mesh = bm; band.material_override = game.assets.material(Color(0.83,0.44,0.10),0.2)
		add_child(band); band.position = Vector3(0,0.15,0)

func take_damage(amount: float, point: Vector3, impulse: Vector3, _hit_kind: String = "bullet") -> void:
	if broken: return
	hp -= amount
	game.fx.impact(point, -impulse.normalized(), "glass" if kind == "glass" else "stone")
	if not attached and kind != "glass":
		var mat := mesh.material_override as StandardMaterial3D
		if mat: mat.albedo_color = mat.albedo_color.darkened(clamp(amount/max_hp,0.0,0.2)*0.5)
	if hp <= 0.0: break_apart(impulse)

func break_apart(impulse: Vector3) -> void:
	if broken: return
	broken = true
	var origin := global_position
	if attached: origin = source_mesh.global_position
	if attached: source_mesh.visible = false
	else: mesh.visible = false
	if collision: collision.set_deferred("disabled",true)
	collision_layer = 0
	game.audio.play_at("glass" if kind == "glass" else "break",origin,0.0)
	game.fx.burst(origin, "glass" if kind == "glass" else "stone", 18)
	game.fx.fragments(origin, size, impulse, kind, 7 if kind == "glass" else 9)
	game.world_changed()
	if kind == "barrel":
		game.fx.explosion(origin+Vector3.UP*0.4)
		game.explode(origin+Vector3.UP*0.4, 5.2, 185.0)
	set_deferred("collision_mask",0)
