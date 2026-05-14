extends Node

# LegacyManager.gd — Autoload Global v1.0.0
# Gestiona los Puntos de Legado (PL) y las mejoras persistentes entre partidas.
#
# ARQUITECTURA v1.0:
#   - LEGACY_DEFS: 40 buffs con estructura tipada (cost, effect, reveal, unlock)
#   - var buffs: Dictionary — estado del jugador { id: {level, seen} }
#   - get_buff_value(id) -> bool — retrocompat con todos los consumidores existentes
#   - get_buff_level(id) -> int — nivel actual del buff
#   - get_effect_value(type) -> float — suma agregada de todos los efectos del mismo tipo
#   - is_revealed(id) -> bool — si el buff es visible en la UI
#   - is_unlockable(id) -> bool — si las condiciones de desbloqueo se cumplen
#   - grant_buff(id) — otorga un buff sin compra (para NG+)

# LEGACY_PATH ahora es property dinámica que apunta al slot activo de SlotManager.
# Cada slot tiene su propio legacy_bank.json (universos paralelos).
var LEGACY_PATH: String:
	get:
		return SlotManager.get_active_legacy_path()

# =====================================================
#  DEFINICIÓN DE BUFFS — 40 mejoras
# =====================================================
# Campos por entrada:
#   name        String  — nombre visible
#   flavor      String  — descripción poética corta
#   cat         String  — economia | estructura | biologia | conocimiento | ruta | ng_plus | secreto
#   cost        int     — costo base en PL (0 = gratuito/automático)
#   cost_growth float   — multiplicador de costo por nivel (1.0 = fijo)
#   max_level   int     — niveles máximos comprables
#   reveal      Dict    — cuándo aparece en la UI
#   unlock      Dict    — cuándo puede comprarse
#   effect      Dict    — efecto tipado { type, value }
#
# reveal/unlock types:
#   always | route_closed | route_closed_any | route_closed_all
#   achievement_unlocked | transcendence_count | buff_owned | mu_peak_reached

const LEGACY_DEFS: Dictionary = {
	# ────────────────────────────────────────────────
	# ECONOMÍA (7)
	# ────────────────────────────────────────────────
	"deflacion": {
		"name": "Deflación Biótica",
		"flavor": "El mercado recuerda los precios anteriores.",
		"cat": "economia", "cost": 4, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "price_scaling_mult", "value": 0.95},
	},
	"memoria_recurso": {
		"name": "Memoria de Recurso",
		"flavor": "El sistema guarda la primera inversión de cada ciclo.",
		"cat": "economia", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "first_producer_free", "value": 1.0},
	},
	"red_confianza": {
		"name": "Red de Confianza",
		"flavor": "El intercambio fluye donde antes había fricción.",
		"cat": "economia", "cost": 3, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "trueque_efficiency_add", "value": 0.10},
	},
	"impulso_manual": {
		"name": "Impulso Manual",
		"flavor": "La mano recuerda el peso de cada click anterior.",
		"cat": "economia", "cost": 3, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "click_base_add", "value": 1.0},
	},
	"redireccion_energia": {
		"name": "Redirección de Energía",
		"flavor": "Nada se pierde. Todo fluye al sustrato.",
		"cat": "economia", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "click_to_passive_ratio", "value": 0.10},
	},
	"legado_metabolico": {
		"name": "Legado Metabólico",
		"flavor": "El ciclo anterior deja nutrientes para el siguiente.",
		"cat": "economia", "cost": 3, "cost_growth": 1.40, "max_level": 5,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "run_start_money", "value": 150.0},
	},
	"sincronia_total": {
		"name": "Sincronía Total",
		"flavor": "La biomasa y el gesto se vuelven uno.",
		"cat": "economia", "cost": 7, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "beta_affects_click", "value": 1.0},
	},

	# ────────────────────────────────────────────────
	# ESTRUCTURA (5)
	# ────────────────────────────────────────────────
	"inercia_escala": {
		"name": "Inercia de Escala",
		"flavor": "El orden administrativo se vuelve ventaja cinética.",
		"cat": "estructura", "cost": 6, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "accounting_md_bonus", "value": 0.05},
	},
	"horizonte_estructural": {
		"name": "Horizonte Estructural",
		"flavor": "El techo se disuelve. La rigidez puede crecer sin límite.",
		"cat": "estructura", "cost": 10, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "remove_kappa_cap", "value": 1.0},
	},
	"deriva_controlada": {
		"name": "Deriva Controlada",
		"flavor": "La persistencia ya no espera. Converge más rápido hacia su límite.",
		"cat": "estructura", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "persistence_conv_speed", "value": 0.40},
	},
	"plasticidad_adaptativa": {
		"name": "Plasticidad Adaptativa",
		"flavor": "El sistema aprendió a doblar antes de romperse.",
		"cat": "estructura", "cost": 6, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "omega_min_floor", "value": 0.30},
	},
	"memoria_estructural": {
		"name": "Memoria Estructural",
		"flavor": "Cada run enseña al sistema dónde duele menos crecer.",
		"cat": "estructura", "cost": 4, "cost_growth": 1.40, "max_level": 3,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "structural_cost_reduction", "value": 0.05},
	},

	# ────────────────────────────────────────────────
	# BIOLOGÍA (3)
	# ────────────────────────────────────────────────
	"absorcion_mejorada": {
		"name": "Absorción Mejorada",
		"flavor": "Las hifas recuerdan cómo alimentarse del caos.",
		"cat": "biologia", "cost": 4, "cost_growth": 1.50, "max_level": 2,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "nutrient_absorb_mult", "value": 0.20},
	},
	"hifas_persistentes": {
		"name": "Hifas Persistentes",
		"flavor": "El micelio no empieza desde cero. Empieza desde donde lo dejaste.",
		"cat": "biologia", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "start_biomasa", "value": 0.5},
	},
	"micelio_resiliente": {
		"name": "Micelio Resiliente",
		"flavor": "El hongo ya no colapsa. Aprende a vivir con el estrés.",
		"cat": "biologia", "cost": 7, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "beta_floor", "value": 1.0},
	},

	# ────────────────────────────────────────────────
	# CONOCIMIENTO (4)
	# ────────────────────────────────────────────────
	"observatorio_genomico": {
		"name": "Observatorio Genómico",
		"flavor": "Ver más del sistema también es poder.",
		"cat": "conocimiento", "cost": 6, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "unlock_hidden_achievements", "value": 1.0},
	},
	"analisis_de_tension": {
		"name": "Análisis de Tensión",
		"flavor": "El estrés estructural se vuelve legible.",
		"cat": "conocimiento", "cost": 3, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "show_epsilon_detail", "value": 1.0},
	},
	"memoria_de_run": {
		"name": "Memoria de Run",
		"flavor": "Cada ciclo biótico deja un registro. El observatorio recuerda.",
		"cat": "conocimiento", "cost": 2, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "show_run_history", "value": 1.0},
	},
	"predictor_estructural": {
		"name": "Predictor Estructural",
		"flavor": "El sistema avisa antes de que el estrés lo alcance.",
		"cat": "conocimiento", "cost": 4, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "warn_epsilon_threshold", "value": 1.0},
	},
	"slot_extra": {
		"name": "Slot Adicional",
		"flavor": "Cada slot abre un universo paralelo donde experimentar otro destino.",
		"cat": "conocimiento", "cost": 5, "cost_growth": 2.0, "max_level": 5,
		"reveal": {"type": "always"}, "unlock": {"type": "always"},
		"effect": {"type": "unlock_save_slot", "value": 1.0},
	},

	# ────────────────────────────────────────────────
	# RUTAS (12) — se revelan/desbloquean según historial de rutas
	# ────────────────────────────────────────────────
	"presion_rentable": {
		"name": "Presión Rentable",
		"flavor": "El colapso acelerado dejó enseñanzas. Las mejoras cuestan menos en el caos.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HIPERASIMILACION"},
		"unlock": {"type": "route_closed", "route": "HIPERASIMILACION"},
		"effect": {"type": "click_upgrade_discount_when_epsilon", "value": 0.80},
	},
	"equilibrio_heredado": {
		"name": "Equilibrio Heredado",
		"flavor": "La homeostasis no termina con la run. Sobrevive en el siguiente ciclo.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HOMEOSTASIS"},
		"unlock": {"type": "route_closed", "route": "HOMEOSTASIS"},
		"effect": {"type": "omega_recovery_speed", "value": 1.25},
	},
	"sangre_negra": {
		"name": "Sangre Negra",
		"flavor": "El parasitismo dejó huellas en el sustrato. La biomasa recuerda el poder.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "PARASITISMO"},
		"unlock": {"type": "route_closed", "route": "PARASITISMO"},
		"effect": {"type": "parasitism_biomasa_start_mult", "value": 1.30},
	},
	"resonancia_simbionte": {
		"name": "Resonancia Simbionte",
		"flavor": "La simbiosis no termina. Se transfiere al siguiente huésped.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "SIMBIOSIS"},
		"unlock": {"type": "route_closed", "route": "SIMBIOSIS"},
		"effect": {"type": "simbiosis_click_bonus", "value": 0.20},
	},
	"deriva_esporada": {
		"name": "Deriva Esporada",
		"flavor": "Las esporas no desaparecen. Regresan convertidas en legado.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_any", "routes": ["ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL"]},
		"unlock": {"type": "route_closed_any", "routes": ["ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL"]},
		"effect": {"type": "pl_gain_mult", "value": 1.25},
	},
	"umbral_cognitivo": {
		"name": "Umbral Cognitivo",
		"flavor": "La singularidad dejó una grieta. El conocimiento fluye a través de ella.",
		"cat": "ruta", "cost": 6, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "SINGULARIDAD"},
		"unlock": {"type": "route_closed", "route": "SINGULARIDAD"},
		"effect": {"type": "start_nivel_cognitivo_bonus", "value": 1.0},
	},
	"umbral_adaptativo": {
		"name": "Umbral Adaptativo",
		"flavor": "Alostasis enseñó que la perturbación también puede anticiparse.",
		"cat": "ruta", "cost": 6, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "ALLOSTASIS"},
		"unlock": {"type": "route_closed", "route": "ALLOSTASIS"},
		"effect": {"type": "disturbance_recovery_speed", "value": 1.40},
	},
	"cristalizacion_permanente": {
		"name": "Cristalización Permanente",
		"flavor": "Homeorresis probó que el orden puede ser permanente.",
		"cat": "ruta", "cost": 6, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HOMEORHESIS"},
		"unlock": {"type": "route_closed", "route": "HOMEORHESIS"},
		"effect": {"type": "omega_shock_reduction", "value": 0.50},
	},
	"eco_panspermico": {
		"name": "Eco Panspérmico",
		"flavor": "Las esporas viajaron más lejos de lo que el sistema esperaba.",
		"cat": "ruta", "cost": 7, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_any", "routes": ["PANSPERMIA NEGRA", "ESPORULACION", "ESPORULACIÓN"]},
		"unlock": {"type": "route_closed_any", "routes": ["PANSPERMIA NEGRA"]},
		"effect": {"type": "start_biomasa", "value": 1.0},
	},
	"simbiosis_agresiva": {
		"name": "Simbiosis Agresiva",
		"flavor": "Dos rutas contrarias dejan un híbrido que el sistema nunca esperó.",
		"cat": "ruta", "cost": 8, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_all", "routes": ["SIMBIOSIS", "PARASITISMO"]},
		"unlock": {"type": "route_closed_all", "routes": ["SIMBIOSIS", "PARASITISMO"]},
		"effect": {"type": "hybrid_symparasit_mult", "value": 1.15},
	},
	"colapso_controlado": {
		"name": "Colapso Controlado",
		"flavor": "Cuando el horizonte se rompe, el colapso se vuelve táctica.",
		"cat": "ruta", "cost": 8, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HIPERASIMILACION"},
		"unlock": {"type": "route_closed", "route": "HIPERASIMILACION", "also_requires_buff": "horizonte_estructural"},
		"effect": {"type": "epsilon_peak_pl_bonus", "value": 2.0},
	},
	"resonancia_cognitiva": {
		"name": "Resonancia Cognitiva",
		"flavor": "El capital cognitivo no muere con la run. Deja un eco.",
		"cat": "ruta", "cost": 7, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"},
		"unlock": {"type": "mu_peak_reached", "threshold": 2.5},
		"effect": {"type": "start_nivel_cognitivo_bonus", "value": 1.0},
	},

	# ────────────────────────────────────────────────
	# NG+ (6) — costo 0, se otorgan vía grant_buff() al completar rutas avanzadas
	# ────────────────────────────────────────────────
	"legado_alostasis": {
		"name": "Resiliencia Alostática",
		"flavor": "El sistema ha aprendido a recalibrarse tras el caos.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "ALLOSTASIS"},
		"unlock": {"type": "route_closed", "route": "ALLOSTASIS"},
		"effect": {"type": "legado_alostasis_active", "value": 1.0},
	},
	"legado_homeorresis": {
		"name": "Trascendencia Cristalina",
		"flavor": "El hongo ya no regula el estrés. Directamente lo trasciende.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HOMEORHESIS"},
		"unlock": {"type": "route_closed", "route": "HOMEORHESIS"},
		"effect": {"type": "legado_homeorresis_active", "value": 1.0},
	},
	"semilla_cosmica": {
		"name": "Semilla Cósmica",
		"flavor": "Las esporas llegaron más lejos de lo que el sistema podía medir.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_any", "routes": ["PANSPERMIA NEGRA", "ESPORULACION", "ESPORULACIÓN"]},
		"unlock": {"type": "route_closed_any", "routes": ["PANSPERMIA NEGRA", "ESPORULACION", "ESPORULACIÓN"]},
		"effect": {"type": "semilla_cosmica_active", "value": 1.0},
	},
	"mente_colmena": {
		"name": "Mente Colmena",
		"flavor": "La singularidad no terminó. Se distribuyó.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_any", "routes": ["SINGULARIDAD", "MENTE COLMENA DISTRIBUIDA"]},
		"unlock": {"type": "route_closed_any", "routes": ["SINGULARIDAD", "MENTE COLMENA DISTRIBUIDA"]},
		"effect": {"type": "mente_colmena_active", "value": 1.0},
	},
	"metabolismo_glitch": {
		"name": "Metabolismo Oscuro",
		"flavor": "El parasitismo dejó algo en el sustrato que no debería estar ahí.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "PARASITISMO"},
		"unlock": {"type": "route_closed", "route": "PARASITISMO"},
		"effect": {"type": "metabolismo_glitch_active", "value": 1.0},
	},
	"aura_dorada": {
		"name": "Aura Dorada",
		"flavor": "La simbiosis perfecta deja un residuo luminoso en el sistema.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "SIMBIOSIS"},
		"unlock": {"type": "route_closed", "route": "SIMBIOSIS"},
		"effect": {"type": "aura_dorada_active", "value": 1.0},
	},

	# ────────────────────────────────────────────────
	# SECRETOS (3)
	# ────────────────────────────────────────────────
	"glitch_persistente": {
		"name": "Glitch Persistente",
		"flavor": "El error no fue corregido. Fue recordado.",
		"cat": "secreto", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "achievement_unlocked", "id": "hongo_realidad"},
		"unlock": {"type": "route_closed", "route": "SINGULARIDAD"},
		"effect": {"type": "singularidad_passive_bonus", "value": 0.15},
	},
	"setpoint_adaptativo": {
		"name": "Setpoint Adaptativo",
		"flavor": "El sistema ya sabe dónde quiere estar. Solo necesita recordarlo.",
		"cat": "secreto", "cost": 3, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 1},
		"unlock": {"type": "route_closed", "route": "HOMEORHESIS"},
		"effect": {"type": "omega_recovery_speed", "value": 1.50},
	},
	"eco_primordial": {
		"name": "Eco Primordial",
		"flavor": "Más allá del primer ciclo, algo del sistema original persiste.",
		"cat": "secreto", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 2},
		"unlock": {"type": "transcendence_count", "count": 2},
		"effect": {"type": "all_income_mult", "value": 0.10},
	},
}

# Orden de categorías para la UI
const CAT_ORDER: Array = ["economia", "estructura", "biologia", "conocimiento", "ruta", "ng_plus", "secreto"]
const CAT_NAMES: Dictionary = {
	"economia":     "ECONOMÍA",
	"estructura":   "ESTRUCTURA",
	"biologia":     "BIOLOGÍA",
	"conocimiento": "CONOCIMIENTO",
	"ruta":         "RUTAS",
	"ng_plus":      "NG+",
	"secreto":      "???",
}

# =====================================================
#  ESTADO DEL JUGADOR
# =====================================================

# Nuevo formato: { id: { "level": int, "seen": bool } }
# Reemplaza el antiguo unlocked_legacies: { id: bool }
var buffs: Dictionary = {}

# Estados de activación manual — { id: bool }
# Si no está en este dict, el buff se considera ACTIVADO por defecto.
# Solo los buffs ya comprados (level > 0) pueden togglearse.
var buff_enabled: Dictionary = {}

var legacy_points: int = 0
var total_runs: int = 0
var last_run_ending: String = ""
var internal_spores_total: float = 0.0

# Historial de Ciclos Bióticos (gateado por upgrade memoria_de_run)
# current_cycle_history: runs del loop de trascendencia actual (se vacía al trascender)
# all_time_history: todos los ciclos desde el primer save (persistente)
var current_cycle_history: Array = []
var all_time_history: Array = []

# Estadísticas de run que sirven como condiciones de desbloqueo
var mu_peak_achieved: bool = false   # true si alguna run terminó con μ ≥ 2.5

# --- LOGROS (persistentes) ---
var achievement_data: Dictionary = {}

# =====================================================
#  TRASCENDENCIA (v0.9.2)
# =====================================================
var esencia: int = 0
var trascendencia_count: int = 0
var first_trascendencia_shown: bool = false
var endings_achieved: Dictionary = {}
var cosmic_unlocked: Dictionary = {}

# =====================================================
#  RUTAS POST-TRASCENDENCIA (v0.9.8)
# =====================================================
var post_tras_route: String = ""  # "vacio" | "carnaval" | "reencarnacion" | ""
var reencarnacion_snapshot: Dictionary = {}  # Serializado de UpgradeManager al momento de trascender

const ENDING_FAMILIES := {
	"HOMEOSTASIS": "orden", "ALLOSTASIS": "orden",
	"HOMEORHESIS": "orden", "SINGULARIDAD": "orden",
	"ESPORULACION": "biologia", "ESPORULACIÓN": "biologia",
	"ESPORULACION TOTAL": "biologia", "PARASITISMO": "biologia",
	"SIMBIOSIS": "biologia", "PANSPERMIA NEGRA": "biologia",
	"MENTE COLMENA DISTRIBUIDA": "biologia",
	"HIPERASIMILACION": "colapso", "HIPERASIMILACIÓN": "colapso",
	"DEPREDADOR DE REALIDADES": "colapso",
	"METABOLISMO OSCURO": "colapso", "MUTACION_FINAL": "colapso",
}

const TRASCENDENCIA_PL_GATE := 50

const TRASCENDENCIA_TITLES := [
	"", "Trascendido", "Trascendido II", "Trascendido III",
	"Arquitecto Cósmico", "Arquitecto Cósmico II", "Demiurgo",
]

# =====================================================
#  BANCO CÓSMICO
# =====================================================
const COSMIC_DATA := {
	"impulso_inicial": {
		"cost": 6, "name": "Impulso Inicial",
		"desc": "Comenzás cada run con $500 ya generados. La economía tiene memoria del ciclo anterior.",
		"tier": 1,
	},
	"omega_primordial": {
		"cost": 8, "name": "Omega Primordial",
		"desc": "Tu Ω_min sube permanentemente +0.05 al inicio de cada run. El sistema recuerda su flexibilidad.",
		"tier": 1,
	},
	"resonancia_biotica": {
		"cost": 10, "name": "Resonancia Biótica",
		"desc": "Tu biomasa inicial es 1.5 (en lugar de 0). El sustrato biológico persiste entre ciclos.",
		"tier": 1,
	},
	"deflacion_cosmica": {
		"cost": 12, "name": "Deflación Cósmica",
		"desc": "El escalado de precios de todos los upgrades se reduce un 8% adicional.",
		"tier": 1,
	},
	"eco_de_legado": {
		"cost": 15, "name": "Eco de Legado",
		"desc": "Al inicio de cada run ganás +5 PL automáticos para gastar en el Banco Genético.",
		"tier": 1,
	},
	"arbol_acelerado": {
		"cost": 18, "name": "Árbol Acelerado",
		"desc": "Los timers de activación de MET.OSCURO y DEPREDADOR se reducen un 40%.",
		"tier": 2,
	},
	"memoria_persistente": {
		"cost": 22, "name": "Memoria Persistente",
		"desc": "Al inicio de run, el primer nivel de Contabilidad y Trueque son gratuitos automáticamente.",
		"tier": 2,
	},
	"convergencia_ciclica": {
		"cost": 28, "name": "Convergencia Cíclica",
		"desc": "Cada trascendencia acumulada suma +5% a todos tus ingresos globales de forma permanente.",
		"tier": 2,
	},
	"fractura_epistemica": {
		"cost": 35, "name": "Fractura Epistémica",
		"desc": "Desbloquea la ruta COLAPSO CONTROLADO: cuando ε > 0.90 y Ω > 0.30, podés cerrar la run con +6 PL.",
		"tier": 3,
	},
	"sustrato_cosmico": {
		"cost": 50, "name": "Sustrato Cósmico",
		"desc": "La próxima trascendencia otorga el doble de Esencia (Ξ ×2). Efecto de un solo uso por compra.",
		"tier": 3,
	},
}

# =====================================================
#  CICLO DE VIDA
# =====================================================

func _ready():
	load_legacy()

## Resetea todo el estado en memoria y recarga desde el slot activo.
## Debe llamarse desde MainMenu al hacer switch de slot, porque los autoloads
## persisten entre reload_current_scene() y no reinician su _ready().
func reload_for_slot() -> void:
	legacy_points = 0
	buffs = {}
	buff_enabled = {}
	internal_spores_total = 0.0
	total_runs = 0
	last_run_ending = ""
	mu_peak_achieved = false
	esencia = 0
	trascendencia_count = 0
	first_trascendencia_shown = false
	endings_achieved = {}
	cosmic_unlocked = {}
	achievement_data = {}
	post_tras_route = ""
	reencarnacion_snapshot = {}
	current_cycle_history = []
	all_time_history = []
	load_legacy()
	print("🔄 [Legacy] Recargado para slot: ", SlotManager.active_slot)

# =====================================================
#  PERSISTENCIA
# =====================================================

func save_legacy():
	var data := {
		"legacy_points": legacy_points,
		"buffs": buffs,
		"spores_buffer": internal_spores_total,
		"total_runs": total_runs,
		"last_run_ending": last_run_ending,
		"mu_peak_achieved": mu_peak_achieved,
		"esencia": esencia,
		"trascendencia_count": trascendencia_count,
		"first_trascendencia_shown": first_trascendencia_shown,
		"endings_achieved": endings_achieved,
		"cosmic_unlocked": cosmic_unlocked,
		"achievement_data": achievement_data,
		"buff_enabled": buff_enabled,
		"post_tras_route": post_tras_route,
		"reencarnacion_snapshot": reencarnacion_snapshot,
		"current_cycle_history": current_cycle_history,
		"all_time_history": all_time_history,
	}
	var path := LEGACY_PATH
	# Asegurar que el directorio del slot existe antes de escribir
	var slot_dir := SlotManager.get_slot_dir(SlotManager.active_slot)
	if not DirAccess.dir_exists_absolute(slot_dir):
		DirAccess.make_dir_recursive_absolute(slot_dir)
	# AUTOBACKUP: copiar archivo existente a .bak antes de sobreescribir
	_backup_legacy(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("💾 [Legacy] Banco genético guardado.")

## Copia legacy_bank.json → legacy_bank.json.bak si tiene datos reales (> 100 bytes).
## Llamado siempre antes de sobreescribir para que haya un fallback de la última versión buena.
func _backup_legacy(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var src := FileAccess.open(path, FileAccess.READ)
	if not src:
		return
	var content := src.get_as_text()
	src.close()
	if content.length() < 100:
		return   # archivo vacío o trivial, no vale backupear
	var bak := FileAccess.open(path + ".bak", FileAccess.WRITE)
	if bak:
		bak.store_string(content)
		bak.close()

## Parsea un archivo JSON y devuelve su contenido como Dictionary, o {} si falla.
func _parse_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	return json.data if json.data is Dictionary else {}

## Devuelve true si el diccionario cargado no tiene progreso real.
## Evita usar como "banco vacío" un archivo que se inicializó con defaults.
func _is_empty_bank(data: Dictionary) -> bool:
	if data.is_empty():
		return true
	return (data.get("trascendencia_count", 0) == 0
		and (data.get("buffs", {}) as Dictionary).is_empty()
		and data.get("legacy_points", 0) == 0
		and (data.get("endings_achieved", {}) as Dictionary).is_empty())

func load_legacy():
	var path := LEGACY_PATH
	var data := _parse_json_file(path)

	# RECOVERY: si el archivo principal está vacío/corrupto y hay backup con datos reales,
	# restaurar desde el backup y reescribir el principal.
	if _is_empty_bank(data):
		var bak_path := path + ".bak"
		if FileAccess.file_exists(bak_path):
			var bak_data := _parse_json_file(bak_path)
			if not _is_empty_bank(bak_data):
				print("⚠️ [Legacy] Banco principal vacío — restaurando desde backup automático")
				data = bak_data
				var restore := FileAccess.open(path, FileAccess.WRITE)
				if restore:
					restore.store_string(JSON.stringify(data))
					restore.close()

	if data.is_empty():
		return

	legacy_points = data.get("legacy_points", 0)
	internal_spores_total = data.get("spores_buffer", 0.0)
	total_runs = data.get("total_runs", 0)
	last_run_ending = data.get("last_run_ending", "")
	mu_peak_achieved = data.get("mu_peak_achieved", false)
	esencia = data.get("esencia", 0)
	trascendencia_count = data.get("trascendencia_count", 0)
	first_trascendencia_shown = data.get("first_trascendencia_shown", false)
	endings_achieved = data.get("endings_achieved", {})
	cosmic_unlocked = data.get("cosmic_unlocked", {})
	achievement_data = data.get("achievement_data", {})
	buff_enabled = data.get("buff_enabled", {})
	post_tras_route = data.get("post_tras_route", "")
	reencarnacion_snapshot = data.get("reencarnacion_snapshot", {})
	current_cycle_history = data.get("current_cycle_history", [])
	all_time_history = data.get("all_time_history", [])

	# Cargar buffs — con migración desde formato antiguo (unlocked_legacies: { id: bool })
	if data.has("buffs"):
		var raw: Dictionary = data.get("buffs", {})
		for k in raw:
			var v = raw[k]
			if v is Dictionary:
				buffs[k] = v
			elif v == true:
				# Migración: bool → level 1
				buffs[k] = {"level": 1, "seen": true}
	elif data.has("unlocked_legacies"):
		# Migración completa desde formato pre-v1.0
		var old: Dictionary = data.get("unlocked_legacies", {})
		for k in old:
			if old[k]:
				buffs[k] = {"level": 1, "seen": true}
		print("🔄 [Legacy] Migración desde unlocked_legacies completada.")

	# Propagar logros al AchievementManager
	if AchievementManager:
		AchievementManager.load_data(achievement_data)

	_migrate_retroactive_endings()
	print("📂 [Legacy] Banco genético cargado. PL:", legacy_points, " Ξ:", esencia, " T#:", trascendencia_count, " buffs:", buffs.size())

func _migrate_retroactive_endings() -> void:
	if endings_achieved.size() > 0:
		return
	if total_runs == 0 and last_run_ending == "":
		return

	# Inferir rutas desde buffs NG+ (cada uno implica haber completado la ruta)
	if get_buff_level("legado_alostasis") > 0:
		endings_achieved["ALLOSTASIS"] = true
		endings_achieved["HOMEOSTASIS"] = true
	if get_buff_level("legado_homeorresis") > 0:
		endings_achieved["HOMEORHESIS"] = true
		endings_achieved["ALLOSTASIS"] = true
		endings_achieved["HOMEOSTASIS"] = true
	if get_buff_level("semilla_cosmica") > 0:
		endings_achieved["PANSPERMIA NEGRA"] = true
		endings_achieved["ESPORULACION"] = true
	if get_buff_level("mente_colmena") > 0:
		endings_achieved["MENTE COLMENA DISTRIBUIDA"] = true
		endings_achieved["SINGULARIDAD"] = true
	if get_buff_level("metabolismo_glitch") > 0:
		endings_achieved["PARASITISMO"] = true
	if get_buff_level("aura_dorada") > 0:
		endings_achieved["SIMBIOSIS"] = true

	if last_run_ending != "" and last_run_ending != "NONE":
		endings_achieved[last_run_ending] = true

	if endings_achieved.size() > 0:
		print("🔄 [Legacy] Migración retroactiva: ", endings_achieved.size(), " rutas recuperadas")
		save_legacy()

# =====================================================
#  API DE BUFFS — LECTURA
# =====================================================

## Retrocompat: devuelve true si el buff tiene level >= 1 Y está activado
func get_buff_value(id: String) -> bool:
	if get_buff_level(id) <= 0:
		return false
	# Respeta el toggle manual: false en buff_enabled = desactivado explícitamente
	return buff_enabled.get(id, true)

## Activa o desactiva el efecto de un buff ya comprado.
## Devuelve el nuevo estado (true = activo).
func toggle_buff_enabled(id: String) -> bool:
	if get_buff_level(id) <= 0:
		return false  # No se puede togglear un buff no comprado
	var current: bool = buff_enabled.get(id, true)
	buff_enabled[id] = not current
	save_legacy()
	print("🔄 [Legacy] Buff %s → %s" % [id, "ACTIVO" if buff_enabled[id] else "INACTIVO"])
	return buff_enabled[id]

## Devuelve true si el buff está activo (comprado y no desactivado manualmente)
func is_buff_active(id: String) -> bool:
	return get_buff_value(id)

## Nivel actual del buff (0 si no fue comprado)
func get_buff_level(id: String) -> int:
	var entry: Dictionary = buffs.get(id, {})
	return int(entry.get("level", 0))

## Suma de todos los efectos del mismo tipo, escalados por nivel
## Ejemplo: get_effect_value("run_start_money") → 300.0 si legado_metabolico está en level 2
func get_effect_value(effect_type: String) -> float:
	var total: float = 0.0
	for id in buffs:
		var lvl: int = get_buff_level(id)
		if lvl <= 0:
			continue
		if not LEGACY_DEFS.has(id):
			continue
		var def: Dictionary = LEGACY_DEFS[id]
		var eff: Dictionary = def.get("effect", {})
		if eff.get("type", "") == effect_type:
			total += float(eff.get("value", 0.0)) * float(lvl)
	return total

## Devuelve true si el buff debería ser visible en la UI
func is_revealed(id: String) -> bool:
	if not LEGACY_DEFS.has(id):
		return false
	var def: Dictionary = LEGACY_DEFS[id]
	var reveal: Dictionary = def.get("reveal", {"type": "always"})
	return _check_condition(reveal)

## Devuelve true si el buff puede ser comprado (condición cumplida, independiente del PL)
func is_unlockable(id: String) -> bool:
	if not LEGACY_DEFS.has(id):
		return false
	var def: Dictionary = LEGACY_DEFS[id]
	var unlock: Dictionary = def.get("unlock", {"type": "always"})
	if not _check_condition(unlock):
		return false
	# Condición adicional opcional: also_requires_buff
	var req_buff: String = unlock.get("also_requires_buff", "")
	if req_buff != "" and get_buff_level(req_buff) == 0:
		return false
	return true

## Condición genérica — evalúa un dict { type, ... }
func _check_condition(cond: Dictionary) -> bool:
	match cond.get("type", "always"):
		"always":
			return true
		"route_closed":
			var route: String = cond.get("route", "")
			return endings_achieved.get(route, false)
		"route_closed_any":
			var routes: Array = cond.get("routes", [])
			for r in routes:
				if endings_achieved.get(r, false):
					return true
			return false
		"route_closed_all":
			var routes: Array = cond.get("routes", [])
			if routes.is_empty():
				return false
			for r in routes:
				if not endings_achieved.get(r, false):
					return false
			return true
		"achievement_unlocked":
			var ach_id: String = cond.get("id", "")
			if AchievementManager and AchievementManager.has_method("is_unlocked"):
				return AchievementManager.is_unlocked(ach_id)
			return false
		"transcendence_count":
			return trascendencia_count >= int(cond.get("count", 1))
		"buff_owned":
			return get_buff_level(cond.get("id", "")) > 0
		"mu_peak_reached":
			return mu_peak_achieved
	return true

# =====================================================
#  API DE BUFFS — ESCRITURA
# =====================================================

## Costo actual del buff según su nivel actual
func get_current_cost(id: String) -> int:
	if not LEGACY_DEFS.has(id):
		return 999
	var def: Dictionary = LEGACY_DEFS[id]
	var base: int = int(def.get("cost", 1))
	var growth: float = float(def.get("cost_growth", 1.0))
	var current_lvl: int = get_buff_level(id)
	if growth <= 1.0 or current_lvl == 0:
		return base
	return int(float(base) * pow(growth, float(current_lvl)))

## True si el jugador puede comprar el buff ahora mismo
func can_afford(id: String) -> bool:
	if not LEGACY_DEFS.has(id):
		return false
	if not is_revealed(id):
		return false
	if not is_unlockable(id):
		return false
	var def: Dictionary = LEGACY_DEFS[id]
	var max_lvl: int = int(def.get("max_level", 1))
	if get_buff_level(id) >= max_lvl:
		return false
	return legacy_points >= get_current_cost(id)

## Compra un nivel del buff. Devuelve true si tuvo éxito.
func purchase_legacy(id: String) -> bool:
	if not can_afford(id):
		return false
	var cost: int = get_current_cost(id)
	legacy_points -= cost
	_set_buff_level(id, get_buff_level(id) + 1)
	save_legacy()
	AudioManager.play_sfx("upgrade")
	print("✨ [Legacy] Comprado: %s (nivel %d) por %d PL" % [id, get_buff_level(id), cost])
	# Side-effects post-compra para upgrades con efecto fuera del estado del legacy
	_apply_post_purchase_effects(id)
	return true

## Side-effects de upgrades cuyos efectos viven fuera del estado del legacy
## (p.ej. desbloquear un slot global en SlotManager).
func _apply_post_purchase_effects(id: String) -> void:
	var entry: Dictionary = LEGACY_DEFS.get(id, {})
	var effect: Dictionary = entry.get("effect", {})
	match effect.get("type", ""):
		"unlock_save_slot":
			SlotManager.unlock_extra_slot()

## Otorga un buff directamente sin costo (para buffs NG+ otorgados por rutas)
func grant_buff(id: String) -> void:
	if get_buff_level(id) > 0:
		return  # Ya tiene el buff
	_set_buff_level(id, 1)
	save_legacy()
	print("🎁 [Legacy] Buff concedido: ", id)

func _set_buff_level(id: String, level: int) -> void:
	if not buffs.has(id):
		buffs[id] = {"level": 0, "seen": false}
	buffs[id]["level"] = level

## Marca el buff como visto en la UI (para el badge "NUEVO")
func mark_buff_seen(id: String) -> void:
	if buffs.has(id):
		buffs[id]["seen"] = true

func has_unseen_buff() -> bool:
	for id in buffs:
		var entry: Dictionary = buffs.get(id, {})
		if not entry.get("seen", true):
			return true
	return false

# =====================================================
#  NOTIFICACIONES DEL SISTEMA DE JUEGO
# =====================================================

## Llamar desde RunManager al cerrar una run con μ alto
func on_run_ended(mu_final: float) -> void:
	if mu_final >= 2.5 and not mu_peak_achieved:
		mu_peak_achieved = true
		print("🧠 [Legacy] mu_peak_achieved desbloqueado (μ = %.2f)" % mu_final)
		save_legacy()

## Registra una run terminada en current_cycle_history y all_time_history.
## Llamado desde RunManager.close_run() después de calcular pl_to_add.
func record_run_end(route: String, reason: String, run_time: float, mu_peak: float, eps_peak: float, pl_gained: int) -> void:
	var entry := {
		"cycle_index": total_runs + 1,
		"trascendencia_tier": trascendencia_count,
		"route": route,
		"reason": reason,
		"run_time": run_time,
		"mu_peak": mu_peak,
		"eps_peak": eps_peak,
		"pl_gained": pl_gained,
		"timestamp": Time.get_unix_time_from_system(),
	}
	current_cycle_history.append(entry)
	all_time_history.append(entry)
	save_legacy()
	print("📜 [Legacy] Run registrada: ciclo #%d → %s" % [entry.cycle_index, route])

## Gate del panel de historial — requiere comprar memoria_de_run en Banco Genético.
func has_run_history_unlocked() -> bool:
	return get_buff_value("memoria_de_run")

# =====================================================
#  CONVERSIÓN DE ESPORAS
# =====================================================

func add_spores(amount: float):
	internal_spores_total += amount
	var new_pl: int = int(internal_spores_total / 50.0)
	if new_pl > 0:
		# Aplicar multiplicador de PL si deriva_esporada está activo
		var pl_mult: float = get_effect_value("pl_gain_mult")
		if pl_mult > 0.0:
			new_pl = int(float(new_pl) * pl_mult)
		add_pl(new_pl)
		internal_spores_total -= (int(internal_spores_total / 50.0) * 50.0)
	save_legacy()

func add_pl(amount: int):
	legacy_points += amount
	save_legacy()
	print("✨ [Legacy] Ganaste +", amount, " PL. Total:", legacy_points)

func increment_run():
	total_runs += 1
	save_legacy()
	print("📈 Ciclo Biótico completado. Total: ", total_runs)

# =====================================================
#  LOGROS
# =====================================================

func save_achievement_data(data: Dictionary) -> void:
	achievement_data = data.duplicate()
	save_legacy()

# =====================================================
#  TRASCENDENCIA — API pública (v0.9.2)
# =====================================================

func mark_ending_achieved(route: String) -> void:
	if route == "" or route == "NONE":
		return
	if not endings_achieved.get(route, false):
		endings_achieved[route] = true
		save_legacy()
		print("🏁 [Legacy] Ruta registrada: ", route)

func get_family_progress() -> Dictionary:
	var prog := {"orden": false, "biologia": false, "colapso": false}
	for route in endings_achieved.keys():
		if endings_achieved[route]:
			var fam: String = ENDING_FAMILIES.get(route, "")
			if prog.has(fam):
				prog[fam] = true
	return prog

func unique_endings_count() -> int:
	var n := 0
	for route in endings_achieved.keys():
		if endings_achieved[route]: n += 1
	return n

func can_transcend() -> bool:
	var prog := get_family_progress()
	if not (prog.orden and prog.biologia and prog.colapso):
		return false
	return legacy_points >= TRASCENDENCIA_PL_GATE

func get_transcend_gate_status() -> String:
	var prog := get_family_progress()
	var t := ""
	t += ("✓" if prog.orden else "✗") + " Familia ORDEN (Homeostasis/Allostasis/Homeorresis/Singularidad)\n"
	t += ("✓" if prog.biologia else "✗") + " Familia BIOLOGÍA (Esporulación/Parasitismo/Simbiosis/Panspermia)\n"
	t += ("✓" if prog.colapso else "✗") + " Familia COLAPSO (Hiperasimilación/Depredador/Met.Oscuro)\n"
	t += ("✓" if legacy_points >= TRASCENDENCIA_PL_GATE else "✗") + " PL acumulado ≥ %d (tenés %d)" % [TRASCENDENCIA_PL_GATE, legacy_points]
	return t

func calculate_esencia_gain() -> int:
	var from_pl := int(legacy_points / 10.0)
	var from_routes := unique_endings_count() * 5
	var tier_bonus := trascendencia_count * 2
	return from_pl + from_routes + tier_bonus

func transcend() -> int:
	if not can_transcend():
		return 0

	var esencia_gain := calculate_esencia_gain()

	if has_cosmic_buff("sustrato_cosmico"):
		esencia_gain *= 2
		cosmic_unlocked["sustrato_cosmico"] = false
		print("✦ [Cosmic] Sustrato Cósmico consumido — Esencia ×2 aplicado")

	esencia += esencia_gain
	trascendencia_count += 1
	TelemetryManager.track_event("trascendencia", {
		"trascendencia_count_new": trascendencia_count
	})

	# Capturar snapshot de upgrades para la ruta Reencarnación Heredada
	reencarnacion_snapshot = UpgradeManager.serialize()
	print("📸 [Post-Tras] Snapshot de upgrades capturado (%d keys)" % reencarnacion_snapshot.size())

	# Reset de estado entre runs (PL, buffs legacy, esporas)
	legacy_points = 0
	internal_spores_total = 0.0
	buffs.clear()
	buff_enabled.clear()  # Los buffs desaparecen, los toggles también
	total_runs = 0
	last_run_ending = ""
	mu_peak_achieved = false
	post_tras_route = ""  # El jugador elige la ruta en el picker del MainMenu
	current_cycle_history.clear()  # Datos archivados en all_time_history

	# Se preservan: esencia, trascendencia_count, first_trascendencia_shown,
	# endings_achieved, cosmic_unlocked, achievement_data, reencarnacion_snapshot

	save_legacy()
	print("⚡ [TRASCENDENCIA #%d] +%d Ξ · Total: %d Ξ" % [trascendencia_count, esencia_gain, esencia])
	return esencia_gain

func get_trascendencia_title() -> String:
	if trascendencia_count <= 0:
		return ""
	var idx: int = min(trascendencia_count, TRASCENDENCIA_TITLES.size() - 1)
	return TRASCENDENCIA_TITLES[idx]

# =====================================================
#  BANCO CÓSMICO
# =====================================================

func can_afford_cosmic(cosmic_id: String) -> bool:
	if not COSMIC_DATA.has(cosmic_id): return false
	if cosmic_unlocked.get(cosmic_id, false): return false
	return esencia >= int((COSMIC_DATA[cosmic_id] as Dictionary).get("cost", 999))

func purchase_cosmic(cosmic_id: String) -> bool:
	if not can_afford_cosmic(cosmic_id): return false
	esencia -= int((COSMIC_DATA[cosmic_id] as Dictionary).get("cost", 0))
	cosmic_unlocked[cosmic_id] = true
	save_legacy()
	AudioManager.play_sfx("upgrade")
	print("✨ [Cosmic] Desbloqueado: ", cosmic_id)
	return true

func has_cosmic_buff(cosmic_id: String) -> bool:
	return cosmic_unlocked.get(cosmic_id, false)
