class_name EndosimbiosisLogic

## ENDOSIMBIOSIS — cruce PARASITISMO × SIMBIOSIS (Biología, T ≥ 2). Verbo: DOSIFICAR.
## "Hace dos mil millones de años una célula se tragó una bacteria y no la pudo digerir. Hoy se
## llama mitocondria." Spec: docs/design/biologia_mutualismo_endosimbiosis.md §6. Estado en
## EvoManager (endo_*); sólo funciones estáticas. Vive DENTRO de Simbiosis (excluye Mutualismo).
##
##   · Entrada: last_run Parasitismo (o Huésped Soberano) + Simbiosis activa → a los ENDO_WINDOW_START s
##     aparece ENGULLIR durante ENDO_WINDOW_LEN s.
##   · Dos economías: tu plata y el ATP del endosimbionte (ENDO_ATP_RATE × autonomía/100 por s).
##     Mientras no tenga Membrana drena ENDO_DRAIN del ingreso. [W] Alimentar: s de ingreso → ATP.
##   · [Q] Transferir el próximo gen (6, orden fijo): cuesta ATP, da su función, −autonomía, +rechazo.
##   · Rechazo ≥ 100 → la célula lo expulsa; autonomía ≥ 100 → se escapa. Las dos cierran como PARASITISMO.
##   · El 6º gen (Genoma) lo vuelve orgánulo: se congelan los medidores y se habilita el sello.

const GENES: Array = ["respiracion", "membrana", "replicacion", "senalizacion", "metabolismo", "genoma"]


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.endosimbiosis_active and EvoManager.mutation_symbiosis and not RunManager.run_closed

## La run anterior dejó un parásito (Parasitismo o su transmutación).
static func has_parasite_memory() -> bool:
	return LegacyManager.last_run_ending in ["PARASITISMO", "HUÉSPED SOBERANO"]

## Puede llegar a aparecer el botón (sin mirar la ventana de tiempo).
static func eligible() -> bool:
	return LegacyManager.trascendencia_count >= Balance.ENDOSIMBIOSIS_MIN_T and has_parasite_memory() \
		and RouteManager.allows_bifurcation() and not RunManager.run_closed \
		and EvoManager.mutation_symbiosis and not EvoManager.endosimbiosis_active \
		and not EvoManager.mutualismo_active and not EvoManager.mutation_coro_simbiotico \
		and EvoManager.red_branch_selected != EvoManager.RedBranch.SYMBIOSIS

static func can_engulf() -> bool:
	return eligible() and EvoManager.endo_window_t >= Balance.ENDO_WINDOW_START \
		and EvoManager.endo_window_t < Balance.ENDO_WINDOW_START + Balance.ENDO_WINDOW_LEN

static func engulf() -> void:
	if not can_engulf():
		return
	EvoManager.endosimbiosis_active = true
	EvoManager.endo_atp = Balance.ENDO_ATP_START
	EvoManager.endo_autonomy = Balance.ENDO_AUTONOMY_START
	EvoManager.endo_rejection = 0.0
	EvoManager.endo_genes = 0
	EvoManager.endo_engulf_time = RunManager.run_time
	LogManager.add(TranslationServer.translate("LOG_ENDOSIMBIOSIS_ON"))
	EvoManager.mutation_activated.emit("endosimbiosis", TranslationServer.translate("MUT_ENDOSIMBIOSIS"))
	AchievementManager.on_mutation_activated("endosimbiosis")
	UIManager.show_toast(TranslationServer.translate("TOAST_ENDOSIMBIOSIS_ON"))
	EvoManager._save_after_mutation()

static func has_gene(id: String) -> bool:
	return EvoManager.endosimbiosis_active and EvoManager.endo_genes > GENES.find(id)

static func is_organelle() -> bool:
	return EvoManager.endo_genes >= GENES.size()

static func next_gene() -> String:
	return GENES[EvoManager.endo_genes] if EvoManager.endo_genes < GENES.size() else ""

static func atp_rate() -> float:
	return Balance.ENDO_ATP_RATE * EvoManager.endo_autonomy / 100.0

static func gene_cost() -> float:
	return Balance.ENDO_GENE_COST * pow(Balance.ENDO_GENE_COST_GROWTH, EvoManager.endo_genes)

static func income() -> float:
	return maxf(EconomyManager.get_delta_total(), 1.0)


# ── [Q] Transferir · [W] Alimentar ───────────────────────────────────────────

static func can_transfer() -> bool:
	return is_active() and not is_organelle() and EvoManager.endo_atp >= gene_cost()

static func transfer() -> void:
	if not can_transfer():
		return
	var gene := next_gene()
	EvoManager.endo_atp -= gene_cost()
	# Todo gen suma rechazo, el Genoma también: si llega a 100, la célula lo expulsa en el acto.
	EvoManager.endo_rejection += Balance.ENDO_TRANSFER_REJECTION
	EvoManager.endo_peak_rejection = maxf(EvoManager.endo_peak_rejection, EvoManager.endo_rejection)
	if EvoManager.endo_rejection >= 100.0:
		RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_ENDO_REJECTED"))
		return
	EvoManager.endo_genes += 1
	if is_organelle():
		UIManager.show_toast(TranslationServer.translate("TOAST_ENDO_ORGANELLE"))
		if RunManager.run_time - EvoManager.endo_engulf_time < Balance.ACH_CONTRARRELOJ_SECS:
			AchievementManager.unlock("contrarreloj")
		return
	EvoManager.endo_autonomy = maxf(EvoManager.endo_autonomy - Balance.ENDO_TRANSFER_AUTONOMY, 0.0)
	UIManager.show_toast(TranslationServer.translate("TOAST_ENDO_GENE") % gene_name(gene))

static func feed_cost() -> float:
	return minf(income() * Balance.ENDO_FEED_SECS, EconomyManager.money)

static func can_feed() -> bool:
	return is_active() and not is_organelle() and EconomyManager.money > 0.0 and EvoManager.endo_feed_cd <= 0.0

## Paga hasta ENDO_FEED_SECS de ingreso (lo que haya) y lo convierte en ATP en proporción.
static func feed() -> void:
	if not can_feed():
		return
	var paid: float = feed_cost()
	EconomyManager.money -= paid
	EvoManager.endo_atp += Balance.ENDO_FEED_ATP * paid / (income() * Balance.ENDO_FEED_SECS)
	EvoManager.endo_feeds += 1
	EvoManager.endo_feed_cd = Balance.ENDO_FEED_COOLDOWN


## Tick (fase de procesos de ruta).
static func process(dt: float) -> void:
	# Ventana de ENGULLIR: cuenta desde que la Simbiosis es elegible.
	if eligible():
		EvoManager.endo_window_t += dt
		ProcariotaLogic.on_engulf_window(EvoManager.endo_window_t)  # Sombra: dejar pasar ENGULLIR
	if not is_active() or is_organelle():
		return
	EvoManager.endo_atp += atp_rate() * dt
	EvoManager.endo_feed_cd = maxf(EvoManager.endo_feed_cd - dt, 0.0)
	EvoManager.endo_rejection = maxf(EvoManager.endo_rejection - Balance.ENDO_REJECTION_DECAY * dt, 0.0)
	EvoManager.endo_autonomy = minf(EvoManager.endo_autonomy + Balance.ENDO_AUTONOMY_REGEN * dt, 100.0)
	if not has_gene("membrana"):
		EconomyManager.money = maxf(EconomyManager.money - income() * Balance.ENDO_DRAIN * dt, 0.0)
	if EvoManager.endo_rejection >= 100.0:
		RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_ENDO_REJECTED"))
	elif EvoManager.endo_autonomy >= 100.0:
		RunManager.close_run("PARASITISMO", TranslationServer.translate("CLOSE_ENDO_ESCAPED"))


# ── Economía (efectos de los genes transferidos) ─────────────────────────────

static func passive_mult() -> float:
	return Balance.ENDO_RESPIRACION_MULT if has_gene("respiracion") and is_active() else 1.0

static func click_mult() -> float:
	return Balance.ENDO_REPLICACION_MULT if has_gene("replicacion") and is_active() else 1.0

static func omega_bonus() -> float:
	return Balance.ENDO_SENALIZACION_OMEGA if has_gene("senalizacion") and is_active() else 0.0

static func cost_factor() -> float:
	return Balance.ENDO_METABOLISMO_DISCOUNT if has_gene("metabolismo") and is_active() else 1.0


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and is_organelle()

static func gene_name(id: String) -> String:
	return TranslationServer.translate("ENDO_GENE_" + id.to_upper())
