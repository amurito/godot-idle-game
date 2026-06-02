extends Node

# TelemetryManager.gd - opt-in anonymous telemetry.
# Stores anonymous run JSON under user://telemetry/runs/ and, if REMOTE_ENDPOINT
# is configured, also POSTs each run to the remote receiver. Only when enabled.

const SETTINGS_PATH := "user://telemetry_settings.json"
const ID_PATH := "user://telemetry_id.txt"
const RUNS_DIR := "user://telemetry/runs"
const MAX_RUN_FILES := 100

# Receptor remoto (opt-in): al cerrar una run, además de guardar el JSON local,
# se POSTea a este endpoint del hub (hyphae-game-hub, server.js -> /api/telemetry).
# Mismo origen cuando se juega en el hub; cross-origin (CORS) cuando se juega en itch.io.
# Dejar vacío = solo local (sin envío remoto). Verificá que la URL del hub sea la correcta.
const REMOTE_ENDPOINT := "https://hyphae-game-hub.onrender.com/api/telemetry"
# Solo si el hub tiene TELEMETRY_INGEST_KEY seteado: mismo valor acá (header X-Telemetry-Key).
const REMOTE_INGEST_KEY := ""
const REMOTE_TIMEOUT := 10.0

var enabled: bool = false
var session_id: String = ""

var _session_started_at: int = 0
var _run_started_at: int = 0
var _run_active: bool = false
var _main_ref: Node = null

var _events: Array = []
var _metrics_series: Array = []
var _mutations_activated: Array = []
var _first_epsilon_high_recorded: bool = false
var _epsilon_peak_seen: float = 0.0


func _ready() -> void:
	_load_settings()
	_connect_game_signals()
	if enabled:
		_start_session()
		_ensure_runs_dir()


func is_enabled() -> bool:
	return enabled


func get_runs_dir_path() -> String:
	_ensure_runs_dir()
	return ProjectSettings.globalize_path(RUNS_DIR)


func open_runs_dir() -> void:
	var path := get_runs_dir_path()
	if OS.get_name() == "HTML5":
		return
	OS.shell_open(path)


func set_enabled(value: bool) -> void:
	if enabled == value:
		return

	enabled = value
	_save_settings()

	if enabled:
		_start_session()
		_ensure_runs_dir()
		if is_instance_valid(_main_ref) and not RunManager.run_closed:
			start_run(_main_ref)
	else:
		if _session_started_at > 0:
			track_event("session_end", {
				"duration_seconds": int(Time.get_unix_time_from_system()) - _session_started_at
			})
		_clear_runtime_buffers()


func start_run(main: Node) -> void:
	_main_ref = main
	if not enabled:
		return

	if session_id == "":
		_start_session()

	_run_started_at = int(Time.get_unix_time_from_system())
	_run_active = true
	_first_epsilon_high_recorded = false
	_epsilon_peak_seen = 0.0
	_events.clear()
	_metrics_series.clear()
	_mutations_activated.clear()

	track_event("session_start", {
		"game_version": _get_game_version(),
		"platform": OS.get_name()
	})
	track_event("run_start")
	sample_metrics(main)


func close_run(summary := {}) -> void:
	if not enabled or not _run_active:
		return

	var run_summary := _build_run_summary(summary)
	track_event("run_close", {
		"final_route": str(run_summary.get("final_route", "")),
		"run_time": float(run_summary.get("run_time", 0.0)),
		"pl_gained": int(run_summary.get("pl_gained", 0))
	})

	var data := {
		"meta": {
			"game_version": _get_game_version(),
			"session_id": session_id,
			"timestamp_start": _run_started_at,
			"timestamp_end": int(Time.get_unix_time_from_system()),
			"platform": OS.get_name()
		},
		"run_summary": run_summary,
		"events": _events.duplicate(true),
		"metrics_series": _metrics_series.duplicate(true)
	}

	_run_active = false
	call_deferred("_save_run_json", data)
	_send_remote(data)


func sample_metrics(main: Node, store_sample: bool = true) -> void:
	_main_ref = main
	if not enabled or not _run_active or not is_instance_valid(main):
		return

	var epsilon := float(StructuralModel.epsilon_runtime)
	_epsilon_peak_seen = max(_epsilon_peak_seen, epsilon)
	if not _first_epsilon_high_recorded and epsilon > 0.65:
		_first_epsilon_high_recorded = true
		track_event("first_epsilon_high", {"epsilon_value": epsilon})

	if not store_sample:
		return

	_metrics_series.append({
		"time": _get_run_time(),
		"epsilon": epsilon,
		"omega": float(StructuralModel.omega),
		"money": float(EconomyManager.money),
		"biomasa": float(BiosphereEngine.biomasa),
		"mu": _get_main_float(main, "cached_mu", 1.0)
	})


func track_event(type: String, payload := {}) -> void:
	if not enabled:
		return

	var event := {
		"type": type,
		"session_id": session_id,
		"timestamp": int(Time.get_unix_time_from_system()),
		"time": _get_run_time()
	}
	if payload is Dictionary:
		for key in payload.keys():
			event[key] = payload[key]
	_events.append(event)

	if type == "mutation_activated" and payload is Dictionary:
		var mutation_id := str(payload.get("mutation_id", ""))
		if mutation_id != "" and not _mutations_activated.has(mutation_id):
			_mutations_activated.append(mutation_id)


func _connect_game_signals() -> void:
	var mutation_callable := Callable(self, "_on_mutation_activated")
	if not EvoManager.mutation_activated.is_connected(mutation_callable):
		EvoManager.mutation_activated.connect(mutation_callable)
	var achievement_callable := Callable(self, "_on_achievement_unlocked")
	if not AchievementManager.achievement_unlocked.is_connected(achievement_callable):
		AchievementManager.achievement_unlocked.connect(achievement_callable)


func _on_mutation_activated(mutation_id: String, _display_name: String) -> void:
	track_event("mutation_activated", {"mutation_id": mutation_id})


func _on_achievement_unlocked(achievement_id: String, _def: Dictionary) -> void:
	track_event("achievement_unlocked", {"achievement_id": achievement_id})


func _start_session() -> void:
	if session_id == "":
		session_id = _load_or_create_session_id()
	_session_started_at = int(Time.get_unix_time_from_system())


func _clear_runtime_buffers() -> void:
	_run_active = false
	_session_started_at = 0
	_run_started_at = 0
	_events.clear()
	_metrics_series.clear()
	_mutations_activated.clear()
	_first_epsilon_high_recorded = false
	_epsilon_peak_seen = 0.0


func _load_settings() -> void:
	enabled = false
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return
	enabled = bool(json.data.get("enabled", false))


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"enabled": enabled}, "\t"))
		file.close()


func _load_or_create_session_id() -> String:
	if FileAccess.file_exists(ID_PATH):
		var file := FileAccess.open(ID_PATH, FileAccess.READ)
		if file:
			var existing := file.get_as_text().strip_edges()
			file.close()
			if existing != "":
				return existing

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var new_id := "PLAYER_%d_%d" % [int(Time.get_unix_time_from_system()), rng.randi()]
	var out := FileAccess.open(ID_PATH, FileAccess.WRITE)
	if out:
		out.store_string(new_id)
		out.close()
	return new_id


func _build_run_summary(summary: Dictionary) -> Dictionary:
	var main := _main_ref
	var run_time := float(summary.get("run_time", _get_run_time()))
	var max_mu := float(summary.get("max_mu", 0.0))
	var max_delta := float(summary.get("max_delta_per_sec", 0.0))
	if is_instance_valid(main):
		max_mu = float(summary.get("max_mu", _get_main_float(main, "mu_peak_run", max_mu)))
		max_delta = float(summary.get("max_delta_per_sec", _get_main_float(main, "delta_peak_run", max_delta)))

	return {
		"final_route": str(summary.get("final_route", RunManager.final_route)),
		"pl_gained": int(summary.get("pl_gained", 0)),
		"run_time": run_time,
		"epsilon_peak": max(float(summary.get("epsilon_peak", StructuralModel.epsilon_peak)), _epsilon_peak_seen),
		"max_mu": max_mu,
		"max_delta_per_sec": max_delta,
		"mutations_activated": summary.get("mutations_activated", _mutations_activated.duplicate()),
		"trascendencia_count": int(summary.get("trascendencia_count", LegacyManager.trascendencia_count))
	}


func _send_remote(data: Dictionary) -> void:
	# Envío anónimo opt-in al receptor remoto. No bloquea el juego: fire-and-forget.
	if REMOTE_ENDPOINT == "":
		return

	var body := JSON.stringify(data)
	var req := HTTPRequest.new()
	req.timeout = REMOTE_TIMEOUT
	add_child(req)
	# Liberar el nodo al terminar (ok o error), sin reintentos.
	req.request_completed.connect(func(_result, _code, _headers, _bytes):
		req.queue_free())

	var headers := PackedStringArray(["Content-Type: application/json"])
	if REMOTE_INGEST_KEY != "":
		headers.append("X-Telemetry-Key: " + REMOTE_INGEST_KEY)

	var err := req.request(REMOTE_ENDPOINT, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		req.queue_free()


func _save_run_json(data: Dictionary) -> void:
	_ensure_runs_dir()
	var stamp := _timestamp_for_filename()
	var path := "%s/run_%s.json" % [RUNS_DIR, stamp]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	_prune_old_runs()


func _ensure_runs_dir() -> void:
	if not DirAccess.dir_exists_absolute(RUNS_DIR):
		DirAccess.make_dir_recursive_absolute(RUNS_DIR)


func _prune_old_runs() -> void:
	var dir := DirAccess.open(RUNS_DIR)
	if not dir:
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	files.sort()
	while files.size() > MAX_RUN_FILES:
		var old_file: String = files.pop_front()
		DirAccess.remove_absolute("%s/%s" % [RUNS_DIR, old_file])


func _timestamp_for_filename() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		int(t.year), int(t.month), int(t.day), int(t.hour), int(t.minute), int(t.second)
	]


func _get_run_time() -> float:
	if RunManager.run_time > 0.0:
		return RunManager.run_time
	if _run_started_at > 0:
		return float(int(Time.get_unix_time_from_system()) - _run_started_at)
	return 0.0


func _get_main_float(main: Node, property_name: String, fallback: float) -> float:
	var value = main.get(property_name)
	if value == null:
		return fallback
	return float(value)


func _get_game_version() -> String:
	return str(Version.VERSION)
