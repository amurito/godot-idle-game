extends Node

var TITLE: String:
	get: return "AntiIDLE — v" + get_version_string()
var VERSION: String:
	get: return get_version_string()
const NAME := "génesis"

const MAJOR := 1
const MINOR := 0
const PATCH := 0
const HOTFIX := 10  # Incrementar para hotfixes: 1.0.0.1, 1.0.0.2, etc.


func get_env(var_name: String) -> String:
	if OS.has_feature("pc"):
		if OS.has_environment(var_name):
			return OS.get_environment(var_name)

	return ""
const BUILD := "dev"
const COMMIT := "local"


func get_version_string() -> String:
	if HOTFIX > 0:
		return "%d.%d.%d.%d-%s" % [MAJOR, MINOR, PATCH, HOTFIX, NAME]
	return "%d.%d.%d-%s" % [MAJOR, MINOR, PATCH, NAME]


func get_build_label() -> String:
	return "%s | build %s | %s" % [
		get_version_string(),
		BUILD,
		COMMIT
	]
