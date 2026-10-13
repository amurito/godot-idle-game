extends RefCounted
## BotPolicy — qué hace el "jugador" simulado en cada frame.
##
## Sólo usa acciones que el jugador real tiene, por el mismo camino de código que la UI:
##   · click en el reactor                      → SimDriver.click()
##   · compra de upgrades                       → SimDriver.buy()  (= teclas 1-9)
##   · botones del panel de mutación            → handlers de main, habilitados con
##                                                UITextBuilders.build_bifurcation_data()
##                                                (lo mismo que decide si el botón está activo)
##   · teclas Q/W de transmutaciones y sellos   → mismas funciones que main._input() /
##                                                NGPlusButtonManager
##
## Configuración (todas opcionales):
##   click_cps: float              clicks por segundo (0 = idle)
##   click_schedule: [[t, cps]..]  cps por tramos (reemplaza a click_cps): rige el último t <= ahora
##   click_from / click_until: s   ventana de clickeo (-1 = sin límite)
##   priority: [ids]               se compran primero apenas alcanza el dinero
##   save_for_priority: bool       si una prioridad no comprada no alcanza, no compra nada más (ahorra)
##   save_from: s                  desde cuándo empieza a ahorrar para las prioridades
##   stop_click_when: [ids]        deja de clickear si EvoManager.mutation_<id> es true
##   buy: "cheapest" | "none"      estrategia de compra
##   buy_ids / avoid: [ids]        upgrades permitidos / excluidos
##   unavoid_on: {id: mutation}    deja de evitar `id` cuando EvoManager.mutation_<mutation> es true
##   max_passive_pct: float        no compra upgrades pasivos si el % pasivo ya lo supera
##                                 (perfil "busco Hiperasimilación": exige >80% activo)
##   uncap_passive_on: mutation    ignora max_passive_pct cuando EvoManager.mutation_<mutation> es true
##   buy_ids_on: {mutation: [ids]} reemplaza buy_ids mientras EvoManager.mutation_<mutation> es true
##   buy_ids_from: [t, [ids]]      reemplaza buy_ids desde los t s de run (p.ej. invertir sólo en pasivo)
##   max_buys_per_decision: int
##   decision_interval: s          cada cuánto decide compras/botones (default 0.5)
##   mutation: "none" | "homeostasis" | "simbiosis" | "red_micelial"
##   branch: "none" | "colonization" | "symbiosis"      (sub-rama de Red Micelial)
##   allostasis: bool
##   transmute: id                 revierte A → A+ (TransmutationLogic) en la 1ª aparición del botón [T]
##   cps_when: {mutation: cps}     ritmo de clicks mientras EvoManager.mutation_<mutation> es true
##   caos_collapse_at: float       dispara [Q] Colapso Dirigido cuando ε ≥ esto (-1 = nunca)
##   caos_cd / caos_seal: bool     compra [W] cuando alcanza / sella apenas puede
##   coro_overload / coro_w / coro_seal: bool  Sobrecarga cuando está lista / compra [W] / sella
##   fusion_bursts / fusion_cd / fusion_seal: bool
##   fusion_cd_save_secs: float    ahorra para el próximo nivel de [W] si cuesta ≤ N s de ingreso
##   fusion_burst_limit: int       máximo de ráfagas que usa (jugador que se olvida de la Q)
##   ayuno_burst_at: float (-1 = nunca)  /  ayuno_ascesis / ayuno_seal: bool
##   micelio_plan: [ids]           Micelio Omnisciente: conecta (click derecho) en este orden, llenando
##                                 cada nodo antes de pasar al siguiente (salta los bloqueados)
##   micelio_swap: [from, to, t]   a los t s de Micelio, desconecta `from` entero y lo pasa a `to`
##                                 (jugador que corrige su plan → no saca el MYTHIC)
##   micelio_seal: bool

const DEFAULT_BUY_IDS := ["click", "auto", "trueque", "click_mult", "auto_mult",
	"trueque_net", "specialization", "cognitive", "accounting", "persistence"]
## Upgrades que alimentan el término pasivo (d, md, e, me y especialización).
const PASSIVE_IDS := ["auto", "auto_mult", "trueque", "trueque_net", "specialization"]

var cfg: Dictionary
var actions: Array = []

var _click_acc: float = 0.0
var _micelio_start: float = -1.0
var _swapped := false
var _micelio_plan: Array = []
var _next_decision_frame: int = 0


func _init(config: Dictionary) -> void:
	cfg = config


func act(d: RefCounted) -> void:
	if RunManager.run_closed:
		return
	var cps := _current_cps()
	if cps > 0.0:
		_click_acc += cps * d.dt()
		while _click_acc >= 1.0:
			_click_acc -= 1.0
			d.click()
	if d.frame >= _next_decision_frame:
		var interval: float = float(cfg.get("decision_interval", 0.5))
		_next_decision_frame = d.frame + maxi(1, int(roundf(interval / d.dt())))
		_buy(d)
		_mutation_choice(d)
		_route_keys(d)


func _current_cps() -> float:
	var t := RunManager.run_time
	if t < float(cfg.get("click_from", 0.0)):
		return 0.0
	var until: float = float(cfg.get("click_until", -1.0))
	if until >= 0.0 and t >= until:
		return 0.0
	for m in cfg.get("stop_click_when", []):
		if bool(EvoManager.get("mutation_" + str(m))):
			return 0.0
	var cps_when: Dictionary = cfg.get("cps_when", {})
	for m in cps_when:
		if bool(EvoManager.get("mutation_" + str(m))):
			return float(cps_when[m])
	if cfg.has("click_schedule"):
		var cps := 0.0
		for entry in cfg.click_schedule:
			if t >= float(entry[0]):
				cps = float(entry[1])
		return cps
	return float(cfg.get("click_cps", 0.0))


# ── Compras ─────────────────────────────────────────────────────────────────────

func _buy(d: RefCounted) -> void:
	if str(cfg.get("buy", "cheapest")) == "none":
		return
	var avoid: Array = _effective_avoid()
	var ids: Array = cfg.get("buy_ids", DEFAULT_BUY_IDS)
	var ids_from: Array = cfg.get("buy_ids_from", [])
	if ids_from.size() == 2 and RunManager.run_time >= float(ids_from[0]):
		ids = ids_from[1]
	var ids_on: Dictionary = cfg.get("buy_ids_on", {})
	for mut in ids_on:
		if bool(EvoManager.get("mutation_" + str(mut))):
			ids = ids_on[mut]
	var max_passive: float = float(cfg.get("max_passive_pct", 100.0))
	var uncap: String = str(cfg.get("uncap_passive_on", ""))
	if uncap != "" and bool(EvoManager.get("mutation_" + uncap)):
		max_passive = 100.0

	# Fusión: ahorrar para [W] cuando el próximo nivel cuesta pocos segundos de ingreso.
	var cd_secs: float = float(cfg.get("fusion_cd_save_secs", 0.0))
	if cd_secs > 0.0 and EvoManager.mutation_fusion_catabolica and not EvoManager.fusion_cd_maxed():
		var cd_cost: float = EvoManager.fusion_cd_cost()
		if EconomyManager.money < cd_cost and cd_cost <= EconomyManager.get_delta_total() * cd_secs:
			return

	# Prioridades: se compran apenas alcanzan; opcionalmente se ahorra para ellas.
	for id in cfg.get("priority", []):
		if id in avoid or UpgradeManager.level(id) > 0 or not UpgradeManager.is_unlocked(id):
			continue
		if UpgradeManager.can_buy(id, EconomyManager.money):
			d.buy(id)
		elif cfg.get("save_for_priority", false) and RunManager.run_time >= float(cfg.get("save_from", 0.0)):
			return  # ahorrando: no se gasta en nada más

	for _i in int(cfg.get("max_buys_per_decision", 30)):
		var passive_capped := false
		if max_passive < 100.0:
			passive_capped = float(EconomyManager.get_active_passive_breakdown().pasivo) >= max_passive
		var best := ""
		var best_cost := INF
		for id in ids:
			if id in avoid:
				continue
			if passive_capped and id in PASSIVE_IDS:
				continue
			if not UpgradeManager.can_buy(id, EconomyManager.money):
				continue
			var c := UpgradeManager.cost(id)
			if c < best_cost:
				best_cost = c
				best = id
		if best == "" or not d.buy(best):
			return


func _effective_avoid() -> Array:
	var avoid: Array = cfg.get("avoid", []).duplicate()
	var unavoid: Dictionary = cfg.get("unavoid_on", {})
	for id in unavoid:
		if bool(EvoManager.get("mutation_" + str(unavoid[id]))):
			avoid.erase(id)
	return avoid


# ── Panel de mutación ───────────────────────────────────────────────────────────

func _mutation_choice(d: RefCounted) -> void:
	var want := str(cfg.get("mutation", "none"))
	var branch := str(cfg.get("branch", "none"))
	var want_allo := bool(cfg.get("allostasis", false))
	if want == "none" and branch == "none" and not want_allo:
		return
	if EvoManager.mutation_parasitism:
		return  # el botón de mutación está bloqueado durante Parasitismo

	var data: Dictionary = UITextBuilders.build_bifurcation_data()
	var mode := str(data.get("tier_mode", ""))

	if mode == "tier1":
		# El botón "Iniciar mutación" sólo es visible con alguna mutación tier 1 latente.
		if not EvoManager.is_any_latent_tier1():
			return
		match want:
			"homeostasis":
				if data.get("homeostasis_ready", false):
					_press(d, "_on_btn_homeostasis_pressed", "mutation:homeostasis")
			"simbiosis":
				if data.get("simbiosis_ready", false):
					_press(d, "_on_btn_symbiosis_pressed", "mutation:simbiosis")
			"red_micelial":
				if data.get("red_micelial_ready", false):
					_press(d, "_on_btn_colonization_pressed", "mutation:red_micelial")
	elif mode == "tier2_branches" and EvoManager.red_branch_selected == EvoManager.RedBranch.NONE:
		if branch == "colonization" and data.get("colonization_ready", false):
			_press(d, "_on_btn_colonization_pressed", "branch:colonization")
		elif branch == "symbiosis" and data.get("symbiosis_ready", false):
			_press(d, "_on_btn_symbiosis_pressed", "branch:symbiosis")
	elif mode == "tier2_homeostasis" and want_allo and not EvoManager.mutation_allostasis:
		if data.get("allostasis_ready", false):
			_press(d, "_on_btn_homeostasis_pressed", "mutation:allostasis")


func _press(d: RefCounted, method: String, label: String) -> void:
	d.main.call(method)
	_log(label)


# ── Teclas de transmutación y sellos ────────────────────────────────────────────

func _route_keys(_d: RefCounted) -> void:
	var tid: String = str(cfg.get("transmute", ""))
	if tid != "" and TransmutationLogic.candidate() == tid and TransmutationLogic.is_visible():
		# Mismo camino que el jugador: [T] abre la confirmación y se acepta.
		UIManager._ng_buttons.open_transmut_dialog()
		UIManager._ng_buttons._on_transmut_confirmed()
		if TransmutationLogic.candidate() != tid:
			_after_key("key:T transmute:" + tid)
	if EvoManager.mutation_coro_simbiotico:
		if cfg.get("coro_overload", false) and CoroSimbioticoLogic.can_overload():
			CoroSimbioticoLogic.overload()
			_after_key("key:Q coro_overload stacks=%.0f" % EvoManager.coro_stacks)
		if cfg.get("coro_w", false) and CoroSimbioticoLogic.can_buy_w():
			CoroSimbioticoLogic.buy_w()
			_after_key("key:W coro_w")
		if cfg.get("coro_seal", false) and CoroSimbioticoLogic.seal_ready():
			UIManager._ng_buttons._on_coro_seal_pressed()
			_log("seal:coro")
	if EvoManager.mutation_micelio_omnisciente:
		_micelio()
	if EvoManager.mutation_caos_orquestado:
		var at: float = float(cfg.get("caos_collapse_at", -1.0))
		if at >= 0.0 and StructuralModel.epsilon_runtime >= at and CaosOrquestadoLogic.can_collapse():
			var eps_now: float = StructuralModel.epsilon_runtime
			CaosOrquestadoLogic.collapse()
			_after_key("key:Q caos_collapse eps=%.2f" % eps_now)
		if cfg.get("caos_cd", false) and CaosOrquestadoLogic.can_buy_cd():
			CaosOrquestadoLogic.buy_cd()
			_after_key("key:W caos_cd")
		if cfg.get("caos_seal", false) and CaosOrquestadoLogic.seal_ready():
			UIManager._ng_buttons._on_caos_seal_pressed()
			_log("seal:caos")
	if EvoManager.mutation_fusion_catabolica:
		var burst_limit: int = int(cfg.get("fusion_burst_limit", 1 << 30))
		if cfg.get("fusion_bursts", false) and EvoManager.fusion_burst_count < burst_limit \
				and EvoManager.fusion_burst_timer <= 0.0 and EvoManager.fusion_burst_cooldown <= 0.0:
			EvoManager.activate_fusion_burst()
			_after_key("key:Q fusion_burst")
		if cfg.get("fusion_cd", false) and EvoManager.can_buy_fusion_cd():
			EvoManager.buy_fusion_cd()
			_after_key("key:W fusion_cd")
		if cfg.get("fusion_seal", false) and EvoManager.fusion_seal_ready():
			UIManager._ng_buttons._on_fusion_seal_pressed()
			_log("seal:fusion")
	elif EvoManager.mutation_ayuno_primordial:
		var burst_at: float = float(cfg.get("ayuno_burst_at", -1.0))
		if burst_at >= 0.0 and EvoManager.ayuno_silencio >= burst_at and not EvoManager.ayuno_burst_active:
			EvoManager.activate_ayuno_burst()
			_after_key("key:Q ayuno_burst S=%.0f" % burst_at)
		if cfg.get("ayuno_ascesis", false) and EvoManager.can_buy_ayuno_ascesis():
			EvoManager.buy_ayuno_ascesis()
			_after_key("key:W ayuno_ascesis")
		if cfg.get("ayuno_seal", false) and EvoManager.ayuno_seal_ready():
			UIManager._ng_buttons._on_ayuno_seal_pressed()
			_log("seal:ayuno")


func _micelio() -> void:
	if _micelio_start < 0.0:
		_micelio_start = RunManager.run_time
		_micelio_plan = cfg.get("micelio_plan", []).duplicate()
	var swap: Array = cfg.get("micelio_swap", [])
	if swap.size() == 3 and not _swapped and RunManager.run_time - _micelio_start >= float(swap[2]):
		_swapped = true
		while MicelioOmniscienteLogic.unassign(str(swap[0])):
			pass
		_log("rclick:micelio_swap %s→%s" % [swap[0], swap[1]])
		_micelio_plan.erase(swap[1])
		_micelio_plan.push_front(swap[1])
	for id in _micelio_plan:
		if not UpgradeManager.is_unlocked(id):
			continue
		var n := 0
		while EvoManager.micelio_pool >= Balance.MICELIO_NODE_STEP and MicelioOmniscienteLogic.assign(id):
			n += 1
		if n > 0:
			_log("rclick:micelio %s x%d" % [id, n])
		if MicelioOmniscienteLogic.connection(id) < Balance.MICELIO_NODE_MAX:
			break  # llena en orden: no pasa al siguiente hasta completar éste
	if cfg.get("micelio_seal", false) and MicelioOmniscienteLogic.seal_ready():
		UIManager._ng_buttons._on_micelio_seal_pressed()
		_log("seal:micelio")


func _after_key(label: String) -> void:
	UIManager.update_ng_plus_buttons()  # main._input() hace lo mismo tras cada tecla
	_log(label)


func _log(label: String) -> void:
	actions.append({"t": snappedf(RunManager.run_time, 0.001), "action": label})
