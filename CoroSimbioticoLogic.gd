class_name CoroSimbioticoLogic

## CORO SIMBIÓTICO — Transmutación (A → A+) de SIMBIOSIS. Verbo: RITMO (a tiempo, no rápido).
## "La cooperación deja de ser un pacto y se vuelve un ritmo."
## Spec: docs/design/involucion_transmutaciones.md §10.2. Se entra por el botón [T]
## (TransmutationLogic). Estado en EvoManager (coro_*); sólo funciones estáticas.
##
##   · Metrónomo: el núcleo late a un tempo (BPM del movimiento actual). El reloj es
##     RunManager.run_time (avanza por frame: determinista en el simulador) desde coro_anchor.
##   · SÓLO LOS ACENTOS (rework 2026-10-17, el autor lo sentía largo y tedioso): se juzga el primer
##     golpe de cada compás (1 de CORO_BEATS_PER_BAR). Alrededor de cada acento hay una zona de ±medio
##     golpe: el PRIMER click en la zona se juzga (±CORO_HIT_WINDOW s = acierto, combo +CORO_ACCENT_COMBO;
##     si no, combo a la mitad). Fuera de las zonas se clickea libre. Acento salteado: −CORO_SKIP_DECAY.
##   · La PARTITURA (sello) pide CORO_MOVEMENT_BARS acentos acertados en cada movimiento (I Andante,
##     II Moderato, III Allegro); fallar corta el combo pero no borra los acentos ya tocados.
##   · Con Coro: ingreso × (1 + CORO_COMBO_BONUS · combo), combo tope CORO_COMBO_CAP.
##   · Legado Compás Interno (todas las runs, sin Coro): metrónomo suave a CORO_LEGACY_TEMPO;
##     cada golpe a tiempo seguido suma +CORO_LEGACY_BONUS al click (tope CORO_LEGACY_CAP).

## Último juicio de un click (para el feedback visual del anillo): ms de reloj real y si fue golpe.
static var last_judge_ms: int = -1
static var last_judge_hit: bool = false


static func activate() -> void:
	if EvoManager.mutation_coro_simbiotico:
		return
	EvoManager.mutation_coro_simbiotico = true
	_reanchor(RunManager.run_time)
	EvoManager.coro_movement = 0
	EvoManager.coro_bars = 0
	LogManager.add(TranslationServer.translate("LOG_CORO_EFFECTS"))
	EvoManager.mutation_activated.emit("coro_simbiotico", TranslationServer.translate("MUT_CORO_SIMBIOTICO"))
	AchievementManager.on_mutation_activated("coro_simbiotico")
	UIManager.show_toast(TranslationServer.translate("TOAST_CORO_ON"))
	EvoManager._save_after_mutation()


## Digestión de Simbiosis: el pacto se vuelve combo inicial (se va si no lo sostenés).
static func digest_simbiosis() -> String:
	EvoManager.coro_combo = maxi(EvoManager.coro_combo, Balance.CORO_DIGEST_COMBO)
	return TranslationServer.translate("TRANSMUT_DIGEST_STACKS") % Balance.CORO_DIGEST_COMBO


# ── Metrónomo ────────────────────────────────────────────────────────────────

## BPM vigente (0 = no hay metrónomo esta run).
static func tempo() -> float:
	if RunManager.run_closed:
		return 0.0
	if EvoManager.mutation_coro_simbiotico:
		return Balance.CORO_TEMPOS[mini(EvoManager.coro_movement, Balance.CORO_TEMPOS.size() - 1)]
	if LegacyManager.get_buff_value("legado_compas_interno"):
		return Balance.CORO_LEGACY_TEMPO
	return 0.0

static func period() -> float:
	var bpm := tempo()
	return 60.0 / bpm if bpm > 0.0 else 0.0

## Posición en el compás de metrónomo: índice de golpe (con decimales) desde el ancla.
static func beat_pos(t: float) -> float:
	var p := period()
	return (t - EvoManager.coro_anchor) / p if p > 0.0 else 0.0

## Fase 0..1 hacia el próximo golpe (0 = en el golpe). Para el anillo y el latido.
static func beat_phase() -> float:
	return fposmod(beat_pos(RunManager.run_time), 1.0)

## El golpe k arranca un compás (acento del metrónomo).
static func is_downbeat(k: int) -> bool:
	return posmod(k, Balance.CORO_BEATS_PER_BAR) == 0

static func _reanchor(t: float) -> void:
	EvoManager.coro_anchor = t
	EvoManager.coro_last_hit_beat = 0
	EvoManager.coro_last_closed_beat = 0
	EvoManager.coro_bar_hits = 0


## Golpe (índice) del acento más cercano a t.
static func nearest_accent(t: float) -> int:
	var bpb: int = Balance.CORO_BEATS_PER_BAR
	return roundi(beat_pos(t) / float(bpb)) * bpb

## Cada click del jugador (main.on_reactor_click). Sólo se juzga el primer click en la zona de un acento.
static func on_click() -> void:
	var p := period()
	if p <= 0.0:
		return
	var t: float = RunManager.run_time
	var a: int = nearest_accent(t)
	var off: float = t - (EvoManager.coro_anchor + a * p)
	if absf(off) > p * 0.5 or a <= EvoManager.coro_last_hit_beat:
		return  # fuera de la zona del acento, o este acento ya se juzgó: click libre
	EvoManager.coro_last_hit_beat = a
	var hit: bool = absf(off) <= Balance.CORO_HIT_WINDOW
	last_judge_ms = Time.get_ticks_msec()
	last_judge_hit = hit
	if hit:
		EvoManager.coro_fail_streak = 0
		EvoManager.coro_combo = mini(EvoManager.coro_combo + Balance.CORO_ACCENT_COMBO, Balance.CORO_COMBO_CAP)
		EvoManager.coro_peak_combo = maxi(EvoManager.coro_peak_combo, EvoManager.coro_combo)
		if EvoManager.mutation_coro_simbiotico:
			_bar_done(EvoManager.coro_anchor + a * p)
	else:
		EvoManager.coro_combo = int(EvoManager.coro_combo / 2.0)
		if EvoManager.mutation_coro_simbiotico:
			_fail_accent()
			EvoManager.coro_misses += 1
			if EvoManager.coro_movement == Balance.CORO_MOVEMENT_BARS.size() - 1:
				EvoManager.coro_allegro_misses += 1


static func _bar_done(beat_time: float) -> void:
	var n_mov: int = Balance.CORO_MOVEMENT_BARS.size()
	if EvoManager.coro_movement >= n_mov:
		return
	EvoManager.coro_bars += 1
	if EvoManager.coro_bars < Balance.CORO_MOVEMENT_BARS[EvoManager.coro_movement]:
		return
	EvoManager.coro_movement += 1
	EvoManager.coro_bars = 0
	if EvoManager.coro_movement >= n_mov:
		UIManager.show_toast(TranslationServer.translate("TOAST_CORO_SCORE_DONE"))
		LogManager.add(TranslationServer.translate("TOAST_CORO_SCORE_DONE"))
		return
	# Cambio de tempo: el golpe recién tocado pasa a ser el golpe 0 del nuevo movimiento.
	_reanchor(beat_time)
	var mov_name := TranslationServer.translate("CORO_MOVEMENT_%d" % EvoManager.coro_movement)
	UIManager.show_toast(TranslationServer.translate("TOAST_CORO_MOVEMENT") % [mov_name, int(tempo())])


## Tick (fase de procesos de ruta): acentos cuya zona cerró sin ningún click.
static func process(_dt: float) -> void:
	var p := period()
	if p <= 0.0:
		return
	var closed: int = floori((RunManager.run_time - EvoManager.coro_anchor) / p - 0.5)
	var first: int = maxi(EvoManager.coro_last_closed_beat + 1, closed - 64)
	for k in range(first, closed + 1):
		if not is_downbeat(k) or k <= EvoManager.coro_last_hit_beat:
			continue
		EvoManager.coro_combo = maxi(EvoManager.coro_combo - Balance.CORO_SKIP_DECAY, 0)
		if EvoManager.mutation_coro_simbiotico and not score_done():
			_fail_accent()
	EvoManager.coro_last_closed_beat = maxi(EvoManager.coro_last_closed_beat, closed)


## FRACASO: CORO_FAIL_STREAK acentos seguidos sin acertar → el ritmo se rompe → vuelve a SIMBIOSIS.
static func _fail_accent() -> void:
	if RunManager.run_closed:
		return
	EvoManager.coro_fail_streak += 1
	if EvoManager.coro_fail_streak == Balance.CORO_FAIL_STREAK - 3:
		UIManager.show_toast(TranslationServer.translate("TOAST_CORO_FAIL_WARN") % (Balance.CORO_FAIL_STREAK - EvoManager.coro_fail_streak))
	if EvoManager.coro_fail_streak >= Balance.CORO_FAIL_STREAK:
		RunManager.close_run("SIMBIOSIS", TranslationServer.translate("CLOSE_CORO_FAIL"))


# ── Economía (IncomeModifiers) ───────────────────────────────────────────────

static func rhythm_mult() -> float:
	if not EvoManager.mutation_coro_simbiotico:
		return 1.0
	return 1.0 + Balance.CORO_COMBO_BONUS * EvoManager.coro_combo

## Legado Compás Interno: sólo click, en todas las runs sin Coro.
static func echo_mult() -> float:
	if EvoManager.mutation_coro_simbiotico or not LegacyManager.get_buff_value("legado_compas_interno"):
		return 1.0
	return 1.0 + minf(Balance.CORO_LEGACY_BONUS * EvoManager.coro_combo, Balance.CORO_LEGACY_CAP)


# ── Sello ────────────────────────────────────────────────────────────────────

static func score_done() -> bool:
	return EvoManager.coro_movement >= Balance.CORO_MOVEMENT_BARS.size()

static func seal_ready() -> bool:
	return EvoManager.mutation_coro_simbiotico and not RunManager.run_closed and score_done()
