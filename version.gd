extends Node

const TITLE := "IDLE Antigravity — v0.9.0"
const VERSION := "0.9.0"
const NAME := "Era Alostática"

const MAJOR := 0
const MINOR := 9
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
