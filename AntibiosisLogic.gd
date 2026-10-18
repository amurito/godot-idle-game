class_name AntibiosisLogic

## ANTIBIOSIS — SOMBRA de SIMBIOSIS (ex Autarquía). Verbo: COMPETIR.
## "La antibiosis es lo contrario de la simbiosis: organismos que se dañan. Los hongos la inventaron:
## la penicilina sale de un hongo." Spec: docs/design/sombras.md §5 y §11. Estado en EvoManager (anti_*).
##
##   · Espejo (sin botón): con la llave, habiendo tenido Simbiosis elegible en la run, con hifas ≥ 5,
##     el click dominando y ε ≥ ANTI_MIRROR_EPS (competir en vez de cooperar con orden): acumular
##     ANTI_MIRROR_TIME s (un bajón descuenta a la mitad, no reinicia; el panel de ε muestra el progreso).
##   · Rivales: cada ANTI_SPAWN s (baja con cada eliminado) aparece una colonia rival; cada una viva
##     roba ingreso (× ANTI_STEAL^vivos). Nacen resistentes a un antibiótico (se ve en el panel).
##   · [Q] β-lactámico · [W] macrólido · [E] tetraciclina: dañan al rival más viejo. Cada uso suma
##     resistencia GLOBAL a ese antibiótico (se degrada sola): repetir rinde cada vez menos, hay que rotar.
##   · Sello: ANTI_SEAL_KILLS rivales eliminados. Fracaso (→ SIMBIOSIS): ANTI_OVERRUN rivales vivos a la vez.

const ABS := ["beta", "macro", "tetra"]


# ── Espejo ───────────────────────────────────────────────────────────────────

static func mirror_open() -> bool:
	return not EvoManager.mutation_antibiosis and LegacyManager.get_buff_level("sombra_antibiosis") > 0 \
		and EvoManager.anti_simb_seen and not InestabilidadLogic._route_taken() \
		and not EvoManager.transmut_reverted.get("simbiosis", false) and not RunManager.run_closed \
		and BiosphereEngine.hifas >= Balance.ANTI_MIRROR_HIFAS

## update_genome (cada logic tick).
static func update_mirror(ctx: Dictionary) -> void:
	if not EvoManager.anti_simb_seen and EvoManager.is_simbiosis_ready():
		EvoManager.anti_simb_seen = true
	if not mirror_open():
		EvoManager.anti_mirror_time = 0.0
		EvoManager._anti_mirror_countdown_last = -1
		return
	# Competir: la colonia grande ataca (click dominante) bajo estrés (ε alto) en vez de cooperar con orden.
	var ok: bool = ctx.act_domina and float(ctx.epsilon) >= Balance.ANTI_MIRROR_EPS
	if not ok:
		EvoManager.anti_mirror_time = maxf(EvoManager.anti_mirror_time - RunManager.LOGIC_TICK * Balance.ANTI_MIRROR_DECAY, 0.0)
		EvoManager._anti_mirror_countdown_last = -1
		return
	EvoManager.anti_mirror_time += RunManager.LOGIC_TICK
	if EvoManager.anti_mirror_time >= Balance.ANTI_MIRROR_TIME:
		EvoManager._anti_mirror_countdown_last = -1
		activate()
		return
	var left: float = Balance.ANTI_MIRROR_TIME - EvoManager.anti_mirror_time
	if left > Balance.INEST_MIRROR_WARN:
		return
	var secs_left := int(ceil(left))
	if secs_left != EvoManager._anti_mirror_countdown_last:
		EvoManager._anti_mirror_countdown_last = secs_left
		UIManager.show_toast(TranslationServer.translate("TOAST_ANTI_MIRROR_WARN") % secs_left)

static func activate() -> void:
	if EvoManager.mutation_antibiosis:
		return
	EvoManager.mutation_antibiosis = true
	EvoManager.anti_mirror_time = 0.0
	EvoManager.anti_spawn_timer = Balance.ANTI_FIRST_SPAWN
	EvoManager.anti_resist = {"beta": 0.0, "macro": 0.0, "tetra": 0.0}
	EvoManager._set_genome_state("simbiosis", "bloqueado")
	LogManager.add(TranslationServer.translate("LOG_ANTI_EFFECTS"))
	EvoManager.mutation_activated.emit("antibiosis", TranslationServer.translate("MUT_ANTIBIOSIS"))
	AchievementManager.on_mutation_activated("antibiosis")
	UIManager.show_toast(TranslationServer.translate("TOAST_ANTI_ON"))
	EvoManager._save_after_mutation()


# ── Estado ───────────────────────────────────────────────────────────────────

static func is_active() -> bool:
	return EvoManager.mutation_antibiosis and not RunManager.run_closed

static func alive() -> int:
	return EvoManager.anti_rivals.size()

static func spawn_interval() -> float:
	return maxf(Balance.ANTI_SPAWN - Balance.ANTI_SPAWN_STEP * EvoManager.anti_kills, Balance.ANTI_SPAWN_MIN)

## Resistencia efectiva de un rival a un antibiótico: la innata + la que generaste usándolo.
static func resistance(rival: Dictionary, ab: String) -> float:
	var innate: float = Balance.ANTI_INNATE_RES if str(rival.get("innate", "")) == ab else 0.0
	return minf(innate + float(EvoManager.anti_resist.get(ab, 0.0)), Balance.ANTI_RES_CAP)

## Ingreso × ANTI_STEAL^vivos: cada rival vivo te roba una parte.
static func steal_mult() -> float:
	if not EvoManager.mutation_antibiosis:
		return 1.0
	return pow(Balance.ANTI_STEAL, alive())


# ── Tick ─────────────────────────────────────────────────────────────────────

static func process(dt: float) -> void:
	if not is_active():
		return
	EvoManager.anti_shot_cd = maxf(EvoManager.anti_shot_cd - dt, 0.0)
	for ab in ABS:
		EvoManager.anti_resist[ab] = maxf(float(EvoManager.anti_resist.get(ab, 0.0)) - Balance.ANTI_RES_DECAY * dt, 0.0)
	EvoManager.anti_spawn_timer -= dt
	if EvoManager.anti_spawn_timer <= 0.0:
		EvoManager.anti_spawn_timer = spawn_interval()
		_spawn()

static func _spawn() -> void:
	var n: int = EvoManager.anti_spawned
	EvoManager.anti_spawned += 1
	# Resistencia innata por un hash entero (determinista, sin RNG global): se ve en el panel.
	var h: int = (n * 2654435761 + 97) & 0x7fffffff
	var hp: float = Balance.ANTI_HP + Balance.ANTI_HP_STEP * EvoManager.anti_kills
	EvoManager.anti_rivals.append({"hp": hp, "max": hp, "innate": ABS[h % ABS.size()]})
	EvoManager.anti_peak_alive = maxi(EvoManager.anti_peak_alive, alive())
	if alive() >= Balance.ANTI_OVERRUN:
		RunManager.close_run("SIMBIOSIS", TranslationServer.translate("CLOSE_ANTI_OVERRUN"))
		return
	UIManager.show_toast(TranslationServer.translate("TOAST_ANTI_RIVAL") % [
		TranslationServer.translate("ANTI_AB_" + str(EvoManager.anti_rivals[-1]["innate"]).to_upper()), alive(), Balance.ANTI_OVERRUN])


# ── [Q] [W] [E] Antibióticos ─────────────────────────────────────────────────

static func shot_cost() -> float:
	return maxf(EconomyManager.get_delta_total(), 1.0) * Balance.ANTI_SHOT_SECS

static func can_shoot(ab: String = "") -> bool:
	return is_active() and alive() > 0 and EvoManager.anti_shot_cd <= 0.0 and EconomyManager.money >= shot_cost()

## Daño que haría ahora `ab` al rival más viejo (para el panel y los botones).
static func damage(ab: String) -> float:
	if alive() == 0:
		return 0.0
	return Balance.ANTI_DMG * (1.0 - resistance(EvoManager.anti_rivals[0], ab))

static func shoot(ab: String) -> void:
	if not can_shoot(ab) or not (ab in ABS):
		return
	EconomyManager.money -= shot_cost()
	var dmg: float = damage(ab)
	var rival: Dictionary = EvoManager.anti_rivals[0]
	rival["hp"] = float(rival["hp"]) - dmg
	EvoManager.anti_resist[ab] = minf(float(EvoManager.anti_resist.get(ab, 0.0)) + Balance.ANTI_RES_PER_USE, Balance.ANTI_RES_CAP)
	EvoManager.anti_peak_resist = maxf(EvoManager.anti_peak_resist, float(EvoManager.anti_resist[ab]))
	EvoManager.anti_shot_cd = Balance.ANTI_SHOT_CD
	EvoManager.anti_shots += 1
	# Rotación: cuántos disparos seguidos sin repetir el antibiótico anterior (logro Rotación Perfecta).
	EvoManager.anti_rotation = EvoManager.anti_rotation + 1 if ab != EvoManager.anti_last_ab else 0
	EvoManager.anti_last_ab = ab
	if EvoManager.anti_rotation >= Balance.ACH_ANTI_ROTATION:
		AchievementManager.unlock("rotacion_perfecta")
	if float(rival["hp"]) <= 0.0:
		EvoManager.anti_rivals.remove_at(0)
		EvoManager.anti_kills += 1
		var bounty: float = maxf(EconomyManager.get_delta_total(), 1.0) * Balance.ANTI_KILL_SECS
		EconomyManager.money += bounty
		UIManager.show_toast(TranslationServer.translate("TOAST_ANTI_KILL") % [EvoManager.anti_kills, Balance.ANTI_SEAL_KILLS])


# ── Sello ────────────────────────────────────────────────────────────────────

static func seal_ready() -> bool:
	return is_active() and EvoManager.anti_kills >= Balance.ANTI_SEAL_KILLS


# ── Legado Penicilina: el parásito, a la vista ───────────────────────────────

## Líneas para el panel de ε: cuánto falta para cada disparador de Parasitismo (o su corrosión).
static func penicilina_lines() -> Array:
	var T := TranslationServer
	var out: Array = []
	if RunManager.run_closed:
		return out
	if EvoManager.mutation_parasitism:
		out.append(T.translate("STICKY_PENI_CORROSION") % ((1.0 - EconomyManager.parasitism_corrosion) * 100.0))
		return out
	if EvoManager.genome.get("parasitismo", "") == "bloqueado":
		return out
	var bio: float = BiosphereEngine.biomasa
	out.append(T.translate("STICKY_PENI_IDLE") % [EconomyManager.time_since_last_click, 120.0, bio, 3.0])
	if UpgradeManager.level("accounting") == 0:
		out.append(T.translate("STICKY_PENI_MASS") % [bio, StructuralModel.epsilon_runtime, minf(RunManager.run_time, 420.0)])
	return out
