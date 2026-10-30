extends Node3D
var game: Node
var velocity := Vector3.ZERO
var damage := 160.0
var lifetime := 4.0
var grenade := false
var mesh: Node3D
var exploded := false

func setup(g: Node, dir: Vector3, power: float, is_grenade: bool) -> void:
	game=g; damage=power; grenade=is_grenade
	velocity=dir.normalized()*(11.5 if grenade else 25.0)
	if grenade: velocity=dir; lifetime=1.8
	mesh=game.assets.instance("res://assets/weapons/%s.glb" % ("grenade" if grenade else "ammo_rocket"))
	add_child(mesh); mesh.scale=Vector3.ONE*(1.5 if grenade else 0.65)

func _physics_process(delta: float) -> void:
	if not game or not game.is_playing() or exploded: return
	lifetime-=delta
	if grenade: velocity.y-=12.0*delta
	var from:=global_position; var to:=from+velocity*delta
	var q:=PhysicsRayQueryParameters3D.create(from,to,1|2)
	var hit:=get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		if grenade:
			global_position=hit.position+hit.normal*0.09
			velocity=velocity.bounce(hit.normal)*0.48
			mesh.rotate_x(delta*8.0)
		else: detonate(hit.position)
	else: global_position=to
	if velocity.length()>0.1: mesh.look_at(global_position+velocity.normalized(),Vector3.UP)
	mesh.rotate_object_local(Vector3.FORWARD,delta*5.0)
	if lifetime<=0.0: detonate(global_position)

func detonate(pos: Vector3) -> void:
	if exploded: return
	exploded=true
	game.fx.explosion(pos)
	game.explode(pos,5.5 if grenade else 6.0,damage)
	queue_free()
