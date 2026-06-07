class_name RouteVacio extends PostTrasRoute

## VACÍO HAMBRIENTO — ruta post-trascendencia.
## Consume todos los buffs cósmicos activos y multiplica la producción ×VACIO_HAMBRIENTO_MULT.
## Sub-ruta ASCESIS PROFUNDA: si el jugador sostiene condiciones de renuncia
## (sin biósfera, sin pasivo, ε < 0.25, clickeo activo) durante ASCESIS_DURATION segundos,
## cierra la run con ese ending especial.

var mult: float = 1.0
var ascesis_timer: float = 0.0

func activate() -> void:
	AchievementManager.push_event("post_tras_route", {"route": "vacio"})
	# Consumir todos los buffs cósmicos activos
	var consumed: int = 0
	for id in LegacyManager.cosmic_unlocked.keys():
		if LegacyManager.cosmic_unlocked[id]:
			LegacyManager.cosmic_unlocked[id] = false
			consumed += 1
	mult = Balance.VACIO_HAMBRIENTO_MULT
	LegacyManager.save_legacy()
	print("🕳️ [VACÍO HAMBRIENTO] %d buffs cósmicos consumidos → ×%.0f producción" % [consumed, mult])
	LogManager.add(tr("LOG_VACIO") % consumed)

func tick(delta: float) -> void:
	if RunManager.run_closed:
		return
	# Requisitos previos: run madura y dinero mínimo generado solo por clicks
	if RunManager.run_time < Balance.ASCESIS_MIN_RUN_TIME or EconomyManager.money < Balance.ASCESIS_MONEY_REQ:
		ascesis_timer = 0.0
		return
	# Condiciones simultáneas: sin biósfera, sin pasivo comprado, sistema calmo
	var biomasa_ok: bool = BiosphereEngine.biomasa < 0.5
	var sin_pasivo: bool = UpgradeManager.level("auto") == 0 and UpgradeManager.level("trueque") == 0
	var epsilon_ok: bool = StructuralModel.epsilon_runtime < 0.25
	# Anti-AFK: la ascesis es renuncia ACTIVA — hay que sostener el clickeo, no esperar quieto
	var click_activo: bool = EconomyManager.time_since_last_click < Balance.ASCESIS_CLICK_TIMEOUT
	if biomasa_ok and sin_pasivo and epsilon_ok and click_activo:
		ascesis_timer += delta
		if ascesis_timer >= Balance.ASCESIS_DURATION:
			RunManager.close_run("ASCESIS_PROFUNDA", tr("CLOSE_ASCESIS"))
	# Si fallan las condiciones el timer se pausa (no se resetea)

func production_mult() -> float:
	return mult

func serialize() -> Dictionary:
	return {
		"mult": mult,
		"ascesis_timer": ascesis_timer,
	}

func deserialize(d: Dictionary) -> void:
	mult = d.get("mult", Balance.VACIO_HAMBRIENTO_MULT)
	ascesis_timer = d.get("ascesis_timer", 0.0)

func get_extra_state() -> Dictionary:
	return {
		"mult": mult,
		"ascesis_timer": ascesis_timer,
	}

func get_badge() -> Dictionary:
	return {
		"text": "🕳️  " + tr("ROUTE_VACIO_HAMBRIENTO") + "  ×%.0f" % mult,
		"color": Color(0.75, 0.2, 1.0),
	}
