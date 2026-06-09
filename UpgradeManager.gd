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
	var upgrades_to_load = [
		"accounting.tres",
		"auto.tres",
		"auto_mult.tres",
		"click.tres",
		"click_mult.tres",
		"cognitive.tres",
		"persistence.tres",
		"specialization.tres",
		"trueque.tres",
		"trueque_allo.tres",
		"trueque_net.tres"
	]
	
	for fname in upgrades_to_load:
		var path = "res://upgrades/" + fname
		if ResourceLoader.exists(path):
			var res = ResourceLoader.load(path)
			if res and res is UpgradeDef:
				_defs.append(res)
		else:
			push_error("UpgradeManager: No se encontró " + path)

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

## Suma de niveles de todos los upgrades (0 = run sin ninguna compra).
func total_levels() -> int:
	var total := 0
	for id in states:
		total += int(states[id].get("level", 0))
	return total

func can_buy(id: String, money: float) -> bool:
	var s = states.get(id, {})
	if s.is_empty(): return false
	var def = get_def(id)
	if def == null: return false
	if def.one_shot and s.level > 0: return false

	# MET.OSCURO: upgrades bloqueados (bioquímica reemplazó la infraestructura).
	# EXCEPCIÓN — Autofagia Necrótica: las compras se reabren para REALIMENTAR la autofagia
	# (el devour da burst proporcional al costo → recomprás material para extender la run).
	# EXCEPCIÓN — Necrosis Controlada: compras reabiertas (necesitás el motor económico real
	# que genera Necromasa para comprar Agentes y empujar Ω al floor).
	if EvoManager.mutation_met_oscuro and not EvoManager.mutation_autolisis and not EvoManager.mutation_necrosis:
		return false

	# Usa cost() que aplica todos los descuentos (memoria_recurso, memoria_estructural, presión_rentable)
	var real_cost := cost(id)

	return money >= real_cost and s.unlocked

## Compra la mejora. Devuelve true si fue exitosa.
## Pasar money ANTES de restar el costo.
func buy(id: String, money: float) -> bool:
	if not can_buy(id, money):
		return false

	var s = states[id]
	var def = get_def(id)

	s.level += 1
	AudioManager.play_sfx("upgrade")
	TutorialManager.notify_upgrade_bought()

	if def.is_multiplicative:
		s.current_value *= def.gain
	else:
		s.current_value += def.gain

	# LEGADO: Deflación (Reducir escalado de costos un 5%)
	var effective_cost_scale = def.cost_scale
	if LegacyManager.get_buff_value("deflacion"):
		# Reduce el componente inflacionario (el excedente sobre 1.0)
		effective_cost_scale = 1.0 + (def.cost_scale - 1.0) * 0.95
		
	# SUBSIDIO HOMEOSTASIS (v0.8.7)
	# Si estamos en Homeostasis, la Contabilidad es más fácil de escalar.
	if id == "accounting" and EvoManager.mutation_homeostasis:
		effective_cost_scale = 1.0 + (effective_cost_scale - 1.0) * 0.8
		print("⚖️ Subsidio Homeostasis aplicado a Contabilidad")

	# DEFLACIÓN CÓSMICA (Banco Cósmico T1): -8% adicional al escalado
	if LegacyManager.has_cosmic_buff("deflacion_cosmica"):
		effective_cost_scale = 1.0 + (effective_cost_scale - 1.0) * 0.92

	# REENCARNACIÓN HEREDADA: deuda del ciclo anterior encarece el escalado ×1.5
	if RouteManager.is_active("reencarnacion"):
		effective_cost_scale *= 1.5

	s.current_cost *= effective_cost_scale

	# Desbloquear dependientes
	for other in _defs:
		if other.unlock_requires == id:
			states[other.id].unlocked = true

	# Notificar logros
	AchievementManager.on_upgrade_bought(id)
	TelemetryManager.track_event("upgrade_bought", {
		"upgrade_id": id,
		"new_level": int(s.level)
	})

	return true

## Costo actual del upgrade (para mostrar en botón y validar compra)
func cost(id: String) -> float:
	var s = states.get(id, {})
	if s.is_empty(): return 0.0

	# LEGADO: Visualizar costo 0 en nivel 0 si aplica
	if s.level == 0 and LegacyManager.get_buff_value("memoria_recurso"):
		return 0.0

	# CÓSMICO: primeras 2 compras de cada upgrade gratuitas (nivel 0 y 1)
	if s.level <= 1 and LegacyManager.has_cosmic_buff("memoria_recurso_cosmica"):
		return 0.0

	var base_cost :float = s.get("current_cost", 0.0)

	# MEMORIA ESTRUCTURAL: -5% por nivel para upgrades estructurales
	const STRUCTURAL_IDS := ["auto", "auto_mult", "trueque", "trueque_net", "trueque_allo",
							 "cognitive", "accounting", "specialization"]
	if id in STRUCTURAL_IDS:
		var cost_reduction := LegacyManager.get_effect_value("structural_cost_reduction")
		if cost_reduction > 0.0:
			base_cost *= (1.0 - cost_reduction)

	# PRESIÓN RENTABLE: -20% para upgrades de click cuando ε > 0.50
	const CLICK_IDS := ["click", "click_mult"]
	if id in CLICK_IDS and LegacyManager.get_buff_value("presion_rentable"):
		if StructuralModel.epsilon_runtime > 0.50:
			var discount := LegacyManager.get_effect_value("click_upgrade_discount_when_epsilon")
			if discount > 0.0:
				base_cost *= discount  # 0.80 = paga solo el 80%

	# NUTRIENTES: red fúngica subsidia upgrades — hasta -15% con nutrientes >= 50
	var nut := BiosphereEngine.nutrientes
	if nut > 0.0:
		base_cost *= (1.0 - clamp(nut / 50.0, 0.0, 0.15))

	return base_cost

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

## Reencarnación Heredada: aplica los niveles del ciclo anterior.
## El costo actual se escala ×1.5^level como "deuda" por el avance heredado.
func apply_reencarnacion_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	for id in snapshot:
		if not states.has(id):
			continue
		var snap = snapshot[id]
		var lvl: int = int(snap.get("level", 0))
		if lvl <= 0:
			continue
		var def = get_def(id)
		if def == null:
			continue
		var s = states[id]
		s.level = lvl
		s.unlocked = true
		# Recalcular valor desde base
		s.current_value = def.base_value
		if def.is_multiplicative:
			for i in range(lvl): s.current_value *= def.gain
		else:
			s.current_value = def.base_value + def.gain * lvl
		# Costo escalado con deuda de reencarnación (×1.5^lvl extra sobre base)
		s.current_cost = def.base_cost * pow(def.cost_scale, lvl) * pow(1.5, lvl)
	print("⚱️ [UpgradeManager] Snapshot de reencarnación aplicado")

# =====================================================
#  COMPRA DE UPGRADES — con efectos post-compra y signal
# =====================================================
signal upgrade_bought(id: String)

func purchase_upgrade(id: String) -> void:
	var c := cost(id)
	if EconomyManager.money >= c:
		if buy(id, EconomyManager.money):
			EconomyManager.money -= c
			LogManager.add("Comprado: " + get_def(id).label)
			apply_bought_effects(id)
			upgrade_bought.emit(id)

func apply_bought_effects(id: String) -> void:
	StructuralModel.structural_cooldown = StructuralModel.STRUCTURAL_COOLDOWN_TIME
	match id:
		"auto":
			if not StructuralModel.unlocked_d:
				StructuralModel.unlocked_d = true
				LogManager.add("Desbloqueado d (Trabajo Manual)")
		"auto_mult":
			if not StructuralModel.unlocked_md:
				StructuralModel.unlocked_md = true
				LogManager.add("Desbloqueado md (Ritmo de Trabajo)")
		"trueque":
			if not StructuralModel.unlocked_e:
				StructuralModel.unlocked_e = true
				LogManager.add("Desbloqueado e (Trueque)")
		"trueque_net":
			if not StructuralModel.unlocked_me:
				StructuralModel.unlocked_me = true
				LogManager.add("Desbloqueado me (Red de Intercambio)")
		"specialization":
			if level("specialization") == 1:
				LogManager.add("Especializacion de Oficio Activa")
		"cognitive":
			pass
		"persistence":
			StructuralModel.persistence_base = value("persistence")
			if not StructuralModel.persistence_upgrade_unlocked:
				StructuralModel.persistence_upgrade_unlocked = true
				LogManager.add("Memoria Operativa: c0 incrementado un 25% (1.75)")
		"accounting":
			if level("accounting") == 1:
				StructuralModel.omega = max(StructuralModel.omega, 0.45)
				StructuralModel.omega_min = max(StructuralModel.omega_min, 0.45)
				StructuralModel.institution_accounting_unlocked = true
				LogManager.add("Institucion desbloqueada — arquitectura reorganizada")
			StructuralModel.epsilon_runtime *= 0.85
			StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak * 0.9, StructuralModel.epsilon_runtime)

## Devuelve cuántos niveles de upgrades están comprados en total.
func get_owned_levels_count() -> int:
	var total: int = 0
	for k in states.keys():
		total += states[k].level
	return total

## Devora el upgrade con mayor current_cost (el más caro actualmente).
## Retorna {devoured: bool, cost: float} — cost = precio del nivel devorado.
func devour_most_expensive_upgrade() -> Dictionary:
	var best_key: String = ""
	var best_cost: float = -1.0
	for k in states.keys():
		var s = states[k]
		if s.level > 0 and s.current_cost > best_cost:
			best_cost = s.current_cost
			best_key = k
	if best_key.is_empty():
		return {"devoured": false, "cost": 0.0}
	var s = states[best_key]
	var def = get_def(best_key)
	var devoured_cost: float = s.current_cost
	s.level -= 1
	s.current_value = def.base_value
	if def.is_multiplicative:
		for i in range(s.level):
			s.current_value *= def.gain
	else:
		s.current_value += def.gain * s.level
	var effective_cost_scale: float = def.cost_scale
	if LegacyManager.get_buff_value("deflacion"):
		effective_cost_scale = 1.0 + (def.cost_scale - 1.0) * 0.95
	s.current_cost /= effective_cost_scale
	return {"devoured": true, "cost": devoured_cost}

func devour_random_upgrade() -> bool:
	var valid_keys = []
	for k in states.keys():
		if states[k].level > 0:
			valid_keys.append(k)
	
	if valid_keys.is_empty():
		return false
		
	var target = valid_keys[randi() % valid_keys.size()]
	var s = states[target]
	var def = get_def(target)
	
	s.level -= 1
	
	# Recalcular desde la base para evitar drift
	s.current_value = def.base_value
	if def.is_multiplicative:
		for i in range(s.level): s.current_value *= def.gain
	else:
		s.current_value += def.gain * s.level

	var effective_cost_scale = def.cost_scale
	if LegacyManager.get_buff_value("deflacion"):
		# Reduce el componente inflacionario
		effective_cost_scale = 1.0 + (def.cost_scale - 1.0) * 0.95

	s.current_cost /= effective_cost_scale
	return true
