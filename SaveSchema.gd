# SaveSchema.gd
# Esquema declarativo del savegame: ÚNICA fuente de verdad de qué se persiste y cómo.
#
# Antes, cada campo se escribía a mano dos veces —en build_save_data() y en apply_save_data()—
# y olvidar uno de los dos lados hacía que el campo dejara de persistir sin ningún error.
# Ahora cada campo se declara una sola vez acá y SaveManager recorre el esquema en ambas
# direcciones. Agregar un campo persistente = agregar UNA línea en la sección correspondiente.
#
# El formato del JSON NO cambia: mismas secciones, mismas claves, mismo saneamiento, mismos
# defaults. Las secciones son agrupaciones lógicas del save, no managers: "evolution" incluye
# campos de BiosphereEngine, "structural" de EconomyManager/RunManager/main, etc.
#
# ── Opciones por campo (_f) ──────────────────────────────────────────────────────
#   prop       propiedad destino si difiere de la clave del save
#   save_get   Callable cuyo retorno se guarda en lugar de leer la propiedad
#   save_sf    guardar como SaveManager._sf(valor, save_sf)        (protección NaN/INF)
#   default    valor si la clave falta al cargar. SIN esta opción el default es el valor
#              actual en memoria (semántica histórica de los campos más viejos)
#   load_sf    [fallback, min] → cargar como SaveManager._sf(valor, fallback, min)
#   load_int   cargar como int(valor)
#
# ── Agregar un campo persistente ─────────────────────────────────────────────────
#   1. Declararlo en la sección que corresponda (respetando el orden si importa).
#   2. Decidir el default: un campo NUEVO casi siempre necesita "default" literal, para que los
#      saves viejos (que no lo tienen) no arrastren el valor que haya en memoria.
#   3. Floats que puedan llegar a NaN: save_sf + load_sf.
#   4. Correr tools/sim/run_golden.ps1 (fallará save_build/save_load por el campo nuevo, como
#      corresponde) y re-grabar con -Mode record.
class_name SaveSchema

## Marca de dueño: el campo vive en el nodo de escena main (no en un autoload).
const MAIN := "main"

## Orden de aplicación al CARGAR. Es el orden histórico de apply_save_data (upgrades primero),
## distinto del orden de las secciones al guardar.
const LOAD_ORDER := ["upgrades", "economy", "dynamic_vars", "structural", "flags", "evolution",
	"homeostasis", "post_tras", "laps"]

static var _sections: Array = []
static var _validated := false


## Secciones en orden de guardado. Se construyen en el primer uso (no al arrancar el autoload):
## los autoloads se agregan al árbol de a uno y el esquema referencia a varios.
static func sections() -> Array:
	if _sections.is_empty():
		_sections = _define()
	return _sections


static func section(name: String) -> Dictionary:
	for s in sections():
		if s.name == name:
			return s
	return {}


# ═════════════════════════════════════════════════════════════════════════════
#  Definición
# ═════════════════════════════════════════════════════════════════════════════

static func _define() -> Array:
	return [
		{"name": "economy", "fields": [
			_f("money", EconomyManager, {"save_sf": 0.0}),
			_f("persistence_dynamic", StructuralModel, {"save_sf": 1.4}),
			_f("persistence_base", StructuralModel, {"save_sf": 1.4, "load_sf": [1.4, -INF]}),
			_f("persistence_upgrade_unlocked", StructuralModel),
			_f("memory_trigger_count", MAIN),
			_f("parasitism_corrosion", EconomyManager, {"save_sf": 1.0, "load_sf": [1.0, -INF]}),
		]},
		{"name": "dynamic_vars", "fields": [
			_f("trueque_base_income", EconomyManager, {"save_sf": 8.0, "load_sf": [8.0, -INF]}),
			_f("trueque_efficiency", EconomyManager, {"save_sf": 0.75, "load_sf": [0.75, -INF]}),
			_f("mutation_auto_factor", EconomyManager, {"save_sf": 1.0, "load_sf": [1.0, -INF]}),
			_f("mutation_trueque_factor", EconomyManager, {"save_sf": 1.0, "load_sf": [1.0, -INF]}),
			_f("mutation_accounting_bonus", EconomyManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
		]},
		{"name": "upgrades",
			"save": func(_main: Node) -> Variant: return UpgradeManager.serialize(),
			"load": func(_main: Node, value: Variant) -> void: UpgradeManager.deserialize(value)},
		{"name": "structural", "fields": [
			_f("epsilon_runtime", StructuralModel, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("epsilon_peak", StructuralModel, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("total_money_generated", EconomyManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("run_time", RunManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("baseline_delta_structural", StructuralModel, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("omega", StructuralModel, {"save_sf": 1.0, "load_sf": [1.0, -INF]}),
			_f("omega_min", StructuralModel, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			# Empuje manual de Control de Ω acumulado en la run (antes se perdía al recargar).
			_f("control_omega_offset", StructuralModel, {"default": 0.0, "save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("institution_accounting_unlocked", StructuralModel),
			_f("institutions_unlocked", MAIN),
		]},
		{"name": "flags", "fields": [
			_f("unlocked_d", StructuralModel),
			_f("unlocked_md", StructuralModel),
			_f("unlocked_e", StructuralModel),
			_f("unlocked_me", StructuralModel),
			# Los logros viven en legacy_bank.json (AchievementManager), no acá.
			_f("run_closed", RunManager),
			_f("final_route", RunManager),
			_f("final_reason", RunManager),
		]},
		{"name": "evolution", "fields": [
			_f("genome", EvoManager),
			_f("mutation_homeostasis", EvoManager),
			_f("mutation_hyperassimilation", EvoManager),
			# Fusión Catabólica
			_f("mutation_fusion_catabolica", EvoManager, {"default": false}),
			_f("fusion_burst_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("fusion_burst_cooldown", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("fusion_burst_count", EvoManager, {"default": 0, "load_int": true}),
			_f("fusion_burst_money", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			# Involución: agenda del botón de reversión y mutaciones revertidas esta run
			_f("transmut_base_time", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("transmut_money_mark", EvoManager, {"save_sf": -1.0, "default": -1.0, "load_sf": [-1.0, -1.0]}),
			_f("transmut_reverted", EvoManager, {"default": {}}),
			# Caos Orquestado (transmutación de Homeostasis) + legado Batuta
			_f("mutation_caos_orquestado", EvoManager, {"default": false}),
			_f("caos_money_mark", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("caos_red_time", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("caos_charge", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("caos_burst_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("caos_burst_saved_mult", EvoManager, {"save_sf": 1.0, "default": 1.0, "load_sf": [1.0, 1.0]}),
			_f("caos_cooldown", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("caos_cd_level", EvoManager, {"default": 0, "load_int": true}),
			_f("caos_collapse_count", EvoManager, {"default": 0, "load_int": true}),
			_f("caos_charged_collapses", EvoManager, {"default": 0, "load_int": true}),
			_f("caos_peak_collapse_eps", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("caos_min_collapse_eps", EvoManager, {"save_sf": 99.0, "default": 99.0, "load_sf": [99.0, 0.0]}),
			_f("batuta_used", EvoManager, {"default": false}),
			# Coro Simbiótico (transmutación de Simbiosis) + ritmo (legado Eco del Coro)
			_f("mutation_coro_simbiotico", EvoManager, {"default": false}),
			_f("coro_stacks", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("coro_money_mark", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("coro_overload_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("coro_cooldown", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("coro_overload_count", EvoManager, {"default": 0, "load_int": true}),
			_f("coro_w_level", EvoManager, {"default": 0, "load_int": true}),
			_f("coro_rhythm_time", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("coro_peak_stacks", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("coro_fortissimo_streak", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			# Micelio Omnisciente (transmutación de Red Micelial)
			_f("mutation_micelio_omnisciente", EvoManager, {"default": false}),
			_f("micelio_pool", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("micelio_nodes", EvoManager, {"default": {}}),
			_f("micelio_drift_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("micelio_full_time", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("micelio_peak_network", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("micelio_disconnects", EvoManager, {"default": 0, "load_int": true}),
			_f("micelio_first_full", EvoManager, {"default": ""}),
			_f("micelio_manual_buys", EvoManager, {"default": 0, "load_int": true}),
			_f("fusion_cd_level", EvoManager, {"default": 0, "load_int": true}),
			# Ayuno Primordial
			_f("mutation_ayuno_primordial", EvoManager, {"default": false}),
			_f("ayuno_silencio", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("ayuno_silencio_peak", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("ayuno_silencio_total", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("ayuno_longest_streak", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			_f("ayuno_cycles", EvoManager, {"default": 0, "load_int": true}),
			_f("ayuno_burst_active", EvoManager, {"default": false}),
			_f("ayuno_burst_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, 0.0]}),
			# Se guarda el multiplicador EFECTIVO (1.0 si no hay ráfaga) y se carga en el campo privado.
			_f("ayuno_burst_saved_mult", EvoManager, {"prop": "_ayuno_burst_saved_mult",
				"save_get": func() -> Variant: return EvoManager.ayuno_burst_mult(),
				"save_sf": 0.0, "default": 1.0, "load_sf": [1.0, 1.0]}),
			_f("ayuno_ascesis_level", EvoManager, {"default": 0, "load_int": true}),
			# Tier 1 / Tier 2 / NG+
			_f("mutation_symbiosis", EvoManager),
			_f("mutation_red_micelial", EvoManager),
			_f("mutation_sporulation", EvoManager),
			_f("mutation_parasitism", EvoManager),
			_f("mutation_allostasis", EvoManager),
			_f("mutation_homeorhesis", EvoManager),
			_f("mutation_depredador", EvoManager),
			_f("mutation_met_oscuro", EvoManager),
			# Autofagia Necrótica
			_f("mutation_autolisis", EvoManager, {"default": false}),
			_f("autolisis_devour_count", EvoManager, {"default": 0}),
			_f("autolisis_devour_timer", EvoManager, {"default": 0.0, "save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("autofagia_speed_level", EvoManager, {"default": 0}),
			_f("autofagia_double_level", EvoManager, {"default": 0}),
			# Necrosis Controlada
			_f("mutation_necrosis", EvoManager, {"default": false}),
			_f("necrosis_omega", EvoManager, {"default": Balance.NECROSIS_OMEGA_START, "save_sf": Balance.NECROSIS_OMEGA_START, "load_sf": [Balance.NECROSIS_OMEGA_START, -INF]}),
			_f("necromasa", EvoManager, {"default": 0.0, "save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("necrosis_agent_count", EvoManager, {"default": 0, "load_int": true}),
			_f("necrosis_active_time", EvoManager, {"default": 0.0, "save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("necrosis_toxicidad", EvoManager, {"default": 0.0, "save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("necrosis_tox_maxed", EvoManager, {"default": false}),
			_f("necrosis_overdose", EvoManager, {"default": false}),
			_f("necrosis_catalyst_level", EvoManager, {"default": 0, "load_int": true}),
			# Protocolo Omega-Cero
			_f("mutation_omega_cero", EvoManager, {"default": false}),
			_f("omega_cero_phi", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, -INF]}),
			_f("omega_cero_devour_count", EvoManager, {"default": 0, "load_int": true}),
			_f("omega_cero_devour_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, -INF]}),
			_f("omega_cero_omega", EvoManager, {"save_sf": Balance.OMEGA_CERO_OMEGA_START,
				"default": Balance.OMEGA_CERO_OMEGA_START, "load_sf": [Balance.OMEGA_CERO_OMEGA_START, -INF]}),
			_f("omega_cero_kernel", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, -INF]}),
			# Remisión Metabólica
			_f("mutation_remision", EvoManager, {"default": false}),
			_f("remision_omega", EvoManager, {"save_sf": Balance.REMISION_OMEGA_START,
				"default": Balance.REMISION_OMEGA_START, "load_sf": [Balance.REMISION_OMEGA_START, -INF]}),
			_f("remision_theta", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, -INF]}),
			_f("remision_band_timer", EvoManager, {"save_sf": 0.0, "default": 0.0, "load_sf": [0.0, -INF]}),
			_f("remision_sealable", EvoManager, {"default": false}),
			_f("remision_locked_run", EvoManager, {"default": false}),
			# Depredador / Metabolismo Oscuro
			_f("depredador_timer", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("depredador_inestabilidad", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("depredador_timer_buys", EvoManager, {"load_int": true}),
			_f("met_oscuro_timer", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("met_oscuro_devoured_count", EvoManager),
			# Red Micelial / ciclo biológico
			_f("red_micelial_phase", EvoManager),
			_f("red_branch_selected", EvoManager),
			_f("seta_formada", EvoManager),
			_f("primordio_active", EvoManager),
			_f("primordio_timer", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("primordio_abort_count", EvoManager),
			_f("primordio_integrity", EvoManager, {"default": Balance.PRIMORDIO_INTEGRITY_MAX,
				"save_sf": Balance.PRIMORDIO_INTEGRITY_MAX, "load_sf": [Balance.PRIMORDIO_INTEGRITY_MAX, -INF]}),
			_f("primordio_pert_timer", EvoManager, {"default": 0.0, "save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("nucleo_conciencia", EvoManager, {"default": false}),
			_f("colonizacion_pert_timer", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("colonizacion_phase_time", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("panspermia_charge", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("panspermia_heat", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("panspermia_misfires", EvoManager),
			_f("nucleo_sync", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("nucleo_temp", EvoManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			# Biosfera (vive en "evolution" por compatibilidad de formato)
			_f("biomasa", BiosphereEngine, {"save_sf": 0.0, "load_sf": [0.0, 0.0]}),
			_f("nutrientes", BiosphereEngine, {"save_sf": 0.0, "load_sf": [0.0, 0.0]}),
			_f("hifas", BiosphereEngine, {"save_sf": 0.0, "load_sf": [0.0, 0.0]}),
			_f("micelio", BiosphereEngine, {"save_sf": 0.0, "load_sf": [0.0, 0.0]}),
		]},
		{"name": "homeostasis", "fields": [
			_f("homeostasis_mode", RunManager),
			_f("post_homeostasis", RunManager),
			_f("resilience_score", RunManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("homeostasis_timer", RunManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
			_f("legacy_homeostasis", RunManager),
			_f("disturbances_survived", RunManager),
			_f("is_recovering_from_extreme", RunManager),
			_f("extreme_shocks_recovered", RunManager),
			_f("homeostasis_tier_reached", RunManager),
			_f("omega_min_peak", RunManager, {"save_sf": 0.0, "load_sf": [0.0, -INF]}),
		]},
		{"name": "post_tras",
			"save": func(_main: Node) -> Variant: return RouteManager.serialize(),
			"load": func(_main: Node, value: Variant) -> void: RouteManager.deserialize(value)},
		{"name": "laps",
			"save": func(_main: Node) -> Variant: return _laps_to_save(),
			"load": func(_main: Node, value: Variant) -> void: LogManager.load_laps(value)},
	]


static func _f(key: String, owner: Variant, opts: Dictionary = {}) -> Dictionary:
	var field := {"key": key, "owner": owner, "prop": key}
	field.merge(opts, true)
	return field


static func _laps_to_save() -> Array:
	var all_laps := LogManager.get_lap_array()
	return all_laps.slice(maxi(0, all_laps.size() - Balance.MAX_LAPS))


# ═════════════════════════════════════════════════════════════════════════════
#  Build / apply
# ═════════════════════════════════════════════════════════════════════════════

static func build_section(sec: Dictionary, main: Node) -> Variant:
	if sec.has("save"):
		return (sec.save as Callable).call(main)
	var out := {}
	for f in sec.fields:
		var value: Variant
		if f.has("save_get"):
			value = (f.save_get as Callable).call()
		else:
			value = _owner(f, main).get(f.prop)
		if f.has("save_sf"):
			value = SaveManager._sf(value, f.save_sf)
		out[f.key] = value
	return out


static func apply_section(sec: Dictionary, main: Node, raw: Variant) -> void:
	if sec.has("load"):
		(sec.load as Callable).call(main, raw)
		return
	for f in sec.fields:
		var target := _owner(f, main)
		var fallback: Variant = f.default if f.has("default") else target.get(f.prop)
		var value: Variant = raw.get(f.key, fallback)
		if f.has("load_sf"):
			value = SaveManager._sf(value, f.load_sf[0], f.load_sf[1])
		elif f.get("load_int", false):
			value = int(value)
		# Las secciones están cacheadas: un default Dictionary/Array sería el MISMO objeto en cada
		# carga y mutarlo en juego contaminaría el default. Copia siempre.
		if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
			value = value.duplicate(true)
		target.set(f.prop, value)


static func _owner(f: Dictionary, main: Node) -> Object:
	return main if typeof(f.owner) == TYPE_STRING and f.owner == MAIN else f.owner


# ═════════════════════════════════════════════════════════════════════════════
#  Validación
# ═════════════════════════════════════════════════════════════════════════════

## Errores del esquema: propiedades inexistentes (que get()/set() ignorarían en silencio) y
## claves duplicadas dentro de una sección. Los campos de MAIN sólo se validan si se pasa main.
static func validate(main: Object = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var saved_props := {}  # owner → { prop: true }
	for sec in sections():
		if sec.has("save") != sec.has("load"):
			errors.append("sección '%s': 'save' y 'load' deben definirse juntos" % sec.name)
		if not sec.has("fields"):
			continue
		var seen := {}
		for f in sec.fields:
			if seen.has(f.key):
				errors.append("sección '%s': clave duplicada '%s'" % [sec.name, f.key])
			seen[f.key] = true
			var is_main: bool = typeof(f.owner) == TYPE_STRING and f.owner == MAIN
			if is_main and main == null:
				continue
			var target: Object = main if is_main else f.owner
			if not _has_property(target, f.prop):
				errors.append("sección '%s': '%s' no existe en %s" % [sec.name, f.prop, MAIN if is_main else str(target.name)])
			if not is_main:
				var props: Dictionary = saved_props.get(target, {})
				props[f.prop] = true
				saved_props[target] = props
	# Owners que declaran TRANSIENT_VARS: cada variable de script debe persistir o estar
	# declarada transitoria (evita "agregué un campo de ruta y no se guarda").
	for owner in saved_props:
		var consts: Dictionary = owner.get_script().get_script_constant_map()
		if not consts.has("TRANSIENT_VARS"):
			continue
		var transient: Array = consts.TRANSIENT_VARS
		for p in owner.get_property_list():
			if not (int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) or str(p.name).begins_with("_reset"):
				continue
			var n := str(p.name)
			var saved: bool = saved_props[owner].has(n)
			if not saved and not (n in transient):
				errors.append("%s.%s no está en SaveSchema ni en TRANSIENT_VARS" % [owner.name, n])
			elif saved and n in transient:
				errors.append("%s.%s está en SaveSchema y en TRANSIENT_VARS" % [owner.name, n])
	return errors


## En builds de debug valida una vez por sesión y reporta con push_error.
static func ensure_valid(main: Object) -> void:
	if _validated or not OS.is_debug_build():
		return
	_validated = true
	for e in validate(main):
		push_error("[SaveSchema] " + e)


static func _has_property(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop:
			return true
	return false
