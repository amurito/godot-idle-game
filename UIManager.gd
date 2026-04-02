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
var fungal_cycle_bar   # Barra de progreso del ciclo biológico (Micelio)

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
	fungal_cycle_bar = _find("FungalCycleBar")
	
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
	var has_abc = UpgradeManager.level("click_mult") > 0
	
	# --- TÉRMINO ACTIVO (Clicks) ---
	# clicks · a · b · cₙ
	var active_term = "clicks · a"
	if has_abc: active_term += " · b"
	active_term += " · cₙ"
	
	if LegacyManager.get_buff_value("impulso_manual"):
		active_term = "( " + active_term + " · [color=#ffcc00]im[/color] )"
	
	var formula_main = active_term
	
	# --- TÉRMINOS PASIVOS (D y E) ---
	if main.unlocked_d: 
		var d_term = "d"
		if main.unlocked_md:
			d_term = "d · md"
			if UpgradeManager.level("specialization") > 0:
				d_term += " · so"
		formula_main += " + " + d_term
		
		if main.unlocked_e:
			var e_term = "e"
			if main.unlocked_me:
				e_term = "e · me"
			if UpgradeManager.level("trueque_allo") > 0:
				e_term += " · [color=cyan]ea[/color]"
			formula_main += " + " + e_term
		
	# --- MULTIPLICADOR GLOBAL (μ) ---
	if LegacyManager.get_buff_value("redireccion_energia"):
		formula_main += " + [color=#ffcc00]re[/color]"

	if main.cached_mu > 1.01:
		formula_main = "[ " + formula_main + " ] · [color=#ff4dff]μ[/color]"
	
	var plain_str = formula_main.replace("[color=#ffcc00]", "").replace("[color=#ff4dff]", "").replace("[/color]", "")
	var fLen = plain_str.length()
	var fSize = 18
	if fLen > 70: fSize = 13
	elif fLen > 55: fSize = 15
	elif fLen > 40: fSize = 16
	
	var t: String = "[center][font_size=%d]∫$ = " % fSize + formula_main + "[/font_size]\n"
	
	# Información del Modelo
	t += "fⁿ = c₀ · κμ^(1 - 1/n)\n\n"
	t += "κμ = k · (1 + α · (μ - 1))\n"
	
	var raw_n = main.get_structural_upgrades()
	t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  μ = %.2f  n = %d[/color][/center]" % [
		main.persistence_base, main.persistence_dynamic, main.cached_mu, raw_n
	]
		
	return t

func build_formula_values(_main: Node) -> String:
	return ""

func build_marginal_contribution(_main: Node) -> String:
	return ""

func update_click_stats_panel(main: Node) -> String:
	var a = UpgradeManager.value("click")
	var b = UpgradeManager.value("click_mult")
	var c_n = main.persistence_dynamic
	
	var d_raw = UpgradeManager.value("auto")
	var md = UpgradeManager.value("auto_mult")
	var so = UpgradeManager.value("specialization")
	
	var e_raw = UpgradeManager.value("trueque")
	var me = UpgradeManager.value("trueque_net")
	
	var ap = main.get_active_passive_breakdown()
	var push = ap.push_abs
		
	var t = "[b]Aporte actual:[/b]\n"
	t += "[color=#cccccc]• Click PUSH = +%.2f\n" % push
	if main.unlocked_d: t += "• Trabajo Manual = +%.2f /s\n" % main.get_auto_income_effective()
	if main.unlocked_e: t += "• Trueque = +%.2f /s[/color]\n\n" % main.get_trueque_income_effective()
	
	t += "[b]Δ$ total = +%.2f[/b]\n" % ap.total
	if ap.total > 0:
		if ap.activo > ap.pasivo:
			t += "CLICK domina el sistema\n\n"
		else:
			t += "La RED SISTÉMICA domina\n\n"
		
	t += "[color=#d946ef]--- Producción activa ---\n"
	t += "a = %.1f   Click base\n" % a
	if UpgradeManager.level("click_mult") > 0:
		t += "b = %.2f   Multiplicador\n" % b
	if main.persistence_upgrade_unlocked:
		t += "c_n(actual) = %.2f\n" % c_n
	if LegacyManager.get_buff_value("impulso_manual"):
		t += "im = 2.00   Impulso Manual (Legado)\n"
	t += "\n"
	
	if main.unlocked_d:
		t += "d = %.1f/s   Trabajo Manual\n" % d_raw
		if main.unlocked_md: t += "md = %.2f   Ritmo de Trabajo\n" % md
		else: t += "md = -- (estructura latente)\n"
		if UpgradeManager.level("specialization") > 0: t += "so = %.2f   Especialización de Oficio\n" % so
		t += "\n"
	
	if main.unlocked_e:
		t += "e = %.1f/s   Trueque corregido\n" % e_raw
		if main.unlocked_me: 
			t += "me = %.2f   Red de Intercambio\n" % me
			if UpgradeManager.level("trueque_allo") > 0:
				t += "ea = %.2f   Escalado Alostático (Legado)\n" % UpgradeManager.value("trueque_allo")
		else: t += "me = -- (estructura latente)\n"
	
	if LegacyManager.get_buff_value("redireccion_energia"):
		t += "re = +%.1f/s   Redirección (10%% Click a Pasivo)\n" % (main.get_click_power() * 0.10)
	
	t += "\n\n--- MODELO ESTRUCTURAL ---\n"
	var n_struct = main.get_effective_structural_n()
	var k_base = EcoModel.get_k_structural(n_struct)
	var alpha = EcoModel.get_alpha(n_struct)
	
	t += "μ = %.2f\n" % main.cached_mu
	t += "k = %.2f\n" % k_base
	t += "α = %.2f\n" % alpha
	t += "κμ = %.2f\n" % main.get_k_eff()
	t += "n = %d\n" % main.get_structural_upgrades()
	
	t += "\n\n--- Capital Cognitivo ---\n"
	t += "μ = %.2f\n" % main.cached_mu
	t += "Nivel cognitivo = %d" % UpgradeManager.level("cognitive")
	
	t += "[/color]"
	
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
