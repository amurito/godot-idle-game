# LegacyDefs.gd
# Definiciones estáticas del árbol de legado: LEGACY_DEFS (40 buffs) + orden de categorías.
# Sin estado — sólo datos. Referenciado como LegacyDefs.LEGACY_DEFS, LegacyDefs.CAT_ORDER, etc.
class_name LegacyDefs

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
		"flavor": "El orden no regresa solo. Regresa más rápido cada vez que lo practicás.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HOMEOSTASIS"},
		"unlock": {"type": "route_closed", "route": "HOMEOSTASIS"},
		"effect": {"type": "omega_min_per_disturbance", "value": 0.04},
		# Efecto: +0.04 Ω_min en burst por perturbación sobrevivida (cap 0.70)
		# Implementado en RunManager.check_shock_tracking()
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
		"flavor": "La simbiosis no termina. La biomasa heredada amplifica cada gesto.",
		"cat": "ruta", "cost": 5, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "SIMBIOSIS"},
		"unlock": {"type": "route_closed", "route": "SIMBIOSIS"},
		"effect": {"type": "simbiosis_click_biomasa_scale", "value": 0.05},
		# Efecto: click × (1 + biomasa × 0.05), cap ×2.5
		# Implementado en EconomyManager.get_click_power()
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
		"flavor": "El sistema recuerda cuánto aprendió. El conocimiento acumulado amplifica cada acción.",
		"cat": "ruta", "cost": 7, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "always"},
		"unlock": {"type": "mu_peak_reached", "threshold": 2.5},
		"effect": {"type": "cognitivo_income_mult_per_level", "value": 0.05},
		# Efecto: +5% a todos los ingresos por nivel cognitivo activo
		# Implementado en EconomyManager.get_click_power() y get_passive_total()
	},
	"entropia_domesticada": {
		"name": "Entropía Domesticada",
		"flavor": "Sostuviste el colapso y no te rompió. La zona roja deja de castigar: alimenta.",
		"cat": "ruta", "cost": 10, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "COLAPSO CONTROLADO"},
		"unlock": {"type": "route_closed", "route": "COLAPSO CONTROLADO"},
		"effect": {"type": "entropia_domesticada_mult", "value": 2.0},
		# Efecto: con ε>0.65, producción × clamp(1 + (ε-0.65)*2.0, 1.0, 2.0)
		# Implementado en EconomyManager.get_click_power() y get_passive_total()
	},

	# ────────────────────────────────────────────────
	# NG+ (6) — costo 0, se otorgan vía grant_buff() al completar rutas avanzadas
	# ────────────────────────────────────────────────
	"legado_alostasis": {
		"name": "Resiliencia Alostática",
		"flavor": "Cada shock superado endurece el sustrato. El caos se vuelve construcción.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "ALLOSTASIS"},
		"unlock": {"type": "route_closed", "route": "ALLOSTASIS"},
		"effect": {"type": "legado_alostasis_active", "value": 1.0},
		# Efecto real: +0.02 Ω_min por perturbación sobrevivida (acumulativo, cap 0.70)
		# Implementado en RunManager.check_shock_tracking()
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
	"semilla_cosmica_oscura": {
		"name": "Semilla Cósmica Oscura",
		"flavor": "Las esporas ya viajaban al vacío. Ahora viajan con memoria de lo que no debió sobrevivir.",
		"cat": "ng_plus", "cost": 8, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "legacy_flag", "flag": "esclerocio_panspermia_done"},
		"unlock": {"type": "legacy_flag", "flag": "esclerocio_panspermia_done"},
		"effect": {"type": "semilla_cosmica_oscura_active", "value": 1.0},
		# Efecto: Memoria Oscura permanente (siempre activa) + ×pasivo SEMILLA_OSCURA_PASIVO_MULT.
		# Desbloqueado por el cruce ESCLEROCIO OSCURO → PANSPERMIA NEGRA (familia COLAPSO × BIOLOGÍA).
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
		"flavor": "La simbiosis perfecta concentra toda su energía en el gesto activo.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "SIMBIOSIS"},
		"unlock": {"type": "route_closed", "route": "SIMBIOSIS"},
		"effect": {"type": "aura_dorada_active", "value": 1.0},
		# Efecto: click ×2.5 (solo click — no afecta pasivo)
	},
	"catabolismo_heredado": {
		"name": "Catabolismo Heredado",
		"flavor": "Las estructuras digeridas no desaparecen. Vuelven como semilla para el siguiente ciclo.",
		"cat": "ng_plus", "cost": 4, "cost_growth": 1.0, "max_level": 3,
		"reveal": {"type": "route_closed", "route": "AUTOFAGIA NECRÓTICA"},
		"unlock": {"type": "route_closed", "route": "AUTOFAGIA NECRÓTICA"},
		"effect": {"type": "run_start_bio", "value": 10.0},
		# Nivel 1 (gratis, otorgado al cerrar la ruta): +10 bio al inicio de run.
		# Nivel 2 (+4 PL): +20 bio. Nivel 3 (+4 PL): +30 bio.
		# Acelera el acceso a mutaciones tempranas en runs posteriores.
	},
	"ciclo_catabolico": {
		"name": "Ciclo Catabólico",
		"flavor": "Que venga de adentro o de afuera, ya no hay distinción. Todo es sustrato.",
		"cat": "ng_plus", "cost": 8, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "legacy_flag", "flag": "autofagia_depredador_done", "description_key": "UNLOCK_REQ_AUTOFAGIA_DEP"},
		"unlock": {"type": "legacy_flag", "flag": "autofagia_depredador_done", "description_key": "UNLOCK_REQ_AUTOFAGIA_DEP"},
		"effect": {"type": "ciclo_catabolico_active", "value": 1.0},
		# Cross AUTOFAGIA NECRÓTICA → DEPREDADOR DE REALIDADES (en ese orden).
		# Efecto: todos los devours en Met.Oscuro (autólisis y depredador) dan ×1.5 bio.
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
