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
##   · Sello: tiempo en zona roja (ε ≥ CAOS_RED_EPS) · Colapsos "con carga" · $ desde la reversión.

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
	EvoManager.caos_burst_saved_mult = 1.0 + Balance.CAOS_COLLAPSE_K * eps
	EvoManager.caos_burst_timer = Balance.CAOS_COLLAPSE_DURATION
	EvoManager.caos_collapse_count += 1
	if eps >= Balance.CAOS_RED_EPS:
		EvoManager.caos_charged_collapses += 1
	EvoManager.caos_peak_collapse_eps = maxf(EvoManager.caos_peak_collapse_eps, eps)
	EvoManager.caos_min_collapse_eps = minf(EvoManager.caos_min_collapse_eps, eps)
	EvoManager.caos_charge = 0.0
	StructuralModel.epsilon_runtime = 0.0
	UIManager.show_toast(TranslationServer.translate("TOAST_CAOS_COLLAPSE") % [eps, EvoManager.caos_burst_saved_mult])


# ── [W] "Afinar la orquesta" (sink): menos cooldown y carga más rápida ───────
## El ciclo de Colapsos lo limitan el cooldown Y lo que tarda la carga en volver a la zona roja;
## por eso [W] baja los dos (medido: sólo cooldown no aceleraba el sello).
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

static func money_since_revert() -> float:
	return maxf(EconomyManager.total_money_generated - EvoManager.caos_money_mark, 0.0)

static func seal_ready() -> bool:
	return EvoManager.mutation_caos_orquestado \
		and EvoManager.caos_red_time >= Balance.CAOS_SEAL_RED_TIME \
		and EvoManager.caos_charged_collapses >= Balance.CAOS_SEAL_CHARGED \
		and money_since_revert() >= Balance.CAOS_SEAL_MONEY


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
