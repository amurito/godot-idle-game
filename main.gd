extends Control

# =====================================================
#  IDLE — v0.6.1 “Observatorio fⁿ — Tagging Layer”
#  Cambios clave:
#  • Integración cronómetro + lap markers
#  • Activo vs Pasivo (CLICK vs d+e)
#  • Métrica estructural fⁿ (observacional)
#  • Persistencia dinámica (no aplicada aún)
#  • Refactor UI + capas consolidadas
# =====================================================


# =============== ECONOMÍA BASE =======================

var money: float = 0.0


# --- CLICK (a · b · c) ---
var click_value: float = 1.0
var click_upgrade_cost: float = 5.0

var click_multiplier: float = 1.0
var click_multiplier_upgrade_cost: float = 200.0

var click_persistence: float = 1.4   # c (base estable)


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
const VERSION := "0.6"
const CODENAME := "Observatorio fⁿ"
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
	return click_value * click_multiplier * click_persistence

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
#  CAPA 3 — fⁿ (OBSERVACIONAL)
# =====================================================

func get_persistence_dynamic() -> float:
	if structural_upgrades <= 1:
		return click_persistence

	var n := float(structural_upgrades)
	return click_persistence * pow(K_PERSISTENCE, (1.0 - 1.0 / n))

func get_n_log() -> float:
	return 1.0 + log(1.0 + structural_upgrades)

func get_n_power() -> float:
	return pow(structural_upgrades + 1.0, 0.35)



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
		"c_base": click_persistence,

		"n_structural": structural_upgrades,
		"f_n": get_persistence_dynamic(),

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
	var t := "Δ$ = clicks × (a × b × c)"

	# --- d ---
	if unlocked_d:
		if specialization_level > 0:
			t += "+  d × md × so" 
		elif unlocked_md:
			t += "  +  d × md"
		else:
			t += "  +  d"
	else:
		t += "  +  d"

	# --- e ---
	if unlocked_e:
		if unlocked_me:
			t += "  +  e × me"
		else:
			t += "  +  e"
	else:
		t += "  +  e"

	return t


func build_formula_values() -> String:
	var t := "= clicks × (%s × %s × %s)" % [
		str(snapped(click_value, 0.01)),
		str(snapped(click_multiplier, 0.01)),
		str(snapped(click_persistence, 0.01))
	]

	# d
	if unlocked_d:
		if specialization_level > 0:
			t += "  +  %s/s × %s × %s" % [
				str(snapped(income_per_second, 0.01)),
				str(snapped(auto_multiplier, 0.01)),
				str(snapped(manual_specialization, 0.01))
			]
		elif unlocked_md:
			t += "  +  %s/s × %s" % [
				str(snapped(income_per_second, 0.01)),
				str(snapped(auto_multiplier, 0.01))
			]
		else:
			t += "  +  %s/s" % str(snapped(income_per_second, 0.01))

	# e
	if unlocked_e:
		if unlocked_me:
			t += "  +  %s/s × %s" % [
				str(snapped(get_trueque_raw(), 0.01)),
				str(snapped(trueque_network_multiplier, 0.01))
			]
		else:
			t += "  +  %s/s" % str(snapped(get_trueque_raw(), 0.01))

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
	click_persistence = PERSISTENCE_NEW_VALUE
	persistence_upgrade_unlocked = true
	structural_upgrades += 1

	add_lap("Upgrade estructural → Persistencia")
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
#  UI — SOLO LEE RESULTADOS
# =====================================================

func update_ui():
	check_dominance_transition()

	var auto_eff := get_auto_income_effective()
	var trueque_eff := get_trueque_income_effective()
	var passive_total := auto_eff + trueque_eff
	var c_dyn := get_persistence_dynamic()

	money_label.text = "Dinero: $" + str(round(money))
	income_label.text = "Ingreso pasivo / s: $" + str(snapped(passive_total, 0.01))

	big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"

	formula_label.text = build_formula_text() + "\n" + build_formula_values()
	marginal_label.text = build_marginal_contribution()

	# CLICK PANEL
	click_stats_label.text = "a = %s    Click base\nb = %s    Multiplicador\nc = %s    Persistencia\n\n%s\n\n" % [
			str(snapped(click_value, 0.01)), str(snapped(click_multiplier, 0.01)), str(snapped(click_persistence, 0.01)), ("Persistencia estructural: ACTIVA" if persistence_upgrade_unlocked else "Persistencia estructural: —")
			]

	click_stats_label.text += "d = %s/s    Trabajo Manual\nmd = %s    Ritmo de trabajo\n\ne = %s/s    Trueque corregido\nme = %s    Red de intercambio\n\n" % [
			str(snapped(income_per_second, 0.01)), str(snapped(auto_multiplier, 0.01)), str(snapped(get_trueque_raw(), 0.01)), str(snapped(trueque_network_multiplier, 0.01))
		]

	click_stats_label.text += "Persistencia dinámica fⁿ = %s\nn(log)=%s   n(power)=%s\n" % [
		str(snapped(c_dyn, 0.01)), str(snapped(get_n_log(), 0.01)), str(snapped(get_n_power(), 0.01))
	]
	click_stats_label.text += "so = %s    Especialización de Oficio\n" % str(snapped(manual_specialization, 0.01))

	if specialization_level > 0:
		formula_label.text += "\n\n✔ Buff estructural activo — transmisión eficiente"
	
	specialization_button.text = "Especialización de Oficio\nBuff → ×%s\nCosto: $%s" % [ str(snapped(manual_specialization, 0.01)), str(round(specialization_cost))]





	# MÉTRICAS LABORATORIO
	var c := get_contribution_breakdown()
	var ap := get_active_passive_breakdown()

	stats_label.text = "--- Distribución de aporte ---\n"
	stats_label.text += "Click: %s%%\n" % str(snapped(c.click, 0.1))
	stats_label.text += "Trabajo Manual: %s%%\n" % str(snapped(c.d, 0.1))
	stats_label.text += "Trueque: %s%%\n\n" % str(snapped(c.e, 0.1))
	stats_label.text += "Δ$ estimado / s = +%s\n" % str(snapped(c.total, 0.01))

	stats_label.text += "\n--- Activo vs Pasivo ---\n"
	stats_label.text += "Activo (CLICK): %s%%\n" % str(snapped(ap.activo, 0.1))
	stats_label.text += "Pasivo (d+e): %s%%\n" % str(snapped(ap.pasivo, 0.1))
	stats_label.text += "Δ$ activo / s = +%s\n" % str(snapped(ap.push_abs, 0.01))
	stats_label.text += "Δ$ pasivo / s = +%s\n" % str(snapped(ap.passive_abs, 0.01))

	stats_label.text += "\nTiempo de sesión: " + format_time(run_time)

	if lab_mode:
		stats_label.text += "\n\n--- Lap markers (últimos 12) ---\n"

		var start: int = max(0, lap_events.size() - 12)
		for i in range(start, lap_events.size()):
			var lap: Dictionary = lap_events[i]
			stats_label.text += "%s → %s\n" % [lap.time, lap.event]

	

	# BOTONES
	# === BOTONES CLICK ===

	upgrade_click_button.text =  "Mejorar click (+%s)\nCosto: $%s" % [str(snapped(click_value + 1, 0.01)),str(round(click_upgrade_cost))]

	upgrade_click_multiplier_button.text =  "Memoria Numérica (×1.06)\nCosto: $%s" % [str(round(click_multiplier_upgrade_cost))]

	persistence_upgrade_button.text = "Memoria Operativa del Sistema (única)\nPersistencia → %s\nCosto: %s" % [ str(PERSISTENCE_NEW_VALUE),("—" if persistence_upgrade_unlocked else "$" + str(round(persistence_upgrade_cost)))
	]

	# === BOTONES AUTO (d + md) ===
	upgrade_auto_button.text = "Trabajo Manual (+1/s)\nCosto: $%s" % [str(round(auto_upgrade_cost))]

	upgrade_auto_multiplier_button.text = "Ritmo de Trabajo (×%s)\nCosto: $%s" %[str(snapped(AUTO_MULTIPLIER_GAIN, 0.01)),str(round(auto_multiplier_upgrade_cost))]


# NUEVO BOTÓN — ESPECIALIZACIÓN DE OFICIO

	
	# === BOTONES TRUEQUE (e + me) ===

	upgrade_trueque_button.text = "Trueque (+1)\nCosto: $%s" % [str(round(trueque_cost))]

	upgrade_trueque_network_button.text = "Red de Intercambio (×%s)\nCosto: $%s" % [str(snapped(TRUEQUE_NETWORK_GAIN, 0.01)),str(round(trueque_network_upgrade_cost))]
