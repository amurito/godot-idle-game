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

# Primordio biológico ACTIVO (Fase 2): maduración por banda de ε + integridad
var primordio_integrity: float = 100.0
var primordio_pert_timer: float = 0.0
var primordio_regar_cd: float = 0.0

# Panspermia (Fase 3): lanzamiento post-ESPORULACIÓN — carga vs calor (dos presiones)
var panspermia_charge: float = 0.0
var panspermia_heat: float = 0.0
var panspermia_misfires: int = 0  # sobrecargas acumuladas; al llegar al máx → aborta a esporulación

# Singularidad (Fase 4, rama azul): integración de cómputo — sincronía vs temperatura
var nucleo_sync: float = 0.0
var nucleo_temp: float = 0.0

# === RAMA VERDE · COLONIZACIÓN activa (Empuje de Frontera) ===
var colonizacion_pert_timer: float = 0.0   # acumulador hacia el próximo evento de retracción
var colonizacion_phase_time: float = 0.0   # s en fase de empuje (escala la mordida de retracción)

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
# Compras de tiempo: cada una resta DEP_TIME_EXTENSION al timer y encarece la siguiente.
var depredador_timer_buys: int = 0
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
	primordio_integrity = 100.0
	primordio_pert_timer = 0.0
	primordio_regar_cd = 0.0
	panspermia_charge = 0.0
	panspermia_heat = 0.0
	panspermia_misfires = 0
	nucleo_sync = 0.0
	nucleo_temp = 0.0
	colonizacion_pert_timer = 0.0
	colonizacion_phase_time = 0.0
	allostasis_timer = 0.0
	homeorhesis_timer = 0.0
	depredador_timer = 0.0
	depredador_inestabilidad = 0.0
	depredador_timer_buys = 0
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
	if GenomeEvaluator.handle_terminal_mutations():
		return
	var ctx := GenomeEvaluator.build_eval_context()
	GenomeEvaluator.update_hiperasimilacion(ctx)
	GenomeEvaluator.update_parasitismo(ctx)
	GenomeEvaluator.update_met_oscuro(ctx)
	GenomeEvaluator.update_depredador(ctx)
	GenomeEvaluator.update_simbiosis(ctx)
	GenomeEvaluator.update_homeostasis(ctx)
	GenomeEvaluator.update_allostasis(ctx)
	GenomeEvaluator.update_homeorhesis(ctx)
	GenomeEvaluator.update_red_micelial(ctx)
	GenomeEvaluator.update_esporulacion(ctx)
	GenomeEvaluator.check_automatic_activations()


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
	depredador_timer_buys = 0
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
	# Inicio: frontera micelial empujada al 60% (Fase 1) + masa/hifas mínimas.
	if not primordio_active and not seta_formada and red_micelial_phase == 1:
		if BiosphereEngine.micelio >= 60.0 and BiosphereEngine.hifas >= 14.5 and BiosphereEngine.biomasa >= 8.0:
			_begin_primordio_biological()

	if primordio_active:
		var dt := RunManager.LOGIC_TICK
		if primordio_regar_cd > 0.0:
			primordio_regar_cd = max(0.0, primordio_regar_cd - dt)

		# La maduración avanza SIEMPRE; el desafío es SOBREVIVIR las contaminaciones
		# escalantes con el agua finita (Regar). Sin regar, la integridad colapsa antes de los 60s.
		primordio_timer += dt
		# Penalización por sobrecalentar (overclickear sube ε > techo): drena integridad extra.
		if StructuralModel.epsilon_runtime > Balance.PRIMORDIO_BAND_HI:
			primordio_integrity -= Balance.PRIMORDIO_OOB_DRAIN * dt

		# Contaminaciones periódicas (escalan con la maduración).
		primordio_pert_timer += dt
		if primordio_pert_timer >= Balance.PRIMORDIO_PERT_INTERVAL:
			primordio_pert_timer = 0.0
			var dmg: float = min(
				Balance.PRIMORDIO_PERT_DMG_BASE + primordio_timer * Balance.PRIMORDIO_PERT_DMG_SCALE,
				Balance.PRIMORDIO_PERT_DMG_MAX
			)
			primordio_integrity -= dmg
			StructuralModel.epsilon_runtime += Balance.PRIMORDIO_PERT_EPS_KICK
			LogManager.add(tr("PRIMORDIO_CONTAM_LOG") % int(dmg))
			UIManager.show_toast(tr("PRIMORDIO_CONTAM_TOAST") % int(dmg))

		primordio_integrity = clampf(primordio_integrity, 0.0, Balance.PRIMORDIO_INTEGRITY_MAX)

		if primordio_integrity <= 0.0:
			_abort_primordio(tr("PRIMORDIO_ABORT_CONTAM"))
			return

		if primordio_timer >= Balance.PRIMORDIO_BIO_MATURE:
			_complete_primordio()

## Arranca el primordio biológico (desde el botón o el auto-trigger): resetea la maduración activa.
func _begin_primordio_biological() -> void:
	primordio_active = true
	primordio_timer = 0.0
	primordio_integrity = Balance.PRIMORDIO_INTEGRITY_MAX
	primordio_pert_timer = 0.0
	primordio_regar_cd = 0.0
	LogManager.add(tr("LOG_PRIMORDIO_ALERT"))
	primordio_iniciado.emit()

## Acción activa "Regar": gasta biomasa, restaura integridad y reencauza ε hacia el centro de banda.
func primordio_regar() -> void:
	if not primordio_active: return
	if BiosphereEngine.biomasa < Balance.PRIMORDIO_REGAR_COST_BIO:
		UIManager.show_toast(tr("PRIMORDIO_SIN_BIO") % BiosphereEngine.biomasa)
		return
	BiosphereEngine.biomasa -= Balance.PRIMORDIO_REGAR_COST_BIO
	primordio_integrity = min(primordio_integrity + Balance.PRIMORDIO_REGAR_HEAL, Balance.PRIMORDIO_INTEGRITY_MAX)
	# Enfría: baja ε hacia la zona segura (saca del sobrecalentamiento de las contaminaciones).
	StructuralModel.epsilon_runtime = move_toward(StructuralModel.epsilon_runtime, Balance.PRIMORDIO_BAND_LO, Balance.PRIMORDIO_REGAR_EPS_PULL)
	AudioManager.play_sfx("click")
	UIManager.show_toast(tr("PRIMORDIO_REGADO_TOAST") % [int(Balance.PRIMORDIO_REGAR_HEAL), int(primordio_integrity)])

# =============================================================
# RAMA VERDE · PANSPERMIA NEGRA (Secuencia de Lanzamiento) — Fase 3
# Post-ESPORULACIÓN: reformar la seta y EYECTAR N veces. Cada pulso cuesta $ (escalado)
# y suma calor; el calor disipa con el tiempo. Sobrecarga → pulso falla (pulsar-esperar).
# =============================================================

func is_panspermia_window() -> bool:
	return mutation_red_micelial and red_branch_selected == RedBranch.COLONIZATION \
		and seta_formada and not RunManager.run_closed \
		and (LegacyManager.last_run_ending == "ESPORULACIÓN" or LegacyManager.last_run_ending == "PANSPERMIA NEGRA")

func panspermia_pulse_cost() -> float:
	return Balance.PANSPERMIA_PULSE_COST

## Disipa carga Y calor con el tiempo (llamado desde el logic tick). La carga decae →
## hay que seguir eyectando; el calor decae → tras un misfire podés volver a eyectar.
func process_panspermia(dt: float) -> void:
	if not is_panspermia_window():
		return
	if panspermia_charge > 0.0:
		panspermia_charge = max(0.0, panspermia_charge - Balance.PANSPERMIA_CHARGE_DECAY * dt)
	if panspermia_heat > 0.0:
		panspermia_heat = max(0.0, panspermia_heat - Balance.PANSPERMIA_HEAT_DECAY * dt)

## Una eyección. Sube carga + calor. Si sobrecalienta → MISFIRE (pierde carga, no avanza).
## Retorna true si la carga llegó a la velocidad de escape (lanzamiento exitoso).
func panspermia_pulse() -> bool:
	var cost: float = Balance.PANSPERMIA_PULSE_COST
	if EconomyManager.money < cost:
		UIManager.show_toast(tr("PANSPERMIA_NEED_MONEY") % cost)
		return false
	# Sobrecalentamiento: la eyección falla y la carga retrocede (penaliza el spam).
	if panspermia_heat + Balance.PANSPERMIA_HEAT_PER_PULSE > Balance.PANSPERMIA_HEAT_MAX:
		panspermia_heat = Balance.PANSPERMIA_HEAT_MAX
		panspermia_charge = max(0.0, panspermia_charge - Balance.PANSPERMIA_OVERLOAD_PENALTY)
		panspermia_misfires += 1
		if panspermia_misfires >= Balance.PANSPERMIA_MAX_MISFIRES:
			# Demasiadas sobrecargas: las esporas no escapan → esporulación local de respaldo (sin Panspermia).
			var esporas := BiosphereEngine.trigger_sporulation()
			if esporas > 1.0:
				LegacyManager.add_spores(esporas)
			LogManager.add(tr("PANSPERMIA_ABORTADO"))
			RunManager.close_run("ESPORULACIÓN", tr("CLOSE_PANSPERMIA_FAIL"))
			return false
		UIManager.show_toast(tr("PANSPERMIA_OVERLOAD") % [panspermia_misfires, Balance.PANSPERMIA_MAX_MISFIRES])
		return false
	EconomyManager.money -= cost
	panspermia_charge += Balance.PANSPERMIA_CHARGE_GAIN
	panspermia_heat += Balance.PANSPERMIA_HEAT_PER_PULSE
	StructuralModel.epsilon_runtime += Balance.PANSPERMIA_PULSE_EPS
	AudioManager.play_sfx("click")
	if panspermia_charge >= Balance.PANSPERMIA_CHARGE_GOAL:
		return true
	UIManager.show_toast(tr("PANSPERMIA_PULSE_OK") % [int(panspermia_charge), int(panspermia_heat)])
	return false

## SINCRONIZACIÓN (rama azul): el medidor sube mientras se cumplen TODAS las condiciones de
## fase a la vez; si se rompe alguna, baja. No es un minijuego de botón: es alcanzar y SOSTENER
## el estado de sincronía (acc + Ω + ε en banda + biomasa) hasta integrar el Núcleo de Conciencia.
func _process_primordio_mechanical(_main_ref: Node):
	if nucleo_conciencia:
		return
	var dt := RunManager.LOGIC_TICK
	if _nucleo_conditions_met():
		nucleo_sync = min(nucleo_sync + Balance.NUCLEO_SYNC_RATE * dt, Balance.NUCLEO_SYNC_GOAL)
		if nucleo_sync >= Balance.NUCLEO_SYNC_GOAL:
			nucleo_conciencia = true
			primordio_active = false
			EconomyManager.mutation_accounting_bonus += 0.2
			LogManager.add(tr("LOG_MC_HITO"))
			UIManager.show_toast(tr("EVO_NUCLEUS_SYNC"))
	else:
		nucleo_sync = max(0.0, nucleo_sync - Balance.NUCLEO_SYNC_DECAY * dt)

## Las cuatro condiciones de fase del Núcleo (todas simultáneas).
func _nucleo_conditions_met() -> bool:
	var eps: float = StructuralModel.epsilon_runtime
	return UpgradeManager.level("accounting") >= Balance.NUCLEO_ACC_MIN \
		and StructuralModel.omega >= Balance.NUCLEO_OMEGA_MIN \
		and eps >= Balance.NUCLEO_EPS_LO and eps <= Balance.NUCLEO_EPS_HI \
		and BiosphereEngine.biomasa >= Balance.NUCLEO_BIO_MIN

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
	_begin_primordio_biological()
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
# RAMA VERDE · COLONIZACIÓN activa (Empuje de Frontera) — anti-AFK
# El micelio ya no se llena solo: se empuja con clicks contra el decay,
# y el sustrato muerde la frontera con retracciones que escalan.
# =============================================================

func is_colonizacion_pushable() -> bool:
	return mutation_red_micelial and red_branch_selected == RedBranch.COLONIZATION \
		and red_micelial_phase < 2 and not seta_formada and not primordio_active

## Llamado por cada click manual (main.on_reactor_click): empuja la frontera micelial.
func colonizacion_pulse() -> void:
	if not is_colonizacion_pushable():
		return
	BiosphereEngine.micelio = min(BiosphereEngine.micelio + Balance.MICELIO_PULSE_GAIN, 100.0)

## Tick de la fase: dispara retracciones periódicas cuya mordida escala con el tiempo.
func process_colonizacion(dt: float) -> void:
	if not is_colonizacion_pushable():
		colonizacion_phase_time = 0.0
		colonizacion_pert_timer = 0.0
		return
	colonizacion_phase_time += dt
	colonizacion_pert_timer += dt
	if colonizacion_pert_timer >= Balance.COLONIZ_PERT_INTERVAL:
		colonizacion_pert_timer = 0.0
		if BiosphereEngine.micelio <= 0.0:
			return
		var bite: float = min(
			Balance.COLONIZ_PERT_BITE_BASE + colonizacion_phase_time * Balance.COLONIZ_PERT_BITE_SCALE,
			Balance.COLONIZ_PERT_BITE_MAX
		)
		BiosphereEngine.micelio = max(BiosphereEngine.micelio - bite, 0.0)
		LogManager.add(tr("COLONIZ_RETRACCION_LOG") % int(bite))
		UIManager.show_toast(tr("COLONIZ_RETRACCION_TOAST") % int(bite))

# =============================================================
# COLOR DEL REACTOR — Fuente Única de Verdad (v0.8.27)
# SOLO modificar aquí si querés cambiar un color del reactor.
# =============================================================
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
	# El frenesí acelera tras DEP_DEVOUR_TICK_FAST_AT comidos.
	var devour_tick: float = Balance.DEP_DEVOUR_TICK_FAST if met_oscuro_devoured_count >= Balance.DEP_DEVOUR_TICK_FAST_AT else Balance.DEP_DEVOUR_TICK_BASE
	if _depredador_active_tick >= devour_tick:
		_depredador_active_tick = 0.0
		var devoured: bool = UpgradeManager.devour_random_upgrade()
		if devoured:
			BiosphereEngine.biomasa += 15.0
			met_oscuro_devoured_count += 1
			AchievementManager.push_event("depredador_devour", {})
			UIManager.show_toast(tr("TOAST_MO_DIGEST") % met_oscuro_devoured_count)
			# Hitos de devorado: regalar tiempo al cruzar 30/50/70/90 comidos para que
			# llegar a DEPREDADOR DE REALIDADES no sea una carrera imposible contra el timer.
			# El conteo sube de a 1, así que cada hito se cruza exactamente una vez.
			if met_oscuro_devoured_count in Balance.DEP_DEVOUR_MILESTONES:
				depredador_inestabilidad = max(0.0, depredador_inestabilidad - Balance.DEP_DEVOUR_MILESTONE_BONUS)
				UIManager.show_toast(tr("TOAST_DEP_DEVOUR_MILESTONE") % [met_oscuro_devoured_count, Balance.DEP_DEVOUR_MILESTONE_BONUS])
			if is_instance_valid(UIManager.big_click_button):
				UIManager.big_click_button.modulate = Color(randf(), randf(), randf())
		else:
			# Consumió toda la realidad antes de la implosión → trascendencia depredatoria.
			RunManager.close_run("DEPREDADOR DE REALIDADES", tr("CLOSE_DEP_REALIDADES"))

# Costo en biomasa de la próxima compra de tiempo del timer de inestabilidad.
# Escala exponencialmente para que estirar el timer sea cada vez más caro.
func depredador_time_cost() -> float:
	return Balance.DEP_TIME_COST_BASE * pow(Balance.DEP_TIME_COST_GROWTH, float(depredador_timer_buys))

# Compra DEP_TIME_EXTENSION segundos de timer pagando biomasa. Retorna true si tuvo éxito.
func buy_depredador_time() -> bool:
	if not mutation_depredador or RunManager.run_closed:
		return false
	var cost: float = depredador_time_cost()
	if BiosphereEngine.biomasa < cost:
		return false
	BiosphereEngine.biomasa -= cost
	depredador_timer_buys += 1
	depredador_inestabilidad = max(0.0, depredador_inestabilidad - Balance.DEP_TIME_EXTENSION)
	UIManager.show_toast(tr("TOAST_DEP_TIME_BOUGHT") % Balance.DEP_TIME_EXTENSION)
	return true

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
