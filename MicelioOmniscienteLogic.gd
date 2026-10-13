class_name MicelioOmniscienteLogic

## MICELIO OMNISCIENTE — Transmutación (A → A+) de RED MICELIAL. Verbo: ASIGNAR.
## "La red deja de crecer hacia afuera y empieza a verlo todo desde adentro."
## Spec: docs/design/involucion_transmutaciones.md §10.3. Se entra por el botón [T]
## (TransmutationLogic). Estado en EvoManager (micelio_*); sólo funciones estáticas.
##
##   · Presupuesto: el micelio libre crece MICELIO_GROW_PER_HIFA·hifas /s mientras
##     libre + conectado < tope (MICELIO_CAP_BASE + MICELIO_CAP_PER_HIFA·hifas).
##   · Nodos = los 9 upgrades numerados. Click derecho conecta MICELIO_NODE_STEP (máx.
##     MICELIO_NODE_MAX por nodo); Shift + click derecho desconecta (vuelve al presupuesto).
##   · Cada nodo: lo que aportan sus niveles × (1 + conexión/máx) y costo −MICELIO_NODE_DISCOUNT
##     por punto. Un nodo lleno se AUTOCOMPRA cuando alcanza la plata (la red lo ve).
##   · Deriva: el micelio libre fluye solo, 1 punto cada MICELIO_DRIFT_INTERVAL s, al nodo más
##     comprado que no esté lleno (AFK funciona, peor que planificar).
##   · Sello: los 9 nodos llenos sostenidos MICELIO_SEAL_HOLD s.
##   · Legado Nodo Latente: el primer nodo que llenaste queda ×MICELIO_LATENT_MULT en todas las runs.

## Los 9 upgrades numerados (mismo orden que las teclas 1-9).
const NODES := ["click", "auto", "trueque", "click_mult", "auto_mult", "trueque_net",
	"specialization", "cognitive", "accounting"]

## true mientras la red se autocompra (UpgradeManager.purchase_upgrade no lo cuenta como compra a mano).
static var _autobuying := false


static func activate() -> void:
	if EvoManager.mutation_micelio_omnisciente:
		return
	EvoManager.mutation_micelio_omnisciente = true
	# Pierde la bifurcación de Red Micelial: la rama elegida (si hubo) se deshace.
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		EconomyManager.mutation_auto_factor /= 1.5
	EvoManager.red_branch_selected = EvoManager.RedBranch.NONE
	EvoManager.red_micelial_phase = 0
	var main := EvoManager.get_tree().get_first_node_in_group("main")
	if is_instance_valid(main) and main.has_method("hide_evo_choice_panel"):
		main.hide_evo_choice_panel()
	LogManager.add(TranslationServer.translate("LOG_MICELIO_EFFECTS"))
	EvoManager.mutation_activated.emit("micelio_omnisciente", TranslationServer.translate("MUT_MICELIO_OMNISCIENTE"))
	AchievementManager.on_mutation_activated("micelio_omnisciente")
	UIManager.show_toast(TranslationServer.translate("TOAST_MICELIO_ON"))
	EvoManager._save_after_mutation()


## Digestión de Red Micelial: la red que creció hacia afuera queda como presupuesto inicial.
static func digest_red_micelial() -> String:
	EvoManager.micelio_pool = maxf(BiosphereEngine.micelio, Balance.MICELIO_DIGEST_POOL)
	return TranslationServer.translate("TRANSMUT_DIGEST_MICELIO") % int(EvoManager.micelio_pool)


## Red Micelial deja de poder transmutarse cuando arrancó el ciclo biológico (punto sin retorno).
static func revert_blocked() -> bool:
	return EvoManager.primordio_active or EvoManager.seta_formada


# ── Presupuesto y nodos ──────────────────────────────────────────────────────

static func connection(id: String) -> float:
	return float(EvoManager.micelio_nodes.get(id, 0.0))

static func connected_total() -> float:
	var total := 0.0
	for id in EvoManager.micelio_nodes:
		total += float(EvoManager.micelio_nodes[id])
	return total

static func cap() -> float:
	return Balance.MICELIO_CAP_BASE + Balance.MICELIO_CAP_PER_HIFA * BiosphereEngine.hifas

static func growth_rate() -> float:
	return Balance.MICELIO_GROW_PER_HIFA * BiosphereEngine.hifas

static func full_nodes() -> int:
	var n := 0
	for id in NODES:
		if connection(id) >= Balance.MICELIO_NODE_MAX:
			n += 1
	return n

static func is_active() -> bool:
	return EvoManager.mutation_micelio_omnisciente and not RunManager.run_closed

static func can_assign(id: String) -> bool:
	return is_active() and id in NODES and UpgradeManager.is_unlocked(id) \
		and EvoManager.micelio_pool >= 1.0 and connection(id) < Balance.MICELIO_NODE_MAX

## Click derecho: conecta hasta MICELIO_NODE_STEP de micelio libre al nodo.
static func assign(id: String) -> bool:
	if not can_assign(id):
		return false
	var amount: float = minf(minf(Balance.MICELIO_NODE_STEP, EvoManager.micelio_pool),
		Balance.MICELIO_NODE_MAX - connection(id))
	_connect(id, amount)
	return true

## Shift + click derecho: desconecta hasta MICELIO_NODE_STEP (cuenta para el MYTHIC).
static func unassign(id: String) -> bool:
	if not is_active() or connection(id) <= 0.0:
		return false
	var amount: float = minf(Balance.MICELIO_NODE_STEP, connection(id))
	EvoManager.micelio_nodes[id] = connection(id) - amount
	EvoManager.micelio_pool += amount
	EvoManager.micelio_disconnects += 1
	return true

static func _connect(id: String, amount: float) -> void:
	EvoManager.micelio_pool -= amount
	EvoManager.micelio_nodes[id] = connection(id) + amount
	EvoManager.micelio_peak_network = maxf(EvoManager.micelio_peak_network, connected_total())
	if EvoManager.micelio_first_full == "" and connection(id) >= Balance.MICELIO_NODE_MAX:
		EvoManager.micelio_first_full = id


## Tick (fase de procesos de ruta).
static func process(dt: float) -> void:
	if not is_active():
		return
	# Crecimiento del presupuesto hasta el tope (libre + conectado).
	var room: float = cap() - EvoManager.micelio_pool - connected_total()
	if room > 0.0:
		EvoManager.micelio_pool += minf(growth_rate() * dt, room)
	# Deriva: el micelio libre fluye solo al nodo más comprado que no esté lleno.
	EvoManager.micelio_drift_timer += dt
	if EvoManager.micelio_drift_timer >= Balance.MICELIO_DRIFT_INTERVAL:
		EvoManager.micelio_drift_timer = 0.0
		if EvoManager.micelio_pool >= 1.0:
			var target := ""
			var best_lvl := -1
			for id in NODES:
				if connection(id) < Balance.MICELIO_NODE_MAX and UpgradeManager.is_unlocked(id) \
						and UpgradeManager.level(id) > best_lvl:
					best_lvl = UpgradeManager.level(id)
					target = id
			if target != "":
				_connect(target, 1.0)
	# Los nodos llenos se autocompran (uno por nodo por tick).
	for id in NODES:
		if connection(id) >= Balance.MICELIO_NODE_MAX and UpgradeManager.can_buy(id, EconomyManager.money):
			_autobuying = true
			UpgradeManager.purchase_upgrade(id)
			_autobuying = false
	# Sello: red completa sostenida.
	if full_nodes() >= NODES.size():
		EvoManager.micelio_full_time += dt
	else:
		EvoManager.micelio_full_time = 0.0


# ── Economía (UpgradeManager.value / cost, EconomyManager, StructuralModel) ──

## Multiplicador de lo que aportan los niveles de un upgrade (1.0 = sin cambio).
static func node_factor(id: String) -> float:
	var k := 1.0
	if EvoManager.mutation_micelio_omnisciente:
		k += Balance.MICELIO_NODE_BONUS * connection(id) / Balance.MICELIO_NODE_MAX
	elif LegacyManager.get_buff_value("legado_nodo_latente") and LegacyManager.nodo_latente_id == id:
		k = Balance.MICELIO_LATENT_MULT
	return k

## Descuento del nodo conectado (1.0 = sin cambio).
static func cost_factor(id: String) -> float:
	if not EvoManager.mutation_micelio_omnisciente:
		return 1.0
	return 1.0 - Balance.MICELIO_NODE_DISCOUNT * connection(id)

## Contabilidad: su +5 %/nivel amplificado (factor sobre el ingreso ya calculado).
static func accounting_factor() -> float:
	var k := node_factor("accounting")
	if k == 1.0:
		return 1.0
	var lvl := float(UpgradeManager.level("accounting"))
	return (1.0 + 0.05 * lvl * k) / (1.0 + 0.05 * lvl)

## Capital Cognitivo: nivel efectivo para μ.
static func cognitive_level() -> float:
	return float(UpgradeManager.level("cognitive")) * node_factor("cognitive")


## Cada compra concretada (UpgradeManager.purchase_upgrade): cuenta las hechas a mano con Micelio.
static func on_purchase() -> void:
	if EvoManager.mutation_micelio_omnisciente and not _autobuying:
		EvoManager.micelio_manual_buys += 1


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and EvoManager.micelio_full_time >= Balance.MICELIO_SEAL_HOLD
