extends Node
## Loads original downloaded files directly: the game also runs without an editor import pass.
var models: Dictionary = {}
var textures: Dictionary = {}
var sounds: Dictionary = {}
var materials: Dictionary = {}
var font: FontFile
var bold: FontFile

func _ready() -> void:
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://assets/fonts/BarlowCondensed-Regular.ttf")
	bold = FontFile.new()
	bold.data = FileAccess.get_file_as_bytes("res://assets/fonts/BarlowCondensed-Bold.ttf")
	for key in ["concrete", "metal", "ground"]:
		var m := StandardMaterial3D.new()
		m.albedo_texture = texture("res://assets/world/%s_albedo.jpg" % key)
		m.normal_enabled = true
		m.normal_texture = texture("res://assets/world/%s_normal.jpg" % key)
		m.normal_scale = 0.65
		m.metallic = 0.65 if key == "metal" else 0.0
		m.roughness = 0.68 if key == "metal" else 0.94
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		materials[key] = m
	var leaves := StandardMaterial3D.new()
	leaves.albedo_texture = texture("res://assets/world/vegetation_albedo.png")
	leaves.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaves.alpha_scissor_threshold = 0.4
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.roughness = 0.95
	materials["vegetation"] = leaves

func texture(path: String) -> Texture2D:
	if textures.has(path): return textures[path]
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	var err := image.load_jpg_from_buffer(bytes) if path.ends_with(".jpg") else image.load_png_from_buffer(bytes)
	if err != OK:
		push_error("Texture missing: " + path)
		return null
	var tex := ImageTexture.create_from_image(image)
	textures[path] = tex
	return tex

func model(path: String) -> PackedScene:
	if models.has(path): return models[path]
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_buffer(FileAccess.get_file_as_bytes(path), "", state)
	if err != OK:
		push_error("Model missing: %s (%s)" % [path, err])
		return null
	var scene := doc.generate_scene(state)
	var packed := PackedScene.new()
	packed.pack(scene)
	scene.free()
	models[path] = packed
	return packed

func instance(path: String) -> Node3D:
	var packed := model(path)
	return packed.instantiate() if packed else Node3D.new()

func sound(path: String) -> AudioStream:
	if sounds.has(path): return sounds[path]
	var bytes := FileAccess.get_file_as_bytes(path)
	var stream: AudioStream
	if path.ends_with(".ogg"): stream = AudioStreamOggVorbis.load_from_buffer(bytes)
	elif path.ends_with(".wav"): stream = AudioStreamWAV.load_from_buffer(bytes)
	if stream: sounds[path] = stream
	return stream

func random_sound(prefix: String, folder: String = "res://assets/audio/") -> AudioStream:
	if not sounds.has("_listing_" + folder):
		var list := []
		for f in DirAccess.get_files_at(folder):
			if not f.ends_with(".import"): list.append(f)
		sounds["_listing_" + folder] = list
	var candidates: Array = []
	for f in sounds["_listing_" + folder]:
		if f.begins_with(prefix) and (f.ends_with(".ogg") or f.ends_with(".wav")): candidates.append(folder + f)
	return sound(candidates.pick_random()) if not candidates.is_empty() else null

func material(color: Color, emission: float = 0.0, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.65
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func mesh_library(path: String) -> Dictionary:
	var root := instance(path)
	var result := {}
	_collect_meshes(root, result)
	root.free()
	return result

func _collect_meshes(n: Node, result: Dictionary) -> void:
	if n is MeshInstance3D and n.mesh:
		result[String(n.name).get_file()] = n.mesh
	for c in n.get_children(): _collect_meshes(c, result)
