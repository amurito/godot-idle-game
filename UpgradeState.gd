extends RefCounted
class_name UpgradeState

# Estado en runtime de una mejora — este sí cambia y se guarda.

var id: String = ""
var level: int = 0
var current_cost: float = 0.0
var current_value: float = 0.0
var unlocked: bool = false

func init_from_def(def: UpgradeDef) -> void:
	id = def.id
	current_cost = def.base_cost
	current_value = def.base_value
	unlocked = def.unlock_requires == ""

func serialize() -> Dictionary:
	return {
		"level": level,
		"current_cost": current_cost,
		"current_value": current_value,
		"unlocked": unlocked
	}

func deserialize(d: Dictionary) -> void:
	level = d.get("level", 0)
	current_cost = d.get("current_cost", current_cost)
	current_value = d.get("current_value", current_value)
	unlocked = d.get("unlocked", unlocked)
