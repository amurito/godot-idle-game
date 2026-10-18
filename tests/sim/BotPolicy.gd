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
##   green: {bio_min, push_cps, seal}  Rama verde (Colonización): empuja la frontera clickeando hasta
##                                 micelio ≥ 25, inicia el Primordio con biomasa ≥ bio_min, riega cuando la
##                                 integridad baja, y con la seta formada aprieta el final (ESPORULACIÓN)
##   eps_band: [lo, hi, cps]       termostato de ε: clickea a `cps` si ε < lo, a cps/2 hasta la mitad de
##                                 la banda y nada por encima (rige desde eps_band_on, mutación)
##   pre_band: [lo, hi, cps, bio]  antes de Hiper: termostato de ε hasta juntar `bio` de biomasa (Hiper
##                                 congela la biomasa: entra con la que tengas)
##   eps_band_on: mutation         activa eps_band sólo con EvoManager.mutation_<m> (default: siempre)
##   balance_ratio: bool           compra click si el activo es < 50 % y pasivo si es > 50 % (Mente Colmena)
##   blue_seal: bool               rama azul: con el Núcleo de Conciencia aprieta el final (SINGULARIDAD)
##   mo_seal_bio: float            Metabolismo Oscuro: sella con biomasa ≥ esto (-1 = nunca)
##   dark: {devour_target, route}  Árbol oscuro. En el Depredador sigue clickeando hasta `devour_target`
##                                 devorados y después deja de clickear y gasta todo (< $1000 → Met. Oscuro);
##                                 en MO activa `route` ("esclerocio" | "autofagia" | "necrosis" | "omega" |
##                                 "omega_starve" | "remision") y juega su minijuego hasta el cierre
##   click_every: s                un solo click cada `s` segundos (runs de pocos clicks; < 120 s evita
##                                 Parasitismo por inactividad)
##   fusion_seal_min_total: $      sella Fusión recién con este total generado (Coloso Estructural)
##   ayuno_seal_min_cycles: int    sella Ayuno recién con estos ciclos (Ayuno Absoluto)
##   dark.omega_seal_phi / dark.omega_seal_max_omega   condiciones del sello de Omega-Cero
##   dark.catalyst: bool           Necrosis: compra Catalizador cuando alcanza (antes que agentes)
##   dark.route "autofagia_full"   Autofagia ahorrando para maximizar velocidad y doble
##   evo_seal: tier                aprieta "SELLAR FINAL" cuando ofrece este tier de Homeostasis
##                                 ("HOMEOSTASIS" | "ALLOSTASIS" | "HOMEORHESIS"), como el jugador
##   transmute: id                 revierte A → A+ (TransmutationLogic) en la 1ª aparición del botón [T]
##   cps_when: {mutation: cps}     ritmo de clicks mientras EvoManager.mutation_<mutation> es true
##   caos_collapse_at: float       dispara [Q] Colapso Dirigido cuando ε ≥ esto (-1 = nunca)
##   caos_cd: bool                 compra [W] cuando alcanza
##   caos_grand_from: s            a los s de Caos pasa a cobrar sólo con ε ≥ CAOS_GRAND_EPS (Gran Colapso)
##   caos_hold_below: float        antes de eso deja de clickear con ε ≥ esto (no gastar el Gran Colapso)
##   rhythm_accuracy: float        Coro Simbiótico: en cada golpe del metrónomo clickea a tiempo con esta
##                                 probabilidad (si no, clickea medio pulso tarde = fuera de tiempo)
##   rhythm_seed: int              semilla del RNG de precisión (default 7)
##   coro_seal: bool               sella apenas la partitura está completa
##   fusion_bursts / fusion_cd / fusion_seal: bool
##   fusion_cd_save_secs: float    ahorra para el próximo nivel de [W] si cuesta ≤ N s de ingreso
##   fusion_burst_limit: int       máximo de ráfagas que usa (jugador que se olvida de la Q)
##   ayuno_burst_at: float (-1 = nunca)  /  ayuno_ascesis / ayuno_seal: bool
##   ayuno_streak_first: bool      no rompe el ayuno hasta tener la racha de silencio del sello
##   ayuno_safe_burst: bool        clickea una vez antes de romper el ayuno si lleva >100 s sin clickear
##                                 (el panel lo avisa: si no, Parasitismo entra → Trampa del Vacío)
##   micelio_plan: [ids]           Micelio Omnisciente: conecta (click derecho) en este orden, llenando
##                                 cada nodo antes de pasar al siguiente (salta los bloqueados)
##   micelio_swap: [from, to, t]   a los t s de Micelio, desconecta `from` entero y lo pasa a `to`
##                                 (jugador que corrige su plan → no saca el MYTHIC)
##   micelio_seal: bool
##   micelio_reinforce: bool       compra [W] Reforzar apenas alcanza (rupturas)
##   micelio_dodge: bool           al crujir un nodo, lo desconecta para salvar los puntos (cuenta como
##                                 desconexión: no saca el MYTHIC) y lo reconecta después
##   huesped_feed_at: float        Huésped: alimenta cuando el hambre llega a esto
##   huesped_precraving: bool      durante el aviso de antojo, si el hambre llegaría alta, alimenta apenas
##                                 puede sin empacharlo (anticipa)
##   huesped_seal: bool
##   mutualismo: {pact, policy, seal, react}  MUTUALISMO (tier 2 de Simbiosis):
##       pact: bool     acepta el pacto apenas aparece
##       policy: "fair" (acepta lo justo, rechaza la Tentación y cuida |R|) · "naive" (acepta todo menos
##               la Tentación, sin mirar R) · "greedy" (acepta todo, Tentación incluida)
##       seal: bool     sella apenas puede · react: s que tarda en decidir (default 2)
##       loan_safe: bool  no compra mientras hay un préstamo pendiente (no incumple)
##       seal_r: float    sella sólo con |R| ≤ esto (default: la banda justa)
##   endosimbiosis: {engulf, seal, max_rej, feed, feed_aut}  ENDOSIMBIOSIS:
##       engulf: aprieta ENGULLIR · seal: sella con el orgánulo
##       max_rej: transfiere sólo si el rechazo quedaría ≤ esto (default: sin mirar)
##       feed: "never" · "smart" (alimenta si falta ATP y la autonomía ≥ feed_aut, default 75) · "always"
##   holobionte: {enter, seal, care, cps_hi, cps_lo, eps_hi}  HOLOBIONTE (tier 3, requiere mutualismo):
##       enter: presenta socios en vez de sellar el pacto · seal: sella el ecosistema
##       prep: en Mutualismo compra sólo pasivo y presenta socios recién con pasivo ≥ enter_share
##             (default 0.36) → la Raíz no se muere al llegar
##   antibiosis: {push, rotate, react, afk, seal}  ANTIBIOSIS (Sombra de Simbiosis):
##       push: con Simbiosis vista y Contabilidad, compra click y clickea fuerte (abre el espejo)
##       rotate: true = elige el antibiótico de más daño · false = siempre el mismo (genera resistencia)
##       react: s que espera desde que llega un rival antes de disparar (default 0) · afk: no dispara
##       reserve_shots: no compra mejoras si la plata no cubre N disparos
##       max_res: no dispara un antibiótico que pasaría esta resistencia (salvo con 2 rivales vivos)
##   procariota: {quorum_at, plasmid, harvest_below, afk, seal}  PROCARIOTA (Sombra de Endosimbiosis;
##       el bot entra dejando pasar ENGULLIR: endosimbiosis.engulf = false):
##       quorum_at: dispara el quorum con la colonia ≥ esto (default 0.8) · plasmid: cicla hasta este
##       plásmido apenas puede · harvest_below: cosecha si la plata es < esto × costo de la mejora más barata
##       (default: nunca) · harvest_spam: cosecha apenas puede (prueba de extinción) · afk: no toca nada
##   inest: {push_band, observe_below, max_open, integrate_above, no_integrate, impulso_cps, seal}
##       INESTABILIDAD CONSCIENTE (Sombra de Homeostasis):
##       push_band: [lo, hi, cps]  con Homeostasis vista y Contabilidad, termostato de ε alto (abre el espejo)
##       observe_below: observa con ε < esto y menos de max_open lemas abiertos (default 0.95 / 2)
##       integrate_above: integra con ε > esto (default 1.08) · no_integrate: nunca integra (MYTHIC)
##       impulso_cps: clicks/s para el Lema del impulso (default 4) · seal: Q.E.D. apenas puede
##       elastic_eps: para la elasticidad integra mientras ε > esto (default 0.45) · cps: clicks fijos
##       reserve: no compra mejoras con menos de reserve × costo de INTEGRAR (default 1.5)
##       hoard_struct: no compra nada hasta revelar el Lema de la estructura (lo resuelve de golpe)
##       care: atiende las necesidades (compra pasivo si la Raíz lo pide; clickea a cps_hi con
##             ε < eps_hi y a cps_lo por encima, para no dejar sin luz al Alga ni sin clicks a la Bacteria)

const DEFAULT_BUY_IDS := ["click", "auto", "trueque", "click_mult", "auto_mult",
	"trueque_net", "specialization", "cognitive", "accounting", "persistence"]
## Upgrades que cuentan para n (StructuralModel.get_structural_upgrades): Lema de la estructura.
const STRUCT_IDS := ["auto", "auto_mult", "trueque", "trueque_net", "cognitive", "accounting", "specialization"]
## Upgrades que alimentan el término pasivo (d, md, e, me y especialización).
const PASSIVE_IDS := ["auto", "auto_mult", "trueque", "trueque_net", "specialization"]

var cfg: Dictionary
var actions: Array = []

var _click_acc: float = 0.0
var _rng := RandomNumberGenerator.new()
var _rh_last_beat_time: float = -1.0e9
var _rh_miss_at: float = -1.0
var _micelio_start: float = -1.0
var _caos_start: float = -1.0
var _caos_was_bursting := false
var _swapped := false
var _micelio_plan: Array = []
var _next_decision_frame: int = 0
var _inest_prog_total: float = -1.0
var _anti_seen_t: float = -1.0
var _inest_prog_t: float = 0.0


func _init(config: Dictionary) -> void:
	cfg = config
	_rng.seed = int(cfg.get("rhythm_seed", 7))


func act(d: RefCounted) -> void:
	if RunManager.run_closed:
		return
	var every_s: float = float(cfg.get("click_every", -1.0))
	if every_s > 0.0 and EconomyManager.time_since_last_click >= every_s:
		d.click()
	var acc: float = float(cfg.get("rhythm_accuracy", -1.0))
	if acc >= 0.0 and EvoManager.mutation_coro_simbiotico and CoroSimbioticoLogic.period() > 0.0:
		_rhythm(d, acc)
	elif _current_cps() > 0.0:
		var cps := _current_cps()
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


## Coro: un click por golpe — en el golpe (≤ 1 frame tarde) con probabilidad `acc`, si no medio
## pulso tarde (fuera de la ventana). Por tiempo absoluto del golpe: el cambio de tempo re-ancla.
func _rhythm(d: RefCounted, acc: float) -> void:
	var t: float = RunManager.run_time
	var p: float = CoroSimbioticoLogic.period()
	var k: int = floori(CoroSimbioticoLogic.beat_pos(t))
	var beat_t: float = EvoManager.coro_anchor + k * p
	if beat_t > _rh_last_beat_time + 1.0e-6:
		_rh_last_beat_time = beat_t
		if not CoroSimbioticoLogic.is_downbeat(k):
			return  # sólo se juzgan los acentos
		if _rng.randf() < acc:
			d.click()
		else:
			_rh_miss_at = beat_t + p * 0.45  # dentro de la zona, fuera de la ventana
	if _rh_miss_at >= 0.0 and t >= _rh_miss_at:
		_rh_miss_at = -1.0
		d.click()


func _current_cps() -> float:
	var t := RunManager.run_time
	if t < float(cfg.get("click_from", 0.0)):
		return 0.0
	var until: float = float(cfg.get("click_until", -1.0))
	if until >= 0.0 and t >= until:
		return 0.0
	var acfg_c: Dictionary = cfg.get("antibiosis", {})
	if acfg_c.get("push", false) and EvoManager.anti_simb_seen and not EvoManager.mutation_antibiosis \
			and UpgradeManager.level("accounting") >= 1:
		# Competir: termostato de ε alto clickeando (como el empuje de Inestabilidad).
		return 8.0 if StructuralModel.epsilon_runtime < 0.5 else 4.0
	var icfg: Dictionary = cfg.get("inest", {})
	if not icfg.is_empty():
		if InestabilidadLogic.is_active():
			return 0.0 if icfg.get("afk", false) else _inest_cps(icfg)
		var pb: Array = icfg.get("push_band", [])
		if pb.size() == 3 and EvoManager.inest_homeo_seen and UpgradeManager.level("accounting") >= 1:
			var ei: float = StructuralModel.epsilon_runtime
			if ei < float(pb[0]):
				return float(pb[2])
			if ei < (float(pb[0]) + float(pb[1])) / 2.0:
				return float(pb[2]) * 0.5
			return 0.0
	var hold: float = float(cfg.get("caos_hold_below", -1.0))
	if hold >= 0.0 and EvoManager.mutation_caos_orquestado and StructuralModel.epsilon_runtime >= hold 			and (_caos_start < 0.0 or RunManager.run_time - _caos_start < float(cfg.get("caos_grand_from", 1.0e9))):
		return 0.0
	var holo: Dictionary = cfg.get("holobionte", {})
	if holo.get("care", false) and HolobionteLogic.is_active():
		var hi: float = float(holo.get("cps_hi", 3.0))
		var lo: float = float(holo.get("cps_lo", 1.2))
		return hi if StructuralModel.epsilon_runtime < float(holo.get("eps_hi", 0.25)) else lo
	var dark: Dictionary = cfg.get("dark", {})
	if not dark.is_empty() and (EvoManager.mutation_depredador or EvoManager.mutation_met_oscuro):
		if EvoManager.mutation_necrosis:
			return float(cfg.get("click_cps", 10.0))  # la Necromasa sale de los clicks
		if EvoManager.mutation_met_oscuro:
			return 0.0
		return float(cfg.get("click_cps", 10.0)) if EvoManager.met_oscuro_devoured_count < int(dark.get("devour_target", 10)) else 0.0
	var every: float = float(cfg.get("click_every", -1.0))
	if every > 0.0:
		return 0.0  # los clicks espaciados los hace act() (ver _click_every)
	var pre: Array = cfg.get("pre_band", [])
	if pre.size() == 4 and not EvoManager.mutation_hyperassimilation and BiosphereEngine.biomasa < float(pre[3]):
		var e0: float = StructuralModel.epsilon_runtime
		if e0 < float(pre[0]):
			return float(pre[2])
		if e0 < (float(pre[0]) + float(pre[1])) / 2.0:
			return float(pre[2]) * 0.5
		return 0.0
	var band: Array = cfg.get("eps_band", [])
	var band_on: String = str(cfg.get("eps_band_on", ""))
	if band.size() == 3 and (band_on == "" or bool(EvoManager.get("mutation_" + band_on))):
		var e: float = StructuralModel.epsilon_runtime
		if e < float(band[0]):
			return float(band[2])
		if e < (float(band[0]) + float(band[1])) / 2.0:
			return float(band[2]) * 0.5
		return 0.0
	var green: Dictionary = cfg.get("green", {})
	if not green.is_empty() and EvoManager.mutation_red_micelial \
			and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		if EvoManager.primordio_active or EvoManager.seta_formada:
			return 0.0  # no sobrecalentar el embrión (ε)
		if BiosphereEngine.micelio < 25.0:
			return float(green.get("push_cps", 4.0))
		return 0.3
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
	var mcfg_b: Dictionary = cfg.get("mutualismo", {})
	if mcfg_b.get("loan_safe", false) and MutualismoLogic.is_active() and EvoManager.mutualismo_loan_due > 0.0:
		return  # junta la plata del préstamo
	# Micelio: [W] Reforzar tiene prioridad (ahorra si cuesta ≤ 60 s de ingreso).
	if cfg.get("micelio_reinforce", false) and MicelioOmniscienteLogic.is_active() 			and EvoManager.micelio_reinforce < Balance.MICELIO_REINFORCE_MAX:
		if MicelioOmniscienteLogic.can_reinforce():
			MicelioOmniscienteLogic.reinforce()
			_after_key("key:W micelio_reinforce %d" % EvoManager.micelio_reinforce)
		elif MicelioOmniscienteLogic.reinforce_cost() <= EconomyManager.get_delta_total() * 60.0:
			return
	# Inestabilidad: no gasta la reserva para INTEGRAR (reserve × su costo); con el Lema de la
	# estructura abierto compra sólo mejoras estructurales.
	var keep: float = 0.0
	var icfg_b: Dictionary = cfg.get("inest", {})
	var inest_struct: bool = false
	if not icfg_b.is_empty() and InestabilidadLogic.is_active():
		if not icfg_b.get("no_integrate", false):
			keep = InestabilidadLogic.integrate_cost() * float(icfg_b.get("reserve", 1.5))
		inest_struct = InestabilidadLogic.is_revealed("estructura") and not InestabilidadLogic.is_proven("estructura")
	# hoard_struct: junta plata hasta revelar el Lema de la estructura y lo resuelve de golpe.
	if icfg_b.get("hoard_struct", false) and InestabilidadLogic.is_active() and not InestabilidadLogic.is_revealed("estructura"):
		return
	# Antibiosis: guarda plata para N disparos (reserve_shots) antes de comprar mejoras.
	var acfg_r: Dictionary = cfg.get("antibiosis", {})
	if AntibiosisLogic.is_active() and acfg_r.has("reserve_shots"):
		keep = maxf(keep, AntibiosisLogic.shot_cost() * float(acfg_r.reserve_shots))
	var avoid: Array = _effective_avoid()
	var ids: Array = cfg.get("buy_ids", DEFAULT_BUY_IDS)
	if inest_struct:
		ids = STRUCT_IDS
	# Antibiosis (push): con Simbiosis vista, sólo click para que domine (abre el espejo).
	var acfg_b: Dictionary = cfg.get("antibiosis", {})
	if acfg_b.get("push", false) and EvoManager.anti_simb_seen and not EvoManager.mutation_antibiosis:
		ids = ["click", "click_mult", "accounting", "cognitive"]
	var ids_from: Array = cfg.get("buy_ids_from", [])
	if ids_from.size() == 2 and RunManager.run_time >= float(ids_from[0]):
		ids = ids_from[1]
	var ids_on: Dictionary = cfg.get("buy_ids_on", {})
	for mut in ids_on:
		if bool(EvoManager.get("mutation_" + str(mut))):
			ids = ids_on[mut]
	var hcfg_b: Dictionary = cfg.get("holobionte", {})
	if hcfg_b.get("prep", false) and MutualismoLogic.is_active() and not EvoManager.holobionte_active:
		ids = PASSIVE_IDS  # prepara el pasivo para la Raíz antes de presentar socios
	if cfg.get("balance_ratio", false) and EvoManager.mutation_red_micelial:
		# Mismo ratio que mide el portal de Mente Colmena (sin los multiplicadores de Red Micelial).
		ids = ["click", "click_mult", "accounting"] if RunManager.mente_colmena_ratio() < 0.5 else ["auto", "auto_mult", "trueque", "trueque_net", "accounting"]
	# Panspermia: con la seta formada se ahorra para el lanzamiento (no se compra nada).
	if not cfg.get("green", {}).is_empty() and EvoManager.seta_formada and EvoManager.is_panspermia_window():
		return
	if cfg.get("holobionte", {}).get("care", false) and HolobionteLogic.is_active() \
			and not HolobionteLogic.need_met("raiz"):  # también con la Raíz muerta: para que vuelva
		ids = PASSIVE_IDS
	var max_passive: float = float(cfg.get("max_passive_pct", 100.0))
	var uncap: String = str(cfg.get("uncap_passive_on", ""))
	if uncap != "" and bool(EvoManager.get("mutation_" + uncap)):
		max_passive = 100.0
	var dark_cfg: Dictionary = cfg.get("dark", {})
	if not dark_cfg.is_empty():
		var droute: String = str(dark_cfg.get("route", ""))
		if EvoManager.mutation_autolisis and droute == "autofagia_full":
			# Con las dos mejoras al máximo, dejar que se coma todo (si no, se realimenta para siempre).
			if DarkTreeLogic.autofagia_upgrade_cost("speed").maxed and DarkTreeLogic.autofagia_upgrade_cost("double").maxed:
				return
			# Ahorrar para las mejoras de Autofagia si la biomasa ya alcanza; si no, realimentar.
			for kind in ["speed", "double"]:
				var c: Dictionary = DarkTreeLogic.autofagia_upgrade_cost(kind)
				if not c.maxed and BiosphereEngine.biomasa >= c.bio:
					return
			ids = DEFAULT_BUY_IDS
			avoid = []
			max_passive = 100.0
		elif EvoManager.mutation_autolisis or (EvoManager.mutation_omega_cero and droute != "omega"):
			return  # no recomprar: que se coma lo que hay (Omega-Cero normal SÍ realimenta el loop)
		if EvoManager.mutation_omega_cero:
			ids = DEFAULT_BUY_IDS
			avoid = []
			max_passive = 100.0
		if EvoManager.mutation_depredador and not EvoManager.mutation_met_oscuro \
				and EvoManager.met_oscuro_devoured_count >= int(dark_cfg.get("devour_target", 10)):
			ids = DEFAULT_BUY_IDS
			avoid = []
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
		if UpgradeManager.can_buy(id, EconomyManager.money - keep):
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
			if not UpgradeManager.can_buy(id, EconomyManager.money - keep):
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
	var green: Dictionary = cfg.get("green", {})
	if not green.is_empty() and EvoManager.mutation_red_micelial \
			and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		if EvoManager.seta_formada:
			if EvoManager.is_panspermia_window():
				# Eyección: no pasar el calor máximo (misfire) y tener con qué pagar.
				# Lanza con presupuesto para ~25 eyecciones: al ritmo que permite el calor la carga sube neto ~+2/s.
				var budget_ok: bool = EvoManager.panspermia_charge > 0.0 \
					or EconomyManager.money >= Balance.PANSPERMIA_PULSE_COST * 25.0
				if budget_ok and EvoManager.panspermia_heat + Balance.PANSPERMIA_HEAT_PER_PULSE <= Balance.PANSPERMIA_HEAT_MAX \
						and EconomyManager.money >= Balance.PANSPERMIA_PULSE_COST:
					_press(_d, "_on_sporulation_final_pressed", "green:eyectar carga=%.0f" % EvoManager.panspermia_charge)
			elif green.get("seal", true):
				_press(_d, "_on_sporulation_final_pressed", "green:esporulacion")
		elif EvoManager.primordio_active:
			var hurt: bool = EvoManager.primordio_integrity <= Balance.PRIMORDIO_INTEGRITY_MAX - Balance.PRIMORDIO_REGAR_HEAL
			var hot: bool = StructuralModel.epsilon_runtime > Balance.PRIMORDIO_BAND_HI
			if (hurt or hot) and BiosphereEngine.biomasa >= Balance.PRIMORDIO_REGAR_COST_BIO:
				_press(_d, "_on_primordio_button_pressed", "green:regar int=%.0f" % EvoManager.primordio_integrity)
		elif BiosphereEngine.micelio >= 25.0 and BiosphereEngine.biomasa >= float(green.get("bio_min", 16.0)):
			_press(_d, "_on_primordio_button_pressed", "green:primordio bio=%.1f" % BiosphereEngine.biomasa)
	if cfg.get("blue_seal", false) and EvoManager.nucleo_conciencia and EvoManager.mutation_red_micelial:
		_press(_d, "_on_sporulation_final_pressed", "blue:singularidad")
	var mo_bio: float = float(cfg.get("mo_seal_bio", -1.0))
	if mo_bio >= 0.0 and EvoManager.mutation_met_oscuro and not EvoManager.mutation_autolisis \
			and not EvoManager.mutation_necrosis and not EvoManager.mutation_omega_cero and not EvoManager.mutation_remision \
			and BiosphereEngine.biomasa >= mo_bio:
		UIManager._ng_buttons._on_met_oscuro_seal_pressed()
		_log("seal:met_oscuro bio=%.0f" % BiosphereEngine.biomasa)
	if not cfg.get("dark", {}).is_empty() and EvoManager.mutation_met_oscuro:
		_dark(str(cfg.dark.get("route", "")))
	elif not cfg.get("dark", {}).is_empty() and EvoManager.mutation_depredador and cfg.dark.get("buy_time", true):
		# Comprar tiempo con biomasa: el Depredador sigue devorando, la economía se achica y la plata
		# puede bajar de $1000 (Met. Oscuro). El botón aparece en el panel del Depredador.
		if EvoManager.depredador_inestabilidad >= EvoManager.DEPREDADOR_INESTABILIDAD_MAX - 12.0 \
				and BiosphereEngine.biomasa >= DarkTreeLogic.depredador_time_cost():
			DarkTreeLogic.buy_depredador_time()
			_log("dark:comprar_tiempo")
	var evo: String = str(cfg.get("evo_seal", ""))
	if evo != "" and RunManager.target_evolution == evo and is_instance_valid(RunManager.evolution_button) \
			and RunManager.evolution_button.visible:
		RunManager._on_evolution_button_pressed()
		_log("seal:" + evo.to_lower())
	var tid: String = str(cfg.get("transmute", ""))
	if tid != "" and TransmutationLogic.candidate() == tid and TransmutationLogic.is_visible():
		# Mismo camino que el jugador: [T] abre la confirmación y se acepta.
		UIManager._ng_buttons.open_transmut_dialog()
		UIManager._ng_buttons._on_transmut_confirmed()
		if TransmutationLogic.candidate() != tid:
			_after_key("key:T transmute:" + tid)
	if EvoManager.mutation_coro_simbiotico:
		if cfg.get("coro_seal", false) and CoroSimbioticoLogic.seal_ready():
			UIManager._ng_buttons._on_coro_seal_pressed()
			_log("seal:coro")
	if EvoManager.mutation_micelio_omnisciente:
		_micelio()
	var icfg: Dictionary = cfg.get("inest", {})
	if not icfg.is_empty() and InestabilidadLogic.is_active() and not icfg.get("afk", false):
		_inest_keys(icfg)
	var pcfg: Dictionary = cfg.get("procariota", {})
	if not pcfg.is_empty() and ProcariotaLogic.is_active() and not pcfg.get("afk", false):
		_procariota_keys(pcfg)
	var acfg: Dictionary = cfg.get("antibiosis", {})
	if not acfg.is_empty() and AntibiosisLogic.is_active() and not acfg.get("afk", false):
		_antibiosis_keys(acfg)
	if EvoManager.mutation_huesped_soberano:
		var feed_at: float = float(cfg.get("huesped_feed_at", -1.0))
		var h_at: float = EvoManager.huesped_hunger + HuespedSoberanoLogic.hunger_rate() * HuespedSoberanoLogic.craving_in()
		var pre: bool = cfg.get("huesped_precraving", false) and HuespedSoberanoLogic.craving_in() <= Balance.HUESPED_CRAVING_WARN \
			and h_at + Balance.HUESPED_CRAVING_HUNGER > Balance.HUESPED_BAND_HI - 2.0 \
			and EvoManager.huesped_hunger - Balance.HUESPED_FEED >= Balance.HUESPED_BAND_LO + 1.0
		if (feed_at >= 0.0 and EvoManager.huesped_hunger >= feed_at) or pre:
			var h0: float = EvoManager.huesped_hunger
			HuespedSoberanoLogic.feed()
			_after_key("key:Q huesped_feed h=%.0f" % h0)
		if cfg.get("huesped_seal", false) and HuespedSoberanoLogic.seal_ready():
			UIManager._ng_buttons._on_huesped_seal_pressed()
			_log("seal:huesped")
	var ecfg: Dictionary = cfg.get("endosimbiosis", {})
	if not ecfg.is_empty():
		_endosimbiosis(ecfg)
	var hcfg: Dictionary = cfg.get("holobionte", {})
	if hcfg.get("enter", false) and HolobionteLogic.can_enter() \
			and (not hcfg.get("prep", false) or HolobionteLogic.passive_share() >= float(hcfg.get("enter_share", 0.36))):
		UIManager._ng_buttons._on_holo_enter_pressed()
		_log("holobionte:enter")
	var mcfg: Dictionary = cfg.get("mutualismo", {})
	if not mcfg.is_empty():
		_mutualismo(mcfg)
	if hcfg.get("seal", false) and HolobionteLogic.seal_ready():
		UIManager._ng_buttons._on_holo_seal_pressed()
		_log("seal:holobionte")
	if EvoManager.mutation_caos_orquestado:
		if _caos_start < 0.0:
			_caos_start = RunManager.run_time
		if _caos_was_bursting and EvoManager.caos_burst_timer <= 0.0:
			_log("burst_end eps=%.2f money=%.0f" % [EvoManager.caos_last_burst_eps, EvoManager.caos_last_burst_money])
		_caos_was_bursting = EvoManager.caos_burst_timer > 0.0
		var at: float = float(cfg.get("caos_collapse_at", -1.0))
		var grand_from: float = float(cfg.get("caos_grand_from", -1.0))
		if grand_from >= 0.0 and RunManager.run_time - _caos_start >= grand_from:
			at = Balance.CAOS_GRAND_EPS + 0.02
		if at >= 0.0 and StructuralModel.epsilon_runtime >= at and CaosOrquestadoLogic.can_collapse():
			var eps_now: float = StructuralModel.epsilon_runtime
			CaosOrquestadoLogic.collapse()
			_after_key("key:Q caos_collapse eps=%.2f" % eps_now)
		if cfg.get("caos_cd", false) and CaosOrquestadoLogic.can_buy_cd():
			CaosOrquestadoLogic.buy_cd()
			_after_key("key:W caos_cd")
	if EvoManager.mutation_fusion_catabolica:
		var burst_limit: int = int(cfg.get("fusion_burst_limit", 1 << 30))
		if cfg.get("fusion_bursts", false) and EvoManager.fusion_burst_count < burst_limit \
				and EvoManager.fusion_burst_timer <= 0.0 and EvoManager.fusion_burst_cooldown <= 0.0:
			EvoManager.activate_fusion_burst()
			_after_key("key:Q fusion_burst")
		if cfg.get("fusion_cd", false) and EvoManager.can_buy_fusion_cd():
			EvoManager.buy_fusion_cd()
			_after_key("key:W fusion_cd")
		if cfg.get("fusion_seal", false) and EvoManager.fusion_seal_ready() \
				and EconomyManager.total_money_generated >= float(cfg.get("fusion_seal_min_total", 0.0)):
			UIManager._ng_buttons._on_fusion_seal_pressed()
			_log("seal:fusion")
	elif EvoManager.mutation_ayuno_primordial:
		var burst_at: float = float(cfg.get("ayuno_burst_at", -1.0))
		var hold_streak: bool = cfg.get("ayuno_streak_first", false) \
			and EvoManager.ayuno_longest_streak < Balance.AYUNO_SELLO_STREAK
		if burst_at >= 0.0 and EvoManager.ayuno_silencio >= burst_at and not EvoManager.ayuno_burst_active and not hold_streak:
			if cfg.get("ayuno_safe_burst", false) and EconomyManager.time_since_last_click > 100.0:
				_d.click()
				_log("click:ayuno_safe")
			EvoManager.activate_ayuno_burst()
			_after_key("key:Q ayuno_burst S=%.0f" % burst_at)
		if cfg.get("ayuno_ascesis", false) and EvoManager.can_buy_ayuno_ascesis():
			EvoManager.buy_ayuno_ascesis()
			_after_key("key:W ayuno_ascesis")
		if cfg.get("ayuno_seal", false) and EvoManager.ayuno_seal_ready() \
				and EvoManager.ayuno_cycles >= int(cfg.get("ayuno_seal_min_cycles", 0)):
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
	# Con la red completa no esquiva: desconectar corta el sello (mejor arriesgar).
	var dodge: String = EvoManager.micelio_rupture_target if cfg.get("micelio_dodge", false) 		and MicelioOmniscienteLogic.full_nodes() < MicelioOmniscienteLogic.NODES.size() else ""
	if dodge != "" and MicelioOmniscienteLogic.connection(dodge) > 0.0:
		while MicelioOmniscienteLogic.unassign(dodge):
			pass
		_log("rclick:micelio_dodge " + dodge)
	for id in _micelio_plan:
		if not UpgradeManager.is_unlocked(id) or id == dodge:
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


func _dark(route: String) -> void:
	var ng = UIManager._ng_buttons
	var free: bool = not (EvoManager.mutation_autolisis or EvoManager.mutation_necrosis \
		or EvoManager.mutation_omega_cero or EvoManager.mutation_remision)
	match route:
		"esclerocio":
			if free and EvoManager.met_oscuro_devoured_count >= Balance.ESCLEROCIO_DEVOURED_REQ \
					and BiosphereEngine.biomasa >= Balance.ESCLEROCIO_BIO_REQ \
					and StructuralModel.epsilon_runtime < Balance.ESCLEROCIO_EPS_MAX:
				ng._on_esclerocio_pressed()
				_log("dark:esclerocio")
		"autofagia", "autofagia_full":
			if free and BiosphereEngine.biomasa >= Balance.AUTOLISIS_BIO_REQ \
					and UpgradeManager.get_owned_levels_count() >= Balance.AUTOLISIS_UPGRADES_REQ:
				EvoManager.activate_autolisis()
				_log("dark:autofagia")
			elif EvoManager.mutation_autolisis:
				for kind in ["speed", "double"]:
					if EvoManager.can_buy_autofagia_upgrade(kind):
						EvoManager.buy_autofagia_upgrade(kind)
						_log("dark:autofagia_" + kind)
		"necrosis":
			if free and BiosphereEngine.biomasa >= Balance.NECROSIS_BIO_REQ \
					and DarkTreeLogic.necrosis_flow_ok():
				EvoManager.activate_necrosis()
				_log("dark:necrosis")
			elif EvoManager.mutation_necrosis:
				if cfg.dark.get("catalyst", false) and DarkTreeLogic.can_buy_necrosis_catalyst():
					DarkTreeLogic.buy_necrosis_catalyst()
					_log("dark:necrosis_catalizador")
				elif EvoManager.necrosis_toxicidad > 0.55 and EvoManager.can_purge_necrosis():
					EvoManager.purge_necrosis()
					_log("dark:necrosis_purga")
				elif EvoManager.necrosis_toxicidad < 0.55 and EvoManager.can_buy_necrosis_agent():
					EvoManager.buy_necrosis_agent()
					_log("dark:necrosis_agente")
		"omega", "omega_starve":
			if EvoManager.omega_cero_gate_ready():
				ng._on_omega_cero_pressed()
				_log("dark:omega_cero")
			elif route == "omega" and EvoManager.mutation_omega_cero and EvoManager.omega_cero_can_seal() \
					and EvoManager.omega_cero_phi >= float(cfg.dark.get("omega_seal_phi", 0.0)) \
					and EvoManager.omega_cero_omega <= float(cfg.dark.get("omega_seal_max_omega", 1.0)):
				ng._on_omega_cero_seal_pressed()
				_log("dark:omega_sello")
		"remision":
			if EvoManager.remision_gate_ready():
				ng._on_remision_pressed()
				_log("dark:remision")
			elif EvoManager.mutation_remision:
				if EvoManager.remision_can_seal():
					ng._on_remision_seal_pressed()
					_log("dark:remision_sello")
				else:
					var c: float = DarkTreeLogic.remision_band_center()
					if EvoManager.remision_omega < c - 0.01:
						ng._on_remision_up_pressed()
					elif EvoManager.remision_omega > c + 0.01:
						ng._on_remision_down_pressed()


func _antibiosis_keys(a: Dictionary) -> void:
	if a.get("seal", false) and AntibiosisLogic.seal_ready():
		UIManager._ng_buttons._on_anti_seal_pressed()
		_log("seal:antibiosis")
		return
	if AntibiosisLogic.alive() == 0:
		_anti_seen_t = -1.0
		return
	if _anti_seen_t < 0.0:
		_anti_seen_t = RunManager.run_time
	if RunManager.run_time - _anti_seen_t < float(a.get("react", 0.0)):
		return
	# max_res: entre los antibióticos que no pasarían esa resistencia, el de más daño (si ninguno,
	# espera; salvo con 2 rivales vivos y sin strict).
	var mr: float = float(a.get("max_res", 9.0))
	var force: bool = not a.get("strict", false) and AntibiosisLogic.alive() >= Balance.ANTI_OVERRUN - 1
	var ab: String = ""
	if a.get("rotate", true):
		var best: float = -1.0
		for x in AntibiosisLogic.ABS:
			var ok: bool = force or float(EvoManager.anti_resist.get(x, 0.0)) + Balance.ANTI_RES_PER_USE <= mr + 0.0001
			if ok and AntibiosisLogic.damage(x) > best:
				best = AntibiosisLogic.damage(x)
				ab = x
	else:
		ab = "beta"
	if ab == "":
		return
	if AntibiosisLogic.can_shoot(ab):
		var k: int = AntibiosisLogic.alive()
		AntibiosisLogic.shoot(ab)
		_after_key("key:%s anti %s alive=%d" % [{"beta": "Q", "macro": "W", "tetra": "E"}[ab], ab, k])
		if AntibiosisLogic.alive() < k:
			_anti_seen_t = -1.0


func _procariota_keys(p: Dictionary) -> void:
	var want: String = str(p.get("plasmid", ""))
	if want != "" and EvoManager.proc_plasmid != want and ProcariotaLogic.can_swap_plasmid() \
			and ProcariotaLogic.frac() >= 0.5:
		ProcariotaLogic.swap_plasmid()
		_after_key("key:E proc_plasmid %s" % EvoManager.proc_plasmid)
	if ProcariotaLogic.can_quorum() and ProcariotaLogic.frac() >= float(p.get("quorum_at", 0.8)):
		var f: float = ProcariotaLogic.frac()
		ProcariotaLogic.quorum()
		_after_key("key:W proc_quorum f=%.2f x%.2f" % [f, EvoManager.proc_quorum_mult])
	if p.get("harvest_spam", false) and ProcariotaLogic.can_harvest():
		ProcariotaLogic.harvest()
		_after_key("key:Q proc_harvest n=%.1f" % EvoManager.proc_n)
	if p.get("seal", false) and ProcariotaLogic.seal_ready():
		UIManager._ng_buttons._on_proc_seal_pressed()
		_log("seal:procariota")


## INESTABILIDAD: el lema que el bot persigue ahora (impulso → inercia → Lyapunov → elasticidad). La
## inercia se saltea mientras P no alcance para sostener ε sin clicks.
func _inest_target() -> String:
	for id in ["impulso", "inercia", "lyapunov", "elasticidad"]:
		if InestabilidadLogic.is_revealed(id) and not InestabilidadLogic.is_proven(id):
			if id == "inercia" and EvoManager.inest_perturb + 0.05 < Balance.INEST_INERCIA_EPS:
				continue
			return id
	return ""

func _inest_cps(icfg: Dictionary) -> float:
	if icfg.has("cps"):
		return float(icfg.cps)  # sin termostato (jugador que no mira ε)
	var e: float = StructuralModel.epsilon_runtime
	match _inest_target():
		"impulso":
			return float(icfg.get("impulso_cps", 4.0))
		"inercia", "elasticidad":
			return 0.0
	# Lyapunov / nada abierto: termostato alrededor de ε ≈ 1.0.
	if e < 0.92:
		return 3.0
	if e < 1.0:
		return 1.5
	return 0.0

func _inest_keys(icfg: Dictionary) -> void:
	var e: float = StructuralModel.epsilon_runtime
	var open: int = EvoManager.inest_revealed - InestabilidadLogic.proven_count()
	# Trabado: 30 s sin progreso en ningún lema → observa aunque tenga lemas abiertos.
	var total: float = InestabilidadLogic.proven_count() * 1000.0
	for k in EvoManager.inest_progress:
		total += float(EvoManager.inest_progress[k])
	total += float(StructuralModel.get_structural_upgrades() - EvoManager.inest_struct_mark) if InestabilidadLogic.is_revealed("estructura") else 0.0
	if total > _inest_prog_total + 0.01:
		_inest_prog_total = total
		_inest_prog_t = RunManager.run_time
	var stuck: bool = RunManager.run_time - _inest_prog_t > 30.0
	if InestabilidadLogic.can_observe() and e < float(icfg.get("observe_below", 0.95)) \
			and (open < int(icfg.get("max_open", 2)) or stuck):
		InestabilidadLogic.observe()
		_after_key("key:Q inest_observe eps=%.2f open=%d" % [e, open])
	# Elasticidad: baja ε integrando hasta que Ω vuelva a ×1.75 su mínimo, sin pasar al converge (< 0.35).
	var integ_at: float = float(icfg.get("integrate_above", 1.08))
	if _inest_target() == "elasticidad" and StructuralModel.omega < InestabilidadLogic.elastic_target():
		integ_at = float(icfg.get("elastic_eps", 0.45))
	# Nada abierto y ε demasiado alto para mirar: integra para poder observar el próximo lema.
	if open == 0 and EvoManager.inest_revealed < InestabilidadLogic.LEMMAS.size():
		integ_at = minf(integ_at, float(icfg.get("observe_below", 0.95)))
	if not icfg.get("no_integrate", false) and e > integ_at \
			and InestabilidadLogic.can_integrate():
		InestabilidadLogic.integrate()
		_after_key("key:W inest_integrate eps=%.2f P=%.2f" % [e, EvoManager.inest_perturb])
	if icfg.get("seal", false) and InestabilidadLogic.seal_ready():
		UIManager._ng_buttons._on_inest_seal_pressed()
		_log("seal:inest")


func _after_key(label: String) -> void:
	UIManager.update_ng_plus_buttons()  # main._input() hace lo mismo tras cada tecla
	_log(label)


func _log(label: String) -> void:
	actions.append({"t": snappedf(RunManager.run_time, 0.001), "action": label})


## MUTUALISMO: entra al pacto y decide cada oferta según la política.
func _mutualismo(m: Dictionary) -> void:
	if m.get("pact", false) and MutualismoLogic.can_enter():
		UIManager._ng_buttons._on_mutualismo_pact_pressed()
		_log("mutualismo:pact")
	if not MutualismoLogic.is_active():
		return
	var offer: String = EvoManager.mutualismo_offer
	if offer != "" and EvoManager.mutualismo_decide_timer <= Balance.MUTUALISMO_DECIDE_TIME - float(m.get("react", 2.0)):
		var policy: String = str(m.get("policy", "fair"))
		if EvoManager.holobionte_active and m.has("holo_policy"):
			policy = str(m.get("holo_policy"))
		var r: float = EvoManager.mutualismo_r
		var band: float = Balance.MUTUALISMO_FAIR_BAND
		var take: bool
		match policy:
			"greedy":
				take = true
			"precise":
				# Acepta lo que acerca R a 0 (Tentación nunca): préstamo si R ≥ 0, auxilio si R ≤ 0.
				match offer:
					"tentacion": take = false
					"prestamo": take = r >= 0.0 and EvoManager.mutualismo_gratitude_due <= 0.0
					"auxilio": take = r <= 0.0
					_: take = true
			"naive":
				take = offer != "tentacion"
			_:
				match offer:
					"tentacion": take = false
					"prestamo": take = r - Balance.MUTUALISMO_LOAN_GET > -band  # que no deje R fuera de banda
					"auxilio": take = r + Balance.MUTUALISMO_AID_GIVE < band
					_: take = true
		if take and MutualismoLogic.can_accept():
			MutualismoLogic.accept()
			_after_key("key:A mutualismo:%s r=%.0f" % [offer, EvoManager.mutualismo_r])
		else:
			MutualismoLogic.reject()
			_after_key("key:R mutualismo:%s r=%.0f" % [offer, EvoManager.mutualismo_r])
	if m.get("seal", false) and MutualismoLogic.seal_ready() \
			and absf(EvoManager.mutualismo_r) <= float(m.get("seal_r", Balance.MUTUALISMO_FAIR_BAND)):
		UIManager._ng_buttons._on_mutualismo_seal_pressed()
		_log("seal:mutualismo")


## ENDOSIMBIOSIS: engulle, transfiere genes respetando el techo de rechazo y alimenta según la política.
func _endosimbiosis(e: Dictionary) -> void:
	if e.get("engulf", false) and EndosimbiosisLogic.can_engulf():
		UIManager._ng_buttons._on_endo_engulf_pressed()
		_log("endo:engulf")
	if not EndosimbiosisLogic.is_active():
		return
	if e.get("seal", false) and EndosimbiosisLogic.seal_ready():
		UIManager._ng_buttons._on_endo_seal_pressed()
		_log("seal:endosimbiosis")
		return
	var max_rej: float = float(e.get("max_rej", 1.0e9))
	if EndosimbiosisLogic.can_transfer() and EvoManager.endo_rejection + Balance.ENDO_TRANSFER_REJECTION <= max_rej:
		EndosimbiosisLogic.transfer()
		_after_key("key:Q endo:gen%d rej=%.0f aut=%.0f" % [EvoManager.endo_genes, EvoManager.endo_rejection, EvoManager.endo_autonomy])
		return
	var feed: String = str(e.get("feed", "smart"))
	var short: bool = EvoManager.endo_atp < EndosimbiosisLogic.gene_cost()
	var want_feed: bool = feed == "always" or (feed == "smart" and short and EvoManager.endo_autonomy >= float(e.get("feed_aut", 75.0)))
	if want_feed and EndosimbiosisLogic.can_feed() and short:
		EndosimbiosisLogic.feed()
		_after_key("key:W endo:feed atp=%.1f aut=%.0f" % [EvoManager.endo_atp, EvoManager.endo_autonomy])
