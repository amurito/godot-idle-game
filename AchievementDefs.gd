# AchievementDefs.gd
# Catálogo estático: Tier enum, colores, íconos y definiciones de logros.
# Sin estado — sólo datos. Referenciado como AchievementDefs.DEFS, AchievementDefs.Tier, etc.
class_name AchievementDefs

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
	"esclerocio_contingencia": {
		"name": "Esporas de Contingencia",
		"desc": "Cerrar ESCLEROCIO OSCURO habiendo devorado 50 o más upgrades.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "esclerocio_contingencia",
	},
	"autolisis_perfecta": {
		"name": "Autofagia Perfecta",
		"desc": "Cerrar AUTÓLISIS DIRIGIDA habiendo consumido 15 o más upgrades.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "autolisis_perfecta",
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
		"desc": "Alcanzar un pico de Δ$ ≥ 50.000/s con Metabolismo Oscuro activo.",
		"tier": Tier.MYTHIC, "secret": true, "toast": "legendary",
		"trigger": "custom", "evaluator": "metabolismo_oscuro_pico",
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
		"desc": "Cerrar una run habiendo activado 3 o más mutaciones distintas (cadena depredador o Carnaval).",
		"tier": Tier.ANCESTRAL, "secret": true, "toast": "legendary",
		"trigger": "event", "event_name": "run_closed",
		"conditions": [{"key": "mutations_this_run", "op": ">=", "value": 3}],
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
