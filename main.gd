extends Control

# =====================================================
#  IDLE — v0.6.3 — “ε : Structural Stability Model”
#  Esta versión introduce:
# persistencia dinámica observacional
# lectura estructural fⁿ
# convergencia suave vía sigmoide α
# preliminar de ε (aún no formalizada)
# =====================================================

# =============== ECONOMÍA BASE =======================

var money: float = 0.0


# --- CLICK (a · b · c) ---
var click_value: float = 1.0
var click_upgrade_cost: float = 5.0

var click_multiplier: float = 1.0
var click_multiplier_upgrade_cost: float = 200.0

# Persistencia base estructural (c₀)
var persistence_base: float = 1.4
# Estado dinámico observado (cₙ)
var persistence_dynamic: float = 1.4


# --- PRODUCTOR d ---
var income_per_second: float = 0.0
var auto_upgrade_cost: float = 10.0


# --- MODIFICADOR md ---
var auto_multiplier: float = 1.0
var auto_multiplier_upgrade_cost: float = 1200.0
const AUTO_MULTIPLIER_SCALE := 1.20
const AUTO_MULTIPLIER_GAIN := 1.06


# --- ESPECIALIZACIÓN DE OFICIO (buff estructural d) v0.6.1---
var manual_specialization: float = 1.0
var specialization_cost := 9000.0
const SPECIALIZATION_GAIN := 1.10
const SPECIALIZATION_SCALE := 1.35
var specialization_level: int = 0


# --- PRODUCTOR e ---
var trueque_level: int = 0
var trueque_base_income: float = 8.0
var trueque_cost: float = 3000.0
const TRUEQUE_COST_SCALE := 1.45
var trueque_efficiency: float = 0.75


# --- MODIFICADOR me ---
var trueque_network_multiplier: float = 1.0
var trueque_network_upgrade_cost: float = 6000.0
const TRUEQUE_NETWORK_GAIN := 1.12
const TRUEQUE_NETWORK_SCALE := 1.35


# --- PERSISTENCIA estructural — fⁿ (observacional) ---
var structural_upgrades: int = 1
const K_PERSISTENCE := 1.25


# =============== SESIÓN / LAB MODE ===================

var run_time: float = 0.0
var lab_mode := true

var lap_events: Array = []
var last_dominance := ""

const RUN_EXPORT_PATH := "C:/Users/nicol/Desktop/idle/runs"



# ========== DESBLOQUEO PROGRESIVO DE FÓRMULA =========

var unlocked_d := false
var unlocked_md := false
var unlocked_e := false
var unlocked_me := false

const CLICK_RATE := 1.0   # clicks / s estimado humano

# === VERSION INFO ===
const VERSION := "0.6.3"
const CODENAME := "v0.6.3 — “ε : Structural Stability Model”"
const BUILD_CHANNEL := "stable"


# ================= REFERENCIAS UI ===================

@onready var money_label = $UIRootContainer/RightPanel/MoneyLabel
@onready var income_label = $UIRootContainer/RightPanel/IncomeLabel
@onready var stats_label = $UIRootContainer/RightPanel/StatsLabel
@onready var export_run_button = $UIRootContainer/RightPanel/ExportRunButton

@onready var big_click_button = $UIRootContainer/LeftPanel/CenterPanel/BigClickButton
@onready var formula_label   = $UIRootContainer/LeftPanel/CenterPanel/FormulaLabel
@onready var click_stats_label = $UIRootContainer/LeftPanel/CenterPanel/ClickStatsLabel
@onready var marginal_label = $UIRootContainer/LeftPanel/CenterPanel/MarginalLabel

@onready var upgrade_click_button = $UIRootContainer/ProductionPanel/ClickPanel/UpgradeClickButton
@onready var upgrade_click_multiplier_button = $UIRootContainer/ProductionPanel/ClickPanel/UpgradeClickMultiplierButton
@onready var persistence_upgrade_button = $UIRootContainer/ProductionPanel/ClickPanel/PersistenceUpgradeButton

@onready var upgrade_auto_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeAutoButton
@onready var upgrade_auto_multiplier_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeAutoMultiplierButton
@onready var specialization_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeSpecializationButton

@onready var upgrade_trueque_button = $UIRootContainer/ProductionPanel/TruequePanel/UpgradeTruequeButton
@onready var upgrade_trueque_network_button = $UIRootContainer/ProductionPanel/TruequePanel/UpgradeTruequeNetworkButton



# =====================================================
#  CAPA 1 — MODELO ECONÓMICO
# =====================================================

func get_click_power() -> float:
	return click_value * click_multiplier * persistence_dynamic

func get_auto_income_effective() -> float:
	return income_per_second * auto_multiplier * manual_specialization

func get_trueque_raw() -> float:
	return trueque_level * trueque_base_income * trueque_efficiency

func get_trueque_income_effective() -> float:
	return get_trueque_raw() * trueque_network_multiplier

func get_passive_total() -> float:
	return get_auto_income_effective() + get_trueque_income_effective()

func get_delta_total() -> float:
	return get_click_power() + get_passive_total()



# =====================================================
#  CAPA 2 — ANÁLISIS MATEMÁTICO
# =====================================================

func get_dominant_term() -> String:
	var p := get_click_power()
	var d := get_auto_income_effective()
	var e := get_trueque_income_effective()
	var m: float = float(max(max(p, d), e))

	if m == p: return "CLICK domina el sistema"
	if m == d: return "Trabajo Manual domina el sistema"
	return "Trueque domina el sistema"


func get_contribution_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var d := get_auto_income_effective()
	var e := get_trueque_income_effective()

	var total := push + d + e
	if total == 0: total = 0.00001

	return {
		"click": push / total * 100.0,
		"d": d / total * 100.0,
		"e": e / total * 100.0,
		"total": total
	}


func get_active_passive_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var passive := get_auto_income_effective() + get_trueque_income_effective()

	var total := push + passive
	if total == 0: total = 0.00001

	return {
		"activo": push / total * 100.0,
		"pasivo": passive / total * 100.0,
		"push_abs": push,
		"passive_abs": passive,
		"total": total
	}



# =====================================================
#  CAPA 3 — fⁿ (OBSERVACIONAL) v0.6.2
# =====================================================




func get_n_log() -> float:
	return 1.0 + log(1.0 + structural_upgrades)

func get_n_power() -> float:
	return pow(structural_upgrades + 1.0, 0.35)


# =====================================================
#  FUNCIÓN SIGMOIDE fⁿ α V0.6.2
# =====================================================
func f_n_alpha(n: float) -> float:
	return 1.0 / (1.0 + exp(-0.35 * (n - 6.0)))

func apply_dynamic_persistence(delta: float) -> void:
	var n := float(structural_upgrades)

	# valor teórico esperado
	var target := get_persistence_target()

	# peso sigmoide — transición suave
	var a := f_n_alpha(n)

	# converge sin overshoot
	persistence_dynamic = lerp(
		persistence_dynamic,
		target,
		clamp(a * delta * 0.4, 0.0, 0.25)
	)


# === Persistencia estructural ===
# c₀  → baseline fijo
# fⁿ  → objetivo teórico según n
# cₙ  → estado dinámico observado

func get_persistence_target() -> float:
	if structural_upgrades <= 1:
		return persistence_base

	var n := float(structural_upgrades)
	return persistence_base * pow(K_PERSISTENCE, (1.0 - 1.0 / n))


# ε = | fⁿ − cₙ |
func get_structural_epsilon() -> float:
	return abs(get_persistence_target() - persistence_dynamic)

func get_structural_state() -> String:
	var e := get_structural_epsilon()

	if e < 0.02:
		return "🟢 Sistema estable — transmisión eficiente"
	elif e < 0.08:
		return "🟡 Zona de transición — reconfiguración estructural"
	else:
		return "🔴 Zona crítica — fricción sistémica"

# =====================================================
#  LAP MARKERS
# =====================================================

func add_lap(event: String) -> void:
	lap_events.append({
		"time": format_time(run_time),
		"event": event,
		"click": snapped(get_click_power(), 0.01),
		"activo_ps": snapped(get_click_power() * CLICK_RATE, 0.01),
		"pasivo_ps": snapped(get_passive_total(), 0.01),
		"dominante": get_dominant_term()
	})


func check_dominance_transition():
	var d := get_dominant_term()
	if d != last_dominance:
		add_lap("Transición de dominio → " + d)
		last_dominance = d

func get_run_filename() -> String:
	var t = Time.get_datetime_dict_from_system()

	return "run_%02d-%02d-%02d_%02d-%02d" % [
		t.day,
		t.month,
		t.year % 100,
		t.hour,
		t.minute
	]

func build_run_snapshot() -> Dictionary:

	var ap := get_active_passive_breakdown()
	var c := get_contribution_breakdown()

	return {
		"version": Version.get_version_string(),
		"session_time": format_time(run_time),

		"economy": {
			"a": click_value,
		"b": click_multiplier,
		"c_n": persistence_dynamic,

		"n_structural": structural_upgrades,
		"f_n": get_persistence_target(),

		"n_log": get_n_log(),
		"n_power": get_n_power(),

		"auto_income": get_auto_income_effective(),
		"trueque_income": get_trueque_income_effective()
		},

		"distribution": {
			"click_%": c.click,
			"manual_%": c.d,
			"trueque_%": c.e,
			"activo_%": ap.activo,
			"pasivo_%": ap.pasivo
		},

		"deltas": {
			"activo_ps": ap.push_abs,
			"pasivo_ps": ap.passive_abs,
			"total_ps": c.total
		},

		"formula_text": build_formula_text(),
		"formula_eval": build_formula_values(),

		"laps": lap_events,
		"build": { "version": VERSION,  "codename": CODENAME,  "channel": BUILD_CHANNEL},
	}
func get_build_string() -> String:
	return "v%s — %s (%s)" % [VERSION, CODENAME, BUILD_CHANNEL]


func ensure_export_dir() -> void:
	DirAccess.make_dir_recursive_absolute(RUN_EXPORT_PATH)


func export_run_json(snapshot: Dictionary, filename: String) -> void:
	ensure_export_dir()

	var path := "%s/%s.json" % [RUN_EXPORT_PATH, filename]
	var f = FileAccess.open(path, FileAccess.WRITE)

	f.store_string(JSON.stringify(snapshot, "\t"))
	f.close()

	print("Run exportada → ", path)


func export_run_csv(snapshot: Dictionary, filename: String) -> void:
	ensure_export_dir()

	var path := "%s/%s.csv" % [RUN_EXPORT_PATH, filename]
	var f = FileAccess.open(path, FileAccess.WRITE)

	f.store_line("time,event,activo_ps,pasivo_ps,total_ps,dominante")

	for lap in snapshot.laps:
		f.store_line(
			"%s,%s,%s,%s,%s,%s" % [
				lap.time,
				lap.event,
				lap.activo_ps,
				lap.pasivo_ps,
				lap.activo_ps + lap.pasivo_ps,
				lap.dominante
			]
		)

	f.close()

	print("CSV generado → ", path)


func _on_ExportRunButton_pressed():

	var filename := get_run_filename()
	var snapshot := build_run_snapshot()

	export_run_json(snapshot, filename)
	export_run_csv(snapshot, filename)

	add_lap("RUN EXPORTADA")

	stats_label.text += "\n\n✔ Run exportada → runs/%s" % filename


# =====================================================
#  FORMATO TEXTO FÓRMULA
# =====================================================

func build_formula_text() -> String:
	var t := "∫$ = clicks · (a · b · cₙ)"

	if unlocked_d:
		t += "  +  d · md"
		if specialization_level > 0:
			t += " · so"

	if unlocked_e:
		t += "  +  e · me"

	t += "\n  cₙ = c₀ · k^(1 − 1/n)"

	return t


func build_formula_values() -> String:
	var cn: float = snapped(persistence_dynamic, 0.01)
	var c0: float = snapped(persistence_base, 0.01)
	var fn: float = snapped(get_persistence_target(), 0.01)

	var t := "= clicks × (%s × %s × %s)" % [
		snapped(click_value, 0.01),
		snapped(click_multiplier, 0.01),
		cn
	]

	t += "\n  c₀ = %s   fⁿ(teórico) = %s   cₙ(actual) = %s" % [c0, fn, cn]	

	if unlocked_d:
		t += "\n  +  %s/s × %s × %s" % [
			snapped(income_per_second, 0.01),
			snapped(auto_multiplier, 0.01),
			snapped(manual_specialization, 0.01)
		]

	if unlocked_e:
		t += "\n  +  %s/s × %s" % [
			snapped(get_trueque_raw(), 0.01),
			snapped(trueque_network_multiplier, 0.01)
		]

	return t



func build_marginal_contribution() -> String:
	var t := "Aporte actual:\n"
	t += "• Click PUSH = +" + str(snapped(get_click_power(), 0.01)) + "\n"
	if unlocked_d: t += "• Trabajo Manual = +" + str(snapped(get_auto_income_effective(), 0.01)) + " /s\n"
	if unlocked_e: t += "• Trueque = +" + str(snapped(get_trueque_income_effective(), 0.01)) + " /s\n"

	t += "\nΔ$ total = +" + str(snapped(get_delta_total(), 0.01))
	t += "\n" + get_dominant_term()
	return t




# =====================================================
#  CICLO DE VIDA
# =====================================================

func _ready():
	stats_label.text = get_build_string() + "\n" + stats_label.text

	update_ui()

func _process(delta):
	apply_dynamic_persistence(delta)
	run_time += delta
	money += get_passive_total() * delta
	update_ui()



func format_time(t: float) -> String:
	var m = float(int(t)) / 60
	var s = int(t) % 60
	return "%02d:%02d" % [m, s]



# =====================================================
#  INPUT & UPGRADES
# =====================================================

func _on_BigClickButton_pressed():
	money += get_click_power()
	big_click_button.scale = Vector2(0.95, 0.95)
	await get_tree().create_timer(0.05).timeout
	big_click_button.scale = Vector2(1, 1)
	update_ui()



# CLICK
func _on_UpgradeClickButton_pressed():
	if money < click_upgrade_cost: return
	money -= click_upgrade_cost
	click_value += 1
	click_upgrade_cost *= 1.5
	update_ui()


func _on_UpgradeClickMultiplierButton_pressed():
	if money < click_multiplier_upgrade_cost: return
	money -= click_multiplier_upgrade_cost
	click_multiplier *= 1.06
	click_multiplier_upgrade_cost *= 1.4
	update_ui()


# PERSISTENCIA ÚNICA
var persistence_upgrade_unlocked := false
var persistence_upgrade_cost := 10000.0
const PERSISTENCE_NEW_VALUE := 1.6

func _on_PersistenceUpgradeButton_pressed():
	if persistence_upgrade_unlocked: return
	if money < persistence_upgrade_cost: return

	money -= persistence_upgrade_cost
	persistence_upgrade_unlocked = true
	structural_upgrades += 1

	# nuevo baseline
	persistence_base = PERSISTENCE_NEW_VALUE

	add_lap("Upgrade estructural → Persistencia (baseline elevado)")

	# 🔹 regla v0.6.3: nunca reducir cn
	if persistence_dynamic < persistence_base:
		persistence_dynamic = persistence_base

	update_ui()



# AUTO (d + md)
func _on_UpgradeAutoButton_pressed():
	if money < auto_upgrade_cost: return
	money -= auto_upgrade_cost
	income_per_second += 1
	auto_upgrade_cost *= 1.6
	unlocked_d = true
	structural_upgrades += 1
	add_lap("Desbloqueado d (Trabajo Manual)")
	update_ui()


func _on_UpgradeAutoMultiplierButton_pressed():
	if money < auto_multiplier_upgrade_cost: return
	money -= auto_multiplier_upgrade_cost
	auto_multiplier *= AUTO_MULTIPLIER_GAIN
	auto_multiplier_upgrade_cost *= AUTO_MULTIPLIER_SCALE
	unlocked_md = true
	structural_upgrades += 1
	add_lap("Desbloqueado md (Ritmo de Trabajo)")
	update_ui()
# NUEVO BOTÓN — ESPECIALIZACIÓN DE OFICIO
func _on_UpgradeSpecializationButton_pressed():
	if money < specialization_cost:
		return

	money -= specialization_cost
	specialization_level += 1
	manual_specialization *= SPECIALIZATION_GAIN
	specialization_cost *= SPECIALIZATION_SCALE
	structural_upgrades += 1

	add_lap("Especialización de Oficio → x%s" %
		str(snapped(manual_specialization, 0.01)))

	update_ui()

# TRUEQUE (e + me)
func _on_UpgradeTruequeButton_pressed():
	if money < trueque_cost: return
	money -= trueque_cost
	trueque_level += 1
	trueque_cost *= TRUEQUE_COST_SCALE
	unlocked_e = true
	add_lap("Desbloqueado e (Trueque)")
	update_ui()


func _on_UpgradeTruequeNetworkButton_pressed():
	if money < trueque_network_upgrade_cost: return
	money -= trueque_network_upgrade_cost
	trueque_network_multiplier *= TRUEQUE_NETWORK_GAIN
	trueque_network_upgrade_cost *= TRUEQUE_NETWORK_SCALE
	unlocked_me = true
	add_lap("Desbloqueado me (Red de Intercambio)")
	update_ui()



# =====================================================
#  UI — SOLO LEE RESULTADOS (v0.6.3 — HUD científico)
# =====================================================

func update_ui():
	check_dominance_transition()

	# ================= PRODUCCIÓN =====================
	var auto_eff := get_auto_income_effective()
	var trueque_eff := get_trueque_income_effective()
	var passive_total := auto_eff + trueque_eff

	money_label.text = "Dinero: $" + str(round(money))
	income_label.text = "Ingreso pasivo / s: $" + str(snapped(passive_total, 0.01))

	big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"

	formula_label.text = build_formula_text() + "\n" + build_formula_values()
	marginal_label.text = build_marginal_contribution()


	# ===============================
#   PANEL — HUD CIENTÍFICO v0.6.3
# ===============================

# Producción activa (siempre visible)
	click_stats_label.text = "=== Producción activa ===\n"
	click_stats_label.text += "a = %s    Click base\n" % snapped(click_value, 0.01)
	click_stats_label.text += "b = %s    Multiplicador\n" % snapped(click_multiplier, 0.01)
	click_stats_label.text += "cₙ = %s    Persistencia\n" % snapped(persistence_dynamic, 0.01)
	click_stats_label.text += "\n"

# ---------- PRODUCTOR d ----------

	if unlocked_d:
		click_stats_label.text += "d = %s/s    Trabajo Manual\n" % snapped(income_per_second, 0.01)
	else:
		click_stats_label.text += "d = — (no descubierto)\n"

# md
	if unlocked_md:
		click_stats_label.text += "md = %s    Ritmo de Trabajo\n" % snapped(auto_multiplier, 0.01)
	elif unlocked_d:
		click_stats_label.text += "md = — (estructura latente)\n"

# so (buff estructural)
	if specialization_level > 0:
		click_stats_label.text += "so = %s    Especialización de Oficio\n" % snapped(manual_specialization, 0.01)

	click_stats_label.text += "\n"

# e / me
	if unlocked_e:
		click_stats_label.text += "e = %s/s    Trueque corregido\n" % snapped(get_trueque_raw(), 0.01)
	else:
		click_stats_label.text += "e = — (no descubierto)\n"

	if unlocked_me:
		click_stats_label.text += "me = %s    Red de intercambio\n" % snapped(trueque_network_multiplier, 0.01)
	elif unlocked_e:
		click_stats_label.text += "me = — (estructura latente)\n"

	click_stats_label.text += "\n"


# ===============================
#   ESPACIO ESTRUCTURAL fⁿ
# ===============================
	var fn:float  = snapped(get_persistence_target(), 0.01)
	var cn: float = snapped(persistence_dynamic, 0.01)
	var eps: float = snapped(abs(fn - cn), 0.001)
	click_stats_label.text += "=== Lectura estructural ===\n"
	click_stats_label.text += "fⁿ(teórico) = %s\n" % fn
	click_stats_label.text += "cₙ(actual) = %s\n" % cn
	click_stats_label.text += "ε = | fⁿ − cₙ | = %s\n" % eps
	click_stats_label.text += get_structural_state() + "\n\n"
	# ---------- PARÁMETROS DEL MODELO ----------
	click_stats_label.text += "c₀ = %s\n" % snapped(persistence_base, 0.01)
	click_stats_label.text += "k = %s\n" % K_PERSISTENCE
	click_stats_label.text += "n = %s\n" % structural_upgrades
	#---------- ESPACIO N OBSERVACIONAL ----------
	click_stats_label.text += "\nn(log) = %s\n" % snapped(get_n_log(), 0.01)
	click_stats_label.text += "n(power) = %s\n" % snapped(get_n_power(), 0.01)


	# =====================================================
	#  MÉTRICAS LABORATORIO
	# =====================================================

	var c := get_contribution_breakdown()
	var ap := get_active_passive_breakdown()

	stats_label.text = "--- Distribución de aporte ---\n"
	stats_label.text += "Click: %s%%\n" % snapped(c.click, 0.1)
	stats_label.text += "Trabajo Manual: %s%%\n" % snapped(c.d, 0.1)
	stats_label.text += "Trueque: %s%%\n\n" % snapped(c.e, 0.1)
	stats_label.text += "Δ$ estimado / s = +%s\n" % snapped(c.total, 0.01)

	stats_label.text += "\n--- Activo vs Pasivo ---\n"
	stats_label.text += "Activo (CLICK): %s%%\n" % snapped(ap.activo, 0.1)
	stats_label.text += "Pasivo (d+e): %s%%\n" % snapped(ap.pasivo, 0.1)
	stats_label.text += "Δ$ activo / s = +%s\n" % snapped(ap.push_abs, 0.01)
	stats_label.text += "Δ$ pasivo / s = +%s\n" % snapped(ap.passive_abs, 0.01)

	stats_label.text += "\nTiempo de sesión: " + format_time(run_time)

	if lab_mode:
		stats_label.text += "\n\n--- Lap markers (últimos 12) ---\n"
		var start: int = max(0, lap_events.size() - 12)
		for i in range(start, lap_events.size()):
			var lap: Dictionary = lap_events[i]
			stats_label.text += "%s → %s\n" % [lap.time, lap.event]

	

	
	# === BOTONES CLICK ===

	upgrade_click_button.text =  "Mejorar click (+%s)\nCosto: $%s" % [str(snapped(click_value + 1, 0.01)),str(round(click_upgrade_cost))]

	upgrade_click_multiplier_button.text =  "Memoria Numérica (×1.06)\nCosto: $%s" % [str(round(click_multiplier_upgrade_cost))]

	persistence_upgrade_button.text = "Memoria Operativa del Sistema (única)\nPersistencia → %s\nCosto: %s" % [ str(PERSISTENCE_NEW_VALUE),("—" if persistence_upgrade_unlocked else "$" + str(round(persistence_upgrade_cost)))
	]

	# === BOTONES AUTO (d + md) ===
	upgrade_auto_button.text = "Trabajo Manual (+1/s)\nCosto: $%s" % [str(round(auto_upgrade_cost))]

	upgrade_auto_multiplier_button.text = "Ritmo de Trabajo (×%s)\nCosto: $%s" %[str(snapped(AUTO_MULTIPLIER_GAIN, 0.01)),str(round(auto_multiplier_upgrade_cost))]

	# === BOTONES ESPECIALIZACIÓN ===
	specialization_button.text = "Especialización de Oficio (×%s)\nCosto: $%s" % [str(snapped(SPECIALIZATION_GAIN, 0.01)),str(round(specialization_cost))]
	
	# === BOTONES TRUEQUE (e + me) ===

	upgrade_trueque_button.text = "Trueque (+1)\nCosto: $%s" % [str(round(trueque_cost))]

	upgrade_trueque_network_button.text = "Red de Intercambio (×%s)\nCosto: $%s" % [str(snapped(TRUEQUE_NETWORK_GAIN, 0.01)),str(round(trueque_network_upgrade_cost))]
