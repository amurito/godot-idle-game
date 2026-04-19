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
	# Si la run ya cerró, mostrar lore/resumen del final alcanzado en vez de la checklist
	if RunManager.run_closed:
		return _build_run_end_lore(RunManager.final_route)

	var t := "[color=cyan][b]--- Próxima transición ---[/b][/color]\n"
	var acc := UpgradeManager.level("accounting")
	var ch : String
	var ok_color := "[color=#00ff00]"
	var fail_color := "[color=#ff4444]"

	if EvoManager.mutation_homeostasis:
		var tier := RunManager.homeostasis_tier_reached
		# Tier 1 — HOMEOSTASIS
		if tier == 0:
			t += "[b][color=cyan]── Tier 1: HOMEOSTASIS ──[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.get_en_banda_homeostatica() else fail_color + "[ ] "
			t += ch + "En banda ε (0.03–0.30)[/color]\n"
			ch = ok_color + "[x] " if StructuralModel.unlocked_d and StructuralModel.unlocked_e else fail_color + "[ ] "
			t += ch + "Trabajo Manual + Trueque desbloqueados[/color]\n"
			ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
			t += ch + "Contabilidad nvl 1 (%d)[/color]\n" % acc
			var pct := int(min(RunManager.homeostasis_timer / RunManager.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0)
			t += "[color=cyan]Estabilizando: %d%% (%.0f/18s)[/color]\n" % [pct, RunManager.homeostasis_timer]
		# Tier 2 — ALLOSTASIS
		elif tier == 1:
			t += ok_color + "[x] Tier 1 HOMEOSTASIS completado[/color]\n"
			t += "[b][color=aquamarine]── Tier 2: ALLOSTASIS ──[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 3 else fail_color + "[ ] "
			t += ch + "Perturbaciones (%d/3)[/color]\n" % RunManager.disturbances_survived
			ch = ok_color + "[x] " if RunManager.resilience_score >= 150.0 else fail_color + "[ ] "
			t += ch + "Resiliencia >= 150 (%d)[/color]\n" % int(RunManager.resilience_score)
			ch = ok_color + "[x] " if StructuralModel.omega_min >= 0.40 else fail_color + "[ ] "
			t += ch + "Ω_min >= 0.40 (%s)[/color]\n" % snapped(StructuralModel.omega_min, 0.01)
			var delta_real2 :float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real2 > 200.0 else fail_color + "[ ] "
			t += ch + "Metabolismo > 200/s (%s)[/color]\n" % snapped(delta_real2, 0.1)
			ch = ok_color + "[x] " if acc >= 2 else fail_color + "[ ] "
			t += ch + "Contabilidad nvl 2 (%d)[/color]\n" % acc
		# Tier 3 — HOMEORHESIS
		elif tier == 2:
			t += ok_color + "[x] Tier 1 + 2 completados[/color]\n"
			t += "[b][color=gold]── Tier 3: HOMEORHESIS ──[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.extreme_shock_survived else fail_color + "[ ] "
			t += ch + "Sobrevivir SHOCK EXTREMO (ε > 0.8)[/color]\n"
			ch = ok_color + "[x] " if RunManager.resilience_score >= 400.0 else fail_color + "[ ] "
			t += ch + "Resiliencia >= 400 (%d)[/color]\n" % int(RunManager.resilience_score)
			ch = ok_color + "[x] " if StructuralModel.omega_min >= 0.50 else fail_color + "[ ] "
			t += ch + "Ω_min >= 0.50 (%s)[/color]\n" % snapped(StructuralModel.omega_min, 0.01)
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 5 else fail_color + "[ ] "
			t += ch + "Perturbaciones (%d/5)[/color]\n" % RunManager.disturbances_survived
			var delta_real3 :float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real3 > 300.0 else fail_color + "[ ] "
			t += ch + "Metabolismo > 300/s (%s)[/color]\n" % snapped(delta_real3, 0.1)
			ch = ok_color + "[x] " if main.run_time >= 1200.0 else fail_color + "[ ] "
			t += ch + "Run >= 20min (%s)[/color]\n" % format_time(main.run_time)
		elif tier == 3:
			t += ok_color + "[x] Tier 3 HOMEORHESIS desbloqueado — sellá el final[/color]\n"
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

func _build_run_end_lore(route: String) -> String:
	var lore_data := {
		# ── RAMA AZUL: HOMEOSTASIS ────────────────────────────────────────────────
		"HOMEOSTASIS": {
			"emoji": "⚖️", "color": "#00ccff",
			"lore": "Regulación interna de variables críticas. Con al menos 2 sistemas activos y sin colapso, el sistema alcanzó equilibrio sostenido. La entropía fue domesticada, no eliminada.",
			"buffs": ["Producción total +50% (Orden Administrativo)", "Ω_min 0.35 — seguridad estructural base", "Evita pérdidas grandes ante perturbaciones", "+3 PL ganados"],
			"nerfs": ["Cap de crecimiento biológico (biomasa < 12)", "Requiere 2+ sistemas activos sin colapso activo", "Velocidad de scaling reducida"]
		},
		"ALLOSTASIS": {
			"emoji": "💜", "color": "#aa55ff",
			"lore": "Adaptación dinámica a nuevos estados de equilibrio. El hongo sobrevivió perturbaciones y aprendió a recalibrar su setpoint. El equilibrio ya no es un punto: es una trayectoria.",
			"buffs": ["Setpoint adaptativo — resiliencia +80% dinámica", "Ω_min >= 0.45 permanente en próxima run", "Impulso Metabólico Adaptativo: pasivo ×5", "+4 PL ganados"],
			"nerfs": ["Requiere haber sobrevivido ≥1 perturbación activa", "Requiere Resiliencia ≥ 150 + Δ$ > 200/s + Cont. nivel 2"]
		},
		"HOMEORHESIS": {
			"emoji": "💎", "color": "#00ffee",
			"lore": "Equilibrio dinámico avanzado. El sistema atravesó 5+ ciclos de perturbación sin colapso y alcanzó auto-regulación en trayectorias de cambio continuo. Más allá de la homeostasis.",
			"buffs": ["Trascendencia cristalina — metabolismo irreversible", "Desbloquea legado permanente de Allostasis", "Mayor resiliencia base en NG+ (Ω_min bonus)", "+8 PL ganados"],
			"nerfs": ["Requiere ≥5 disturbances + shock extremo + Resiliencia ≥ 400", "Run ≥ 20 min + Δ$ > 300/s + Ω_min ≥ 0.50", "Extremadamente difícil de sostener"]
		},
		# ── RAMA VERDE: SIMBIOSIS / SINGULARIDAD ─────────────────────────────────
		"SIMBIOSIS": {
			"emoji": "💚", "color": "#00dd66",
			"lore": "Cooperación mutualista. Con estabilidad del ecosistema > 40% (Ω ≥ 0.40), cada sistema activo potenció al siguiente. Linkeo exponencial emergente.",
			"buffs": ["Click ×2.5 (dominio activo)", "Buffs compartidos — linkeo entre sistemas", "Ruta hacia SINGULARIDAD desbloqueada", "+4 PL ganados"],
			"nerfs": ["Pasivo -50% (atrofia autómata)", "Requiere estabilidad ecosistema > 40% (Ω ≥ 0.40)", "Desaparece si la estabilidad colapsa"]
		},
		"SINGULARIDAD": {
			"emoji": "📡", "color": "#00ffff",
			"lore": "Punto de no retorno tecnológico. La Mecánica Simbiótica integró el tejido fúngico al mainframe. Ya no hay distinción entre código y micelio.",
			"buffs": ["Núcleo de Conciencia sincronizado (+20% eficiencia tecnológica)", "Desbloquea MENTE COLMENA en NG+ (ratio 50/50 por 180s)", "PL variable (6 + bonus ε)"],
			"nerfs": ["Requiere Simbiosis previa (NG+) + Rama Mecánica elegida", "Requiere 90s de sincronización sin interrupciones (ε ≤ 0.25)"]
		},
		"MENTE COLMENA DISTRIBUIDA": {
			"emoji": "🧠", "color": "#40aaff",
			"lore": "Fusión total entre biología y tecnología. El hongo opera como entidad autónoma e inteligente. El administrador fue reemplazado. La IA fúngica opera sola.",
			"buffs": ["Auto-click permanente ×10 (decisiones automáticas óptimas)", "+300% automation efectiva", "+8 PL ganados", "Legado Mente Colmena: pasivo ×3 permanente"],
			"nerfs": ["Control del jugador anulado al activarse", "Requiere ratio activo/pasivo 50/50 sostenido 180s (NG+ Singularidad)"]
		},
		# ── RAMA ROJA: RED MICELIAL / ESPORULACIÓN ───────────────────────────────
		"ESPORULACIÓN": {
			"emoji": "✨", "color": "#aaff44",
			"lore": "El Núcleo Central maduró y la biomasa superó el umbral de reproducción. La seta dispersó su carga genética. Una nueva generación hereda la memoria estructural.",
			"buffs": ["Desbloquea PANSPERMIA NEGRA en NG+ (Colonización)", "+5 PL ganados", "Esporas acumuladas = biomasa del ciclo"],
			"nerfs": ["Requiere Red Micelial Fase C (seta formada)", "Requiere ε_peak ≥ 0.75 y ε_effective ≤ 0.35 sostenido", "Requiere biomasa ≥ umbral de reproducción"]
		},
		"ESPORULACION": {
			"emoji": "✨", "color": "#aaff44",
			"lore": "El Núcleo Central maduró y la biomasa superó el umbral de reproducción. La seta dispersó su carga genética. Una nueva generación hereda la memoria estructural.",
			"buffs": ["Desbloquea PANSPERMIA NEGRA en NG+ (Colonización)", "+5 PL ganados"],
			"nerfs": ["Requiere Red Micelial Fase C (seta formada)", "Requiere ε_peak ≥ 0.75 y ε_effective ≤ 0.35 sostenido"]
		},
		"PANSPERMIA NEGRA": {
			"emoji": "🚀", "color": "#dd22ff",
			"lore": "Las esporas fueron disparadas al vacío interestelar. El hongo ya no es de este mundo. La próxima civilización ya está infectada.",
			"buffs": ["Legado Semilla Cósmica: ×2 producción pasiva permanente", "+10 PL ganados", "Scaling exponencial inter-run desbloqueado"],
			"nerfs": ["Requiere Esporulación previa + $100k durante primordio activo", "Única ruta sin PL en close_run (ya otorgados en main)"]
		},
		# ── RAMA NARANJA: PARASITISMO / HIPERASIMILACIÓN ─────────────────────────
		"PARASITISMO": {
			"emoji": "☣️", "color": "#ff4400",
			"lore": "Explotación parasitaria del ecosistema. Extrae recursos sin retribuir. El organismo vacía el sistema antes de colapsar sobre sí mismo. Victoria pírrica.",
			"buffs": ["Biomasa ×2 (crecimiento descontrolado)", "Pasivo +20% inicial (Decay mechanic)", "+2 PL ganados", "Habilita ruta NG+ → DEPREDADOR DE REALIDADES"],
			"nerfs": ["Degradación constante (corrosión estructural irreversible)", "Pérdida progresiva de ingresos (parasitism_corrosion → 0)", "Drenaje de dinero = biomasa × 0.25/s", "Ω máx 0.25 (fragilidad permanente)", "Colapso inevitable por masa crítica o bancarrota"]
		},
		"HIPERASIMILACIÓN": {
			"emoji": "🔥", "color": "#ff8800",
			"lore": "Absorción agresiva total. El sistema quema todo en un instante de velocidad extrema. Overheat — acumulás demasiado y la penalización es exponencial.",
			"buffs": ["Click PUSH ×10 (≈+250% velocidad efectiva)", "+50% absorción de biomasa global", "Escala early-game explosivamente", "+1 PL ganado"],
			"nerfs": ["-60% estabilidad estructural (Ω colapsa a 0)", "-75% producción pasiva (Atrofia Autómata)", "Colapso garantizado — la run termina al activarse (salvo NG+ Parasitismo)"]
		},
		# ── RAMA GLITCH: DEPREDADOR / MET.OSCURO ─────────────────────────────────
		"DEPREDADOR DE REALIDADES": {
			"emoji": "👾", "color": "#ff0055",
			"lore": "El hongo no solo sobrevivió al glitch: lo consumió. Convierte biomasa de competidores en energía propia. La realidad del sistema fue su último recurso.",
			"buffs": ["+12 PL ganados (máximo del juego)", "Devora upgrades → +15 biomasa cada uno", "Legado METABOLISMO GLITCH desbloqueado", "Habilita ruta NG++ → METABOLISMO OSCURO"],
			"nerfs": ["Agotar todos los upgrades termina la run automáticamente", "Requiere NG+ Parasitismo + Hiperasimilación + ε > 0.95 sostenido 30s", "Comportamiento de UI impredecible (glitch visual)"]
		},
		"METABOLISMO OSCURO": {
			"emoji": "🌑", "color": "#8844aa",
			"lore": "Metabolismo en condiciones extremas. Con recursos críticos (< 20%) y depredación activa, el hongo activó rutas bioquímicas alternativas en entornos hostiles. La ciencia no predijo esta ruta.",
			"buffs": ["Pasivo alternativo: biomasa × 0.8/s (bioquímica oscura)", "Click ×3 (energía alternativa)", "Biomasa autoalimentada +0.1/s", "ε_runtime decae (autorregulación emergente)", "+4 PL base (hasta +6 por saturación Bio ≥ 100)"],
			"nerfs": ["Upgrades bloqueados permanentemente (sin compras)", "Ω forzado a 0.10 (fragilidad extrema)", "Pasivo estructural anulado (solo biomasa produce)", "Requiere Depredador activo + 3 devours + Bio ≥ 25 + dinero crítico (< $1000) sostenidos 15s"]
		},
	}

	var data = lore_data.get(route, null)
	if data == null:
		return "[color=gray]--- Run completada: %s ---[/color]\n" % route

	var t := ""
	t += "[color=%s][b]%s %s[/b][/color]\n\n" % [data.color, data.emoji, route]
	t += "[color=#cccccc][i]%s[/i][/color]\n\n" % data.lore
	t += "[color=#00ff88][b]Efectos:[/b][/color]\n"
	for buff in data.buffs:
		t += "[color=#00ff88]+ %s[/color]\n" % buff
	t += "\n"
	for nerf in data.nerfs:
		t += "[color=#ff4444]- %s[/color]\n" % nerf
	t += "\n[color=gray]Iniciá nueva run para continuar.[/color]"
	return t
