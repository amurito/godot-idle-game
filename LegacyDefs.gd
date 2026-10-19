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
		"cat": "conocimiento", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		# Recompensa de sellar INESTABILIDAD CONSCIENTE (decisión del autor 2026-10-18): ya no se compra.
		"reveal": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
		"unlock": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
		"effect": {"type": "unlock_hidden_achievements", "value": 1.0},
	},
	"analisis_de_tension": {
		"name": "Análisis de Tensión",
		"flavor": "El estrés estructural se vuelve legible.",
		"cat": "conocimiento", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		# Recompensa de sellar INESTABILIDAD CONSCIENTE (decisión del autor 2026-10-18): ya no se compra.
		"reveal": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
		"unlock": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
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
		"cat": "conocimiento", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		# Recompensa de sellar INESTABILIDAD CONSCIENTE (decisión del autor 2026-10-18): ya no se compra.
		"reveal": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
		"unlock": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
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
		"flavor": "Las estructuras digeridas no desaparecen. Vuelven como combustible para el siguiente ciclo.",
		"cat": "ng_plus", "cost": 4, "cost_growth": 1.0, "max_level": 3,
		"reveal": {"type": "route_closed", "route": "AUTOFAGIA NECRÓTICA"},
		"unlock": {"type": "route_closed", "route": "AUTOFAGIA NECRÓTICA"},
		"effect": {"type": "run_start_nutrients", "value": 40.0},
		# Nivel 1 (gratis, otorgado al cerrar la ruta): +40 nutrientes al inicio de run.
		# Nivel 2 (+4 PL): +80 nut. Nivel 3 (+4 PL): +120 nut.
		# Acelera el crecimiento de biomasa desde el primer tick con hifas activas.
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
	"apoptosis_heredada": {
		"name": "Apoptosis Heredada",
		"flavor": "La muerte celular programada ya no es un final. Es una herramienta.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "NECROSIS CONTROLADA"},
		"unlock": {"type": "route_closed", "route": "NECROSIS CONTROLADA"},
		"effect": {"type": "apoptosis_heredada_active", "value": 1.0},
		# Otorgado gratis al cerrar NECROSIS CONTROLADA por 1ª vez.
		# Efecto: con Ω<0.30, click y pasivo escalan clampf(1+(0.30−Ω)×1.67, 1, 1.5).
	},
	"plasticidad_terminal": {
		"name": "Plasticidad Terminal",
		"flavor": "El extremo de la estabilidad y el extremo del colapso son el mismo borde.",
		"cat": "ng_plus", "cost": 8, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "legacy_flag", "flag": "homeorhesis_necrosis_done", "description_key": "UNLOCK_REQ_HOMEORHESIS_NECROSIS"},
		"unlock": {"type": "legacy_flag", "flag": "homeorhesis_necrosis_done", "description_key": "UNLOCK_REQ_HOMEORHESIS_NECROSIS"},
		"effect": {"type": "plasticidad_terminal_active", "value": 1.0},
		# Cross HOMEORHESIS → NECROSIS CONTROLADA (homeorhesis completada alguna vez, luego necrosis).
		# Efecto: ×1.5 income (click y pasivo) cuando Ω>0.55 O Ω<0.10 — premia ambos extremos.
	},
	# ── ACCESOS A SUB-RUTAS DE MET. OSCURO ─────────────────────────────────────
	# Desbloquean los botones de sub-ruta dentro de una run con Met. Oscuro activo.
	# Progresión en dificultad: Esclerocio → Autofagia → Necrosis → Omega-Cero.
	"acceso_esclerocio": {
		"name": "Acceso: Esclerocio Oscuro",
		"flavor": "La bioquímica oscura ya no es accidental. El hongo aprende a encapsularse con intención.",
		"cat": "ng_plus", "cost": 30, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "min": 1},
		"unlock": {"type": "transcendence_count", "min": 1},
		"effect": {"type": "route_access", "route": "esclerocio"},
		# Habilita el botón ESCLEROCIO OSCURO durante Met. Oscuro (T≥1).
	},
	"acceso_autofagia": {
		"name": "Acceso: Autofagia Necrótica",
		"flavor": "El organismo que presenció su propia devoración puede elegir repetirla con control.",
		"cat": "ng_plus", "cost": 50, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "DEPREDADOR DE REALIDADES"},
		"unlock": {"type": "route_closed", "route": "DEPREDADOR DE REALIDADES"},
		"effect": {"type": "route_access", "route": "autolisis"},
		# Habilita el botón AUTOFAGIA NECRÓTICA durante Met. Oscuro (requiere DEPREDADOR completado).
	},
	"acceso_necrosis": {
		"name": "Acceso: Necrosis Controlada",
		"flavor": "El colapso metabólico fue explorado. Ahora se puede dirigir el proceso con instrumentos.",
		"cat": "ng_plus", "cost": 50, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_any", "routes": ["METABOLISMO OSCURO", "ESCLEROCIO OSCURO", "AUTOFAGIA NECRÓTICA"]},
		"unlock": {"type": "route_closed_any", "routes": ["METABOLISMO OSCURO", "ESCLEROCIO OSCURO", "AUTOFAGIA NECRÓTICA"]},
		"effect": {"type": "route_access", "route": "necrosis"},
		# Habilita el botón NECROSIS CONTROLADA durante Met. Oscuro (requiere cualquier final MO completado).
	},
	"protocolo_omega_cero": {
		"name": "Protocolo Omega-Cero",
		"flavor": "Tres muertes aprendidas. Una síntesis. El hongo ya no sobrevive a través de una: las ejecuta todas a la vez.",
		"cat": "ng_plus", "cost": 100, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_all", "routes": ["AUTOFAGIA NECRÓTICA", "NECROSIS CONTROLADA", "ESCLEROCIO OSCURO"]},
		"unlock": {"type": "route_closed_all", "routes": ["AUTOFAGIA NECRÓTICA", "NECROSIS CONTROLADA", "ESCLEROCIO OSCURO"]},
		"effect": {"type": "protocolo_omega_cero_active", "value": 1.0},
		# PERMISO: comprarlo habilita la ruta PROTOCOLO OMEGA-CERO dentro de Met. Oscuro.
		# Gate en EvoManager.omega_cero_gate_ready() chequea get_buff_value("protocolo_omega_cero").
		# Requiere T≥2 (check en EvoManager) + haber cerrado las 3 sub-rutas previas.
	},
	"memoria_sinaptica": {
		"name": "Memoria Sináptica",
		"flavor": "Lo que se sintetizó en el borde de Ω=0 dejó una huella que la economía recuerda para siempre.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "PROTOCOLO OMEGA-CERO"},
		"unlock": {"type": "route_closed", "route": "PROTOCOLO OMEGA-CERO"},
		"effect": {"type": "memoria_sinaptica_active", "value": 1.0},
		# Otorgado gratis al sellar PROTOCOLO OMEGA-CERO por 1ª vez.
		# Efecto: término pasivo aditivo exp(k·(1−Ω))−1 acotado (EconomyManager.get_passive_total).
		# La intensidad (k) escala con omega_cero_kernel_max (el mejor Núcleo Φ logrado).
	},
	"sintesis_vital": {
		"name": "Síntesis Vital",
		"flavor": "El que tocó el piso absoluto y el que se recuperó al máximo descubrieron que el colapso y el crecimiento son el mismo borde.",
		"cat": "ng_plus", "cost": 8, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "legacy_flag", "flag": "omega_remision_done", "description_key": "UNLOCK_REQ_OMEGA_REMISION"},
		"unlock": {"type": "legacy_flag", "flag": "omega_remision_done", "description_key": "UNLOCK_REQ_OMEGA_REMISION"},
		"effect": {"type": "sintesis_vital_active", "value": 1.0},
		# Cross PROTOCOLO OMEGA-CERO ↔ REMISIÓN METABÓLICA (cualquier orden).
		# Efecto: click y pasivo ×2.0 cuando Ω<0.20 Y biomasa≥80 (fragilidad + abundancia simultáneas).
	},
	"remision_metabolica": {
		"name": "Remisión Metabólica",
		"flavor": "Probadas todas las formas de morir, queda una sola por aprender: sanar. El organismo recuerda cómo florecer en el borde del colapso.",
		"cat": "ng_plus", "cost": 15, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed_all", "routes": ["AUTOFAGIA NECRÓTICA", "NECROSIS CONTROLADA", "ESCLEROCIO OSCURO", "PROTOCOLO OMEGA-CERO"]},
		"unlock": {"type": "route_closed_all", "routes": ["AUTOFAGIA NECRÓTICA", "NECROSIS CONTROLADA", "ESCLEROCIO OSCURO", "PROTOCOLO OMEGA-CERO"]},
		"effect": {"type": "remision_metabolica_active", "value": 1.0},
		# PERMISO: comprarlo habilita la ruta REMISIÓN METABÓLICA dentro de Met. Oscuro.
		# Gate en EvoManager.remision_gate_ready() chequea get_buff_value("remision_metabolica").
		# Es el item final del árbol oscuro (requiere las 4 sub-rutas, incl. OMEGA-CERO).
	},
	"control_omega": {
		"name": "Control de Ω",
		"flavor": "El que aprendió a estabilizar el colapso ya no sufre la deriva: ahora la dirige.",
		"cat": "ng_plus", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "REMISIÓN METABÓLICA"},
		"unlock": {"type": "route_closed", "route": "REMISIÓN METABÓLICA"},
		"effect": {"type": "control_omega_active", "value": 1.0},
		# Otorgado gratis al cerrar REMISIÓN METABÓLICA por 1ª vez.
		# Efecto: en runs normales habilita empujar Ω con cooldown (UIManager / main).
		# Offset positivo acumulado también amplifica producción pasiva hasta +30% (EconomyManager).
	},

	# ────────────────────────────────────────────────
	# TRANSMUTACIONES (1) — revertir una mutación dominada para abrir una ruta más OP
	# ────────────────────────────────────────────────
	"transmut_fusion": {
		"name": "Transmutación: Fusión Catabólica",
		"flavor": "El hongo desaprende el frenesí absorbente. En su lugar, funde click y metabolismo en un solo motor estable.",
		"cat": "transmutaciones", "cost": 15, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "transcendence_count", "count": 3},
		"effect": {"type": "transmut_fusion_active", "value": 1.0},
		# TODAS las transmutaciones se revelan a partir de T≥3 (hito de meta-progresión).
		# LLAVE permanente, sin toggle: con Hiperasimilación activa aparece el botón de reversión [T]
		# (TransmutationLogic). Spec: docs/design/involucion_transmutaciones.md.
	},
	# Recompensa de SELLAR Fusión Catabólica (otorgada vía grant_buff, cost 0, no comprable).
	"legado_motor_fundido": {
		"name": "Legado: Motor Fundido",
		"flavor": "El motor singular dejó su huella en el genoma. Click y metabolismo ya nunca corren por separado: todo ingreso fluye un 25% más fuerte, para siempre.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "FUSIÓN CATABÓLICA"},
		"unlock": {"type": "route_closed", "route": "FUSIÓN CATABÓLICA"},
		"effect": {"type": "all_income_mult", "value": 0.25},
	},
	# TRANSMUTACIÓN de Homeostasis (A → A+). Llave sin toggle: con Homeostasis activa aparece [T].
	"transmut_caos": {
		"name": "Transmutación: Caos Orquestado",
		"flavor": "El equilibrio perfecto era una jaula. El hongo aprende a dirigir el caos en vez de temerle.",
		"cat": "transmutaciones", "cost": 15, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "HOMEOSTASIS"},
		"effect": {"type": "transmut_caos_active", "value": 1.0},
	},
	# Recompensa de SELLAR Caos Orquestado: una herramienta, no un multiplicador.
	"legado_batuta": {
		"name": "Legado: Batuta",
		"flavor": "Quien dirigió el caos conserva la batuta: una vez por run, silencia la orquesta (ε → 0).",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "CAOS ORQUESTADO"},
		"unlock": {"type": "route_closed", "route": "CAOS ORQUESTADO"},
		"effect": {"type": "batuta_active", "value": 1.0},
	},
	# TRANSMUTACIÓN de Simbiosis (A → A+). Llave sin toggle: con Simbiosis activa aparece [T].
	"transmut_coro": {
		"name": "Transmutación: Coro Simbiótico",
		"flavor": "El pacto se disuelve en ritmo. Ya no cooperan dos: late uno solo.",
		"cat": "transmutaciones", "cost": 15, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "SIMBIOSIS"},
		"effect": {"type": "transmut_coro_active", "value": 1.0},
	},
	# Recompensa de SELLAR Coro Simbiótico: el metrónomo sigue sonando en todas las runs.
	"legado_compas_interno": {
		"name": "Legado: Compás Interno",
		"flavor": "El coro terminó, pero el pulso quedó: en todas las runs, clickear a tiempo rinde más.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "CORO SIMBIÓTICO"},
		"unlock": {"type": "route_closed", "route": "CORO SIMBIÓTICO"},
		"effect": {"type": "compas_interno_active", "value": 1.0},
	},
	# TRANSMUTACIÓN de Red Micelial (A → A+). Llave sin toggle: con Red Micelial activa aparece [T].
	"transmut_micelio": {
		"name": "Transmutación: Micelio Omnisciente",
		"flavor": "La red deja de crecer hacia afuera y empieza a verlo todo desde adentro.",
		"cat": "transmutaciones", "cost": 15, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed_any", "routes": ["ESPORULACIÓN", "ESPORULACION", "PANSPERMIA NEGRA"]},
		"effect": {"type": "transmut_micelio_active", "value": 1.0},
	},
	# Recompensa de SELLAR Micelio Omnisciente: el primer nodo que llenaste queda conectado.
	"legado_nodo_latente": {
		"name": "Legado: Nodo Latente",
		"flavor": "La red recuerda el primer lugar que vio entero: ese upgrade rinde más en todas las runs.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "MICELIO OMNISCIENTE"},
		"unlock": {"type": "route_closed", "route": "MICELIO OMNISCIENTE"},
		"effect": {"type": "nodo_latente_active", "value": 1.0},
	},
	# BIOLOGÍA (B4): recompensa de sellar cada ruta nueva. Se otorgan al cerrar (RunManager.close_run).
	"legado_micorriza": {
		"name": "Legado: Micorriza",
		"flavor": "El pacto con la raíz quedó en el sustrato: pasivo ×1.10 en todas las runs.",
		"cat": "biologia", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "MUTUALISMO"},
		"unlock": {"type": "route_closed", "route": "MUTUALISMO"},
		"effect": {"type": "micorriza_passive", "value": 1.10},
	},
	"legado_microbioma": {
		"name": "Legado: Microbioma",
		"flavor": "Los socios del holobionte siguen adentro: los shocks de Homeostasis y la corrosión parasitaria pegan un 25 % menos.",
		"cat": "biologia", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HOLOBIONTE"},
		"unlock": {"type": "route_closed", "route": "HOLOBIONTE"},
		"effect": {"type": "microbioma_dampen", "value": 0.75},
	},
	"legado_mitocondria": {
		"name": "Legado: Mitocondria",
		"flavor": "El parásito tragado respira para vos: click y pasivo ×1.15 mientras ε < 0.30, en todas las runs.",
		"cat": "biologia", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "ENDOSIMBIOSIS"},
		"unlock": {"type": "route_closed", "route": "ENDOSIMBIOSIS"},
		"effect": {"type": "mitocondria_mult", "value": 1.15},
	},
	# Fracaso de Micelio Omnisciente: la red rota aprende a resistir (sólo rinde en Micelio).
	"legado_cicatriz_micelial": {
		"name": "Legado: Cicatriz Micelial",
		"flavor": "La red se rompió una vez. Ahora cicatriza antes de romperse.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "MICELIO FRAGMENTADO"},
		"unlock": {"type": "route_closed", "route": "MICELIO FRAGMENTADO"},
		"effect": {"type": "micelio_rupture_scar", "value": 0.75},
	},
	# TRANSMUTACIÓN de Parasitismo (A → A+). Llave sin toggle: con Parasitismo activo aparece [T].
	"transmut_huesped": {
		"name": "Transmutación: Huésped Soberano",
		"flavor": "El huésped deja de ser víctima: domestica a su parásito.",
		"cat": "transmutaciones", "cost": 15, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "PARASITISMO"},
		"effect": {"type": "transmut_huesped_active", "value": 1.0},
	},
	# Recompensa de SELLAR Huésped Soberano: el pacto con el parásito sigue en todas las runs.
	"legado_pacto_soberano": {
		"name": "Legado: Pacto Soberano",
		"flavor": "El parásito recuerda quién lo alimentó: en todas las runs, su corrosión avanza a la mitad.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "HUÉSPED SOBERANO"},
		"unlock": {"type": "route_closed", "route": "HUÉSPED SOBERANO"},
		"effect": {"type": "pacto_soberano_active", "value": 1.0},
	},
	# SOMBRA de Hiperasimilación: abandona el consumo por completo. LLAVE permanente, sin toggle:
	# se entra por DISPARADOR ESPEJO — dejar de clickear con pasivo propio y ε bajo
	# (GenomeEvaluator.update_ayuno_espejo). No compite con Fusión: una se toma teniendo Hiper.
	"transmut_ayuno": {
		"name": "Transmutación: Ayuno Primordial",
		"flavor": "El hongo desaprende el frenesí absorbente. Sin sustrato, sin nutrientes — descubre que el silencio también produce.",
		"cat": "transmutaciones", "cost": 20, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "transcendence_count", "count": 3},
		"effect": {"type": "transmut_ayuno_active", "value": 1.0},
	},
	# SOMBRA de Homeostasis (A → anti-A). Llave sin toggle: entra por espejo (sostener ε alto).
	"sombra_inestabilidad": {
		"name": "Sombra: Inestabilidad Consciente",
		"flavor": "El hongo deja de reducir ε y empieza a medirlo. Mirar la ecuación la cambia.",
		"cat": "transmutaciones", "cost": 20, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "HOMEOSTASIS"},
		"effect": {"type": "sombra_inestabilidad_active", "value": 1.0},
	},
	# Recompensa de SELLAR Inestabilidad Consciente (con los 3 legados de conocimiento).
	"legado_lema_lyapunov": {
		"name": "Legado: Lema de Lyapunov",
		"flavor": "La ecuación quedó demostrada: la fórmula del núcleo muestra los valores reales de a, b, d y e en todas las runs.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
		"unlock": {"type": "route_closed", "route": "INESTABILIDAD CONSCIENTE"},
		"effect": {"type": "lema_lyapunov_active", "value": 1.0},
	},
	# SOMBRA de Parasitismo (A → anti-A). Llave sin toggle: entra por espejo (activo, con plata, sin comprar).
	"sombra_autosuficiencia": {
		"name": "Sombra: Autosuficiencia",
		"flavor": "Parasitismo es depender del sistema y drenarlo. Autosuficiencia es no depender de nada: el hongo cultiva lo que necesita.",
		"cat": "transmutaciones", "cost": 20, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "PARASITISMO"},
		"effect": {"type": "sombra_autosuficiencia_active", "value": 1.0},
	},
	# Recompensa de SELLAR Autosuficiencia: un sistema (cultivar sin mercado, en cualquier run).
	"legado_despensa_propia": {
		"name": "Legado: Despensa Propia",
		"flavor": "La huerta quedó plantada: en todas las runs, cada 3 minutos podés cultivar un nivel de la mejora más barata con 3 de biomasa.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "AUTOSUFICIENCIA"},
		"unlock": {"type": "route_closed", "route": "AUTOSUFICIENCIA"},
		"effect": {"type": "despensa_propia_active", "value": 1.0},
	},
	# SOMBRA de Simbiosis (A → anti-A). Llave sin toggle: entra por espejo (colonia grande y agresiva).
	"sombra_antibiosis": {
		"name": "Sombra: Antibiosis",
		"flavor": "Lo contrario de la simbiosis: organismos que se dañan. Los hongos la inventaron — la penicilina sale de uno.",
		"cat": "transmutaciones", "cost": 20, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "SIMBIOSIS"},
		"effect": {"type": "sombra_antibiosis_active", "value": 1.0},
	},
	# Recompensa de SELLAR Antibiosis: visibilidad (el parásito, a la vista).
	"legado_penicilina": {
		"name": "Legado: Penicilina",
		"flavor": "Quien venció a sus rivales reconoce al parásito antes de que llegue: el panel de ε muestra cuánto falta para que entre Parasitismo, en todas las runs.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "ANTIBIOSIS"},
		"unlock": {"type": "route_closed", "route": "ANTIBIOSIS"},
		"effect": {"type": "penicilina_active", "value": 1.0},
	},
	# SOMBRA de Endosimbiosis (A → anti-A). Llave sin toggle: entra por espejo (dejar pasar ENGULLIR).
	"sombra_procariota": {
		"name": "Sombra: Procariota",
		"flavor": "El hongo expulsa sus orgánulos y vuelve a ser lo que fue antes de ser hongo: una colonia que se divide.",
		"cat": "transmutaciones", "cost": 20, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "transcendence_count", "count": 3},
		"unlock": {"type": "route_closed", "route": "ENDOSIMBIOSIS"},
		"effect": {"type": "sombra_procariota_active", "value": 1.0},
	},
	# Recompensa de SELLAR Procariota: visibilidad (expresión génica de los legados).
	"legado_plasmido": {
		"name": "Legado: Plásmido",
		"flavor": "La colonia aprendió a leer sus genes: el panel de Buffs activos muestra cuánto multiplica cada legado tu click y tu pasivo, en todas las runs.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "PROCARIOTA"},
		"unlock": {"type": "route_closed", "route": "PROCARIOTA"},
		"effect": {"type": "plasmido_active", "value": 1.0},
	},
	# Recompensa de SELLAR Ayuno Primordial (otorgada vía grant_buff, cost 0, no comprable).
	"legado_primicia_del_vacio": {
		"name": "Legado: Primicia del Vacío",
		"flavor": "El sistema ya estaba produciendo en el silencio antes de nacer. Al inicio de cada run, el metabolismo pasivo florece ×2 durante 90 segundos.",
		"cat": "transmutaciones", "cost": 0, "cost_growth": 1.0, "max_level": 1,
		"reveal": {"type": "route_closed", "route": "AYUNO PRIMORDIAL"},
		"unlock": {"type": "route_closed", "route": "AYUNO PRIMORDIAL"},
		"effect": {"type": "primicia_del_vacio_active", "value": 1.0},
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
const CAT_ORDER: Array = ["economia", "estructura", "biologia", "conocimiento", "ruta", "ng_plus", "transmutaciones", "secreto"]
const CAT_NAMES: Dictionary = {
	"economia":     "ECONOMÍA",
	"estructura":   "ESTRUCTURA",
	"biologia":     "BIOLOGÍA",
	"conocimiento": "CONOCIMIENTO",
	"ruta":         "RUTAS",
	"ng_plus":      "NG+",
	"transmutaciones": "TRANSMUTACIONES",
	"secreto":      "???",
}
