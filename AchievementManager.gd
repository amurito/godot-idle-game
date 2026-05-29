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

# ──────────────────────── TIERS ────────────────────────
enum Tier { MICELIO, ESPORA, FRUTO, ANCESTRAL, MYTHIC }

const TIER_NAMES := {
	Tier.MICELIO:   "MICELIO",
	Tier.ESPORA:    "ESPORA",
	Tier.FRUTO:     "FRUTO",
	Tier.ANCESTRAL: "ANCESTRAL",
	Tier.MYTHIC:    "MYTHIC",
}
const TIER_COLORS := {
	Tier.MICELIO:   Color(0.72, 0.48, 0.25),
	Tier.ESPORA:    Color(0.90, 0.90, 0.92),
	Tier.FRUTO:     Color(1.00, 0.80, 0.25),
	Tier.ANCESTRAL: Color(0.85, 0.20, 0.30),
	Tier.MYTHIC:    Color(0.55, 0.10, 0.85),
}
const TIER_ICONS := {
	Tier.MICELIO:   "🟤",
	Tier.ESPORA:    "⚪",
	Tier.FRUTO:     "🟡",
	Tier.ANCESTRAL: "🔴",
	Tier.MYTHIC:    "🟣",
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

	# ═══════════════ MICELIO ═══════════════

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
	# Eliminados en v1.0.0.10: primer_eslabon (overlap con pequena_red),
	# primer_latido (trivial — se disparaba con el primer click).
	"pequena_red": {
		"name": "Pequeña Red",
		"desc": "Comprar 5 upgrades en una run.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event_count", "event_name": "upgrade_bought", "target": 5,
		"progress_key": "ACH_PROGFMT_UPGRADES",
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
		"desc": "Sostener ε < 0.20 durante 3 minutos.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "sustained", "metric": "epsilon", "op": "<", "target": 0.20, "duration": 180.0,
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
		"desc": "Desbloquear todos los eslabones productivos y cognitivos (d, md, so, e, me, μ, mem, contabilidad).",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "custom", "evaluator": "arbol_productivo",
	},
	"passive_dominance": {
		"name": "Dominancia Pasiva",
		"desc": "Hacer que el término PASIVO (Trabajo Manual o Trueque) domine el sistema.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "custom", "evaluator": "passive_dominance",
	},
	"jardin_controlado": {
		"name": "Jardín Controlado",
		"desc": "Cerrar una run sin ninguna perturbación y con Ω ≥ 0.50.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [
			{"key": "disturbances_survived", "op": "==", "value": 0},
			{"key": "omega", "op": ">=", "value": 0.50},
		],
	},
	"mano_ligera": {
		"name": "Mano Ligera",
		"desc": "Cerrar una run con menos de 50 clicks totales.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "click_count", "op": "<", "value": 50}],
	},
	"primer_click_letal": {
		"name": "Primer Click Letal",
		"desc": "Hacer un click que genere más de $10.000 de una vez.",
		"tier": Tier.MICELIO, "secret": false, "toast": "small",
		"trigger": "event", "event_name": "big_click",
		"conditions": [{"key": "power", "op": ">=", "value": 10000.0}],
	},

	# ═══════════════ ESPORA ═══════════════

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
		"target": 3, "progress_key": "ACH_PROGFMT_DISTURBANCES",
	},
	"punto_inflexion": {
		"name": "Punto de Inflexión",
		"desc": "Cambiar el término dominante 3 veces en una sola run.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event_count", "event_name": "dominant_switch", "target": 3,
		"progress_key": "ACH_PROGFMT_SWITCHES",
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
		"progress_key": "ACH_PROGFMT_MUTATIONS",
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
	"bioma_despierto": {
		"name": "Bioma Despierto",
		"desc": "Red micelial madura — alcanzar Hifas ≥ 10.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "threshold", "metric": "hifas", "target": 10.0,
	},
	"escalado_alostatico": {
		"name": "Escalado Alostático",
		"desc": "Comprar el upgrade Escalado Alostático (ea) por primera vez — ×2 al Trueque.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "upgrade_bought",
		"conditions": [{"key": "id", "op": "==", "value": "trueque_allo"}],
	},
	"carnaval_iniciado": {
		"name": "¡Que Comience el Carnaval!",
		"desc": "Activar la ruta CARNAVAL DE MUTACIONES.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "post_tras_route",
		"conditions": [{"key": "route", "op": "==", "value": "carnaval"}],
	},
	"reencarnado": {
		"name": "El Eterno Retorno",
		"desc": "Activar la ruta REENCARNACIÓN HEREDADA.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "post_tras_route",
		"conditions": [{"key": "route", "op": "==", "value": "reencarnacion"}],
	},
	"vacio_iniciado": {
		"name": "Hambre Cósmica",
		"desc": "Activar la ruta VACÍO HAMBRIENTO.",
		"tier": Tier.ESPORA, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "post_tras_route",
		"conditions": [{"key": "route", "op": "==", "value": "vacio"}],
	},

	# ═══════════════ FRUTO ═══════════════

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
		"desc": "Cerrar PARASITISMO sin comprar nunca Contabilidad y con ≥ 100 clicks (anti-AFK).",
		"tier": Tier.FRUTO, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "micelio_salvaje",
	},
	"fruta_prohibida": {
		"name": "Fruta Prohibida",
		"desc": "Cerrar PARASITISMO o HIPERASIMILACIÓN habiendo alcanzado un pico de ε > 0.80.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [
			{"key": "route", "op": "in", "value": ["PARASITISMO", "HIPERASIMILACION", "HIPERASIMILACIÓN"]},
			{"key": "epsilon_peak", "op": ">", "value": 0.80},
		],
	},
	"maquina_organica": {
		"name": "Máquina Orgánica",
		"desc": "Tener $100.000 en el banco al mismo tiempo.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "threshold", "metric": "money", "target": 100_000.0,
	},
	# Eliminado en v1.0.0.10: hambre_elegante (overlap fuerte con parasito_insaciable).
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
	"ruta_allostasis": {
		"name": "Alostasis Estructural",
		"desc": "Cerrar una run por la ruta de Allostasis.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "==", "value": "ALLOSTASIS"}],
	},
	"cinco_legados": {
		"name": "Cinco Legados",
		"desc": "Tener 5 o más mejoras del Banco Genético desbloqueadas.",
		"tier": Tier.FRUTO, "secret": false, "toast": "full",
		"trigger": "custom", "evaluator": "cinco_legados",
	},

	# ═══════════════ ANCESTRAL + MYTHIC (todos secretos) ═══════════════

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
	"colapso_depredatorio": {
		"name": "Colapso Depredatorio",
		"desc": "Cerrar por COLAPSO DEPREDATORIO: el estrés estructural colapsó bajo presión del Depredador.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "colapso_depredatorio",
	},
	"polimorfia_total": {
		"name": "Polimorfía Total",
		"desc": "Cerrar CARNAVAL DE MUTACIONES tras 12 rotaciones con Bio ≥ 8.0, Ω ≥ 0.35, $ ≥ 300K.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "polimorfia_total",
	},
	"domador_del_caos": {
		"name": "Domador del Caos",
		"desc": "Cerrar CARNAVAL DE MUTACIONES tras 3+ rotaciones habiendo acumulado $ ≥ 1M.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "domador_del_caos",
	},
	"ruta_ascesis": {
		"name": "Ascesis Profunda",
		"desc": "Cerrar VACÍO HAMBRIENTO por renuncia absoluta (ASCESIS PROFUNDA).",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "==", "value": "ASCESIS_PROFUNDA"}],
	},
	"ruta_reencarnacion": {
		"name": "Reencarnación Consumada",
		"desc": "Cerrar una run con la mutación Reencarnación Heredada activa.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "reencarnacion_active", "op": "==", "value": true}],
	},
	"metabolismo_oscuro_pico": {
		"name": "Pico Metabólico Oscuro",
		"desc": "Alcanzar Δ$ ≥ 500.000/s con Metabolismo Oscuro activo durante 30 segundos.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "metabolismo_oscuro_pico", "duration": 30.0,
	},
	"legado_absoluto": {
		"name": "Legado Absoluto",
		"desc": "Desbloquear todas las mejoras del Banco Genético.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "legado_absoluto",
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
	"depredador_total": {
		"name": "Depredador Absoluto",
		"desc": "Devorar 50 upgrades en una sola run de DEPREDADOR.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event_count", "event_name": "depredador_devour", "target": 50,
		"progress_key": "ACH_PROGFMT_DEVOURED",
	},
	"ascension_total": {
		"name": "Ascensión Total",
		"desc": "Trascender 5 veces.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "threshold", "metric": "trascendencia_count", "target": 5.0,
	},
	"dios_de_las_moscas": {
		"name": "El Dios de las Moscas",
		"desc": "Cerrar todos los finales posibles del juego.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "dios_de_las_moscas",
		"target": 17, "progress_key": "ACH_PROGFMT_ENDINGS",
	},
	"ruta_homeorhesis": {
		"name": "Homeorhesis",
		"desc": "Cerrar una run por la ruta de Homeorhesis — evolución irreversible.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "route", "op": "==", "value": "HOMEORHESIS"}],
	},
	"omega_inviolable": {
		"name": "Omega Inviolable",
		"desc": "Sostener Ω ≥ ω_min ≥ 0.55 durante 120 segundos sin caer.",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "omega_inviolable", "duration": 120.0,
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
		"progress_key": "ACH_PROGFMT_ACHIEVEMENTS",
	},
	"ultima_espora": {
		"name": "Última Espora",
		"desc": "Desbloquear todos los logros del juego.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "ultima_espora",
	},
}

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
	"omega_inviolable", "metabolismo_oscuro_pico",
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
	# For dios_de_las_moscas: count endings achieved out of ALL_ENDINGS
	elif id == "dios_de_las_moscas":
		var count := 0
		for route in ALL_ENDINGS:
			if LegacyManager.endings_achieved.get(route, false):
				count += 1
		current = float(count)
	# For reino_subterraneo: count unlocked MICELIO+ESPORA+FRUTO achievements (target is dynamic)
	elif id == "reino_subterraneo":
		var unlocked_count := 0
		var total_count := 0
		for aid in DEFS:
			var adef: Dictionary = DEFS[aid]
			if adef["tier"] == Tier.ANCESTRAL or adef["tier"] == Tier.MYTHIC: continue
			total_count += 1
			if is_unlocked(aid): unlocked_count += 1
		current = float(unlocked_count)
		var ratio_rs := clampf(current / float(total_count), 0.0, 1.0) if total_count > 0 else 0.0
		return {"current": current, "target": float(total_count), "ratio": ratio_rs}
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
	# Evaluado solo cuando se cierra METABOLISMO OSCURO por saturación
	return RunManager.final_route == "METABOLISMO OSCURO" \
		and RunManager.final_reason.contains("Saturación Oscura")

func _eval_colapso_depredatorio(_s: Dictionary) -> bool:
	return RunManager.final_route == "COLAPSO DEPREDATORIO"

func _eval_polimorfia_total(_s: Dictionary) -> bool:
	return RunManager.final_route == "POLIMORFÍA TOTAL" or RunManager.final_route == "POLIMORFIA TOTAL"

func _eval_domador_del_caos(_s: Dictionary) -> bool:
	return RunManager.final_route == "DOMADOR DEL CAOS"

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
	return EvoManager.mutation_met_oscuro and s.get("delta_total", 0.0) >= 500000.0

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
		"seta_formed":            _seta_formed_this_run,
		"bought_accounting":      _bought_accounting_this_run,
		"reencarnacion_active":   RunManager.reencarnacion_active,
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
