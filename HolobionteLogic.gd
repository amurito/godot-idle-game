class_name HolobionteLogic

## HOLOBIONTE — tier 3 de SIMBIOSIS (Biología, T ≥ 2). Verbo: SOSTENER UN ECOSISTEMA.
## "Ningún organismo es uno solo: el holobionte es el hongo más todo lo que vive en él."
## Spec: docs/design/biologia_mutualismo_endosimbiosis.md §5. Estado en EvoManager (holo_*);
## sólo funciones estáticas. Vive DENTRO de Mutualismo: las ofertas de la Raíz siguen corriendo
## (más espaciadas) y la llegada de cada socio nuevo es una oferta más ("socio_<id>").
##
##   · Entrada: Mutualismo sellable (confianza y R justa) → PRESENTAR SOCIOS en vez de sellar.
##   · Socios: Raíz (ya está) + Bacteria, Alga, Levadura (llegan cada HOLO_RECRUIT_INTERVAL s).
##   · Salud 0–100: necesidad cumplida +HEAL/s, incumplida −HURT/s. A 0 muere: pierde su bonus,
##     −3 confianza y su oferta de entrada vuelve a los HOLO_RESPAWN s.
##   · Necesidades cruzadas a propósito: Raíz pasivo ≥ 50 %, Bacteria ≥ 1 cps, Alga ε ≤ 0.30,
##     Levadura una compra cada 60 s.
##   · Sello: los 4 socios con salud ≥ HOLO_SEAL_HEALTH durante HOLO_SEAL_HOLD s seguidos.
##   · Colapso: HOLO_COLLAPSE_DEATHS muertes → la run cierra como MUTUALISMO.

const PARTNERS: Array = ["raiz", "bacteria", "alga", "levadura"]
const RECRUIT_ORDER: Array = ["bacteria", "alga", "levadura"]


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.holobionte_active and MutualismoLogic.is_active()

static func can_enter() -> bool:
	return LegacyManager.trascendencia_count >= Balance.HOLOBIONTE_MIN_T \
		and not EvoManager.holobionte_active and MutualismoLogic.seal_ready()

static func enter() -> void:
	if not can_enter():
		return
	EvoManager.holobionte_active = true
	EvoManager.holo_health = {"raiz": Balance.HOLO_JOIN_HEALTH}
	EvoManager.holo_respawn = {}
	EvoManager.holo_recruit_timer = Balance.HOLO_RECRUIT_INTERVAL
	EvoManager.holo_since_buy = 0.0
	LogManager.add(TranslationServer.translate("LOG_HOLOBIONTE_ON"))
	EvoManager.mutation_activated.emit("holobionte", TranslationServer.translate("MUT_HOLOBIONTE"))
	AchievementManager.on_mutation_activated("holobionte")
	UIManager.show_toast(TranslationServer.translate("TOAST_HOLOBIONTE_ON"))
	EvoManager._save_after_mutation()

static func alive(id: String) -> bool:
	return EvoManager.holobionte_active and EvoManager.holo_health.has(id)

static func health(id: String) -> float:
	return float(EvoManager.holo_health.get(id, 0.0))

static func alive_count() -> int:
	return EvoManager.holo_health.size()

## Coherencia: la salud del socio más débil (0 si falta alguno).
static func coherence() -> float:
	if alive_count() < PARTNERS.size():
		return 0.0
	var m := 100.0
	for id in PARTNERS:
		m = minf(m, health(id))
	return m


# ── Necesidades ──────────────────────────────────────────────────────────────

## Proporción pasiva del ingreso (la misma medida que el desglose activo/pasivo del panel).
static func passive_share() -> float:
	var b: Dictionary = EconomyManager.get_contribution_breakdown()
	return clampf(1.0 - float(b.get("click", 0.0)) / 100.0, 0.0, 1.0)

static func need_met(id: String) -> bool:
	match id:
		"raiz": return passive_share() >= Balance.HOLO_RAIZ_PASSIVE_SHARE
		"bacteria": return EvoManager.holo_cps >= Balance.HOLO_BACTERIA_CPS
		"alga": return StructuralModel.epsilon_runtime <= Balance.HOLO_ALGA_EPS
		"levadura": return EvoManager.holo_since_buy <= Balance.HOLO_LEVADURA_BUY_EVERY
	return false

## Valor actual de la necesidad, para el panel ("0.6/1 cps").
static func need_text(id: String) -> String:
	var T := func(k: String) -> String: return TranslationServer.translate(k)
	match id:
		"raiz": return T.call("HOLO_NEED_RAIZ") % [passive_share() * 100.0, Balance.HOLO_RAIZ_PASSIVE_SHARE * 100.0]
		"bacteria": return T.call("HOLO_NEED_BACTERIA") % [EvoManager.holo_cps, Balance.HOLO_BACTERIA_CPS]
		"alga": return T.call("HOLO_NEED_ALGA") % [StructuralModel.epsilon_runtime, Balance.HOLO_ALGA_EPS]
		"levadura": return T.call("HOLO_NEED_LEVADURA") % [EvoManager.holo_since_buy, Balance.HOLO_LEVADURA_BUY_EVERY]
	return ""


# ── Hooks ────────────────────────────────────────────────────────────────────

## Click manual (main): media móvil de clicks por segundo (τ = HOLO_CPS_TAU s).
static func on_click() -> void:
	if EvoManager.holobionte_active:
		EvoManager.holo_cps += 1.0 / Balance.HOLO_CPS_TAU

## Compra de mejora (UpgradeManager): la Levadura quiere que circule la plata.
static func on_purchase() -> void:
	if EvoManager.holobionte_active:
		EvoManager.holo_since_buy = 0.0


# ── Reclutamiento (ofertas "socio_<id>" del sistema de Mutualismo) ───────────

## Próximo socio por sumar (el primero del orden que no está ni esperando reaparecer).
static func next_recruit() -> String:
	for id in RECRUIT_ORDER:
		if not EvoManager.holo_health.has(id) and not EvoManager.holo_respawn.has(id):
			return id
	for id in EvoManager.holo_respawn:
		if float(EvoManager.holo_respawn[id]) <= 0.0:
			return id
	return ""

## Llamado por MutualismoLogic al abrir una oferta: si toca un socio, la oferta es su entrada.
static func pending_recruit_offer() -> String:
	if not is_active() or EvoManager.holo_recruit_timer > 0.0:
		return ""
	var id := next_recruit()
	return "socio_" + id if id != "" else ""

static func accept_recruit(offer: String) -> void:
	var id := offer.trim_prefix("socio_")
	EvoManager.holo_health[id] = Balance.HOLO_JOIN_HEALTH
	EvoManager.holo_respawn.erase(id)
	EvoManager.holo_recruit_timer = Balance.HOLO_RECRUIT_INTERVAL
	if id == "levadura":
		EvoManager.holo_since_buy = 0.0
	UIManager.show_toast(TranslationServer.translate("TOAST_HOLO_JOIN") % partner_name(id))

static func reject_recruit(_offer: String) -> void:
	EvoManager.holo_recruit_timer = Balance.HOLO_RECRUIT_INTERVAL


## Tick (fase de procesos de ruta, después de MutualismoLogic).
static func process(dt: float) -> void:
	if not is_active():
		return
	EvoManager.holo_cps -= EvoManager.holo_cps * minf(dt / Balance.HOLO_CPS_TAU, 1.0)
	EvoManager.holo_since_buy += dt
	EvoManager.holo_recruit_timer = maxf(EvoManager.holo_recruit_timer - dt, 0.0)
	for id in EvoManager.holo_respawn.keys():
		EvoManager.holo_respawn[id] = maxf(float(EvoManager.holo_respawn[id]) - dt, 0.0)
	for id in EvoManager.holo_health.keys():
		var h: float = float(EvoManager.holo_health[id])
		h += (Balance.HOLO_HEAL if need_met(id) else -Balance.HOLO_HURT) * dt
		if h <= 0.0:
			_die(id)
		else:
			EvoManager.holo_health[id] = minf(h, 100.0)
	if alive_count() == PARTNERS.size():
		var all90 := true
		for id in PARTNERS:
			if health(id) < 90.0:
				all90 = false
		if all90:
			EvoManager.holo_all90 = true
	if coherence() >= Balance.HOLO_SEAL_HEALTH:
		EvoManager.holo_coherence_time += dt
	else:
		EvoManager.holo_coherence_time = 0.0

static func _die(id: String) -> void:
	EvoManager.holo_health.erase(id)
	EvoManager.holo_respawn[id] = Balance.HOLO_RESPAWN
	EvoManager.holo_deaths += 1
	EvoManager.mutualismo_trust = maxi(EvoManager.mutualismo_trust - Balance.HOLO_DEATH_TRUST, 0)
	UIManager.show_toast(TranslationServer.translate("TOAST_HOLO_DEATH") % partner_name(id))
	# Salida: con demasiadas muertes el ecosistema se desarma y queda el pacto con la Raíz
	# (calibración 2026-10-16: sin esto, quien no atiende a los socios quedaba con la run trabada).
	if EvoManager.holo_deaths >= Balance.HOLO_COLLAPSE_DEATHS:
		RunManager.close_run("MUTUALISMO", TranslationServer.translate("CLOSE_HOLO_COLLAPSE"))


# ── Economía ─────────────────────────────────────────────────────────────────

static func click_mult() -> float:
	return Balance.HOLO_BACTERIA_MULT if alive("bacteria") and is_active() else 1.0

static func passive_mult() -> float:
	return Balance.HOLO_RAIZ_MULT if alive("raiz") and is_active() else 1.0

static func omega_bonus() -> float:
	return Balance.HOLO_ALGA_OMEGA if alive("alga") and is_active() else 0.0

static func cost_factor() -> float:
	return Balance.HOLO_LEVADURA_DISCOUNT if alive("levadura") and is_active() else 1.0


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and EvoManager.holo_coherence_time >= Balance.HOLO_SEAL_HOLD

static func partner_name(id: String) -> String:
	return TranslationServer.translate("HOLO_PARTNER_" + id.to_upper())
