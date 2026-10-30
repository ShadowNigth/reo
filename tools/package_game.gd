extends SceneTree
## Packages the raw-resource runtime build. No generated art or editor cache.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var source := ProjectSettings.globalize_path("res://")
	var output := args[0] if not args.is_empty() else "umbral.pck"
	var packer := PCKPacker.new()
	var err := packer.pck_start(output)
	if err != OK: quit(1); return
	var count := [0]
	_add_dir(packer,source,"",count)
	packer.add_file("res://.godot/global_script_class_cache.cfg",source.path_join(".godot/global_script_class_cache.cfg")); count[0]+=1
	err = packer.flush(false)
	print("UMBRAL_PACKED files=",count," error=",err," output=",output)
	quit(err)

func _add_dir(packer: PCKPacker,root: String,relative: String,count: Array) -> void:
	var folder := root.path_join(relative)
	var dir := DirAccess.open(folder)
	if dir == null: return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name.begins_with("."): name=dir.get_next(); continue
		var rel := relative.path_join(name)
		if dir.current_is_dir(): _add_dir(packer,root,rel,count)
		elif not name.ends_with(".import") and not name.ends_with(".uid"):
			packer.add_file("res://"+rel,folder.path_join(name)); count[0]+=1
		name=dir.get_next()
	dir.list_dir_end()
