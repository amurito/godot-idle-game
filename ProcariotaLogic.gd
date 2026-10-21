class_name ProcariotaLogic

## PROCARIOTA — SOMBRA de ENDOSIMBIOSIS. Verbo: DIVIDIRSE.
## "Endosimbiosis es el nacimiento de la célula eucariota. Procariota es deshacerlo: el hongo expulsa
## sus orgánulos y vuelve a ser lo que fue antes de ser hongo." Spec: docs/design/sombras.md §4 y §10.
## Estado en EvoManager (proc_*); sólo funciones estáticas.
##
##   · Espejo (sin botón): con la llave, dejar pasar la ventana de ENGULLIR sin engullir. Reemplaza
##     a la Simbiosis de la run (sus efectos y sus cierres).
##   · Fisión binaria: población N con crecimiento logístico (se duplica cada PROC_DOUBLING s lejos
##     de la capacidad K). El ingreso escala con N (PROC_INCOME_MIN → PROC_INCOME_MAX).
##   · Toxinas: con N ≥ PROC_TOXIN_FRAC·K se acumulan; a PROC_TOXIN_LYSIS hay LISIS (N × PROC_LYSIS_KEEP).
##   · [Q] Cosechar: N a la mitad → plata. [W] Quorum (N ≥ PROC_QUORUM_FRAC·K): ráfaga
##     × (1 + PROC_QUORUM_K·N/K) durante PROC_QUORUM_DURATION s y N baja a PROC_QUORUM_AFTER·K.
##   · [E] Plásmido: cicla resistencia / virulencia / metabólico, cuesta PROC_PLASMID_COST de N.
##   · Sello: PROC_SEAL_QUORUMS quorums. Fracaso (→ SIMBIOSIS): PROC_LYSIS_FAIL lisis o cosechar
##     con N < PROC_EXTINCT_N (extinción).

const PLASMIDS := ["resistencia", "virulencia", "metabolico"]


# ── Espejo ───────────────────────────────────────────────────────────────────

## La llave está comprada y la run puede llegar a ofrecer ENGULLIR.
static func mirror_armed() -> bool:
	return LegacyManager.get_buff_level("sombra_procariota") > 0 and not EvoManager.mutation_procariota \
		and EndosimbiosisLogic.eligible()

## EndosimbiosisLogic.process, cada tick con la ventana corriendo: avisa al abrirse y, si se cierra
## sin engullir, el hongo expulsa sus orgánulos.
static func on_engulf_window(t: float) -> void:
	if not mirror_armed():
		return
	var start: float = Balance.ENDO_WINDOW_START
	if t >= start and not EvoManager._proc_window_warned:
		EvoManager._proc_window_warned = true
		UIManager.show_toast(TranslationServer.translate("TOAST_PROC_MIRROR_WARN"))
	if t >= start + Balance.ENDO_WINDOW_LEN:
		activate()

static func activate() -> void:
	if EvoManager.mutation_procariota:
		return
	EvoManager.mutation_procariota = true
	# Expulsa los orgánulos: la Simbiosis de la run deja de existir (efectos, sello y cierres).
	EvoManager.mutation_symbiosis = false
	EvoManager.transmut_reverted["simbiosis"] = true
	EvoManager._set_genome_state("simbiosis", "bloqueado")
	EvoManager.proc_n = Balance.PROC_N_START
	EvoManager.proc_peak_n = Balance.PROC_N_START
	LogManager.add(TranslationServer.translate("LOG_PROC_EFFECTS"))
	EvoManager.mutation_activated.emit("procariota", TranslationServer.translate("MUT_PROCARIOTA"))
	AchievementManager.on_mutation_activated("procariota")
	UIManager.show_toast(TranslationServer.translate("TOAST_PROC_ON"))
	EvoManager._save_after_mutation()


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutation_procariota and not RunManager.run_closed

static func frac() -> float:
	return clampf(EvoManager.proc_n / Balance.PROC_K, 0.0, 1.0)

static func has_plasmid(id: String) -> bool:
	return EvoManager.proc_plasmid == id

static func growth_rate() -> float:
	var r: float = log(2.0) / Balance.PROC_DOUBLING
	return r * (Balance.PROC_PLASMID_GROWTH if has_plasmid("metabolico") else 1.0) * (1.0 + 0.2 * RouteUpgrades.level("proc_medio"))

static func toxin_rate() -> float:
	return Balance.PROC_TOXIN_RATE * (Balance.PROC_PLASMID_TOXIN if has_plasmid("resistencia") else 1.0) * (1.0 - 0.2 * RouteUpgrades.level("proc_pared"))

static func quorum_k() -> float:
	return Balance.PROC_QUORUM_K + (Balance.PROC_PLASMID_QUORUM if has_plasmid("virulencia") else 0.0) + 0.75 * RouteUpgrades.level("proc_senal")


# ── Economía (IncomeModifiers) ───────────────────────────────────────────────

## La colonia es la economía: ingreso × (MIN → MAX según N/K), × la ráfaga del quorum.
static func colony_mult() -> float:
	if not EvoManager.mutation_procariota:
		return 1.0
	var m: float = lerpf(Balance.PROC_INCOME_MIN, Balance.PROC_INCOME_MAX, frac())
	if EvoManager.proc_quorum_timer > 0.0:
		m *= EvoManager.proc_quorum_mult
	return m


# ── Tick ─────────────────────────────────────────────────────────────────────

static func process(dt: float) -> void:
	if not is_active():
		return
	var k: float = Balance.PROC_K
	var n: float = EvoManager.proc_n
	EvoManager.proc_n = minf(n + growth_rate() * n * (1.0 - n / k) * dt, k)
	EvoManager.proc_peak_n = maxf(EvoManager.proc_peak_n, EvoManager.proc_n)
	EvoManager.proc_harvest_cd = maxf(EvoManager.proc_harvest_cd - dt, 0.0)
	EvoManager.proc_plasmid_cd = maxf(EvoManager.proc_plasmid_cd - dt, 0.0)
	if EvoManager.proc_quorum_timer > 0.0:
		EvoManager.proc_quorum_timer = maxf(EvoManager.proc_quorum_timer - dt, 0.0)
	# Saturación: cerca de K los desechos se acumulan; lejos de K se degradan.
	if frac() >= Balance.PROC_TOXIN_FRAC:
		if EvoManager.proc_toxin <= 0.0:
			UIManager.show_toast(TranslationServer.translate("TOAST_PROC_TOXIN_WARN"))
		EvoManager.proc_toxin += toxin_rate() * dt
	else:
		EvoManager.proc_toxin = maxf(EvoManager.proc_toxin - Balance.PROC_TOXIN_DECAY * dt, 0.0)
	if EvoManager.proc_toxin >= Balance.PROC_TOXIN_LYSIS:
		_lysis()

static func _lysis() -> void:
	EvoManager.proc_lyses += 1
	EvoManager.proc_toxin = 0.0
	EvoManager.proc_n *= Balance.PROC_LYSIS_KEEP
	if EvoManager.proc_lyses >= Balance.PROC_LYSIS_FAIL:
		RunManager.close_run("SIMBIOSIS", TranslationServer.translate("CLOSE_PROC_LYSIS"))
		return
	UIManager.show_toast(TranslationServer.translate("TOAST_PROC_LYSIS") % [EvoManager.proc_lyses, Balance.PROC_LYSIS_FAIL])


# ── [Q] Cosechar ─────────────────────────────────────────────────────────────

## Plata de cosechar ahora: la mitad de la colonia en s de ingreso.
static func harvest_value() -> float:
	return maxf(EconomyManager.get_delta_total(), 1.0) * Balance.PROC_HARVEST_SECS * frac() * 0.5

static func can_harvest() -> bool:
	return is_active() and EvoManager.proc_harvest_cd <= 0.0

static func harvest() -> void:
	if not can_harvest():
		return
	# Cosechar una colonia mínima la extingue.
	if EvoManager.proc_n < Balance.PROC_EXTINCT_N:
		RunManager.close_run("SIMBIOSIS", TranslationServer.translate("CLOSE_PROC_EXTINCT"))
		return
	var value: float = harvest_value()
	EconomyManager.money += value
	EvoManager.proc_n *= 0.5
	EvoManager.proc_harvests += 1
	EvoManager.proc_harvest_cd = Balance.PROC_HARVEST_CD
	UIManager.show_toast(TranslationServer.translate("TOAST_PROC_HARVEST") % UITextBuilders.format_compact(value))


# ── [W] Quorum ───────────────────────────────────────────────────────────────

static func can_quorum() -> bool:
	return is_active() and EvoManager.proc_quorum_timer <= 0.0 and frac() >= Balance.PROC_QUORUM_FRAC

static func quorum() -> void:
	if not can_quorum():
		return
	var f: float = frac()
	EvoManager.proc_quorum_mult = 1.0 + quorum_k() * f
	EvoManager.proc_quorum_timer = Balance.PROC_QUORUM_DURATION
	EvoManager.proc_quorums += 1
	EvoManager.proc_best_quorum_mult = maxf(EvoManager.proc_best_quorum_mult, EvoManager.proc_quorum_mult)
	if f < Balance.ACH_PROC_ABSOLUTE_FRAC:
		EvoManager.proc_quorum_all_high = false
	EvoManager.proc_n = Balance.PROC_K * Balance.PROC_QUORUM_AFTER
	UIManager.show_toast(TranslationServer.translate("TOAST_PROC_QUORUM") % [EvoManager.proc_quorum_mult,
		EvoManager.proc_quorums, Balance.PROC_SEAL_QUORUMS])


# ── [E] Plásmido ─────────────────────────────────────────────────────────────

static func next_plasmid() -> String:
	var i: int = PLASMIDS.find(EvoManager.proc_plasmid)
	return PLASMIDS[(i + 1) % PLASMIDS.size()]

static func can_swap_plasmid() -> bool:
	return is_active() and EvoManager.proc_plasmid_cd <= 0.0 and EvoManager.proc_n >= Balance.PROC_EXTINCT_N * 2.0

## Transferencia horizontal: cambia el gen que expresa la colonia; cuesta parte de la población.
static func swap_plasmid() -> void:
	if not can_swap_plasmid():
		return
	EvoManager.proc_plasmid = next_plasmid()
	EvoManager.proc_n *= 1.0 - Balance.PROC_PLASMID_COST
	EvoManager.proc_plasmid_cd = Balance.PROC_PLASMID_CD
	EvoManager.proc_plasmid_swaps += 1
	if not EvoManager.proc_plasmids_used.has(EvoManager.proc_plasmid):
		EvoManager.proc_plasmids_used[EvoManager.proc_plasmid] = true
		if EvoManager.proc_plasmids_used.size() >= PLASMIDS.size():
			AchievementManager.unlock("conjugacion")
	UIManager.show_toast(TranslationServer.translate("TOAST_PROC_PLASMID") % TranslationServer.translate("PROC_PLASMID_" + EvoManager.proc_plasmid.to_upper()))


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and EvoManager.proc_quorums >= Balance.PROC_SEAL_QUORUMS
