extends Node

# UpgradeManager.gd — Autoload
# Carga las definiciones de mejoras desde res://upgrades/*.tres
# y centraliza la lógica de compra, estado y persistencia.

# =====================================================
#  DEFINICIONES (cargadas desde disco en _ready)
# =====================================================
var _defs: Array = []   # Array de UpgradeDef Resources

func _ready() -> void:
	_load_defs()
	_init_states()

func _load_defs() -> void:
	_defs.clear()
	var dir := DirAccess.open("res://upgrades")
	if dir == null:
		push_error("UpgradeManager: no se pudo abrir res://upgrades/")
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res = ResourceLoader.load("res://upgrades/" + fname)
			if res and res is UpgradeDef:
				_defs.append(res)
		fname = dir.get_next()
	dir.list_dir_end()

# =====================================================
#  ESTADO RUNTIME
# =====================================================
# id → { level, current_cost, current_value, unlocked }
var states: Dictionary = {}

func _init_states() -> void:
	for def in _defs:
		states[def.id] = {
			"level": 0,
			"current_cost": def.base_cost,
			"current_value": def.base_value,
			"unlocked": def.unlock_requires == ""
		}

func reset() -> void:
	_init_states()

# =====================================================
#  API PÚBLICA
# =====================================================
func get_def(id: String) -> UpgradeDef:
	for def in _defs:
		if def.id == id:
			return def
	return null

func get_state(id: String) -> Dictionary:
	return states.get(id, {})

func can_buy(id: String, money: float) -> bool:
	var s = states.get(id, {})
	if s.is_empty(): return false
	var def = get_def(id)
	if def == null: return false
	if def.one_shot and s.level > 0: return false
	return money >= s.current_cost and s.unlocked

## Compra la mejora. Devuelve true si fue exitosa.
## Pasar money ANTES de restar el costo.
func buy(id: String, money: float) -> bool:
	if not can_buy(id, money):
		return false

	var s = states[id]
	var def = get_def(id)

	s.level += 1

	if def.is_multiplicative:
		s.current_value *= def.gain
	else:
		s.current_value += def.gain

	s.current_cost *= def.cost_scale

	# Desbloquear dependientes
	for other in _defs:
		if other.unlock_requires == id:
			states[other.id].unlocked = true

	return true

## Costo actual del upgrade (para mostrar en botón)
func cost(id: String) -> float:
	return states.get(id, {}).get("current_cost", 0.0)

## Valor actual (click_value, income_per_second, etc.)
func value(id: String) -> float:
	return states.get(id, {}).get("current_value", 0.0)

## Nivel actual
func level(id: String) -> int:
	return states.get(id, {}).get("level", 0)

## ¿Está desbloqueado?
func is_unlocked(id: String) -> bool:
	return states.get(id, {}).get("unlocked", false)

# =====================================================
#  SAVE / LOAD
# =====================================================
func serialize() -> Dictionary:
	var out := {}
	for id in states:
		out[id] = states[id].duplicate()
	return out

func deserialize(d: Dictionary) -> void:
	for id in d:
		if states.has(id):
			var s = d[id]
			states[id].level = s.get("level", 0)
			states[id].current_cost = s.get("current_cost", states[id].current_cost)
			states[id].current_value = s.get("current_value", states[id].current_value)
			states[id].unlocked = s.get("unlocked", states[id].unlocked)
