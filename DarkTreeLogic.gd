class_name DarkTreeLogic

## Lógica de process de todas las rutas del árbol oscuro (Met. Oscuro, sub-rutas, Depredador).
## El estado (vars) vive en EvoManager; este clase solo tiene funciones estáticas.
## Patrón idéntico a PrimordioLogic.gd.

const AUTOFAGIA_BURST_COOLDOWN := 60.0

# ── MET. OSCURO ──────────────────────────────────────────────────────────────

static func process_met_oscuro(dt: float) -> bool:
	EvoManager._met_oscuro_active_time += dt
	var income_rate := BiosphereEngine.biomasa * 0.8
	EvoManager._met_oscuro_income_accum += income_rate * dt
	if EvoManager._met_oscuro_income_accum >= 1.0:
		var gain: float = floor(EvoManager._met_oscuro_income_accum)
		EconomyManager.money += gain
		EvoManager._met_oscuro_income_accum -= gain
	var _bio_rate: float = Balance.AUTOLISIS_BIO_PASSIVE if EvoManager.mutation_autolisis else 0.1
	BiosphereEngine.biomasa += _bio_rate * dt
	StructuralModel.epsilon_runtime = max(0.0, StructuralModel.epsilon_runtime - 0.05 * dt)
	EvoManager._met_oscuro_status_timer += dt
	if EvoManager._met_oscuro_status_timer >= EvoManager.MET_OSCURO_STATUS_INTERVAL:
		EvoManager._met_oscuro_status_timer = 0.0
		if not EvoManager.mutation_autolisis and not EvoManager.mutation_necrosis and not EvoManager.mutation_remision:
			LogManager.add(TranslationServer.translate("LOG_MO_TICK") % [BiosphereEngine.biomasa, income_rate, EconomyManager.money])
	if not EvoManager.mutation_autolisis and not EvoManager.mutation_necrosis and not EvoManager.mutation_omega_cero and not EvoManager.mutation_remision:
		if BiosphereEngine.biomasa >= 100.0 and EvoManager._met_oscuro_active_time >= 30.0 and not RunManager.run_closed:
			LegacyManager.add_pl(2)
			RunManager.close_run("METABOLISMO OSCURO", TranslationServer.translate("CLOSE_MO_SATURACION"))
			return false
		if EconomyManager.money >= 1000000.0 and not RunManager.run_closed:
			RunManager.close_run("METABOLISMO OSCURO", TranslationServer.translate("CLOSE_MO_MILLONARIO"))
			return false
	return EvoManager._met_oscuro_active_time >= Balance.MET_OSCURO_SEAL_COOLDOWN

# ── AUTOFAGIA NECRÓTICA ───────────────────────────────────────────────────────

static func activate_autolisis() -> void:
	if EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_omega_cero or EvoManager.mutation_remision:
		return
	EvoManager.mutation_autolisis = true
	EvoManager.autolisis_devour_timer = 0.0
	EvoManager.mutation_activated.emit("autolisis", TranslationServer.translate("MUT_AUTOLISIS"))
	LogManager.add(TranslationServer.translate("LOG_AUTOLISIS_START"))
	UIManager.show_toast(TranslationServer.translate("TOAST_AUTOFAGIA_KEYS"))
	EvoManager._save_after_mutation()

## Intervalo efectivo entre devours, acortado por Enzimas Líticas (piso AUTOFAGIA_DEVOUR_FLOOR).
static func autofagia_devour_interval() -> float:
	var reduced: float = Balance.AUTOLISIS_DEVOUR_INTERVAL - EvoManager.autofagia_speed_level * Balance.AUTOFAGIA_SPEED_REDUCTION
	return max(Balance.AUTOFAGIA_DEVOUR_FLOOR, reduced)

## Probabilidad [0,1] del 2º devour por tick (Fagocitosis Doble). Capeada en MAX_CHANCE (80%).
static func autofagia_double_chance() -> float:
	return min(Balance.AUTOFAGIA_DOUBLE_MAX_CHANCE, EvoManager.autofagia_double_level * Balance.AUTOFAGIA_DOUBLE_PER_LEVEL)

## Tira 1 d20 contra una chance. Fallan round(20*(1-chance)) caras bajas.
static func _roll_autofagia_d20(chance: float) -> Dictionary:
	var fail_faces: int = clampi(int(round(20.0 * (1.0 - chance))), 0, 20)
	var success_min: int = fail_faces + 1
	var roll: int = randi_range(1, 20)
	return {"roll": roll, "success_min": success_min, "success": roll >= success_min}

## Devora el upgrade más caro y aplica el burst. Retorna true si quedaba material.
static func _autofagia_consume_one() -> bool:
	var result: Dictionary = UpgradeManager.devour_most_expensive_upgrade()
	if not result.devoured:
		return false
	EvoManager.autolisis_devour_count += 1
	var burst_money: float = min(result.cost * Balance.AUTOLISIS_MONEY_BURST_MULT, Balance.AUTOLISIS_MONEY_BURST_CAP)
	EconomyManager.money += burst_money
	var bio_burst: float = max(Balance.AUTOLISIS_BIO_BURST, result.cost / Balance.AUTOLISIS_BIO_FROM_COST_DIVISOR)
	bio_burst = min(bio_burst, Balance.AUTOLISIS_BIO_BURST_CAP)
	if LegacyManager.get_buff_value("ciclo_catabolico"):
		bio_burst *= Balance.CICLO_CATABOLICO_BIO_MULT
	BiosphereEngine.biomasa += bio_burst
	UIManager.show_toast(TranslationServer.translate("TOAST_AUTOLISIS_DEVOUR") % [EvoManager.autolisis_devour_count, burst_money, bio_burst])
	LogManager.add(TranslationServer.translate("LOG_AUTOLISIS_DEVOUR") % [EvoManager.autolisis_devour_count, burst_money, bio_burst])
	return true

## Tick de autólisis. Cada intervalo devora el upgrade más caro; con Fagocitosis Doble puede devorar hasta 3.
static func process_autolisis(dt: float) -> void:
	if EvoManager.autofagia_burst_cooldown > 0.0:
		EvoManager.autofagia_burst_cooldown = max(0.0, EvoManager.autofagia_burst_cooldown - dt)
	EvoManager.autolisis_devour_timer += dt
	if EvoManager.autolisis_devour_timer < autofagia_devour_interval():
		return
	EvoManager.autolisis_devour_timer = 0.0
	if not _autofagia_consume_one():
		if not RunManager.run_closed:
			RunManager.close_run("AUTOFAGIA NECRÓTICA", TranslationServer.translate("CLOSE_AUTOLISIS_AGOTADO"))
		return
	var chance := autofagia_double_chance()
	if chance <= 0.0:
		return
	var d := _roll_autofagia_d20(chance)
	var extra: int = 0
	if d.success:
		extra = 2 if d.roll >= Balance.AUTOFAGIA_TRIPLE_CRIT else 1
	EvoManager.autofagia_dice_rolled.emit(d.roll, d.success_min, extra)
	for _i in range(extra):
		if not _autofagia_consume_one():
			if not RunManager.run_closed:
				RunManager.close_run("AUTOFAGIA NECRÓTICA", TranslationServer.translate("CLOSE_AUTOLISIS_AGOTADO"))
			return

## Colapso voluntario del núcleo (cierre manual). Disponible tras N devours.
static func autofagia_colapsar() -> void:
	if RunManager.run_closed or not EvoManager.mutation_autolisis:
		return
	if EvoManager.autolisis_devour_count < Balance.AUTOFAGIA_COLAPSO_MIN_DEVOURS:
		return
	RunManager.close_run("AUTOFAGIA NECRÓTICA", TranslationServer.translate("CLOSE_AUTOFAGIA_COLAPSO"), true)

## kind: "speed" | "double". Retorna {bio, money, level, maxed}.
static func autofagia_upgrade_cost(kind: String) -> Dictionary:
	var lvl: int = EvoManager.autofagia_speed_level if kind == "speed" else EvoManager.autofagia_double_level
	var maxv: int = Balance.AUTOFAGIA_SPEED_MAX_LEVEL if kind == "speed" else Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL
	var scale: float = pow(Balance.AUTOFAGIA_UPG_COST_GROWTH, lvl)
	return {
		"bio": Balance.AUTOFAGIA_UPG_BIO_BASE * scale,
		"money": Balance.AUTOFAGIA_UPG_MONEY_BASE * scale,
		"level": lvl,
		"maxed": lvl >= maxv,
	}

## Devours requeridos para comprar el SIGUIENTE nivel de Fagocitosis Doble (0 si no hay gate).
static func autofagia_double_gate_req() -> int:
	var next_level: int = EvoManager.autofagia_double_level + 1
	return int(Balance.AUTOFAGIA_DOUBLE_GATE.get(next_level, 0))

static func can_buy_autofagia_upgrade(kind: String) -> bool:
	if not EvoManager.mutation_autolisis or RunManager.run_closed:
		return false
	var c: Dictionary = autofagia_upgrade_cost(kind)
	if c.maxed:
		return false
	if kind == "double" and EvoManager.autolisis_devour_count < autofagia_double_gate_req():
		return false
	return BiosphereEngine.biomasa >= c.bio and EconomyManager.money >= c.money

static func buy_autofagia_upgrade(kind: String) -> bool:
	if not can_buy_autofagia_upgrade(kind):
		return false
	var c: Dictionary = autofagia_upgrade_cost(kind)
	BiosphereEngine.biomasa -= c.bio
	EconomyManager.money -= c.money
	if kind == "speed":
		EvoManager.autofagia_speed_level += 1
		LogManager.add(TranslationServer.translate("LOG_AUTOFAGIA_SPEED") % EvoManager.autofagia_speed_level)
	else:
		EvoManager.autofagia_double_level += 1
		LogManager.add(TranslationServer.translate("LOG_AUTOFAGIA_DOUBLE") % int(autofagia_double_chance() * 100))
	AudioManager.play_sfx("upgrade")
	return true

## True si la Digestión Masiva está disponible: ambas mejoras en MAX, recursos suficientes,
## ≥ 3 upgrades restantes y sin cooldown.
static func can_autofagia_digest_burst() -> bool:
	if not EvoManager.mutation_autolisis or RunManager.run_closed:
		return false
	if EvoManager.autofagia_speed_level < Balance.AUTOFAGIA_SPEED_MAX_LEVEL:
		return false
	if EvoManager.autofagia_double_level < Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL:
		return false
	if UpgradeManager.get_owned_levels_count() < 3:
		return false
	if EvoManager.autofagia_burst_cooldown > 0.0:
		return false
	return BiosphereEngine.biomasa >= Balance.AUTOFAGIA_BURST_BIO_COST and EconomyManager.money >= Balance.AUTOFAGIA_BURST_MONEY_COST

## Consume la mitad de los upgrades restantes de golpe. Retorna devours hechos.
static func autofagia_digest_burst() -> int:
	if not can_autofagia_digest_burst():
		return 0
	BiosphereEngine.biomasa -= Balance.AUTOFAGIA_BURST_BIO_COST
	EconomyManager.money -= Balance.AUTOFAGIA_BURST_MONEY_COST
	var levels: int = UpgradeManager.get_owned_levels_count()
	var to_devour: int = maxi(1, levels / 2)
	var done: int = 0
	for _i in range(to_devour):
		if not _autofagia_consume_one():
			break
		done += 1
	EvoManager.autofagia_burst_cooldown = AUTOFAGIA_BURST_COOLDOWN
	if done > 0:
		UIManager.show_toast(TranslationServer.translate("TOAST_AUTOFAGIA_BURST") % done)
		LogManager.add(TranslationServer.translate("LOG_AUTOFAGIA_BURST") % [done, EvoManager.autolisis_devour_count])
	return done

# ── NECROSIS CONTROLADA ───────────────────────────────────────────────────────

## Activa la sub-ruta. Necrosis toma control de Ω y abre la doble economía.
## Requisito de economía de Necrosis: Δ$/s al ENTRAR a Met. Oscuro (o el actual, si es mayor).
## Medirlo con el Δ de adentro de MO lo hacía casi imposible en T3+ (G11): para bajar de $1000 hay
## que achicar la economía comprando tiempo, y adentro de MO no se puede comprar.
static func necrosis_flow_ok() -> bool:
	return maxf(EvoManager.met_oscuro_entry_delta, EconomyManager.get_delta_total()) >= Balance.NECROSIS_FLOW_REQ

static func activate_necrosis() -> void:
	if EvoManager.mutation_necrosis or EvoManager.mutation_autolisis or EvoManager.mutation_omega_cero or EvoManager.mutation_remision:
		return
	EvoManager.mutation_necrosis = true
	EvoManager.necrosis_omega = Balance.NECROSIS_OMEGA_START
	EvoManager.necromasa = 0.0
	EvoManager.necrosis_agent_count = 0
	EvoManager.necrosis_active_time = 0.0
	EvoManager.necrosis_toxicidad = 0.0
	EvoManager.necrosis_tox_maxed = false
	EvoManager.necrosis_overdose = false
	EvoManager.necrosis_catalyst_level = 0
	EvoManager.mutation_activated.emit("necrosis", TranslationServer.translate("MUT_NECROSIS"))
	LogManager.add(TranslationServer.translate("LOG_NECROSIS_START"))
	UIManager.show_toast(TranslationServer.translate("TOAST_NECROSIS_KEYS"))
	EvoManager._save_after_mutation()

## Multiplicador necrótico: rampa suave que premia cada paso, capeada cerca del floor.
static func necrosis_mult() -> float:
	if not EvoManager.mutation_necrosis:
		return 1.0
	var safe_omega: float = max(EvoManager.necrosis_omega, Balance.NECROSIS_OMEGA_FLOOR)
	return clampf(Balance.NECROSIS_OMEGA_START / safe_omega, 1.0, Balance.NECROSIS_MULT_CAP)

## Índice necrótico [0,1]: progreso desde Ω inicial hasta el floor (para barra de progreso).
static func necrosis_index() -> float:
	var span: float = Balance.NECROSIS_OMEGA_START - Balance.NECROSIS_OMEGA_FLOOR
	return clampf((Balance.NECROSIS_OMEGA_START - EvoManager.necrosis_omega) / max(span, 0.0001), 0.0, 1.0)

## Costo en Ν del próximo Agente Necrótico.
static func necrosis_agent_cost() -> float:
	return Balance.NECROSIS_AGENT_COST_BASE * pow(Balance.NECROSIS_AGENT_COST_GROWTH, EvoManager.necrosis_agent_count)

static func can_buy_necrosis_agent() -> bool:
	if not EvoManager.mutation_necrosis or RunManager.run_closed:
		return false
	return EvoManager.necromasa >= necrosis_agent_cost()

## Compra un Agente Necrótico: baja Ω (×factor), sube el multiplicador Y la toxicidad (escalada).
static func buy_necrosis_agent() -> bool:
	if not can_buy_necrosis_agent():
		return false
	EvoManager.necromasa -= necrosis_agent_cost()
	EvoManager.necrosis_agent_count += 1
	EvoManager.necrosis_omega *= Balance.NECROSIS_AGENT_OMEGA_FACTOR
	var tox_add: float = Balance.NECROSIS_TOX_PER_AGENT * (1.0 + (EvoManager.necrosis_agent_count - 1) * Balance.NECROSIS_TOX_SCALE_PER_AGENT)
	EvoManager.necrosis_toxicidad = minf(1.0, EvoManager.necrosis_toxicidad + tox_add)
	if EvoManager.necrosis_toxicidad >= 0.99:
		EvoManager.necrosis_tox_maxed = true
		_trigger_necrosis_overdose()
	AudioManager.play_sfx("upgrade")
	LogManager.add(TranslationServer.translate("LOG_NECROSIS_AGENT") % [EvoManager.necrosis_agent_count, EvoManager.necrosis_omega])
	if EvoManager.necrosis_omega <= Balance.NECROSIS_OMEGA_FLOOR and not RunManager.run_closed:
		RunManager.close_run("NECROSIS CONTROLADA", TranslationServer.translate("CLOSE_NECROSIS"))
	return true

## SOBREDOSIS TÓXICA: destruye toda la Ν y bloquea la generación hasta que tox < OVERDOSE_RECOVER.
static func _trigger_necrosis_overdose() -> void:
	if EvoManager.necrosis_overdose:
		return
	EvoManager.necromasa = 0.0
	EvoManager.necrosis_overdose = true
	LogManager.add(TranslationServer.translate("LOG_NECROSIS_OVERDOSE"))

## Factor de eficiencia [piso,1] de generación de Ν. En sobredosis = 0.0.
static func necrosis_efficiency() -> float:
	if EvoManager.necrosis_overdose:
		return 0.0
	var tox_excess: float = maxf(0.0, EvoManager.necrosis_toxicidad - necrosis_tox_floor())
	return clampf(1.0 - tox_excess, Balance.NECROSIS_EFF_FLOOR, 1.0)

## Tasa de Ν pasiva (% del pasivo de economía, gateada por eficiencia y catalizador).
static func necrosis_passive_rate() -> float:
	if not EvoManager.mutation_necrosis or RunManager.run_closed:
		return 0.0
	return EconomyManager.get_passive_total() * Balance.NECROSIS_PASSIVE_FRACTION * necrosis_efficiency() * necrosis_catalyst_mult()

## Ν estimada por el próximo click (para display en MSTAT).
static func necrosis_click_preview() -> float:
	var power: float = EconomyManager.get_click_power()
	var base: float = pow(maxf(power, 0.0), Balance.NECROSIS_MASA_EXP) * Balance.NECROSIS_CONVERSION
	return base * necrosis_efficiency() * necrosis_catalyst_mult()

## Multiplicador de Ν del Catalizador Necrótico (aditivo: 1 + nivel×0.20).
static func necrosis_catalyst_mult() -> float:
	return 1.0 + EvoManager.necrosis_catalyst_level * Balance.NECROSIS_CATALYST_PER_LEVEL

## Ν generada por un click (sublineal en el poder, gateada por toxicidad, ×catalizador).
static func add_necromasa_from_click(power: float) -> void:
	if not EvoManager.mutation_necrosis or RunManager.run_closed:
		return
	var base: float = pow(max(power, 0.0), Balance.NECROSIS_MASA_EXP) * Balance.NECROSIS_CONVERSION
	EvoManager.necromasa += base * necrosis_efficiency() * necrosis_catalyst_mult()

## Costo en Ν del próximo nivel de Catalizador (escala ×2 por nivel).
static func necrosis_catalyst_cost() -> float:
	return Balance.NECROSIS_CATALYST_COST_BASE * pow(Balance.NECROSIS_CATALYST_COST_GROWTH, EvoManager.necrosis_catalyst_level)

static func can_buy_necrosis_catalyst() -> bool:
	if not EvoManager.mutation_necrosis or RunManager.run_closed:
		return false
	return EvoManager.necromasa >= necrosis_catalyst_cost()

## Compra un nivel de Catalizador: gasta Ν y sube el multiplicador de generación de Ν.
static func buy_necrosis_catalyst() -> bool:
	if not can_buy_necrosis_catalyst():
		return false
	EvoManager.necromasa -= necrosis_catalyst_cost()
	EvoManager.necrosis_catalyst_level += 1
	AchievementManager.push_event("necrosis_catalyst_bought", {})
	AudioManager.play_sfx("upgrade")
	LogManager.add(TranslationServer.translate("LOG_NECROSIS_CATALYST") % [EvoManager.necrosis_catalyst_level, int(necrosis_catalyst_mult() * 100.0)])
	return true

## Costo de una Depuración. Cuadrático en toxicidad.
static func necrosis_purge_cost() -> float:
	return Balance.NECROSIS_PURGE_COST_BASE * (1.0 + EvoManager.necrosis_toxicidad * EvoManager.necrosis_toxicidad * 5.0)

## Floor de toxicidad según agentes desplegados.
static func necrosis_tox_floor() -> float:
	return EvoManager.necrosis_agent_count * Balance.NECROSIS_TOX_FLOOR_PER_AGENT

static func can_purge_necrosis() -> bool:
	if not EvoManager.mutation_necrosis or RunManager.run_closed:
		return false
	return EvoManager.necrosis_toxicidad > necrosis_tox_floor() + 0.05 and EvoManager.necromasa >= necrosis_purge_cost()

## Depuración: gastás Ν para reducir la toxicidad, clampea al floor.
static func purge_necrosis() -> bool:
	if not can_purge_necrosis():
		return false
	EvoManager.necromasa -= necrosis_purge_cost()
	EvoManager.necrosis_toxicidad = maxf(necrosis_tox_floor(), EvoManager.necrosis_toxicidad * Balance.NECROSIS_PURGE_FRACTION)
	AudioManager.play_sfx("upgrade")
	LogManager.add(TranslationServer.translate("LOG_NECROSIS_PURGE") % (EvoManager.necrosis_toxicidad * 100.0))
	return true

## Tick de necrosis: cuenta el tiempo activo, decae toxicidad y verifica recuperación de sobredosis.
static func process_necrosis(dt: float) -> void:
	if not EvoManager.mutation_necrosis or RunManager.run_closed:
		return
	EvoManager.necrosis_active_time += dt
	var tox_floor: float = necrosis_tox_floor()
	if EvoManager.necrosis_toxicidad > tox_floor:
		EvoManager.necrosis_toxicidad = maxf(tox_floor, EvoManager.necrosis_toxicidad - Balance.NECROSIS_TOX_DECAY * dt)
	if EvoManager.necrosis_overdose and EvoManager.necrosis_toxicidad < Balance.NECROSIS_TOX_OVERDOSE_RECOVER:
		EvoManager.necrosis_overdose = false
		LogManager.add(TranslationServer.translate("LOG_NECROSIS_OVERDOSE_RECOVER"))
	EvoManager.necromasa += necrosis_passive_rate() * dt

# ── PROTOCOLO OMEGA-CERO ──────────────────────────────────────────────────────

## ¿El jugador desbloqueó el protocolo y cumple el gate en-run?
static func omega_cero_gate_ready() -> bool:
	if RunManager.run_closed or not EvoManager.mutation_met_oscuro:
		return false
	if EvoManager.mutation_omega_cero or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_remision:
		return false
	if LegacyManager.trascendencia_count < 2:
		return false
	if not LegacyManager.get_buff_value("protocolo_omega_cero"):
		return false
	return BiosphereEngine.biomasa >= Balance.OMEGA_CERO_BIO_REQ \
		and EvoManager.met_oscuro_devoured_count >= Balance.OMEGA_CERO_DEVOUR_REQ

## Activa el protocolo. Toma control de Ω y abre el loop de síntesis.
static func activate_omega_cero() -> void:
	if EvoManager.mutation_omega_cero or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_remision:
		return
	EvoManager.mutation_omega_cero = true
	EvoManager.omega_cero_phi = 0.0
	EvoManager.omega_cero_devour_count = 0
	EvoManager.omega_cero_devour_timer = 0.0
	EvoManager.omega_cero_omega = Balance.OMEGA_CERO_OMEGA_START
	EvoManager._omega_cero_starve_ticks = 0
	EvoManager.mutation_activated.emit("omega_cero", TranslationServer.translate("MUT_OMEGA_CERO"))
	LogManager.add(TranslationServer.translate("LOG_OMEGA_CERO_START"))
	UIManager.show_toast(TranslationServer.translate("TOAST_OMEGA_CERO_KEYS"))
	EvoManager._save_after_mutation()

## Multiplicador de Φ por devour: escala con la rigidez (Ω bajo amplifica), capeado.
static func omega_cero_phi_mult() -> float:
	if not EvoManager.mutation_omega_cero:
		return 1.0
	var safe_omega: float = max(EvoManager.omega_cero_omega, Balance.OMEGA_CERO_OMEGA_FLOOR)
	return clampf(Balance.OMEGA_CERO_K / safe_omega, 1.0, Balance.OMEGA_CERO_PHI_CAP)

## Progreso [0,1] hacia el sello (Φ acumulada / target).
static func omega_cero_progress() -> float:
	return clampf(EvoManager.omega_cero_phi / Balance.OMEGA_CERO_PHI_TARGET, 0.0, 1.0)

## El sello está disponible cuando se alcanzó el target de Φ.
static func omega_cero_can_seal() -> bool:
	return EvoManager.mutation_omega_cero and not RunManager.run_closed \
		and EvoManager.omega_cero_phi >= Balance.OMEGA_CERO_PHI_TARGET

## Consume un upgrade del batch. Retorna el costo, o -1.0 si no hay material.
static func _omega_cero_consume_upgrade() -> float:
	var result: Dictionary = UpgradeManager.devour_most_expensive_upgrade()
	if not result.devoured:
		return -1.0
	EconomyManager.money += result.cost * Balance.OMEGA_CERO_MONEY_BURST_MULT
	return result.cost

## Tick del protocolo. Batch de hasta BATCH_SIZE consumos por tick, Φ y Ω se aplican UNA VEZ.
static func process_omega_cero(dt: float) -> void:
	if not EvoManager.mutation_omega_cero or RunManager.run_closed:
		return
	EvoManager.omega_cero_devour_timer += dt
	if EvoManager.omega_cero_devour_timer < Balance.OMEGA_CERO_DEVOUR_INTERVAL:
		return
	EvoManager.omega_cero_devour_timer = 0.0

	var batch_count: int = 0
	for _i in range(Balance.OMEGA_CERO_BATCH_SIZE):
		if _omega_cero_consume_upgrade() < 0.0:
			break
		batch_count += 1

	if batch_count == 0:
		EvoManager._omega_cero_starve_ticks += 1
		if EvoManager._omega_cero_starve_ticks > Balance.OMEGA_CERO_STARVE_GRACE:
			EvoManager.omega_cero_phi = maxf(EvoManager.omega_cero_phi - Balance.OMEGA_CERO_PHI_DECAY_TICK, 0.0)
			UIManager.show_toast(TranslationServer.translate("TOAST_OMEGA_CERO_INANICION") % [EvoManager.omega_cero_phi, EvoManager._omega_cero_starve_ticks - Balance.OMEGA_CERO_STARVE_GRACE])
			if EvoManager.omega_cero_phi <= 0.0 and not RunManager.run_closed:
				_omega_cero_finalize()
				RunManager.close_run("COLAPSO SINTÉTICO", TranslationServer.translate("CLOSE_OMEGA_CERO_COLAPSO"))
		return

	EvoManager._omega_cero_starve_ticks = 0
	EvoManager.omega_cero_devour_count += 1
	EvoManager.omega_cero_omega = maxf(EvoManager.omega_cero_omega * Balance.OMEGA_CERO_OMEGA_FACTOR, Balance.OMEGA_CERO_OMEGA_FLOOR)
	var phi_gain: float = Balance.OMEGA_CERO_PHI_BASE * omega_cero_phi_mult()
	EvoManager.omega_cero_phi += phi_gain
	UIManager.show_toast(TranslationServer.translate("TOAST_OMEGA_CERO_DEVOUR") % [batch_count, EvoManager.omega_cero_devour_count, phi_gain, EvoManager.omega_cero_omega])
	LogManager.add(TranslationServer.translate("LOG_OMEGA_CERO_DEVOUR") % [batch_count, EvoManager.omega_cero_devour_count, phi_gain, EvoManager.omega_cero_omega])
	if EvoManager.omega_cero_omega <= Balance.OMEGA_CERO_OMEGA_FLOOR and not RunManager.run_closed:
		_omega_cero_finalize()
		RunManager.close_run("PROTOCOLO OMEGA-CERO", TranslationServer.translate("CLOSE_OMEGA_CERO_FLOOR"))

## Sello intencional (eco escleroidal): el hongo decide que la síntesis está completa.
static func omega_cero_seal() -> void:
	if not omega_cero_can_seal():
		return
	_omega_cero_finalize()
	RunManager.close_run("PROTOCOLO OMEGA-CERO", TranslationServer.translate("CLOSE_OMEGA_CERO_SEAL"))

## Fija el Núcleo Φ (intensidad del buff NG+) antes de cerrar. Capeado.
static func _omega_cero_finalize() -> void:
	EvoManager.omega_cero_kernel = clampf(EvoManager.omega_cero_phi / Balance.OMEGA_CERO_PHI_TARGET, 1.0, Balance.OMEGA_CERO_KERNEL_CAP)

# ── REMISIÓN METABÓLICA ───────────────────────────────────────────────────────

## ¿El jugador desbloqueó el permiso y cumple el gate en-run? Última ruta del árbol oscuro.
static func remision_gate_ready() -> bool:
	if RunManager.run_closed or not EvoManager.mutation_met_oscuro:
		return false
	if EvoManager.mutation_omega_cero or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_remision:
		return false
	if EvoManager.remision_locked_run:
		return false
	if not LegacyManager.get_buff_value("remision_metabolica"):
		return false
	return BiosphereEngine.biomasa >= Balance.REMISION_BIO_GATE

## Activa la ruta. Toma control de Ω y abre el loop de sanación.
static func activate_remision() -> void:
	if EvoManager.mutation_remision or EvoManager.mutation_omega_cero or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis:
		return
	EvoManager.mutation_remision = true
	EvoManager.remision_omega = Balance.REMISION_OMEGA_START
	EvoManager.remision_theta = 0.0
	EvoManager.remision_band_timer = 0.0
	EvoManager.remision_sealable = false
	EvoManager.mutation_activated.emit("remision", TranslationServer.translate("MUT_REMISION"))
	LogManager.add(TranslationServer.translate("LOG_REMISION_START"))
	UIManager.show_toast(TranslationServer.translate("TOAST_REMISION_KEYS"))
	EvoManager._save_after_mutation()

## Centro actual de la banda objetivo (se desplaza senoidal lento).
static func remision_band_center() -> float:
	return Balance.REMISION_BAND_CENTER + Balance.REMISION_BAND_AMP * sin(EvoManager.remision_band_timer * Balance.REMISION_BAND_FREQ)

## ¿Ω dentro de la banda objetivo en este instante?
static func remision_in_band() -> bool:
	return absf(EvoManager.remision_omega - remision_band_center()) <= Balance.REMISION_BAND_HALF

## Empuje manual de Ω (dir = +1 sube, −1 baja). Clampeado al rango de la ruta.
static func remision_nudge(dir: int) -> void:
	if not EvoManager.mutation_remision or RunManager.run_closed:
		return
	EvoManager.remision_omega = clampf(EvoManager.remision_omega + dir * Balance.REMISION_NUDGE, Balance.REMISION_OMEGA_MIN, Balance.REMISION_OMEGA_MAX)

## Progreso [0,1] del contador Θ hacia el sello.
static func remision_progress() -> float:
	return clampf(EvoManager.remision_theta / Balance.REMISION_THETA_TARGET, 0.0, 1.0)

## El sello queda armado al alcanzar el target de Θ; no se revierte salvo involución.
static func remision_can_seal() -> bool:
	return EvoManager.mutation_remision and not RunManager.run_closed and EvoManager.remision_sealable

## Tick de la ruta. Ω deriva al colapso; dentro de banda la biomasa florece y Θ sube.
static func process_remision(dt: float) -> void:
	if not EvoManager.mutation_remision or RunManager.run_closed:
		return
	EvoManager.remision_band_timer += dt
	EvoManager.remision_omega = clampf(EvoManager.remision_omega - Balance.REMISION_OMEGA_DRIFT * dt, Balance.REMISION_OMEGA_MIN, Balance.REMISION_OMEGA_MAX)
	if remision_in_band():
		BiosphereEngine.biomasa += BiosphereEngine.biomasa * Balance.REMISION_BLOOM_RATE * dt
		EvoManager.remision_theta += dt
		if EvoManager.remision_theta >= Balance.REMISION_THETA_TARGET and not EvoManager.remision_sealable:
			EvoManager.remision_sealable = true
			UIManager.show_toast(TranslationServer.translate("TOAST_REMISION_SELLO"))
			LogManager.add(TranslationServer.translate("LOG_REMISION_SELLO"))
	else:
		BiosphereEngine.biomasa = maxf(BiosphereEngine.biomasa - BiosphereEngine.biomasa * Balance.REMISION_WITHER_RATE * dt, 0.0)
		if not EvoManager.remision_sealable:
			EvoManager.remision_theta = maxf(EvoManager.remision_theta - Balance.REMISION_THETA_DECAY * dt, 0.0)
	if BiosphereEngine.biomasa < Balance.REMISION_BIO_FLOOR and not RunManager.run_closed:
		_remision_involucionar()

## Sello intencional: el organismo declara la remisión completa.
static func remision_seal() -> void:
	if not remision_can_seal():
		return
	EvoManager.mutation_remision = false
	RunManager.close_run("REMISIÓN METABÓLICA", TranslationServer.translate("CLOSE_REMISION_SELLO") % BiosphereEngine.biomasa)

## Involución: la enfermedad regresa. Degrada a Met. Oscuro y bloquea REMISIÓN esta run.
static func _remision_involucionar() -> void:
	EvoManager.mutation_remision = false
	EvoManager.remision_locked_run = true
	EvoManager.remision_sealable = false
	EvoManager.remision_theta = 0.0
	UIManager.show_toast(TranslationServer.translate("TOAST_REMISION_INVOLUCION"))
	LogManager.add(TranslationServer.translate("LOG_REMISION_INVOLUCION"))
	EvoManager._save_after_mutation()

# ── CONTROL DE Ω (buff NG+ de REMISIÓN) ──────────────────────────────────────

## ¿Disponible el empuje manual de Ω? Solo con el buff y fuera de las sub-rutas oscuras.
static func control_omega_available() -> bool:
	if RunManager.run_closed or EvoManager.mutation_met_oscuro:
		return false
	return LegacyManager.get_buff_value("control_omega")

## Empuje manual de Ω en runs normales (dir = +1/−1). Acotado en magnitud y con cooldown.
static func control_omega_nudge(dir: int) -> void:
	if not control_omega_available():
		return
	var now: int = Time.get_ticks_msec()
	if now - EvoManager.control_omega_last_ms < int(Balance.CONTROL_OMEGA_COOLDOWN * 1000.0):
		return
	EvoManager.control_omega_last_ms = now
	StructuralModel.control_omega_offset = clampf(
		StructuralModel.control_omega_offset + dir * Balance.CONTROL_OMEGA_NUDGE,
		-Balance.CONTROL_OMEGA_MAX, Balance.CONTROL_OMEGA_MAX)

# ── DEPREDADOR ────────────────────────────────────────────────────────────────

static func process_depredador(dt: float) -> void:
	EvoManager.depredador_inestabilidad += dt
	if EvoManager.depredador_inestabilidad >= EvoManager.DEPREDADOR_INESTABILIDAD_MAX and not RunManager.run_closed:
		RunManager.close_run("COLAPSO DEPREDATORIO", TranslationServer.translate("CLOSE_COLAPSO_DEP"))
		return
	EvoManager._depredador_active_tick += dt
	var devour_tick: float = Balance.DEP_DEVOUR_TICK_FAST if EvoManager.met_oscuro_devoured_count >= Balance.DEP_DEVOUR_TICK_FAST_AT else Balance.DEP_DEVOUR_TICK_BASE
	if EvoManager._depredador_active_tick >= devour_tick:
		EvoManager._depredador_active_tick = 0.0
		var devoured: bool = UpgradeManager.devour_random_upgrade()
		if devoured:
			var dep_bio: float = 15.0
			if LegacyManager.get_buff_value("ciclo_catabolico"):
				dep_bio *= Balance.CICLO_CATABOLICO_BIO_MULT
			BiosphereEngine.biomasa += dep_bio
			EvoManager.met_oscuro_devoured_count += 1
			AchievementManager.push_event("depredador_devour", {})
			UIManager.show_toast(TranslationServer.translate("TOAST_MO_DIGEST") % EvoManager.met_oscuro_devoured_count)
			if EvoManager.met_oscuro_devoured_count in Balance.DEP_DEVOUR_MILESTONES:
				EvoManager.depredador_inestabilidad = max(0.0, EvoManager.depredador_inestabilidad - Balance.DEP_DEVOUR_MILESTONE_BONUS)
				UIManager.show_toast(TranslationServer.translate("TOAST_DEP_DEVOUR_MILESTONE") % [EvoManager.met_oscuro_devoured_count, Balance.DEP_DEVOUR_MILESTONE_BONUS])
			if is_instance_valid(UIManager.big_click_button):
				UIManager.big_click_button.modulate = Color(randf(), randf(), randf())
		else:
			RunManager.close_run("DEPREDADOR DE REALIDADES", TranslationServer.translate("CLOSE_DEP_REALIDADES"))

## Costo en biomasa de la próxima compra de tiempo del timer de inestabilidad.
static func depredador_time_cost() -> float:
	return Balance.DEP_TIME_COST_BASE * pow(Balance.DEP_TIME_COST_GROWTH, float(EvoManager.depredador_timer_buys))

## Compra DEP_TIME_EXTENSION segundos de timer pagando biomasa. Retorna true si tuvo éxito.
static func buy_depredador_time() -> bool:
	if not EvoManager.mutation_depredador or RunManager.run_closed:
		return false
	var cost: float = depredador_time_cost()
	if BiosphereEngine.biomasa < cost:
		return false
	BiosphereEngine.biomasa -= cost
	EvoManager.depredador_timer_buys += 1
	EvoManager.depredador_inestabilidad = max(0.0, EvoManager.depredador_inestabilidad - Balance.DEP_TIME_EXTENSION)
	UIManager.show_toast(TranslationServer.translate("TOAST_DEP_TIME_BOUGHT") % Balance.DEP_TIME_EXTENSION)
	return true

static func process_depredador_progress(dt: float) -> void:
	EvoManager._depredador_status_timer += dt
	if EvoManager._depredador_status_timer >= EvoManager.DEPREDADOR_STATUS_INTERVAL:
		EvoManager._depredador_status_timer = 0.0
		var dep_threshold := 30.0 * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
		var pct := int((EvoManager.depredador_timer / dep_threshold) * 100.0)
		var bar_len := int(pct / 5.0)
		var bar := ""
		for i in range(20):
			bar += "|" if i < bar_len else "."
		LogManager.add(TranslationServer.translate("LOG_DEP_TICK") % [StructuralModel.epsilon_runtime, bar, pct, EvoManager.depredador_timer])
		UIManager.show_toast(TranslationServer.translate("TOAST_DEP_PROGRESS") % [pct, EvoManager.depredador_timer])

## Retorna 1 si glitch se activó, -1 si se desactivó, 0 si sin cambio.
static func process_glitch(_dt: float) -> int:
	if not LegacyManager.get_buff_value("metabolismo_glitch"):
		return 0
	var glitch_now := StructuralModel.epsilon_runtime > 0.40
	var result := 0
	if glitch_now and not EvoManager._glitch_was_active:
		LogManager.add(TranslationServer.translate("LOG_GLITCH_ACTIVO"))
		UIManager.show_toast(TranslationServer.translate("TOAST_MG_ACTIVO"))
		result = 1
	elif not glitch_now and EvoManager._glitch_was_active:
		UIManager.show_toast(TranslationServer.translate("TOAST_MG_INACTIVO"))
		result = -1
	EvoManager._glitch_was_active = glitch_now
	return result
