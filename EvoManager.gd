extends Node

# EvoManager.gd — Autoload
# Maneja la evolución del genoma y las mutaciones irreversibles.
# Actúa de forma autónoma: observa a BiosphereEngine y main.gd,
# muta su propio estado y emite señales para que main actúe.

signal mutation_unlocked(mutation_id: String)
signal mutation_activated(mutation_id: String, display_name: String)
signal run_ended_by_mutation(route: String, reason: String)
@warning_ignore("unused_signal")
signal primordio_iniciado()
@warning_ignore("unused_signal")
signal primordio_abortado(abort_count: int, reason: String)
@warning_ignore("unused_signal")
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

# === AUTÓLISIS DIRIGIDA (sub-ruta de Met. Oscuro) ===
var mutation_autolisis := false
var autolisis_devour_count: int = 0
var autolisis_devour_timer: float = 0.0

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
	mutation_autolisis = false
	autolisis_devour_count = 0
	autolisis_devour_timer = 0.0
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
# CICLO BIOLÓGICO: PRIMORDIO — delegates a PrimordioLogic
# (lógica extraída a PrimordioLogic.gd; vars de estado permanecen aquí)
# =============================================================
func check_red_micelial_transition(m: Node) -> void: PrimordioLogic.check_red_micelial_transition(m)
func update_primordio(m: Node) -> void: PrimordioLogic.update_primordio(m)
func primordio_regar() -> void: PrimordioLogic.primordio_regar()
func try_iniciar_primordio() -> bool: return PrimordioLogic.try_iniciar_primordio()
func is_panspermia_window() -> bool: return PrimordioLogic.is_panspermia_window()
func panspermia_pulse_cost() -> float: return PrimordioLogic.panspermia_pulse_cost()
func process_panspermia(dt: float) -> void: PrimordioLogic.process_panspermia(dt)
func panspermia_pulse() -> bool: return PrimordioLogic.panspermia_pulse()
func is_colonizacion_pushable() -> bool: return PrimordioLogic.is_colonizacion_pushable()
func colonizacion_pulse() -> void: PrimordioLogic.colonizacion_pulse()
func process_colonizacion(dt: float) -> void: PrimordioLogic.process_colonizacion(dt)

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
	# Autólisis toma el control del cierre — saltar los auto-cierres de MO
	if not mutation_autolisis:
		if BiosphereEngine.biomasa >= 100.0 and _met_oscuro_active_time >= 30.0 and not RunManager.run_closed:
			LegacyManager.add_pl(2)
			RunManager.close_run("METABOLISMO OSCURO", tr("CLOSE_MO_SATURACION"))
			return false
		if EconomyManager.money >= 1000000.0 and not RunManager.run_closed:
			RunManager.close_run("METABOLISMO OSCURO", tr("CLOSE_MO_MILLONARIO"))
			return false
	return _met_oscuro_active_time >= Balance.MET_OSCURO_SEAL_COOLDOWN

func activate_autolisis() -> void:
	if mutation_autolisis:
		return
	mutation_autolisis = true
	autolisis_devour_timer = 0.0
	mutation_activated.emit("autolisis", tr("MUT_AUTOLISIS"))
	UIManager.show_toast(tr("TOAST_AUTOLISIS_START"))
	LogManager.add(tr("LOG_AUTOLISIS_START"))

## Tick de autólisis. Cada AUTOLISIS_DEVOUR_INTERVAL devora el upgrade más caro.
## Cada devour da un burst de $ (proporcional al costo del upgrade) + bio fija.
## Cuando no quedan upgrades → run closes por agotamiento.
func process_autolisis(dt: float) -> void:
	autolisis_devour_timer += dt
	if autolisis_devour_timer < Balance.AUTOLISIS_DEVOUR_INTERVAL:
		return
	autolisis_devour_timer = 0.0
	var result: Dictionary = UpgradeManager.devour_most_expensive_upgrade()
	if not result.devoured:
		if not RunManager.run_closed:
			RunManager.close_run("AUTÓLISIS DIRIGIDA", tr("CLOSE_AUTOLISIS_AGOTADO"))
		return
	autolisis_devour_count += 1
	var burst_money: float = result.cost * Balance.AUTOLISIS_MONEY_BURST_MULT
	EconomyManager.money += burst_money
	BiosphereEngine.biomasa += Balance.AUTOLISIS_BIO_BURST
	UIManager.show_toast(tr("TOAST_AUTOLISIS_DEVOUR") % autolisis_devour_count)
	LogManager.add(tr("LOG_AUTOLISIS_DEVOUR") % [autolisis_devour_count, burst_money])

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
