extends CanvasLayer
const INK := Color(0.035,0.049,0.052,0.95)
const PAPER := Color(0.88,0.90,0.83)
const MUTED := Color(0.49,0.58,0.56)
const RED := Color(0.88,0.22,0.13)
const MINT := Color(0.44,0.84,0.68)
const AMBER := Color(0.96,0.66,0.28)
var game: Node
var root: Control
var gameplay: Control
var panel: PanelContainer
var panel_body: VBoxContainer
var health: ProgressBar
var stamina: ProgressBar
var health_text: Label
var ammo: Label
var weapon_name: Label
var wave_text: Label
var enemy_text: Label
var timer_text: Label
var slot_labels: Array[Label] = []
var slot_panels: Array[PanelContainer] = []
var prompt: Label
var objective: Label
var toast_text: Label
var toast_time := 0.0
var banner_title: Label
var banner_sub: Label
var banner_time := 0.0
var hit_marker: Label
var damage_overlay: ColorRect
var vignette: ColorRect
var headshot := false
var offered := ""
var inventory_signature := ""
var fps: Label
var gore_check: CheckButton
var shake_check: CheckButton

func setup(g: Node) -> void:
	game=g; layer=10
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(root)
	_build_gameplay(); _build_panel()

func _font(size: int = 20,bold: bool=false) -> Font:
	return game.assets.bold if bold else game.assets.font

func _label(text: String,size: int=20,color: Color=PAPER,bold: bool=false) -> Label:
	var l:=Label.new(); l.text=text; l.add_theme_font_override("font",_font(size,bold)); l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _style(bg: Color,border: Color=Color.TRANSPARENT) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border
	s.set_border_width_all(1); s.content_margin_left=18; s.content_margin_right=18; s.content_margin_top=13; s.content_margin_bottom=13
	s.corner_radius_top_left=2; s.corner_radius_bottom_right=2
	return s

func _button(text: String,fn: Callable,accent: bool=false) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(0,48)
	b.add_theme_font_override("font",_font(21,true)); b.add_theme_font_size_override("font_size",21)
	b.add_theme_color_override("font_color",PAPER); b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_stylebox_override("normal",_style(RED if accent else Color(0.08,0.105,0.105,0.95),Color(0.94,0.36,0.2) if accent else Color(0.22,0.29,0.28)))
	b.add_theme_stylebox_override("hover",_style(Color(0.98,0.32,0.18) if accent else Color(0.16,0.22,0.21),MINT))
	b.add_theme_stylebox_override("pressed",_style(Color(0.5,0.13,0.08)))
	b.pressed.connect(fn)
	return b

func _panel_box(parent: Control,pos: Vector2,size: Vector2) -> VBoxContainer:
	var p:=PanelContainer.new(); p.add_theme_stylebox_override("panel",_style(INK,Color(0.20,0.28,0.26,0.7))); p.position=pos; p.custom_minimum_size=size
	parent.add_child(p)
	var v:=VBoxContainer.new(); v.add_theme_constant_override("separation",5); p.add_child(v)
	return v

func _build_gameplay() -> void:
	gameplay=Control.new(); gameplay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); gameplay.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(gameplay)
	vignette=ColorRect.new(); vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader:=Shader.new(); shader.code="shader_type canvas_item; void fragment(){ vec2 p=UV-0.5; float v=smoothstep(0.20,0.73,length(p)); COLOR=vec4(0.005,0.009,0.01,v*0.62); }"
	var mat:=ShaderMaterial.new(); mat.shader=shader; vignette.material=mat; gameplay.add_child(vignette)
	damage_overlay=ColorRect.new(); damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); damage_overlay.color=Color(0.5,0.01,0.0,0.0); damage_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE; gameplay.add_child(damage_overlay)
	var top:=_panel_box(gameplay,Vector2(26,22),Vector2(220,70))
	top.add_child(_label("U M B R A L  /  SECTOR 07",15,MINT,true))
	wave_text=_label("OLEADA 01",30,PAPER,true); top.add_child(wave_text)
	enemy_text=_label("PREPARATE",16,MUTED); top.add_child(enemy_text)
	var stats_box:=_panel_box(gameplay,Vector2(1030,22),Vector2(220,60))
	timer_text=_label("00:00  /  0 BAJAS",20,PAPER,true); stats_box.add_child(timer_text)
	fps=_label("",13,MUTED); stats_box.add_child(fps)
	objective=_label("",17,MINT); objective.position=Vector2(28,151); objective.size=Vector2(520,35); gameplay.add_child(objective)
	var bottom:=_panel_box(gameplay,Vector2(26,564),Vector2(264,122))
	health_text=_label("INTEGRIDAD  100",20,PAPER,true); bottom.add_child(health_text)
	health=ProgressBar.new(); health.max_value=100; health.value=100; health.show_percentage=false; health.custom_minimum_size=Vector2(225,9)
	health.add_theme_stylebox_override("fill",_style(MINT)); health.add_theme_stylebox_override("background",_style(Color(0.15,0.19,0.18))); bottom.add_child(health)
	stamina=ProgressBar.new(); stamina.max_value=100; stamina.value=100; stamina.show_percentage=false; stamina.custom_minimum_size=Vector2(225,4); stamina.add_theme_stylebox_override("fill",_style(AMBER)); stamina.add_theme_stylebox_override("background",_style(Color(0.15,0.19,0.18))); bottom.add_child(stamina)
	bottom.add_child(_label("F  Linterna     G  Granada",15,MUTED))
	var ammo_box:=_panel_box(gameplay,Vector2(998,564),Vector2(252,122))
	weapon_name=_label("BATE DE RESCATE",18,MUTED,true); ammo_box.add_child(weapon_name)
	ammo=_label("∞",52,PAPER,true); ammo_box.add_child(ammo)
	for i in range(3):
		var p:=PanelContainer.new(); p.position=Vector2(370+i*185,625); p.custom_minimum_size=Vector2(175,61); p.add_theme_stylebox_override("panel",_style(INK,Color(0.2,0.28,0.26)))
		gameplay.add_child(p); slot_panels.append(p)
		var l:=_label("",16); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size=Vector2(140,35); p.add_child(l); slot_labels.append(l)
	var cross:=_label("+",26,Color(0.82,0.91,0.83,0.8)); cross.position=Vector2(632,345); cross.size=Vector2(20,30); gameplay.add_child(cross)
	hit_marker=_label("×",36,RED,true); hit_marker.position=Vector2(628,338); hit_marker.modulate.a=0; gameplay.add_child(hit_marker)
	prompt=_label("",23,PAPER,true); prompt.position=Vector2(340,488); prompt.size=Vector2(600,40); prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; gameplay.add_child(prompt)
	toast_text=_label("",19,MINT); toast_text.position=Vector2(340,574); toast_text.size=Vector2(600,40); toast_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; gameplay.add_child(toast_text)
	banner_title=_label("",58,PAPER,true); banner_title.position=Vector2(290,185); banner_title.size=Vector2(700,72); banner_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; gameplay.add_child(banner_title)
	banner_sub=_label("",21,MUTED); banner_sub.position=Vector2(240,258); banner_sub.size=Vector2(800,45); banner_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; gameplay.add_child(banner_sub)
	gameplay.visible=false

func _build_panel() -> void:
	panel=PanelContainer.new(); panel.position=Vector2(70,40); panel.custom_minimum_size=Vector2(475,610); panel.add_theme_stylebox_override("panel",_style(Color(0.025,0.039,0.041,0.96),Color(0.23,0.32,0.29)))
	root.add_child(panel); panel_body=VBoxContainer.new(); panel_body.add_theme_constant_override("separation",6); panel.add_child(panel_body)

func clear_panel() -> void:
	for c in panel_body.get_children(): panel_body.remove_child(c); c.queue_free()
	panel.visible=true

func add_text(text: String,size: int=19,color: Color=PAPER,bold: bool=false) -> void:
	var l:=_label(text,size,color,bold); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size.x=430; panel_body.add_child(l)

func show_menu() -> void:
	gameplay.visible=false; clear_panel()
	add_text("ARCHIVO DE CUARENTENA  /  07",16,MINT,true)
	add_text("UMBRAL",74,PAPER,true)
	add_text("P R O T O C O L O   C E R O",22,RED,true)
	add_text("El hangar dejó de responder.\nLo que queda adentro ya no es humano.",23,MUTED)
	add_text("SUPERVIVENCIA FPS · OLEADAS INFINITAS",15,MINT,true)
	panel_body.add_child(_button("ENTRAR AL SECTOR  →",func(): game.start_run(),true))
	panel_body.add_child(_button("CONTROLES Y SUPERVIVENCIA",show_controls))
	panel_body.add_child(_button("CONFIGURACIÓN",show_settings))
	panel_body.add_child(_button("CRÉDITOS DE RECURSOS",show_credits))
	add_text("18+ · Violencia gráfica ficticia, sangre y horror.\nPrototipo personal · mapa con licencia no comercial.",15,MUTED)
	add_text("RÉCORD  /  %02d oleadas · %d bajas" % [game.record.wave,game.record.kills],16,AMBER,true)

func show_controls() -> void:
	clear_panel(); add_text("MANUAL DE CAMPO",40,PAPER,true)
	add_text("W A S D  Moverse    ·    RATÓN  Apuntar\nSHIFT  Correr    ·    ESPACIO  Saltar\nCLIC IZQ.  Atacar    ·    CLIC DER.  Apuntar\nR  Recargar    ·    E  Recoger / abrir caja\n1 / 2 / 3  Equipar    ·    Q  Arma anterior\nF  Linterna    ·    G  Granada    ·    ESC  Pausa",21)
	add_text("TRES RANURAS. NINGUNA RED DE SEGURIDAD.",18,MINT,true)
	add_text("La ranura 1 solo admite melee. La pistola y la tercera arma pueden cambiarse por cualquier arma de fuego. La caja aparece en una única plataforma y tarda 75 s en reponerse.",19,MUTED)
	add_text("Los golpes tienen inercia, empuje y resistencia por masa. Destruí cristales, tabiques y barriles; las explosiones también te alcanzan. Entre oleadas recuperás 12 de salud.",19,MUTED)
	panel_body.add_child(_button("VOLVER",show_menu,true))

func show_settings() -> void:
	clear_panel(); add_text("CONFIGURACIÓN",40,PAPER,true)
	gore_check=CheckButton.new(); gore_check.text="Sangre y efectos gráficos"; gore_check.button_pressed=game.settings.gore; gore_check.add_theme_font_override("font",_font(20)); gore_check.toggled.connect(func(v): game.settings.gore=v; game.apply_settings()); panel_body.add_child(gore_check)
	shake_check=CheckButton.new(); shake_check.text="Sacudida de cámara e impactos"; shake_check.button_pressed=game.settings.shake; shake_check.add_theme_font_override("font",_font(20)); shake_check.toggled.connect(func(v): game.settings.shake=v; game.apply_settings()); panel_body.add_child(shake_check)
	add_text("SENSIBILIDAD DEL RATÓN",16,MINT,true)
	var sens:=HSlider.new(); sens.min_value=0.3; sens.max_value=2.5; sens.step=0.1; sens.value=game.settings.sensitivity; sens.value_changed.connect(func(v): game.settings.sensitivity=v; game.apply_settings()); panel_body.add_child(sens)
	add_text("VOLUMEN GENERAL",16,MINT,true)
	var vol:=HSlider.new(); vol.min_value=0; vol.max_value=1; vol.step=0.05; vol.value=game.settings.volume; vol.value_changed.connect(func(v): game.settings.volume=v; game.apply_settings()); panel_body.add_child(vol)
	add_text("CALIDAD / PRESUPUESTO DE EFECTOS",16,MINT,true)
	var quality:=OptionButton.new(); quality.add_item("Baja · 18 enemigos simultáneos"); quality.add_item("Media · 26 enemigos simultáneos"); quality.selected=0 if game.settings.quality=="low" else 1; quality.add_theme_font_override("font",_font(20)); quality.item_selected.connect(func(i): game.settings.quality="low" if i==0 else "medium"; game.director.max_alive=18 if i==0 else 26; game.apply_settings()); panel_body.add_child(quality)
	add_text("Los cambios se guardan automáticamente. El límite de enemigos no limita la cantidad total de cada oleada.",16,MUTED)
	panel_body.add_child(_button("VOLVER",_settings_back,true))

func _settings_back() -> void:
	if game.state=="paused": show_pause()
	else: show_menu()

func show_credits() -> void:
	clear_panel(); add_text("RECURSOS Y AUTORES",36,PAPER,true)
	add_text("Mapa: Abandoned Spaceship\nJaanus Jaggo / Perfoon · CC BY-NC 4.0\nTexturas originales reducidas para este prototipo.",20,MINT)
	add_text("Enemigos y armas adicionales: Quaternius\nZombie Apocalypse Kit · CC0\nArmas, partículas y sonidos: Kenney\nWeapon Pack, Particle Pack, audio · CC0",20,PAPER)
	add_text("Voces de criaturas: artisticdude\nImpactos y ambiente: rubberduck / qubodup\nFuentes: Barlow Condensed · Jeremy Tribby · OFL",19,MUTED)
	add_text("Motor: Godot · MIT\nInventario completo, fuentes y licencias:\ndocs/THIRD_PARTY_NOTICES.md",17,MUTED)
	add_text("El uso personal no elimina las licencias. No redistribuir el mapa con fines comerciales sin permiso de su autor.",16,AMBER)
	panel_body.add_child(_button("VOLVER",show_menu,true))

func show_pause() -> void:
	clear_panel(); add_text("SEÑAL EN PAUSA",43,PAPER,true)
	add_text("Oleada %02d  ·  %d bajas  ·  %s" % [game.director.wave,game.stats.kills,_time()],22,MINT)
	panel_body.add_child(_button("REANUDAR",func(): game.pause_game(),true))
	panel_body.add_child(_button("CONFIGURACIÓN",show_settings))
	panel_body.add_child(_button("REINICIAR PARTIDA",func(): game.restart()))
	panel_body.add_child(_button("VOLVER AL MENÚ",func(): game.to_menu()))
	add_text("WASD moverse · E interactuar · R recargar\n1 melee · 2 pistola / arma · 3 tercera arma",18,MUTED)

func show_death() -> void:
	clear_panel(); add_text("SEÑAL PERDIDA",57,RED,true)
	add_text("El sector sigue en cuarentena.",23,MUTED)
	add_text("%02d" % game.director.wave,76,PAPER,true)
	add_text("OLEADA ALCANZADA",17,MINT,true)
	add_text("%d bajas  ·  %d puntos  ·  %s\n%d oleadas completadas" % [game.stats.kills,game.stats.score,_time(),game.stats.waves_cleared],23,PAPER)
	panel_body.add_child(_button("VOLVER A INTENTAR",func(): game.restart(),true))
	panel_body.add_child(_button("MENÚ PRINCIPAL",func(): game.to_menu()))

func show_loot(id: String) -> void:
	offered=id; game.open_loot(); gameplay.visible=false; clear_panel()
	var w:Dictionary=game.catalog.weapon(id)
	add_text("SUMINISTRO RECUPERADO",16,MINT,true)
	add_text(String(w.name).to_upper(),39,PAPER,true)
	add_text(game.catalog.category(id),18,AMBER,true)
	add_text("DAÑO  %s    ·    CARGADOR  %s\nCADENCIA  %.2f s    ·    ALCANCE  %.0f m" % [str(w.damage)+(" ×"+str(w.pellets) if int(w.pellets)>1 else ""),str(w.mag) if w.kind!="melee" else "∞",w.rate,w.range],22)
	add_text("Elegí qué reemplazar. Solo conservás tres armas. Cancelar descarta el hallazgo.",19,MUTED)
	for i in range(3):
		if game.catalog.compatible(i,id):
			var old:String=game.player.slots[i].id
			var text:="[%d] REEMPLAZAR %s" % [i+1,String(game.catalog.weapon(old).name).to_upper() if not old.is_empty() else "RANURA VACÍA"]
			panel_body.add_child(_button(text,func(): _choose(i),i==2 or (i==1 and String(game.player.slots[2].id).is_empty())))
	panel_body.add_child(_button("DEJAR EL ARMA",cancel_loot))

func _choose(index: int) -> void:
	if game.player.replace_slot(index,offered):
		game.audio.play_ui("pickup"); offered=""; game.close_loot(); toast("Arma equipada en la ranura %d." % [index+1])

func cancel_loot() -> void:
	offered=""; game.close_loot()

func show_gameplay() -> void:
	panel.visible=false; gameplay.visible=true; refresh_inventory()

func hide_panels() -> void:
	panel.visible=false; gameplay.visible=true

func refresh_inventory() -> void:
	var signature:=str(game.player.slots)+str(game.player.slot)
	if signature==inventory_signature: return
	inventory_signature=signature
	for i in range(3):
		if slot_labels.size()<=i: return
		var id:String=game.player.slots[i].id
		slot_labels[i].text="[%d]  %s" % [i+1,String(game.catalog.weapon(id).name).to_upper() if not id.is_empty() else "RANURA VACÍA"]
		slot_panels[i].add_theme_stylebox_override("panel",_style(Color(0.07,0.13,0.12,0.95) if i==game.player.slot else INK,MINT if i==game.player.slot else Color(0.2,0.28,0.26)))

func banner(title: String,subtitle: String,duration: float=3.0) -> void:
	banner_title.text=title; banner_sub.text=subtitle; banner_time=duration

func toast(text: String) -> void:
	toast_text.text=text; toast_time=4.0

func _time() -> String:
	return "%02d:%02d" % [int(game.stats.time)/60,int(game.stats.time)%60]

func _process(delta: float) -> void:
	if not game or not game.player or not health: return
	health.value=game.player.hp; stamina.value=game.player.stamina
	health_text.text="INTEGRIDAD  %03d" % ceili(game.player.hp)
	var w:Dictionary=game.player.weapon(); var item:Dictionary=game.player.current()
	weapon_name.text=String(w.name).to_upper()
	if game.player.reload_left>0: ammo.text="RECARGANDO"
	elif w.kind=="melee": ammo.text="∞  /  MELEE"
	elif String(item.id).is_empty(): ammo.text="—"
	else: ammo.text="%02d / %03d" % [item.mag,item.reserve]
	ammo.add_theme_font_size_override("font_size",30 if game.player.reload_left>0 else 48)
	wave_text.text="OLEADA %02d" % maxi(1,game.director.wave)
	enemy_text.text="%d HOSTILES  ·  %d EN CAMINO" % [game.director.alive,game.director.pending] if game.director.active else "RESPIRO  ·  %02d s" % ceili(maxf(0,game.director.intermission))
	timer_text.text="%s  /  %d BAJAS" % [_time(),game.stats.kills]
	fps.text="%d FPS  ·  %d OBJETOS" % [Engine.get_frames_per_second(),get_tree().get_node_count()]
	objective.text="SUMINISTRO  ·  %.0f m  ↗" % game.player.global_position.distance_to(game.world.crate_anchor) if is_instance_valid(game.director.crate) else "SUMINISTRO  ·  REPONIENDO %02d s" % ceili(maxf(0,game.director.crate_cooldown))
	var near:Node3D=game.director.nearest_interactable() if game.is_playing() else null
	prompt.text="[ E ]  ABRIR SUMINISTRO" if near and near.kind=="weapon" else ("[ E ]  RECOGER MUNICIÓN" if near else "")
	toast_time-=delta; toast_text.modulate.a=clampf(toast_time,0,1)
	banner_time-=delta; banner_title.modulate.a=clampf(banner_time,0,1); banner_sub.modulate.a=clampf(banner_time,0,1)
	hit_marker.modulate.a=clampf(game.player.hit_flash*5,0,1); hit_marker.text="×" if not headshot else "◇"
	damage_overlay.color.a=game.player.hurt_flash*0.27+(0.08 if game.player.hp<25 else 0.0)
	refresh_inventory()
