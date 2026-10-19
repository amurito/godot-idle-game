class_name AutosuficienciaLogic

## AUTOSUFICIENCIA — SOMBRA de PARASITISMO. Verbo: CULTIVAR.
## "Parasitismo es depender del sistema y drenarlo. Autosuficiencia es no depender de nada."
## Spec: docs/design/sombras.md §6 y §12. Estado en EvoManager (auto_*); sólo funciones estáticas.
##
##   · Espejo (sin botón): con la llave, habiendo tenido Parasitismo latente en la run, clickeando,
##     con biomasa ≥ AUTO_MIRROR_BIO y plata para comprar (≥ AUTO_MIRROR_RICH × la mejora más barata)
##     pero SIN comprar (AUTO_MIRROR_NO_BUY s desde la última compra): acumular AUTO_MIRROR_TIME s.
##     Exige actividad a propósito: un AFK va a Parasitismo, no acá (lección de Ayuno).
##   · Mercado cerrado: los botones de mejora CULTIVAN (UpgradeManager.purchase_upgrade lo redirige):
##     cuesta NUTRIENTES y tarda AUTO_CULT_TIME s; un cultivo a la vez. Los nutrientes son el límite
##     (salen del estrés absorbido: clickear sube ε y llena el sustrato).
##   · [W] Fermentar: plata → nutrientes (acelera), pero suma OLOR (AUTO_FERMENT_SCENT, baja solo):
##     a AUTO_SCENT_FAIL el parásito vuelve. Decisión: cuánto acelerar sin atraerlo.
##   · Sello: AUTO_SEAL_LEVELS niveles cultivados. Fracaso (→ PARASITISMO): el olor llega al límite o
##     AUTO_PARASITE_IDLE s sin clickear (el propio disparador de inactividad del parásito).


# ── Espejo ───────────────────────────────────────────────────────────────────

static func mirror_open() -> bool:
	return not EvoManager.mutation_autosuficiencia and LegacyManager.get_buff_level("sombra_autosuficiencia") > 0 \
		and EvoManager.auto_paras_seen and not InestabilidadLogic._route_taken() and not RunManager.run_closed

static func cheapest_cost() -> float:
	var best: float = INF
	for id in UpgradeManager.states:
		var s: Dictionary = UpgradeManager.states[id]
		if not s.get("unlocked", false) or not UpgradeManager.conditional_unlock_ok(id):
			continue
		var def = UpgradeManager.get_def(id)
		if def == null or (def.one_shot and int(s.level) > 0):
			continue
		best = minf(best, UpgradeManager.cost(id))
	return best

## Condición del momento (sin la llave/ruta): activo, con biomasa, con plata y sin comprar.
static func mirror_condition() -> bool:
	return EconomyManager.time_since_last_click < Balance.AUTO_MIRROR_CLICK \
		and BiosphereEngine.biomasa >= Balance.AUTO_MIRROR_BIO \
		and RunManager.run_time - EvoManager._auto_last_buy_t >= Balance.AUTO_MIRROR_NO_BUY \
		and EconomyManager.money >= cheapest_cost() * Balance.AUTO_MIRROR_RICH

## update_genome (cada logic tick).
static func update_mirror(_ctx: Dictionary) -> void:
	if not EvoManager.auto_paras_seen and EvoManager.genome.get("parasitismo", "") == "latente":
		EvoManager.auto_paras_seen = true
	if not mirror_open():
		EvoManager.auto_mirror_time = 0.0
		EvoManager._auto_mirror_countdown_last = -1
		return
	if not mirror_condition():
		EvoManager.auto_mirror_time = maxf(EvoManager.auto_mirror_time - RunManager.LOGIC_TICK * Balance.AUTO_MIRROR_DECAY, 0.0)
		EvoManager._auto_mirror_countdown_last = -1
		return
	EvoManager.auto_mirror_time += RunManager.LOGIC_TICK
	if EvoManager.auto_mirror_time >= Balance.AUTO_MIRROR_TIME:
		EvoManager._auto_mirror_countdown_last = -1
		activate()
		return
	var left: float = Balance.AUTO_MIRROR_TIME - EvoManager.auto_mirror_time
	if left > Balance.INEST_MIRROR_WARN:
		return
	var secs_left := int(ceil(left))
	if secs_left != EvoManager._auto_mirror_countdown_last:
		EvoManager._auto_mirror_countdown_last = secs_left
		UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_MIRROR_WARN") % secs_left)

## UpgradeManager.purchase_upgrade (compra con plata exitosa): reinicia el "sin comprar" del espejo.
static func on_purchase() -> void:
	EvoManager._auto_last_buy_t = RunManager.run_time

static func activate() -> void:
	if EvoManager.mutation_autosuficiencia:
		return
	EvoManager.mutation_autosuficiencia = true
	EvoManager.auto_mirror_time = 0.0
	EvoManager._set_genome_state("parasitismo", "bloqueado")
	LogManager.add(TranslationServer.translate("LOG_AUTO_EFFECTS"))
	EvoManager.mutation_activated.emit("autosuficiencia", TranslationServer.translate("MUT_AUTOSUFICIENCIA"))
	AchievementManager.on_mutation_activated("autosuficiencia")
	UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_ON"))
	EvoManager._save_after_mutation()


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutation_autosuficiencia and not RunManager.run_closed

static func cultivating() -> bool:
	return EvoManager.auto_cult_id != ""

## Nutrientes que cuesta el próximo cultivo (suben con cada nivel cultivado).
static func cult_cost() -> float:
	return Balance.AUTO_CULT_NUT * pow(Balance.AUTO_CULT_NUT_GROWTH, EvoManager.auto_levels)

static func can_cultivate(id: String) -> bool:
	if not is_active() or cultivating() or BiosphereEngine.nutrientes < cult_cost():
		return false
	var s: Dictionary = UpgradeManager.states.get(id, {})
	if s.is_empty() or not s.get("unlocked", false) or not UpgradeManager.conditional_unlock_ok(id):
		return false
	var def = UpgradeManager.get_def(id)
	return def != null and not (def.one_shot and int(s.level) > 0)


# ── Cultivar (los botones de mejora, redirigidos) ────────────────────────────

## UpgradeManager.purchase_upgrade llama acá durante la Sombra: el botón cultiva en vez de comprar.
static func cultivate(id: String) -> void:
	if not can_cultivate(id):
		if is_active():
			if cultivating():
				UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_BUSY") % EvoManager.auto_cult_timer)
			elif BiosphereEngine.nutrientes < cult_cost():
				UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_NO_BIO") % [cult_cost(), BiosphereEngine.nutrientes])
		return
	BiosphereEngine.nutrientes -= cult_cost()
	EvoManager.auto_cult_id = id
	EvoManager.auto_cult_timer = Balance.AUTO_CULT_TIME
	UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_CULT") % [UpgradeManager.get_def(id).label, Balance.AUTO_CULT_TIME])

static func _harvest() -> void:
	var id: String = EvoManager.auto_cult_id
	EvoManager.auto_cult_id = ""
	EvoManager.auto_cult_timer = 0.0
	# Sube un nivel sin plata (buy() aplica el escalado de costo como cualquier compra).
	if UpgradeManager.buy(id, INF):
		UpgradeManager.apply_bought_effects(id)
		UpgradeManager.upgrade_bought.emit(id)
		EvoManager.auto_levels += 1
		EvoManager.auto_kinds[id] = true
		if EvoManager.auto_kinds.size() >= Balance.ACH_AUTO_POLY:
			AchievementManager.unlock("policultivo")
		UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_HARVEST") % [UpgradeManager.get_def(id).label,
			EvoManager.auto_levels, Balance.AUTO_SEAL_LEVELS])


# ── [W] Fermentar ────────────────────────────────────────────────────────────

static func ferment_cost() -> float:
	return maxf(EconomyManager.get_delta_total(), 1.0) * Balance.AUTO_FERMENT_SECS

static func can_ferment() -> bool:
	return is_active() and EvoManager.auto_ferment_cd <= 0.0 and EconomyManager.money >= ferment_cost()

## La puerta de salida del mercado: plata → nutrientes (con olor).
static func ferment() -> void:
	if not can_ferment():
		return
	EconomyManager.money -= ferment_cost()
	BiosphereEngine.nutrientes += Balance.AUTO_FERMENT_NUT
	EvoManager.auto_ferment_cd = Balance.AUTO_FERMENT_CD
	EvoManager.auto_ferments += 1
	EvoManager.auto_scent += Balance.AUTO_FERMENT_SCENT
	if EvoManager.auto_scent >= Balance.AUTO_SCENT_FAIL:
		RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_AUTO_SCENT"))
		return
	if EvoManager.auto_scent >= Balance.AUTO_SCENT_FAIL * 0.6:
		UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_SCENT_WARN") % [EvoManager.auto_scent, Balance.AUTO_SCENT_FAIL])
		return
	UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_FERMENT") % Balance.AUTO_FERMENT_NUT)


# ── Tick ─────────────────────────────────────────────────────────────────────

static func process(dt: float) -> void:
	if not is_active():
		return
	EvoManager.auto_ferment_cd = maxf(EvoManager.auto_ferment_cd - dt, 0.0)
	EvoManager.auto_scent = maxf(EvoManager.auto_scent - Balance.AUTO_SCENT_DECAY * dt, 0.0)
	if cultivating():
		EvoManager.auto_cult_timer -= dt
		if EvoManager.auto_cult_timer <= 0.0:
			_harvest()
	# FRACASO: el parásito vuelve con su propio disparador (inactividad).
	var idle: float = EconomyManager.time_since_last_click
	if idle >= Balance.AUTO_PARASITE_IDLE:
		RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_AUTO_PARASITE"))
		return
	var left := int(ceil(Balance.AUTO_PARASITE_IDLE - idle))
	if left <= 20 and left != EvoManager._auto_idle_warned:
		EvoManager._auto_idle_warned = left
		if left in [20, 10, 5, 3, 2, 1]:
			UIManager.show_toast(TranslationServer.translate("TOAST_AUTO_IDLE_WARN") % left)
	elif left > 20:
		EvoManager._auto_idle_warned = -1


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and EvoManager.auto_levels >= Balance.AUTO_SEAL_LEVELS


# ── Legado Despensa Propia (cualquier run) ───────────────────────────────────

## La mejora más barata disponible (la que cultiva el legado).
static func cheapest_id() -> String:
	var best: float = INF
	var out := ""
	for id in UpgradeManager.states:
		var s: Dictionary = UpgradeManager.states[id]
		if not s.get("unlocked", false) or not UpgradeManager.conditional_unlock_ok(id):
			continue
		var def = UpgradeManager.get_def(id)
		if def == null or (def.one_shot and int(s.level) > 0):
			continue
		if UpgradeManager.cost(id) < best:
			best = UpgradeManager.cost(id)
			out = id
	return out

static func despensa_available() -> bool:
	return LegacyManager.get_buff_value("legado_despensa_propia") and not EvoManager.mutation_autosuficiencia \
		and not RunManager.run_closed and RunManager.run_time - EvoManager._despensa_last_t >= Balance.AUTO_DESPENSA_CD \
		and BiosphereEngine.biomasa >= Balance.AUTO_DESPENSA_BIO and cheapest_id() != ""

## Un nivel gratis de la mejora más barata, pagado con biomasa (cooldown largo).
static func use_despensa() -> void:
	if not despensa_available():
		return
	var id := cheapest_id()
	BiosphereEngine.biomasa -= Balance.AUTO_DESPENSA_BIO
	EvoManager._despensa_last_t = RunManager.run_time
	if UpgradeManager.buy(id, INF):
		UpgradeManager.apply_bought_effects(id)
		UpgradeManager.upgrade_bought.emit(id)
		UIManager.show_toast(TranslationServer.translate("TOAST_DESPENSA_USED") % UpgradeManager.get_def(id).label)
