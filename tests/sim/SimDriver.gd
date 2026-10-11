extends RefCounted
## SimDriver — motor del simulador headless.
##
## Instancia main.tscn REAL y avanza tiempo simulado ejecutando el mismo código que el motor
## de Godot ejecuta en el juego, en el mismo orden dentro de cada frame:
##
##   1. input        → acciones del bot (click, compras, botones, teclas Q/W)
##   2. autoloads    → TutorialManager._process(dt)      (anti-stuck: regala $ por idle)
##   3. escena       → main._process(dt)                 (run_time, time_since_last_click)
##   4. subárbol     → fungi_ui._process(dt)             (desbloqueo de hifas)
##   5. Timers de main en orden de creación: _logic_timer → _ui_timer → _autosave_timer
##
## Lo único que se reemplaza es el reloj de pared: el tiempo avanza en frames enteros de
## FRAME_DT segundos, y las cadencias de los Timers se derivan de las constantes reales del
## juego (si dejan de ser múltiplos de FRAME_DT, boot() falla en vez de simular mal).
##
## Los visuales (ReactorVisual / Reactor3D / RemisionWaveControl) quedan apagados: no modifican
## estado de juego, pero consumen el RNG global y harían la simulación dependiente del framerate.

const MAIN_SCENE := "res://main.tscn"
const FRAME_DT := 0.05

var main: Node = null
var frame: int = 0
var platform: String = "desktop"
var run_ui: bool = true
var run_autosave: bool = false

var logic_every: int = 0
var ui_every: int = 0
var autosave_every: int = 0

var clicks: int = 0
var purchases: Array = []
var events: Array = []

var perf_logic := PackedInt64Array()
var perf_ui := PackedInt64Array()
var perf_click := PackedInt64Array()

## Diagnóstico opcional: si EconomyManager expone un dict `_diag` de contadores de llamadas
## (instrumentación temporal), se acumulan las llamadas hechas dentro de cada fase.
var diag_calls := {"logic": {}, "ui": {}, "click": {}}
var diag_counts := {"logic": 0, "ui": 0, "click": 0}

var _fungi: Node = null


## Arranca la escena de juego. Hay que hacer `await driver.boot(...)`.
## opts: seed (int), platform ("desktop"|"web"), ui (bool), autosave (bool)
func boot(host: Node, opts: Dictionary) -> bool:
	platform = str(opts.get("platform", "desktop"))
	run_ui = bool(opts.get("ui", true))
	run_autosave = bool(opts.get("autosave", false))
	seed(int(opts.get("seed", 1337)))

	# Visual: el reactor 3D requiere SubViewport; en headless no aporta nada.
	AccessibilityManager.reactor_3d_enabled = false

	# Si boot() se llama desde el _ready() del host, el root todavía está armando hijos y
	# add_child() falla en silencio (main nunca entraría al árbol). Esperar un frame lo evita.
	await host.get_tree().process_frame

	var packed: PackedScene = load(MAIN_SCENE)
	main = packed.instantiate()
	# DISABLED antes de entrar al árbol: los Timers que main crea en _ready() heredan el modo
	# y nunca disparan solos; tampoco corre ningún _process del subárbol. Todo lo avanza step().
	main.process_mode = Node.PROCESS_MODE_DISABLED
	host.get_tree().root.add_child(main)
	if not main.is_inside_tree():
		printerr("[SimDriver] main.tscn no pudo entrar al árbol de escena.")
		return false
	TutorialManager.set_process(false)

	# Dejar resolver los await/call_deferred de inicialización (montaje de fungi_ui, etc.).
	for i in 3:
		await host.get_tree().process_frame

	if not _derive_cadence():
		return false
	_fungi = main.fungi_ui if is_instance_valid(main.fungi_ui) else null
	if bool(opts.get("visual", false)):
		_enable_visual_mode()
	_connect_events()
	return true


## Modo visual: el reloj de juego lo sigue avanzando step(), pero el resto del árbol de main
## (animaciones, tweens, toasts, reactor) vuelve a procesar para poder mirar la run.
## No es determinista (los visuales consumen RNG global): sólo para observar, nunca para goldens.
func _enable_visual_mode() -> void:
	for timer_name in ["_logic_timer", "_ui_timer", "_autosave_timer"]:
		var t: Variant = main.get(timer_name)
		if t is Timer:
			(t as Timer).stop()
	main.process_mode = Node.PROCESS_MODE_INHERIT
	main.set_process(false)        # su _process suma delta REAL a run_time: lo maneja step()
	main.set_process_input(false)  # las teclas las maneja el simulador (velocidad/pausa)
	if is_instance_valid(_fungi):
		_fungi.set_process(false)  # step() llama a su _process con el delta simulado


func _derive_cadence() -> bool:
	var consts: Dictionary = (main.get_script() as Script).get_script_constant_map()
	var ui_interval: float = float(consts.get("UI_TICK_WEB", 0.25)) if platform == "web" else float(consts.get("UI_TICK", 0.1))
	logic_every = _frames_for(RunManager.LOGIC_TICK, "LOGIC_TICK")
	ui_every = _frames_for(ui_interval, "UI_TICK")
	autosave_every = _frames_for(float(consts.get("AUTOSAVE_INTERVAL", 30.0)), "AUTOSAVE_INTERVAL")
	return logic_every > 0 and ui_every > 0 and autosave_every > 0


func _frames_for(interval: float, label: String) -> int:
	var n := interval / FRAME_DT
	if absf(n - roundf(n)) > 1e-6:
		printerr("[SimDriver] %s=%.4f no es múltiplo de FRAME_DT=%.4f: la simulación no sería fiel." % [label, interval, FRAME_DT])
		return 0
	return int(roundf(n))


func _connect_events() -> void:
	EvoManager.mutation_activated.connect(func(id: String, _name: String) -> void:
		events.append({"t": now(), "type": "mutation", "id": id}))
	UpgradeManager.upgrade_bought.connect(func(id: String) -> void:
		purchases.append({"t": now(), "id": id, "level": UpgradeManager.level(id)}))
	AchievementManager.achievement_unlocked.connect(func(id: String, _def: Dictionary) -> void:
		events.append({"t": now(), "type": "achievement", "id": id}))


func now() -> float:
	return snappedf(RunManager.run_time, 0.001)


func dt() -> float:
	return FRAME_DT


## Un frame simulado completo (FRAME_DT segundos de juego).
func step(bot: RefCounted = null) -> void:
	frame += 1
	if bot != null:
		bot.act(self)
	TutorialManager._process(FRAME_DT)
	main._process(FRAME_DT)
	if is_instance_valid(_fungi):
		_fungi._process(FRAME_DT)
	if frame % logic_every == 0:
		var d0 := _diag_snapshot()
		var t0 := Time.get_ticks_usec()
		main._on_logic_tick()
		perf_logic.append(Time.get_ticks_usec() - t0)
		_diag_accumulate("logic", d0)
	if run_ui and frame % ui_every == 0:
		var d1 := _diag_snapshot()
		var t1 := Time.get_ticks_usec()
		main._on_ui_tick()
		perf_ui.append(Time.get_ticks_usec() - t1)
		_diag_accumulate("ui", d1)
	if run_autosave and frame % autosave_every == 0:
		main._on_autosave_tick()


# ── Acciones del jugador (mismo camino de código que la UI) ─────────────────────

## Click en el reactor: BigClickButton._pressed() → main.on_reactor_click() con su ε por defecto.
func click() -> void:
	var d0 := _diag_snapshot()
	var t0 := Time.get_ticks_usec()
	main.on_reactor_click()
	perf_click.append(Time.get_ticks_usec() - t0)
	_diag_accumulate("click", d0)
	clicks += 1


func _diag_snapshot() -> Dictionary:
	var counters: Variant = EconomyManager.get("_diag")
	return (counters as Dictionary).duplicate() if counters is Dictionary else {}


func _diag_accumulate(phase: String, before: Dictionary) -> void:
	if before.is_empty():
		return
	diag_counts[phase] += 1
	var now_counts: Dictionary = EconomyManager.get("_diag")
	for k in now_counts:
		diag_calls[phase][k] = int(diag_calls[phase].get(k, 0)) + int(now_counts[k]) - int(before.get(k, 0))


## Llamadas promedio por fase: { "logic": {"get_click_power": 4.0, ...}, ... }
func diag_report() -> Dictionary:
	var out := {}
	for phase in diag_calls:
		var n: int = maxi(1, int(diag_counts[phase]))
		var per := {}
		for k in diag_calls[phase]:
			per[k] = snappedf(float(diag_calls[phase][k]) / n, 0.01)
		out[phase] = per
	return out


## Compra de upgrade: mismo camino que las teclas 1-9 y los botones de upgrade.
func buy(id: String) -> bool:
	var before := UpgradeManager.level(id)
	UpgradeManager.purchase_upgrade(id)
	return UpgradeManager.level(id) > before


# ── Observación ─────────────────────────────────────────────────────────────────

## Muestra del estado observable. Sólo lee: no modifica estado ni consume RNG.
func sample() -> Dictionary:
	var br: Dictionary = EconomyManager.get_contribution_breakdown()
	var ap: Dictionary = EconomyManager.get_active_passive_breakdown()
	return {
		"t": now(),
		"money": EconomyManager.money,
		"total_money": EconomyManager.total_money_generated,
		"delta_total": br.get("total", 0.0),
		"click_power": EconomyManager.get_click_power(),
		"passive": EconomyManager.get_passive_total(),
		"activo_pct": ap.get("activo", 0.0),
		"eps": StructuralModel.epsilon_runtime,
		"eps_eff": StructuralModel.epsilon_effective,
		"omega": StructuralModel.omega,
		"mu": EconomyManager.cached_mu,
		"biomasa": BiosphereEngine.biomasa,
		"hifas": BiosphereEngine.hifas,
		"nutrientes": BiosphereEngine.nutrientes,
		"micelio": BiosphereEngine.micelio,
		"upgrade_levels": UpgradeManager.total_levels(),
		"genome": EvoManager.genome.duplicate(),
		"ach_unlocked": AchievementManager.unlocked_count(),
		"ach_clock": AchievementManager._run_time,
		"run_closed": RunManager.run_closed,
		"final_route": RunManager.final_route,
	}


## Microbenchmark del pipeline económico en el estado actual (funciones puras de lectura).
func bench_economy(iterations: int = 300) -> Dictionary:
	var out := {}
	var calls := {
		"get_click_power": func() -> void: EconomyManager.get_click_power(),
		"get_passive_total": func() -> void: EconomyManager.get_passive_total(),
		"get_contribution_breakdown": func() -> void: EconomyManager.get_contribution_breakdown(),
		"get_active_passive_breakdown": func() -> void: EconomyManager.get_active_passive_breakdown(),
		"get_effect_value(all_income_mult)": func() -> void: LegacyManager.get_effect_value("all_income_mult"),
	}
	for label in calls:
		var fn: Callable = calls[label]
		var t0 := Time.get_ticks_usec()
		for i in iterations:
			fn.call()
		out[label + "_us"] = snappedf(float(Time.get_ticks_usec() - t0) / iterations, 0.01)
	return out


## Costo de update_ui() aislado. MUTA estado (avanza el reloj de logros, ver auditoría C2):
## llamar sólo cuando la simulación ya terminó.
func bench_update_ui(iterations: int = 30) -> float:
	var t0 := Time.get_ticks_usec()
	for i in iterations:
		main.update_ui()
	return snappedf(float(Time.get_ticks_usec() - t0) / iterations, 0.1)
