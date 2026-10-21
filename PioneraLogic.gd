class_name PioneraLogic

## HIFA PIONERA — SOMBRA de RED MICELIAL (ex Núcleo Aislado). Verbo: EXPLORAR.
## "La Red se expande en todas direcciones. La Hifa Pionera es una sola punta que avanza sin ramificar."
## Spec: docs/design/sombras.md §7 y §13. Estado en EvoManager (pion_*); sólo funciones estáticas.
##
##   · Espejo (sin botón): con la llave, habiendo tenido Red Micelial latente en la run, comprar
##     PION_MIRROR_BUYS mejoras de click seguidas sin ninguna pasiva (crecer sin ramificar). Una compra
##     pasiva reinicia la cuenta.
##   · Mapa del sustrato 1D: la punta avanza sola (PION_SPEED m/s) y los clicks la empujan. Cada
##     PION_SEGMENT m hay una bifurcación: [Q] izquierda · [E] derecha · [W] sondear (revela las dos).
##     Ramas: nutrientes (+energía, ráfaga de ingreso), neutra, roca (frena), toxinas (−energía).
##   · Energía: baja al avanzar y al esperar en una bifurcación; sin elegir en PION_FORK_AUTO s, elige sola.
##   · Sello: PION_GOAL m. Fracaso: energía 0 → final propio HIFA EXTRAVIADA.

const PASSIVE_IDS := ["auto", "auto_mult", "trueque", "trueque_net", "specialization", "trueque_allo"]
const CLICK_IDS := ["click", "click_mult"]
const TILES := ["nutri", "neutro", "roca", "toxina"]
## Preferencia del jugador sensato (y del bot): nutrientes > neutra > roca > toxinas.
const TILE_RANK := {"nutri": 3, "neutro": 2, "roca": 1, "toxina": 0}


# ── Espejo ───────────────────────────────────────────────────────────────────

static func mirror_open() -> bool:
	return not EvoManager.mutation_hifa_pionera and LegacyManager.get_buff_level("sombra_pionera") > 0 \
		and EvoManager.pion_red_seen and not InestabilidadLogic._route_taken() and not RunManager.run_closed

## update_genome (cada logic tick): registra que Red Micelial estuvo latente.
static func update_mirror(_ctx: Dictionary) -> void:
	if not EvoManager.pion_red_seen and EvoManager.genome.get("red_micelial", "") == "latente":
		EvoManager.pion_red_seen = true

## UpgradeManager.purchase_upgrade (compra con plata exitosa).
static func on_purchase(id: String) -> void:
	if not mirror_open() or RunManager.run_time < Balance.PION_MIRROR_MIN_RUN:
		return
	if id in PASSIVE_IDS:
		if EvoManager.pion_streak > 0:
			EvoManager.pion_streak = 0
		return
	if not (id in CLICK_IDS):
		return
	EvoManager.pion_streak += 1
	if EvoManager.pion_streak >= Balance.PION_MIRROR_BUYS:
		activate()
	elif EvoManager.pion_streak >= Balance.PION_MIRROR_BUYS - 2:
		UIManager.show_toast(TranslationServer.translate("TOAST_PION_MIRROR_WARN") % (Balance.PION_MIRROR_BUYS - EvoManager.pion_streak))

static func activate() -> void:
	if EvoManager.mutation_hifa_pionera:
		return
	EvoManager.mutation_hifa_pionera = true
	EvoManager.pion_seed = LegacyManager.total_runs * 7919 + 13
	EvoManager.pion_energy = Balance.PION_ENERGY_START
	if LegacyManager.get_buff_value("legado_memoria_punta"):
		EvoManager.pion_energy += Balance.PION_MEMORY_ENERGY
	EvoManager.pion_min_energy = EvoManager.pion_energy
	EvoManager.pion_seg_type = "neutro"
	EvoManager.pion_seg_left = Balance.PION_SEGMENT
	EvoManager._set_genome_state("red_micelial", "bloqueado")
	LogManager.add(TranslationServer.translate("LOG_PION_EFFECTS"))
	EvoManager.mutation_activated.emit("hifa_pionera", TranslationServer.translate("MUT_HIFA_PIONERA"))
	AchievementManager.on_mutation_activated("hifa_pionera")
	UIManager.show_toast(TranslationServer.translate("TOAST_PION_ON"))
	EvoManager._save_after_mutation()


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutation_hifa_pionera and not RunManager.run_closed

static func at_fork() -> bool:
	return EvoManager.pion_at_fork

## Tipo de rama de la bifurcación `fork` (0 = izquierda, 1 = derecha): hash entero determinista.
static func tile(fork: int, side: int) -> String:
	# Mezcla de 32 bits tipo murmur (la multiplicación simple repetía rachas en índices consecutivos).
	var h: int = (fork * 2 + side + EvoManager.pion_seed * 1000003) & 0xffffffff
	h = (h * 0x9E3779B1) & 0xffffffff
	h ^= h >> 15
	h = (h * 0x85EBCA77) & 0xffffffff
	h ^= h >> 13
	h = (h * 0xC2B2AE3D) & 0xffffffff
	h ^= h >> 16
	var r: int = h % 100
	if r < Balance.PION_P_NUTRI:
		return "nutri"
	if r < Balance.PION_P_NUTRI + Balance.PION_P_NEUTRO:
		return "neutro"
	if r < Balance.PION_P_NUTRI + Balance.PION_P_NEUTRO + Balance.PION_P_ROCA:
		return "roca"
	return "toxina"

## Velocidad actual (m/s): base + empuje de los clicks, frenada en roca.
static func speed() -> float:
	var v: float = Balance.PION_SPEED + 0.5 * RouteUpgrades.level("pion_apical") + Balance.PION_CLICK_PUSH * EvoManager.pion_cps
	var rock: float = minf(Balance.PION_ROCK_SLOW + 0.15 * RouteUpgrades.level("pion_punta"), 1.0)
	return v * (rock if EvoManager.pion_seg_type == "roca" else 1.0)

## Energía máxima (mejora de ruta Reservas Lipídicas: +20/nivel).
static func energy_max() -> float:
	return Balance.PION_ENERGY_MAX + 20.0 * RouteUpgrades.level("pion_lipidos")

## Costo de sondear (mejora de ruta Quimiotropismo: −2/nivel).
static func probe_cost() -> float:
	return maxf(Balance.PION_PROBE_COST - 2.0 * RouteUpgrades.level("pion_quimio"), 0.0)

## Ráfaga de ingreso de un bolsillo de nutrientes.
static func burst_mult() -> float:
	return Balance.PION_NUTRI_BURST if EvoManager.mutation_hifa_pionera and EvoManager.pion_burst_timer > 0.0 else 1.0


# ── Hooks ────────────────────────────────────────────────────────────────────

static func on_click() -> void:
	if EvoManager.mutation_hifa_pionera:
		EvoManager.pion_cps += 1.0 / Balance.PION_CPS_TAU


# ── Tick ─────────────────────────────────────────────────────────────────────

static func process(dt: float) -> void:
	if not is_active():
		return
	EvoManager.pion_cps -= EvoManager.pion_cps * minf(dt / Balance.PION_CPS_TAU, 1.0)
	EvoManager.pion_burst_timer = maxf(EvoManager.pion_burst_timer - dt, 0.0)
	if at_fork():
		EvoManager.pion_energy -= Balance.PION_WAIT_DRAIN * dt
		EvoManager.pion_fork_wait += dt
		if EvoManager.pion_fork_wait >= Balance.PION_FORK_AUTO:
			choose(0, true)
	else:
		var step: float = speed() * dt
		EvoManager.pion_dist = minf(EvoManager.pion_dist + step, Balance.PION_GOAL)
		EvoManager.pion_seg_left -= step
		EvoManager.pion_energy -= Balance.PION_DRAIN * dt
		if EvoManager.pion_dist >= Balance.PION_GOAL:
			EvoManager.pion_seg_left = 0.0
		elif EvoManager.pion_seg_left <= 0.0:
			EvoManager.pion_at_fork = true
			EvoManager.pion_fork_wait = 0.0
			EvoManager.pion_revealed = false
	EvoManager.pion_min_energy = minf(EvoManager.pion_min_energy, EvoManager.pion_energy)
	if EvoManager.pion_energy <= 0.0:
		EvoManager.pion_energy = 0.0
		RunManager.close_run("HIFA EXTRAVIADA", TranslationServer.translate("CLOSE_PION_LOST"))


# ── [W] Sondear · [Q] / [E] elegir ───────────────────────────────────────────

static func can_probe() -> bool:
	return is_active() and at_fork() and not EvoManager.pion_revealed and EvoManager.pion_energy > probe_cost()

static func probe() -> void:
	if not can_probe():
		return
	EvoManager.pion_energy -= probe_cost()
	EvoManager.pion_revealed = true
	EvoManager.pion_probes += 1
	UIManager.show_toast(TranslationServer.translate("TOAST_PION_PROBE") % [
		TranslationServer.translate("PION_TILE_" + tile(EvoManager.pion_forks, 0).to_upper()),
		TranslationServer.translate("PION_TILE_" + tile(EvoManager.pion_forks, 1).to_upper())])

static func can_choose() -> bool:
	return is_active() and at_fork()

## Toma la rama `side` (0 izquierda, 1 derecha). `auto` = se eligió sola por esperar.
static func choose(side: int, auto: bool = false) -> void:
	if not can_choose():
		return
	var t: String = tile(EvoManager.pion_forks, side)
	if not EvoManager.pion_revealed:
		EvoManager.pion_blind_streak = EvoManager.pion_blind_streak + 1 if t != "toxina" else 0
		if EvoManager.pion_blind_streak >= Balance.ACH_PION_BLIND:
			AchievementManager.unlock("a_ciegas")
	else:
		EvoManager.pion_blind_streak = 0
	EvoManager.pion_forks += 1
	EvoManager.pion_at_fork = false
	EvoManager.pion_seg_type = t
	EvoManager.pion_seg_left = Balance.PION_SEGMENT
	match t:
		"nutri":
			EvoManager.pion_energy = minf(EvoManager.pion_energy + Balance.PION_NUTRI_ENERGY, energy_max())
			EvoManager.pion_burst_timer = Balance.PION_NUTRI_BURST_SECS
		"toxina":
			EvoManager.pion_energy -= maxf(Balance.PION_TOXIN_ENERGY - 5.0 * RouteUpgrades.level("pion_punta"), 0.0)
			EvoManager.pion_toxins += 1
	var key: String = "TOAST_PION_AUTO" if auto else "TOAST_PION_TILE"
	UIManager.show_toast(TranslationServer.translate(key) % TranslationServer.translate("PION_TILE_" + t.to_upper()))


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and EvoManager.pion_dist >= Balance.PION_GOAL


# ── Legado Mapa del Sustrato: el flujo de la biósfera, a la vista ────────────

static func substrate_line() -> String:
	var bio: float = 0.0
	if BiosphereEngine.hifas > 0.0 and BiosphereEngine.nutrientes > 0.0:
		bio = BiosphereEngine.hifas * sqrt(BiosphereEngine.nutrientes) * 0.02
	var nut: float = (StructuralModel.epsilon_runtime - StructuralModel.epsilon_effective) * 12.0
	return TranslationServer.translate("STICKY_MAPA_SUSTRATO") % [bio, nut]
