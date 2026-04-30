extends Node

# AchievementManager.gd — Autoload (v0.9.4)
# 50 logros en 4 tiers. Arquitectura híbrida:
#   push_snapshot(dict)  → estado del mundo cada tick
#   push_event(name, {}) → eventos puntuales
#   CUSTOM_EVALUATORS    → lógica compleja con nombre
#   unlocked → {id: {unlocked_at, seen}}  (persistente, legacy_bank.json)
#   _progress → {id: float}              (efímero, per-run)
#   _timers   → {id: float}              (efímero, sustained checks)

signal achievement_unlocked(id: String, def: Dictionary)

# ──────────────────────── TIERS ────────────────────────
enum Tier { MICELIO, ESPORA, FRUTO, ANCESTRAL }

const TIER_NAMES := {
	Tier.MICELIO:   "MICELIO",
	Tier.ESPORA:    "ESPORA",
	Tier.FRUTO:     "FRUTO",
	Tier.ANCESTRAL: "ANCESTRAL",
}
const TIER_COLORS := {
	Tier.MICELIO:   Color(0.72, 0.48, 0.25),
	Tier.ESPORA:    Color(0.90, 0.90, 0.92),
	Tier.FRUTO:     Color(1.00, 0.80, 0.25),
	Tier.ANCESTRAL: Color(0.85, 0.20, 0.30),
}
const TIER_ICONS := {
	Tier.MICELIO:   "🟤",
	Tier.ESPORA:    "⚪",
	Tier.FRUTO:     "🟡",
	Tier.ANCESTRAL: "🔴",
}

# TOAST LEVELS
# "silent"    sin popup (logros de onboarding)
# "small"     popup discreto
# "full"      popup normal
# "legendary" popup destacado (ANCESTRAL + logros clave)

# ──────────────────────── CATÁLOGO (50 logros) ────────────────────────
# trigger types:
#   "threshold"        — métrica cruza target una vez (snapshot)
#   "sustained"        — métrica sostenida N segundos (op/target/duration)
#   "sustained_between"— métrica en rango [min,max] N segundos
#   "event"            — evento puntual con conditions opcionales
#   "event_count"      — acumula eventos, tiene progreso (target)
#   "custom"           — evaluador nombrado en CUSTOM_EVALUATORS
const DEFS := {

	# ═══════════════ MICELIO (14) ═══════════════

	"primera_espora": {
		"name": "Primera Espora",
		"desc": "Completar la primera run con cualquier final.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event", "event_name": "run_closed",
	},
	"brote_inicial": {
		"name": "Brote Inicial",
		"desc": "Generar $1.000 acumulados.",
		"tier": Tier.MICELIO, "secret": false, "toast": "silent",
		"trigger": "threshold", "metric": "total_money", "target": 1000.0,
	},
	"primer_eslabon": {
		"name": "Primer Eslabón",
		"desc": "Comprar el primer upgrade del juego.",
		"tier": Tier.MICELIO, "secret": false, "toast": "silent",
		"trigger": "event", "event_name": "upgrade_bought",
	},
	"primer_latido": {
		"name": "Primer Latido",
		"desc": "Mantener producción positiva durante 30 segundos seguidos.",
		"tier": Tier.MICELIO, "secret": false, "toast": "silent",
		"trigger": "sustained", "metric": "delta_total", "op": ">", "target": 0.0, "duration": 30.0,
	},
	"pequena_red": {
		"name": "Pequeña Red",
		"desc": "Comprar 5 upgrades en una run.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event_count", "event_name": "upgrade_bought", "target": 5,
		"progress_format": "{current} / {target} upgrades",
	},
	"raices_profundas": {
		"name": "Raíces Profundas",
		"desc": "Alcanzar biomasa ≥ 5.0.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "threshold", "metric": "biomasa", "target": 5.0,
	},
	"umbral_verde": {
		"name": "Umbral Verde",
		"desc": "Biomasa ≥ 3.0 con ε < 0.30 al mismo tiempo.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "custom", "evaluator": "umbral_verde",
	},
	"sistema_respira": {
		"name": "El Sistema Respira",
		"desc": "Sostener ε < 0.20 durante 60 segundos.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "sustained", "metric": "epsilon", "op": "<", "target": 0.20, "duration": 60.0,
	},
	"metabolismo_estable": {
		"name": "Metabolismo Estable",
		"desc": "Mantener Δ$ ≥ 25/s durante 60 segundos seguidos.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "sustained", "metric": "delta_total", "op": ">=", "target": 25.0, "duration": 60.0,
	},
	"delta_100": {
		"name": "Δ$ ≥ 100/s",
		"desc": "Alcanzar metabolismo total de 100 $/s.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "threshold", "metric": "delta_total", "target": 100.0,
	},
	"arbol_productivo": {
		"name": "Árbol Productivo",
		"desc": "Desbloquear todos los eslabones productivos (d, md, so, e, me).",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "custom", "evaluator": "arbol_productivo",
	},
	"click_dominance": {
		"name": "Dominancia del Click",
		"desc": "Hacer que el término CLICK domine el sistema.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "custom", "evaluator": "click_dominance",
	},
	"jardin_controlado": {
		"name": "Jardín Controlado",
		"desc": "Completar una run sin ninguna perturbación.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "disturbances_survived", "op": "==", "value": 0}],
	},
	"mano_ligera": {
		"name": "Mano Ligera",
		"desc": "Cerrar una run con menos de 50 clicks totales.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "click_count", "op": "<", "value": 50}],
	},

	# ═══════════════ ESPORA (14) ═══════════════

	"red_micelial_activada": {
		"name": "Red Micelial",
		"desc": "Activar la mutación Red Micelial.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "red_micelial_activated",
	},
	"ruta_hiperasimilacion": {
		"name": "Hiperasimilación",
		"desc": "Cerrar una run por la ruta de Hiperasimilación.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "in", "value": ["HIPERASIMILACION", "HIPERASIMILACIÓN"]}],
	},
	"ruta_simbiosis": {
		"name": "Simbiosis Estructural",
		"desc": "Cerrar una run por la ruta de Simbiosis.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "==", "value": "SIMBIOSIS"}],
	},
	"ruta_esporulacion": {
		"name": "Esporulación Irreversible",
		"desc": "Cerrar una run por la ruta de Esporulación.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "in", "value": ["ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL"]}],
	},
	"tension_productiva": {
		"name": "Tensión Productiva",
		"desc": "Tener Homeostasis y Red Micelial en estado latente al mismo tiempo.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "custom", "evaluator": "tension_productiva",
	},
	"arquitecto_caos": {
		"name": "Arquitecto del Caos",
		"desc": "Sobrevivir 3 perturbaciones seguidas sin resetear el timer homeostático.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "disturbance_streak",
		"conditions": [{"key": "streak", "op": ">=", "value": 3}],
		"target": 3, "progress_format": "{current} / {target} perturbaciones",
	},
	"punto_inflexion": {
		"name": "Punto de Inflexión",
		"desc": "Cambiar el término dominante 3 veces en una sola run.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event_count", "event_name": "dominant_switch", "target": 3,
		"progress_format": "{current} / {target} cambios",
	},
	"sin_tocar": {
		"name": "Sin Tocar",
		"desc": "Cerrar HOMEOSTASIS con ≤ 10 clicks totales.",
		"tier": Tier.ESPORA, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [
			{"key": "route", "op": "==", "value": "HOMEOSTASIS"},
			{"key": "click_count", "op": "<=", "value": 10},
		],
	},
	"economia_guerra": {
		"name": "Economía de Guerra",
		"desc": "Sostener 10.000 $/s con Parasitismo activo.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "custom", "evaluator": "economia_guerra",
	},
	"cultivo_cruzado": {
		"name": "Cultivo Cruzado",
		"desc": "Activar 2 mutaciones distintas en una misma run.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event_count", "event_name": "mutation_activated", "target": 2,
		"progress_format": "{current} / {target} mutaciones",
	},
	"presion_adaptativa": {
		"name": "Presión Adaptativa",
		"desc": "Sobrevivir una perturbación con ε > 0.50.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "disturbance_survived",
		"conditions": [{"key": "epsilon", "op": ">", "value": 0.50}],
	},
	"motor_autotrofo": {
		"name": "Motor Autótrofo",
		"desc": "Alcanzar 50.000 $/s de metabolismo total.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "threshold", "metric": "delta_total", "target": 50000.0,
	},
	"cosecha_temprana": {
		"name": "Cosecha Temprana",
		"desc": "Cerrar una run en menos de 5 minutos.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "run_time", "op": "<", "value": 300.0}],
	},
	"simetria_viva": {
		"name": "Simetría Viva",
		"desc": "Mantener biomasa entre 4.0 y 6.0 durante 90 segundos.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "sustained_between", "metric": "biomasa",
		"min": 4.0, "max": 6.0, "duration": 90.0,
	},

	# ═══════════════ FRUTO (14) ═══════════════

	"ruta_parasitismo": {
		"name": "Parasitismo Consumado",
		"desc": "Cerrar una run por la ruta de Parasitismo.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "==", "value": "PARASITISMO"}],
	},
	"homeostasis_perfecta": {
		"name": "Homeostasis Perfecta",
		"desc": "Cerrar Homeostasis con resilience_score ≥ 300.",
		"tier": Tier.FRUTO, "secret": false, "toast": "legendary",
		"trigger": "event", "event_name": "homeostasis_tier_reached",
		"conditions": [{"key": "score", "op": ">=", "value": 300.0}],
	},
	"millonario": {
		"name": "Millonario de Esporas",
		"desc": "Generar $1.000.000 acumulados.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "threshold", "metric": "total_money", "target": 1_000_000.0,
	},
	"equilibrio_fragil": {
		"name": "Equilibrio Frágil",
		"desc": "Sostener ε entre 0.10 y 0.20 durante 60 segundos.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "sustained_between", "metric": "epsilon",
		"min": 0.10, "max": 0.20, "duration": 60.0,
	},
	"parasito_insaciable": {
		"name": "Parásito Insaciable",
		"desc": "Alcanzar biomasa ≥ 20 con Parasitismo activo.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "custom", "evaluator": "parasito_insaciable",
	},
	"ciclo_completo": {
		"name": "Ciclo Completo",
		"desc": "Formar la seta y esporular en la misma run.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "custom", "evaluator": "ciclo_completo",
	},
	"resiliencia_cristalina": {
		"name": "Resiliencia Cristalina",
		"desc": "Acumular resilience_score ≥ 500.",
		"tier": Tier.FRUTO, "secret": false, "toast": "legendary",
		"trigger": "threshold", "metric": "resilience_score", "target": 500.0,
	},
	"kappa_maximo": {
		"name": "Kappa Máximo",
		"desc": "Alcanzar κμ ≥ 1.80.",
		"tier": Tier.FRUTO, "secret": false, "toast": "legendary",
		"trigger": "threshold", "metric": "k_eff", "target": 1.80,
	},
	"micelio_salvaje": {
		"name": "Micelio Salvaje",
		"desc": "Cerrar PARASITISMO sin comprar nunca Contabilidad.",
		"tier": Tier.FRUTO, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "micelio_salvaje",
	},
	"fruta_prohibida": {
		"name": "Fruta Prohibida",
		"desc": "Cerrar PARASITISMO o HIPERASIMILACIÓN con ε > 0.40.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [
			{"key": "route", "op": "in", "value": ["PARASITISMO", "HIPERASIMILACION", "HIPERASIMILACIÓN"]},
			{"key": "epsilon", "op": ">", "value": 0.40},
		],
	},
	"maquina_organica": {
		"name": "Máquina Orgánica",
		"desc": "Tener $100.000 en el banco al mismo tiempo.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "threshold", "metric": "money", "target": 100_000.0,
	},
	"hambre_elegante": {
		"name": "Hambre Elegante",
		"desc": "Parasitismo activo con biomasa ≥ 15 durante 60 segundos.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "custom", "evaluator": "hambre_elegante",
		"duration": 60.0,
	},
	"eficiencia_brutal": {
		"name": "Eficiencia Brutal",
		"desc": "Cerrar una run con resilience_score ≥ 200 y ≤ 30 clicks.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [
			{"key": "resilience_score", "op": ">=", "value": 200.0},
			{"key": "click_count", "op": "<=", "value": 30},
		],
	},
	"latido_cosmico": {
		"name": "Latido Cósmico",
		"desc": "Mantener Δ$ ≥ 500, ε < 0.15 y biomasa ≥ 5 durante 90 segundos.",
		"tier": Tier.FRUTO, "secret": false, "toast": "legendary",
		"trigger": "custom", "evaluator": "latido_cosmico",
		"duration": 90.0,
	},

	# ═══════════════ ANCESTRAL (8, todos secretos) ═══════════════

	"hongo_realidad": {
		"name": "El Hongo se Come la Realidad",
		"desc": "Activar el Depredador de Realidades.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "depredador_activated",
	},
	"bioquimica_oscura": {
		"name": "Bioquímica Oscura",
		"desc": "Activar el Metabolismo Oscuro (post-Depredador).",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "met_oscuro_activated",
	},
	"saturacion_total": {
		"name": "Saturación Total",
		"desc": "Cerrar METABOLISMO OSCURO por saturación de biomasa (≥ 100).",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "saturacion_total",
	},
	"tres_vidas_camino": {
		"name": "Tres Vidas, Un Camino",
		"desc": "Alcanzar HOMEOSTASIS → ALLOSTASIS → HOMEORHESIS progresivamente.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "tres_vidas_camino",
	},
	"entropia_cero": {
		"name": "Entropía Cero",
		"desc": "Sostener ε < 0.05 con biomasa > 8.0 durante 120 segundos.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "entropia_cero",
		"duration": 120.0,
	},
	"organismo_total": {
		"name": "Organismo Total",
		"desc": "Biomasa > 10, κμ > 1.6 y ε < 0.15 simultáneamente.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "organismo_total",
	},
	"sin_dioses_ni_clicks": {
		"name": "Sin Dioses ni Clicks",
		"desc": "Cerrar una ruta de endgame sin clicks después del minuto 1.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [
			{"key": "route", "op": "in",
				"value": ["HOMEOSTASIS", "ALLOSTASIS", "HOMEORHESIS", "PARASITISMO", "SIMBIOSIS"]},
			{"key": "clicks_after_minute_one", "op": "==", "value": 0},
		],
	},
	"run_imposible": {
		"name": "La Run Imposible",
		"desc": "Cerrar una ruta con 3 o más mutaciones activas simultáneamente.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "mutations_active_count", "op": ">=", "value": 3}],
	},
	"reino_subterraneo": {
		"name": "Reino Subterráneo",
		"desc": "Desbloquear todos los logros MICELIO, ESPORA y FRUTO.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "reino_subterraneo",
	},
	"ultima_espora": {
		"name": "Última Espora",
		"desc": "Desbloquear los 50 logros.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "ultima_espora",
	},
}

# ──────────────────────── ESTADO PERSISTENTE ────────────────────────
# id → { "unlocked_at": int (unix timestamp), "seen": bool }
var unlocked: Dictionary = {}

# ──────────────────────── ESTADO EFÍMERO (per-run) ────────────────────────
var main: Node = null
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
	"hambre_elegante", "latido_cosmico", "entropia_cero"
]

# ──────────────────────── INIT ────────────────────────
var CUSTOM_EVALUATORS: Dictionary = {}

func _ready() -> void:
	CUSTOM_EVALUATORS = {
		"umbral_verde":       _eval_umbral_verde,
		"arbol_productivo":   _eval_arbol_productivo,
		"click_dominance":    _eval_click_dominance,
		"tension_productiva": _eval_tension_productiva,
		"economia_guerra":    _eval_economia_guerra,
		"parasito_insaciable":_eval_parasito_insaciable,
		"ciclo_completo":     _eval_ciclo_completo,
		"micelio_salvaje":    _eval_micelio_salvaje,
		"hambre_elegante":    _eval_hambre_elegante_cond,
		"latido_cosmico":     _eval_latido_cosmico_cond,
		"tres_vidas_camino":  _eval_tres_vidas_camino,
		"entropia_cero":      _eval_entropia_cero_cond,
		"organismo_total":    _eval_organismo_total,
		"reino_subterraneo":  _eval_reino_subterraneo,
		"ultima_espora":      _eval_ultima_espora,
		"saturacion_total":   _eval_saturacion_total,
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
	_show_toast(id, def)
	if main:
		main.add_lap("🏁 Logro — " + def["name"])
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
	return unlocked.size()

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
	var target: float = float(def.get("target", 1))
	var ratio := clampf(current / target, 0.0, 1.0) if target > 0.0 else 0.0
	return {"current": current, "target": target, "ratio": ratio}

func get_display_name(id: String) -> String:
	if not DEFS.has(id): return "???"
	var def: Dictionary = DEFS[id]
	if def.get("secret", false) and not is_unlocked(id):
		return "??? (secreto)"
	return def["name"]

func get_display_desc(id: String) -> String:
	if not DEFS.has(id): return ""
	var def: Dictionary = DEFS[id]
	if def.get("secret", false) and not is_unlocked(id):
		return "Logro oculto — descubrilo jugando."
	return def["desc"]

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
	return StructuralModel.unlocked_d and StructuralModel.unlocked_md \
		and UpgradeManager.level("specialization") > 0 \
		and StructuralModel.unlocked_e and StructuralModel.unlocked_me

func _eval_click_dominance(_s: Dictionary) -> bool:
	if not (StructuralModel.unlocked_d or StructuralModel.unlocked_e): return false
	return main != null and main.get_dominant_term() == "CLICK domina el sistema"

func _eval_tension_productiva(_s: Dictionary) -> bool:
	return EvoManager.genome.get("homeostasis", "dormido") == "latente" \
		and EvoManager.genome.get("red_micelial", "dormido") == "latente"

func _eval_economia_guerra(s: Dictionary) -> bool:
	return EvoManager.mutation_parasitism and s.get("delta_total", 0.0) >= 10000.0

func _eval_parasito_insaciable(s: Dictionary) -> bool:
	return EvoManager.mutation_parasitism and s.get("biomasa", 0.0) >= 20.0

func _eval_ciclo_completo(_s: Dictionary) -> bool:
	# Se dispara en on_run_closed vía push_event con seta_formed en payload.
	# Este evaluador no se usa en el tick — devuelve false siempre.
	return false

func _eval_micelio_salvaje(_s: Dictionary) -> bool:
	return false  # Evaluado en on_run_closed payload

func _eval_hambre_elegante_cond(s: Dictionary) -> bool:
	return EvoManager.mutation_parasitism and s.get("biomasa", 0.0) >= 15.0

func _eval_latido_cosmico_cond(s: Dictionary) -> bool:
	return s.get("delta_total", 0.0) >= 500.0 \
		and s.get("epsilon", 1.0) < 0.15 \
		and s.get("biomasa", 0.0) >= 5.0

func _eval_tres_vidas_camino(_s: Dictionary) -> bool:
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
		if def["tier"] == Tier.ANCESTRAL: continue
		if not is_unlocked(id): return false
	return true

func _eval_ultima_espora(_s: Dictionary) -> bool:
	return unlocked.size() >= DEFS.size()

func _eval_saturacion_total(_s: Dictionary) -> bool:
	# Evaluado solo cuando se cierra METABOLISMO OSCURO por saturación
	return RunManager.final_route == "METABOLISMO OSCURO" \
		and RunManager.final_reason.contains("Saturación Oscura")

# ──────────────────────── META-ACHIEVEMENTS ────────────────────────

func _check_meta_achievements() -> void:
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
		"epsilon":                _snapshot.get("epsilon", 0.0),
		"disturbances_survived":  RunManager.disturbances_survived,
		"resilience_score":       RunManager.resilience_score,
		"mutations_active_count": active_count,
		"seta_formed":            _seta_formed_this_run,
		"bought_accounting":      _bought_accounting_this_run,
	}
	push_event("run_closed", payload)
	# Logros especiales que dependen de estado interno cruzado
	if route == "PARASITISMO" and not _bought_accounting_this_run:
		unlock("micelio_salvaje")
	if route in ["ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL"] and _seta_formed_this_run:
		unlock("ciclo_completo")
	if route == "HOMEORHESIS" and _eval_tres_vidas_camino({}):
		unlock("tres_vidas_camino")
	if route == "METABOLISMO OSCURO" and _eval_saturacion_total({}):
		unlock("saturacion_total")

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

func on_met_oscuro_activated() -> void:
	push_event("met_oscuro_activated", {})

func on_red_micelial_activated() -> void:
	push_event("red_micelial_activated", {})
	on_mutation_activated("red_micelial")

func on_seta_formed() -> void:
	_seta_formed_this_run = true

# ──────────────────────── TOAST ────────────────────────

func _show_toast(id: String, def: Dictionary) -> void:
	var level: String = def.get("toast", "full")
	if level == "silent":
		return
	if not UIManager.system_message_label:
		return
	var tier: int = def.get("tier", Tier.MICELIO)
	var icon: String = TIER_ICONS.get(tier, "🏁")
	var tier_name: String = TIER_NAMES.get(tier, "?")
	var name_str: String = def["name"]
	match level:
		"small":
			UIManager.system_message_label.text = "%s %s" % [icon, name_str]
		"full":
			UIManager.system_message_label.text = \
				"%s LOGRO [%s] — %s" % [icon, tier_name, name_str]
		"legendary":
			UIManager.system_message_label.text = \
				"✨ %s LOGRO LEGENDARIO [%s] ✨ — %s" % [icon, tier_name, name_str]

# ──────────────────────── PERSISTENCIA ────────────────────────

func load_data(data: Dictionary) -> void:
	unlocked.clear()
	for id in data:
		var entry = data[id]
		# Soporta formato viejo (id → true) y nuevo (id → {unlocked_at, seen})
		if entry is bool:
			if entry:
				unlocked[id] = {"unlocked_at": 0, "seen": true}
		elif entry is Dictionary:
			unlocked[id] = entry

func get_data() -> Dictionary:
	return unlocked.duplicate(true)

func migrate_from_legacy_save(flags: Dictionary, achievements: Dictionary) -> void:
	# Flags estructurales viejos → nuevos ids
	var flag_map := {
		"unlocked_tree":              "arbol_productivo",
		"unlocked_click_dominance":   "click_dominance",
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
