class_name CoroSimbioticoLogic

## CORO SIMBIÓTICO — Transmutación (A → A+) de SIMBIOSIS.
## "La cooperación deja de ser un pacto y se vuelve un ritmo."
## Spec: docs/design/involucion_transmutaciones.md §5.3. Se entra por el botón [T]
## (TransmutationLogic). Estado en EvoManager (coro_*); sólo funciones estáticas.
##
##   · Ritmo (stacks): cada click suma 1; decaen con constante de tiempo = ventana (5 s + [W]),
##     así que a N clicks/s el ritmo converge a N × ventana. Se cuentan en TODAS las runs (el legado
##     Eco del Coro los usa), pero sólo pagan con Coro activo o con el legado.
##   · Con Coro: ingreso × (1 + CORO_STACK_BONUS · stacks · desafinación), tope de stacks CORO_STACK_CAP.
##     Desafinación = (1 − ε/2): el estrés desafina el coro.
##   · [Q] Sobrecarga: CORO_OVERLOAD_DURATION s de auto-click a CORO_OVERLOAD_CPS, ε + CORO_OVERLOAD_EPS.
##   · [W] Sostener el coro: +1 s de ventana por nivel.
##   · Sello: tiempo con ≥ CORO_SEAL_STACKS stacks · Sobrecargas · $ desde la reversión.

static func activate() -> void:
	if EvoManager.mutation_coro_simbiotico:
		return
	EvoManager.mutation_coro_simbiotico = true
	EvoManager.coro_money_mark = EconomyManager.total_money_generated
	LogManager.add(TranslationServer.translate("LOG_CORO_EFFECTS"))
	EvoManager.mutation_activated.emit("coro_simbiotico", TranslationServer.translate("MUT_CORO_SIMBIOTICO"))
	AchievementManager.on_mutation_activated("coro_simbiotico")
	UIManager.show_toast(TranslationServer.translate("TOAST_CORO_ON"))
	EvoManager._save_after_mutation()


## Digestión de Simbiosis: el pacto se vuelve ritmo inicial (decae si no lo sostenés).
static func digest_simbiosis() -> String:
	EvoManager.coro_stacks = maxf(EvoManager.coro_stacks, Balance.CORO_DIGEST_STACKS)
	return TranslationServer.translate("TRANSMUT_DIGEST_STACKS") % int(Balance.CORO_DIGEST_STACKS)


## Ventana del ritmo (s): constante de decaimiento de los stacks.
static func window() -> float:
	if EvoManager.mutation_coro_simbiotico:
		return Balance.CORO_WINDOW_BASE + Balance.CORO_W_WINDOW_PER_LEVEL * EvoManager.coro_w_level
	return Balance.CORO_WINDOW_BASE


## Cada click del jugador (main.on_reactor_click) y de la Sobrecarga.
static func on_click(n: float = 1.0) -> void:
	EvoManager.coro_stacks = minf(EvoManager.coro_stacks + n, Balance.CORO_STACK_CAP)


## Tick (fase de procesos de ruta). Corre en todas las runs: decaimiento del ritmo.
static func process(dt: float) -> void:
	if RunManager.run_closed:
		return
	EvoManager.coro_stacks = maxf(EvoManager.coro_stacks - EvoManager.coro_stacks / window() * dt, 0.0)
	if not EvoManager.mutation_coro_simbiotico:
		return
	# Sobrecarga: auto-click (como Mente Colmena: el dinero cuenta como generado).
	if EvoManager.coro_overload_timer > 0.0:
		var clicks: float = Balance.CORO_OVERLOAD_CPS * dt
		var gained: float = EconomyManager.get_click_power() * clicks
		EconomyManager.money += gained
		EconomyManager.total_money_generated += gained
		on_click(clicks)
		EvoManager.coro_overload_timer -= dt
		if EvoManager.coro_overload_timer <= 0.0:
			EvoManager.coro_overload_timer = 0.0
			EvoManager.coro_cooldown = Balance.CORO_OVERLOAD_COOLDOWN
	elif EvoManager.coro_cooldown > 0.0:
		EvoManager.coro_cooldown = maxf(0.0, EvoManager.coro_cooldown - dt)
	var s: float = EvoManager.coro_stacks
	EvoManager.coro_peak_stacks = maxf(EvoManager.coro_peak_stacks, s)
	if s >= Balance.CORO_SEAL_STACKS:
		EvoManager.coro_rhythm_time += dt
	# Fortissimo (MYTHIC): ≥ CORO_MYTHIC_STACKS sostenidos sin Sobrecarga.
	if s >= Balance.CORO_MYTHIC_STACKS and EvoManager.coro_overload_timer <= 0.0:
		EvoManager.coro_fortissimo_streak += dt
		if EvoManager.coro_fortissimo_streak >= Balance.CORO_MYTHIC_SECONDS and not AchievementManager.is_unlocked("fortissimo"):
			AchievementManager.unlock("fortissimo")
	else:
		EvoManager.coro_fortissimo_streak = 0.0


# ── Economía (IncomeModifiers) ───────────────────────────────────────────────

## Desafinación: el estrés desafina el coro (ε 0 → ×1; ε 1 → ×0.5; ε ≥ 2 → ×0).
static func tuning() -> float:
	return clampf(1.0 - StructuralModel.epsilon_runtime / 2.0, 0.0, 1.0)

static func rhythm_mult() -> float:
	if not EvoManager.mutation_coro_simbiotico:
		return 1.0
	return 1.0 + Balance.CORO_STACK_BONUS * EvoManager.coro_stacks * tuning()

## Legado Eco del Coro (todas las runs, salvo con Coro activo, que ya paga su ritmo completo).
static func echo_mult() -> float:
	if EvoManager.mutation_coro_simbiotico or not LegacyManager.get_buff_value("legado_eco_del_coro"):
		return 1.0
	return 1.0 + minf(Balance.CORO_ECHO_BONUS * EvoManager.coro_stacks, Balance.CORO_ECHO_CAP)


# ── [Q] Sobrecarga ───────────────────────────────────────────────────────────

static func can_overload() -> bool:
	return EvoManager.mutation_coro_simbiotico and not RunManager.run_closed \
		and EvoManager.coro_overload_timer <= 0.0 and EvoManager.coro_cooldown <= 0.0

static func overload() -> void:
	if not can_overload():
		return
	EvoManager.coro_overload_timer = Balance.CORO_OVERLOAD_DURATION
	EvoManager.coro_overload_count += 1
	StructuralModel.epsilon_runtime += Balance.CORO_OVERLOAD_EPS
	UIManager.show_toast(TranslationServer.translate("TOAST_CORO_OVERLOAD"))


# ── [W] Sostener el coro (sink) ──────────────────────────────────────────────

static func w_cost() -> float:
	return Balance.CORO_W_COST_BASE * pow(Balance.CORO_W_COST_GROWTH, EvoManager.coro_w_level)

static func w_maxed() -> bool:
	return EvoManager.coro_w_level >= Balance.CORO_W_MAX_LEVEL

static func can_buy_w() -> bool:
	return EvoManager.mutation_coro_simbiotico and not RunManager.run_closed and not w_maxed() \
		and EconomyManager.money >= w_cost()

static func buy_w() -> void:
	if not can_buy_w():
		return
	EconomyManager.money -= w_cost()
	EvoManager.coro_w_level += 1
	UIManager.show_toast(TranslationServer.translate("TOAST_CORO_W_BUY") % window())


# ── Sello ────────────────────────────────────────────────────────────────────

static func money_since_revert() -> float:
	return maxf(EconomyManager.total_money_generated - EvoManager.coro_money_mark, 0.0)

static func seal_ready() -> bool:
	return EvoManager.mutation_coro_simbiotico \
		and EvoManager.coro_rhythm_time >= Balance.CORO_SEAL_RHYTHM_TIME \
		and EvoManager.coro_overload_count >= Balance.CORO_SEAL_OVERLOADS \
		and money_since_revert() >= Balance.CORO_SEAL_MONEY
