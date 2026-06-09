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

# === AUTOFAGIA NECRÓTICA (sub-ruta de Met. Oscuro) ===
var mutation_autolisis := false
var autolisis_devour_count: int = 0
var autolisis_devour_timer: float = 0.0
# Mejoras de autofagia (multinivel capeadas): aceleran/duplican los devours
var autofagia_speed_level: int = 0   # Enzimas Líticas → -5s por nivel (piso 5s)
var autofagia_double_level: int = 0  # Fagocitosis Doble → +20% chance devour doble por nivel

# === NECROSIS CONTROLADA (sub-ruta de Met. Oscuro, doble economía Ν) ===
var mutation_necrosis := false
var necrosis_omega: float = 0.10     # Ω controlado por la ruta (override del clamp de MO)
var necromasa: float = 0.0           # moneda Ν acumulada (atada al flujo real)
var necrosis_agent_count: int = 0    # Agentes Necróticos comprados

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
	autofagia_speed_level = 0
	autofagia_double_level = 0
	mutation_necrosis = false
	necrosis_omega = Balance.NECROSIS_OMEGA_START
	necromasa = 0.0
	necrosis_agent_count = 0
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
	var _bio_rate: float = Balance.AUTOLISIS_BIO_PASSIVE if mutation_autolisis else 0.1
	BiosphereEngine.biomasa += _bio_rate * dt
	StructuralModel.epsilon_runtime = max(0.0, StructuralModel.epsilon_runtime - 0.05 * dt)
	_met_oscuro_status_timer += dt
	if _met_oscuro_status_timer >= MET_OSCURO_STATUS_INTERVAL:
		_met_oscuro_status_timer = 0.0
		LogManager.add(tr("LOG_MO_TICK") % [BiosphereEngine.biomasa, income_rate, EconomyManager.money])
	# Autólisis/Necrosis toman el control del cierre — saltar los auto-cierres de MO
	if not mutation_autolisis and not mutation_necrosis:
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

## Intervalo efectivo entre devours, acortado por Enzimas Líticas (piso AUTOFAGIA_DEVOUR_FLOOR).
func autofagia_devour_interval() -> float:
	var reduced: float = Balance.AUTOLISIS_DEVOUR_INTERVAL - autofagia_speed_level * Balance.AUTOFAGIA_SPEED_REDUCTION
	return max(Balance.AUTOFAGIA_DEVOUR_FLOOR, reduced)

## Probabilidad [0,1] de devorar 2 upgrades en vez de 1 (Fagocitosis Doble).
func autofagia_double_chance() -> float:
	return min(1.0, autofagia_double_level * Balance.AUTOFAGIA_DOUBLE_PER_LEVEL)

## Devora el upgrade más caro y aplica el burst. Retorna true si quedaba material.
func _autofagia_consume_one() -> bool:
	var result: Dictionary = UpgradeManager.devour_most_expensive_upgrade()
	if not result.devoured:
		return false
	autolisis_devour_count += 1
	var burst_money: float = result.cost * Balance.AUTOLISIS_MONEY_BURST_MULT
	EconomyManager.money += burst_money
	var bio_burst: float = max(Balance.AUTOLISIS_BIO_BURST, result.cost / Balance.AUTOLISIS_BIO_FROM_COST_DIVISOR)
	if LegacyManager.get_buff_value("ciclo_catabolico"):
		bio_burst *= Balance.CICLO_CATABOLICO_BIO_MULT
	BiosphereEngine.biomasa += bio_burst
	UIManager.show_toast(tr("TOAST_AUTOLISIS_DEVOUR") % autolisis_devour_count)
	LogManager.add(tr("LOG_AUTOLISIS_DEVOUR") % [autolisis_devour_count, burst_money])
	return true

## Tick de autólisis. Cada intervalo (acortable) devora el upgrade más caro; con
## Fagocitosis Doble/Triple puede devorar hasta 3. Cuando no queda material → cierra por agotamiento.
func process_autolisis(dt: float) -> void:
	autolisis_devour_timer += dt
	if autolisis_devour_timer < autofagia_devour_interval():
		return
	autolisis_devour_timer = 0.0
	if not _autofagia_consume_one():
		if not RunManager.run_closed:
			RunManager.close_run("AUTOFAGIA NECRÓTICA", tr("CLOSE_AUTOLISIS_AGOTADO"))
		return
	# Fagocitosis Doble/Triple: cada roll exitoso habilita el siguiente (cap 3 devours por tick).
	var double_ch := autofagia_double_chance()
	if randf() < double_ch:
		if not _autofagia_consume_one():
			if not RunManager.run_closed:
				RunManager.close_run("AUTOFAGIA NECRÓTICA", tr("CLOSE_AUTOLISIS_AGOTADO"))
			return
		# Triple (3er devour) — solo si el doble ya tuvo éxito, misma probabilidad.
		if randf() < double_ch:
			if not _autofagia_consume_one():
				if not RunManager.run_closed:
					RunManager.close_run("AUTOFAGIA NECRÓTICA", tr("CLOSE_AUTOLISIS_AGOTADO"))

## Colapso voluntario del núcleo (cierre manual). Disponible tras N devours.
func autofagia_colapsar() -> void:
	if RunManager.run_closed or not mutation_autolisis:
		return
	if autolisis_devour_count < Balance.AUTOFAGIA_COLAPSO_MIN_DEVOURS:
		return
	RunManager.close_run("AUTOFAGIA NECRÓTICA", tr("CLOSE_AUTOFAGIA_COLAPSO"))

# ── Mejoras de autofagia: costo (bio + dinero) y compra ──────────────────────
## kind: "speed" | "double". Retorna {bio, money, level, maxed}.
func autofagia_upgrade_cost(kind: String) -> Dictionary:
	var lvl: int = autofagia_speed_level if kind == "speed" else autofagia_double_level
	var maxv: int = Balance.AUTOFAGIA_SPEED_MAX_LEVEL if kind == "speed" else Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL
	var scale: float = pow(Balance.AUTOFAGIA_UPG_COST_GROWTH, lvl)
	return {
		"bio": Balance.AUTOFAGIA_UPG_BIO_BASE * scale,
		"money": Balance.AUTOFAGIA_UPG_MONEY_BASE * scale,
		"level": lvl,
		"maxed": lvl >= maxv,
	}

func can_buy_autofagia_upgrade(kind: String) -> bool:
	if not mutation_autolisis or RunManager.run_closed:
		return false
	var c: Dictionary = autofagia_upgrade_cost(kind)
	if c.maxed:
		return false
	return BiosphereEngine.biomasa >= c.bio and EconomyManager.money >= c.money

func buy_autofagia_upgrade(kind: String) -> bool:
	if not can_buy_autofagia_upgrade(kind):
		return false
	var c: Dictionary = autofagia_upgrade_cost(kind)
	BiosphereEngine.biomasa -= c.bio
	EconomyManager.money -= c.money
	if kind == "speed":
		autofagia_speed_level += 1
		LogManager.add(tr("LOG_AUTOFAGIA_SPEED") % autofagia_speed_level)
	else:
		autofagia_double_level += 1
		LogManager.add(tr("LOG_AUTOFAGIA_DOUBLE") % int(autofagia_double_chance() * 100))
	AudioManager.play_sfx("upgrade")
	return true

# ── NECROSIS CONTROLADA ──────────────────────────────────────────────────────
## Activa la sub-ruta. Necrosis toma control de Ω (override del clamp de MO) y
## abre la doble economía: el flujo real genera Necromasa (Ν), Ν compra Agentes
## que empujan Ω hacia el floor. Irreversible.
func activate_necrosis() -> void:
	if mutation_necrosis:
		return
	mutation_necrosis = true
	necrosis_omega = Balance.NECROSIS_OMEGA_START
	necromasa = 0.0
	necrosis_agent_count = 0
	mutation_activated.emit("necrosis", tr("MUT_NECROSIS"))
	UIManager.show_toast(tr("TOAST_NECROSIS_START"))
	LogManager.add(tr("LOG_NECROSIS_START"))

## Multiplicador necrótico: rampa suave que premia cada paso, capeada cerca del floor.
func necrosis_mult() -> float:
	if not mutation_necrosis:
		return 1.0
	var safe_omega: float = max(necrosis_omega, Balance.NECROSIS_OMEGA_FLOOR)
	return clampf(Balance.NECROSIS_OMEGA_START / safe_omega, 1.0, Balance.NECROSIS_MULT_CAP)

## Índice necrótico [0,1]: progreso desde Ω inicial hasta el floor (para barra de progreso).
func necrosis_index() -> float:
	var span: float = Balance.NECROSIS_OMEGA_START - Balance.NECROSIS_OMEGA_FLOOR
	return clampf((Balance.NECROSIS_OMEGA_START - necrosis_omega) / max(span, 0.0001), 0.0, 1.0)

## Costo en Ν del próximo Agente Necrótico (escala con la cantidad comprada).
func necrosis_agent_cost() -> float:
	return Balance.NECROSIS_AGENT_COST_BASE * pow(Balance.NECROSIS_AGENT_COST_GROWTH, necrosis_agent_count)

func can_buy_necrosis_agent() -> bool:
	if not mutation_necrosis or RunManager.run_closed:
		return false
	return necromasa >= necrosis_agent_cost()

## Compra un Agente Necrótico: baja Ω (×factor) y sube el multiplicador. Cierra al cruzar el floor.
func buy_necrosis_agent() -> bool:
	if not can_buy_necrosis_agent():
		return false
	necromasa -= necrosis_agent_cost()
	necrosis_agent_count += 1
	necrosis_omega *= Balance.NECROSIS_AGENT_OMEGA_FACTOR
	AudioManager.play_sfx("upgrade")
	LogManager.add(tr("LOG_NECROSIS_AGENT") % [necrosis_agent_count, necrosis_omega])
	if necrosis_omega <= Balance.NECROSIS_OMEGA_FLOOR and not RunManager.run_closed:
		necrosis_omega = Balance.NECROSIS_OMEGA_FLOOR
		RunManager.close_run("NECROSIS CONTROLADA", tr("CLOSE_NECROSIS"))
	return true

## Tick de necrosis: la Necromasa también acumula del flujo pasivo realizado (0 bajo MO puro;
## la fuente principal es el click manual, en main.on_reactor_click). Anti-AFK: sin flujo, no hay Ν.
func process_necrosis(dt: float) -> void:
	if not mutation_necrosis or RunManager.run_closed:
		return
	var passive_flow: float = EconomyManager.get_passive_total()
	if passive_flow > 0.0:
		necromasa += passive_flow * Balance.NECROSIS_CONVERSION * dt

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
			var dep_bio: float = 15.0
			if LegacyManager.get_buff_value("ciclo_catabolico"):
				dep_bio *= Balance.CICLO_CATABOLICO_BIO_MULT
			BiosphereEngine.biomasa += dep_bio
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
