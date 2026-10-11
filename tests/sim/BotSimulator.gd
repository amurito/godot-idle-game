extends Node
## BotSimulator — escena de entrada del simulador de bots headless.
##
## Uso (siempre vía sandbox):
##   .\tools\sim\run_sandboxed.ps1 -Scene res://tests/sim/BotSimulator.tscn `
##       -SceneArgs "--scenario=fresh_active","--out=C:\ruta\reporte.json"
##
## Argumentos:
##   --scenario=<id>       escenario de Scenarios.gd (default fresh_hiper)
##   --seed=<int>          semilla del RNG global (default 1337)
##   --platform=desktop|web  cadencia del UI tick (10 Hz / 4 Hz)
##   --ui=true|false       ejecutar el UI tick (false = sólo lógica, más rápido)
##   --max_t=<s>           override del máximo de segundos simulados
##   --out=<ruta.json>     reporte completo (muestras, eventos, rendimiento)
##   --list                lista los escenarios y sale

const SimGuard := preload("res://tests/sim/SimGuard.gd")
const SimDriver := preload("res://tests/sim/SimDriver.gd")
const BotPolicy := preload("res://tests/sim/BotPolicy.gd")
const Scenarios := preload("res://tests/sim/Scenarios.gd")

const FRAMES_PER_REAL_FRAME := 400   # 20 s simulados por frame real: deja correr call_deferred


func _ready() -> void:
	if not SimGuard.assert_sandbox():
		get_tree().quit(2)
		return
	var args := SimGuard.parse_args()

	if args.has("list"):
		for id in Scenarios.ALL:
			print("%-22s %s" % [id, Scenarios.ALL[id].desc])
		get_tree().quit(0)
		return

	var scenario_id := str(args.get("scenario", "fresh_hiper"))
	if not Scenarios.ALL.has(scenario_id):
		printerr("[BotSimulator] escenario desconocido: %s (usá --list)" % scenario_id)
		get_tree().quit(1)
		return
	var sc: Dictionary = Scenarios.ALL[scenario_id]
	var opts := {
		"seed": int(args.get("seed", "1337")),
		"platform": str(args.get("platform", "desktop")),
		"ui": SimGuard.arg_bool(args, "ui", true),
	}
	var max_t: float = float(args.get("max_t", str(sc.get("max_t", 1800.0))))
	var sample_every: float = float(sc.get("sample_every", 10.0))

	var report := await run_scenario(scenario_id, sc, opts, max_t, sample_every)
	_print_summary(report)
	if args.has("out"):
		if SimGuard.write_text(str(args["out"]), SimGuard.to_canonical_json(report)):
			print("[BotSimulator] reporte → %s" % args["out"])
	get_tree().quit(0)


func run_scenario(scenario_id: String, sc: Dictionary, opts: Dictionary, max_t: float, sample_every: float) -> Dictionary:
	Scenarios.apply_legacy(sc.get("legacy", {}))
	var pl_before := LegacyManager.legacy_points

	var d = SimDriver.new()
	var ok: bool = await d.boot(self, opts)
	if not ok:
		return {"scenario": scenario_id, "error": "boot falló"}
	var bot = BotPolicy.new(sc.get("bot", {}))

	var samples: Array = [d.sample()]
	var sample_frames := maxi(1, int(roundf(sample_every / d.dt())))
	var max_frames := int(ceil(max_t / d.dt()))
	var wall_start := Time.get_ticks_msec()

	while d.frame < max_frames and not RunManager.run_closed:
		for i in FRAMES_PER_REAL_FRAME:
			d.step(bot)
			if d.frame % sample_frames == 0:
				samples.append(d.sample())
			if RunManager.run_closed or d.frame >= max_frames:
				break
		await get_tree().process_frame
	samples.append(d.sample())
	var wall_s := (Time.get_ticks_msec() - wall_start) / 1000.0

	var report := {
		"scenario": scenario_id,
		"desc": sc.get("desc", ""),
		"config": {"bot": sc.get("bot", {}), "legacy": sc.get("legacy", {}), "opts": opts,
			"max_t": max_t, "frame_dt": d.dt(),
			"cadence_frames": {"logic": d.logic_every, "ui": d.ui_every}},
		"outcome": {
			"run_closed": RunManager.run_closed,
			"final_route": RunManager.final_route,
			"final_reason": RunManager.final_reason,
			"t_end": d.now(),
			"clicks": d.clicks,
			"purchases": d.purchases.size(),
			"upgrade_levels": UpgradeManager.total_levels(),
			"pl_gained": LegacyManager.legacy_points - pl_before,
			"total_money": EconomyManager.total_money_generated,
		},
		"achievement_clock": {
			"ach_run_time": AchievementManager._run_time,
			"real_run_time": RunManager.run_time,
			"ratio": AchievementManager._run_time / maxf(RunManager.run_time, 0.001),
		},
		"transmutation": _transmutation_metrics(),
		"events": d.events,
		"bot_actions": bot.actions,
		"purchases": d.purchases,
		"samples": samples,
		"perf": {
			"logic_tick": SimGuard.perf_stats(d.perf_logic),
			"ui_tick": SimGuard.perf_stats(d.perf_ui),
			"click": SimGuard.perf_stats(d.perf_click),
			"economy_us_per_call": d.bench_economy(),
			"wall_seconds": wall_s,
			"sim_speed_x": d.now() / maxf(wall_s, 0.001),
		},
	}
	# update_ui() avanza el reloj de logros (auditoría C2): se mide recién al final.
	report.perf["update_ui_us"] = d.bench_update_ui()
	return report


func _transmutation_metrics() -> Dictionary:
	return {
		"ayuno": {
			"active": EvoManager.mutation_ayuno_primordial,
			"cycles": EvoManager.ayuno_cycles,
			"silencio_total": EvoManager.ayuno_silencio_total,
			"silencio_peak": EvoManager.ayuno_silencio_peak,
			"longest_streak": EvoManager.ayuno_longest_streak,
			"ascesis_level": EvoManager.ayuno_ascesis_level,
		},
		"fusion": {
			"active": EvoManager.mutation_fusion_catabolica,
			"burst_count": EvoManager.fusion_burst_count,
			"cd_level": EvoManager.fusion_cd_level,
		},
	}


func _print_summary(r: Dictionary) -> void:
	if r.has("error"):
		printerr("[BotSimulator] %s: %s" % [r.get("scenario", "?"), r.error])
		return
	var o: Dictionary = r.outcome
	var p: Dictionary = r.perf
	var opts: Dictionary = r.config.opts
	print("")
	print("═══ SIM %s (%s, seed %d) ═══" % [r.scenario, opts.platform, opts.seed])
	print(r.desc)
	if o.run_closed:
		print("Resultado: %s a t=%.1f s" % [o.final_route, o.t_end])
	else:
		print("Resultado: run abierta al límite (t=%.1f s)" % o.t_end)
	print("clicks %d | compras %d | niveles %d | PL +%d | $ total %s" % [o.clicks, o.purchases, o.upgrade_levels, o.pl_gained, String.num_scientific(o.total_money)])
	var muts: Array = []
	var achs: Array = []
	for e in r.events:
		if e.type == "mutation":
			muts.append("%s@%.0fs" % [e.id, e.t])
		elif e.type == "achievement":
			achs.append(e.id)
	print("Mutaciones: %s" % (", ".join(muts) if not muts.is_empty() else "—"))
	print("Logros (%d): %s" % [achs.size(), ", ".join(achs) if not achs.is_empty() else "—"])
	var acts: Array = []
	for a in r.bot_actions:
		acts.append("%s@%.0fs" % [a.action, a.t])
	if not acts.is_empty():
		print("Acciones del bot: %s" % ", ".join(acts.slice(0, 12)) + (" …(+%d)" % (acts.size() - 12) if acts.size() > 12 else ""))
	var tr_m: Dictionary = r.transmutation
	if tr_m.ayuno.active or tr_m.ayuno.cycles > 0:
		print("Ayuno: ciclos %d | S total %.0f | S pico %.0f | racha máx %.0fs | ascesis %d" % [tr_m.ayuno.cycles, tr_m.ayuno.silencio_total, tr_m.ayuno.silencio_peak, tr_m.ayuno.longest_streak, tr_m.ayuno.ascesis_level])
	if tr_m.fusion.active or tr_m.fusion.burst_count > 0:
		print("Fusión: ráfagas %d | CD nivel %d" % [tr_m.fusion.burst_count, tr_m.fusion.cd_level])
	print("Reloj de logros: %.2f× (AchievementManager._run_time / run_time)" % r.achievement_clock.ratio)
	print("logic tick : %s" % _fmt_perf(p.logic_tick))
	print("ui tick    : %s" % _fmt_perf(p.ui_tick))
	print("click      : %s" % _fmt_perf(p.click))
	var eco: Dictionary = p.economy_us_per_call
	var eco_parts: Array = []
	for k in eco:
		eco_parts.append("%s %.1f" % [str(k).trim_suffix("_us"), eco[k]])
	print("economía µs/llamada: %s" % " | ".join(eco_parts))
	print("update_ui(): %.1f µs" % p.update_ui_us)
	print("velocidad: %.0f s simulados en %.1f s reales (%.0f×)" % [o.t_end, p.wall_seconds, p.sim_speed_x])


func _fmt_perf(s: Dictionary) -> String:
	if int(s.get("n", 0)) == 0:
		return "—"
	return "n=%d mean %.0f µs | p50 %d | p95 %d | max %d µs | total %.0f ms" % [s.n, s.mean_us, s.p50_us, s.p95_us, s.max_us, s.total_ms]
