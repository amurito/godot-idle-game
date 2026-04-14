extends Node

# LogManager.gd — Autoload
# Gestiona la bitácora de eventos (laps), el toggle de vista,
# la exportación de runs y el snapshot de sesión.

# =====================================================
#  ESTADO
# =====================================================
var lap_events: Array = []
var last_dominance: String = ""
var show_all_laps: bool = false

func reset() -> void:
	lap_events.clear()
	last_dominance = ""
	show_all_laps = false

# =====================================================
#  API — Agregar eventos
# =====================================================
func add(event: String, main: Control) -> void:
	lap_events.append({
		"time": main.format_time(main.run_time),
		"event": event,
		"click": snapped(main.get_click_power(), 0.01),
		"activo_ps": snapped(main.get_click_power() * main.CLICK_RATE, 0.01),
		"pasivo_ps": snapped(main.get_passive_total(), 0.01),
		"dominante": main.get_dominant_term(),
		"mu": snapped(main.cached_mu, 0.01),
		"mu_level": UpgradeManager.level("cognitive"),
	})

func check_dominance_transition(main: Control) -> void:
	var d = main.get_dominant_term()
	if d != last_dominance:
		add("Transición de dominio → " + d, main)
		last_dominance = d

# =====================================================
#  API — Filtros y vista
# =====================================================
func is_major(event: String) -> bool:
	return (
		event.find("Mutación") != -1
		or event.find("FINAL") != -1
		or event.find("LOGRO") != -1
		or event.find("Institución") != -1
	)

func update_log_label(main: Control) -> void:
	if not UIManager.lap_log_label: return
	
	if not main.lab_mode:
		UIManager.lap_log_label.text = ""
		return

	var txt := ""
	if show_all_laps:
		var lines := 18
		txt = "--- Eventos (completo) ---\n"
		var start = max(0, lap_events.size() - lines)
		for i in range(start, lap_events.size()):
			var lap = lap_events[i]
			txt += "%s → %s\n" % [lap.time, lap.event]
	else:
		# vista compacta: sólo eventos "mayores"
		txt = "--- Eventos clave ---\n"
		var shown := 0
		for i in range(lap_events.size() - 1, -1, -1):
			var lap = lap_events[i]
			if is_major(lap.event):
				txt += "%s → %s\n" % [lap.time, lap.event]
				shown += 1
			if shown >= 6:
				break
	
	UIManager.lap_log_label.text = txt

func update_toggle_button(_main: Control) -> void:
	if UIManager.toggle_lap_button:
		UIManager.toggle_lap_button.text = (
			"📜 Ver todos los eventos"
			if not show_all_laps
			else "📋 Ver eventos clave"
		)

func toggle_view(main: Control) -> void:
	show_all_laps = !show_all_laps
	update_toggle_button(main)
	update_log_label(main)

# =====================================================
#  API — Save / Load
# =====================================================
func get_lap_array() -> Array:
	return lap_events

func load_laps(arr) -> void:
	if arr is Array:
		lap_events = arr

# =====================================================
#  API — Export Run
# =====================================================
func get_run_filename() -> String:
	var t = Time.get_datetime_dict_from_system()
	return "run_%02d-%02d-%02d_%02d-%02d" % [
		t.day, t.month, t.year % 100, t.hour, t.minute
	]

func _get_timestamp_meta() -> Dictionary:
	var now := Time.get_datetime_dict_from_system()
	var dd := str(now.day).pad_zeros(2)
	var mm := str(now.month).pad_zeros(2)
	var yyyy := str(now.year)
	var hh := str(now.hour).pad_zeros(2)
	var mi := str(now.minute).pad_zeros(2)
	return {
		"fecha_humana": "%s/%s/%s" % [dd, mm, yyyy],
		"hora_humana": "%s:%s" % [hh, mi],
		"filename_stamp": "%s-%s-%s_%s-%s" % [dd, mm, yyyy, hh, mi]
	}

func _ensure_runs_dir() -> void:
	var path = "user://runs"
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)

func build_run_json(main: Control, meta: Dictionary) -> Dictionary:
	return {
		"version": main.VERSION,
		"fecha": meta.fecha_humana,
		"hora": meta.hora_humana,
		"tiempo_sesion": UIManager.session_time_label.text if UIManager.session_time_label else "",
		"delta_total_s": UIManager.sys_delta_label.text if UIManager.sys_delta_label else "",
		"activo_vs_pasivo": UIManager.sys_active_passive_label.text if UIManager.sys_active_passive_label else "",
		"distribucion_aporte": UIManager.sys_breakdown_label.text if UIManager.sys_breakdown_label else "",
		"lap_markers": UIManager.lap_log_label.text if UIManager.lap_log_label else "",
		"dominio": main.get_dominant_term(),
		"laps": lap_events,
		"evolution": {
			"final_route": main.final_route,
			"mutation_flags": {
				"homeostasis": EvoManager.mutation_homeostasis,
				"hyperassimilation": EvoManager.mutation_hyperassimilation,
				"symbiosis": EvoManager.mutation_symbiosis,
				"red_micelial": EvoManager.mutation_red_micelial
			},
			"structural_state": {
				"epsilon_runtime": StructuralModel.epsilon_runtime,
				"epsilon_peak": StructuralModel.epsilon_peak,
				"omega": StructuralModel.omega,
				"omega_min": StructuralModel.omega_min,
				"biomasa": BiosphereEngine.biomasa,
				"hifas": BiosphereEngine.hifas,
				"accounting_level": UpgradeManager.level("accounting")
			}
		}
	}

func build_run_csv(meta: Dictionary) -> String:
	var csv := ""
	csv += "fecha;hora;tiempo_sesion\n"
	csv += "%s;%s;\n" % [meta.fecha_humana, meta.hora_humana]
	return csv

func build_clipboard_text(main: Control, meta: Dictionary) -> String:
	var t := ""
	t += "IDLE — Modelo Económico Evolutivo\n"
	t += "Run exportada — %s %s\n" % [meta.fecha_humana, meta.hora_humana]
	t += "Versión: %s\n" % main.VERSION
	t += "--------------------------------\n\n"
	t += "--- Sistema — Δ$ y dinámica ---\n"
	t += (UIManager.sys_delta_label.text if UIManager.sys_delta_label else "") + "\n\n"
	t += (UIManager.sys_active_passive_label.text if UIManager.sys_active_passive_label else "") + "\n\n"
	t += (UIManager.sys_breakdown_label.text if UIManager.sys_breakdown_label else "") + "\n\n"
	t += (UIManager.session_time_label.text if UIManager.session_time_label else "") + "\n\n"
	t += (UIManager.lap_log_label.text if UIManager.lap_log_label else "")
	return t

func export_run(main: Control) -> void:
	_ensure_runs_dir()
	var meta := _get_timestamp_meta()
	
	# JSON
	var json_data := build_run_json(main, meta)
	var json_path := "user://runs/run_%s.json" % meta.filename_stamp
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file:
		json_file.store_string(JSON.stringify(json_data, "\t"))
		json_file.close()

	# CSV
	var csv_path := "user://runs/run_%s.csv" % meta.filename_stamp
	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file:
		csv_file.store_string(build_run_csv(meta))
		csv_file.close()

	# Clipboard
	DisplayServer.clipboard_set(build_clipboard_text(main, meta))

	if UIManager.system_message_label:
		UIManager.system_message_label.text = "Run exportada — %s %s\nGuardada en /runs" % [meta.fecha_humana, meta.hora_humana]
