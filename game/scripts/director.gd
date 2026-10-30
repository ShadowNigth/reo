extends Node
## Infinite waves with a hard alive cap, bounded queues and a no-repeat spawn bag.
var game: Node
var wave := 0
var pending := 0
var alive := 0
var intermission := 6.0
var spawn_timer := 0.0
var active := false
var previous_wave_points: Array = []
var wave_points: Array = []
var recent_points: Array = []
var last_point := -1
var rng := RandomNumberGenerator.new()
var spawn_bag: Array[String] = []
var kills_since_ammo := 0
var max_alive := 26
var wave_signature := ""
var crate_cooldown := 12.0
var crate: Node3D
var loot_bag: Array = []
var ammo_drops: Array[Node3D] = []
var wave_kills := 0

func setup(g: Node, seed_value: int = 0) -> void:
	game=g
	rng.seed=seed_value if seed_value!=0 else randi()
	max_alive=26 if game.settings.quality!="low" else 18
	crate_cooldown=12.0

func _process(delta: float) -> void:
	if not game or not game.is_playing(): return
	crate_cooldown-=delta
	if crate_cooldown<=0.0 and not is_instance_valid(crate): spawn_crate()
	for drop in ammo_drops.duplicate():
		if not is_instance_valid(drop): ammo_drops.erase(drop)
	if not active:
		intermission-=delta
		if intermission<=0.0: start_wave()
		return
	spawn_timer-=delta
	if pending>0 and alive<max_alive and spawn_timer<=0.0:
		spawn_enemy(); pending-=1
		spawn_timer=maxf(0.3,1.1-wave*0.025)
	if pending==0 and alive==0:
		active=false; intermission=16.0
		game.stats.waves_cleared=wave
		game.player.hp=minf(100.0,game.player.hp+12.0)
		if wave%3==0: game.player.grenades=mini(3,game.player.grenades+1)
		game.hud.banner("SECTOR CONTENIDO","Oleada %02d superada · +12 salud · 16 s de respiro" % wave,4.0)
		game.audio.play_ui("pickup")
		game.save_record()

func start_wave() -> void:
	wave+=1; active=true; wave_kills=0
	pending=mini(150,5+wave*3)
	wave_points.clear(); recent_points.clear(); last_point=-1
	var indices:=range(game.world.spawn_points.size()); indices.shuffle()
	var count:=mini(3+floori(wave / 3.0),7)
	# Do not reuse the previous wave's entire active set.
	if indices.slice(0,count)==previous_wave_points: indices.append(indices.pop_front())
	wave_points=indices.slice(0,count)
	previous_wave_points=wave_points.duplicate()
	wave_signature="%d:%s" % [wave,str(wave_points)]
	spawn_bag.clear()
	for i in range(pending):
		var roll:=rng.randf()
		var kind:="walker"
		if wave>=2 and roll<0.25: kind="runner"
		if wave>=3 and roll>0.78: kind="crawler"
		if wave>=4 and roll>0.89: kind="brute"
		if wave>=5 and roll>0.64 and roll<0.78: kind="stalker"
		spawn_bag.append(kind)
	spawn_timer=0.2
	game.hud.banner("OLEADA %02d" % wave,"%d hostiles · nuevas rutas de acceso" % pending,3.5)
	game.audio.play_ui("alarm",-14.0)

func choose_spawn() -> Dictionary:
	var allowed:=wave_points.filter(func(i): return i!=last_point and not i in recent_points)
	if allowed.is_empty(): allowed=wave_points.filter(func(i): return i!=last_point)
	if allowed.is_empty(): allowed=wave_points
	var index: int=allowed[rng.randi_range(0,allowed.size()-1)] if not allowed.is_empty() else 0
	var p: Vector3=game.world.spawn_points[index]
	if p.distance_to(game.player.global_position)<7.0:
		var result: Dictionary = game.world.random_spawn(game.player.global_position,recent_points,rng)
		index=result.index; p=result.position
	else: p+=Vector3(rng.randf_range(-0.55,0.55),0.2,rng.randf_range(-0.55,0.55))
	last_point=index; recent_points.append(index)
	if recent_points.size()>mini(3,wave_points.size()): recent_points.pop_front()
	return {"index":index,"position":p}

func spawn_enemy(kind: String = "", pos: Vector3 = Vector3.INF) -> Node:
	var chosen:=choose_spawn()
	if kind.is_empty(): kind=spawn_bag.pop_back() if not spawn_bag.is_empty() else "walker"
	var enemy: Node=preload("res://scripts/enemy.gd").new()
	enemy.name="Hostile_%d_%d" % [wave,game.stats.spawned]
	game.actors.add_child(enemy)
	enemy.global_position=pos if pos!=Vector3.INF else chosen.position
	enemy.setup(game,kind,wave)
	alive+=1; game.stats.spawned+=1
	return enemy

func enemy_killed(enemy: Node) -> void:
	game.stats.kills+=1; wave_kills+=1; kills_since_ammo+=1
	game.stats.score+=150 if enemy.data.id=="brute" else 100
	enemy_removed(enemy)
	# 12% base chance; pity after 14 kills, never more than three ammo boxes on the map.
	if ammo_drops.size()<3 and (rng.randf()<0.12 or kills_since_ammo>=14):
		spawn_ammo(enemy.global_position)
		kills_since_ammo=0

func enemy_removed(enemy: Node) -> void:
	if not enemy.counted: return
	enemy.counted=false
	alive=maxi(0,alive-1)

func spawn_ammo(pos: Vector3) -> void:
	var pickup:=preload("res://scripts/pickup.gd").new()
	pickup.kind="ammo"; pickup.model_name="ammo_pistol"
	game.actors.add_child(pickup); pickup.global_position=pos+Vector3.UP*0.2
	pickup.setup(game); ammo_drops.append(pickup)

func spawn_crate() -> void:
	if is_instance_valid(crate): return
	crate=preload("res://scripts/pickup.gd").new()
	crate.kind="weapon"; crate.model_name="ammo_rocketModern"
	game.actors.add_child(crate); crate.global_position=game.world.crate_anchor+Vector3.UP*0.15
	crate.setup(game)
	game.hud.toast("Suministro disponible en la plataforma marcada.")

func roll_weapon() -> String:
	if loot_bag.is_empty():
		for w in game.catalog.WEAPONS: loot_bag.append(w.id)
		loot_bag.shuffle()
	return String(loot_bag.pop_back())

func claim_crate() -> void:
	if not is_instance_valid(crate): return
	var id:=roll_weapon()
	crate.queue_free(); crate=null; crate_cooldown=75.0
	game.player.offer_weapon(id)

func nearest_interactable() -> Node3D:
	var best: Node3D=null; var distance:=2.7
	for n in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(n): continue
		var d:float=game.player.global_position.distance_to(n.global_position)
		if d<distance:
			var q:=PhysicsRayQueryParameters3D.create(game.player.camera.global_position,n.global_position+Vector3.UP*0.5,1,[game.player.get_rid()])
			if not game.player.get_world_3d().direct_space_state.intersect_ray(q).is_empty(): continue
			best=n; distance=d
	return best
