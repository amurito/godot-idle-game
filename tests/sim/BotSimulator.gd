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
##   --visual              ventana con el juego real + panel de seguimiento (sin --headless)
##   --speed=<x>           modo visual: segundos de juego por segundo real (default 5)
##   --autoquit            modo visual: cerrar la ventana al terminar (sin esperar Esc)
##   --screenshot=<ruta.png>  modo visual: guarda una captura de la ventana al terminar
##   --list                lista los escenarios y sale
##
## Modo visual — teclas: + / - velocidad · Espacio pausa · Esc salir.
## No es determinista (los visuales consumen RNG global): sirve para mirar, no para goldens.

const SimGuard := preload("res://tests/sim/SimGuard.gd")
const SimDriver := preload("res://tests/sim/SimDriver.gd")
const BotPolicy := preload("res://tests/sim/BotPolicy.gd")
const Scenarios := preload("res://tests/sim/Scenarios.gd")

const FRAMES_PER_REAL_FRAME := 400   # 20 s simulados por frame real: deja correr call_deferred
const MAX_FRAMES_PER_REAL_FRAME_VISUAL := 2000

# Estado del modo visual
var visual := false
var speed := 5.0
var paused := false
var _quit_requested := false
var _hud: RichTextLabel = null
var _scenario_id := ""
var _scenario_desc := ""
var _last_d: RefCounted = null
var _last_bot: RefCounted = null


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
	_scenario_id = scenario_id
	_scenario_desc = str(sc.get("desc", ""))
	var opts := {
		"seed": int(args.get("seed", "1337")),
		"platform": str(args.get("platform", "desktop")),
		"ui": SimGuard.arg_bool(args, "ui", true),
		"visual": SimGuard.arg_bool(args, "visual", false),
	}
	visual = opts.visual
	speed = maxf(0.1, float(args.get("speed", "5")))
	if visual:
		_build_hud()
	var max_t: float = float(args.get("max_t", str(sc.get("max_t", 1800.0))))
	var sample_every: float = float(sc.get("sample_every", 10.0))

	var report := await run_scenario(scenario_id, sc, opts, max_t, sample_every)
	_print_summary(report)
	if args.has("out"):
		if SimGuard.write_text(str(args["out"]), SimGuard.to_canonical_json(report)):
			print("[BotSimulator] reporte → %s" % args["out"])
	if visual and args.has("screenshot"):
		_render_hud(null, null, report)
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(str(args["screenshot"]))
		print("[BotSimulator] captura → %s" % args["screenshot"])
	if visual and not SimGuard.arg_bool(args, "autoquit", false):
		paused = true
		_render_hud(null, null, report)
		while not _quit_requested:
			await get_tree().process_frame
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

	var budget := 0.0
	while d.frame < max_frames and not RunManager.run_closed and not _quit_requested:
		var n := FRAMES_PER_REAL_FRAME
		if visual:
			# Ritmo controlado: `speed` segundos de juego por segundo real.
			budget += 0.0 if paused else get_process_delta_time() * speed / d.dt()
			n = mini(int(budget), MAX_FRAMES_PER_REAL_FRAME_VISUAL)
			budget -= n
		for i in n:
			d.step(bot)
			if d.frame % sample_frames == 0:
				samples.append(d.sample())
			if RunManager.run_closed or d.frame >= max_frames:
				break
		if visual:
			_render_hud(d, bot, {})
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
			"memory": {
				"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
				"static_max_mb": Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0,
				"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
				"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
				"orphan_nodes": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			},
		},
	}
	# update_ui() avanza el reloj de logros (auditoría C2): se mide recién al final.
	report.perf["update_ui_us"] = d.bench_update_ui()
	var parts: Dictionary = d.bench_ui_breakdown()
	report.perf["ui_breakdown_us"] = parts
	var ordered := parts.keys()
	ordered.sort_custom(func(a, b) -> bool: return parts[a] > parts[b])
	var lines: Array = []
	for k in ordered:
		lines.append("%s %.0f" % [k, parts[k]])
	print("desglose UI (µs): " + " | ".join(lines))
	if EconomyManager.get("_diag") is Dictionary:
		report.perf["economy_calls_per_phase"] = d.diag_report()
		print("llamadas al pipeline económico por fase: %s" % JSON.stringify(report.perf.economy_calls_per_phase))
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


# ═════════════════════════════════════════════════════════════════════════════
#  Modo visual — panel de seguimiento y controles
# ═════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visual:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				speed = minf(speed * 2.0, 512.0)
			KEY_MINUS, KEY_KP_SUBTRACT:
				speed = maxf(speed / 2.0, 0.25)
			KEY_SPACE:
				paused = not paused
			KEY_ESCAPE:
				_quit_requested = true
			_:
				return
		get_viewport().set_input_as_handled()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128  # máxima: por encima de popups del tutorial y toasts del juego
	add_child(layer)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.06, 0.9)
	sb.border_color = Color(0.35, 0.85, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -452.0
	panel.offset_right = -12.0
	panel.offset_top = 12.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud = RichTextLabel.new()
	_hud.bbcode_enabled = true
	_hud.fit_content = true
	_hud.scroll_active = false
	_hud.custom_minimum_size = Vector2(420, 0)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_theme_font_size_override("normal_font_size", 14)
	_hud.add_theme_font_size_override("bold_font_size", 15)
	panel.add_child(_hud)
	layer.add_child(panel)


func _render_hud(d: RefCounted, bot: RefCounted, report: Dictionary) -> void:
	if _hud == null:
		return
	if d != null:
		_last_d = d
		_last_bot = bot
	var t := "[b][color=#7dffb0]SIMULADOR · %s[/color][/b]
" % _scenario_id
	t += "[color=#9aa]%s[/color]

" % _scenario_desc
	var state := "[color=#ffcc55]PAUSA[/color]" if paused else "×%s" % _fmt_speed(speed)
	t += "[b]t = %s[/b]   %s
" % [_fmt_time(RunManager.run_time), state]
	t += "$ %s   Δ$/s %s
" % [_fmt_num(EconomyManager.money), _fmt_num(EconomyManager.get_delta_total())]
	t += "ε %.2f   Ω %.2f   bio %.1f   hifas %.1f
" % [StructuralModel.epsilon_runtime, StructuralModel.omega, BiosphereEngine.biomasa, BiosphereEngine.hifas]
	if _last_d != null:
		t += "clicks %d   compras %d   reloj logros %.2f×
" % [_last_d.clicks, _last_d.purchases.size(), AchievementManager._run_time / maxf(RunManager.run_time, 0.001)]
		t += "
[b]Eventos[/b]
"
		var evs: Array = _last_d.events.slice(maxi(0, _last_d.events.size() - 6))
		if evs.is_empty():
			t += "[color=#777]—[/color]
"
		for e in evs:
			var col := "#ff88cc" if e.type == "mutation" else "#ffd866"
			t += "[color=%s]%s  %s[/color]
" % [col, _fmt_time(e.t), ("🧬 " if e.type == "mutation" else "🏆 ") + str(e.id)]
	if _last_bot != null:
		var acts: Array = _last_bot.actions.slice(maxi(0, _last_bot.actions.size() - 4))
		if not acts.is_empty():
			t += "
[b]Acciones del bot[/b]
"
			for a in acts:
				t += "[color=#88ccff]%s  %s[/color]
" % [_fmt_time(a.t), a.action]
	if not report.is_empty() and report.has("outcome"):
		var o: Dictionary = report.outcome
		t += "
[b][color=#7dffb0]RUN TERMINADA[/color][/b]
"
		if o.run_closed:
			t += "Final: [b]%s[/b] a %s   PL +%d
" % [o.final_route, _fmt_time(o.t_end), o.pl_gained]
		else:
			t += "Run abierta al límite (%s)
" % _fmt_time(o.t_end)
		t += "[color=#9aa]Esc para salir[/color]
"
	else:
		t += "
[color=#667]+ / - velocidad · Espacio pausa · Esc salir[/color]"
	_hud.text = EmojiToRichText.rich(t)


static func _fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]


static func _fmt_speed(x: float) -> String:
	return ("%.0f" % x) if x >= 1.0 else ("%.2f" % x)


static func _fmt_num(x: float) -> String:
	var a := absf(x)
	if a >= 1e9:
		return "%.2fB" % (x / 1e9)
	if a >= 1e6:
		return "%.2fM" % (x / 1e6)
	if a >= 1e3:
		return "%.1fK" % (x / 1e3)
	return "%.1f" % x
