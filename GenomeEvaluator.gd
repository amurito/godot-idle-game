# GenomeEvaluator.gd
# class_name para evaluación del genoma — todas las sub-evaluaciones de update_genome.
# Funciones estáticas: acceden a EvoManager (autoload) directamente sin instancia.
class_name GenomeEvaluator

# ─────────────────────────────────────────────────────────────
# update_genome — Helpers de evaluación
# ─────────────────────────────────────────────────────────────

## Maneja el caso especial de Red Micelial / Parasitismo activos (Tier 1 congelado).
## Returns: true si manejó el caso (caller debe retornar), false en caso contrario.
static func handle_terminal_mutations() -> bool:
	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_parasitism):
		return false

	if EvoManager.genome.hiperasimilacion != "activo": EvoManager._set_genome_state("hiperasimilacion", "bloqueado")
	if EvoManager.genome.homeostasis != "activo": EvoManager._set_genome_state("homeostasis", "bloqueado")
	if EvoManager.genome.parasitismo != "activo" and not EvoManager.mutation_parasitism: EvoManager._set_genome_state("parasitismo", "bloqueado")
	if EvoManager.genome.simbiosis != "activo" and not EvoManager.mutation_symbiosis: EvoManager._set_genome_state("simbiosis", "bloqueado")

	# Forzamos estado activo en el genoma para que no se vea como "latente" en el HUD
	if EvoManager.mutation_red_micelial: EvoManager._set_genome_state("red_micelial", "activo")
	if EvoManager.mutation_parasitism: EvoManager._set_genome_state("parasitismo", "activo")

	# No bloqueamos esporulación: es el final de la rama roja
	check_automatic_activations()
	return true


## Calcula el contexto de evaluación: valores derivados que comparten todas las sub-funciones.
static func build_eval_context() -> Dictionary:
	var ap = EconomyManager.get_active_passive_breakdown()
	return {
		"epsilon": StructuralModel.epsilon_runtime,
		"accounting": UpgradeManager.level("accounting"),
		"run_time": RunManager.run_time,
		"bio_pressure": StructuralModel.get_structural_pressure(),
		"biomasa": BiosphereEngine.biomasa,
		"hifas": BiosphereEngine.hifas,
		"ap": ap,
		"act_domina": ap.activo > ap.pasivo,
	}


# ─────────────────────────────────────────────────────────────
# update_genome — Sub-evaluaciones por mutación
# ─────────────────────────────────────────────────────────────

## HIPERASIMILACIÓN (Exceso): activo > 80, ε > 0.4, biomasa > 4, sin contabilidad, run > 180s
static func update_hiperasimilacion(ctx: Dictionary) -> void:
	if EvoManager.mutation_homeostasis or EvoManager.mutation_symbiosis or EvoManager.mutation_parasitism or EvoManager.mutation_red_micelial:
		EvoManager._set_genome_state("hiperasimilacion", "bloqueado")
	elif ctx.ap.activo > 80.0 and ctx.epsilon > 0.4 and ctx.biomasa > 4.0 \
			and ctx.accounting == 0 and ctx.run_time > 180.0:
		EvoManager._set_genome_state("hiperasimilacion", "activo")
	elif ctx.ap.activo > 60.0 or ctx.epsilon > 0.4:
		EvoManager._set_genome_state("hiperasimilacion", "latente")
	else:
		EvoManager._set_genome_state("hiperasimilacion", "dormido")


## PARASITISMO (Degeneración): inactividad prolongada o estancamiento.
## NO requiere ε alto porque dejar de clickear ya colapsa ε por diseño.
static func update_parasitismo(ctx: Dictionary) -> void:
	var inactivity_trigger: bool = EconomyManager.time_since_last_click > 120.0 and ctx.biomasa > 3.0
	var stagnation_trigger: bool = ctx.run_time > 1800.0 and ctx.biomasa > 5.0 \
		and LegacyManager.last_run_ending != "HOMEOSTASIS"

	# Countdown inactividad: últimos 10s antes de que se active Parasitismo por idle
	if not EvoManager.mutation_parasitism and ctx.biomasa > 3.0:
		var idle := EconomyManager.time_since_last_click
		var secs_left := int(120.0 - idle)
		if secs_left >= 1 and secs_left <= 10 and secs_left != EvoManager._parasitismo_countdown_last:
			EvoManager._parasitismo_countdown_last = secs_left
			UIManager.show_countdown(secs_left, "PARASITISMO")
		elif idle < 110.0:
			EvoManager._parasitismo_countdown_last = -1

	if EvoManager.mutation_parasitism:
		EvoManager._set_genome_state("parasitismo", "activo")
	elif EvoManager.mutation_homeostasis or EvoManager.mutation_symbiosis or EvoManager.mutation_hyperassimilation or EvoManager.mutation_red_micelial:
		EvoManager._set_genome_state("parasitismo", "bloqueado")
	elif (ctx.biomasa > 6.0 and ctx.epsilon > 0.35 and ctx.accounting == 0 and ctx.run_time > 420.0) \
			or inactivity_trigger or stagnation_trigger:
		EvoManager._set_genome_state("parasitismo", "activo")
	elif ctx.biomasa > 2.0 or EconomyManager.time_since_last_click > 60.0:
		EvoManager._set_genome_state("parasitismo", "latente")
	else:
		EvoManager._set_genome_state("parasitismo", "dormido")


## METABOLISMO OSCURO (Post-Depredador): bioquímica oscura tras recursos críticos.
## Requiere: Depredador activo, dinero < $1000, ≥3 devours, biomasa ≥ 25.
static func update_met_oscuro(ctx: Dictionary) -> void:
	if EvoManager.mutation_met_oscuro:
		EvoManager._set_genome_state("met_oscuro", "activo")
		return
	if not EvoManager.mutation_depredador:
		EvoManager._set_genome_state("met_oscuro", "dormido")
		return

	var devoured_ok: bool = EvoManager.met_oscuro_devoured_count >= Balance.MET_OSCURO_DEVOURED_REQ
	var recursos_criticos: bool = EconomyManager.money < 1000.0
	var bio_ok: bool = ctx.biomasa >= Balance.MET_OSCURO_BIO_REQ

	if devoured_ok and recursos_criticos and bio_ok:
		var prev_mt := EvoManager.met_oscuro_timer
		EvoManager.met_oscuro_timer += RunManager.LOGIC_TICK
		if prev_mt == 0.0 and EvoManager.met_oscuro_timer > 0.0:
			LogManager.add(tr("LOG_BIOQUIMICA") % [EconomyManager.money, int(Balance.MET_OSCURO_REQUIRED_TIME), EvoManager.met_oscuro_devoured_count, ctx.biomasa])
		# ÁRBOL ACELERADO (Banco Cósmico T2): timers -40%
		var threshold := Balance.MET_OSCURO_REQUIRED_TIME * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
		# MEMORIA OSCURA (Esclerocio): la run recuerda cómo entrar en oscuridad → -10% al threshold.
		if RunManager.is_memoria_oscura_active():
			threshold *= Balance.MEMORIA_OSCURA_MO_THRESH_MULT
		EvoManager._set_genome_state("met_oscuro", "activo" if EvoManager.met_oscuro_timer >= threshold else "latente")
		var secs_left := int(threshold - EvoManager.met_oscuro_timer)
		if secs_left >= 1 and secs_left <= 10 and secs_left != EvoManager._met_oscuro_countdown_last:
			EvoManager._met_oscuro_countdown_last = secs_left
			UIManager.show_countdown(secs_left, "MET.OSCURO")
	else:
		EvoManager.met_oscuro_timer = max(0.0, EvoManager.met_oscuro_timer - RunManager.LOGIC_TICK * 1.5)
		EvoManager._set_genome_state("met_oscuro", "dormido" if EvoManager.met_oscuro_timer == 0.0 else "latente")
		EvoManager._met_oscuro_countdown_last = -1


## DEPREDADOR DE REALIDADES (Glitch Survival): post-Parasitismo o post-2ª Trascendencia.
## Carga durante 30s (o 18s con Árbol Acelerado) cuando ε > 0.95 con Hiperasimilación activa.
static func update_depredador(ctx: Dictionary) -> void:
	if EvoManager.mutation_depredador:
		EvoManager._set_genome_state("depredador", "activo")
		return

	var unlock_gate: bool = LegacyManager.last_run_ending == "PARASITISMO" \
		or LegacyManager.trascendencia_count > 1
	var hyper_active: bool = EvoManager.mutation_hyperassimilation or EvoManager.genome.hiperasimilacion == "activo"

	if not (unlock_gate and hyper_active):
		EvoManager._set_genome_state("depredador", "dormido")
		return

	if ctx.epsilon > 0.95:
		var prev_timer := EvoManager.depredador_timer
		EvoManager.depredador_timer += RunManager.LOGIC_TICK
		# Notificar al iniciar la carga
		if prev_timer == 0.0 and EvoManager.depredador_timer > 0.0:
			LogManager.add(tr("LOG_DEPREDADOR_DETECTED") % ctx.epsilon)
		# ÁRBOL ACELERADO (Banco Cósmico T2): timer Depredador -40%
		var threshold := 30.0 * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
		EvoManager._set_genome_state("depredador", "activo" if EvoManager.depredador_timer >= threshold else "latente")
		var secs_left := int(threshold - EvoManager.depredador_timer)
		if secs_left >= 1 and secs_left <= 10 and secs_left != EvoManager._depredador_countdown_last:
			EvoManager._depredador_countdown_last = secs_left
			UIManager.show_countdown(secs_left, "DEPREDADOR")
	else:
		EvoManager.depredador_timer = max(0.0, EvoManager.depredador_timer - RunManager.LOGIC_TICK * 2.0)
		EvoManager._set_genome_state("depredador", "dormido" if EvoManager.depredador_timer == 0.0 else "latente")
		EvoManager._depredador_countdown_last = -1

	# Timeout de seguridad: si Depredador nunca arrancó a cargar tras HYPER_TIMEOUT s,
	# la run cierra normalmente con HIPERASIMILACION (evita run atrapada).
	if EvoManager.depredador_timer == 0.0:
		EvoManager._hyper_active_timer += RunManager.LOGIC_TICK
		var timeout := Balance.HYPER_TIMEOUT
		var secs_left := int(timeout - EvoManager._hyper_active_timer)
		if secs_left in [30, 20, 10, 5, 4, 3, 2, 1]:
			UIManager.show_countdown(secs_left, "HIPERASIMILACIÓN (colapso)")
		if EvoManager._hyper_active_timer >= timeout:
			LogManager.add(tr("LOG_HIPER_TIMEOUT") % int(timeout))
			EvoManager.run_ended_by_mutation.emit("HIPERASIMILACION", "El sistema colapsó por saturación — ε insuficiente para Depredador")


## SIMBIOSIS (v0.8.5 — Camino del Hardware): Ω ≥ 0.40 con clic dominante.
static func update_simbiosis(ctx: Dictionary) -> void:
	if EvoManager.mutation_symbiosis:
		EvoManager._set_genome_state("simbiosis", "activo")
	elif EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation or EvoManager.mutation_red_micelial or EvoManager.mutation_parasitism:
		EvoManager._set_genome_state("simbiosis", "bloqueado")
	elif ctx.accounting >= 1 and ctx.hifas >= 5.0 and StructuralModel.omega >= 0.40 and ctx.act_domina:
		EvoManager._set_genome_state("simbiosis", "latente")
	elif ctx.accounting >= 1 and ctx.hifas >= 3.0:
		EvoManager._set_genome_state("simbiosis", "latente")
	else:
		EvoManager._set_genome_state("simbiosis", "dormido")


## HOMEOSTASIS (Ruta del Equilibrio): ε en banda + Ω balanceado + flujos duales.
static func update_homeostasis(ctx: Dictionary) -> void:
	var t := LegacyManager.trascendencia_count
	var low_fungal_noise: bool = ctx.hifas < 8.0

	# Condiciones de latente según tier de run
	var epsilon_ok: bool
	var flujos_ok: bool
	var omega_ok: bool
	var orden_ok: bool

	if t >= 1:
		epsilon_ok = ctx.epsilon > 0.05 and ctx.epsilon < 0.25
		var total_flow: float = float(ctx.ap["activo"]) + float(ctx.ap["pasivo"])
		flujos_ok = total_flow > 0 and (float(ctx.ap["pasivo"]) / total_flow) >= 0.30
		omega_ok = StructuralModel.omega >= 0.55
		orden_ok = ctx.accounting >= 2
	else:
		epsilon_ok = ctx.epsilon > 0.02 and ctx.epsilon < 0.45
		flujos_ok = ctx.ap["pasivo"] > 0 and ctx.ap["activo"] > 0
		omega_ok = StructuralModel.omega >= 0.40
		orden_ok = ctx.accounting >= 1

	if EvoManager.mutation_red_micelial or EvoManager.mutation_hyperassimilation or EvoManager.mutation_parasitism \
			or EvoManager.mutation_symbiosis or EvoManager.mutation_allostasis or EvoManager.mutation_homeorhesis:
		EvoManager._set_genome_state("homeostasis", "bloqueado")
	elif EvoManager.mutation_homeostasis:
		EvoManager._set_genome_state("homeostasis", "activo")
	elif RunManager.is_homeostasis_candidate() and low_fungal_noise and epsilon_ok:
		EvoManager._set_genome_state("homeostasis", "latente")
	elif orden_ok and flujos_ok and omega_ok and ctx.run_time > 120.0:
		EvoManager._set_genome_state("homeostasis", "latente")
	else:
		EvoManager._set_genome_state("homeostasis", "dormido")


## ALOSTASIS (NG+): Homeostasis activa + ≥1 perturbación sobrevivida.
static func update_allostasis(_ctx: Dictionary) -> void:
	if EvoManager.mutation_allostasis:
		EvoManager._set_genome_state("allostasis", "activo")
	elif EvoManager.mutation_red_micelial or EvoManager.mutation_hyperassimilation or EvoManager.mutation_parasitism \
			or EvoManager.mutation_symbiosis or not EvoManager.mutation_homeostasis:
		EvoManager._set_genome_state("allostasis", "bloqueado")
	elif LegacyManager.last_run_ending == "HOMEOSTASIS":
		# Latente desde la primera perturbación sobrevivida (fiel al árbol)
		EvoManager._set_genome_state("allostasis", "latente" if RunManager.disturbances_survived >= 1 else "dormido")
	else:
		EvoManager._set_genome_state("allostasis", "dormido")


## HOMEORRESIS (NG+): Allostasis activa + ≥5 perturbaciones (o shock extremo sobrevivido).
static func update_homeorhesis(_ctx: Dictionary) -> void:
	if EvoManager.mutation_homeorhesis:
		EvoManager._set_genome_state("homeorhesis", "activo")
	elif EvoManager.mutation_red_micelial or EvoManager.mutation_hyperassimilation or EvoManager.mutation_parasitism \
			or EvoManager.mutation_symbiosis or not EvoManager.mutation_allostasis:
		EvoManager._set_genome_state("homeorhesis", "bloqueado")
	elif LegacyManager.last_run_ending == "ALLOSTASIS":
		# Latente cuando se cumplen "5 ciclos sin colapso"
		var conditions_met: bool = RunManager.disturbances_survived >= 5 or RunManager.extreme_shock_survived
		EvoManager._set_genome_state("homeorhesis", "latente" if conditions_met else "dormido")
	else:
		EvoManager._set_genome_state("homeorhesis", "dormido")


## RED MICELIAL (v0.8.10 — Ruta de la Expansión): hifas altas, ε bajo, pasivo dominante.
static func update_red_micelial(ctx: Dictionary) -> void:
	if EvoManager.mutation_red_micelial:
		EvoManager._set_genome_state("red_micelial", "activo")
	elif EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation or EvoManager.mutation_symbiosis:
		EvoManager._set_genome_state("red_micelial", "bloqueado")
	elif ctx.hifas >= 11.5 and ctx.biomasa >= 5.0 and ctx.epsilon < 0.65 \
			and ctx.accounting >= 1 and not ctx.act_domina:
		EvoManager._set_genome_state("red_micelial", "latente")
	elif ctx.hifas >= 5.0:
		EvoManager._set_genome_state("red_micelial", "latente")
	else:
		EvoManager._set_genome_state("red_micelial", "dormido")


## ESPORULACIÓN (Fase 2 de Red Micelial): determinada por presión biológica.
static func update_esporulacion(ctx: Dictionary) -> void:
	if EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation:
		EvoManager._set_genome_state("esporulacion", "bloqueado")
	elif ctx.bio_pressure > 20.0:
		EvoManager._set_genome_state("esporulacion", "activo")
	elif ctx.bio_pressure > 8.0:
		EvoManager._set_genome_state("esporulacion", "latente")
	else:
		EvoManager._set_genome_state("esporulacion", "dormido")


static func check_automatic_activations():
	# CARNAVAL: bloquear activaciones automáticas de segundo nivel — solo rotan las mutaciones del pool
	if RouteManager.is_active("carnaval"):
		return

	# MET.OSCURO tiene prioridad sobre Depredador (congela el devorar)
	if EvoManager.genome.met_oscuro == "activo" and not EvoManager.mutation_met_oscuro:
		EvoManager.activate_met_oscuro()
		return

	# DEPREDADOR tiene prioridad sobre el resto
	if EvoManager.genome.depredador == "activo" and not EvoManager.mutation_depredador:
		EvoManager.activate_depredador()
		return  # Evita que hiperasimilación cierre la run en el mismo tick

	if EvoManager.genome.hiperasimilacion == "activo" and not EvoManager.mutation_hyperassimilation:
		EvoManager.activate_hyperassimilation()

	if EvoManager.genome.parasitismo == "activo" and not EvoManager.mutation_parasitism:
		EvoManager.activate_parasitism()

	if EvoManager.genome.allostasis == "activo" and not EvoManager.mutation_allostasis:
		EvoManager.activate_allostasis()

	if EvoManager.genome.homeorhesis == "activo" and not EvoManager.mutation_homeorhesis:
		EvoManager.activate_homeorhesis()

	# Simbiosis, Homeostasis y Red Micelial ahora son MANUALES vía Choice Panel

	if EvoManager.genome.esporulacion == "activo" and not EvoManager.mutation_sporulation and EvoManager.red_micelial_phase == 2:
		EvoManager.activate_sporulation()

