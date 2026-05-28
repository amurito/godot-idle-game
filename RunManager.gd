extends Node

# RunManager.gd — Autoload
# Gestiona el ciclo de vida de la run: cierres, chequeos finales, homeostasis, perturbaciones.

signal disturbance_triggered(shock: float, is_extreme: bool)

# ==================== CONSTANTES ====================
const LOGIC_TICK := 0.2

# ==================== ESTADO DE RUN ====================
var run_time: float = 0.0
var run_closed := false
var final_route := "NONE"
var final_reason := ""
var homeostasis_mode := false
var post_homeostasis := false
var homeostasis_timer := 0.0

var resilience_score := 0.0
var disturbance_timer := 0.0
const DISTURBANCE_INTERVAL := 20.0

var legacy_homeostasis := false
var disturbances_survived: int = 0
var disturbances_without_reset: int = 0  # Racha de perturbaciones sin reset de timer (para logro)
var is_recovering_from_shock: bool = false
var is_recovering_from_extreme: bool = false  # shock de 0.8-1.0 en curso
var _shock_peak_epsilon: float = 0.0          # epsilon_runtime al pico del shock (para logro presion_adaptativa)
var extreme_shocks_recovered: int = 0         # veces que se volvió a banda tras shock extremo
var omega_min_peak: float = 0.0  # Máximo histórico de omega_min en la run

# FRACTURA EPISTÉMICA — carga sostenida antes de COLAPSO CONTROLADO
var _fractura_carga_timer: float = 0.0
const FRACTURA_CARGA_DURATION := 20.0  # segundos de ε > 0.90 sostenido con HIPER activa

var evolution_button: Button = null
var target_evolution: String = ""

# NG+ MENTE COLMENA — runtime state + auto-buy
var mente_colmena_active: bool = false
var mente_colmena_timer: float = 0.0
var _mente_colmena_buy_timer: float = 0.0
const MENTE_COLMENA_BUY_PRIORITY: Array = [
	"accounting", "trueque", "auto", "trueque_net", "auto_mult",
	"cognitive", "persistence", "specialization", "click_mult", "click",
]

# ==================== POST-TRASCENDENCIA (v0.9.8) ====================
# VACÍO HAMBRIENTO
var vacio_hambriento_active: bool = false
var vacio_hambriento_mult: float = 1.0   # ×100 si activo
var ascesis_timer: float = 0.0

# REENCARNACIÓN HEREDADA
var reencarnacion_active: bool = false

# CARNAVAL DE MUTACIONES
var carnaval_active: bool = false
var carnaval_mutations: Array = []        # 3 ids de mutación seleccionados al azar
var carnaval_index: int = 0
var carnaval_timer: float = 0.0
var carnaval_total_rotations: int = 0    # Cuenta rotaciones para POLIMORFÍA TOTAL
var carnaval_peak_money: float = 0.0     # Pico de dinero alcanzado en carnaval
const CARNAVAL_POOL := ["homeostasis", "simbiosis", "red_micelial", "parasitismo", "hiperasimilacion"]

# ==================== INICIALIZACIÓN ====================
func reset():
	run_time = 0.0
	run_closed = false
	final_route = "NONE"
	final_reason = ""
	homeostasis_mode = false
	post_homeostasis = false
	resilience_score = 0.0
	homeostasis_timer = 0.0
	homeostasis_tier_reached = 0
	disturbances_survived = 0
	disturbances_without_reset = 0
	is_recovering_from_shock = false
	is_recovering_from_extreme = false
	extreme_shocks_recovered = 0
	omega_min_peak = 0.0
	legacy_homeostasis = false
	vacio_hambriento_active = false
	vacio_hambriento_mult = 1.0
	ascesis_timer = 0.0
	reencarnacion_active = false
	carnaval_active = false
	carnaval_mutations = []
	carnaval_index = 0
	carnaval_timer = 0.0
	carnaval_total_rotations = 0
	carnaval_peak_money = 0.0
	mente_colmena_active = false
	mente_colmena_timer = 0.0
	_mente_colmena_buy_timer = 0.0
	_fractura_carga_timer = 0.0

# ==================== HELPERS ====================
func get_en_banda_homeostatica() -> bool:
	return StructuralModel.epsilon_runtime >= 0.03 and StructuralModel.epsilon_runtime <= 0.30

# ==================== CIERRE DE RUN ====================
func close_run(route: String, reason: String):
	if run_closed: return
	run_closed = true
	final_route = route
	final_reason = reason
	AudioManager.play_sfx("run_close")
	LogManager.add(tr("LOG_RUN_CLOSED") % route)

	LegacyManager.last_run_ending = route
	LegacyManager.mark_ending_achieved(route) # Tracking persistente para gate de Trascendencia
	LegacyManager.on_run_ended(EconomyManager.cached_mu)  # Notificar μ final para desbloqueos
	LegacyManager.save_legacy()

	# Logros — notificar cierre de run (antes de resetear contadores)
	AchievementManager.on_run_closed(route)

	# SINGULARIDAD: PL variable (6 + bonus épsilon) ya otorgado en main.gd antes de close_run()
	var pl_to_add: int = Balance.PL_REWARDS.get(route, 0)
	var _total_pl := pl_to_add

	if pl_to_add > 0:
		LegacyManager.add_pl(pl_to_add)
		UIManager.show_toast(tr("MSG_PL_GAINED") % [pl_to_add, route])
	LogManager.add(tr("LOG_PL_BASE") % [pl_to_add, route])

	# COLAPSO CONTROLADO (Banco Genético): +PL extra según ε_peak alcanzado esta run
	if LegacyManager.get_buff_value("colapso_controlado"):
		var eps_bonus: float = LegacyManager.get_effect_value("epsilon_peak_pl_bonus")
		var extra_pl: int = int(floor(StructuralModel.epsilon_peak * eps_bonus))
		if extra_pl > 0:
			LegacyManager.add_pl(extra_pl)
			_total_pl += extra_pl
			LogManager.add(tr("LOG_PL_COLAPSO") % [extra_pl, StructuralModel.epsilon_peak, eps_bonus])

	# NG+ Bonus variable (t >= 1): PL adicional según rendimiento de la run
	if LegacyManager.trascendencia_count >= 1:
		var ng_bonus := 0
		var ng_formula := ""
		var cap: int = Balance.NG_CAPS.get(route, 0)
		match route:
			# ── Tier 1 ──
			"HOMEOSTASIS":
				var raw := int(floor(resilience_score / 50.0))
				ng_bonus = min(raw, cap)
				ng_formula = "resiliencia %.0f / 50 = %d (cap %d)" % [resilience_score, ng_bonus, cap]
			"SIMBIOSIS":
				var raw := int(floor(run_time / 300.0))
				ng_bonus = min(raw, cap)
				ng_formula = "run_time %.0fs / 300 = %d (cap %d)" % [run_time, ng_bonus, cap]
			"HIPERASIMILACION", "HIPERASIMILACIÓN":
				var raw := int(floor(StructuralModel.epsilon_peak * 5.0))
				ng_bonus = min(raw, cap)
				ng_formula = "ε_peak %.2f × 5 = %d (cap %d)" % [StructuralModel.epsilon_peak, ng_bonus, cap]
			"PARASITISMO":
				var raw := int(floor(BiosphereEngine.biomasa / 8.0))
				ng_bonus = min(raw, cap)
				ng_formula = "biomasa %.1f / 8 = %d (cap %d)" % [BiosphereEngine.biomasa, ng_bonus, cap]
			# ── Red micelial ──
			"ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL":
				var raw := int(floor(BiosphereEngine.micelio / 20.0))
				ng_bonus = min(raw, cap)
				ng_formula = "micelio %.1f / 20 = %d (cap %d)" % [BiosphereEngine.micelio, ng_bonus, cap]
			# ── Tier 2 ──
			"ALLOSTASIS":
				ng_bonus = min(disturbances_survived, cap)
				ng_formula = "perturbaciones %d (cap %d)" % [disturbances_survived, cap]
			"HOMEORHESIS":
				var raw := int(floor(omega_min_peak * 10.0))
				ng_bonus = min(raw, cap)
				ng_formula = "omega_min_peak %.2f × 10 = %d (cap %d)" % [omega_min_peak, ng_bonus, cap]
			"MUTACION_FINAL", "METABOLISMO OSCURO":
				var raw := EvoManager.met_oscuro_devoured_count * 2
				ng_bonus = min(raw, cap)
				ng_formula = "devoured %d × 2 = %d (cap %d)" % [EvoManager.met_oscuro_devoured_count, ng_bonus, cap]
			"POLIMORFÍA TOTAL", "POLIMORFIA TOTAL":
				var raw := int(floor(carnaval_total_rotations / 2.0))
				ng_bonus = min(raw, cap)
				ng_formula = "rotaciones %d / 2 = %d (cap %d)" % [carnaval_total_rotations, ng_bonus, cap]
			"DOMADOR DEL CAOS":
				var raw := int(floor(carnaval_peak_money / 500_000.0))
				ng_bonus = min(raw, cap)
				ng_formula = "dinero_pico $%.1fM / 500K = %d (cap %d)" % [carnaval_peak_money / 1_000_000.0, ng_bonus, cap]
			"ASCESIS_PROFUNDA":
				var raw := int(floor(omega_min_peak * 10.0))
				ng_bonus = min(raw, cap)
				ng_formula = "omega_min_peak %.2f × 10 = %d (cap %d)" % [omega_min_peak, ng_bonus, cap]
			# ── Tier 3 (late-game) ──
			"MENTE COLMENA DISTRIBUIDA":
				var raw := int(floor(run_time / 600.0))
				ng_bonus = min(raw, cap)
				ng_formula = "run_time %.0fs / 600 = %d (cap %d)" % [run_time, ng_bonus, cap]
			"DEPREDADOR DE REALIDADES":
				var raw := EvoManager.met_oscuro_devoured_count
				ng_bonus = min(raw, cap)
				ng_formula = "devoured %d (cap %d)" % [EvoManager.met_oscuro_devoured_count, cap]
			"COLAPSO DEPREDATORIO":
				var raw := EvoManager.met_oscuro_devoured_count * 2
				ng_bonus = min(raw, cap)
				ng_formula = "devoured %d × 2 = %d (cap %d)" % [EvoManager.met_oscuro_devoured_count, ng_bonus, cap]
			"PANSPERMIA NEGRA":
				var raw := int(floor(BiosphereEngine.micelio / 20.0))
				ng_bonus = min(raw, cap)
				ng_formula = "micelio %.1f / 20 = %d (cap %d)" % [BiosphereEngine.micelio, ng_bonus, cap]
		if ng_bonus > 0:
			LegacyManager.add_pl(ng_bonus)
			_total_pl += ng_bonus
		LogManager.add(tr("LOG_PL_NG") % [ng_bonus, ng_formula])

	LegacyManager.record_run_end(route, reason, run_time, EconomyManager.cached_mu, StructuralModel.epsilon_peak, _total_pl)

	# Resetear estado de run ANTES de guardar para no heredar shocks/perturbaciones
	disturbances_survived = 0
	disturbances_without_reset = 0
	is_recovering_from_shock = false
	is_recovering_from_extreme = false
	extreme_shocks_recovered = 0
	homeostasis_tier_reached = 0

	TelemetryManager.close_run({"pl_gained": _total_pl})
	SaveManager.save_game(get_tree().get_first_node_in_group("main"))

func enter_post_homeostasis():
	post_homeostasis = true
	LogManager.add(tr("LOG_POST_HOMEOSTASIS"))

# ==================== CHEQUEOS FINALES ====================
# HOMEOSTASIS → ALLOSTASIS → HOMEORHESIS son tiers progresivos EN LA MISMA RUN.
# El jugador activa HOMEOSTASIS una sola vez y decide cuándo sellar el final.
# Cada tier desbloquea el botón de cierre correspondiente; cuanto más aguanta, mejor ending.

var homeostasis_tier_reached := 0  # 0=ninguno, 1=homeostasis, 2=allostasis, 3=homeorhesis

func check_homeostasis_final(delta: float):
	if carnaval_active or run_closed or not EvoManager.mutation_homeostasis:
		if not EvoManager.mutation_homeostasis:
			homeostasis_timer = max(homeostasis_timer - delta * 2.0, 0.0)
		return

	var banda_estricta = get_en_banda_homeostatica()
	var flexibilidad_minima = StructuralModel.omega > 0.25
	var control_activo = UpgradeManager.level("accounting") >= 1
	var metabolismo_activo = EconomyManager.delta_per_sec > 30.0
	var crecimiento_controlado = BiosphereEngine.biomasa < 12.0
	var redundancia = StructuralModel.unlocked_d and StructuralModel.unlocked_e

	if banda_estricta and flexibilidad_minima and control_activo and metabolismo_activo and crecimiento_controlado and redundancia:
		homeostasis_timer += delta
	else:
		if StructuralModel.epsilon_effective > 0.35:
			homeostasis_timer = 0.0
			disturbances_without_reset = 0 # Rompe la racha de "arquitecto_caos"
		else:
			homeostasis_timer = max(homeostasis_timer - delta, 0.0)

	# Tier 1: HOMEOSTASIS — 18s en banda
	if homeostasis_timer >= Balance.HOMEOSTASIS_TIME_REQUIRED and homeostasis_tier_reached < 1:
		homeostasis_tier_reached = 1
		post_homeostasis = true
		LogManager.add(tr("LOG_TIER1_HOMEOSTASIS"))
		UIManager.show_toast(tr("TOAST_HOMEOSTASIS"))

	# Tier 2: ALLOSTASIS — más perturbaciones, metabolismo mayor
	if homeostasis_tier_reached >= 1 and homeostasis_tier_reached < 2:
		var delta_real :float = EconomyManager.get_contribution_breakdown().total
		var ok = disturbances_survived >= 3 and StructuralModel.omega_min >= 0.40 \
			and resilience_score >= 150.0 and UpgradeManager.level("accounting") >= 2 \
			and delta_real > 200.0
		if ok:
			homeostasis_tier_reached = 2
			if not LegacyManager.get_buff_value("legado_alostasis"):
				LegacyManager.grant_buff("legado_alostasis")
			LogManager.add(tr("LOG_TIER2_ALLOSTASIS"))
			UIManager.show_toast(tr("TOAST_ALLOSTASIS"))

	# Tier 3: HOMEORHESIS — shock extremo + larga duración
	if homeostasis_tier_reached >= 2 and homeostasis_tier_reached < 3:
		omega_min_peak = max(omega_min_peak, StructuralModel.omega_min)
		var delta_real :float = EconomyManager.get_contribution_breakdown().total
		# CICATRIZ METABÓLICA (Banco Cósmico T2): reduce el tiempo mínimo a la mitad
		var homeorhesis_min_time: float = Balance.HOMEORHESIS_MIN_RUN_TIME
		if LegacyManager.has_cosmic_buff("cicatriz_metabolica"):
			homeorhesis_min_time *= 0.5
		var ok = extreme_shocks_recovered >= 1 and resilience_score >= 400.0 \
			and omega_min_peak >= 0.50 and disturbances_survived >= 5 \
			and delta_real > 300.0 and run_time >= homeorhesis_min_time
		if ok:
			homeostasis_tier_reached = 3
			if not LegacyManager.get_buff_value("legado_homeorresis"):
				LegacyManager.grant_buff("legado_homeorresis")
			LogManager.add(tr("LOG_TIER3_HOMEORHESIS"))
			UIManager.show_toast(tr("TOAST_HOMEORHESIS"))

	# Mostrar el botón del tier más alto alcanzado
	if homeostasis_tier_reached == 3:
		_show_evolution_button("HOMEORHESIS")
	elif homeostasis_tier_reached == 2:
		_show_evolution_button("ALLOSTASIS")
	elif homeostasis_tier_reached == 1:
		_show_evolution_button("HOMEOSTASIS")

func check_allostasis_final(_delta: float):
	pass # Integrado en check_homeostasis_final como tiers progresivos

func check_homeorhesis_final(_delta: float):
	pass # Integrado en check_homeostasis_final como tiers progresivos

func check_symbiosis_final(_delta: float):
	if carnaval_active or run_closed or not EvoManager.mutation_symbiosis:
		return

	var stable_band: bool = (
		StructuralModel.epsilon_effective >= 0.12
		and StructuralModel.epsilon_effective <= 0.55
		and StructuralModel.omega > 0.30
		and UpgradeManager.level("accounting") >= 1
	)

	# Auto-cierre: 5 minutos en banda estable (antes 15 min)
	if stable_band and run_time > 300.0:
		close_run("SIMBIOSIS", tr("CLOSE_SIMBIOSIS_SOSTENIDA"))
		return

	# Cierre de emergencia: si omega > 0.50 (rama Simbiosis Mecánica activa) por 60s
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS \
		and StructuralModel.omega >= 0.50 \
		and run_time > 60.0:
		close_run("SIMBIOSIS", tr("CLOSE_SIMBIOSIS_MECANICA"))

func is_fractura_epistemica_available() -> bool:
	# Rework v1.0.0.10 (profundidad): requiere HIPER ya mutada (solo posible en gate Depredador),
	# ε > 0.90, run > 4min y biomasa mínima. Debe sostenerse 20s para disparar.
	return not carnaval_active and not run_closed \
		and LegacyManager.has_cosmic_buff("fractura_epistemica") \
		and EvoManager.mutation_hyperassimilation \
		and StructuralModel.epsilon_runtime > 0.90 \
		and run_time > 240.0 \
		and BiosphereEngine.biomasa > 5.0

func check_fractura_epistemica(dt: float):
	# FRACTURA EPISTÉMICA (Banco Cósmico T3): cierra como COLAPSO CONTROLADO.
	# Requiere HIPER activa + ε > 0.90 sostenido durante FRACTURA_CARGA_DURATION segundos.
	# El reactor lerp Rojo→Dorado mientras carga (ver EvoManager.get_reactor_color).
	if not is_fractura_epistemica_available():
		# Solo decaer mientras la run está activa; si ya cerró (COLAPSO CONTROLADO),
		# el timer queda congelado para que el reactor permanezca dorado en el endscreen.
		if not run_closed:
			_fractura_carga_timer = max(0.0, _fractura_carga_timer - dt * 2.0)
		return

	var prev := _fractura_carga_timer
	_fractura_carga_timer += dt

	# Toast de alerta al alcanzar el 50% de carga
	var half := FRACTURA_CARGA_DURATION * 0.5
	if prev < half and _fractura_carga_timer >= half:
		UIManager.show_toast(tr("FRACTURA_CHARGING_50"))

	if _fractura_carga_timer >= FRACTURA_CARGA_DURATION:
		close_run("COLAPSO CONTROLADO", tr("CLOSE_COLAPSO_CONTROLADO"))

func check_parasitism_final(_delta: float):
	if carnaval_active or run_closed or not EvoManager.mutation_parasitism:
		return

	# Opción A: Colapso estructural clásico
	if BiosphereEngine.biomasa > 18.0 and StructuralModel.omega < 0.22 and StructuralModel.epsilon_effective > 0.45:
		close_run("PARASITISMO", tr("CLOSE_PARASITISMO_DRENA"))
		return

	# Opción B: Bancarrota — el hongo drenó toda la liquidez
	if BiosphereEngine.biomasa >= 15.0 and EconomyManager.money < 1000.0:
		close_run("PARASITISMO", tr("CLOSE_PARASITISMO_BANCARROTA"))
		return

	# Opción C: Masa crítica — crecimiento descontrolado
	if BiosphereEngine.biomasa >= 25.0:
		close_run("PARASITISMO", tr("CLOSE_PARASITISMO_MASA"))

func check_sporulation_trigger(_delta: float):
	if carnaval_active or run_closed or EvoManager.mutation_sporulation:
		return

	if not EvoManager.mutation_red_micelial or EvoManager.red_micelial_phase != 2:
		return
	if EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation:
		return

	var _structural_pressure: float = StructuralModel.get_structural_pressure()

	if (
		StructuralModel.epsilon_peak >= 0.75
		and StructuralModel.epsilon_effective <= 0.35
		and StructuralModel.omega <= 0.30
		and BiosphereEngine.biomasa >= 10.0
		and BiosphereEngine.hifas >= 12.0
		and run_time >= 900.0
	):
		EvoManager.activate_mutation("esporulacion")

# ==================== HOMEOSTASIS DINÁMICA ====================
func update_homeostasis_mode(delta: float):
	var n_struct: float = StructuralModel.get_effective_structural_n()
	var complexity_impact: float = n_struct / max(EconomyManager.cached_mu, 1.0)
	StructuralModel.omega = 1.0 / max(1.0 + StructuralModel.epsilon_effective * complexity_impact, 0.0001)
	var stability: float = clamp(1.0 - StructuralModel.epsilon_effective, 0.0, 1.0)
	resilience_score += stability * delta

	# Pausar perturbaciones cuando el jugador evolucionó a Red Micelial o Simbiosis:
	# ya superó la fase homeostática, las perturbaciones dejan de tener sentido
	var en_mutacion_avanzada = EvoManager.mutation_red_micelial or EvoManager.mutation_symbiosis \
		or EvoManager.mutation_hyperassimilation or EvoManager.mutation_parasitism
	if not EvoManager.primordio_active and not en_mutacion_avanzada:
		disturbance_timer += delta
		if disturbance_timer >= DISTURBANCE_INTERVAL:
			disturbance_timer = 0.0
			trigger_disturbance()

	# UMBRAL ADAPTATIVO (Banco Genético): recuperación más rápida tras perturbaciones
	var eps_lerp_factor := 0.05
	if is_recovering_from_shock:
		var recovery_boost := LegacyManager.get_effect_value("disturbance_recovery_speed")
		if recovery_boost > 0.0:
			eps_lerp_factor *= recovery_boost

	StructuralModel.epsilon_runtime = lerp(
		StructuralModel.epsilon_runtime,
		StructuralModel.epsilon_effective,
		eps_lerp_factor * delta
	)

	# EQUILIBRIO HEREDADO / SETPOINT ADAPTATIVO: regeneración lenta de Ω_min tras shocks
	var omega_recovery_mult := LegacyManager.get_effect_value("omega_recovery_speed")
	if omega_recovery_mult > 0.0:
		var regen := 0.0015 * delta * omega_recovery_mult
		# Cap dinámico: no superar el omega actual (el movimiento natural lo limita arriba)
		StructuralModel.omega_min = min(StructuralModel.omega_min + regen, StructuralModel.omega)

func trigger_disturbance():
	var shock := randf_range(0.1, 0.4)
	var is_extreme := false
	# Shock extremo disponible una vez alcanzado Tier 2 (ALLOSTASIS) en la run actual
	if homeostasis_tier_reached >= 2 and randf() < 0.2:
		shock = randf_range(0.8, 1.0)
		is_extreme = true
		LogManager.add(tr("LOG_SHOCK_EXTREME") % str(snapped(shock, 0.01)))
	else:
		LogManager.add(tr("LOG_SHOCK_NORMAL") % str(snapped(shock, 0.01)))

	StructuralModel.epsilon_runtime += shock
	_shock_peak_epsilon = StructuralModel.epsilon_runtime  # pico real para logro presion_adaptativa
	is_recovering_from_shock = true
	if is_extreme:
		is_recovering_from_extreme = true
	disturbances_without_reset += 1
	AchievementManager.on_disturbance_streak(disturbances_without_reset)

	# Shocks extremos tienen consecuencias: drenan omega_min y dinero
	if is_extreme:
		var penalty_omega := 0.15 if not LegacyManager.get_buff_value("legado_homeorresis") else 0.05
		# CRISTALIZACIÓN PERMANENTE (Banco Genético): reduce la penalización de Ω -50%
		if LegacyManager.get_buff_value("cristalizacion_permanente"):
			penalty_omega *= (1.0 - LegacyManager.get_effect_value("omega_shock_reduction"))
		StructuralModel.omega_min = max(0.0, StructuralModel.omega_min - penalty_omega)
		var money_drain := EconomyManager.money * 0.20
		EconomyManager.money = max(0.0, EconomyManager.money - money_drain)
		LogManager.add(tr("LOG_SHOCK_DRAIN") % [snapped(penalty_omega, 0.01), money_drain])

	disturbance_triggered.emit(shock, is_extreme)

# ==================== SHOCK TRACKING ====================
# Llamado cada tick desde main.gd (_on_logic_tick).
# Detecta spike extremo (epsilon_runtime > 0.8) y recovery al volver a banda homeostática.
func check_shock_tracking():
	if is_recovering_from_shock and get_en_banda_homeostatica():
		disturbances_survived += 1
		is_recovering_from_shock = false
		if is_recovering_from_extreme:
			is_recovering_from_extreme = false
			extreme_shocks_recovered += 1
			LogManager.add(tr("LOG_SHOCK_ABSORBED") % extreme_shocks_recovered)
		else:
			LogManager.add(tr("LOG_SHOCK_STABILIZED") % disturbances_survived)
		AchievementManager.on_disturbance_survived(_shock_peak_epsilon)

		# LEGADO ALOSTASIS: Ω_min crece +0.02 por shock estabilizado (cap 0.70)
		if LegacyManager.get_buff_value("legado_alostasis"):
			StructuralModel.omega_min = min(StructuralModel.omega_min + 0.02, 0.70)
			LogManager.add(tr("LOG_NG_ALOSTASIS") % StructuralModel.omega_min)

		# EQUILIBRIO HEREDADO: +0.04 Ω_min en burst por shock estabilizado (cap 0.70)
		var eq_bonus: float = LegacyManager.get_effect_value("omega_min_per_disturbance")
		if eq_bonus > 0.0:
			StructuralModel.omega_min = min(StructuralModel.omega_min + eq_bonus, 0.70)
			LogManager.add(tr("LOG_NG_EQ_HEREDADO") % [eq_bonus, StructuralModel.omega_min])

func check_perfect_homeostasis():
	if not post_homeostasis or AchievementManager.is_unlocked("homeostasis_perfecta"):
		return

	if resilience_score >= 300.0:
		# El unlock dispara el toast y el add_lap automáticamente vía AchievementManager
		AchievementManager.unlock("homeostasis_perfecta")
		legacy_homeostasis = true
		post_homeostasis = false

# ==================== POST-TRASCENDENCIA: ACTIVACIÓN ====================

## Llamado desde main.gd en _ready(), después de que los sistemas están inicializados
func activate_post_tras_route() -> void:
	var route := LegacyManager.post_tras_route
	if route == "":
		return

	match route:
		"vacio":
			_activate_vacio_hambriento()
		"carnaval":
			_activate_carnaval()
		"reencarnacion":
			_activate_reencarnacion()

	# La ruta se consume: se borra para no re-aplicarla en reinicios sin trascendencia
	LegacyManager.post_tras_route = ""
	LegacyManager.save_legacy()

func _activate_vacio_hambriento() -> void:
	AchievementManager.push_event("post_tras_route", {"route": "vacio"})
	# Contar y consumir todos los buffs cósmicos activos
	var consumed := 0
	for id in LegacyManager.cosmic_unlocked.keys():
		if LegacyManager.cosmic_unlocked[id]:
			LegacyManager.cosmic_unlocked[id] = false
			consumed += 1

	vacio_hambriento_active = true
	vacio_hambriento_mult = Balance.VACIO_HAMBRIENTO_MULT
	LegacyManager.save_legacy()
	print("🕳️ [VACÍO HAMBRIENTO] %d buffs cósmicos consumidos → ×%.0f producción" % [consumed, vacio_hambriento_mult])
	LogManager.add(tr("LOG_VACIO") % consumed)

func _activate_carnaval() -> void:
	AchievementManager.push_event("post_tras_route", {"route": "carnaval"})
	# Seleccionar 3 mutaciones aleatorias sin repetición del pool
	var pool := CARNAVAL_POOL.duplicate()
	pool.shuffle()
	carnaval_mutations = pool.slice(0, 3)
	carnaval_index = 0
	carnaval_timer = 0.0
	carnaval_total_rotations = 0
	carnaval_peak_money = 0.0
	carnaval_active = true
	# Aplicar la primera inmediatamente
	EvoManager.carnaval_set_mutation(carnaval_mutations[0])
	print("🎭 [CARNAVAL] Mutaciones: %s" % str(carnaval_mutations))
	LogManager.add(tr("LOG_CARNAVAL_START") % [carnaval_mutations[0], carnaval_mutations[1], carnaval_mutations[2]])

func _activate_reencarnacion() -> void:
	AchievementManager.push_event("post_tras_route", {"route": "reencarnacion"})
	reencarnacion_active = true
	UpgradeManager.apply_reencarnacion_snapshot(LegacyManager.reencarnacion_snapshot)
	print("⚱️ [REENCARNACIÓN] Snapshot aplicado")
	LogManager.add(tr("LOG_REENCARNACION"))

## Tick del Carnaval: rotar mutación cada Balance.CARNAVAL_INTERVAL segundos
func update_carnaval(delta: float) -> void:
	if run_closed or not carnaval_active or carnaval_mutations.is_empty():
		return
	carnaval_timer += delta

	# Actualizar pico de dinero alcanzado en carnaval
	carnaval_peak_money = max(carnaval_peak_money, EconomyManager.money)

	if carnaval_timer >= Balance.CARNAVAL_INTERVAL:
		carnaval_timer = 0.0
		carnaval_index = (carnaval_index + 1) % carnaval_mutations.size()
		carnaval_total_rotations += 1
		var next_mut :String= carnaval_mutations[carnaval_index]
		EvoManager.carnaval_set_mutation(next_mut)
		LogManager.add(tr("LOG_CARNAVAL_ROT") % [carnaval_total_rotations, next_mut])

		# CHEQUEO: POLIMORFÍA TOTAL
		if carnaval_total_rotations >= 12:
			var biomasa := BiosphereEngine.biomasa
			var omega := StructuralModel.omega
			var dinero := EconomyManager.money
			if biomasa >= 8.0 and omega >= 0.35 and dinero >= 300000.0:
				close_run("POLIMORFÍA TOTAL", tr("CLOSE_POLIMORFIA") % [biomasa, omega, dinero/1000.0])
				return

		# CHEQUEO: DOMADOR DEL CAOS
		if carnaval_total_rotations >= 3 and carnaval_peak_money >= 1000000.0:
			close_run("DOMADOR DEL CAOS", tr("CLOSE_DOMADOR_CAOS") % [carnaval_peak_money / 1000000.0])
			return

# ==================== ASCESIS PROFUNDA (sub-ruta VACÍO HAMBRIENTO) ====================
func check_ascesis_profunda(delta: float) -> void:
	if run_closed:
		return
	# Requisitos previos: run madura y dinero generado suficiente (clicks, no pasivo)
	if run_time < 900.0 or EconomyManager.money < 1000000.0:
		ascesis_timer = 0.0
		return
	# Condiciones simultáneas: sin biósfera, sin pasivo comprado, sistema calmo
	var biomasa_ok := BiosphereEngine.biomasa < 0.5
	var sin_pasivo := UpgradeManager.level("auto") == 0 and UpgradeManager.level("trueque") == 0
	var epsilon_ok := StructuralModel.epsilon_runtime < 0.25
	if biomasa_ok and sin_pasivo and epsilon_ok:
		ascesis_timer += delta
		if ascesis_timer >= Balance.ASCESIS_DURATION:
			close_run("ASCESIS_PROFUNDA", tr("CLOSE_ASCESIS"))
	# Si fallan las condiciones el timer se pausa (no se resetea)

# ==================== UI EVOLUCIÓN ====================
func _show_evolution_button(target: String):
	if target_evolution == target:
		return
	target_evolution = target

	if not is_instance_valid(evolution_button):
		evolution_button = Button.new()
		evolution_button.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		evolution_button.custom_minimum_size = Vector2(0, 80)
		evolution_button.pressed.connect(_on_evolution_button_pressed)
		# Icono Twemoji (🧬) — vía Button.icon en lugar del char emoji para que
		# se renderice también en web export (donde el font default no incluye emojis).
		var dna_path := "res://emoji/1f9ec.png"
		if ResourceLoader.exists(dna_path):
			evolution_button.icon = load(dna_path)
			evolution_button.expand_icon = false
		UIManager.root.get_node("RightPanel").add_child(evolution_button)
		UIManager.root.get_node("RightPanel").move_child(evolution_button, 0)

	evolution_button.text = "SELLAR FINAL (" + target + ")"
	match target:
		"HOMEOSTASIS":
			evolution_button.add_theme_color_override("font_color", Color.CYAN)
		"ALLOSTASIS":
			evolution_button.add_theme_color_override("font_color", Color.AQUAMARINE)
		"HOMEORHESIS":
			evolution_button.add_theme_color_override("font_color", Color.GOLD)
	evolution_button.visible = true

func _on_evolution_button_pressed():
	match target_evolution:
		"HOMEOSTASIS":
			close_run("HOMEOSTASIS", tr("CLOSE_HOMEOSTASIS"))
		"ALLOSTASIS":
			UIManager.big_click_button.modulate = Color(0.2, 0.9, 1.0)
			close_run("ALLOSTASIS", tr("CLOSE_ALLOSTASIS"))
		"HOMEORHESIS":
			UIManager.big_click_button.modulate = Color(1.0, 0.8, 0.2)
			close_run("HOMEORHESIS", tr("CLOSE_HOMEORHESIS"))
	evolution_button.visible = false

# =====================================================
#  HOMEOSTASIS — candidato helper (extraído de main.gd)
# =====================================================
func is_homeostasis_candidate() -> bool:
	var banda_estricta := get_en_banda_homeostatica()
	var flexibilidad_minima := StructuralModel.omega > 0.25
	var control_activo := UpgradeManager.level("accounting") >= 1
	var metabolismo_activo := EconomyManager.delta_per_sec > 30.0
	var crecimiento_controlado := BiosphereEngine.biomasa < 12.0
	var redundancia := StructuralModel.unlocked_d and StructuralModel.unlocked_e
	var no_hyper := not EvoManager.mutation_hyperassimilation
	var red_blocks_homeostasis := EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2
	return banda_estricta and flexibilidad_minima and control_activo and metabolismo_activo and crecimiento_controlado and redundancia and no_hyper and not red_blocks_homeostasis

# =====================================================
#  NG+ MENTE COLMENA — lógica de activación y auto-buy
# =====================================================

func activate_mente_colmena() -> void:
	mente_colmena_active = true
	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.disabled = true
		UIManager.big_click_button.modulate = Color(0.1, 0.8, 1.0)
	if not LegacyManager.get_buff_value("mente_colmena"):
		LegacyManager.grant_buff("mente_colmena")
		UIManager.show_toast(tr("TOAST_MC_UNLOCKED"))
	close_run("MENTE COLMENA DISTRIBUIDA", tr("CLOSE_MENTE_COLMENA"))

func tick_auto_buy(dt: float) -> void:
	_mente_colmena_buy_timer += dt
	if _mente_colmena_buy_timer < Balance.MENTE_COLMENA_BUY_INTERVAL:
		return
	_mente_colmena_buy_timer = 0.0
	_mente_colmena_auto_buy()

func _mente_colmena_auto_buy() -> void:
	if run_closed:
		return
	var bought_id: String = ""
	var bought_cost: float = 0.0

	for id in MENTE_COLMENA_BUY_PRIORITY:
		if not UpgradeManager.can_buy(id, EconomyManager.money):
			continue
		var c := UpgradeManager.cost(id)
		if UpgradeManager.buy(id, EconomyManager.money):
			EconomyManager.money -= c
			bought_id = id
			bought_cost = c
			UpgradeManager.apply_bought_effects(id)
			break

	if bought_id == "":
		var best_id := ""
		var best_cost := INF
		for id in UpgradeManager.states.keys():
			var c := UpgradeManager.cost(id)
			if c > 0.0 and c < best_cost and UpgradeManager.can_buy(id, EconomyManager.money):
				best_cost = c
				best_id = id
		if best_id != "":
			if UpgradeManager.buy(best_id, EconomyManager.money):
				EconomyManager.money -= best_cost
				bought_id = best_id
				bought_cost = best_cost
				UpgradeManager.apply_bought_effects(best_id)

	if bought_id != "":
		var def := UpgradeManager.get_def(bought_id)
		var label_str := def.label if def else bought_id
		LogManager.add(tr("LOG_AI_BOUGHT") % [label_str, bought_cost])
		UIManager.show_toast(tr("TOAST_AI_BOUGHT") % label_str)
