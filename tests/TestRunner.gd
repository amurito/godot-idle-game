extends Node

# =====================================================
# TestRunner.gd — v0.9.8
# Ejecuta todos los tests básicos del proyecto.
#
# Cómo usar:
#   1. Project → Run a Specific Scene → tests/TestRunner.tscn
#   2. O fijar TestRunner.tscn como escena principal temporalmente.
#
# Salida solo por consola. Sin UI, sin dependencia de la escena principal.
# Código de salida: 0 = todos pasaron, 1 = alguno falló.
# =====================================================

# ---------------------------------------------------
# PROPIEDADES MOCK — necesarias para SaveManager tests
# SaveManager.build_save_data(main) y apply_save_data(main, data)
# esperan estas propiedades en el objeto "main"
# ---------------------------------------------------
var memory_trigger_count: int = 0
var run_time: float = 0.0
var institutions_unlocked: bool = false

func update_ui() -> void:
	pass  # Stub: apply_save_data llama main.update_ui() al final

# ---------------------------------------------------
# FRAMEWORK MÍNIMO
# ---------------------------------------------------
var _total_passed := 0
var _total_failed := 0
var _suite := ""
var _s_pass := 0
var _s_fail := 0

func _begin(name: String) -> void:
	_suite = name
	_s_pass = 0
	_s_fail = 0
	print("\n── %s ──" % name)

func _end() -> void:
	var ok := _s_fail == 0
	print("   %s  [%d✅  %d❌]" % ["PASS" if ok else "FAIL", _s_pass, _s_fail])
	_total_passed += _s_pass
	_total_failed += _s_fail

func chk(desc: String, cond: bool) -> void:
	if cond:
		_s_pass += 1
	else:
		_s_fail += 1
		print("   ❌ FAIL: %s" % desc)

func eq(a: float, b: float, tol: float = 0.0001) -> bool:
	return abs(a - b) <= tol

# =====================================================
# RUNNER PRINCIPAL
# =====================================================

func _ready() -> void:
	print("\n════════════════════════════════════════════")
	print("     IDLE Fungi — Test Suite  (v0.9.8)")
	print("════════════════════════════════════════════")

	_run_eco_model()
	_run_biosphere()
	_run_legacy_manager()
	_run_save_load()

	print("\n════════════════════════════════════════════")
	var label := "✅ TODOS PASARON" if _total_failed == 0 else "❌  %d FALLARON" % _total_failed
	print("  TOTAL: %d pasados,  %d fallados  —  %s" % [_total_passed, _total_failed, label])
	print("════════════════════════════════════════════\n")

	get_tree().quit(1 if _total_failed > 0 else 0)

# =====================================================
# SUITE 1 — EcoModel  (matemática pura, sin estado)
# =====================================================

func _run_eco_model() -> void:
	_begin("EcoModel")

	# Potencia de click: base × mult × p × mu
	chk("click_power: 2×3×1.5×2 = 18",
		eq(EcoModel.get_click_power(2.0, 3.0, 1.5, 2.0), 18.0))

	# Ingreso automático con contabilidad = 2 → ×(1+2×0.05) = ×1.1
	chk("auto_income contabilidad=2:  100×1.1 = 110",
		eq(EcoModel.get_auto_income_effective(100.0, 1.0, 1.0, 1.0, 1.0, 2), 110.0))

	# Trueque raw: level × base × eficiencia
	chk("trueque_raw: 3×50×0.8 = 120",
		eq(EcoModel.get_trueque_raw(3, 50.0, 0.8), 120.0))

	# persistence_target con n=1 devuelve base_p directamente
	chk("persistence_target n=1 = base_p",
		eq(EcoModel.get_persistence_target(500.0, 1.5, 1), 500.0))

	# persistence_target con n=2: base × k^(1−1/2) = 500 × √1.5
	var expected_p2 := 500.0 * pow(1.5, 0.5)
	chk("persistence_target n=2: base × k^0.5",
		eq(EcoModel.get_persistence_target(500.0, 1.5, 2), expected_p2))

	# Omega: 1 / (1 + eps × k_mu × n^0.85)
	var expected_omega := 1.0 / (1.0 + 0.5 * 2.0 * pow(4.0, 0.85))
	chk("omega formula: 1/(1+eps×k×n^0.85)",
		eq(EcoModel.get_omega(0.5, 2.0, 4.0), expected_omega))

	# Con epsilon = 0, omega siempre 1.0
	chk("omega = 1.0 cuando epsilon = 0",
		eq(EcoModel.get_omega(0.0, 2.0, 10.0), 1.0))

	# structural_pressure = eps_eff × (1+eps_peak) × n × (1−acct)
	var expected_press := 0.5 * (1.0 + 0.3) * 4.0 * (1.0 - 0.1)
	chk("structural_pressure formula",
		eq(EcoModel.get_structural_pressure(0.5, 0.3, 4, 0.1), expected_press))

	# k_eff: base_k × (1 + alpha × (mu−1))
	var expected_keff := 1.1 * (1.0 + 0.2 * (1.5 - 1.0))
	chk("k_eff formula",
		eq(EcoModel.get_k_eff(1.1, 0.2, 1.5), expected_keff))

	_end()

# =====================================================
# SUITE 2 — BiosphereEngine  (requiere autoloads)
# =====================================================

func _run_biosphere() -> void:
	_begin("BiosphereEngine")

	# Snapshot de LegacyManager para aislar el entorno de tests
	var saved_buffs := LegacyManager.buffs.duplicate(true)
	var saved_cosmic := LegacyManager.cosmic_unlocked.duplicate(true)
	LegacyManager.buffs = {}
	LegacyManager.cosmic_unlocked = {}

	# reset() sin legado → biomasa = 0
	BiosphereEngine.reset()
	chk("reset: biomasa = 0.0 (sin legado)", eq(BiosphereEngine.biomasa, 0.0))
	chk("reset: nutrientes = 0.0",           eq(BiosphereEngine.nutrientes, 0.0))
	chk("reset: hifas = 0.0",               eq(BiosphereEngine.hifas, 0.0))

	# beta = 1.0 con biomasa = 0
	BiosphereEngine.biomasa = 0.0
	chk("beta = 1.0 con biomasa = 0",
		eq(BiosphereEngine.get_biomass_beta(), 1.0))

	# beta > 1.0 con biomasa positiva  (log(1+bio)×efficiency > 0)
	BiosphereEngine.biomasa = 5.0
	chk("beta > 1.0 con biomasa = 5",
		BiosphereEngine.get_biomass_beta() > 1.0)

	# Absorción normal:  eps_eff = eps / (1 + bio × 0.5)
	BiosphereEngine.biomasa = 4.0
	BiosphereEngine.hifas = 5.0
	BiosphereEngine._compute_epsilon_breakdown(0.0, 0.5, false, false, false)
	var expected_normal := 0.5 / (1.0 + 4.0 * 0.5)   # ≈ 0.1667
	chk("absorción normal: eps_eff = eps/(1+bio×0.5)",
		eq(BiosphereEngine.epsilon_effective, expected_normal))

	# Hiperasimilación:  eps_eff = eps × (1 + bio × 0.25)
	BiosphereEngine.biomasa = 2.0
	BiosphereEngine.hifas = 5.0
	BiosphereEngine._compute_epsilon_breakdown(0.0, 0.5, true, false, false)
	var expected_hyper := 0.5 * (1.0 + 2.0 * 0.25)   # = 0.75
	chk("hiperasimilación: eps_eff = eps×(1+bio×0.25)",
		eq(BiosphereEngine.epsilon_effective, expected_hyper))

	# Simbiosis:  eps_eff = eps × 0.25
	BiosphereEngine.biomasa = 3.0
	BiosphereEngine.hifas = 5.0
	BiosphereEngine._compute_epsilon_breakdown(0.0, 0.8, false, false, true)
	chk("simbiosis: eps_eff = eps × 0.25",
		eq(BiosphereEngine.epsilon_effective, 0.8 * 0.25))

	# Sin hifas:  eps_eff = eps_runtime (no hay absorción)
	BiosphereEngine.hifas = 0.0
	BiosphereEngine._compute_epsilon_breakdown(0.0, 0.6, false, false, false)
	chk("sin hifas: eps_eff = eps_runtime",
		eq(BiosphereEngine.epsilon_effective, 0.6))

	# trigger_sporulation reduce biomasa al 10%
	var saved_seta := EvoManager.seta_formada
	EvoManager.seta_formada = false
	BiosphereEngine.biomasa = 10.0
	BiosphereEngine.hifas = 0.0
	var spores := BiosphereEngine.trigger_sporulation()
	chk("sporulation: biomasa → 10% original (= 1.0)",
		eq(BiosphereEngine.biomasa, 1.0))
	chk("sporulation: spores = bio × 0.8 (= 8.0)",
		eq(spores, 8.0))
	EvoManager.seta_formada = saved_seta

	# Restaurar LegacyManager
	LegacyManager.buffs = saved_buffs
	LegacyManager.cosmic_unlocked = saved_cosmic

	_end()

# =====================================================
# SUITE 3 — LegacyManager  (banco genético)
# =====================================================

func _run_legacy_manager() -> void:
	_begin("LegacyManager")

	# Snapshot para restaurar estado real del jugador al final
	var snap_buffs := LegacyManager.buffs.duplicate(true)
	var snap_endings := LegacyManager.endings_achieved.duplicate(true)
	var snap_pl := LegacyManager.legacy_points

	# get_effect_value con buffs vacíos → 0.0
	LegacyManager.buffs = {}
	chk("get_effect_value vacío = 0.0",
		eq(LegacyManager.get_effect_value("start_biomasa"), 0.0))

	# is_revealed — tipo "always" siempre visible
	chk("is_revealed: tipo always = true ('deflacion')",
		LegacyManager.is_revealed("deflacion"))
	chk("is_revealed: tipo always = true ('impulso_manual')",
		LegacyManager.is_revealed("impulso_manual"))

	# is_revealed — route_gated sin ruta → false
	LegacyManager.endings_achieved = {}
	chk("is_revealed: route_gated sin ruta = false",
		not LegacyManager.is_revealed("presion_rentable"))

	# is_revealed — route_gated con ruta → true
	LegacyManager.endings_achieved = {"HIPERASIMILACION": true}
	chk("is_revealed: route_gated con ruta = true",
		LegacyManager.is_revealed("presion_rentable"))

	# is_revealed — route_closed_all: requiere AMBAS rutas
	LegacyManager.endings_achieved = {"SIMBIOSIS": true}
	chk("is_revealed: route_closed_all con 1 de 2 = false",
		not LegacyManager.is_revealed("simbiosis_agresiva"))
	LegacyManager.endings_achieved = {"SIMBIOSIS": true, "PARASITISMO": true}
	chk("is_revealed: route_closed_all con ambas = true",
		LegacyManager.is_revealed("simbiosis_agresiva"))

	# is_revealed — route_closed_any: basta con una ruta
	LegacyManager.endings_achieved = {"ESPORULACION": true}
	chk("is_revealed: route_closed_any con una ruta = true",
		LegacyManager.is_revealed("deriva_esporada"))

	# get_effect_value con buff aplicado directamente
	LegacyManager.buffs = {}
	LegacyManager._set_buff_level("hifas_persistentes", 1)
	chk("get_effect_value con hifas_persistentes (lvl1) = 0.5",
		eq(LegacyManager.get_effect_value("start_biomasa"), 0.5))

	# Acumulación: dos buffs del mismo effect_type se suman
	LegacyManager._set_buff_level("eco_panspermico", 1)
	chk("get_effect_value acumula hifas + eco = 1.5",
		eq(LegacyManager.get_effect_value("start_biomasa"), 1.5))

	# get_buff_level y get_buff_value básico
	LegacyManager.buffs = {}
	LegacyManager._set_buff_level("deflacion", 1)
	chk("get_buff_level = 1",  LegacyManager.get_buff_level("deflacion") == 1)
	chk("get_buff_value = true", LegacyManager.get_buff_value("deflacion"))
	chk("get_buff_level buff no comprado = 0",
		LegacyManager.get_buff_level("horizonte_estructural") == 0)

	# Buff desconocido no crashea
	chk("buff desconocido: is_revealed = false",
		not LegacyManager.is_revealed("BUFF_QUE_NO_EXISTE"))
	chk("buff desconocido: get_buff_level = 0",
		LegacyManager.get_buff_level("BUFF_QUE_NO_EXISTE") == 0)

	# Restaurar estado real del jugador
	LegacyManager.buffs = snap_buffs
	LegacyManager.endings_achieved = snap_endings
	LegacyManager.legacy_points = snap_pl

	_end()

# =====================================================
# SUITE 4 — SaveManager  (arranque frío y estructura)
# =====================================================

func _run_save_load() -> void:
	_begin("SaveManager")

	# apply_save_data con dict vacío no crashea (todos los bloques tienen .has() guard)
	SaveManager.apply_save_data(self, {})
	chk("apply_save_data con {} no crashea", true)

	# apply_save_data respeta economy.money cuando está presente
	var snap_money := EconomyManager.money
	SaveManager.apply_save_data(self, {"economy": {"money": 777.0}})
	chk("apply_save_data restaura economy.money = 777",
		eq(EconomyManager.money, 777.0))
	EconomyManager.money = snap_money  # restaurar

	# build_save_data devuelve Dictionary con todas las claves esperadas
	var snap := SaveManager.build_save_data(self)
	chk("build_save_data retorna Dictionary", snap is Dictionary)
	chk("clave 'economy' existe",    snap.has("economy"))
	chk("clave 'flags' existe",      snap.has("flags"))
	chk("clave 'evolution' existe",  snap.has("evolution"))
	chk("clave 'homeostasis' existe",snap.has("homeostasis"))
	chk("clave 'upgrades' existe",   snap.has("upgrades"))
	chk("clave 'laps' existe",       snap.has("laps"))

	# Subestructura de evolution tiene campos clave
	var ev = snap.get("evolution", {})
	chk("evolution.genome existe",           ev.has("genome"))
	chk("evolution.biomasa existe",          ev.has("biomasa"))
	chk("evolution.mutation_homeostasis existe", ev.has("mutation_homeostasis"))

	# load_game sin archivo no crashea (guard en SaveManager)
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		SaveManager.load_game(self)
		chk("load_game sin archivo: termina sin error", true)
	else:
		chk("load_game sin archivo (skip — save existente en disco)", true)

	_end()
