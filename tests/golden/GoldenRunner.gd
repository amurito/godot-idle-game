extends Node
## GoldenRunner — tests de caracterización del comportamiento ACTUAL del juego.
##
## Un golden test no afirma que el comportamiento sea correcto: congela el comportamiento de hoy
## para que cualquier refactor que lo cambie —aunque sea en el último bit de un float o en el
## tipo int/float de una variable— falle con un diff legible.
##
## Uso (siempre vía sandbox):
##   .\tools\sim\run_golden.ps1 -Mode record   → graba tests/golden/data/*.json con el código actual
##   .\tools\sim\run_golden.ps1                → compara contra lo grabado
##
## Suites:
##   economy     pipeline económico: perfiles de runtime × upgrades × mutaciones × buffs
##   save        build_save_data sobre estados con valores distintos en cada variable, y
##               apply_save_data de saves completos/vacíos/NaN/negativos/incompletos/viejos
##               sobre un estado "sucio" (hace observable la política de default por campo)
##   trajectory  run determinista del bot con volcado completo de estado cada 60 s
##
## Argumentos: --mode=record|check  --suite=economy|save|trajectory  --scenario=<id>  --t=<s>
##             --golden-dir=<ruta absoluta> (obligatorio al grabar; al chequear usa res://)

const SimGuard := preload("res://tests/sim/SimGuard.gd")
const SimDriver := preload("res://tests/sim/SimDriver.gd")
const BotPolicy := preload("res://tests/sim/BotPolicy.gd")
const Scenarios := preload("res://tests/sim/Scenarios.gd")
const StateDump := preload("res://tests/golden/StateDump.gd")
const MockMain := preload("res://tests/golden/MockMain.gd")

const DEFAULT_GOLDEN_DIR := "res://tests/golden/data"

## Autoloads con estado de partida: lo que el save serializa o el tick muta.
const GAME_AUTOLOADS := ["EconomyManager", "StructuralModel", "BiosphereEngine", "EvoManager",
	"RunManager", "UpgradeManager", "RouteManager", "LogManager"]
## Lo que hay que restaurar entre casos (incluye banco de legado y logros).
const RESTORE_AUTOLOADS := ["EconomyManager", "StructuralModel", "BiosphereEngine", "EvoManager",
	"RunManager", "UpgradeManager", "RouteManager", "LogManager", "LegacyManager", "AchievementManager"]
## Volcado de trayectorias: todo lo anterior.
const TRAJECTORY_AUTOLOADS := RESTORE_AUTOLOADS
## Autoloads cuyas variables primitivas se rellenan con valores distintos para la suite save.
const FILL_AUTOLOADS := ["EconomyManager", "StructuralModel", "BiosphereEngine", "EvoManager", "RunManager"]

# ── Suite economy: espacio de estados ───────────────────────────────────────────

const RUNTIME_PROFILES := {
	"calm": {"eps": 0.10, "omega": 0.80, "bio": 2.0, "hifas": 3.0, "nut": 10.0, "mu": 1.2, "pers": 1.4, "t": 30.0, "corrosion": 1.0, "ctrl": 0.0},
	"tense": {"eps": 0.45, "omega": 0.25, "bio": 12.0, "hifas": 12.0, "nut": 60.0, "mu": 2.0, "pers": 1.6, "t": 300.0, "corrosion": 0.7, "ctrl": 0.05},
	"edge": {"eps": 0.72, "omega": 0.07, "bio": 95.0, "hifas": 40.0, "nut": 160.0, "mu": 3.5, "pers": 1.9, "t": 900.0, "corrosion": 0.3, "ctrl": 0.1},
}

const UPGRADE_PROFILES := {
	"early": [["click", 5], ["click_mult", 2], ["auto", 3], ["auto_mult", 1], ["trueque", 1]],
	"late": [["click", 30], ["click_mult", 20], ["auto", 25], ["auto_mult", 25], ["trueque", 15],
		["trueque_net", 12], ["specialization", 8], ["cognitive", 10], ["accounting", 4], ["persistence", 1]],
}

## Variables de EvoManager por mutación. red_branch_selected: 0 NONE, 1 COLONIZATION, 2 SYMBIOSIS.
const MUTATIONS := {
	"none": {},
	"symbiosis": {"mutation_symbiosis": true},
	"red_micelial": {"mutation_red_micelial": true},
	"red_colonization": {"mutation_red_micelial": true, "red_branch_selected": 1},
	"red_nucleo": {"mutation_red_micelial": true, "red_branch_selected": 2, "nucleo_conciencia": true},
	"hyper": {"mutation_hyperassimilation": true},
	"hyper_mo": {"mutation_hyperassimilation": true, "mutation_met_oscuro": true},
	"mo_autolisis": {"mutation_met_oscuro": true, "mutation_autolisis": true},
	"mo_necrosis": {"mutation_met_oscuro": true, "mutation_necrosis": true, "necrosis_omega": 0.05, "necromasa": 40.0},
	"mo_omega_cero": {"mutation_met_oscuro": true, "mutation_omega_cero": true, "omega_cero_phi": 120.0, "omega_cero_omega": 0.04},
	"mo_remision": {"mutation_met_oscuro": true, "mutation_remision": true, "remision_omega": 0.3},
	"homeostasis": {"mutation_homeostasis": true},
	"allostasis": {"mutation_allostasis": true},
	"parasitism": {"mutation_parasitism": true},
	"depredador": {"mutation_depredador": true},
	"fusion_idle": {"mutation_fusion_catabolica": true},
	"fusion_burst": {"mutation_fusion_catabolica": true, "fusion_burst_timer": 5.0},
	"ayuno": {"mutation_ayuno_primordial": true, "ayuno_silencio": 150.0, "ayuno_ascesis_level": 3},
	"ayuno_burst": {"mutation_ayuno_primordial": true, "ayuno_ascesis_level": 3, "ayuno_burst_active": true, "_ayuno_burst_saved_mult": 4.0},
}

## Mutaciones representativas para el barrido buff-por-buff (una por familia de rutas).
const SINGLE_BUFF_MUTATIONS := ["none", "symbiosis", "red_colonization", "hyper", "mo_autolisis",
	"homeostasis", "parasitism", "fusion_burst", "ayuno"]

var mode := "check"
var golden_dir := DEFAULT_GOLDEN_DIR
var failures := 0
var checks := 0


func _ready() -> void:
	if not SimGuard.assert_sandbox():
		get_tree().quit(2)
		return
	await get_tree().process_frame
	LocaleManager.set_locale("es")  # los textos del log viajan en el save: locale fijo
	var args := SimGuard.parse_args()
	mode = str(args.get("mode", "check"))
	golden_dir = str(args.get("golden-dir", DEFAULT_GOLDEN_DIR))
	var suite := str(args.get("suite", ""))
	print("[Golden] modo=%s suite=%s" % [mode, suite])

	var t0 := Time.get_ticks_msec()
	match suite:
		"economy":
			suite_economy()
		"save":
			await suite_save()
		"trajectory":
			await suite_trajectory(str(args.get("scenario", "fresh_hiper")), float(args.get("t", "240")))
		_:
			printerr("[Golden] suite desconocida: '%s'" % suite)
			failures += 1

	print("[Golden] %s: %d comparaciones, %d fallas (%.1f s)" % [suite, checks, failures, (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit(0 if failures == 0 else 1)


# ═════════════════════════════════════════════════════════════════════════════
#  SUITE economy
# ═════════════════════════════════════════════════════════════════════════════

func suite_economy() -> void:
	print("── economy ──")
	var base := StateDump.capture_autoloads(RESTORE_AUTOLOADS)

	# Estados de upgrades por perfil, calculados con la misma fórmula que UpgradeManager.buy()
	# sin buffs (sin efectos colaterales de compra: logros, tutorial, audio).
	var up_states := {}
	for prof in UPGRADE_PROFILES:
		StateDump.restore_autoloads(base)
		_set_upgrade_levels(UPGRADE_PROFILES[prof])
		up_states[prof] = UpgradeManager.states.duplicate(true)

	var buff_sets := _buff_sets()
	var cases := {}

	for r in RUNTIME_PROFILES:
		for u in UPGRADE_PROFILES:
			for m in MUTATIONS:
				for b in ["none", "all", "route:vacio"]:
					cases["%s|%s|%s|%s" % [r, u, m, b]] = _economy_case(base, up_states[u], r, m, buff_sets[b])
		for m in SINGLE_BUFF_MUTATIONS:
			for b in buff_sets:
				if b in ["none", "all", "route:vacio"]:
					continue
				cases["%s|late|%s|%s" % [r, m, b]] = _economy_case(base, up_states["late"], r, m, buff_sets[b])

	StateDump.restore_autoloads(base)
	print("  %d casos" % cases.size())
	_golden("economy", cases)


func _economy_case(base: Dictionary, up_state: Dictionary, runtime_id: String, mutation_id: String, buff_set: Dictionary) -> Variant:
	StateDump.restore_autoloads(base)
	UpgradeManager.states = up_state.duplicate(true)
	_apply_runtime(RUNTIME_PROFILES[runtime_id])
	_apply_vars(EvoManager, MUTATIONS[mutation_id], "mutación " + mutation_id)
	_apply_buff_set(buff_set)
	var direct: Variant = StateDump.encode(_economy_outputs())
	_check_memo_equivalence(direct, "%s|%s|%s" % [runtime_id, mutation_id, str(buff_set.keys())])
	return direct


## Dentro de un bloque memo el pipeline debe devolver exactamente lo mismo que el cálculo directo,
## también en la segunda pasada (servida desde el caché).
func _check_memo_equivalence(direct: Variant, label: String) -> void:
	if not EconomyManager.has_method("begin_memo"):
		return
	EconomyManager.begin_memo()
	var first: Variant = StateDump.encode(_economy_outputs())
	var cached: Variant = StateDump.encode(_economy_outputs())
	EconomyManager.end_memo()
	var ref := JSON.stringify(direct, "", true, true)
	if JSON.stringify(first, "", true, true) != ref or JSON.stringify(cached, "", true, true) != ref:
		failures += 1
		printerr("[Golden] memo ≠ cálculo directo en %s" % label)


func _economy_outputs() -> Dictionary:
	var costs := {}
	for id in UpgradeManager.states:
		costs[id] = UpgradeManager.cost(id)
	return {
		"click": EconomyManager.get_click_power(),
		"passive": EconomyManager.get_passive_total(),
		"auto": EconomyManager.get_auto_income_effective(),
		"trueque": EconomyManager.get_trueque_income_effective(),
		"pmult": EconomyManager.get_passive_multiplier(),
		"ms": EconomyManager.get_memoria_sinaptica_additive(),
		"delta_total": EconomyManager.get_delta_total(),
		"breakdown": EconomyManager.get_contribution_breakdown(),
		"active_passive": EconomyManager.get_active_passive_breakdown(),
		"dominant": EconomyManager.get_dominant_term(),
		"cost": costs,
	}


func _set_upgrade_levels(levels: Array) -> void:
	for pair in levels:
		var id: String = pair[0]
		var lvl: int = pair[1]
		var def: UpgradeDef = UpgradeManager.get_def(id)
		if def == null or not UpgradeManager.states.has(id):
			printerr("[Golden] upgrade inexistente en perfil: %s" % id)
			failures += 1
			continue
		var value: float = def.base_value
		var cost: float = def.base_cost
		for i in lvl:
			value = value * def.gain if def.is_multiplicative else value + def.gain
			cost *= def.cost_scale
		var s: Dictionary = UpgradeManager.states[id]
		s["level"] = lvl
		s["unlocked"] = true
		s["current_value"] = value
		s["current_cost"] = cost


func _apply_runtime(r: Dictionary) -> void:
	StructuralModel.epsilon_runtime = r.eps
	StructuralModel.epsilon_effective = r.eps
	StructuralModel.omega = r.omega
	StructuralModel.persistence_dynamic = r.pers
	StructuralModel.control_omega_offset = r.ctrl
	EconomyManager.cached_mu = r.mu
	EconomyManager.parasitism_corrosion = r.corrosion
	BiosphereEngine.biomasa = r.bio
	BiosphereEngine.hifas = r.hifas
	BiosphereEngine.nutrientes = r.nut
	RunManager.run_time = r.t


## Set validado: Object.set() sobre una propiedad inexistente falla en silencio y debilitaría
## el golden sin avisar, así que cada nombre se verifica antes.
func _apply_vars(node: Object, vars: Dictionary, label: String) -> void:
	var known := StateDump.script_vars(node)
	for k in vars:
		if not (str(k) in known):
			printerr("[Golden] %s: variable inexistente '%s'" % [label, k])
			failures += 1
			continue
		node.set(k, vars[k])


func _buff_sets() -> Dictionary:
	var sets := {"none": {}, "route:vacio": {"route": "vacio"}}
	var all_buffs := {}
	for id in LegacyManager.LEGACY_DEFS:
		var lvl := int(LegacyManager.LEGACY_DEFS[id].get("max_level", 1))
		sets["buff:" + str(id)] = {"buffs": {id: lvl}}
		all_buffs[id] = lvl
	var all_cosmic: Array = []
	for cid in LegacyManager.COSMIC_DATA:
		sets["cosmic:" + str(cid)] = {"cosmic": [cid]}
		all_cosmic.append(cid)
	sets["all"] = {"buffs": all_buffs, "cosmic": all_cosmic, "trascendencia_count": 5,
		"endings": ["SIMBIOSIS", "PARASITISMO"]}
	return sets


func _apply_buff_set(spec: Dictionary) -> void:
	var buffs: Dictionary = spec.get("buffs", {})
	for id in buffs:
		LegacyManager._set_buff_level(str(id), int(buffs[id]))
	for cid in spec.get("cosmic", []):
		LegacyManager.cosmic_unlocked[str(cid)] = true
	if spec.has("trascendencia_count"):
		LegacyManager.trascendencia_count = int(spec.trascendencia_count)
	for e in spec.get("endings", []):
		LegacyManager.endings_achieved[str(e)] = true
	if spec.has("route"):
		RouteManager.activate(str(spec.route))


# ═════════════════════════════════════════════════════════════════════════════
#  SUITE save (build + load)
# ═════════════════════════════════════════════════════════════════════════════

func suite_save() -> void:
	print("── save ──")
	var mock: Node = MockMain.new()
	add_child(mock)
	var base := StateDump.capture_autoloads(RESTORE_AUTOLOADS)

	# El esquema no puede referenciar propiedades inexistentes (get/set las ignorarían en silencio).
	# Se carga dinámicamente para que este runner también funcione sobre código anterior al esquema
	# (así se graban los goldens con el comportamiento original).
	if ResourceLoader.exists("res://SaveSchema.gd"):
		checks += 1
		var schema_errors: PackedStringArray = load("res://SaveSchema.gd").validate(mock)
		if schema_errors.is_empty():
			print("  [OK] SaveSchema.validate()")
		else:
			failures += 1
			for e in schema_errors:
				print("  [ERROR] SaveSchema: %s" % e)

	# ── build: cada variable con un valor distinto → cualquier campo mal mapeado salta ──
	var build := {}
	var fixtures := {}
	for variant in [["distinct_a", 1], ["distinct_b", 2]]:
		StateDump.restore_autoloads(base)
		_fill_distinct(int(variant[1]), mock)
		var data: Dictionary = SaveManager.build_save_data(mock)
		_add_sections(build, str(variant[0]), data)
		fixtures["full_" + str(variant[0]).trim_prefix("distinct_")] = JSON.parse_string(JSON.stringify(data))

	# NaN en todo float: caracteriza qué campos sanea _sf() al guardar y cuáles no.
	StateDump.restore_autoloads(base)
	_fill_distinct(1, mock)
	_fill_floats(NAN)
	_add_sections(build, "nan_all", SaveManager.build_save_data(mock))
	_golden("save_build", build)

	# ── load: cada fixture se aplica sobre DOS estados "sucios" (variante 7 y la misma con
	# booleanos invertidos). Así la política de default de cada campo (valor actual en memoria
	# vs. literal) queda visible en el volcado: para cualquier bool, en uno de los dos estados
	# el valor sucio difiere del literal false. ──
	var full_a: Dictionary = fixtures["full_a"]
	fixtures["empty"] = {}
	fixtures["empty_sections"] = {"economy": {}, "dynamic_vars": {}, "upgrades": {}, "structural": {},
		"flags": {}, "evolution": {}, "homeostasis": {}, "post_tras": {}, "laps": []}
	fixtures["nan_values"] = _map_numbers(full_a, func(_x: float) -> float: return NAN)
	fixtures["negative"] = _map_numbers(full_a, func(x: float) -> float: return -absf(x) - 1.5)
	fixtures["alternating_missing"] = _drop_alternate_keys(full_a)
	fixtures["migration_legacy"] = {
		"flags": {"run_closed": false, "final_route": "", "unlocked_tree": true},
		"achievements": {"legacy_achievement_x": true},
		"evolution": {"genome": {"hiperasimilacion": "latente"}, "mutation_sporulation": true},
	}

	var loaded := {}
	for fid in fixtures:
		for dirty in [["dirtyA", false], ["dirtyB", true]]:
			StateDump.restore_autoloads(base)
			_fill_distinct(7, mock, bool(dirty[1]))
			var data: Dictionary = fixtures[fid].duplicate(true)
			data = SaveManager._migrate(data)
			SaveManager.apply_save_data(mock, data)
			var dumped := StateDump.dump_autoloads(GAME_AUTOLOADS)
			dumped["MockMain"] = StateDump.dump(mock)
			for section in dumped:
				loaded["%s@%s|%s" % [fid, dirty[0], section]] = dumped[section]
	_golden("save_load", loaded)

	# ── realismo: save de una run real simulada (main.tscn real) ──
	StateDump.restore_autoloads(base)
	mock.queue_free()
	var sc: Dictionary = Scenarios.ALL["fresh_hiper"]
	var d = SimDriver.new()
	if not await d.boot(self, {"seed": 99, "platform": "desktop", "ui": true}):
		failures += 1
		return
	var bot = BotPolicy.new(sc.bot)
	while d.now() < 90.0:
		d.step(bot)
	var sim_build := {}
	_add_sections(sim_build, "fresh_hiper_t90", SaveManager.build_save_data(d.main))
	_golden("save_build_sim", sim_build)


func _add_sections(out: Dictionary, prefix: String, data: Dictionary) -> void:
	for section in data:
		if section == "save_version":
			continue  # cambia con cada release; no es parte del contrato del refactor
		out["%s|%s" % [prefix, section]] = StateDump.encode(data[section])


## Asigna a cada variable primitiva un valor distinto derivado de su NOMBRE (y de la variante).
## Derivarlo del nombre —y no de un contador— hace que agregar o quitar variables en un manager
## no altere los valores de las demás: el diff de un golden muestra sólo lo que cambió.
func _fill_distinct(variant: int, mock: Node, invert_bools: bool = false) -> void:
	for n in FILL_AUTOLOADS:
		var node := get_node("/root/" + n)
		for name in StateDump.state_vars(node):
			match typeof(node.get(name)):
				TYPE_BOOL:
					node.set(name, _distinct_bool(name, variant, invert_bools))
				TYPE_INT:
					node.set(name, _distinct_int(name, variant))
				TYPE_FLOAT:
					node.set(name, _distinct_float(name, variant))
				TYPE_STRING:
					node.set(name, "v%d_%s" % [variant, name])
	var genome_states := ["dormido", "latente", "activo", "bloqueado"]
	for k in EvoManager.genome.keys():
		EvoManager.genome[k] = genome_states[_distinct_int("genome." + str(k), variant) % genome_states.size()]
	for id in UpgradeManager.states:
		var s: Dictionary = UpgradeManager.states[id]
		s["level"] = 2 + _distinct_int(str(id) + ".level", variant) % 60
		s["current_cost"] = _distinct_float(str(id) + ".cost", variant) * 7.0
		s["current_value"] = _distinct_float(str(id) + ".value", variant)
		s["unlocked"] = _distinct_bool(str(id) + ".unlocked", variant, invert_bools)
	LogManager.lap_events = [
		{"time": "00:0%d:00" % variant, "event": "lap A v%d" % variant},
		{"time": "00:0%d:30" % variant, "event": "lap B v%d" % variant},
	]
	mock.memory_trigger_count = _distinct_int("memory_trigger_count", variant)
	mock.institutions_unlocked = _distinct_bool("institutions_unlocked", variant, invert_bools)


static func _distinct_hash(name: String, variant: int) -> int:
	return absi(("%s#%d" % [name, variant]).hash())


static func _distinct_int(name: String, variant: int) -> int:
	return 3 + _distinct_hash(name, variant) % 100000


## Múltiplos de 1/32: exactos en binario, sin ruido de formato al serializar.
static func _distinct_float(name: String, variant: int) -> float:
	return 0.5 + float(_distinct_hash(name, variant) % 64000) / 32.0


static func _distinct_bool(name: String, variant: int, invert: bool) -> bool:
	var b: bool = (_distinct_hash(name, variant) & 1) == 1
	return not b if invert else b


func _fill_floats(value: float) -> void:
	for n in FILL_AUTOLOADS:
		var node := get_node("/root/" + n)
		for name in StateDump.state_vars(node):
			if typeof(node.get(name)) == TYPE_FLOAT:
				node.set(name, value)
	for id in UpgradeManager.states:
		UpgradeManager.states[id]["current_cost"] = value
		UpgradeManager.states[id]["current_value"] = value


## Reemplaza recursivamente cada número (tras JSON todos son float) por fn(x).
func _map_numbers(v: Variant, fn: Callable) -> Variant:
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			return fn.call(float(v))
		TYPE_DICTIONARY:
			var out := {}
			for k in v:
				out[k] = _map_numbers(v[k], fn)
			return out
		TYPE_ARRAY:
			var arr: Array = []
			for item in v:
				arr.append(_map_numbers(item, fn))
			return arr
		_:
			return v


## En cada sección, elimina una clave sí y una no (orden alfabético): simula saves de versiones
## anteriores a las que les faltan campos, mezclados con campos presentes.
func _drop_alternate_keys(data: Dictionary) -> Dictionary:
	var out := {}
	for section in data:
		var value: Variant = data[section]
		if typeof(value) != TYPE_DICTIONARY:
			out[section] = value
			continue
		var keys: Array = value.keys()
		keys.sort()
		var kept := {}
		for idx in keys.size():
			if idx % 2 == 0:
				kept[keys[idx]] = value[keys[idx]]
		out[section] = kept
	return out


# ═════════════════════════════════════════════════════════════════════════════
#  SUITE trajectory
# ═════════════════════════════════════════════════════════════════════════════

func suite_trajectory(scenario_id: String, t_max: float) -> void:
	print("── trajectory %s (%.0f s) ──" % [scenario_id, t_max])
	if not Scenarios.ALL.has(scenario_id):
		printerr("[Golden] escenario desconocido: %s" % scenario_id)
		failures += 1
		return
	var sc: Dictionary = Scenarios.ALL[scenario_id]
	Scenarios.apply_legacy(sc.get("legacy", {}))
	var d = SimDriver.new()
	if not await d.boot(self, {"seed": 777, "platform": "desktop", "ui": true}):
		failures += 1
		return
	var bot = BotPolicy.new(sc.get("bot", {}))

	var out := {}
	var sample_frames := int(roundf(5.0 / d.dt()))
	var dump_frames := int(roundf(60.0 / d.dt()))
	var max_frames := int(roundf(t_max / d.dt()))
	out["sample_%08.1f" % 0.0] = StateDump.encode(d.sample())
	var has_memo: bool = EconomyManager.has_method("begin_memo")
	var memo_leaks := 0
	while d.frame < max_frames and not RunManager.run_closed:
		for i in 400:
			d.step(bot)
			# Invariante: entre frames ningún bloque memo puede quedar abierto (cachearía la economía).
			if has_memo and (int(EconomyManager.get("_memo_depth")) != 0 or not (EconomyManager.get("_memo") as Dictionary).is_empty()):
				memo_leaks += 1
			if d.frame % sample_frames == 0:
				out["sample_%08.1f" % d.now()] = StateDump.encode(d.sample())
			if d.frame % dump_frames == 0:
				_add_dump(out, "dump_%08.1f" % d.now())
			if RunManager.run_closed or d.frame >= max_frames:
				break
		await get_tree().process_frame
	_add_dump(out, "end")
	out["end|events"] = StateDump.encode({"events": d.events, "purchases": d.purchases,
		"actions": bot.actions, "clicks": d.clicks})
	if has_memo:
		checks += 1
		if memo_leaks == 0:
			print("  [OK] invariante memo: ningún bloque abierto entre frames (%d frames)" % d.frame)
		else:
			failures += 1
			print("  [ERROR] invariante memo: %d frames con un bloque memo abierto" % memo_leaks)
	_golden("trajectory_" + scenario_id, out)


func _add_dump(out: Dictionary, prefix: String) -> void:
	var dumped := StateDump.dump_autoloads(TRAJECTORY_AUTOLOADS)
	for n in dumped:
		out["%s|%s" % [prefix, n]] = dumped[n]


# ═════════════════════════════════════════════════════════════════════════════
#  Grabar / comparar
# ═════════════════════════════════════════════════════════════════════════════

## data: Dictionary cuyas claves de primer nivel definen una línea del archivo (diffs legibles).
##
## La comparación es por TEXTO canónico: cada valor en memoria se convierte una sola vez a JSON
## (claves ordenadas, floats con precisión completa) tanto al grabar como al chequear. Igualdad de
## texto ⇔ valores idénticos bit a bit. No se compara contra el JSON reparseado porque la
## conversión float↔texto de Godot no es idempotente en los últimos bits.
func _golden(name: String, data: Dictionary) -> void:
	checks += 1
	var actual := _line_map(data)
	var path := golden_dir.path_join(name + ".json")
	if mode == "record":
		if SimGuard.write_text(path, _render_lines(actual)):
			print("  [REC] %s (%d entradas)" % [name, actual.size()])
		else:
			failures += 1
		return
	var golden := _read_lines(path)
	if golden.is_empty():
		failures += 1
		print("  [FALTA] %s: no hay golden grabado en %s (corré con -Mode record)" % [name, path])
		return

	var changed: Array = []
	var missing: Array = []
	var extra: Array = []
	for k in golden:
		if not actual.has(k):
			missing.append(k)
		elif actual[k] != golden[k]:
			changed.append(k)
	for k in actual:
		if not golden.has(k):
			extra.append(k)
	if changed.is_empty() and missing.is_empty() and extra.is_empty():
		print("  [OK] %s (%d entradas)" % [name, actual.size()])
		return

	failures += 1
	print("  [DIFF] %s: %d entradas cambiadas, %d faltantes, %d nuevas" % [name, changed.size(), missing.size(), extra.size()])
	for k in missing.slice(0, 5):
		print("     faltante: %s" % k)
	for k in extra.slice(0, 5):
		print("     nueva:    %s" % k)
	var shown := 0
	for k in changed:
		if shown >= 12:
			break
		var diffs := StateDump.diff(JSON.parse_string(golden[k]), JSON.parse_string(actual[k]), k, [], 4)
		for e in diffs:
			print("     %s\n        golden: %s\n        actual: %s" % [e.path, str(e.golden), str(e.actual)])
			shown += 1


## { clave → texto JSON canónico del valor }
static func _line_map(data: Dictionary) -> Dictionary:
	var out := {}
	for k in data:
		out[str(k)] = JSON.stringify(data[k], "", true, true)
	return out


## JSON válido con una entrada de primer nivel por línea y claves ordenadas: archivos
## estables y diffs de git legibles.
static func _render_lines(lines_by_key: Dictionary) -> String:
	var keys := lines_by_key.keys()
	keys.sort()
	var lines: Array = []
	for k in keys:
		lines.append("%s: %s" % [JSON.stringify(str(k)), lines_by_key[k]])
	return "{\n" + ",\n".join(lines) + "\n}\n"


## Inversa de _render_lines: lee el texto de cada entrada sin reparsear los valores.
static func _read_lines(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line()
		if line == "{" or line == "}" or line.strip_edges() == "":
			continue
		var sep := line.find("\": ")
		if sep < 0:
			continue
		var key: String = JSON.parse_string(line.substr(0, sep + 1))
		out[key] = line.substr(sep + 3).trim_suffix(",")
	f.close()
	return out
