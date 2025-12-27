extends Node

const VERSION := "v0.5.1"
const CODENAME := "TheLab"
const CYCLE := "Persistence"
const BUILD_ID := "001"
const COMMIT_TAG := "pre-fn"

func get_full_title() -> String:
	return "IDLE — %s %s (%s #%s, %s)" % [
		CODENAME,
		VERSION,
		CYCLE,
		BUILD_ID,
		COMMIT_TAG
	]
