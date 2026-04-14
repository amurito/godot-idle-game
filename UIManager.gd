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
	if StructuralModel.unlocked_d: 
		var d_term = "d"
		if StructuralModel.unlocked_md:
			d_term = "d · md"
			if UpgradeManager.level("specialization") > 0:
				d_term += " · so"
		formula_main += " + " + d_term
		
		if StructuralModel.unlocked_e:
			var e_term = "e"
			if StructuralModel.unlocked_me:
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
		StructuralModel.persistence_base, StructuralModel.persistence_dynamic, main.cached_mu, raw_n
	]
		
	return t

func build_formula_values(_main: Node) -> String:
	return ""

func build_marginal_contribution(_main: Node) -> String:
	return ""

func update_click_stats_panel(main: Node) -> String:
	var a = UpgradeManager.value("click")
	var b = UpgradeManager.value("click_mult")
	var c_n = StructuralModel.persistence_dynamic
	
	var d_raw = UpgradeManager.value("auto")
	var md = UpgradeManager.value("auto_mult")
	var so = UpgradeManager.value("specialization")
	
	var e_raw = UpgradeManager.value("trueque")
	var me = UpgradeManager.value("trueque_net")
	
	var ap = main.get_active_passive_breakdown()
	var push = ap.push_abs
		
	var t = "[b]Aporte actual:[/b]\n"
	t += "[color=#cccccc]• Click PUSH = +%.2f\n" % push
	if StructuralModel.unlocked_d: t += "• Trabajo Manual = +%.2f /s\n" % main.get_auto_income_effective()
	if StructuralModel.unlocked_e: t += "• Trueque = +%.2f /s[/color]\n\n" % main.get_trueque_income_effective()
	
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
	if StructuralModel.persistence_upgrade_unlocked:
		t += "c_n(actual) = %.2f\n" % c_n
	if LegacyManager.get_buff_value("impulso_manual"):
		t += "im = 2.00   Impulso Manual (Legado)\n"
	t += "\n"
	
	if StructuralModel.unlocked_d:
		t += "d = %.1f/s   Trabajo Manual\n" % d_raw
		if StructuralModel.unlocked_md: t += "md = %.2f   Ritmo de Trabajo\n" % md
		else: t += "md = -- (estructura latente)\n"
		if UpgradeManager.level("specialization") > 0: t += "so = %.2f   Especialización de Oficio\n" % so
		t += "\n"
	
	if StructuralModel.unlocked_e:
		t += "e = %.1f/s   Trueque corregido\n" % e_raw
		if StructuralModel.unlocked_me: 
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

func build_evo_checklist(main: Node) -> String:
	var t := "[color=cyan][b]--- Próxima transición ---[/b][/color]\n"
	var acc := UpgradeManager.level("accounting")
	var ch : String
	var ok_color := "[color=#00ff00]"
	var fail_color := "[color=#ff4444]"

	if RunManager.homeostasis_mode:
		t += "[b][color=cyan]Allostasis (Tier 2):[/color][/b]\n"
		ch = ok_color + "[x] " if RunManager.disturbances_survived >= 3 else fail_color + "[ ] "
		t += ch + "Superar 3 perturbaciones (%d/3)[/color]\n" % RunManager.disturbances_survived
		ch = ok_color + "[x] " if RunManager.resilience_score >= 150.0 else fail_color + "[ ] "
		t += ch + "Resiliencia >= 150 (%d)[/color]\n" % int(RunManager.resilience_score)
		ch = ok_color + "[x] " if StructuralModel.omega_min >= 0.40 else fail_color + "[ ] "
		t += ch + "Flexibilidad Ω_min >= 0.40 (%s)[/color]\n" % snapped(StructuralModel.omega_min, 0.01)
		ch = ok_color + "[x] " if main.delta_per_sec > 200.0 else fail_color + "[ ] "
		t += ch + "Metabolismo > 200/s (%s)[/color]\n" % snapped(main.delta_per_sec, 0.1)
		ch = ok_color + "[x] " if acc >= 2 else fail_color + "[ ] "
		t += ch + "Contabilidad nvl 2 (%d)[/color]\n" % acc
		t += "\n"

	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		t += "[b]Objetivo: Integración Mecánica[/b]\n"

		# Hito 1: Estabilidad
		var eps_ok: bool = StructuralModel.epsilon_runtime <= 0.25 or EvoManager.nucleo_conciencia
		ch = ok_color + "[x] " if eps_ok else fail_color + "[ ] "
		t += ch + "Estabilidad estructural (ε <= 0.25) (" + str(snapped(StructuralModel.epsilon_runtime, 0.01)) + ")[/color]\n"

		# Hito 2: Sincronización
		if EvoManager.primordio_active:
			t += "[color=cyan]>>> SINCRONIZACIÓN: %s%%[/color]\n" % str(int(EvoManager.primordio_timer / EvoManager.PRIMORDIO_DURATION * 100.0))
		elif EvoManager.nucleo_conciencia:
			t += ok_color + "[x] Núcleo de Conciencia Sincronizado[/color]\n"
		else:
			var acc_ok := acc >= 2
			ch = ok_color + "[x] " if acc_ok else fail_color + "[ ] "
			t += ch + "Integrar redes en Mainframe (Contabilidad nvl 2)[/color]\n"

		# Hito 3: Núcleo
		ch = ok_color + "[x] " if EvoManager.nucleo_conciencia else fail_color + "[ ] "
		t += ch + "Singularidad Biomecánica lista[/color]\n"

	elif EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		t += "[b]Objetivo: Ciclo de Vida Biológico[/b]\n"

		# Hito 1: Micelio
		var mic_ok: bool = BiosphereEngine.micelio >= 60.0 or EvoManager.seta_formada
		ch = ok_color + "[x] " if mic_ok else fail_color + "[ ] "
		t += ch + "Micelio desarrollado (>60%) (" + str(int(BiosphereEngine.micelio)) + "%) [/color]\n"

		# Hito 2: Primordio
		if EvoManager.primordio_active:
			t += "[color=yellow]>>> PRIMORDIO EN CURSO: %ds / 90s[/color]\n" % int(EvoManager.primordio_timer)
		elif EvoManager.seta_formada:
			t += ok_color + "[x] Ciclo biológico completado exitosamente[/color]\n"
		else:
			ch = fail_color + "[ ] "
			t += ch + "Sobrevivir fase Primordio (90s)[/color]\n"

		# Hito 3: Seta
		ch = ok_color + "[x] " if EvoManager.seta_formada else fail_color + "[ ] "
		t += ch + "Seta Fructífera madura[/color]\n"

		if EvoManager.seta_formada:
			t += "[color=cyan][b]¡LISTO PARA ESPORULACIÓN TOTAL![/b][/color]\n"

	elif EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 1:
		t += "[b]Red Micelial → Fase B:[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas > 10.0 else fail_color + "[ ] "
		t += ch + "Hifas > 10  (%s)[/color]\n" % snapped(BiosphereEngine.hifas, 0.1)
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)
		ch = ok_color + "[x] " if StructuralModel.epsilon_effective < 0.32 else fail_color + "[ ] "
		t += ch + "ε_ef < 0.32  (%s)[/color]\n" % snapped(StructuralModel.epsilon_effective, 0.01)
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + "Contabilidad >= 1  (nivel: %d)[/color]\n" % acc
		ch = ok_color + "[x] " if main.run_time > 200.0 else fail_color + "[ ] "
		t += ch + "Tiempo > 200 s  (%s)[/color]\n" % format_time(main.run_time)

	elif not EvoManager.mutation_red_micelial and not EvoManager.mutation_homeostasis \
		and not EvoManager.mutation_hyperassimilation and not EvoManager.mutation_parasitism:
		t += "[b]Red Micelial (Fase A):[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 11.5 else fail_color + "[ ] "
		t += ch + "Hifas >= 12  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (" + str(snapped(BiosphereEngine.biomasa, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.epsilon_runtime < 0.65 else fail_color + "[ ] "
		t += ch + "ε_runtime < 0.65  (" + str(snapped(StructuralModel.epsilon_runtime, 0.01)) + ")[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + "Contabilidad >= 1  (nivel: " + str(acc) + ")[/color]\n"

	if not EvoManager.mutation_homeostasis and not EvoManager.mutation_hyperassimilation \
		and not EvoManager.mutation_sporulation and not EvoManager.mutation_red_micelial:
		t += "\n[color=gray]Homeostasis (Tier 1):[/color]\n"
		ch = ok_color + "[x] " if main.get_en_banda_homeostatica() else fail_color + "[ ] "
		t += ch + "Banda 0.03 < ε < 0.30  (%s)[/color]\n" % snapped(StructuralModel.epsilon_effective, 0.01)
		ch = ok_color + "[x] " if StructuralModel.omega > 0.25 else fail_color + "[ ] "
		t += ch + "Flexib. Ω > 0.25  (%s)[/color]\n" % snapped(StructuralModel.omega, 0.01)
		ch = ok_color + "[x] " if BiosphereEngine.biomasa < 12.0 else fail_color + "[ ] "
		t += ch + "Biomasa < 12  (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)
		ch = ok_color + "[x] " if main.delta_per_sec > 30.0 else fail_color + "[ ] "
		t += ch + "Metabolismo > 30/s (%s)[/color]\n" % snapped(main.delta_per_sec, 0.1)
		ch = ok_color + "[x] " if StructuralModel.unlocked_d and StructuralModel.unlocked_e else fail_color + "[ ] "
		t += ch + "Pasivos d+e activos[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + "Contabilidad >= 1  (nivel: %d)[/color]\n" % acc

	if EvoManager.mutation_parasitism:
		t += "\n[color=#ffaa00]--- Objetivos de Colapso ---[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 15.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 15 (Succión)  (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)
		ch = ok_color + "[x] " if EconomyManager.money < 1000.0 else fail_color + "[ ] "
		t += ch + "Liquidez < $1000  ($%s)[/color]\n" % snapped(EconomyManager.money, 1)
		t += "\nÓ\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 25.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 25 (Masa Crítica) (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)

	return t
