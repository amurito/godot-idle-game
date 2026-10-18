class_name InestabilidadLogic

## INESTABILIDAD CONSCIENTE — SOMBRA de HOMEOSTASIS. Verbo: OBSERVAR. Lore matemático.
## "El hongo deja de reducir ε y empieza a medirlo. Descubre que es una ecuación, y que mirarla la cambia."
## Spec: docs/design/sombras.md §3 y §9. Estado en EvoManager (inest_*); sólo funciones estáticas.
##
##   · Espejo (sin botón): con la llave, habiendo tenido Homeostasis elegible en la run y con
##     Contabilidad ≥ 1, sostener ε ≥ INEST_MIRROR_EPS durante INEST_MIRROR_TIME s (avisa antes).
##   · Perturbación P: se suma al objetivo de ε (StructuralModel), así que ε sube suave.
##   · [Q] OBSERVAR: P += INEST_OBSERVE_P y revela el próximo lema (efecto del observador). Cada lema
##     revelado sin demostrar sigue empujando P (INEST_OPEN_DRIFT/s): mirar de más acelera la deriva.
##   · [W] INTEGRAR: cuesta INEST_INTEGRATE_SECS s de ingreso, P −= INEST_INTEGRATE_P.
##   · Lemas: cada uno nombra un término de la ecuación y se demuestra jugando. Demostrado = su
##     coeficiente queda visible y el ingreso sube (teorema). Sello Q.E.D.: los 5.
##   · Fracaso (vuelve a la base, HOMEOSTASIS): ε > INEST_DIVERGE_EPS durante INEST_DIVERGE_TIME s
##     (la ecuación diverge) o ε < INEST_CONVERGE_EPS durante INEST_CONVERGE_TIME s (converge sola).

## Orden fijo de revelación. Cada lema: coeficiente, condición y tiempo de demostración.
const LEMMAS := ["impulso", "lyapunov", "inercia", "estructura", "elasticidad"]
const COEF := {"impulso": "a", "lyapunov": "ε", "inercia": "d", "estructura": "n", "elasticidad": "Ω"}

static func activate() -> void:
	if EvoManager.mutation_inestabilidad:
		return
	EvoManager.mutation_inestabilidad = true
	EvoManager.inest_mirror_time = 0.0
	# Homeostasis queda negada: sin modo homeostático ni tiers esta run (como Caos Orquestado).
	RunManager.homeostasis_mode = false
	RunManager.post_homeostasis = false
	if is_instance_valid(RunManager.evolution_button):
		RunManager.evolution_button.visible = false
	RunManager.target_evolution = ""
	EvoManager._set_genome_state("homeostasis", "bloqueado")
	LogManager.add(TranslationServer.translate("LOG_INEST_EFFECTS"))
	EvoManager.mutation_activated.emit("inestabilidad_consciente", TranslationServer.translate("MUT_INESTABILIDAD"))
	AchievementManager.on_mutation_activated("inestabilidad_consciente")
	UIManager.show_toast(TranslationServer.translate("TOAST_INEST_ON"))
	EvoManager._save_after_mutation()


# ── Espejo ───────────────────────────────────────────────────────────────────

## Mutaciones con las que el espejo no corre: la run ya eligió otro camino.
static func _route_taken() -> bool:
	return EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation \
		or EvoManager.mutation_symbiosis or EvoManager.mutation_red_micelial or EvoManager.mutation_parasitism \
		or EvoManager.mutation_depredador or EvoManager.mutation_met_oscuro \
		or EvoManager.mutualismo_active or EvoManager.holobionte_active or EvoManager.endosimbiosis_active \
		or TransmutationLogic.any_active() or EvoManager.transmut_reverted.get("homeostasis", false) \
		or RouteManager.is_active("carnaval") or RouteManager.is_active("vacio")

## update_genome (cada logic tick). Homeostasis elegible alguna vez en la run (su botón habilitado o
## su gen latente) = tuviste el equilibrio al alcance; sostener el desequilibrio después es la Sombra.
static func update_mirror(ctx: Dictionary) -> void:
	if not EvoManager.inest_homeo_seen and (EvoManager.genome.get("homeostasis", "") == "latente" 			or RunManager.is_homeostasis_candidate()):
		EvoManager.inest_homeo_seen = true
	if EvoManager.mutation_inestabilidad or LegacyManager.get_buff_level("sombra_inestabilidad") <= 0:
		return
	if not mirror_open(int(ctx.accounting)):
		EvoManager.inest_mirror_time = 0.0
		EvoManager._inest_mirror_countdown_last = -1
		return
	# El tiempo con ε alto se ACUMULA: un bajón no lo reinicia, lo descuenta a la mitad de velocidad
	# (ε oscila con cada click; exigir 60 s seguidos era injugable — feedback del autor 2026-10-18).
	if float(ctx.epsilon) < Balance.INEST_MIRROR_EPS:
		EvoManager.inest_mirror_time = maxf(EvoManager.inest_mirror_time - RunManager.LOGIC_TICK * Balance.INEST_MIRROR_DECAY, 0.0)
		EvoManager._inest_mirror_countdown_last = -1
		return
	EvoManager.inest_mirror_time += RunManager.LOGIC_TICK
	if EvoManager.inest_mirror_time >= Balance.INEST_MIRROR_TIME:
		EvoManager._inest_mirror_countdown_last = -1
		activate()
		return
	var left: float = Balance.INEST_MIRROR_TIME - EvoManager.inest_mirror_time
	if left > Balance.INEST_MIRROR_WARN:
		return
	var secs_left := int(ceil(left))
	if secs_left != EvoManager._inest_mirror_countdown_last:
		EvoManager._inest_mirror_countdown_last = secs_left
		UIManager.show_toast(TranslationServer.translate("TOAST_INEST_MIRROR_WARN") % secs_left)


## El espejo puede correr (todo menos ε): llave, Homeostasis elegible antes, Contabilidad, ninguna ruta.
static func mirror_open(accounting: int = -1) -> bool:
	if accounting < 0:
		accounting = UpgradeManager.level("accounting")
	return not EvoManager.mutation_inestabilidad and LegacyManager.get_buff_level("sombra_inestabilidad") > 0 \
		and not _route_taken() and EvoManager.inest_homeo_seen and accounting >= 1 and not RunManager.run_closed


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutation_inestabilidad and not RunManager.run_closed

## Perturbación que se suma al objetivo de ε (0 fuera de la ruta).
static func perturbation() -> float:
	return EvoManager.inest_perturb if is_active() else 0.0

static func is_revealed(id: String) -> bool:
	return LEMMAS.find(id) < EvoManager.inest_revealed

static func is_proven(id: String) -> bool:
	return EvoManager.inest_proven.get(id, false)

static func proven_count() -> int:
	return EvoManager.inest_proven.size()

static func hold_time(id: String) -> float:
	return float(Balance.INEST_LEMMA_HOLD.get(id, 20.0))

## Progreso del lema en [0, 1] (para el panel).
static func progress(id: String) -> float:
	if is_proven(id):
		return 1.0
	if id == "estructura":
		return clampf(float(_struct_gained()) / Balance.INEST_STRUCT_UPGRADES, 0.0, 1.0)
	return clampf(float(EvoManager.inest_progress.get(id, 0.0)) / hold_time(id), 0.0, 1.0)

static func _struct_gained() -> int:
	return maxi(StructuralModel.get_structural_upgrades() - EvoManager.inest_struct_mark, 0)

## Condición de cada lema en este instante.
static func condition(id: String) -> bool:
	var eps: float = StructuralModel.epsilon_runtime
	match id:
		"impulso":     # a: el impulso manual domina la ecuación
			return EvoManager.inest_cps >= Balance.INEST_IMPULSO_CPS
		"lyapunov":    # ε: el sistema vive al borde del caos, sin caer
			return eps >= Balance.INEST_LYAPUNOV_LO and eps <= Balance.INEST_LYAPUNOV_HI
		"inercia":     # d: el pasivo sostiene la inestabilidad sin manos
			return EconomyManager.time_since_last_click >= Balance.INEST_INERCIA_IDLE and eps >= Balance.INEST_INERCIA_EPS
		"estructura":  # n: la estructura crece aunque tiemble
			return _struct_gained() >= Balance.INEST_STRUCT_UPGRADES
		"elasticidad": # Ω: la ecuación también sabe ceder — Ω vuelve a ×1.75 de su mínimo
			return StructuralModel.omega >= elastic_target()
	return false

## Ω que pide el Lema de la elasticidad: ×INEST_ELASTIC_RATIO el mínimo desde que se reveló.
static func elastic_target() -> float:
	return minf(EvoManager.inest_elastic_min * Balance.INEST_ELASTIC_RATIO, 0.95)

## Ingreso × (1 + INEST_THEOREM_BONUS · lemas demostrados): cada teorema es una herramienta.
static func theorem_mult() -> float:
	if not EvoManager.mutation_inestabilidad:
		return 1.0
	return 1.0 + Balance.INEST_THEOREM_BONUS * proven_count()


# ── Tick ─────────────────────────────────────────────────────────────────────

static func process(dt: float) -> void:
	if not is_active():
		return
	EvoManager.inest_cps -= EvoManager.inest_cps * minf(dt / Balance.INEST_CPS_TAU, 1.0)
	EvoManager.inest_observe_cd = maxf(EvoManager.inest_observe_cd - dt, 0.0)
	EvoManager.inest_integrate_cd = maxf(EvoManager.inest_integrate_cd - dt, 0.0)
	var eps: float = StructuralModel.epsilon_runtime
	EvoManager.inest_peak_eps = maxf(EvoManager.inest_peak_eps, eps)
	if is_revealed("elasticidad") and not is_proven("elasticidad"):
		EvoManager.inest_elastic_min = minf(EvoManager.inest_elastic_min, StructuralModel.omega)
	# Lo observado sigue perturbando: cada lema a la vista y sin demostrar empuja P.
	var open: int = EvoManager.inest_revealed - proven_count()
	if open > 0:
		EvoManager.inest_perturb = minf(EvoManager.inest_perturb + Balance.INEST_OPEN_DRIFT * open * dt, Balance.INEST_P_MAX)

	# Lemas revelados: el progreso sube mientras se cumple y baja a la mitad de velocidad si no.
	for i in mini(EvoManager.inest_revealed, LEMMAS.size()):
		var id: String = LEMMAS[i]
		if is_proven(id):
			continue
		if condition(id):
			if id != "estructura":
				EvoManager.inest_progress[id] = float(EvoManager.inest_progress.get(id, 0.0)) + dt
			if id == "estructura" or float(EvoManager.inest_progress[id]) >= hold_time(id):
				_prove(id)
		elif id != "estructura":
			EvoManager.inest_progress[id] = maxf(float(EvoManager.inest_progress.get(id, 0.0)) - dt * Balance.INEST_PROGRESS_DECAY, 0.0)
	if EvoManager.inest_revealed >= LEMMAS.size() and not EvoManager.inest_all_revealed_at_once:
		# Principio de Incertidumbre: los 5 lemas a la vista sin haber demostrado ninguno.
		if proven_count() == 0:
			EvoManager.inest_all_revealed_at_once = true
			AchievementManager.unlock("principio_incertidumbre")

	# FRACASO: la ecuación diverge (ε muy alto) o converge sola (ε muy bajo) → vuelve a HOMEOSTASIS.
	if eps > Balance.INEST_DIVERGE_EPS:
		if EvoManager.inest_diverge_time <= 0.0:
			UIManager.show_toast(TranslationServer.translate("TOAST_INEST_DIVERGING") % Balance.INEST_DIVERGE_TIME)
		EvoManager.inest_diverge_time += dt
		if EvoManager.inest_diverge_time >= Balance.INEST_DIVERGE_TIME:
			RunManager.close_run("HOMEOSTASIS", TranslationServer.translate("CLOSE_INEST_DIVERGE"))
			return
	else:
		EvoManager.inest_diverge_time = 0.0
	if eps < Balance.INEST_CONVERGE_EPS:
		EvoManager.inest_converge_time += dt
		if EvoManager.inest_converge_time >= Balance.INEST_CONVERGE_TIME:
			RunManager.close_run("HOMEOSTASIS", TranslationServer.translate("CLOSE_INEST_CONVERGE"))
			return
	else:
		EvoManager.inest_converge_time = 0.0

static func _prove(id: String) -> void:
	EvoManager.inest_proven[id] = true
	EvoManager.inest_progress[id] = hold_time(id)
	var lname: String = TranslationServer.translate("INEST_LEMMA_" + id.to_upper())
	UIManager.show_toast(TranslationServer.translate("TOAST_INEST_PROVEN") % [lname, theorem_mult()])
	LogManager.add(TranslationServer.translate("LOG_INEST_PROVEN") % [lname, COEF[id], proven_count(), LEMMAS.size()])


# ── Hooks ────────────────────────────────────────────────────────────────────

## Click manual (main): media móvil de clicks/s (Lema del impulso).
static func on_click() -> void:
	if EvoManager.mutation_inestabilidad:
		EvoManager.inest_cps += 1.0 / Balance.INEST_CPS_TAU


# ── [Q] OBSERVAR ─────────────────────────────────────────────────────────────

static func can_observe() -> bool:
	return is_active() and EvoManager.inest_observe_cd <= 0.0 and EvoManager.inest_revealed < LEMMAS.size()

## Revela el próximo lema; mirar perturba (P sube).
static func observe() -> void:
	if not can_observe():
		return
	var id: String = LEMMAS[EvoManager.inest_revealed]
	EvoManager.inest_revealed += 1
	EvoManager.inest_observations += 1
	EvoManager.inest_perturb = minf(EvoManager.inest_perturb + Balance.INEST_OBSERVE_P, Balance.INEST_P_MAX)
	EvoManager.inest_observe_cd = Balance.INEST_OBSERVE_CD
	if id == "estructura":
		EvoManager.inest_struct_mark = StructuralModel.get_structural_upgrades()
	elif id == "elasticidad":
		EvoManager.inest_elastic_min = StructuralModel.omega
	UIManager.show_toast(TranslationServer.translate("TOAST_INEST_OBSERVED") % [
		TranslationServer.translate("INEST_LEMMA_" + id.to_upper()), Balance.INEST_OBSERVE_P])


# ── [W] INTEGRAR ─────────────────────────────────────────────────────────────

static func integrate_cost() -> float:
	return maxf(EconomyManager.get_delta_total() * Balance.INEST_INTEGRATE_SECS, Balance.INEST_INTEGRATE_MIN_COST)

static func can_integrate() -> bool:
	return is_active() and EvoManager.inest_integrate_cd <= 0.0 \
		and EvoManager.inest_perturb > Balance.INEST_P_MIN and EconomyManager.money >= integrate_cost()

## Integrar la ecuación la amortigua: P baja (puede quedar negativa y frenar el ε natural).
static func integrate() -> void:
	if not can_integrate():
		return
	EconomyManager.money -= integrate_cost()
	EvoManager.inest_perturb = maxf(EvoManager.inest_perturb - Balance.INEST_INTEGRATE_P, Balance.INEST_P_MIN)
	EvoManager.inest_integrate_cd = Balance.INEST_INTEGRATE_CD
	EvoManager.inest_integrations += 1
	UIManager.show_toast(TranslationServer.translate("TOAST_INEST_INTEGRATED") % EvoManager.inest_perturb)


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and proven_count() >= LEMMAS.size()


# ── Legados de conocimiento (recompensa) ─────────────────────────────────────

## Umbrales de ε del árbol que avisa el Predictor Estructural: [ε, clave de nombre].
static func epsilon_thresholds() -> Array:
	var out: Array = [[0.35, "PRED_MASA_CRITICA"], [0.40, "PRED_HIPER"], [0.65, "PRED_RED"], [0.95, "PRED_DEPREDADOR"]]
	if LegacyManager.get_buff_level("sombra_inestabilidad") > 0 and not EvoManager.mutation_inestabilidad:
		out.insert(2, [Balance.INEST_MIRROR_EPS, "PRED_INEST"])
	return out

## Próximo umbral por encima de ε ([] si no hay).
static func next_threshold(eps: float) -> Array:
	for th in epsilon_thresholds():
		if eps < float(th[0]):
			return th
	return []

## Predictor Estructural: aviso al quedar a menos de PREDICTOR_MARGIN por debajo de un umbral. El
## aviso de ese umbral se rearma cuando ε baja 2 márgenes por debajo.
static func tick_predictor() -> void:
	if not LegacyManager.get_buff_value("predictor_estructural") or RunManager.run_closed:
		return
	var eps: float = StructuralModel.epsilon_runtime
	var ths: Array = epsilon_thresholds()
	var w: int = EvoManager._predictor_warned_idx
	if w >= ths.size() or (w >= 0 and eps < float(ths[w][0]) - 2.0 * Balance.PREDICTOR_MARGIN):
		w = -1
	for i in ths.size():
		var v: float = float(ths[i][0])
		if eps < v and v - eps <= Balance.PREDICTOR_MARGIN and i != w:
			w = i
			UIManager.show_toast(TranslationServer.translate("TOAST_PREDICTOR") % [v, TranslationServer.translate(ths[i][1])])
			break
	EvoManager._predictor_warned_idx = w
