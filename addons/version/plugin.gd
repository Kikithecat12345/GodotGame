@tool
extends EditorPlugin

var path = "res://BuildVersion.json"
var file
var version

func _enter_tree():
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ)
		version = JSON.parse_string(file.get_as_text())["version"]
		file = null
	updateVersion()

func _build():
	updateVersion()
	return true

func updateVersion():
	ProjectSettings.set_setting("version", version)
	ProjectSettings.save()
	print("Using build version: ", version)
