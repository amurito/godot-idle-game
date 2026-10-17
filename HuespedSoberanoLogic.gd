class_name HuespedSoberanoLogic

## HUÉSPED SOBERANO — Transmutación (A → A+) de PARASITISMO. Verbo: DOMESTICAR.
## "El huésped deja de ser víctima: domestica a su parásito."
## Spec: docs/design/involucion_transmutaciones.md §10.4. Se entra por el botón [T]
## (TransmutationLogic); el cierre de Parasitismo espera mientras queden apariciones del botón
## (RunManager.check_parasitism_final). Estado en EvoManager (huesped_*); sólo funciones estáticas.
##
##   · Hambre 0–100: sube HUESPED_HUNGER_RATE·(1 + K·nivel) /s. [Q] Alimentar: −HUESPED_FEED.
##     Cuesta una comida de la despensa (digestión: la biomasa robada) o, sin despensa,
##     HUESPED_FEED_MONEY_PCT del dinero actual.
##   · Banda HUESPED_BAND_LO–HI: la confianza sube. Arriba: muerde (corrosión). Abajo: perezoso
##     (la confianza baja, sin regalos).
##   · Antojos: cada tanto el hambre salta +HUESPED_CRAVING_HUNGER, avisando HUESPED_CRAVING_WARN s antes.
##   · Niveles de confianza (HUESPED_LEVELS): regalos de $ cada HUESPED_GIFT_INTERVAL s y trueque
##     × (1 + HUESPED_TRUEQUE_PER_LEVEL · nivel). Sello: el último nivel.

static func activate() -> void:
	if EvoManager.mutation_huesped_soberano:
		return
	EvoManager.mutation_huesped_soberano = true
	EvoManager.huesped_hunger = Balance.HUESPED_HUNGER_START
	EvoManager.huesped_craving_timer = _craving_interval(0)
	LogManager.add(TranslationServer.translate("LOG_HUESPED_EFFECTS"))
	EvoManager.mutation_activated.emit("huesped_soberano", TranslationServer.translate("MUT_HUESPED_SOBERANO"))
	AchievementManager.on_mutation_activated("huesped_soberano")
	UIManager.show_toast(TranslationServer.translate("TOAST_HUESPED_ON"))
	EvoManager._save_after_mutation()


## Digestión de Parasitismo: la biomasa robada llena la despensa (comidas gratis).
static func digest_parasitismo() -> String:
	EvoManager.huesped_pantry = pantry_preview()
	return TranslationServer.translate("TRANSMUT_DIGEST_PANTRY") % EvoManager.huesped_pantry

static func pantry_preview() -> int:
	return int(floor(maxf(BiosphereEngine.biomasa, 0.0) / Balance.HUESPED_PANTRY_BIO_PER_MEAL))


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutation_huesped_soberano and not RunManager.run_closed

static func level() -> int:
	var lvl := 0
	for need in Balance.HUESPED_LEVELS:
		if EvoManager.huesped_trust >= float(need):
			lvl += 1
	return lvl

static func next_level_trust() -> float:
	var lvl := level()
	return float(Balance.HUESPED_LEVELS[lvl]) if lvl < Balance.HUESPED_LEVELS.size() else 0.0

static func in_band() -> bool:
	return EvoManager.huesped_hunger >= Balance.HUESPED_BAND_LO and EvoManager.huesped_hunger <= Balance.HUESPED_BAND_HI

static func hunger_rate() -> float:
	return Balance.HUESPED_HUNGER_RATE * (1.0 + Balance.HUESPED_HUNGER_LEVEL_K * level())

static func _craving_interval(n: int) -> float:
	var seq: Array = Balance.HUESPED_CRAVING_INTERVALS
	return float(seq[posmod(n, seq.size())])

## Segundos hasta el próximo antojo (para el aviso del panel).
static func craving_in() -> float:
	return EvoManager.huesped_craving_timer


# ── [Q] Alimentar ────────────────────────────────────────────────────────────

static func feed_cost() -> float:
	return EconomyManager.money * Balance.HUESPED_FEED_MONEY_PCT

static func can_feed() -> bool:
	return is_active() and EvoManager.huesped_hunger > 0.0

static func feed() -> void:
	if not can_feed():
		return
	if EvoManager.huesped_pantry > 0:
		EvoManager.huesped_pantry -= 1
	else:
		EconomyManager.money -= feed_cost()
	EvoManager.huesped_hunger = maxf(EvoManager.huesped_hunger - Balance.HUESPED_FEED, 0.0)
	EvoManager.huesped_feeds += 1


## Tick (fase de procesos de ruta).
static func process(dt: float) -> void:
	if not is_active():
		return
	# Saves de antes del arreglo: Huésped activado sobre un Ayuno (Trampa del Vacío) dejaba las dos
	# rutas activas. Huésped reemplaza al Ayuno.
	if EvoManager.mutation_ayuno_primordial:
		EvoManager.mutation_ayuno_primordial = false
		EvoManager._set_genome_state("hiperasimilacion", "bloqueado")
	var lvl_before := level()
	EvoManager.huesped_hunger = minf(EvoManager.huesped_hunger + hunger_rate() * dt, 100.0)
	# Antojos (secuencia fija de intervalos: determinista, sin RNG).
	EvoManager.huesped_craving_timer -= dt
	if EvoManager.huesped_craving_timer <= Balance.HUESPED_CRAVING_WARN and not EvoManager.huesped_craving_warned:
		EvoManager.huesped_craving_warned = true
		UIManager.show_toast(TranslationServer.translate("TOAST_HUESPED_CRAVING_WARN"))
	if EvoManager.huesped_craving_timer <= 0.0:
		EvoManager.huesped_hunger = minf(EvoManager.huesped_hunger + Balance.HUESPED_CRAVING_HUNGER, 100.0)
		EvoManager.huesped_cravings += 1
		EvoManager.huesped_craving_timer = _craving_interval(EvoManager.huesped_cravings)
		EvoManager.huesped_craving_warned = false
	# Banda: confianza; fuera de banda, mordida o pereza.
	if in_band():
		EvoManager.huesped_trust += Balance.HUESPED_TRUST_GAIN * dt
		EvoManager.huesped_gift_timer += dt
		if EvoManager.huesped_gift_timer >= Balance.HUESPED_GIFT_INTERVAL:
			EvoManager.huesped_gift_timer = 0.0
			_gift()
	else:
		if lvl_before >= 1:
			EvoManager.huesped_left_band = true
		if EvoManager.huesped_hunger > Balance.HUESPED_BAND_HI:
			EconomyManager.parasitism_corrosion = maxf(0.0, EconomyManager.parasitism_corrosion - Balance.HUESPED_BITE_CORROSION * dt)
			EvoManager.huesped_bite_time += dt
		else:
			EvoManager.huesped_trust = maxf(0.0, EvoManager.huesped_trust - Balance.HUESPED_TRUST_LOSS * dt)
	var lvl := level()
	if lvl > lvl_before:
		UIManager.show_toast(TranslationServer.translate("TOAST_HUESPED_LEVEL") % lvl)
	# FRACASO: con el hambre al tope el parásito deja de morder y te come → vuelve a PARASITISMO.
	if EvoManager.huesped_hunger >= 100.0:
		if EvoManager.huesped_starve_time == 0.0:
			UIManager.show_toast(TranslationServer.translate("TOAST_HUESPED_STARVE") % Balance.HUESPED_STARVE_TIME)
		EvoManager.huesped_starve_time += dt
		if EvoManager.huesped_starve_time >= Balance.HUESPED_STARVE_TIME:
			RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_HUESPED_FAIL"))
	else:
		EvoManager.huesped_starve_time = 0.0


static func _gift() -> void:
	var lvl := level()
	if lvl <= 0:
		return
	var amount: float = EconomyManager.get_delta_total() * Balance.HUESPED_GIFT_SECS_PER_LEVEL * lvl
	EconomyManager.money += amount
	EconomyManager.total_money_generated += amount


# ── Economía ─────────────────────────────────────────────────────────────────

## Trueque domesticado (EconomyManager): 1.0 fuera de la ruta.
static func trueque_mult() -> float:
	if not EvoManager.mutation_huesped_soberano:
		return 1.0
	return 1.0 + Balance.HUESPED_TRUEQUE_PER_LEVEL * level()

## Legado Pacto Soberano: la corrosión de Parasitismo avanza más lento en todas las runs.
static func corrosion_rate_mult() -> float:
	return Balance.HUESPED_PACT_CORROSION if LegacyManager.get_buff_value("legado_pacto_soberano") else 1.0


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and level() >= Balance.HUESPED_LEVELS.size()
