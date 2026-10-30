extends Node
var failures: Array[String] = []
var checks := 0
func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition: failures.append(label)
	print(("PASS " if condition else "FAIL ")+label)

func run(game: Node) -> void:
	print("UMBRAL_SMOKE_BEGIN")
	check(is_instance_valid(game.hud),"HUD exists before first weapon equip")
	check(is_instance_valid(game.player.weapon_visual),"Initial melee viewmodel is equipped")
	game.fx.burst(game.player.global_position,"blood",8)
	check(game.fx.emitters[0].emitting,"Particle burst restarts without CPUParticles.stop")
	check(game.catalog.WEAPONS.size()>=29,"29 downloaded weapon variants")
	for w in game.catalog.WEAPONS:
		check(FileAccess.file_exists(game.catalog.model_path(w.id)),"Model exists: "+w.id)
	check(game.player.slots.size()==3,"Exactly three inventory slots")
	check(not game.catalog.compatible(0,"pistol"),"Melee slot rejects pistol")
	check(not game.catalog.compatible(1,"bat"),"Gun slot rejects melee")
	check(game.catalog.compatible(1,"shotgun"),"Pistol can become shotgun")
	check(game.catalog.compatible(2,"rifle"),"Third slot accepts rifle")
	check(game.player.current().id=="bat","Run starts with melee")
	check(game.player.slots[1].mag==8 and game.player.slots[1].reserve==16,"Scarce starting ammunition")
	game.player.equip(1,true)
	var before:int=game.player.current().mag
	game.player.fire()
	check(game.player.current().mag==before-1,"Trigger consumes one round")
	game.player.current().mag=0
	game.player.reload()
	check(game.player.reload_left>0,"Reload has a real delay")
	game.player.finish_reload()
	check(game.player.current().mag==8 and game.player.current().reserve==8,"Reload transfers, never creates ammo")
	check(game.player.replace_slot(2,"shotgun"),"Equip third weapon")
	check(not game.player.replace_slot(2,"knife"),"Reject incompatible swap")
	var old:Dictionary=game.player.slots[1].duplicate()
	check(game.player.replace_slot(1,"lmg"),"Replace pistol with LMG")
	check(game.player.slots[1].id=="lmg","Replacement persists")
	game.player.slots[1]=old; game.player.equip(0,true)
	var damageable:Node3D=preload("res://scripts/breakable.gd").new()
	damageable.kind="glass"; damageable.hp=35; damageable.size=Vector3(1,1,0.1)
	game.world.add_child(damageable); damageable.global_position=Vector3(-10,1,-2); damageable.setup(game)
	damageable.take_damage(40,Vector3(-10,1,-2),Vector3.FORWARD*5)
	check(damageable.broken,"Glass breaks under damage")
	var wall:Node3D=preload("res://scripts/breakable.gd").new(); wall.hp=110; wall.size=Vector3.ONE
	game.world.add_child(wall); wall.global_position=Vector3(-12,1,-2); wall.setup(game)
	wall.take_damage(20,Vector3(-12,1,-2),Vector3.FORWARD)
	check(not wall.broken,"Wall survives partial damage")
	wall.take_damage(100,Vector3(-12,1,-2),Vector3.FORWARD)
	check(wall.broken,"Wall breaks cumulatively")
	game.director.start_wave()
	var enemy:Node=game.director.spawn_enemy("walker",Vector3(-9,0.3,1.5))
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(is_instance_valid(enemy) and enemy.hp>0,"Animated enemy spawns in physics world")
	var hp_before:float=enemy.hp
	enemy.take_damage(20,enemy.global_position+Vector3.UP*0.9,Vector3.FORWARD*15,"melee")
	check(enemy.hp<hp_before,"Enemy receives melee damage")
	check(enemy.knockback.length()>0,"Mass-weighted melee impulse")
	enemy.take_damage(9999,enemy.global_position+Vector3.UP,Vector3.FORWARD*10)
	check(enemy.dead,"Enemy death transition")
	var head_before:Vector3=enemy.skeleton.get_bone_global_pose(enemy.skeleton.find_bone("Head")).origin
	for frame in range(45): await get_tree().physics_frame
	check(enemy.ragdoll_active and enemy.ragdoll_bones.size()>=12,"Death activates articulated physical skeleton")
	var head_after:Vector3=enemy.skeleton.get_bone_global_pose(enemy.skeleton.find_bone("Head")).origin
	check(head_after.is_finite() and head_before.distance_to(head_after)>0.05,"Ragdoll joints move under gravity and impulse")
	check(enemy.ragdoll.is_simulating_physics(),"Ragdoll simulation remains live")
	check(not is_instance_valid(game.director.crate),"At most one supply crate before cooldown")
	game.director.spawn_crate(); var first:Node3D=game.director.crate
	game.director.spawn_crate()
	check(game.director.crate==first,"Supply spawn is a singleton")
	game.director.spawn_ammo(Vector3(-8,0.3,5)); var count:int=game.director.ammo_drops.size()
	game.player.add_ammo()
	check(count<=3,"Bounded ammo drops")
	var positions: Array=[]
	for i in range(20): positions.append(game.director.choose_spawn().index)
	check(positions.size()==20,"Spawn director continues indefinitely")
	for i in range(1,positions.size()): check(positions[i]!=positions[i-1],"No immediate spawn repetition %d"%i)
	game.player.hp=100; game.player.invulnerable=0; game.player.take_damage(13,Vector3.ZERO)
	check(game.player.hp==87,"Player damage")
	game.player.invulnerable=0; game.player.take_damage(999,Vector3.ZERO)
	check(game.state=="dead","Death menu state")
	print("UMBRAL_SMOKE_END checks=%d failures=%d" % [checks,failures.size()])
	for f in failures: print("FAILURE: "+f)
	get_tree().quit(1 if not failures.is_empty() else 0)
