extends Node

# EvoManager.gd — Autoload
# Maneja la evolución del genoma y las mutaciones irreversibles.
# Actúa de forma autónoma: observa a BiosphereEngine y main.gd,
# muta su propio estado y emite señales para que main actúe.

signal mutation_unlocked(mutation_id: String)
signal mutation_activated(mutation_id: String, display_name: String)
signal run_ended_by_mutation(route: String, reason: String)
signal primordio_iniciado()
signal primordio_abortado(abort_count: int, reason: String)
signal seta_formada_signal()

var genome := {
	"hiperasimilacion": "dormido",
	"parasitismo": "dormido",
	"red_micelial": "dormido",
	"esporulacion": "dormido",
	"simbiosis": "dormido",
	"homeostasis": "dormido",
	"trascendencia": "dormido",
	"allostasis": "dormido",
	"homeorhesis": "dormido",
	"depredador": "dormido",
	"met_oscuro": "dormido"
}

var mutation_hyperassimilation := false
var mutation_symbiosis := false
var mutation_homeostasis := false
var mutation_red_micelial := false
var mutation_sporulation := false
var mutation_parasitism := false
var mutation_allostasis := false
var mutation_homeorhesis := false

var red_micelial_phase := 0
enum RedBranch { NONE, COLONIZATION, SYMBIOSIS }
var red_branch_selected: int = RedBranch.NONE

# === CICLO BIOLÓGICO: PRIMORDIO ===
var primordio_active: bool = false
var primordio_timer: float = 0.0
var primordio_abort_count: int = 0
var seta_formada: bool = false
var nucleo_conciencia := false # Hito final Rama Azul

# === NG+ SECRETOS ===
var allostasis_timer: float = 0.0
var homeorhesis_timer: float = 0.0
var mutation_depredador := false
var depredador_timer: float = 0.0
var _depredador_active_tick: float = 0.0
var _depredador_status_timer: float = 0.0
const DEPREDADOR_STATUS_INTERVAL := 10.0
# Timer de inestabilidad (post-activación): ventana antes de la implosión.
# Cuenta hacia arriba mientras el Depredador está activo. Si llega al máximo
# sin resolverse (sellar MET.OSCURO o consumir todos los upgrades) → COLAPSO.
var depredador_inestabilidad: float = 0.0
const DEPREDADOR_INESTABILIDAD_MAX := 60.0
var _depredador_countdown_last: int = -1
var _met_oscuro_countdown_last: int = -1
var _parasitismo_countdown_last: int = -1
var _hyper_active_timer: float = 0.0   # tiempo activo en hiperasimilación sin depredador

# === NG+ METABOLISMO OSCURO (Post-Depredador) ===
var mutation_met_oscuro := false
var met_oscuro_timer: float = 0.0  # Progreso de activación (0→15s)
var met_oscuro_devoured_count: int = 0  # Upgrades devorados durante la run
# Runtime process vars (fase activa)
var _met_oscuro_income_accum: float = 0.0
var _met_oscuro_status_timer: float = 0.0
var _met_oscuro_active_time: float = 0.0
const MET_OSCURO_STATUS_INTERVAL := 12.0

# === NG+ METABOLISMO GLITCH ===
var _glitch_was_active: bool = false

func reset() -> void:
	genome = {
		"hiperasimilacion": "dormido",
		"parasitismo": "dormido",
		"red_micelial": "dormido",
		"esporulacion": "dormido",
		"simbiosis": "dormido",
		"homeostasis": "dormido",
		"trascendencia": "dormido",
		"depredador": "dormido",
		"met_oscuro": "dormido",
		"allostasis": "dormido",
		"homeorhesis": "dormido"
}
	mutation_hyperassimilation = false
	mutation_symbiosis = false
	mutation_homeostasis = false
	mutation_red_micelial = false
	mutation_sporulation = false
	mutation_parasitism = false
	mutation_allostasis = false
	mutation_homeorhesis = false
	mutation_depredador = false
	mutation_met_oscuro = false
	met_oscuro_timer = 0.0
	met_oscuro_devoured_count = 0
	red_micelial_phase = 0
	red_branch_selected = RedBranch.NONE
	primordio_active = false
	primordio_timer = 0.0
	primordio_abort_count = 0
	seta_formada = false
	nucleo_conciencia = false
	allostasis_timer = 0.0
	homeorhesis_timer = 0.0
	depredador_timer = 0.0
	depredador_inestabilidad = 0.0
	_depredador_active_tick = 0.0
	_depredador_status_timer = 0.0
	_depredador_countdown_last = -1
	_met_oscuro_countdown_last = -1
	_parasitismo_countdown_last = -1
	_hyper_active_timer = 0.0
	_met_oscuro_income_accum = 0.0
	_met_oscuro_status_timer = 0.0
	_met_oscuro_active_time = 0.0
	_glitch_was_active = false

func update_genome():
	if RunManager.run_closed:
		return

	# Bloqueo temprano: rutas finales (Red Micelial / Parasitismo) congelan Tier 1
	if _handle_terminal_mutations():
		return

	# Construir contexto compartido: todos los valores derivados que usan las sub-evaluaciones
	var ctx := _build_eval_context()

	# Evaluar cada mutación. Orden importa: las flags activas de unas bloquean a otras.
	_update_hiperasimilacion(ctx)
	_update_parasitismo(ctx)
	_update_met_oscuro(ctx)
	_update_depredador(ctx)
	_update_simbiosis(ctx)
	_update_homeostasis(ctx)
	_update_allostasis(ctx)
	_update_homeorhesis(ctx)
	_update_red_micelial(ctx)
	_update_esporulacion(ctx)

	_check_automatic_activations()


# ─────────────────────────────────────────────────────────────
# update_genome — Helpers de evaluación
# ─────────────────────────────────────────────────────────────

## Maneja el caso especial de Red Micelial / Parasitismo activos (Tier 1 congelado).
## Returns: true si manejó el caso (caller debe retornar), false en caso contrario.
func _handle_terminal_mutations() -> bool:
	if not (mutation_red_micelial or mutation_parasitism):
		return false

	if genome.hiperasimilacion != "activo": _set_genome_state("hiperasimilacion", "bloqueado")
	if genome.homeostasis != "activo": _set_genome_state("homeostasis", "bloqueado")
	if genome.parasitismo != "activo" and not mutation_parasitism: _set_genome_state("parasitismo", "bloqueado")
	if genome.simbiosis != "activo" and not mutation_symbiosis: _set_genome_state("simbiosis", "bloqueado")

	# Forzamos estado activo en el genoma para que no se vea como "latente" en el HUD
	if mutation_red_micelial: _set_genome_state("red_micelial", "activo")
	if mutation_parasitism: _set_genome_state("parasitismo", "activo")

	# No bloqueamos esporulación: es el final de la rama roja
	_check_automatic_activations()
	return true


## Calcula el contexto de evaluación: valores derivados que comparten todas las sub-funciones.
func _build_eval_context() -> Dictionary:
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
func _update_hiperasimilacion(ctx: Dictionary) -> void:
	if mutation_homeostasis or mutation_symbiosis or mutation_parasitism or mutation_red_micelial:
		_set_genome_state("hiperasimilacion", "bloqueado")
	elif ctx.ap.activo > 80.0 and ctx.epsilon > 0.4 and ctx.biomasa > 4.0 \
			and ctx.accounting == 0 and ctx.run_time > 180.0:
		_set_genome_state("hiperasimilacion", "activo")
	elif ctx.ap.activo > 60.0 or ctx.epsilon > 0.4:
		_set_genome_state("hiperasimilacion", "latente")
	else:
		_set_genome_state("hiperasimilacion", "dormido")


## PARASITISMO (Degeneración): inactividad prolongada o estancamiento.
## NO requiere ε alto porque dejar de clickear ya colapsa ε por diseño.
func _update_parasitismo(ctx: Dictionary) -> void:
	var inactivity_trigger: bool = EconomyManager.time_since_last_click > 120.0 and ctx.biomasa > 3.0
	var stagnation_trigger: bool = ctx.run_time > 1800.0 and ctx.biomasa > 5.0 \
		and LegacyManager.last_run_ending != "HOMEOSTASIS"

	# Countdown inactividad: últimos 10s antes de que se active Parasitismo por idle
	if not mutation_parasitism and ctx.biomasa > 3.0:
		var idle := EconomyManager.time_since_last_click
		var secs_left := int(120.0 - idle)
		if secs_left >= 1 and secs_left <= 10 and secs_left != _parasitismo_countdown_last:
			_parasitismo_countdown_last = secs_left
			UIManager.show_countdown(secs_left, "PARASITISMO")
		elif idle < 110.0:
			_parasitismo_countdown_last = -1

	if mutation_parasitism:
		_set_genome_state("parasitismo", "activo")
	elif mutation_homeostasis or mutation_symbiosis or mutation_hyperassimilation or mutation_red_micelial:
		_set_genome_state("parasitismo", "bloqueado")
	elif (ctx.biomasa > 6.0 and ctx.epsilon > 0.35 and ctx.accounting == 0 and ctx.run_time > 420.0) \
			or inactivity_trigger or stagnation_trigger:
		_set_genome_state("parasitismo", "activo")
	elif ctx.biomasa > 2.0 or EconomyManager.time_since_last_click > 60.0:
		_set_genome_state("parasitismo", "latente")
	else:
		_set_genome_state("parasitismo", "dormido")


## METABOLISMO OSCURO (Post-Depredador): bioquímica oscura tras recursos críticos.
## Requiere: Depredador activo, dinero < $1000, ≥3 devours, biomasa ≥ 25.
func _update_met_oscuro(ctx: Dictionary) -> void:
	if mutation_met_oscuro:
		_set_genome_state("met_oscuro", "activo")
		return
	if not mutation_depredador:
		_set_genome_state("met_oscuro", "dormido")
		return

	var devoured_ok: bool = met_oscuro_devoured_count >= 3
	var recursos_criticos: bool = EconomyManager.money < 1000.0
	var bio_ok: bool = ctx.biomasa >= 25.0

	if devoured_ok and recursos_criticos and bio_ok:
		var prev_mt := met_oscuro_timer
		met_oscuro_timer += RunManager.LOGIC_TICK
		if prev_mt == 0.0 and met_oscuro_timer > 0.0:
			LogManager.add(tr("LOG_BIOQUIMICA") % [EconomyManager.money, int(Balance.MET_OSCURO_REQUIRED_TIME), met_oscuro_devoured_count, ctx.biomasa])
		# ÁRBOL ACELERADO (Banco Cósmico T2): timers -40%
		var threshold := Balance.MET_OSCURO_REQUIRED_TIME * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
		_set_genome_state("met_oscuro", "activo" if met_oscuro_timer >= threshold else "latente")
		var secs_left := int(threshold - met_oscuro_timer)
		if secs_left >= 1 and secs_left <= 10 and secs_left != _met_oscuro_countdown_last:
			_met_oscuro_countdown_last = secs_left
			UIManager.show_countdown(secs_left, "MET.OSCURO")
	else:
		met_oscuro_timer = max(0.0, met_oscuro_timer - RunManager.LOGIC_TICK * 1.5)
		_set_genome_state("met_oscuro", "dormido" if met_oscuro_timer == 0.0 else "latente")
		_met_oscuro_countdown_last = -1


## DEPREDADOR DE REALIDADES (Glitch Survival): post-Parasitismo o post-2ª Trascendencia.
## Carga durante 30s (o 18s con Árbol Acelerado) cuando ε > 0.95 con Hiperasimilación activa.
func _update_depredador(ctx: Dictionary) -> void:
	if mutation_depredador:
		_set_genome_state("depredador", "activo")
		return

	var unlock_gate: bool = LegacyManager.last_run_ending == "PARASITISMO" \
		or LegacyManager.trascendencia_count > 1
	var hyper_active: bool = mutation_hyperassimilation or genome.hiperasimilacion == "activo"

	if not (unlock_gate and hyper_active):
		_set_genome_state("depredador", "dormido")
		return

	if ctx.epsilon > 0.95:
		var prev_timer := depredador_timer
		depredador_timer += RunManager.LOGIC_TICK
		# Notificar al iniciar la carga
		if prev_timer == 0.0 and depredador_timer > 0.0:
			LogManager.add(tr("LOG_DEPREDADOR_DETECTED") % ctx.epsilon)
		# ÁRBOL ACELERADO (Banco Cósmico T2): timer Depredador -40%
		var threshold := 30.0 * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
		_set_genome_state("depredador", "activo" if depredador_timer >= threshold else "latente")
		var secs_left := int(threshold - depredador_timer)
		if secs_left >= 1 and secs_left <= 10 and secs_left != _depredador_countdown_last:
			_depredador_countdown_last = secs_left
			UIManager.show_countdown(secs_left, "DEPREDADOR")
	else:
		depredador_timer = max(0.0, depredador_timer - RunManager.LOGIC_TICK * 2.0)
		_set_genome_state("depredador", "dormido" if depredador_timer == 0.0 else "latente")
		_depredador_countdown_last = -1

	# Timeout de seguridad: si Depredador nunca arrancó a cargar tras HYPER_TIMEOUT s,
	# la run cierra normalmente con HIPERASIMILACION (evita run atrapada).
	if depredador_timer == 0.0:
		_hyper_active_timer += RunManager.LOGIC_TICK
		var timeout := Balance.HYPER_TIMEOUT
		var secs_left := int(timeout - _hyper_active_timer)
		if secs_left in [30, 20, 10, 5, 4, 3, 2, 1]:
			UIManager.show_countdown(secs_left, "HIPERASIMILACIÓN (colapso)")
		if _hyper_active_timer >= timeout:
			LogManager.add(tr("LOG_HIPER_TIMEOUT") % int(timeout))
			run_ended_by_mutation.emit("HIPERASIMILACION", "El sistema colapsó por saturación — ε insuficiente para Depredador")


## SIMBIOSIS (v0.8.5 — Camino del Hardware): Ω ≥ 0.40 con clic dominante.
func _update_simbiosis(ctx: Dictionary) -> void:
	if mutation_symbiosis:
		_set_genome_state("simbiosis", "activo")
	elif mutation_homeostasis or mutation_hyperassimilation or mutation_red_micelial or mutation_parasitism:
		_set_genome_state("simbiosis", "bloqueado")
	elif ctx.accounting >= 1 and ctx.hifas >= 5.0 and StructuralModel.omega >= 0.40 and ctx.act_domina:
		_set_genome_state("simbiosis", "latente")
	elif ctx.accounting >= 1 and ctx.hifas >= 3.0:
		_set_genome_state("simbiosis", "latente")
	else:
		_set_genome_state("simbiosis", "dormido")


## HOMEOSTASIS (Ruta del Equilibrio): ε en banda + Ω balanceado + flujos duales.
func _update_homeostasis(ctx: Dictionary) -> void:
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

	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism \
			or mutation_symbiosis or mutation_allostasis or mutation_homeorhesis:
		_set_genome_state("homeostasis", "bloqueado")
	elif mutation_homeostasis:
		_set_genome_state("homeostasis", "activo")
	elif RunManager.is_homeostasis_candidate() and low_fungal_noise and epsilon_ok:
		_set_genome_state("homeostasis", "latente")
	elif orden_ok and flujos_ok and omega_ok and ctx.run_time > 120.0:
		_set_genome_state("homeostasis", "latente")
	else:
		_set_genome_state("homeostasis", "dormido")


## ALOSTASIS (NG+): Homeostasis activa + ≥1 perturbación sobrevivida.
func _update_allostasis(_ctx: Dictionary) -> void:
	if mutation_allostasis:
		_set_genome_state("allostasis", "activo")
	elif mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism \
			or mutation_symbiosis or not mutation_homeostasis:
		_set_genome_state("allostasis", "bloqueado")
	elif LegacyManager.last_run_ending == "HOMEOSTASIS":
		# Latente desde la primera perturbación sobrevivida (fiel al árbol)
		_set_genome_state("allostasis", "latente" if RunManager.disturbances_survived >= 1 else "dormido")
	else:
		_set_genome_state("allostasis", "dormido")


## HOMEORRESIS (NG+): Allostasis activa + ≥5 perturbaciones (o shock extremo sobrevivido).
func _update_homeorhesis(_ctx: Dictionary) -> void:
	if mutation_homeorhesis:
		_set_genome_state("homeorhesis", "activo")
	elif mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism \
			or mutation_symbiosis or not mutation_allostasis:
		_set_genome_state("homeorhesis", "bloqueado")
	elif LegacyManager.last_run_ending == "ALLOSTASIS":
		# Latente cuando se cumplen "5 ciclos sin colapso"
		var conditions_met: bool = RunManager.disturbances_survived >= 5 or RunManager.extreme_shock_survived
		_set_genome_state("homeorhesis", "latente" if conditions_met else "dormido")
	else:
		_set_genome_state("homeorhesis", "dormido")


## RED MICELIAL (v0.8.10 — Ruta de la Expansión): hifas altas, ε bajo, pasivo dominante.
func _update_red_micelial(ctx: Dictionary) -> void:
	if mutation_red_micelial:
		_set_genome_state("red_micelial", "activo")
	elif mutation_homeostasis or mutation_hyperassimilation or mutation_symbiosis:
		_set_genome_state("red_micelial", "bloqueado")
	elif ctx.hifas >= 11.5 and ctx.biomasa >= 5.0 and ctx.epsilon < 0.65 \
			and ctx.accounting >= 1 and not ctx.act_domina:
		_set_genome_state("red_micelial", "latente")
	elif ctx.hifas >= 5.0:
		_set_genome_state("red_micelial", "latente")
	else:
		_set_genome_state("red_micelial", "dormido")


## ESPORULACIÓN (Fase 2 de Red Micelial): determinada por presión biológica.
func _update_esporulacion(ctx: Dictionary) -> void:
	if mutation_homeostasis or mutation_hyperassimilation:
		_set_genome_state("esporulacion", "bloqueado")
	elif ctx.bio_pressure > 20.0:
		_set_genome_state("esporulacion", "activo")
	elif ctx.bio_pressure > 8.0:
		_set_genome_state("esporulacion", "latente")
	else:
		_set_genome_state("esporulacion", "dormido")


func _check_automatic_activations():
	# CARNAVAL: bloquear activaciones automáticas de segundo nivel — solo rotan las mutaciones del pool
	if RunManager.carnaval_active:
		return

	# MET.OSCURO tiene prioridad sobre Depredador (congela el devorar)
	if genome.met_oscuro == "activo" and not mutation_met_oscuro:
		activate_met_oscuro()
		return

	# DEPREDADOR tiene prioridad sobre el resto
	if genome.depredador == "activo" and not mutation_depredador:
		activate_depredador()
		return  # Evita que hiperasimilación cierre la run en el mismo tick

	if genome.hiperasimilacion == "activo" and not mutation_hyperassimilation:
		activate_hyperassimilation()

	if genome.parasitismo == "activo" and not mutation_parasitism:
		activate_parasitism()

	if genome.allostasis == "activo" and not mutation_allostasis:
		activate_allostasis()

	if genome.homeorhesis == "activo" and not mutation_homeorhesis:
		activate_homeorhesis()

	# Simbiosis, Homeostasis y Red Micelial ahora son MANUALES vía Choice Panel

	if genome.esporulacion == "activo" and not mutation_sporulation and red_micelial_phase == 2:
		activate_sporulation()

func is_any_latent_tier1() -> bool:
	return genome.simbiosis == "latente" or genome.homeostasis == "latente" or genome.red_micelial == "latente"

func is_homeostasis_ready() -> bool:
	return RunManager.is_homeostasis_candidate()

func is_simbiosis_ready() -> bool:
	var hifas = BiosphereEngine.hifas
	var acc = UpgradeManager.level("accounting")
	var ap = EconomyManager.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo
	# Árbol: "Estabilidad del ecosistema > 40%" → Ω ≥ 0.40
	return acc >= 1 and hifas >= 5.0 and StructuralModel.omega >= 0.40 and act_domina

func is_red_micelial_ready() -> bool:
	var hifas = BiosphereEngine.hifas
	var biomasa = BiosphereEngine.biomasa
	var acc = UpgradeManager.level("accounting")
	var ap = EconomyManager.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo
	var eps = StructuralModel.epsilon_runtime
	return hifas >= 11.5 and biomasa >= 5.0 and eps < 0.65 and acc >= 1 and not act_domina

func is_allostasis_ready() -> bool:
	var ok_dist = RunManager.disturbances_survived >= 3
	var ok_resil = RunManager.resilience_score >= 150.0
	var ok_omega = StructuralModel.omega_min >= 0.40
	var ok_delta = EconomyManager.delta_per_sec >= 200.0
	var ok_acc = UpgradeManager.level("accounting") >= 2
	return ok_dist and ok_resil and ok_omega and ok_delta and ok_acc


func activate_mutation(id: String) -> void:
	match id:
		"hiperasimilacion": activate_hyperassimilation()
		"homeostasis": activate_homeostasis()
		"red_micelial": activate_red_micelial()
		"esporulacion": activate_sporulation()
		"parasitismo": activate_parasitism()
		"simbiosis": activate_symbiosis()
		"allostasis": activate_allostasis()
		"depredador": activate_depredador()
		"homeorhesis": activate_homeorhesis()
		"met_oscuro": activate_met_oscuro()

func _set_genome_state(mutation: String, new_state: String):
	# Si la clave no existe, la creamos en lugar de crashear
	if not genome.has(mutation):
		genome[mutation] = "dormido"
	
	if genome[mutation] != new_state:
		genome[mutation] = new_state
		if new_state == "latente":
			mutation_unlocked.emit(mutation)


func activate_allostasis():
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis: return
	LogManager.add(tr("LOG_ALOSTASIS_EVO"))
	mutation_allostasis = true
	mutation_activated.emit("allostasis", tr("MUT_ALLOSTASIS"))
	AchievementManager.on_mutation_activated("allostasis")
	
func activate_homeorhesis():
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis: return
	LogManager.add(tr("LOG_HOMEORRESIS_EVO"))
	mutation_homeorhesis = true
	mutation_activated.emit("homeorhesis", tr("MUT_HOMEORHESIS"))
	AchievementManager.on_mutation_activated("homeorhesis")

func activate_depredador():
	if mutation_homeostasis or mutation_red_micelial or mutation_symbiosis or mutation_parasitism: return
	LogManager.add(tr("LOG_GLITCH_ALERT"))
	mutation_depredador = true
	depredador_inestabilidad = 0.0  # arranca la cuenta hacia la implosión
	mutation_activated.emit("depredador", tr("MUT_DEPREDADOR"))
	AchievementManager.on_depredador_activated()

	if not LegacyManager.get_buff_value("metabolismo_glitch"):
		LegacyManager.grant_buff("metabolismo_glitch")
		UIManager.show_toast(tr("TOAST_MG_UNLOCKED"))

func activate_met_oscuro():
	if mutation_met_oscuro: return
	if not mutation_depredador: return  # Solo post-Depredador
	mutation_met_oscuro = true
	LogManager.add(tr("LOG_MO_ACTIVATED"))
	LogManager.add(tr("LOG_MO_EFFECTS"))
	LogManager.add(tr("LOG_MO_CLOSE"))
	mutation_activated.emit("met_oscuro", tr("MUT_MET_OSCURO"))
	AchievementManager.on_met_oscuro_activated()
	# Recalcular estrés/omega tras aplicar los nerfs permanentes
	StructuralModel.omega = 0.10
	StructuralModel.omega_min = min(StructuralModel.omega_min, 0.10)

func activate_hyperassimilation():
	if mutation_homeostasis or mutation_parasitism or mutation_symbiosis: return
	mutation_hyperassimilation = true
	LogManager.add(tr("LOG_HIPER_EFFECTS"))
	mutation_activated.emit("hiperasimilacion", tr("MUT_HIPERASIMILACION"))
	AchievementManager.on_mutation_activated("hiperasimilacion")
	# No cerrar si Depredador puede cargarse: venimos de PARASITISMO O trascendencia_count > 1
	var depredador_gate: bool = LegacyManager.last_run_ending == "PARASITISMO" \
		or LegacyManager.trascendencia_count > 1
	if not depredador_gate:
		run_ended_by_mutation.emit("HIPERASIMILACION", "El sistema prioriza absorción total sobre estabilidad")

func activate_homeostasis():
	if mutation_homeostasis or mutation_symbiosis: return
	mutation_homeostasis = true
	mutation_hyperassimilation = false # bloqueo cruzado
	mutation_activated.emit("homeostasis", tr("MUT_HOMEOSTASIS"))
	AchievementManager.on_mutation_activated("homeostasis")

func activate_red_micelial():
	if mutation_homeostasis or mutation_hyperassimilation or mutation_symbiosis: return
	mutation_red_micelial = true
	mutation_activated.emit("red_micelial", tr("MUT_RED_MICELIAL"))
	AchievementManager.on_red_micelial_activated()

func activate_sporulation():
	if mutation_sporulation: return
	if not mutation_red_micelial or red_micelial_phase != 2: return
	if mutation_homeostasis or mutation_hyperassimilation: return

	mutation_sporulation = true
	mutation_activated.emit("esporulacion", tr("MUT_ESPORULACION"))
	AchievementManager.on_mutation_activated("esporulacion")
	run_ended_by_mutation.emit("ESPORULACION", "El sistema abandona la coherencia local y se dispersa en esporas")

func activate_parasitism():
	if mutation_homeostasis or mutation_symbiosis or mutation_parasitism: return
	mutation_parasitism = true
	mutation_hyperassimilation = false
	BiosphereEngine.apply_parasitism_buffs()
	mutation_activated.emit("parasitismo", tr("MUT_PARASITISMO"))
	AchievementManager.on_mutation_activated("parasitismo")
	# El parasitismo no cierra la run inmediatamente, requiere un hito de drenaje o colapso.

func check_parasitism_final(_main: Control):
	if not mutation_parasitism or RunManager.run_closed: return
	
	# Condición de victoria por parasitismo: 1 PL (mínimo histórico)
	if BiosphereEngine.biomasa >= 15.0 and EconomyManager.money < 1000.0:
		LegacyManager.add_pl(1)
		RunManager.close_run("PARASITISMO", tr("CLOSE_EVO_PARASITISMO_BANCARROTA"))
	elif BiosphereEngine.biomasa >= 25.0:
		LegacyManager.add_pl(1)
		RunManager.close_run("PARASITISMO", tr("CLOSE_EVO_PARASITISMO_MASA"))

func activate_symbiosis():
	if mutation_homeostasis or mutation_hyperassimilation or mutation_red_micelial: return
	mutation_symbiosis = true
	mutation_activated.emit("simbiosis", tr("MUT_SIMBIOSIS"))

# =============================================================
# CICLO BIOLÓGICO: PRIMORDIO (Fase 2)
# =============================================================

func check_red_micelial_transition(_main_ref: Node):
	if mutation_red_micelial and red_micelial_phase == 0:
		# Fase A -> Fase B
		var hifas_req = 11.5 if red_branch_selected == RedBranch.COLONIZATION else 9.5
		var eps_req = 0.65 if red_branch_selected == RedBranch.COLONIZATION else 0.35

		if BiosphereEngine.hifas >= hifas_req \
		and BiosphereEngine.biomasa >= 5.0 \
		and StructuralModel.epsilon_runtime <= eps_req \
		and RunManager.run_time >= 200.0:
			red_micelial_phase = 1
			LogManager.add(tr("LOG_RED_FASE_B"))
			UIManager.show_toast(tr("TOAST_RED_INTEGRACION"))

func update_primordio(main_ref: Node) -> void:
	if red_branch_selected == RedBranch.COLONIZATION:
		_process_primordio_biological(main_ref)
	elif red_branch_selected == RedBranch.SYMBIOSIS:
		_process_primordio_mechanical(main_ref)

func _process_primordio_biological(_main_ref: Node):
	# ... (lógica anterior de primordio biológico) ...
	if not primordio_active and not seta_formada and red_micelial_phase == 1:
		if BiosphereEngine.hifas >= 14.5 and BiosphereEngine.biomasa >= 8.0:
			primordio_active = true
			LogManager.add(tr("LOG_PRIMORDIO_ALERT"))
			primordio_iniciado.emit()

	if primordio_active:
		primordio_timer += RunManager.LOGIC_TICK

		# Condiciones de supervivencia (Relajadas v0.8.40)
		var reason := ""
		if StructuralModel.epsilon_runtime >= 0.50: reason = "Estrés Crítico (>0.50)"
		elif BiosphereEngine.hifas >= 60.0: reason = "Inestabilidad por Hifas (>60)"
		elif EconomyManager.delta_per_sec < 50.0: reason = "Falta de Nutrientes (<50/$s)"

		if reason != "":
			_abort_primordio(reason)
			return

		if primordio_timer >= Balance.PRIMORDIO_DURATION:
			_complete_primordio()

func _process_primordio_mechanical(_main_ref: Node):
	# En la rama azul, el "primordio" es un proceso de Computación Estructural
	if not primordio_active and not nucleo_conciencia and red_micelial_phase == 1:
		# Requisitos: Contabilidad alta y estabilidad
		if UpgradeManager.level("accounting") >= 2 and StructuralModel.epsilon_runtime <= 0.25:
			primordio_active = true
			LogManager.add(tr("LOG_MC_SYNC_START"))
			UIManager.show_toast(tr("TOAST_MC_SISTEMA"))

	if primordio_active:
		# La estabilidad acelera el proceso
		var speed_mult = clamp(1.0 + (0.5 - StructuralModel.epsilon_runtime), 0.5, 2.0)
		primordio_timer += RunManager.LOGIC_TICK * speed_mult

		if primordio_timer >= Balance.PRIMORDIO_DURATION:
			primordio_active = false
			nucleo_conciencia = true
			LogManager.add(tr("LOG_MC_HITO"))
			# Bonus de eficiencia tecnológica
			EconomyManager.mutation_accounting_bonus += 0.2

func try_iniciar_primordio() -> bool:
	# Guards
	if not mutation_red_micelial: return false
	if red_branch_selected != RedBranch.COLONIZATION: return false
	if primordio_active or seta_formada: return false
	
	# Costo en micelio, escala con abortos previos
	var costo := 20.0 * (1.0 + primordio_abort_count * 0.2)
	if BiosphereEngine.micelio < costo:
		return false
	
	BiosphereEngine.micelio -= costo
	primordio_active = true
	primordio_timer = 0.0
	primordio_iniciado.emit()
	return true

func _abort_primordio(reason: String) -> void:
	primordio_active = false
	primordio_timer = 0.0
	primordio_abort_count += 1
	BiosphereEngine.micelio = max(BiosphereEngine.micelio - 40.0, 0.0)
	primordio_abortado.emit(primordio_abort_count, reason)

func _complete_primordio() -> void:
	primordio_active = false
	primordio_timer = 0.0
	seta_formada = true
	red_micelial_phase = 2  # Fase C: Seta formada, esporulación disponible
	seta_formada_signal.emit()
	AchievementManager.on_seta_formed()

# =============================================================
# COLOR DEL REACTOR — Fuente Única de Verdad (v0.8.27)
# SOLO modificar aquí si querés cambiar un color del reactor.
# =============================================================
func get_reactor_color() -> Color:
	# Prioridad 0A: MET.OSCURO (post-Depredador, bioquímica oscura)
	if mutation_met_oscuro:
		return Color(0.53, 0.27, 0.67)    # Púrpura Oscuro
	# Prioridad 0B: Depredador de Realidades
	if mutation_depredador:
		return Color(1.0, 0.0, 0.33)      # Rojo Glitch
	# Prioridad 0C: Vacío Hambriento (post-trascendencia)
	if RunManager.vacio_hambriento_active:
		return Color(0.75, 0.2, 1.0)      # Violeta Vacío
	# Prioridad 0: Seta Formada (v0.8.42 - Brillo máximo)
	if seta_formada:
		return Color(0.65, 1.2, 0.2)      # Verde Incandescente (sobrepasamos 1.0 para bloom)

	# Prioridad 1: Final por Esporulación
	if mutation_sporulation:
		return Color(0.7, 1.0, 0.4)       # Verde Nuclear

	# Prioridad 2: Ramas elegidas de Red Micelial
	if red_branch_selected == RedBranch.COLONIZATION:
		return Color(0.45, 1.0, 0.05)     # Verde Lima Líquido
	if red_branch_selected == RedBranch.SYMBIOSIS:
		return Color(0.0, 0.9, 1.0)       # Cian Eléctrico

	# Prioridad 3: Mutaciones base activas
	if mutation_hyperassimilation:
		# Fractura Epistémica cargando: lerp Rojo (HIPER) → Dorado (COLAPSO CONTROLADO)
		if RunManager._fractura_carga_timer > 0.0:
			var t := clampf(RunManager._fractura_carga_timer / RunManager.FRACTURA_CARGA_DURATION, 0.0, 1.0)
			return Color(0.95, 0.05, 0.05).lerp(Color(1.1, 0.85, 0.05), t)
		return Color(0.95, 0.05, 0.05)    # Rojo
	if mutation_homeorhesis:
		return Color(0.55, 1.0, 0.92)     # Aqua Nacarado (NG+++)
	if mutation_allostasis:
		return Color(0.2, 1.0, 0.88)      # Turquesa Brillante (NG+)
	if mutation_homeostasis:
		return Color(0.05, 0.88, 0.68)    # Verde Equilibrio
	if mutation_parasitism:
		return Color(1.0, 0.45, 0.0)      # Naranja
	if nucleo_conciencia:
		return Color(0.2, 0.5, 1.0)       # Azul Eléctrico (SINGULARIDAD)
	if mutation_red_micelial:
		return Color(0.3, 1.0, 0.3)       # Verde Hoja
	if mutation_symbiosis:
		return Color(0.4, 0.9, 0.7)       # Verde Agua

	# Prioridad 4: Base (sin mutaciones)
	return Color(0.15, 0.65, 1.0)         # Azul Tecnológico

# ==================== CARNAVAL DE MUTACIONES ====================
## Aplica una mutación del carnaval: limpia todas las flags y activa solo la indicada
func carnaval_set_mutation(id: String) -> void:
	# Limpiar flags Y genome states de las mutaciones rotativas + segundo nivel disruptivo
	mutation_hyperassimilation = false
	mutation_symbiosis = false
	mutation_homeostasis = false
	mutation_red_micelial = false
	mutation_parasitism = false
	mutation_depredador = false
	mutation_met_oscuro = false
	red_micelial_phase = 0
	genome["hiperasimilacion"] = "dormido"
	genome["simbiosis"] = "dormido"
	genome["homeostasis"] = "dormido"
	genome["red_micelial"] = "dormido"
	genome["parasitismo"] = "dormido"
	genome["depredador"] = "dormido"
	genome["met_oscuro"] = "dormido"
	# Resetear efectos persistentes de parasitismo que de otro modo matan la producción
	EconomyManager.parasitism_corrosion = 1.0
	# Las flags de segundo nivel (allostasis, homeorhesis, etc.) no se tocan — son sub-rutas
	match id:
		"homeostasis":
			mutation_homeostasis = true
			genome["homeostasis"] = "activo"
		"simbiosis":
			mutation_symbiosis = true
			genome["simbiosis"] = "activo"
		"red_micelial":
			mutation_red_micelial = true
			# phase = 0 en carnaval: efectos básicos sin primordio ni bifurcación
			genome["red_micelial"] = "activo"
		"parasitismo":
			mutation_parasitism = true
			genome["parasitismo"] = "activo"
		"hiperasimilacion":
			mutation_hyperassimilation = true
			genome["hiperasimilacion"] = "activo"
	print("🎭 [CARNAVAL] Mutación activa → %s" % id)

# =====================================================
#  PROCESS METHODS — NG+ ROUTES (llamados desde main._on_logic_tick)
# =====================================================

## Retorna true si el botón de sellado debe mostrarse (UI queda en main.gd)
func process_met_oscuro(dt: float) -> bool:
	_met_oscuro_active_time += dt
	var income_rate := BiosphereEngine.biomasa * 0.8
	_met_oscuro_income_accum += income_rate * dt
	if _met_oscuro_income_accum >= 1.0:
		var gain: float = floor(_met_oscuro_income_accum)
		EconomyManager.money += gain
		_met_oscuro_income_accum -= gain
	BiosphereEngine.biomasa += 0.1 * dt
	StructuralModel.epsilon_runtime = max(0.0, StructuralModel.epsilon_runtime - 0.05 * dt)
	_met_oscuro_status_timer += dt
	if _met_oscuro_status_timer >= MET_OSCURO_STATUS_INTERVAL:
		_met_oscuro_status_timer = 0.0
		LogManager.add(tr("LOG_MO_TICK") % [BiosphereEngine.biomasa, income_rate, EconomyManager.money])
	if BiosphereEngine.biomasa >= 100.0 and _met_oscuro_active_time >= 30.0 and not RunManager.run_closed:
		LegacyManager.add_pl(2)
		RunManager.close_run("METABOLISMO OSCURO", tr("CLOSE_MO_SATURACION"))
		return false
	if EconomyManager.money >= 1000000.0 and not RunManager.run_closed:
		RunManager.close_run("METABOLISMO OSCURO", tr("CLOSE_MO_MILLONARIO"))
		return false
	return _met_oscuro_active_time >= Balance.MET_OSCURO_SEAL_COOLDOWN

func process_depredador(dt: float) -> void:
	# Timer de inestabilidad: el Depredador es una mutación que no se sostiene.
	# Si el jugador no la resuelve antes del límite (sellando MET.OSCURO o
	# consumiendo todos los upgrades), el sistema implosiona → COLAPSO DEPREDATORIO.
	depredador_inestabilidad += dt
	if depredador_inestabilidad >= DEPREDADOR_INESTABILIDAD_MAX and not RunManager.run_closed:
		RunManager.close_run("COLAPSO DEPREDATORIO", tr("CLOSE_COLAPSO_DEP"))
		return
	_depredador_active_tick += dt
	if _depredador_active_tick >= 1.5:
		_depredador_active_tick = 0.0
		var devoured: bool = UpgradeManager.devour_random_upgrade()
		if devoured:
			BiosphereEngine.biomasa += 15.0
			met_oscuro_devoured_count += 1
			AchievementManager.push_event("depredador_devour", {})
			UIManager.show_toast(tr("TOAST_MO_DIGEST") % met_oscuro_devoured_count)
			if is_instance_valid(UIManager.big_click_button):
				UIManager.big_click_button.modulate = Color(randf(), randf(), randf())
		else:
			# Consumió toda la realidad antes de la implosión → trascendencia depredatoria.
			RunManager.close_run("DEPREDADOR DE REALIDADES", tr("CLOSE_DEP_REALIDADES"))

func process_depredador_progress(dt: float) -> void:
	_depredador_status_timer += dt
	if _depredador_status_timer >= DEPREDADOR_STATUS_INTERVAL:
		_depredador_status_timer = 0.0
		var pct := int((depredador_timer / 30.0) * 100.0)
		var bar_len := int(pct / 5.0)
		var bar := ""
		for i in range(20):
			bar += "|" if i < bar_len else "."
		LogManager.add(tr("LOG_DEP_TICK") % [StructuralModel.epsilon_runtime, bar, pct, depredador_timer])
		UIManager.show_toast(tr("TOAST_DEP_PROGRESS") % [pct, depredador_timer])

## Retorna 1 si glitch se activó, -1 si se desactivó, 0 si sin cambio
func process_glitch(_dt: float) -> int:
	if not LegacyManager.get_buff_value("metabolismo_glitch"):
		return 0
	var glitch_now := StructuralModel.epsilon_runtime > 0.40
	var result := 0
	if glitch_now and not _glitch_was_active:
		LogManager.add(tr("LOG_GLITCH_ACTIVO"))
		UIManager.show_toast(tr("TOAST_MG_ACTIVO"))
		result = 1
	elif not glitch_now and _glitch_was_active:
		UIManager.show_toast(tr("TOAST_MG_INACTIVO"))
		result = -1
	_glitch_was_active = glitch_now
	return result
