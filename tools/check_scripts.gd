extends SceneTree
## Compiles every project script (addons excluded) and exits with code 1 if
## any fail. Catches parse and typing errors that a test run can hide.
##   godot --headless --path . --script res://tools/check_scripts.gd

var _failed: Array[String] = []


func _initialize() -> void:
	var count := _check_dir("res://")
	if _failed.is_empty():
		print("check_scripts: %d scripts OK" % count)
		quit(0)
	else:
		printerr("check_scripts: %d failed: %s" % [_failed.size(), ", ".join(_failed)])
		quit(1)


func _check_dir(path: String) -> int:
	var count := 0
	var dir := DirAccess.open(path)
	for sub in dir.get_directories():
		if sub.begins_with(".") or (path == "res://" and sub == "addons"):
			continue
		count += _check_dir(path.path_join(sub))
	for file in dir.get_files():
		if file.get_extension() != "gd":
			continue
		var full := path.path_join(file)
		count += 1
		var script := load(full) as GDScript
		if script == null or not script.can_instantiate():
			_failed.append(full)
	return count
