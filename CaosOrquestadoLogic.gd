class_name CaosOrquestadoLogic

## CAOS ORQUESTADO — Transmutación (A → A+) de HOMEOSTASIS.
## "Homeostasis aprendió a no temerle al caos: lo dirige."
## Spec: docs/design/involucion_transmutaciones.md §5.2. Se entra por el botón [T]
## (TransmutationLogic). Estado en EvoManager (caos_*); sólo funciones estáticas, como DarkTreeLogic.
##
##   · Combustible: todo el ingreso × (1 + CAOS_FUEL_K · ε), tope CAOS_FUEL_CAP. Ω no baja de 0.20.
##   · Carga de caos: crece CAOS_CHARGE_RATE/s y es piso de ε (StructuralModel): el caos se acumula
##     si no lo dirigís, y el Colapso lo cobra.
##   · [Q] Colapso Dirigido: cobra el ε acumulado → ráfaga × (1 + CAOS_COLLAPSE_K · ε) durante
##     CAOS_COLLAPSE_DURATION s y ε vuelve a 0. Decisión constante: mantener ε alto o cobrarlo.
##   · [W] acorta el cooldown del Colapso (sink de dinero).
##   · Sello: GRAN COLAPSO — un Colapso cobrado con ε ≥ CAOS_GRAND_EPS cuya ráfaga genere
##     ≥ CAOS_GRAND_MONEY sella la ruta al terminar. Si no alcanza, se vuelve a cargar.

static func activate() -> void:
	if EvoManager.mutation_caos_orquestado:
		return
	EvoManager.mutation_caos_orquestado = true
	EvoManager.caos_money_mark = EconomyManager.total_money_generated
	# Homeostasis revertida: sin modo homeostático ni tiers (Alostasis/Homeorresis) esta run.
	RunManager.homeostasis_mode = false
	RunManager.post_homeostasis = false
	if is_instance_valid(RunManager.evolution_button):
		RunManager.evolution_button.visible = false
	RunManager.target_evolution = ""
	LogManager.add(TranslationServer.translate("LOG_CAOS_EFFECTS"))
	EvoManager.mutation_activated.emit("caos_orquestado", TranslationServer.translate("MUT_CAOS_ORQUESTADO"))
	AchievementManager.on_mutation_activated("caos_orquestado")
	UIManager.show_toast(TranslationServer.translate("TOAST_CAOS_ON"))
	EvoManager._save_after_mutation()


## Digestión de Homeostasis: la estabilidad acumulada queda como reserva de Ω.
static func digest_homeostasis() -> String:
	StructuralModel.omega_min += Balance.CAOS_DIGEST_OMEGA_MIN
	return TranslationServer.translate("TRANSMUT_DIGEST_OMEGA") % Balance.CAOS_DIGEST_OMEGA_MIN


## Tick (fase de procesos de ruta).
static func process(dt: float) -> void:
	if not EvoManager.mutation_caos_orquestado or RunManager.run_closed:
		return
	# El caos se acumula si no lo dirigís: la carga sube sola (pausada durante el Colapso).
	if EvoManager.caos_burst_timer <= 0.0:
		EvoManager.caos_charge = minf(EvoManager.caos_charge + charge_rate() * dt, Balance.CAOS_CHARGE_MAX)
	if StructuralModel.epsilon_runtime >= Balance.CAOS_RED_EPS:
		EvoManager.caos_red_time += dt
	if EvoManager.caos_burst_timer > 0.0:
		EvoManager.caos_burst_timer -= dt
		if EvoManager.caos_burst_timer <= 0.0:
			EvoManager.caos_burst_timer = 0.0
			EvoManager.caos_cooldown = effective_cooldown()
			_end_burst()
	elif EvoManager.caos_cooldown > 0.0:
		EvoManager.caos_cooldown = maxf(0.0, EvoManager.caos_cooldown - dt)


# ── Economía (IncomeModifiers) ───────────────────────────────────────────────

## Combustible: × (1 + k·ε), tope. 1.0 si la ruta no está activa.
static func fuel_mult() -> float:
	if not EvoManager.mutation_caos_orquestado:
		return 1.0
	return minf(1.0 + Balance.CAOS_FUEL_K * maxf(StructuralModel.epsilon_runtime, 0.0), Balance.CAOS_FUEL_CAP)

static func burst_mult() -> float:
	if not EvoManager.mutation_caos_orquestado or EvoManager.caos_burst_timer <= 0.0:
		return 1.0
	return EvoManager.caos_burst_saved_mult


# ── [Q] Colapso Dirigido ─────────────────────────────────────────────────────

static func can_collapse() -> bool:
	return EvoManager.mutation_caos_orquestado and not RunManager.run_closed \
		and EvoManager.caos_burst_timer <= 0.0 and EvoManager.caos_cooldown <= 0.0

## Cobra el ε acumulado: ráfaga proporcional y ε → 0.
static func collapse() -> void:
	if not can_collapse():
		return
	var eps: float = maxf(StructuralModel.epsilon_runtime, 0.0)
	EvoManager.caos_burst_saved_mult = 1.0 + collapse_k() * eps
	EvoManager.caos_burst_timer = Balance.CAOS_COLLAPSE_DURATION
	EvoManager.caos_collapse_count += 1
	if eps >= Balance.CAOS_RED_EPS:
		EvoManager.caos_charged_collapses += 1
	EvoManager.caos_burst_eps = eps
	EvoManager.caos_burst_money_mark = EconomyManager.total_money_generated
	EvoManager.caos_peak_collapse_eps = maxf(EvoManager.caos_peak_collapse_eps, eps)
	EvoManager.caos_min_collapse_eps = minf(EvoManager.caos_min_collapse_eps, eps)
	EvoManager.caos_charge = 0.0
	StructuralModel.epsilon_runtime = 0.0
	if is_grand_attempt():
		UIManager.show_toast(TranslationServer.translate("TOAST_CAOS_GRAND_START") % [eps, UIManager.format_compact(Balance.CAOS_GRAND_MONEY)])
	else:
		UIManager.show_toast(TranslationServer.translate("TOAST_CAOS_COLLAPSE") % [eps, EvoManager.caos_burst_saved_mult])


# ── [W] "Afinar la orquesta" (sink): menos cooldown y carga más rápida ───────
## El ciclo de Colapsos lo limitan el cooldown Y lo que tarda la carga en volver a la zona roja,
## y el Gran Colapso lo limita lo que rinde una ráfaga: [W] ataca los tres.
## Multiplicador por ε del Colapso: [W] lo afina (+CAOS_CD_BURST_BONUS por nivel).
static func collapse_k() -> float:
	return Balance.CAOS_COLLAPSE_K * (1.0 + Balance.CAOS_CD_BURST_BONUS * EvoManager.caos_cd_level)

static func charge_rate() -> float:
	return Balance.CAOS_CHARGE_RATE * (1.0 + Balance.CAOS_CD_CHARGE_BONUS * EvoManager.caos_cd_level)

static func effective_cooldown() -> float:
	return maxf(Balance.CAOS_CD_FLOOR,
		Balance.CAOS_COLLAPSE_COOLDOWN * pow(1.0 - Balance.CAOS_CD_REDUCE_PCT, EvoManager.caos_cd_level))

static func cd_cost() -> float:
	return Balance.CAOS_CD_COST_BASE * pow(Balance.CAOS_CD_COST_GROWTH, EvoManager.caos_cd_level)

static func cd_maxed() -> bool:
	return effective_cooldown() <= Balance.CAOS_CD_FLOOR

static func can_buy_cd() -> bool:
	return EvoManager.mutation_caos_orquestado and not RunManager.run_closed and not cd_maxed() \
		and EconomyManager.money >= cd_cost()

static func buy_cd() -> void:
	if not can_buy_cd():
		return
	EconomyManager.money -= cd_cost()
	EvoManager.caos_cd_level += 1
	if EvoManager.caos_cooldown > 0.0:
		EvoManager.caos_cooldown = minf(EvoManager.caos_cooldown, effective_cooldown())
	UIManager.show_toast(TranslationServer.translate("TOAST_CAOS_CD_BUY") % effective_cooldown())


# ── Sello ────────────────────────────────────────────────────────────────────

## La ráfaga en curso fue cobrada con ε suficiente para un Gran Colapso.
static func is_grand_attempt() -> bool:
	return EvoManager.caos_burst_eps >= Balance.CAOS_GRAND_EPS

## $ generados por la ráfaga en curso.
static func burst_money() -> float:
	return maxf(EconomyManager.total_money_generated - EvoManager.caos_burst_money_mark, 0.0)

## Fin de una ráfaga: registra el intento; un Gran Colapso logrado sella la ruta.
static func _end_burst() -> void:
	var money: float = burst_money()
	EvoManager.caos_last_burst_eps = EvoManager.caos_burst_eps
	EvoManager.caos_last_burst_money = money
	if not is_grand_attempt():
		return
	EvoManager.caos_grand_attempts += 1
	EvoManager.caos_best_grand_money = maxf(EvoManager.caos_best_grand_money, money)
	if money >= Balance.CAOS_GRAND_MONEY:
		LogManager.add(TranslationServer.translate("LOG_CAOS_GRAND_DONE") % [EvoManager.caos_burst_eps, UIManager.format_compact(money)])
		RunManager.close_run("CAOS ORQUESTADO", TranslationServer.translate("CLOSE_CAOS"))
	else:
		UIManager.show_toast(TranslationServer.translate("TOAST_CAOS_GRAND_FAIL") % [UIManager.format_compact(money), UIManager.format_compact(Balance.CAOS_GRAND_MONEY)])
		# FRACASO: el caos dirigido se desordena → vuelve al orden de origen.
		if EvoManager.caos_grand_attempts >= Balance.CAOS_GRAND_FAILS:
			RunManager.close_run("HOMEOSTASIS", TranslationServer.translate("CLOSE_CAOS_FAIL"))

## Sin botón: el Gran Colapso sella solo al terminar su ráfaga.
static func seal_ready() -> bool:
	return false


# ── Legado: Batuta (ε → 0 una vez por run, en cualquier run) ────────────────

static func batuta_available() -> bool:
	return LegacyManager.get_buff_value("legado_batuta") and not EvoManager.batuta_used \
		and not RunManager.run_closed and StructuralModel.epsilon_runtime > 0.0

static func use_batuta() -> void:
	if not batuta_available():
		return
	EvoManager.batuta_used = true
	StructuralModel.epsilon_runtime = 0.0
	UIManager.show_toast(TranslationServer.translate("TOAST_BATUTA_USED"))
	LogManager.add(TranslationServer.translate("LOG_BATUTA_USED"))
