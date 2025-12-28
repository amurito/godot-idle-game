extends Node

const TITLE := "IDLE — The Lab"

const MAJOR := 0
const MINOR := 5
const PATCH := 1
const NAME := "TheLab"

func _get_env(name: String, fallback: String) -> String:
	if OS.has_feature("pc"):
		if OS.has_environment(name):
			return OS.get_environment(name)

	return fallback
	
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
