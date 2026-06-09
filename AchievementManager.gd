extends Node

# AchievementManager.gd — Autoload (v1.0.0.10)
# Catálogo de logros en 5 tiers (MICELIO/ESPORA/FRUTO/ANCESTRAL/MYTHIC). Arquitectura híbrida:
#   push_snapshot(dict)  → estado del mundo cada tick
#   push_event(name, {}) → eventos puntuales
#   CUSTOM_EVALUATORS    → lógica compleja con nombre
#   unlocked → {id: {unlocked_at, seen}}  (persistente, legacy_bank.json)
#   _progress → {id: float}              (efímero, per-run)
#   _timers   → {id: float}              (efímero, sustained checks)

signal achievement_unlocked(id: String, def: Dictionary)

# ──────────────────────── TIERS (alias a AchievementDefs) ────────────────────────
# Los callers externos (main.gd, MainMenu.gd) siguen usando AchievementManager.Tier.* sin cambios.
const Tier       = AchievementDefs.Tier
const TIER_NAMES  = AchievementDefs.TIER_NAMES
const TIER_COLORS = AchievementDefs.TIER_COLORS
const TIER_ICONS  = AchievementDefs.TIER_ICONS
const DEFS        = AchievementDefs.DEFS


# ──────────────────────── ESTADO PERSISTENTE ────────────────────────
# id → { "unlocked_at": int (unix timestamp), "seen": bool }
var unlocked: Dictionary = {}

# ──────────────────────── ESTADO EFÍMERO (per-run) ────────────────────────
var main: Node = null
var _toast_layer: CanvasLayer = null
var _toast_container: VBoxContainer = null
var _snapshot: Dictionary = {}          # último push_snapshot recibido

# Progreso de event_count (id → float, se resetea en reset_run_state)
var _progress: Dictionary = {}

# Timers para sustained / custom con duration (id → float segundos)
var _timers: Dictionary = {}

# Tracking per-run
var _run_time: float = 0.0
var _click_count: int = 0
var _clicks_after_minute_one: int = 0
var _upgrades_this_run: int = 0
var _mutations_this_run: int = 0
var _last_dominant: String = ""
var _bought_accounting_this_run: bool = false
var _seta_formed_this_run: bool = false

# IDs de logros con timers custom (duration en DEFS)
const CUSTOM_TIMER_IDS := [
	"latido_cosmico", "entropia_cero",
	"omega_inviolable",
]

# ──────────────────────── INIT ────────────────────────
var CUSTOM_EVALUATORS: Dictionary = {}

func _ready() -> void:
	CUSTOM_EVALUATORS = {
		"umbral_verde":       _eval_umbral_verde,
		"arbol_productivo":   _eval_arbol_productivo,
		"passive_dominance":  _eval_passive_dominance,
		"tension_productiva": _eval_tension_productiva,
		"economia_guerra":    _eval_economia_guerra,
		"parasito_insaciable":_eval_parasito_insaciable,
		# ciclo_completo y micelio_salvaje se desbloquean SOLO desde on_run_closed
		# (sus evaluadores siempre devuelven false — no se registran aquí).
		"latido_cosmico":     _eval_latido_cosmico_cond,
		"tres_vidas_camino":  _eval_tres_vidas_camino,
		"entropia_cero":      _eval_entropia_cero_cond,
		"organismo_total":    _eval_organismo_total,
		"reino_subterraneo":  _eval_reino_subterraneo,
		"ultima_espora":      _eval_ultima_espora,
		"saturacion_total":   _eval_saturacion_total,
		"colapso_depredatorio": _eval_colapso_depredatorio,
		"polimorfia_total":       _eval_polimorfia_total,
		"domador_del_caos":       _eval_domador_del_caos,
		"esclerocio_contingencia":_eval_esclerocio_contingencia,
		"autolisis_perfecta":     _eval_autolisis_perfecta,
		"funcion_pura":           _eval_funcion_pura,
		"cinco_legados":          _eval_cinco_legados,
		"omega_inviolable":       _eval_omega_inviolable_cond,
		"metabolismo_oscuro_pico":_eval_met_oscuro_pico_cond,
		"legado_absoluto":        _eval_legado_absoluto,
		"dios_de_las_moscas":     _eval_dios_de_las_moscas,
	}
	_init_timers()

func _init_timers() -> void:
	for id in DEFS:
		var def: Dictionary = DEFS[id]
		if def.get("trigger") in ["sustained", "sustained_between"] \
				or (def.get("trigger") == "custom" and def.has("duration")):
			_timers[id] = 0.0

func set_main(m: Node) -> void:
	main = m

# ──────────────────────── API PUSH ────────────────────────

func push_snapshot(data: Dictionary) -> void:
	_snapshot = data

func push_event(event_name: String, payload: Dictionary = {}) -> void:
	if RunManager.run_closed and event_name != "run_closed":
		return
	for id in DEFS:
		if is_unlocked(id): continue
		var def: Dictionary = DEFS[id]
		if def.get("trigger") == "event" and def.get("event_name") == event_name:
			if _check_conditions(def.get("conditions", []), payload):
				unlock(id)
		elif def.get("trigger") == "event_count" and def.get("event_name") == event_name:
			_progress[id] = _progress.get(id, 0.0) + 1.0
			if _progress[id] >= float(def.get("target", 1)):
				unlock(id)

# ──────────────────────── API PÚBLICA ────────────────────────

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func unlock(id: String) -> void:
	if not DEFS.has(id):
		push_warning("[Achievements] id desconocido: %s" % id)
		return
	if is_unlocked(id):
		return
	unlocked[id] = {
		"unlocked_at": int(Time.get_unix_time_from_system()),
		"seen": false,
	}
	var def: Dictionary = DEFS[id]
	emit_signal("achievement_unlocked", id, def)
	AudioManager.play_sfx("achievement")
	_show_toast(id, def)
	if main:
		LogManager.add("🏁 Logro — " + def["name"])
	LegacyManager.save_achievement_data(unlocked)
	_check_meta_achievements()

func mark_seen(id: String) -> void:
	if unlocked.has(id):
		unlocked[id]["seen"] = true

func get_all_ids() -> Array:
	return DEFS.keys()

func get_by_tier(tier: int) -> Array:
	var out: Array = []
	for id in DEFS.keys():
		if DEFS[id]["tier"] == tier:
			out.append(id)
	return out

func total_count() -> int:
	return DEFS.size()

func unlocked_count() -> int:
	# Contar solo logros que existen en DEFS. El dict `unlocked` puede tener IDs
	# huérfanos de versiones viejas (logros renombrados/removidos persistidos en
	# legacy_bank.json) que inflarían el header "X / Y" por encima del real.
	var c := 0
	for id in unlocked:
		if DEFS.has(id): c += 1
	return c

func get_progress(id: String) -> Dictionary:
	if not DEFS.has(id):
		return {"current": 0.0, "target": 1.0, "ratio": 0.0}
	if is_unlocked(id):
		var t: float = float((DEFS[id] as Dictionary).get("target", 1))
		return {"current": t, "target": t, "ratio": 1.0}
	var def: Dictionary = DEFS[id]
	var current: float = _progress.get(id, 0.0)
	# For disturbance_streak: read from RunManager
	if id == "arquitecto_caos":
		current = float(RunManager.disturbances_without_reset)
	# For dios_de_las_moscas: count endings achieved out of ALL_ENDINGS
	elif id == "dios_de_las_moscas":
		var count := 0
		for route in ALL_ENDINGS:
			if LegacyManager.endings_achieved.get(route, false):
				count += 1
		current = float(count)
	# For reino_subterraneo: count unlocked MICELIO+ESPORA+FRUTO achievements (target is dynamic)
	elif id == "reino_subterraneo":
		var _uc := 0
		var _tc := 0
		for aid in DEFS:
			var adef: Dictionary = DEFS[aid]
			if adef["tier"] == Tier.ANCESTRAL or adef["tier"] == Tier.MYTHIC: continue
			_tc += 1
			if is_unlocked(aid): _uc += 1
		current = float(_uc)
		var ratio_rs := clampf(current / float(_tc), 0.0, 1.0) if _tc > 0 else 0.0
		return {"current": current, "target": float(_tc), "ratio": ratio_rs}
	var target: float = float(def.get("target", 1))
	var ratio := clampf(current / target, 0.0, 1.0) if target > 0.0 else 0.0
	return {"current": current, "target": target, "ratio": ratio}

func get_display_name(id: String) -> String:
	if not DEFS.has(id): return "???"
	var def: Dictionary = DEFS[id]
	if def.get("secret", false) and not is_unlocked(id):
		return tr("ACH_SECRET_NAME")
	return tr("ACH_" + id.to_upper() + "_NAME")

func get_display_desc(id: String) -> String:
	if not DEFS.has(id): return ""
	var def: Dictionary = DEFS[id]
	if def.get("secret", false) and not is_unlocked(id):
		return tr("ACH_SECRET_DESC")
	return tr("ACH_" + id.to_upper() + "_DESC")

func has_unseen() -> bool:
	for id in unlocked:
		if not unlocked[id].get("seen", false):
			return true
	return false

# ──────────────────────── TICK ────────────────────────

func check_tick(delta: float) -> void:
	if not main or RunManager.run_closed:
		return
	_run_time += delta
	_update_dominant_switch()
	_eval_thresholds()
	_eval_sustained(delta)
	_eval_custom_one_shot()
	_eval_custom_timers(delta)

func _update_dominant_switch() -> void:
	var cur: String = _snapshot.get("dominant_term", "")
	if cur == "" or cur == _last_dominant:
		return
	if _last_dominant != "":
		push_event("dominant_switch", {})
	_last_dominant = cur

func _eval_thresholds() -> void:
	for id in DEFS:
		if is_unlocked(id): continue
		var def: Dictionary = DEFS[id]
		if def.get("trigger") != "threshold": continue
		var metric: String = def.get("metric", "")
		var value: float = _snapshot.get(metric, 0.0)
		if value >= float(def.get("target", 0.0)):
			unlock(id)

func _eval_sustained(delta: float) -> void:
	for id in _timers:
		if is_unlocked(id): continue
		var def: Dictionary = DEFS[id]
		var trigger: String = def.get("trigger", "")
		if trigger not in ["sustained", "sustained_between"]:
			continue  # custom timers handled in _eval_custom_timers
		var active := false
		if trigger == "sustained":
			var metric: String = def.get("metric", "")
			var value: float = _snapshot.get(metric, 0.0)
			active = _eval_op(value, def.get("op", ">="), float(def.get("target", 0.0)))
		else:  # sustained_between
			var metric: String = def.get("metric", "")
			var value: float = _snapshot.get(metric, 0.0)
			active = value >= float(def.get("min", 0.0)) and value <= float(def.get("max", 1.0))
		if active:
			_timers[id] += delta
			if _timers[id] >= float(def.get("duration", 60.0)):
				unlock(id)
		else:
			_timers[id] = 0.0

func _eval_custom_one_shot() -> void:
	for id in DEFS:
		if is_unlocked(id): continue
		var def: Dictionary = DEFS[id]
		if def.get("trigger") != "custom": continue
		if def.has("duration"): continue  # manejado en _eval_custom_timers
		var ev: String = def.get("evaluator", "")
		if ev in CUSTOM_EVALUATORS:
			if CUSTOM_EVALUATORS[ev].call(_snapshot):
				unlock(id)

func _eval_custom_timers(delta: float) -> void:
	for id in CUSTOM_TIMER_IDS:
		if is_unlocked(id): continue
		if not _timers.has(id): continue
		var def: Dictionary = DEFS[id]
		var ev: String = def.get("evaluator", "")
		if ev not in CUSTOM_EVALUATORS: continue
		if CUSTOM_EVALUATORS[ev].call(_snapshot):
			_timers[id] += delta
			if _timers[id] >= float(def.get("duration", 60.0)):
				unlock(id)
		else:
			_timers[id] = 0.0

# ──────────────────────── EVALUADOR DE CONDICIONES ────────────────────────

func _check_conditions(conditions: Array, payload: Dictionary) -> bool:
	for cond in conditions:
		var key: String = cond.get("key", "")
		var op: String = cond.get("op", "==")
		var expected = cond.get("value", null)
		var actual = payload.get(key, null)
		if not _eval_condition_value(actual, op, expected):
			return false
	return true

func _eval_condition_value(actual, op: String, expected) -> bool:
	match op:
		"==":  return actual == expected
		"!=":  return actual != expected
		">=":  return float(actual) >= float(expected)
		"<=":  return float(actual) <= float(expected)
		">":   return float(actual) > float(expected)
		"<":   return float(actual) < float(expected)
		"in":
			if expected is Array:
				return actual in expected
			return false
	return false

func _eval_op(value: float, op: String, target: float) -> bool:
	match op:
		">=": return value >= target
		"<=": return value <= target
		">":  return value > target
		"<":  return value < target
		"==": return is_equal_approx(value, target)
	return false

# ──────────────────────── CUSTOM EVALUATORS ────────────────────────

func _eval_umbral_verde(s: Dictionary) -> bool:
	return s.get("biomasa", 0.0) >= 3.0 and s.get("epsilon", 1.0) < 0.30

func _eval_arbol_productivo(_s: Dictionary) -> bool:
	# Eslabones estructurales: d, md, so, e, me
	if not (StructuralModel.unlocked_d and StructuralModel.unlocked_md \
		and UpgradeManager.level("specialization") > 0 \
		and StructuralModel.unlocked_e and StructuralModel.unlocked_me):
		return false
	# Capital cognitivo (μ) + memoria operativa (persistence c₀) + contabilidad
	return UpgradeManager.level("cognitive") > 0 \
		and UpgradeManager.level("persistence") > 0 \
		and UpgradeManager.level("accounting") > 0

func _eval_passive_dominance(_s: Dictionary) -> bool:
	# Requiere haber abierto al menos una pata pasiva (Trabajo Manual o Trueque)
	if not (StructuralModel.unlocked_d or StructuralModel.unlocked_e): return false
	if main == null: return false
	var dom: String = EconomyManager.get_dominant_term()
	return dom == "Trabajo Manual domina el sistema" or dom == "Trueque domina el sistema"

func _eval_tension_productiva(_s: Dictionary) -> bool:
	return EvoManager.genome.get("homeostasis", "dormido") == "latente" \
		and EvoManager.genome.get("red_micelial", "dormido") == "latente"

func _eval_economia_guerra(s: Dictionary) -> bool:
	return EvoManager.mutation_parasitism and s.get("delta_total", 0.0) >= 10000.0

func _eval_parasito_insaciable(s: Dictionary) -> bool:
	return EvoManager.mutation_parasitism and s.get("biomasa", 0.0) >= 20.0

func _eval_ciclo_completo(_s: Dictionary) -> bool:
	# Desbloqueo exclusivo vía on_run_closed (ruta ESPORULACIÓN + _seta_formed_this_run).
	# No se registra en CUSTOM_EVALUATORS — este stub existe solo para referencia.
	return false

func _eval_micelio_salvaje(_s: Dictionary) -> bool:
	# Desbloqueo exclusivo vía on_run_closed (ruta PARASITISMO + sin Contabilidad).
	# No se registra en CUSTOM_EVALUATORS — este stub existe solo para referencia.
	return false

func _eval_latido_cosmico_cond(s: Dictionary) -> bool:
	return s.get("delta_total", 0.0) >= 500.0 \
		and s.get("epsilon", 1.0) < 0.15 \
		and s.get("biomasa", 0.0) >= 5.0

func _eval_tres_vidas_camino(_s: Dictionary) -> bool:
	# Camino tick: concede el logro retroactivamente si el jugador ya tiene los 3 endings
	# (útil en saves migrados o actualizaciones que añadieron este logro después).
	# Camino explícito en on_run_closed: disparo inmediato al cerrar HOMEORHESIS.
	# Ambos caminos son intencionales — unlock() es idempotente.
	return LegacyManager.endings_achieved.get("HOMEOSTASIS", false) \
		and LegacyManager.endings_achieved.get("ALLOSTASIS", false) \
		and LegacyManager.endings_achieved.get("HOMEORHESIS", false)

func _eval_entropia_cero_cond(s: Dictionary) -> bool:
	return s.get("epsilon", 1.0) < 0.05 and s.get("biomasa", 0.0) > 8.0

func _eval_organismo_total(s: Dictionary) -> bool:
	return s.get("biomasa", 0.0) > 10.0 \
		and s.get("k_eff", 0.0) > 1.6 \
		and s.get("epsilon", 1.0) < 0.15

func _eval_reino_subterraneo(_s: Dictionary) -> bool:
	for id in DEFS:
		var def: Dictionary = DEFS[id]
		if def["tier"] == Tier.ANCESTRAL or def["tier"] == Tier.MYTHIC: continue
		if not is_unlocked(id): return false
	return true

func _eval_ultima_espora(_s: Dictionary) -> bool:
	# Fix: excluirse a sí mismo del conteo (antes era inalcanzable por self-reference).
	# Considera todos los demás logros desbloqueados — al unlock del último, este se libera.
	for id in DEFS:
		if id == "ultima_espora": continue
		if not is_unlocked(id): return false
	return true

func _eval_saturacion_total(_s: Dictionary) -> bool:
	# Cerrar MET.OSCURO con biomasa saturada (≥100). Chequea el ESTADO real,
	# no el texto del reason: antes hacía .contains("Saturación Oscura") que fallaba
	# por (a) tilde — el locale es "Saturacion Oscura" sin tilde —, (b) EN "Dark Saturation",
	# y (c) el sello manual usa CLOSE_MO_VOLUNTARIO. Sirve para auto-saturación y sello.
	return RunManager.final_route == "METABOLISMO OSCURO" \
		and BiosphereEngine.biomasa >= 100.0

func _eval_colapso_depredatorio(_s: Dictionary) -> bool:
	return RunManager.final_route == "COLAPSO DEPREDATORIO"

func _eval_polimorfia_total(_s: Dictionary) -> bool:
	return RunManager.final_route == "POLIMORFÍA TOTAL" or RunManager.final_route == "POLIMORFIA TOTAL"

func _eval_domador_del_caos(_s: Dictionary) -> bool:
	return RunManager.final_route == "DOMADOR DEL CAOS"

func _eval_esclerocio_contingencia(_s: Dictionary) -> bool:
	return RunManager.final_route == "ESCLEROCIO OSCURO" \
		and EvoManager.met_oscuro_devoured_count >= 50

func _eval_autolisis_perfecta(_s: Dictionary) -> bool:
	return RunManager.final_route == "AUTOFAGIA NECRÓTICA" \
		and EvoManager.autolisis_devour_count >= 15 \
		and EvoManager.autofagia_speed_level >= Balance.AUTOFAGIA_SPEED_MAX_LEVEL \
		and EvoManager.autofagia_double_level >= Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL

func _eval_funcion_pura(_s: Dictionary) -> bool:
	return RunManager.final_route == "NECROSIS CONTROLADA" \
		and EvoManager.necrosis_active_time <= 75.0 \
		and not EvoManager.necrosis_tox_maxed

func _eval_cinco_legados(_s: Dictionary) -> bool:
	var count := 0
	for id in LegacyManager.LEGACY_DEFS:
		if LegacyManager.get_buff_level(id) > 0:
			count += 1
	return count >= 5

func _eval_omega_inviolable_cond(_s: Dictionary) -> bool:
	return StructuralModel.omega_min >= 0.55 \
		and StructuralModel.omega >= StructuralModel.omega_min

func _eval_met_oscuro_pico_cond(s: Dictionary) -> bool:
	return EvoManager.mutation_met_oscuro and s.get("delta_total", 0.0) >= 50000.0

func _eval_legado_absoluto(_s: Dictionary) -> bool:
	for id in LegacyManager.LEGACY_DEFS:
		if LegacyManager.get_buff_level(id) == 0:
			return false
	return true

const ALL_ENDINGS := [
	"HOMEOSTASIS", "ALLOSTASIS", "HOMEORHESIS",
	"HIPERASIMILACION", "ESPORULACION", "PARASITISMO", "SIMBIOSIS",
	"METABOLISMO OSCURO", "COLAPSO DEPREDATORIO", "DEPREDADOR DE REALIDADES",
	"COLAPSO CONTROLADO",
	"POLIMORFÍA TOTAL", "DOMADOR DEL CAOS", "ASCESIS_PROFUNDA",
	"SINGULARIDAD", "PANSPERMIA NEGRA", "MENTE COLMENA DISTRIBUIDA",
]

func _eval_dios_de_las_moscas(_s: Dictionary) -> bool:
	for route in ALL_ENDINGS:
		if not LegacyManager.endings_achieved.get(route, false):
			return false
	return true

# ──────────────────────── META-ACHIEVEMENTS ────────────────────────

func _check_meta_achievements() -> void:
	if not is_unlocked("cinco_legados") and _eval_cinco_legados({}):
		unlock("cinco_legados")
	if not is_unlocked("legado_absoluto") and _eval_legado_absoluto({}):
		unlock("legado_absoluto")
	if not is_unlocked("dios_de_las_moscas") and _eval_dios_de_las_moscas({}):
		unlock("dios_de_las_moscas")
	if not is_unlocked("reino_subterraneo") and _eval_reino_subterraneo({}):
		unlock("reino_subterraneo")
	if not is_unlocked("ultima_espora") and _eval_ultima_espora({}):
		unlock("ultima_espora")

# ──────────────────────── HOOKS (backward compat → push_event) ────────────────────────

func on_run_closed(route: String) -> void:
	var active_count := 0
	for key in EvoManager.genome:
		if EvoManager.genome[key] == "activo":
			active_count += 1
	var payload := {
		"route":                  route,
		"click_count":            _click_count,
		"clicks_after_minute_one":_clicks_after_minute_one,
		"run_time":               _run_time,
		"epsilon":                StructuralModel.epsilon_runtime,  # runtime = lo que ve el jugador
		"epsilon_peak":           StructuralModel.epsilon_peak,     # pico de estrés alcanzado en la run
		"omega":                  StructuralModel.omega,
		"disturbances_survived":  RunManager.disturbances_survived,
		"resilience_score":       RunManager.resilience_score,
		"mutations_active_count": active_count,
		"mutations_this_run":     _mutations_this_run,
		"seta_formed":            _seta_formed_this_run,
		"bought_accounting":      _bought_accounting_this_run,
		"reencarnacion_active":   RouteManager.is_active("reencarnacion"),
	}
	push_event("run_closed", payload)
	# Logros especiales que dependen de estado interno cruzado
	# micelio_salvaje: gate anti-AFK añadido (click_count >= 100) en v1.0.0.10
	if route == "PARASITISMO" and not _bought_accounting_this_run and _click_count >= 100:
		unlock("micelio_salvaje")
	if route in ["ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL"] and _seta_formed_this_run:
		unlock("ciclo_completo")
	# tres_vidas_camino: también vive en CUSTOM_EVALUATORS para concesión retroactiva
	# (saves migrados que ya tengan los 3 endings pero no el logro).
	# Aquí LegacyManager ya registró HOMEORHESIS, así que _eval devuelve true si aplica.
	if route == "HOMEORHESIS" and _eval_tres_vidas_camino({}):
		unlock("tres_vidas_camino")
	if route == "METABOLISMO OSCURO" and _eval_saturacion_total({}):
		unlock("saturacion_total")
	if route == "COLAPSO DEPREDATORIO":
		unlock("colapso_depredatorio")
	if route in ["POLIMORFÍA TOTAL", "POLIMORFIA TOTAL"] and _eval_polimorfia_total({}):
		unlock("polimorfia_total")
	if route == "DOMADOR DEL CAOS" and _eval_domador_del_caos({}):
		unlock("domador_del_caos")
	if route == "ESCLEROCIO OSCURO" and EvoManager.met_oscuro_devoured_count >= 50:
		unlock("esclerocio_contingencia")
	if route == "AUTOFAGIA NECRÓTICA" and _eval_autolisis_perfecta({}):
		unlock("autolisis_perfecta")
	if route == "NECROSIS CONTROLADA" and _eval_funcion_pura({}):
		unlock("funcion_pura")

func on_upgrade_bought(id: String) -> void:
	_upgrades_this_run += 1
	if id == "accounting":
		_bought_accounting_this_run = true
	push_event("upgrade_bought", {"id": id, "count": _upgrades_this_run})

func on_click() -> void:
	_click_count += 1
	if _run_time > 60.0:
		_clicks_after_minute_one += 1

func on_disturbance_streak(streak: int) -> void:
	_progress["arquitecto_caos"] = float(streak)
	push_event("disturbance_streak", {"streak": streak})

func on_disturbance_survived(epsilon: float) -> void:
	push_event("disturbance_survived", {"epsilon": epsilon})

func on_homeostasis_tier_reached(tier: int, score: float) -> void:
	if tier >= 1:
		push_event("homeostasis_tier_reached", {"tier": tier, "score": score})

func on_mutation_activated(mutation_id: String) -> void:
	_mutations_this_run += 1
	push_event("mutation_activated", {"id": mutation_id, "count": _mutations_this_run})

func on_depredador_activated() -> void:
	push_event("depredador_activated", {})
	on_mutation_activated("depredador")

func on_met_oscuro_activated() -> void:
	push_event("met_oscuro_activated", {})
	on_mutation_activated("met_oscuro")

func on_red_micelial_activated() -> void:
	push_event("red_micelial_activated", {})
	on_mutation_activated("red_micelial")

func on_seta_formed() -> void:
	_seta_formed_this_run = true

# ──────────────────────── TOAST ────────────────────────

func _get_toast_container() -> VBoxContainer:
	if is_instance_valid(_toast_container):
		return _toast_container
	if not main:
		return null
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 10
	main.add_child(_toast_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(root)
	_toast_container = VBoxContainer.new()
	_toast_container.add_theme_constant_override("separation", 6)
	_toast_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_toast_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_container.offset_left = -396
	_toast_container.offset_top = -320
	_toast_container.offset_right = -16
	_toast_container.offset_bottom = -72
	_toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_container)
	return _toast_container


func _show_toast(_id: String, def: Dictionary) -> void:
	var level: String = def.get("toast", "full")
	if level == "silent":
		return

	var tier: int = def.get("tier", Tier.MICELIO)
	var icon: String = TIER_ICONS.get(tier, "🏁")
	var tier_name: String = TIER_NAMES.get(tier, "?")
	var name_str: String = tr("ACH_" + _id.to_upper() + "_NAME")
	var desc_str: String = tr("ACH_" + _id.to_upper() + "_DESC")
	var color: Color = TIER_COLORS.get(tier, Color(0.7, 0.7, 0.75))
	var is_legendary: bool = level == "legendary"

	var container := _get_toast_container()
	if not container:
		return

	# ── Panel principal ──
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.11, 0.96)
	style.set_border_width_all(0)
	style.border_width_left = 4
	style.border_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate.a = 0.0
	container.add_child(panel)

	# ── Layout interno ──
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	# RichTextLabel para que EmojiToRichText pueda reemplazar con Twemoji en web
	var icon_lbl := RichTextLabel.new()
	icon_lbl.bbcode_enabled = true
	icon_lbl.fit_content = true
	icon_lbl.scroll_active = false
	icon_lbl.custom_minimum_size = Vector2(36, 36)
	icon_lbl.add_theme_font_size_override("normal_font_size", 28)
	icon_lbl.text = EmojiToRichText.rich(icon)
	hbox.add_child(icon_lbl)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var header_lbl := Label.new()
	header_lbl.text = EmojiToRichText.strip(("★ LOGRO LEGENDARIO" if is_legendary else "LOGRO") + " — " + tier_name)
	header_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(10))
	header_lbl.add_theme_color_override("font_color", color)
	vbox.add_child(header_lbl)

	var name_lbl := Label.new()
	name_lbl.text = EmojiToRichText.strip(name_str)
	name_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	vbox.add_child(name_lbl)

	if level in ["full", "legendary"] and desc_str != "":
		var desc_lbl := Label.new()
		desc_lbl.text = EmojiToRichText.strip(desc_str)
		desc_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.custom_minimum_size = Vector2(260, 0)
		vbox.add_child(desc_lbl)

	# ── Animación: fade-in → espera → slide-out derecha ──
	if AccessibilityManager.reduce_motion:
		panel.modulate.a = 1.0
		var t := panel.create_tween()
		t.tween_interval(3.0 if level == "small" else 4.5)
		t.tween_callback(panel.queue_free)
	else:
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.25)
		tween.tween_interval(4.0 if level == "small" else 5.0)
		tween.tween_property(panel, "modulate:a", 0.0, 0.4)
		tween.tween_callback(panel.queue_free)

# ──────────────────────── PERSISTENCIA ────────────────────────

func load_data(data: Dictionary) -> void:
	unlocked.clear()
	# Migración de ids renombrados (v1.0.0.10): la key vieja se vuelca al id nuevo.
	# Si solo existe la vieja → migra. Si existen las dos → preserva la nueva.
	const ID_RENAMES := {
		"fractura_epistemica": "colapso_depredatorio",  # colisión con cosmic buff (v1.0.0.10)
		# NOTA v1.0.0.10: `click_dominance` se eliminó y reemplazó por `passive_dominance`
		# (lógica OPUESTA). No se migra: el unlock viejo queda como dead entry en `unlocked`
		# (no aparece en UI porque ya no existe en DEFS). passive_dominance debe ganarse limpio.
	}
	for id in data:
		var entry = data[id]
		var target_id: String = ID_RENAMES.get(id, id)
		if target_id != id and data.has(target_id):
			# Ya existe la versión nueva — ignorar la vieja
			continue
		# Soporta formato viejo (id → true) y nuevo (id → {unlocked_at, seen})
		if entry is bool:
			if entry:
				unlocked[target_id] = {"unlocked_at": 0, "seen": true}
		elif entry is Dictionary:
			unlocked[target_id] = entry

func get_data() -> Dictionary:
	return unlocked.duplicate(true)

func migrate_from_legacy_save(flags: Dictionary, achievements: Dictionary) -> void:
	# Flags estructurales viejos → nuevos ids
	var flag_map := {
		"unlocked_tree":              "arbol_productivo",
		# "unlocked_click_dominance" eliminado en v1.0.0.10 junto con el logro click_dominance.
		"unlocked_delta_100":         "delta_100",
		"achievement_millionaire":    "millonario",
		"achievement_fragile_balance":"equilibrio_fragil",
		"achievement_insatiable_parasite":"parasito_insaciable",
	}
	for old_flag in flag_map:
		if flags.get(old_flag, false) and not is_unlocked(flag_map[old_flag]):
			unlocked[flag_map[old_flag]] = {"unlocked_at": 0, "seen": true}

	# Dict de logros del formato previo a v0.9.3
	var ach_map := {
		"homeostasis_perfect": "homeostasis_perfecta",
		"hyperassimilation":   "ruta_hiperasimilacion",
		"red_micelial":        "red_micelial_activada",
		"sporulation":         "ruta_esporulacion",
	}
	for old_key in ach_map:
		if achievements.get(old_key, false) and not is_unlocked(ach_map[old_key]):
			unlocked[ach_map[old_key]] = {"unlocked_at": 0, "seen": true}

	if unlocked.size() > 0:
		LegacyManager.save_achievement_data(unlocked)
		print("🔄 [Achievements] Migración completada: %d logros recuperados" % unlocked.size())

# ──────────────────────── RESETS ────────────────────────

func reset_run_state() -> void:
	_run_time = 0.0
	_click_count = 0
	_clicks_after_minute_one = 0
	_upgrades_this_run = 0
	_mutations_this_run = 0
	_last_dominant = ""
	_bought_accounting_this_run = false
	_seta_formed_this_run = false
	_progress.clear()
	# Resetear timers efímeros
	for id in _timers:
		_timers[id] = 0.0
	_snapshot = {}

func hard_reset() -> void:
	unlocked.clear()
	reset_run_state()
