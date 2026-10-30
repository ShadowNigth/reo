extends Node3D
var game: Node
var kind := "ammo"
var model_name := "ammo_pistol"
var age := 0.0
var visual: Node3D
var label: Label3D
var taken := false

func setup(g: Node) -> void:
	game=g; add_to_group("interactable")
	visual=game.assets.instance("res://assets/weapons/%s.glb" % model_name)
	add_child(visual)
	var box:=AABB(); var first:=true
	for n in visual.find_children("*","MeshInstance3D",true,false):
		var mi:=n as MeshInstance3D
		if first: box=mi.get_aabb(); first=false
		else: box=box.merge(mi.get_aabb())
	var s:=0.7/maxf(box.size.length(),0.01)
	visual.scale=Vector3.ONE*s
	visual.position=Vector3(0,0.4,0)
	for n in visual.find_children("*","MeshInstance3D",true,false):
		var mi:=n as MeshInstance3D
		for surf in range(mi.mesh.get_surface_count()):
			var orig:=mi.mesh.surface_get_material(surf)
			var mat:StandardMaterial3D=orig.duplicate() if orig is StandardMaterial3D else game.assets.material(Color(0.4,0.5,0.3))
			mat.emission_enabled=true; mat.emission=Color(0.14,0.5,0.32) if kind=="weapon" else Color(0.6,0.38,0.08); mat.emission_energy_multiplier=0.45
			mi.set_surface_override_material(surf,mat)
	label=Label3D.new(); label.text="SUMINISTRO" if kind=="weapon" else "MUNICIÓN"
	label.font=game.assets.font; label.font_size=36; label.pixel_size=0.005
	label.modulate=Color(0.47,0.95,0.76) if kind=="weapon" else Color(1.0,0.76,0.35)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.no_depth_test=true
	add_child(label); label.position.y=1.25
	var light:=OmniLight3D.new(); light.light_color=Color(0.2,0.85,0.58) if kind=="weapon" else Color(0.95,0.58,0.17)
	light.omni_range=3.0; light.light_energy=0.8; add_child(light); light.position.y=0.6

func _process(delta: float) -> void:
	if not game or not game.is_playing(): return
	age+=delta
	if visual: visual.rotation.y+=delta*0.55; visual.position.y=0.4+sin(age*2.0)*0.07
	if kind=="ammo":
		if age>80.0: queue_free(); return
		if global_position.distance_to(game.player.global_position)<1.2: interact()

func interact() -> void:
	if taken: return
	if kind=="weapon": game.director.claim_crate()
	else:
		taken=true; game.player.add_ammo(); queue_free()
