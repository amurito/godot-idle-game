extends Node

var unlocked = {}
var mu_bonus := 0.0

func unlock(node_id):
	if unlocked.has(node_id):
		return
	
	unlocked[node_id] = true
	
	match node_id:
		"HIFAS":
			mu_bonus += 0.02
