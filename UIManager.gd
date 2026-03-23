extends Node

# UIManager.gd — Autoload
# Encargado de la actualización visual y gestión de referencias de UI.

var root: Control

# Referencias de Labels (Sin tipo fijo para soportar Label y RichTextLabel)
var money_label
var sys_delta_label
var delta_total_label
var system_state_label
var system_message_label
var session_time_label
var lap_log_label
var formula_label
var marginal_label
var epsilon_sticky_label
var sys_active_passive_label
var sys_breakdown_label
var system_achievements_label
var institution_panel_label
var genome_summary_label
var click_stats_label
var lap_markers_label
var epsilon_sticky_panel

# Referencias de Botones (Upgrades) (Sin tipo fijo para flexibilidad)
var upgrade_click_button
var upgrade_click_multiplier_button
var persistence_upgrade_button
var upgrade_auto_button
var upgrade_auto_multiplier_button
var specialization_button
var upgrade_trueque_button
var upgrade_trueque_network_button
var upgrade_cognitive_button
var upgrade_accounting_button

# Otros
var export_run_button
var big_click_button
var toggle_lap_button

func setup(ui_root: Control):
	root = ui_root
	
	# Labels
	money_label = _find("MoneyLabel")
	sys_delta_label = _find("SystemDeltaLabel")
	delta_total_label = _find("DeltaTotalLabel")
	system_state_label = _find("SystemStateLabel")
	system_message_label = _find("SystemMessageLabel")
	session_time_label = _find("SessionTimeLabel")
	lap_log_label = _find("LapLogLabel")
	formula_label = _find("FormulaLabel")
	marginal_label = _find("MarginalLabel")
	epsilon_sticky_label = _find("EpsilonStickyLabel")
	sys_active_passive_label = _find("SystemActivePassiveLabel")
	sys_breakdown_label = _find("SystemBreakdownLabel")
	system_achievements_label = _find("SystemAchievementsLabel")
	institution_panel_label = _find("InstitutionPanelLabel")
	genome_summary_label = _find("GenomeSummaryLabel")
	click_stats_label = _find("ClickStatsLabel")
	lap_markers_label = _find("LapLogLabel")
	epsilon_sticky_panel = _find("EpsilonStickyPanel")
	
	# Botones
	upgrade_click_button = _find("UpgradeClickButton")
	upgrade_click_multiplier_button = _find("UpgradeClickMultiplierButton")
	persistence_upgrade_button = _find("PersistenceUpgradeButton")
	upgrade_auto_button = _find("UpgradeAutoButton")
	upgrade_auto_multiplier_button = _find("UpgradeAutoMultiplierButton")
	specialization_button = _find("UpgradeSpecializationButton")
	upgrade_trueque_button = _find("UpgradeTruequeButton")
	upgrade_trueque_network_button = _find("UpgradeTruequeNetworkButton")
	upgrade_cognitive_button = _find("UpgradeCognitiveButton")
	upgrade_accounting_button = _find("UpgradeAccountingButton")
	
	export_run_button = _find("ExportRunButton")
	big_click_button = _find("BigClickButton")
	toggle_lap_button = _find("ToggleLapViewButton")
	
	print("🎨 [UIManager] Todos los nodos vinculados.")

func _find(node_name: String):
	return root.find_child(node_name, true, false)

# --- Métodos de actualización ---

func update_money(amount: float):
	if money_label: money_label.text = "Dinero: $" + str(round(amount))

func update_timer(t: float):
	if session_time_label: session_time_label.text = "Tiempo de sesión: " + format_time(t)

# --- Generación de Textos de HUD ---

func build_formula_text(main: Node) -> String:
	var t := "Δ$ = (a · b · c) + (d · md) + (e · me)"
	if main.cached_mu > 1.01:
		t = "Δ$ = [(a · b · c) + (d · md) + (e · me)] · μ"
	return t

func build_formula_values(main: Node) -> String:
	var p = main.get_click_power()
	var d = main.get_auto_income_effective()
	var e = main.get_trueque_income_effective()
	
	var txt = "p = +%s | d = +%s | e = +%s" % [
		str(snapped(p, 0.01)),
		str(snapped(d, 0.01)),
		str(snapped(e, 0.01))
	]
	
	if main.cached_mu > 1.01:
		txt += " | μ = x%s" % str(snapped(main.cached_mu, 0.01))
	
	return txt

func build_marginal_contribution(main: Node) -> String:
	var p = main.get_click_power()
	var d = main.get_auto_income_effective()
	var e = main.get_trueque_income_effective()
	var total = p + d + e
	if total <= 0: return "Sin producción activa"
	
	var pp = (p / total) * 100.0
	var pd = (d / total) * 100.0
	var pe = (e / total) * 100.0
	
	return "Contribución: P(%.0f%%) D(%.0f%%) E(%.0f%%)" % [pp, pd, pe]

func update_click_stats_panel(main: Node) -> String:
	var p = main.get_click_power()
	var t = "--- Detalle de Producción ---\n"
	t += "Potencia Click : %s\n" % snapped(p, 0.01)
	t += "μ Efectivo     : x%s\n" % snapped(main.cached_mu, 0.02)
	t += "Persistencia cₙ: %s" % snapped(main.persistence_dynamic, 0.02)
	return t

# --- Helpers ---

func update_appearance(money: float):
	for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
		if btn.has_method("update_appearance"):
			btn.update_appearance(money)

func get_system_phase(omega: float) -> String:
	if omega > 0.65: return "Estable / Flexible"
	if omega > 0.45: return "Cristalización Incipiente"
	if omega > 0.25: return "Rigidez Crítica"
	return "Colapso Predictivo"

func format_time(t: float) -> String:
	var hours = int(t / 3600)
	var mins = int(fmod(t, 3600) / 60)
	var secs = int(fmod(t, 60))
	return "%02d:%02d:%02d" % [hours, mins, secs]

func epsilon_flag(v: float, limit: float) -> String:
	return "⚠️" if v > limit else "✅"
