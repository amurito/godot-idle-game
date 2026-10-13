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

# NG+ CAP — notificación una sola vez por run cuando el bonus variable satura el cap
var _ng_cap_notified: bool = false

var evolution_button: Button = null
var target_evolution: String = ""

# NG+ MENTE COLMENA — runtime state + auto-buy
var mente_colmena_active: bool = false   # true sólo DURANTE una ráfaga activable (no permanente)
var mente_colmena_timer: float = 0.0     # progreso del gate de sincronía
var _mente_colmena_buy_timer: float = 0.0
var mc_burst_timer: float = 0.0          # s restantes de la ráfaga de IA en curso
var mc_cooldown_timer: float = 0.0       # s restantes de cooldown tras una ráfaga
const MENTE_COLMENA_BUY_PRIORITY: Array = [
	"accounting", "trueque", "auto", "trueque_net", "auto_mult",
	"cognitive", "persistence", "specialization", "click_mult", "click",
]

# ==================== POST-TRASCENDENCIA ====================
# Estado de rutas movido a RouteManager + clases routes/Route*.gd (Opción B)
# Estos getters de compatibilidad permiten que saves/código externo viejo no explote
# durante el período de migración; los nuevos consumers deben usar RouteManager directamente.

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
	RouteManager.reset()
	mente_colmena_active = false
	mente_colmena_timer = 0.0
	_mente_colmena_buy_timer = 0.0
	mc_burst_timer = 0.0
	mc_cooldown_timer = 0.0
	_fractura_carga_timer = 0.0
	_ng_cap_notified = false

# ==================== HELPERS ====================
func get_en_banda_homeostatica() -> bool:
	return StructuralModel.epsilon_runtime >= 0.03 and StructuralModel.epsilon_runtime <= 0.30

## true si el jugador posee el legado permanente Semilla Cósmica Oscura
## (Memoria Oscura siempre activa, no consumible).
func _has_permanent_dark_legacy() -> bool:
	return LegacyManager.get_buff_value("semilla_cosmica_oscura")

## true si el buff "Memoria Oscura" está activo esta run.
## SEMILLA DURMIENTE: mientras haya cargas (dark_legacy_charges > 0) la Memoria Oscura está
## activa en TODAS las runs, hasta germinar en Panspermia o borrarse al trascender.
## El legado permanente (semilla_cosmica_oscura) la mantiene activa sin consumir cargas.
func is_memoria_oscura_active() -> bool:
	return LegacyManager.dark_legacy_charges > 0 or _has_permanent_dark_legacy()

# ==================== CIERRE DE RUN ====================
func close_run(route: String, reason: String, skip_ng_bonus: bool = false):
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
	var pl_to_add: int = int(Balance.PL_REWARDS.get(route, 0))
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
	# skip_ng_bonus: el cierre MANUAL de AUTOFAGIA (colapso voluntario) no otorga este bonus —
	# se reserva para el cierre natural (agotamiento de material).
	if LegacyManager.trascendencia_count >= 1 and not skip_ng_bonus:
		var ng_bonus := 0
		var ng_formula := ""
		var cap: int = int(Balance.NG_CAPS.get(route, 0))
		var rule: Dictionary = ng_bonus_rule(route)
		if not rule.is_empty():
			var value: Variant = (rule.value as Callable).call()
			ng_bonus = mini(_ng_raw(rule, value), cap)
			var shown: Variant = (rule.show as Callable).call(value) if rule.has("show") else value
			ng_formula = str(rule.log).format({"v": str(rule.vfmt) % shown, "b": ng_bonus, "c": cap})
		if ng_bonus > 0:
			LegacyManager.add_pl(ng_bonus)
			_total_pl += ng_bonus
			LogManager.add(tr("LOG_PL_NG") % [ng_bonus, ng_formula])

	LegacyManager.record_run_end(route, reason, run_time, EconomyManager.cached_mu, StructuralModel.epsilon_peak, _total_pl)

	# ── ESCLEROCIO OSCURO ──────────────────────────────────────────
	# Al cerrar por ESCLEROCIO, sembrar una semilla durmiente de Memoria Oscura.
	# Las cargas mantienen la Memoria Oscura activa en TODAS las runs siguientes
	# (semilla durmiente) hasta que germinan en Panspermia o se borran al trascender.
	if route == "ESCLEROCIO OSCURO":
		LegacyManager.dark_legacy_charges += 1
		LogManager.add(tr("LOG_ESCLEROCIO_SEMBRADO"))
	# Cruce con PANSPERMIA NEGRA: si hay una semilla durmiente activa, germina → desbloquea
	# el legado permanente y consume una carga.
	if route == "PANSPERMIA NEGRA" and LegacyManager.dark_legacy_charges > 0:
		LegacyManager.dark_legacy_charges -= 1
		if not LegacyManager.esclerocio_panspermia_done:
			LegacyManager.esclerocio_panspermia_done = true
			LogManager.add(tr("LOG_SEMILLA_OSCURA_UNLOCK"))
			UIManager.show_toast(tr("TOAST_SEMILLA_OSCURA"))

	# AUTOFAGIA NECRÓTICA: primera vez que cierra → desbloquear Catabolismo Heredado.
	if route == "AUTOFAGIA NECRÓTICA":
		if not LegacyManager.get_buff_value("catabolismo_heredado"):
			LegacyManager.grant_buff("catabolismo_heredado")
			UIManager.show_toast(tr("TOAST_CATABOLISMO_UNLOCKED"))
			LogManager.add(tr("LOG_CATABOLISMO_UNLOCKED"))

	# DEPREDADOR DE REALIDADES + AUTOFAGIA NECRÓTICA previa → cross Ciclo Catabólico.
	# Orden requerido: primero cerrar AUTOFAGIA, luego DEPREDADOR.
	if route == "DEPREDADOR DE REALIDADES" \
			and LegacyManager.endings_achieved.get("AUTOFAGIA NECRÓTICA", false) \
			and not LegacyManager.autofagia_depredador_done:
		LegacyManager.autofagia_depredador_done = true
		LogManager.add(tr("LOG_CICLO_CATABOLICO_UNLOCK"))
		UIManager.show_toast(tr("TOAST_CICLO_CATABOLICO_UNLOCK"))

	# FUSIÓN CATABÓLICA: recompensa OP permanente al sellar → +25% a todo el ingreso (Motor Fundido).
	if route == "FUSIÓN CATABÓLICA":
		if not LegacyManager.get_buff_value("legado_motor_fundido"):
			LegacyManager.grant_buff("legado_motor_fundido")
			UIManager.show_toast(tr("TOAST_FUSION_REWARD"))
			LogManager.add(tr("LOG_FUSION_REWARD"))

	# CAOS ORQUESTADO: legado Batuta (ε → 0 una vez por run, en cualquier run).
	if route == "CAOS ORQUESTADO":
		if not LegacyManager.get_buff_value("legado_batuta"):
			LegacyManager.grant_buff("legado_batuta")
			UIManager.show_toast(tr("TOAST_CAOS_REWARD"))
			LogManager.add(tr("LOG_CAOS_REWARD"))

	# CORO SIMBIÓTICO: legado Eco del Coro (ritmo suave en todas las runs).
	if route == "CORO SIMBIÓTICO":
		if not LegacyManager.get_buff_value("legado_eco_del_coro"):
			LegacyManager.grant_buff("legado_eco_del_coro")
			UIManager.show_toast(tr("TOAST_CORO_REWARD"))
			LogManager.add(tr("LOG_CORO_REWARD"))

	# MICELIO OMNISCIENTE: legado Nodo Latente (el primer nodo que llenaste queda conectado).
	if route == "MICELIO OMNISCIENTE":
		var node_id: String = EvoManager.micelio_first_full
		if node_id == "":
			node_id = "auto"
		LegacyManager.nodo_latente_id = node_id
		if not LegacyManager.get_buff_value("legado_nodo_latente"):
			LegacyManager.grant_buff("legado_nodo_latente")
			UIManager.show_toast(tr("TOAST_MICELIO_REWARD"))
		LogManager.add(tr("LOG_MICELIO_REWARD") % tr("UPG_" + node_id.to_upper()))

	# AYUNO PRIMORDIAL: recompensa permanente al sellar → pasivo ×2→×1 en los primeros 90 s de run.
	if route == "AYUNO PRIMORDIAL":
		if not LegacyManager.get_buff_value("legado_primicia_del_vacio"):
			LegacyManager.grant_buff("legado_primicia_del_vacio")
			UIManager.show_toast(tr("TOAST_AYUNO_REWARD"))
			LogManager.add(tr("LOG_AYUNO_REWARD"))

	# NECROSIS CONTROLADA: primera vez que cierra → desbloquear Apoptosis Heredada.
	if route == "NECROSIS CONTROLADA":
		if not LegacyManager.get_buff_value("apoptosis_heredada"):
			LegacyManager.grant_buff("apoptosis_heredada")
			UIManager.show_toast(tr("TOAST_APOPTOSIS_UNLOCKED"))
			LogManager.add(tr("LOG_APOPTOSIS_UNLOCKED"))
		# Cross HOMEORHESIS → NECROSIS: dominio de ambos extremos de Ω.
		# Orden requerido: HOMEORHESIS completada alguna vez, luego cerrar NECROSIS.
		if LegacyManager.endings_achieved.get("HOMEORHESIS", false) \
				and not LegacyManager.homeorhesis_necrosis_done:
			LegacyManager.homeorhesis_necrosis_done = true
			LogManager.add(tr("LOG_PLASTICIDAD_TERMINAL_UNLOCK"))
			UIManager.show_toast(tr("TOAST_PLASTICIDAD_TERMINAL_UNLOCK"))

	# PROTOCOLO OMEGA-CERO: registrar el Núcleo Φ (intensidad de Memoria Sináptica) +
	# otorgar el buff gratis la 1ª vez + resolver el cruce con REMISIÓN METABÓLICA.
	if route == "PROTOCOLO OMEGA-CERO":
		LegacyManager.record_omega_cero_kernel(EvoManager.omega_cero_kernel)
		if not LegacyManager.get_buff_value("memoria_sinaptica"):
			LegacyManager.grant_buff("memoria_sinaptica")
			UIManager.show_toast(tr("TOAST_MEMORIA_SINAPTICA_UNLOCKED"))
			LogManager.add(tr("LOG_MEMORIA_SINAPTICA_UNLOCKED"))
		# Cross OMEGA-CERO ↔ REMISIÓN METABÓLICA (cualquier orden): colapso = crecimiento.
		if LegacyManager.endings_achieved.get("REMISIÓN METABÓLICA", false) \
				and not LegacyManager.omega_remision_done:
			LegacyManager.omega_remision_done = true
			LogManager.add(tr("LOG_SINTESIS_VITAL_UNLOCK"))
			UIManager.show_toast(tr("TOAST_SINTESIS_VITAL_UNLOCK"))

	# REMISIÓN METABÓLICA: otorgar el buff "Control de Ω" gratis la 1ª vez +
	# resolver el cruce con PROTOCOLO OMEGA-CERO (lado simétrico).
	if route == "REMISIÓN METABÓLICA":
		var _ctrl_nuevo: bool = not LegacyManager.get_buff_value("control_omega")
		if _ctrl_nuevo:
			LegacyManager.grant_buff("control_omega")
			LogManager.add(tr("LOG_CONTROL_OMEGA_UNLOCKED"))
		# Cross OMEGA-CERO ↔ REMISIÓN METABÓLICA (cualquier orden): colapso = crecimiento.
		var _cross_nuevo: bool = false
		if LegacyManager.endings_achieved.get("PROTOCOLO OMEGA-CERO", false) \
				and not LegacyManager.omega_remision_done:
			LegacyManager.omega_remision_done = true
			LogManager.add(tr("LOG_SINTESIS_VITAL_UNLOCK"))
			_cross_nuevo = true
		# Toast consolidado: un solo mensaje con todo lo desbloqueado esta run
		if _ctrl_nuevo or _cross_nuevo:
			var _toast_key: String = "TOAST_REMISION_BANCO_CROSS" if _cross_nuevo else "TOAST_REMISION_BANCO_SOLO"
			UIManager.show_toast(tr(_toast_key))

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
	if not RouteManager.allows_bifurcation() or run_closed or not EvoManager.mutation_homeostasis:
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
	if not RouteManager.allows_bifurcation() or run_closed or not EvoManager.mutation_symbiosis:
		return
	# Con la llave de Coro Simbiótico, el pacto espera la decisión: no cierra mientras el botón
	# de reversión [T] tenga apariciones pendientes (si no, Simbiosis podía cerrar antes del botón).
	if TransmutationLogic.candidate() == "coro" and TransmutationLogic.appearances_left() > 0:
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
	return RouteManager.allows_bifurcation() and not run_closed \
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
	if not RouteManager.allows_bifurcation() or run_closed or not EvoManager.mutation_parasitism:
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
		return

	# Opción D: La Trampa del Vacío — el parásito entró durante AYUNO PRIMORDIAL (romper el ayuno
	# tras >120 s sin clickear). El drain de Ayuno mantiene la biomasa en ~0, así que A/B/C nunca
	# se cumplirían y la run quedaba en limbo con ambas mutaciones activas: el parásito devora el
	# ayuno y cierra la run (desbloquea el logro trampa_del_vacio en on_run_closed).
	if EvoManager.mutation_ayuno_primordial:
		close_run("PARASITISMO", tr("CLOSE_PARASITISMO_AYUNO"))

## Botón de final de la rama verde (Red Micelial). Antes vivía en main._on_sporulation_final_pressed().
##   · Núcleo de conciencia → SINGULARIDAD: PL = 6 + bonus por estabilidad (ε bajo, hasta +5)
##   · Seta + ventana de Panspermia → un pulso de eyección; si alcanza la velocidad de escape,
##     PANSPERMIA NEGRA (+ Semilla Cósmica la primera vez)
##   · Seta → ESPORULACIÓN (las esporas pasan al banco)
## Devuelve true si la run sigue abierta y la UI debe refrescarse (pulso sin lanzamiento).
func resolve_sporulation_final() -> bool:
	if run_closed:
		return false
	if EvoManager.nucleo_conciencia:
		var bonus_efficiency: float = clamp(1.0 - StructuralModel.epsilon_runtime, 0.0, 1.0) * 5.0
		var pl := 6 + int(bonus_efficiency)
		LegacyManager.add_pl(pl)
		LogManager.add(tr("LOG_PL_SINGULARIDAD") % [pl, pl - 6])  # 6 base + bonus por estabilidad ε
		UIManager.show_toast(tr("TOAST_SINGULARIDAD_PL") % pl)
		close_run("SINGULARIDAD", tr("CLOSE_SINGULARIDAD"))
	elif EvoManager.seta_formada and EvoManager.is_panspermia_window():
		if not EvoManager.panspermia_pulse():
			return true
		# Velocidad de escape alcanzada → lanzamiento exitoso.
		if not LegacyManager.get_buff_value("semilla_cosmica"):
			LegacyManager.grant_buff("semilla_cosmica")
			UIManager.show_toast(tr("TOAST_SEMILLA_COSMICA"))
		# El PL (+10) lo otorga close_run vía Balance.PL_REWARDS.
		close_run("PANSPERMIA NEGRA", tr("CLOSE_PANSPERMIA"))
	elif EvoManager.seta_formada:
		var esporas := BiosphereEngine.trigger_sporulation()
		if esporas > 1.0:
			LegacyManager.add_spores(esporas)
		close_run("ESPORULACIÓN", tr("CLOSE_ESPORULACION"))
	return false

func check_sporulation_trigger(_delta: float):
	if not RouteManager.allows_bifurcation() or run_closed or EvoManager.mutation_sporulation:
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
	var en_mutacion_avanzada = EvoManager.mutation_red_micelial or EvoManager.mutation_micelio_omnisciente or EvoManager.mutation_symbiosis \
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

## Llamado desde main.gd en _ready(), después de que los sistemas están inicializados.
## Delega a RouteManager que instancia la clase concreta de la ruta.
func activate_post_tras_route() -> void:
	var route: String = LegacyManager.post_tras_route
	if route == "":
		return
	RouteManager.activate(route)
	# La ruta se consume: se borra para no re-aplicarla en reinicios sin trascendencia
	LegacyManager.post_tras_route = ""
	LegacyManager.save_legacy()

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
	# Sincronización lograda: otorga el legado (ráfaga activable + pasivo ×3) y cierra la run.
	# Ya NO deja auto-play permanente: en runs futuras la IA es una ráfaga que disparás.
	if not LegacyManager.get_buff_value("mente_colmena"):
		LegacyManager.grant_buff("mente_colmena")
		UIManager.show_toast(tr("TOAST_MC_UNLOCKED"))
	# La singularidad puntual se DISTRIBUYE en la colmena: el núcleo deja de ser un final propio.
	EvoManager.nucleo_conciencia = false
	close_run("MENTE COLMENA DISTRIBUIDA", tr("CLOSE_MENTE_COLMENA"))

## Dispara una RÁFAGA de auto-play (si el legado está desbloqueado y no hay cooldown).
func activate_mc_burst() -> void:
	if run_closed or not LegacyManager.get_buff_value("mente_colmena"):
		return
	if mc_burst_timer > 0.0 or mc_cooldown_timer > 0.0:
		return
	mc_burst_timer = Balance.MC_BURST_DURATION
	mente_colmena_active = true
	_mente_colmena_buy_timer = 0.0
	UIManager.show_toast(tr("TOAST_MC_BURST_ON"))

## Avanza la ráfaga / cooldown (llamado desde el logic tick).
func tick_mc_burst(dt: float) -> void:
	if mc_burst_timer > 0.0:
		mc_burst_timer -= dt
		if mc_burst_timer <= 0.0:
			mc_burst_timer = 0.0
			mente_colmena_active = false
			mc_cooldown_timer = Balance.MC_BURST_COOLDOWN
			if is_instance_valid(UIManager.big_click_button):
				UIManager.big_click_button.disabled = false
			UIManager.show_toast(tr("TOAST_MC_BURST_OFF"))
	elif mc_cooldown_timer > 0.0:
		mc_cooldown_timer = max(0.0, mc_cooldown_timer - dt)

## Fase "Mente Colmena" del logic tick: ráfaga/cooldown, auto-play mientras está activa, y si no,
## el gate de sincronía (sólo tras SINGULARIDAD con rama Simbiosis).
func tick_mente_colmena(dt: float) -> void:
	tick_mc_burst(dt)  # IA = ráfaga activable con cooldown (no permanente)
	if mente_colmena_active:
		# Auto-click: simula 10 clicks por segundo
		var sim_power: float = EconomyManager.get_click_power() * 10.0 * dt
		EconomyManager.money += sim_power
		EconomyManager.total_money_generated += sim_power
		StructuralModel.epsilon_runtime += 0.008 * 10.0 * dt
		if is_instance_valid(UIManager.big_click_button):
			UIManager.big_click_button.set_active_delta(sim_power)
		tick_auto_buy(dt)
	elif LegacyManager.last_run_ending == "SINGULARIDAD" and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		_tick_mente_colmena_gate(dt)

## Sincronía: ratio activo/pasivo ≈ 50/50 con ε en banda y flujo mínimo durante MC_GATE_HOLD s.
func _tick_mente_colmena_gate(dt: float) -> void:
	var ap: Dictionary = EconomyManager.get_active_passive_breakdown()
	var tot: float = ap.activo + ap.pasivo
	if tot <= 0:
		return
	var ratio: float = ap.activo / tot
	# Si el estrés supera 0.50, rompe la sincronización
	var stress_too_high: bool = StructuralModel.epsilon_runtime > 0.50
	var eps_ok := StructuralModel.epsilon_runtime >= Balance.MC_GATE_EPS_LO and StructuralModel.epsilon_runtime <= Balance.MC_GATE_EPS_HI
	var flow_ok := EconomyManager.get_delta_total() >= Balance.MC_GATE_DELTA_MIN
	if abs(ratio - 0.5) <= Balance.MC_GATE_RATIO_TOL and eps_ok and flow_ok:
		var was_zero := mente_colmena_timer == 0.0
		mente_colmena_timer += dt
		if was_zero:
			LogManager.add(tr("LAP_MC_SINCRONIA") % Balance.MC_GATE_HOLD)
		if mente_colmena_timer >= Balance.MC_GATE_HOLD:
			activate_mente_colmena()
		else:
			var pct := int(mente_colmena_timer / Balance.MC_GATE_HOLD * 100.0)
			var prev_pct := int((mente_colmena_timer - dt) / Balance.MC_GATE_HOLD * 100.0)
			if int(pct / 25.0) > int(prev_pct / 25.0): # lap cada 25%
				LogManager.add(tr("LAP_MC_SYNC_PCT") % [pct, mente_colmena_timer, Balance.MC_GATE_HOLD])
			UIManager.show_toast("🧠 MENTE COLMENA — %d%% (%.0f/%.0fs) — ratio %.1f%%/%.1f%%" % [pct, mente_colmena_timer, Balance.MC_GATE_HOLD, ap.activo, ap.pasivo])
	else:
		if mente_colmena_timer > 0.0:
			if stress_too_high:
				LogManager.add(tr("LAP_MC_BROKEN_STRESS") % StructuralModel.epsilon_runtime)
			else:
				LogManager.add(tr("LAP_MC_BROKEN_RATIO") % [ap.activo, ap.pasivo])
		mente_colmena_timer = 0.0

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

# ==================== NG+ CAP NOTIFICATION ====================

## Ruta de cierre más probable dado el estado actual de mutaciones.
func get_predicted_route() -> String:
	if LegacyManager.trascendencia_count == 0:
		return ""
	if RouteManager.is_active("vacio"):            return "ASCESIS_PROFUNDA"
	if RouteManager.is_active("carnaval"):         return "POLIMORFÍA TOTAL"
	if EvoManager.mutation_depredador:             return "DEPREDADOR DE REALIDADES"
	if EvoManager.mutation_remision:               return "REMISIÓN METABÓLICA"
	if EvoManager.mutation_omega_cero:             return "PROTOCOLO OMEGA-CERO"
	if EvoManager.mutation_met_oscuro:             return "METABOLISMO OSCURO"
	if EvoManager.mutation_caos_orquestado:        return "CAOS ORQUESTADO"
	if EvoManager.mutation_coro_simbiotico:        return "CORO SIMBIÓTICO"
	if EvoManager.mutation_micelio_omnisciente:    return "MICELIO OMNISCIENTE"
	if homeostasis_tier_reached >= 3:              return "HOMEORHESIS"
	if homeostasis_tier_reached >= 2:              return "ALLOSTASIS"
	if EvoManager.mutation_homeorhesis:            return "HOMEORHESIS"
	if EvoManager.mutation_allostasis:             return "ALLOSTASIS"
	if EvoManager.mutation_homeostasis:            return "HOMEOSTASIS"
	if EvoManager.mutation_symbiosis:              return "SIMBIOSIS"
	if EvoManager.mutation_red_micelial:           return "ESPORULACIÓN"
	if EvoManager.mutation_parasitism:             return "PARASITISMO"
	if EvoManager.mutation_ayuno_primordial:        return "AYUNO PRIMORDIAL"
	if EvoManager.mutation_hyperassimilation:      return "HIPERASIMILACIÓN"
	return ""

## Calcula el bonus NG+ actual para la ruta dada sin efectos secundarios.
## Devuelve {bonus, cap, raw, saturated}.
func compute_ng_bonus(route: String) -> Dictionary:
	var cap: int = int(Balance.NG_CAPS.get(route, 0))
	var _rs: Dictionary = RouteManager.get_extra_state()
	var raw := 0
	match route:
		"HOMEOSTASIS":
			raw = int(floor(resilience_score / 50.0))
		"SIMBIOSIS":
			raw = int(floor(run_time / 300.0))
		"HIPERASIMILACION", "HIPERASIMILACIÓN":
			raw = int(floor(StructuralModel.epsilon_peak * 5.0))
		"PARASITISMO":
			raw = int(floor(BiosphereEngine.biomasa / 8.0))
		"ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL":
			raw = int(floor(BiosphereEngine.micelio / 20.0))
		"ALLOSTASIS":
			raw = disturbances_survived
		"HOMEORHESIS":
			raw = int(floor(omega_min_peak * 10.0))
		"MUTACION_FINAL", "METABOLISMO OSCURO":
			raw = EvoManager.met_oscuro_devoured_count * 2
		"PROTOCOLO OMEGA-CERO":
			raw = int(EvoManager.omega_cero_phi / 50.0)
		"REMISIÓN METABÓLICA":
			raw = int(BiosphereEngine.biomasa / Balance.REMISION_PL_DIVISOR)
		"ESCLEROCIO OSCURO":
			raw = int(floor(EvoManager.met_oscuro_devoured_count / 8.0))
		"AUTOFAGIA NECRÓTICA":
			raw = int(floor(EvoManager.autolisis_devour_count / 3.0))
		"NECROSIS CONTROLADA":
			raw = int(floor(EvoManager.necrosis_agent_count / 2.0))
		"POLIMORFÍA TOTAL", "POLIMORFIA TOTAL":
			raw = int(floor(_rs.get("total_rotations", 0) / 2.0))
		"DOMADOR DEL CAOS":
			raw = int(floor(_rs.get("peak_money", 0.0) / 500_000.0))
		"ASCESIS_PROFUNDA":
			raw = int(floor(omega_min_peak * 10.0))
		"MENTE COLMENA DISTRIBUIDA":
			raw = int(floor(run_time / 600.0))
		"DEPREDADOR DE REALIDADES":
			raw = EvoManager.met_oscuro_devoured_count
		"COLAPSO DEPREDATORIO":
			raw = EvoManager.met_oscuro_devoured_count * 2
		"PANSPERMIA NEGRA":
			raw = int(floor(BiosphereEngine.micelio / 20.0))
		"AYUNO PRIMORDIAL":
			raw = int(floor(EvoManager.ayuno_silencio_peak / Balance.AYUNO_NG_PEAK_DIV))
	var bonus: int = int(min(raw, cap))
	return {"bonus": bonus, "cap": cap, "raw": raw, "saturated": cap > 0 and bonus >= cap}

## Notifica una sola vez por run cuando el bonus NG+ satura el cap.
## Llamado desde main.gd _on_logic_tick().
func check_ng_cap() -> void:
	if run_closed or _ng_cap_notified or LegacyManager.trascendencia_count == 0:
		return
	var route := get_predicted_route()
	if route.is_empty():
		return
	var info := compute_ng_bonus(route)
	if info.saturated:
		_ng_cap_notified = true
		UIManager.show_toast(tr("TOAST_NG_CAP") % [info.bonus, info.cap, route])
		LogManager.add(tr("LOG_NG_CAP") % [info.bonus, route])

# ═════════════════════════════════════════════════════════════════════════════
#  Bono NG+ por ruta (datos)
# ═════════════════════════════════════════════════════════════════════════════
# Al cerrar con trascendencia ≥ 1: bono = min(raw, Balance.NG_CAPS[ruta]), donde raw sale de
# una métrica de la run. Cada regla:
#   value  Callable → valor de la métrica
#   op     "div" int(floor(v/k)) · "div_trunc" int(v/k) · "mul" int(floor(v*k)) · "id" int(v)
#   k      constante de la operación
#   vfmt   formato del valor en el log; show (opcional) transforma el valor antes de mostrarlo
#   log    plantilla del log: {v} valor formateado, {b} bono, {c} cap
# Agregar una ruta = agregar una entrada (y su cap en Balance.NG_CAPS).
var _ng_rules: Dictionary = {}

func ng_bonus_rule(route: String) -> Dictionary:
	if _ng_rules.is_empty():
		_ng_rules = _build_ng_rules()
	return _ng_rules.get(route, {})

func _ng_raw(rule: Dictionary, v: Variant) -> int:
	match str(rule.op):
		"div": return int(floor(v / rule.k))
		"div_trunc": return int(v / rule.k)
		"mul": return int(floor(v * rule.k))
		_: return int(v)

func _build_ng_rules() -> Dictionary:
	var money_m := func(v: float) -> float: return v / 1_000_000.0
	var defs := {
		# ── Tier 1 ──
		"HOMEOSTASIS": {"value": func() -> Variant: return resilience_score, "op": "div", "k": 50.0,
			"vfmt": "%.0f", "log": "resiliencia {v} / 50 = {b} (cap {c})"},
		"SIMBIOSIS": {"value": func() -> Variant: return run_time, "op": "div", "k": 300.0,
			"vfmt": "%.0f", "log": "run_time {v}s / 300 = {b} (cap {c})"},
		"HIPERASIMILACION": {"value": func() -> Variant: return StructuralModel.epsilon_peak, "op": "mul", "k": 5.0,
			"vfmt": "%.2f", "log": "ε_peak {v} × 5 = {b} (cap {c})"},
		"PARASITISMO": {"value": func() -> Variant: return BiosphereEngine.biomasa, "op": "div", "k": 8.0,
			"vfmt": "%.1f", "log": "biomasa {v} / 8 = {b} (cap {c})"},
		# ── Red micelial ──
		"ESPORULACION": {"value": func() -> Variant: return BiosphereEngine.micelio, "op": "div", "k": 20.0,
			"vfmt": "%.1f", "log": "micelio {v} / 20 = {b} (cap {c})"},
		# ── Tier 2 ──
		"ALLOSTASIS": {"value": func() -> Variant: return disturbances_survived, "op": "id", "k": 1.0,
			"vfmt": "%d", "log": "perturbaciones {v} (cap {c})"},
		"HOMEORHESIS": {"value": func() -> Variant: return omega_min_peak, "op": "mul", "k": 10.0,
			"vfmt": "%.2f", "log": "omega_min_peak {v} × 10 = {b} (cap {c})"},
		"METABOLISMO OSCURO": {"value": func() -> Variant: return EvoManager.met_oscuro_devoured_count, "op": "mul", "k": 2,
			"vfmt": "%d", "log": "devoured {v} × 2 = {b} (cap {c})"},
		"PROTOCOLO OMEGA-CERO": {"value": func() -> Variant: return EvoManager.omega_cero_phi, "op": "div_trunc", "k": 50.0,
			"vfmt": "%.0f", "log": "phi {v} / 50 = {b} (cap {c})"},
		"REMISIÓN METABÓLICA": {"value": func() -> Variant: return BiosphereEngine.biomasa, "op": "div_trunc", "k": Balance.REMISION_PL_DIVISOR,
			"vfmt": "%.0f", "log": "biomasa {v} / " + ("%.0f" % Balance.REMISION_PL_DIVISOR) + " = {b} (cap {c})"},
		"ESCLEROCIO OSCURO": {"value": func() -> Variant: return EvoManager.met_oscuro_devoured_count, "op": "div", "k": 8.0,
			"vfmt": "%d", "log": "devoured {v} / 8 = {b} (cap {c})"},
		"AUTOFAGIA NECRÓTICA": {"value": func() -> Variant: return EvoManager.autolisis_devour_count, "op": "div", "k": 3.0,
			"vfmt": "%d", "log": "autolisis_devoured {v} / 3 = {b} (cap {c})"},
		"NECROSIS CONTROLADA": {"value": func() -> Variant: return EvoManager.necrosis_agent_count, "op": "div", "k": 2.0,
			"vfmt": "%d", "log": "agentes {v} / 2 = {b} (cap {c})"},
		"POLIMORFÍA TOTAL": {"value": func() -> Variant: return int(RouteManager.get_extra_state().get("total_rotations", 0)), "op": "div", "k": 2.0,
			"vfmt": "%d", "log": "rotaciones {v} / 2 = {b} (cap {c})"},
		"DOMADOR DEL CAOS": {"value": func() -> Variant: return RouteManager.get_extra_state().get("peak_money", 0.0), "op": "div", "k": 500_000.0,
			"vfmt": "%.1f", "show": money_m, "log": "dinero_pico ${v}M / 500K = {b} (cap {c})"},
		"ASCESIS_PROFUNDA": {"value": func() -> Variant: return omega_min_peak, "op": "mul", "k": 10.0,
			"vfmt": "%.2f", "log": "omega_min_peak {v} × 10 = {b} (cap {c})"},
		# ── Tier 3 (late-game) ──
		"MENTE COLMENA DISTRIBUIDA": {"value": func() -> Variant: return run_time, "op": "div", "k": 600.0,
			"vfmt": "%.0f", "log": "run_time {v}s / 600 = {b} (cap {c})"},
		"DEPREDADOR DE REALIDADES": {"value": func() -> Variant: return EvoManager.met_oscuro_devoured_count, "op": "id", "k": 1.0,
			"vfmt": "%d", "log": "devoured {v} (cap {c})"},
		"COLAPSO DEPREDATORIO": {"value": func() -> Variant: return EvoManager.met_oscuro_devoured_count, "op": "mul", "k": 2,
			"vfmt": "%d", "log": "devoured {v} × 2 = {b} (cap {c})"},
		"PANSPERMIA NEGRA": {"value": func() -> Variant: return BiosphereEngine.micelio, "op": "div", "k": 20.0,
			"vfmt": "%.1f", "log": "micelio {v} / 20 = {b} (cap {c})"},
		"FUSIÓN CATABÓLICA": {"value": func() -> Variant: return EconomyManager.total_money_generated, "op": "div", "k": 10_000_000.0,
			"vfmt": "%.1f", "show": money_m, "log": "generado ${v}M / $10M = {b} (cap {c})"},
		"CAOS ORQUESTADO": {"value": func() -> Variant: return EvoManager.caos_charged_collapses, "op": "div", "k": 2.0,
			"vfmt": "%d", "log": "colapsos con carga {v} / 2 = {b} (cap {c})"},
		"CORO SIMBIÓTICO": {"value": func() -> Variant: return EvoManager.coro_peak_stacks, "op": "div", "k": 20.0,
			"vfmt": "%.0f", "log": "pico de ritmo {v} / 20 = {b} (cap {c})"},
		"MICELIO OMNISCIENTE": {"value": func() -> Variant: return EvoManager.micelio_peak_network, "op": "div", "k": 20.0,
			"vfmt": "%.0f", "log": "red conectada pico {v} / 20 = {b} (cap {c})"},
		"AYUNO PRIMORDIAL": {"value": func() -> Variant: return EvoManager.ayuno_silencio_peak, "op": "div", "k": Balance.AYUNO_NG_PEAK_DIV,
			"vfmt": "%.1f", "log": "S_peak {v} / " + ("%.0f" % Balance.AYUNO_NG_PEAK_DIV) + " = {b} (cap {c})"},
	}
	# Alias históricos (con/sin tilde, nombres viejos) → misma regla.
	var aliases := {
		"HIPERASIMILACIÓN": "HIPERASIMILACION",
		"ESPORULACIÓN": "ESPORULACION", "ESPORULACION TOTAL": "ESPORULACION",
		"MUTACION_FINAL": "METABOLISMO OSCURO",
		"POLIMORFIA TOTAL": "POLIMORFÍA TOTAL",
	}
	for alias in aliases:
		defs[alias] = defs[aliases[alias]]
	return defs
