# PrimordioLogic.gd
# Ciclo biológico: Primordio + Panspermia + Singularidad + Colonización.
# Funciones estáticas — acceden a EvoManager (autoload) directamente.
# Los vars de estado (primordio_active, etc.) viven en EvoManager.gd.
class_name PrimordioLogic

# =============================================================
# CICLO BIOLÓGICO: PRIMORDIO (Fase 2)
# =============================================================

static func check_red_micelial_transition(_main_ref: Node):
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 0:
		# Fase A -> Fase B
		var hifas_req = 11.5 if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION else 9.5
		var eps_req = 0.65 if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION else 0.35

		if BiosphereEngine.hifas >= hifas_req \
		and BiosphereEngine.biomasa >= 5.0 \
		and StructuralModel.epsilon_runtime <= eps_req \
		and RunManager.run_time >= 200.0:
			EvoManager.red_micelial_phase = 1
			LogManager.add(tr("LOG_RED_FASE_B"))
			UIManager.show_toast(tr("TOAST_RED_INTEGRACION"))

static func update_primordio(main_ref: Node) -> void:
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		_process_primordio_biological(main_ref)
	elif EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		_process_primordio_mechanical(main_ref)

static func _process_primordio_biological(_main_ref: Node):
	# Inicio: frontera micelial empujada al 60% (Fase 1) + masa/hifas mínimas.
	if not EvoManager.primordio_active and not EvoManager.seta_formada and EvoManager.red_micelial_phase == 1:
		if BiosphereEngine.micelio >= 60.0 and BiosphereEngine.hifas >= 14.5 and BiosphereEngine.biomasa >= 8.0:
			_begin_primordio_biological()

	if EvoManager.primordio_active:
		var dt := RunManager.LOGIC_TICK
		if EvoManager.primordio_regar_cd > 0.0:
			EvoManager.primordio_regar_cd = max(0.0, EvoManager.primordio_regar_cd - dt)

		# La maduración avanza SIEMPRE; el desafío es SOBREVIVIR las contaminaciones
		# escalantes con el agua finita (Regar). Sin regar, la integridad colapsa antes de los 60s.
		EvoManager.primordio_timer += dt
		# Penalización por sobrecalentar (overclickear sube ε > techo): drena integridad extra.
		if StructuralModel.epsilon_runtime > Balance.PRIMORDIO_BAND_HI:
			EvoManager.primordio_integrity -= Balance.PRIMORDIO_OOB_DRAIN * dt

		# Contaminaciones periódicas (escalan con la maduración).
		EvoManager.primordio_pert_timer += dt
		if EvoManager.primordio_pert_timer >= Balance.PRIMORDIO_PERT_INTERVAL:
			EvoManager.primordio_pert_timer = 0.0
			var dmg: float = min(
				Balance.PRIMORDIO_PERT_DMG_BASE + EvoManager.primordio_timer * Balance.PRIMORDIO_PERT_DMG_SCALE,
				Balance.PRIMORDIO_PERT_DMG_MAX
			)
			EvoManager.primordio_integrity -= dmg
			StructuralModel.epsilon_runtime += Balance.PRIMORDIO_PERT_EPS_KICK
			LogManager.add(tr("PRIMORDIO_CONTAM_LOG") % int(dmg))
			UIManager.show_toast(tr("PRIMORDIO_CONTAM_TOAST") % int(dmg))

		EvoManager.primordio_integrity = clampf(EvoManager.primordio_integrity, 0.0, Balance.PRIMORDIO_INTEGRITY_MAX)

		if EvoManager.primordio_integrity <= 0.0:
			_abort_primordio(tr("PRIMORDIO_ABORT_CONTAM"))
			return

		if EvoManager.primordio_timer >= Balance.PRIMORDIO_BIO_MATURE:
			_complete_primordio()

## Arranca el primordio biológico (desde el botón o el auto-trigger): resetea la maduración activa.
static func _begin_primordio_biological() -> void:
	EvoManager.primordio_active = true
	EvoManager.primordio_timer = 0.0
	EvoManager.primordio_integrity = Balance.PRIMORDIO_INTEGRITY_MAX
	EvoManager.primordio_pert_timer = 0.0
	EvoManager.primordio_regar_cd = 0.0
	LogManager.add(tr("LOG_PRIMORDIO_ALERT"))
	EvoManager.primordio_iniciado.emit()

## Acción activa "Regar": gasta biomasa, restaura integridad y reencauza ε hacia el centro de banda.
static func primordio_regar() -> void:
	if not EvoManager.primordio_active: return
	if BiosphereEngine.biomasa < Balance.PRIMORDIO_REGAR_COST_BIO:
		UIManager.show_toast(tr("PRIMORDIO_SIN_BIO") % BiosphereEngine.biomasa)
		return
	BiosphereEngine.biomasa -= Balance.PRIMORDIO_REGAR_COST_BIO
	EvoManager.primordio_integrity = min(EvoManager.primordio_integrity + Balance.PRIMORDIO_REGAR_HEAL, Balance.PRIMORDIO_INTEGRITY_MAX)
	# Enfría: baja ε hacia la zona segura (saca del sobrecalentamiento de las contaminaciones).
	StructuralModel.epsilon_runtime = move_toward(StructuralModel.epsilon_runtime, Balance.PRIMORDIO_BAND_LO, Balance.PRIMORDIO_REGAR_EPS_PULL)
	AudioManager.play_sfx("click")
	UIManager.show_toast(tr("PRIMORDIO_REGADO_TOAST") % [int(Balance.PRIMORDIO_REGAR_HEAL), int(EvoManager.primordio_integrity)])

# =============================================================
# RAMA VERDE · PANSPERMIA NEGRA (Secuencia de Lanzamiento) — Fase 3
# Post-ESPORULACIÓN: reformar la seta y EYECTAR N veces. Cada pulso cuesta $ (escalado)
# y suma calor; el calor disipa con el tiempo. Sobrecarga → pulso falla (pulsar-esperar).
# =============================================================

static func is_panspermia_window() -> bool:
	return EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION \
		and EvoManager.seta_formada and not RunManager.run_closed \
		and (LegacyManager.last_run_ending == "ESPORULACIÓN" or LegacyManager.last_run_ending == "PANSPERMIA NEGRA")

static func panspermia_pulse_cost() -> float:
	return Balance.PANSPERMIA_PULSE_COST

## Disipa carga Y calor con el tiempo (llamado desde el logic tick). La carga decae →
## hay que seguir eyectando; el calor decae → tras un misfire podés volver a eyectar.
static func process_panspermia(dt: float) -> void:
	if not is_panspermia_window():
		return
	if EvoManager.panspermia_charge > 0.0:
		EvoManager.panspermia_charge = max(0.0, EvoManager.panspermia_charge - Balance.PANSPERMIA_CHARGE_DECAY * dt)
	if EvoManager.panspermia_heat > 0.0:
		EvoManager.panspermia_heat = max(0.0, EvoManager.panspermia_heat - Balance.PANSPERMIA_HEAT_DECAY * dt)

## Una eyección. Sube carga + calor. Si sobrecalienta → MISFIRE (pierde carga, no avanza).
## Retorna true si la carga llegó a la velocidad de escape (lanzamiento exitoso).
static func panspermia_pulse() -> bool:
	var cost: float = Balance.PANSPERMIA_PULSE_COST
	if EconomyManager.money < cost:
		UIManager.show_toast(tr("PANSPERMIA_NEED_MONEY") % cost)
		return false
	# Sobrecalentamiento: la eyección falla y la carga retrocede (penaliza el spam).
	if EvoManager.panspermia_heat + Balance.PANSPERMIA_HEAT_PER_PULSE > Balance.PANSPERMIA_HEAT_MAX:
		EvoManager.panspermia_heat = Balance.PANSPERMIA_HEAT_MAX
		EvoManager.panspermia_charge = max(0.0, EvoManager.panspermia_charge - Balance.PANSPERMIA_OVERLOAD_PENALTY)
		EvoManager.panspermia_misfires += 1
		if EvoManager.panspermia_misfires >= Balance.PANSPERMIA_MAX_MISFIRES:
			# Demasiadas sobrecargas: las esporas no escapan → esporulación local de respaldo (sin Panspermia).
			var esporas := BiosphereEngine.trigger_sporulation()
			if esporas > 1.0:
				LegacyManager.add_spores(esporas)
			LogManager.add(tr("PANSPERMIA_ABORTADO"))
			RunManager.close_run("ESPORULACIÓN", tr("CLOSE_PANSPERMIA_FAIL"))
			return false
		UIManager.show_toast(tr("PANSPERMIA_OVERLOAD") % [EvoManager.panspermia_misfires, Balance.PANSPERMIA_MAX_MISFIRES])
		return false
	EconomyManager.money -= cost
	EvoManager.panspermia_charge += Balance.PANSPERMIA_CHARGE_GAIN
	EvoManager.panspermia_heat += Balance.PANSPERMIA_HEAT_PER_PULSE
	StructuralModel.epsilon_runtime += Balance.PANSPERMIA_PULSE_EPS
	AudioManager.play_sfx("click")
	if EvoManager.panspermia_charge >= Balance.PANSPERMIA_CHARGE_GOAL:
		return true
	UIManager.show_toast(tr("PANSPERMIA_PULSE_OK") % [int(EvoManager.panspermia_charge), int(EvoManager.panspermia_heat)])
	return false

## SINCRONIZACIÓN (rama azul): el medidor sube mientras se cumplen TODAS las condiciones de
## fase a la vez; si se rompe alguna, baja. No es un minijuego de botón: es alcanzar y SOSTENER
## el estado de sincronía (acc + Ω + ε en banda + biomasa) hasta integrar el Núcleo de Conciencia.
static func _process_primordio_mechanical(_main_ref: Node):
	if EvoManager.nucleo_conciencia:
		return
	var dt := RunManager.LOGIC_TICK
	if _nucleo_conditions_met():
		EvoManager.nucleo_sync = min(EvoManager.nucleo_sync + Balance.NUCLEO_SYNC_RATE * dt, Balance.NUCLEO_SYNC_GOAL)
		if EvoManager.nucleo_sync >= Balance.NUCLEO_SYNC_GOAL:
			EvoManager.nucleo_conciencia = true
			EvoManager.primordio_active = false
			EconomyManager.mutation_accounting_bonus += 0.2
			LogManager.add(tr("LOG_MC_HITO"))
			UIManager.show_toast(tr("EVO_NUCLEUS_SYNC"))
	else:
		EvoManager.nucleo_sync = max(0.0, EvoManager.nucleo_sync - Balance.NUCLEO_SYNC_DECAY * dt)

## Las cuatro condiciones de fase del Núcleo (todas simultáneas).
static func _nucleo_conditions_met() -> bool:
	var eps: float = StructuralModel.epsilon_runtime
	return UpgradeManager.level("accounting") >= Balance.NUCLEO_ACC_MIN \
		and StructuralModel.omega >= Balance.NUCLEO_OMEGA_MIN \
		and eps >= Balance.NUCLEO_EPS_LO and eps <= Balance.NUCLEO_EPS_HI \
		and BiosphereEngine.biomasa >= Balance.NUCLEO_BIO_MIN

static func try_iniciar_primordio() -> bool:
	# Guards
	if not EvoManager.mutation_red_micelial: return false
	if EvoManager.red_branch_selected != EvoManager.RedBranch.COLONIZATION: return false
	if EvoManager.primordio_active or EvoManager.seta_formada: return false
	
	# Costo en micelio, escala con abortos previos
	var costo := 20.0 * (1.0 + EvoManager.primordio_abort_count * 0.2)
	if BiosphereEngine.micelio < costo:
		return false
	
	BiosphereEngine.micelio -= costo
	_begin_primordio_biological()
	return true

static func _abort_primordio(reason: String) -> void:
	EvoManager.primordio_active = false
	EvoManager.primordio_timer = 0.0
	EvoManager.primordio_abort_count += 1
	BiosphereEngine.micelio = max(BiosphereEngine.micelio - 40.0, 0.0)
	EvoManager.primordio_abortado.emit(EvoManager.primordio_abort_count, reason)

static func _complete_primordio() -> void:
	EvoManager.primordio_active = false
	EvoManager.primordio_timer = 0.0
	EvoManager.seta_formada = true
	EvoManager.red_micelial_phase = 2  # Fase C: Seta formada, esporulación disponible
	EvoManager.seta_formada_signal.emit()
	AchievementManager.on_seta_formed()

# =============================================================
# RAMA VERDE · COLONIZACIÓN activa (Empuje de Frontera) — anti-AFK
# El micelio ya no se llena solo: se empuja con clicks contra el decay,
# y el sustrato muerde la frontera con retracciones que escalan.
# =============================================================

static func is_colonizacion_pushable() -> bool:
	return EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION \
		and EvoManager.red_micelial_phase < 2 and not EvoManager.seta_formada and not EvoManager.primordio_active

## Llamado por cada click manual (main.on_reactor_click): empuja la frontera micelial.
static func colonizacion_pulse() -> void:
	if not is_colonizacion_pushable():
		return
	BiosphereEngine.micelio = min(BiosphereEngine.micelio + Balance.MICELIO_PULSE_GAIN, 100.0)

## Tick de la fase: dispara retracciones periódicas cuya mordida escala con el tiempo.
static func process_colonizacion(dt: float) -> void:
	if not is_colonizacion_pushable():
		EvoManager.colonizacion_phase_time = 0.0
		EvoManager.colonizacion_pert_timer = 0.0
		return
	EvoManager.colonizacion_phase_time += dt
	EvoManager.colonizacion_pert_timer += dt
	if EvoManager.colonizacion_pert_timer >= Balance.COLONIZ_PERT_INTERVAL:
		EvoManager.colonizacion_pert_timer = 0.0
		if BiosphereEngine.micelio <= 0.0:
			return
		var bite: float = min(
			Balance.COLONIZ_PERT_BITE_BASE + EvoManager.colonizacion_phase_time * Balance.COLONIZ_PERT_BITE_SCALE,
			Balance.COLONIZ_PERT_BITE_MAX
		)
		BiosphereEngine.micelio = max(BiosphereEngine.micelio - bite, 0.0)
		LogManager.add(tr("COLONIZ_RETRACCION_LOG") % int(bite))
		UIManager.show_toast(tr("COLONIZ_RETRACCION_TOAST") % int(bite))

# =============================================================
# COLOR DEL REACTOR — Fuente Única de Verdad (v0.8.27)
# SOLO modificar aquí si querés cambiar un color del reactor.
# =============================================================
