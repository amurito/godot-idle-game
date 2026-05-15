extends Node

const TITLE := "AntiIDLE — v1.0.0"
const VERSION := "1.0.0"
const NAME := "Primera Luz"

const MAJOR := 1
const MINOR := 0
const PATCH := 0


func get_env(var_name: String) -> String:
	if OS.has_feature("pc"):
		if OS.has_environment(var_name):
			return OS.get_environment(var_name)

	return ""
const BUILD := "dev"
const COMMIT := "local"


func get_version_string() -> String:
	return "%s.%s.%s-%s" % [MAJOR, MINOR, PATCH, NAME]


func get_build_label() -> String:
	return "%s | build %s | %s" % [
		get_version_string(),
		BUILD,
		COMMIT
	]
