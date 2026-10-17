class_name MutualismoLogic

## MUTUALISMO — tier 2 de SIMBIOSIS (Biología, T ≥ 1). Verbo: NEGOCIAR.
## "La micorriza: el hongo le da fósforo a la raíz; la raíz le paga con azúcar."
## Spec: docs/design/biologia_mutualismo_endosimbiosis.md §4. Estado en EvoManager (mutualismo_*);
## sólo funciones estáticas. Mutualismo vive DENTRO de Simbiosis (mutation_symbiosis sigue true).
##
##   · Entrada: Simbiosis activa ≥ MUTUALISMO_ENTRY_TIME s → botón ACEPTAR PACTO.
##   · Cada MUTUALISMO_OFFER_INTERVAL s el socio ofrece algo; MUTUALISMO_DECIDE_TIME s para [A]/[R].
##     Todo se mide en SEGUNDOS DE INGRESO (EconomyManager.get_delta_total()).
##   · Reciprocidad R = lo dado − lo recibido (en s de ingreso). Sello: confianza ≥ TRUST_SEAL y
##     |R| ≤ FAIR_BAND. R ≤ −BREAK → cierra como PARASITISMO; R ≥ +BREAK → cierra como SIMBIOSIS.
##   · Secuencia de ofertas fija (determinista, sin RNG), como los antojos de Huésped.

const OFFER_SEQ: Array = [
	"intercambio", "prestamo", "intercambio", "auxilio", "tentacion",
	"intercambio", "prestamo", "auxilio", "intercambio", "tentacion",
]


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutualismo_active and EvoManager.mutation_symbiosis and not RunManager.run_closed

## ¿Se puede aceptar el pacto ahora? (T ≥ 1, Simbiosis "pura": sin Coro, sin Simbiosis Mecánica).
static func can_enter() -> bool:
	return LegacyManager.trascendencia_count >= Balance.MUTUALISMO_MIN_T \
		and RouteManager.allows_bifurcation() and not RunManager.run_closed \
		and EvoManager.mutation_symbiosis and not EvoManager.mutualismo_active \
		and not EvoManager.endosimbiosis_active \
		and not EvoManager.mutation_coro_simbiotico \
		and EvoManager.red_branch_selected != EvoManager.RedBranch.SYMBIOSIS \
		and RunManager.run_time >= Balance.MUTUALISMO_ENTRY_TIME

static func enter() -> void:
	if not can_enter():
		return
	EvoManager.mutualismo_active = true
	EvoManager.mutualismo_trust = 0
	EvoManager.mutualismo_r = 0.0
	EvoManager.mutualismo_offer = ""
	EvoManager.mutualismo_offer_timer = Balance.MUTUALISMO_FIRST_OFFER
	LogManager.add(TranslationServer.translate("LOG_MUTUALISMO_ON"))
	EvoManager.mutation_activated.emit("mutualismo", TranslationServer.translate("MUT_MUTUALISMO"))
	AchievementManager.on_mutation_activated("mutualismo")
	UIManager.show_toast(TranslationServer.translate("TOAST_MUTUALISMO_ON"))
	EvoManager._save_after_mutation()

## Ingreso de referencia: 1 "segundo de ingreso".
static func income() -> float:
	return maxf(EconomyManager.get_delta_total(), 1.0)

static func next_offer_kind() -> String:
	var kind: String = OFFER_SEQ[posmod(EvoManager.mutualismo_offers, OFFER_SEQ.size())]
	# Un préstamo / auxilio a la vez: si hay uno pendiente, el socio ofrece un intercambio.
	if kind == "prestamo" and EvoManager.mutualismo_loan_due > 0.0:
		return "intercambio"
	if kind == "auxilio" and EvoManager.mutualismo_gratitude_due > 0.0:
		return "intercambio"
	return kind

## Segundos de ingreso que pide dar la oferta actual (0 si la oferta te da plata).
static func offer_give_secs() -> float:
	match EvoManager.mutualismo_offer:
		"intercambio": return Balance.MUTUALISMO_EXCHANGE_GIVE
		"auxilio": return Balance.MUTUALISMO_AID_GIVE
	return 0.0

## Si no te alcanza, das lo que tengas: el retorno y R se calculan sobre lo que diste de verdad
## (calibración 2026-10-16: exigir el monto entero dejaba fuera a quien gasta todo en mejoras).
static func can_accept() -> bool:
	return is_active() and EvoManager.mutualismo_offer != "" \
		and (offer_give_secs() <= 0.0 or EconomyManager.money > 0.0)

## Pacto sellable (también es la puerta a Holobionte). En Holobionte se sella el ecosistema, no el pacto.
static func seal_ready() -> bool:
	return is_active() and not EvoManager.holobionte_active \
		and EvoManager.mutualismo_trust >= Balance.MUTUALISMO_TRUST_SEAL \
		and absf(EvoManager.mutualismo_r) <= Balance.MUTUALISMO_FAIR_BAND


# ── [A] Aceptar / [R] Rechazar ───────────────────────────────────────────────

## Paga hasta `secs` de ingreso con la plata que haya. Devuelve los segundos pagados de verdad.
static func _pay(secs: float) -> float:
	var paid: float = minf(income() * secs, EconomyManager.money)
	EconomyManager.money -= paid
	var paid_secs: float = paid / income()
	EvoManager.mutualismo_r += paid_secs
	return paid_secs

static func _receive(secs: float) -> void:
	var amount: float = income() * secs
	EconomyManager.money += amount
	EconomyManager.total_money_generated += amount
	EvoManager.mutualismo_r -= secs

static func _trust(delta: int) -> void:
	EvoManager.mutualismo_trust = maxi(EvoManager.mutualismo_trust + delta, 0)

static func accept() -> void:
	if not can_accept():
		return
	if EvoManager.mutualismo_offer.begins_with("socio_"):
		HolobionteLogic.accept_recruit(EvoManager.mutualismo_offer)
		EvoManager.mutualismo_reject_streak = 0
		_close_offer(false)
		return
	match EvoManager.mutualismo_offer:
		"intercambio":
			var given: float = _pay(Balance.MUTUALISMO_EXCHANGE_GIVE)
			# El retorno llega como ×boost al ingreso, proporcional a lo dado; se acredita en R al
			# aceptar (trato justo). Boost de 30 s a ×1.5 = 15 s de ingreso.
			EvoManager.mutualismo_r -= given
			var frac: float = given / Balance.MUTUALISMO_EXCHANGE_GIVE
			EvoManager.mutualismo_boost_timer = maxf(EvoManager.mutualismo_boost_timer, Balance.MUTUALISMO_EXCHANGE_SECS * frac)
			_trust(1)
		"prestamo":
			_receive(Balance.MUTUALISMO_LOAN_GET)
			EvoManager.mutualismo_loan_due = Balance.MUTUALISMO_LOAN_TERM
			_trust(1)
		"auxilio":
			var aid: float = _pay(Balance.MUTUALISMO_AID_GIVE)
			EvoManager.mutualismo_gratitude_secs = aid * Balance.MUTUALISMO_AID_RETURN / Balance.MUTUALISMO_AID_GIVE
			EvoManager.mutualismo_gratitude_due = Balance.MUTUALISMO_AID_GRATITUDE_TIME
			_trust(2)
		"tentacion":
			_receive(Balance.MUTUALISMO_TEMPT_GET)
			_trust(-4)
			EvoManager.mutualismo_tempted += 1
	EvoManager.mutualismo_accepted += 1
	EvoManager.mutualismo_reject_streak = 0
	_close_offer()

static func reject() -> void:
	if not is_active() or EvoManager.mutualismo_offer == "":
		return
	if EvoManager.mutualismo_offer.begins_with("socio_"):
		HolobionteLogic.reject_recruit(EvoManager.mutualismo_offer)
		_close_offer(false)
		return
	# Rechazar la Tentación es lo correcto: no cuenta como desaire.
	if EvoManager.mutualismo_offer != "tentacion":
		if EvoManager.holobionte_active:
			EvoManager.holo_rejects += 1  # MYTHIC Nadie Muere: no rechazar nada en el ecosistema
		EvoManager.mutualismo_reject_streak += 1
		if EvoManager.mutualismo_reject_streak >= Balance.MUTUALISMO_REJECT_STREAK:
			EvoManager.mutualismo_reject_streak = 0
			_trust(-1)
			UIManager.show_toast(TranslationServer.translate("TOAST_MUTUALISMO_SNUB"))
	_close_offer()

## `advance`: las ofertas de socio (Holobionte) no avanzan la secuencia de la Raíz.
static func _close_offer(advance: bool = true) -> void:
	EvoManager.mutualismo_offer = ""
	EvoManager.mutualismo_decide_timer = 0.0
	if advance:
		EvoManager.mutualismo_offers += 1
	EvoManager.mutualismo_offer_timer = Balance.HOLO_OFFER_INTERVAL if EvoManager.holobionte_active else Balance.MUTUALISMO_OFFER_INTERVAL


## Tick (fase de procesos de ruta).
static func process(dt: float) -> void:
	if not is_active():
		return
	EvoManager.mutualismo_boost_timer = maxf(EvoManager.mutualismo_boost_timer - dt, 0.0)
	# Préstamo: el socio cobra al vencer. Sin plata suficiente: cobra lo que hay e incumplís.
	if EvoManager.mutualismo_loan_due > 0.0:
		EvoManager.mutualismo_loan_due -= dt
		if EvoManager.mutualismo_loan_due <= 0.0:
			EvoManager.mutualismo_loan_due = 0.0
			# Sin plata suficiente: cobra lo que hay e incumplís.
			var paid: float = _pay(Balance.MUTUALISMO_LOAN_PAY)
			if paid >= Balance.MUTUALISMO_LOAN_PAY - 0.01:
				EvoManager.mutualismo_loans_paid += 1
				if EvoManager.mutualismo_loans_paid >= Balance.ACH_BUEN_PAGADOR_LOANS:
					AchievementManager.unlock("buen_pagador")
				UIManager.show_toast(TranslationServer.translate("TOAST_MUTUALISMO_LOAN_PAID"))
			else:
				_trust(-3)
				EvoManager.mutualismo_defaulted = true
				UIManager.show_toast(TranslationServer.translate("TOAST_MUTUALISMO_DEFAULT"))
	# Auxilio: la gratitud llega después.
	if EvoManager.mutualismo_gratitude_due > 0.0:
		EvoManager.mutualismo_gratitude_due -= dt
		if EvoManager.mutualismo_gratitude_due <= 0.0:
			EvoManager.mutualismo_gratitude_due = 0.0
			# La gratitud salda lo dado en la reciprocidad; el 0.5× extra es premio, no deuda
			# (calibración 2026-10-16: contarlo entero hacía derivar R hacia la ruptura en runs largas).
			_receive(EvoManager.mutualismo_gratitude_secs)
			EvoManager.mutualismo_r += EvoManager.mutualismo_gratitude_secs - EvoManager.mutualismo_gratitude_secs * Balance.MUTUALISMO_AID_GIVE / Balance.MUTUALISMO_AID_RETURN
			UIManager.show_toast(TranslationServer.translate("TOAST_MUTUALISMO_GRATITUDE"))
	# Ofertas.
	if EvoManager.mutualismo_offer == "":
		EvoManager.mutualismo_offer_timer -= dt
		if EvoManager.mutualismo_offer_timer <= 0.0:
			var recruit: String = HolobionteLogic.pending_recruit_offer()
			EvoManager.mutualismo_offer = recruit if recruit != "" else next_offer_kind()
			EvoManager.mutualismo_decide_timer = Balance.MUTUALISMO_DECIDE_TIME
			UIManager.show_toast(TranslationServer.translate("TOAST_MUTUALISMO_OFFER") % offer_name(EvoManager.mutualismo_offer))
	else:
		EvoManager.mutualismo_decide_timer -= dt
		if EvoManager.mutualismo_decide_timer <= 0.0:
			reject()  # no decidir = rechazar
	_check_break()


## Ruptura del pacto: abusar → el socio se vuelve presa (PARASITISMO); ser explotado → SIMBIOSIS.
static func _check_break() -> void:
	if EvoManager.mutualismo_r <= -Balance.MUTUALISMO_BREAK:
		RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_MUTUALISMO_TRAICION"))
	elif EvoManager.mutualismo_r >= Balance.MUTUALISMO_BREAK:
		RunManager.close_run("SIMBIOSIS", TranslationServer.translate("CLOSE_MUTUALISMO_EXPLOTADO"))


# ── Economía ─────────────────────────────────────────────────────────────────

## Retorno del Intercambio: ×boost a todo el ingreso mientras dura.
static func income_mult() -> float:
	if EvoManager.mutualismo_boost_timer > 0.0 and is_active():
		return Balance.MUTUALISMO_EXCHANGE_MULT
	return 1.0


# ── Textos ───────────────────────────────────────────────────────────────────

static func offer_name(kind: String) -> String:
	if kind.begins_with("socio_"):
		return TranslationServer.translate("HOLO_OFFER_RECRUIT") % HolobionteLogic.partner_name(kind.trim_prefix("socio_"))
	return TranslationServer.translate("MUTUALISMO_OFFER_" + kind.to_upper())

## Descripción corta de la oferta: lo que das / lo que recibís, en $ actuales.
static func offer_desc(kind: String) -> String:
	var f := func(secs: float) -> String: return "$" + UITextBuilders.format_compact(income() * secs)
	if kind.begins_with("socio_"):
		var id: String = kind.trim_prefix("socio_")
		return TranslationServer.translate("HOLO_DESC_" + id.to_upper())
	match kind:
		"intercambio":
			return TranslationServer.translate("MUTUALISMO_DESC_INTERCAMBIO") % [f.call(Balance.MUTUALISMO_EXCHANGE_GIVE), Balance.MUTUALISMO_EXCHANGE_MULT, Balance.MUTUALISMO_EXCHANGE_SECS]
		"prestamo":
			return TranslationServer.translate("MUTUALISMO_DESC_PRESTAMO") % [f.call(Balance.MUTUALISMO_LOAN_GET), f.call(Balance.MUTUALISMO_LOAN_PAY), Balance.MUTUALISMO_LOAN_TERM]
		"auxilio":
			return TranslationServer.translate("MUTUALISMO_DESC_AUXILIO") % [f.call(Balance.MUTUALISMO_AID_GIVE), f.call(Balance.MUTUALISMO_AID_RETURN), Balance.MUTUALISMO_AID_GRATITUDE_TIME]
		"tentacion":
			return TranslationServer.translate("MUTUALISMO_DESC_TENTACION") % f.call(Balance.MUTUALISMO_TEMPT_GET)
	return ""
