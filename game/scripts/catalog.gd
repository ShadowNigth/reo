extends RefCounted
## Data-driven arsenal. Every visual references a downloaded model.
const WEAPONS := [
	{"id":"bat", "name":"Bate de rescate", "kind":"melee", "model":"bat_saw", "damage":48.0, "rate":0.66, "range":2.65, "mag":0, "reserve":0, "reload":0.0, "pellets":0, "spread":0.0, "kick":0.10, "mass":2.8},
	{"id":"knife", "name":"Cuchillo de supervivencia", "kind":"melee", "model":"knife_sharp", "damage":34.0, "rate":0.34, "range":2.1, "mag":0, "reserve":0, "reload":0.0, "pellets":0, "spread":0.0, "kick":0.06, "mass":0.7},
	{"id":"machete", "name":"Cuchillo de brecha", "kind":"melee", "model":"knifeRound_sharp", "damage":62.0, "rate":0.78, "range":2.5, "mag":0, "reserve":0, "reload":0.0, "pellets":0, "spread":0.0, "kick":0.13, "mass":1.5},
	{"id":"pistol", "name":"P9 · Servicio", "kind":"pistol", "model":"pistol", "damage":30.0, "rate":0.27, "range":65.0, "mag":8, "reserve":16, "reload":1.45, "pellets":1, "spread":0.006, "kick":0.045, "mass":1.0},
	{"id":"silenced", "name":"P9 · Silenciada", "kind":"pistol", "model":"pistolSilencer", "damage":35.0, "rate":0.31, "range":55.0, "mag":10, "reserve":30, "reload":1.5, "pellets":1, "spread":0.004, "kick":0.028, "mass":1.2},
	{"id":"shotgun", "name":"Quebrantahuesos", "kind":"shotgun", "model":"shotgun", "damage":19.0, "rate":0.88, "range":27.0, "mag":6, "reserve":18, "reload":2.5, "pellets":8, "spread":0.062, "kick":0.13, "mass":3.6},
	{"id":"breacher", "name":"Brecha corta", "kind":"shotgun", "model":"shotgunShort", "damage":21.0, "rate":0.72, "range":19.0, "mag":4, "reserve":20, "reload":2.15, "pellets":7, "spread":0.085, "kick":0.12, "mass":2.8},
	{"id":"smg", "name":"Vector · SMG", "kind":"smg", "model":"smg", "damage":19.0, "rate":0.075, "range":42.0, "mag":30, "reserve":90, "reload":1.8, "pellets":1, "spread":0.025, "kick":0.025, "mass":2.4},
	{"id":"uzi", "name":"Uzi · Compacta", "kind":"smg", "model":"uzi", "damage":20.0, "rate":0.085, "range":36.0, "mag":25, "reserve":100, "reload":1.65, "pellets":1, "spread":0.028, "kick":0.027, "mass":2.2},
	{"id":"uzi_s", "name":"Uzi · Susurro", "kind":"smg", "model":"uziSilencer", "damage":22.0, "rate":0.09, "range":40.0, "mag":25, "reserve":75, "reload":1.7, "pellets":1, "spread":0.018, "kick":0.02, "mass":2.5},
	{"id":"uzi_l", "name":"Uzi · Extendida", "kind":"smg", "model":"uziLong", "damage":22.0, "rate":0.08, "range":46.0, "mag":32, "reserve":96, "reload":1.9, "pellets":1, "spread":0.019, "kick":0.025, "mass":2.6},
	{"id":"uzi_ls", "name":"Uzi · Fantasma", "kind":"smg", "model":"uziLongSilencer", "damage":24.0, "rate":0.085, "range":45.0, "mag":30, "reserve":90, "reload":1.85, "pellets":1, "spread":0.014, "kick":0.02, "mass":2.7},
	{"id":"uzi_g", "name":"Uzi · Dorada", "kind":"smg", "model":"uziGold", "damage":26.0, "rate":0.075, "range":40.0, "mag":28, "reserve":112, "reload":1.55, "pellets":1, "spread":0.021, "kick":0.027, "mass":2.3},
	{"id":"uzi_gs", "name":"Uzi · Áurea S", "kind":"smg", "model":"uziGoldSilencer", "damage":27.0, "rate":0.08, "range":43.0, "mag":28, "reserve":84, "reload":1.6, "pellets":1, "spread":0.015, "kick":0.02, "mass":2.5},
	{"id":"uzi_gl", "name":"Uzi · Áurea L", "kind":"smg", "model":"uziGoldLong", "damage":27.0, "rate":0.075, "range":48.0, "mag":35, "reserve":105, "reload":1.8, "pellets":1, "spread":0.016, "kick":0.023, "mass":2.7},
	{"id":"uzi_gls", "name":"Uzi · Silencio Áureo", "kind":"smg", "model":"uziGoldLongSilencer", "damage":28.0, "rate":0.08, "range":46.0, "mag":32, "reserve":96, "reload":1.8, "pellets":1, "spread":0.012, "kick":0.018, "mass":2.8},
	{"id":"rifle", "name":"AR · Centinela", "kind":"rifle", "model":"rifle", "damage":37.0, "rate":0.13, "range":80.0, "mag":24, "reserve":72, "reload":2.1, "pellets":1, "spread":0.012, "kick":0.045, "mass":3.5},
	{"id":"lmg", "name":"M60 · Bastión", "kind":"lmg", "model":"machinegun", "damage":38.0, "rate":0.105, "range":75.0, "mag":60, "reserve":120, "reload":3.6, "pellets":1, "spread":0.025, "kick":0.045, "mass":7.0},
	{"id":"sniper", "name":"SR · Vigía", "kind":"sniper", "model":"sniper", "damage":155.0, "rate":1.15, "range":120.0, "mag":5, "reserve":20, "reload":2.7, "pellets":1, "spread":0.002, "kick":0.14, "mass":5.5},
	{"id":"sniper_c", "name":"SR · Espectro", "kind":"sniper", "model":"sniperCamo", "damage":175.0, "rate":1.25, "range":120.0, "mag":5, "reserve":15, "reload":2.9, "pellets":1, "spread":0.001, "kick":0.15, "mass":5.8},
	{"id":"launcher", "name":"Lanzacohetes · Ruina", "kind":"launcher", "model":"rocketlauncher", "damage":210.0, "rate":1.4, "range":80.0, "mag":1, "reserve":5, "reload":2.8, "pellets":1, "spread":0.0, "kick":0.18, "mass":8.0},
	{"id":"launcher_m", "name":"Lanzacohetes · Cerbero", "kind":"launcher", "model":"rocketlauncherModern", "damage":230.0, "rate":1.5, "range":80.0, "mag":1, "reserve":5, "reload":3.0, "pellets":1, "spread":0.0, "kick":0.19, "mass":8.5},
	{"id":"launcher_r", "name":"Lanzacohetes · Cerbero R", "kind":"launcher", "model":"rocketlauncherModernRotating", "damage":245.0, "rate":1.6, "range":80.0, "mag":1, "reserve":4, "reload":3.1, "pellets":1, "spread":0.0, "kick":0.2, "mass":9.0},
	{"id":"launcher_s", "name":"Lanzacohetes · Bastón", "kind":"launcher", "model":"rocketlauncherSide", "damage":220.0, "rate":1.45, "range":80.0, "mag":1, "reserve":6, "reload":2.9, "pellets":1, "spread":0.0, "kick":0.18, "mass":8.2},
	{"id":"grenadier", "name":"Lanzagranadas · Tambor", "kind":"launcher", "model":"machinegunLauncher", "damage":145.0, "rate":0.65, "range":55.0, "mag":4, "reserve":12, "reload":3.2, "pellets":1, "spread":0.012, "kick":0.11, "mass":5.5},
	{"id":"flame", "name":"Purgador · Lanzallamas", "kind":"flame", "model":"flamethrower", "damage":12.0, "rate":0.08, "range":8.0, "mag":100, "reserve":150, "reload":3.2, "pellets":1, "spread":0.10, "kick":0.008, "mass":6.0},
	{"id":"flame_h", "name":"Purgador · Ligero", "kind":"flame", "model":"flamethrowerHandle", "damage":10.0, "rate":0.065, "range":6.5, "mag":80, "reserve":160, "reload":2.8, "pellets":1, "spread":0.12, "kick":0.006, "mass":4.0},
	{"id":"pulse", "name":"Pulso · Contención", "kind":"energy", "model":"blaster", "damage":42.0, "rate":0.28, "range":70.0, "mag":16, "reserve":48, "reload":2.0, "pellets":1, "spread":0.003, "kick":0.035, "mass":2.8},
	{"id":"repeater", "name":"Repetidor · Arcadia", "kind":"energy", "model":"blaster-repeater", "damage":26.0, "rate":0.10, "range":60.0, "mag":40, "reserve":120, "reload":2.4, "pellets":1, "spread":0.018, "kick":0.023, "mass":3.6}
]
const ENEMIES := [
	{"id":"walker", "name":"Errante", "model":"zombie_basic", "hp":90.0, "speed":1.65, "damage":13.0, "scale":1.28, "radius":0.36, "mass":75.0, "color":Color(0.72,0.70,0.66), "reach":1.45, "cooldown":1.3},
	{"id":"runner", "name":"Desgarrador", "model":"zombie_basic", "hp":62.0, "speed":3.8, "damage":10.0, "scale":1.12, "radius":0.29, "mass":48.0, "color":Color(0.70,0.52,0.46), "reach":1.35, "cooldown":0.85},
	{"id":"brute", "name":"Coloso", "model":"zombie_chubby", "hp":330.0, "speed":1.15, "damage":29.0, "scale":1.75, "radius":0.65, "mass":220.0, "color":Color(0.66,0.64,0.58), "reach":2.1, "cooldown":1.8},
	{"id":"crawler", "name":"Reptante", "model":"zombie_basic", "hp":48.0, "speed":2.8, "damage":8.0, "scale":0.65, "radius":0.32, "mass":30.0, "color":Color(0.62,0.65,0.64), "reach":1.2, "cooldown":0.8},
	{"id":"stalker", "name":"Acechador", "model":"zombie_chubby", "hp":145.0, "speed":2.6, "damage":18.0, "scale":1.4, "radius":0.4, "mass":95.0, "color":Color(0.56,0.59,0.65), "reach":1.65, "cooldown":1.1}
]
static func weapon(id: String) -> Dictionary:
	for w in WEAPONS:
		if w.id == id: return w.duplicate(true)
	return WEAPONS[0].duplicate(true)
static func enemy(id: String) -> Dictionary:
	for e in ENEMIES:
		if e.id == id: return e.duplicate(true)
	return ENEMIES[0].duplicate(true)
static func model_path(id: String) -> String:
	var w := weapon(id)
	return "res://assets/%s/%s.glb" % ["models" if id in ["bat","shotgun","rifle","smg"] else "weapons", w.model]
static func compatible(slot: int, id: String) -> bool:
	return (slot == 0 and weapon(id).kind == "melee") or (slot > 0 and weapon(id).kind != "melee")
static func category(id: String) -> String:
	return {"melee":"CUERPO A CUERPO", "pistol":"PISTOLA", "shotgun":"ESCOPETA", "smg":"SUBFUSIL", "rifle":"FUSIL", "lmg":"AMETRALLADORA", "sniper":"FRANCOTIRADOR", "launcher":"EXPLOSIVOS", "flame":"LANZALLAMAS", "energy":"ENERGÍA"}.get(weapon(id).kind, "ARMA")
