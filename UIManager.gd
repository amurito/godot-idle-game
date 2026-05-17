extends Node

# UIManager.gd — Autoload
# Encargado de la actualización visual y gestión de referencias de UI.

var root: Control
var scene: Node  # Scene root (UIRoot), parent of UIRootContainer — needed for header nodes

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
var lab_mode: bool = false

# ========== HEADER BAR (Phase 2) ==========
var header_money_value
var header_money_delta
var header_epsilon_bar
var header_omega_bar
var header_biomasa_bar
var header_epsilon_value
var header_omega_value
var header_biomasa_value

# ========== CENTER PANEL COLLAPSIBLE — GENOMA ==========
var genome_scroll            # GenomeScroll ScrollContainer (togglable)
var route_badge_label        # Label en el header mostrando la ruta activa

# ========== RIGHT PANEL COLLAPSIBLES (Phase 4) ==========
var economy_content          # EconomyContent VBoxContainer (togglable)
var structural_content       # StructuralContent GridContainer (togglable)
var structural_eps_value     # EpsValue label
var structural_omg_value     # OmgValue label
var structural_pers_value    # PersValue label
var structural_acc_value     # AccValue label

var evo_choice_panel         # Panel de elección evolutiva
var opt_homeostasis          # Opción Homeostasis
var opt_colonization         # Opción Colonización
var opt_symbiosis            # Opción Simbiosis
var btn_homeostasis          # Botón Homeostasis
var btn_colonization         # Botón Colonización
var btn_symbiosis            # Botón Simbiosis
var primordio_button         # Botón Primordio (Ciclo Biológico)
var sporulation_final_button # Botón final (Seta/Singularidad/Panspermia)

func setup(ui_root: Control):
	root = ui_root
	scene = ui_root.get_parent()  # UIRoot (scene root) — contains HeaderBar as sibling
	
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

	# Header Bar nodes (search from scene root, NOT ui_root — header is a sibling of UIRootContainer)
	header_money_value = _find_scene("MoneyValue")
	header_money_delta = _find_scene("MoneyDelta")
	header_epsilon_bar = _find_scene("EpsilonBar")
	header_omega_bar = _find_scene("OmegaBar")
	header_biomasa_bar = _find_scene("BiomasaBar")
	header_epsilon_value = _find_scene("EpsilonValue")
	header_omega_value = _find_scene("OmegaValue")
	header_biomasa_value = _find_scene("BiomasaValue")

	# Center panel collapsible — Genoma Fúngico
	genome_scroll = _find("GenomeScroll")
	var mutation_toggle_btn = _find("MutationToggleBtn")
	if mutation_toggle_btn and genome_scroll:
		mutation_toggle_btn.toggled.connect(func(pressed: bool):
			_toggle_collapsible_panel(genome_scroll, mutation_toggle_btn, pressed, "Genoma Fúngico + Próxima Mutación")
		)

	# Right panel collapsibles (Phase 4)
	economy_content = _find("EconomyContent")
	structural_content = _find("StructuralContent")
	structural_eps_value = _find("EpsValue")
	structural_omg_value = _find("OmgValue")
	structural_pers_value = _find("PersValue")
	structural_acc_value = _find("AccValue")

	# Wire toggle buttons for collapsible sections (Phase 6 — Smooth Transitions)
	var economy_btn = _find("EconomyToggleBtn")
	if economy_btn:
		economy_btn.toggled.connect(func(pressed: bool):
			_toggle_collapsible_panel(economy_content, economy_btn, pressed, "Economía")
		)

	var structural_btn = _find("StructuralToggleBtn")
	if structural_btn:
		structural_btn.toggled.connect(func(pressed: bool):
			_toggle_collapsible_panel(structural_content, structural_btn, pressed, "Estructura")
		)

	# Route badge — label dinámico en el header para ruta post-trascendencia
	var header_content = _find_scene("HeaderContent")
	if header_content:
		route_badge_label = Label.new()
		route_badge_label.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
		route_badge_label.visible = false
		# Insertar antes del spacer derecho (último hijo)
		header_content.add_child(route_badge_label)
		header_content.move_child(route_badge_label, header_content.get_child_count() - 2)

	# Panel evolutivo y botones de ramificación (hijos de la escena raíz)
	evo_choice_panel = _find_scene("EvoChoicePanel")
	opt_homeostasis = _find_scene("OptHomeostasis")
	opt_colonization = _find_scene("OptColonization")
	opt_symbiosis = _find_scene("OptSymbiosis")
	btn_homeostasis = _find_scene("BtnHomeostasis")
	btn_colonization = _find_scene("BtnColonization")
	btn_symbiosis = _find_scene("BtnSymbiosis")
	primordio_button = _find_scene("PrimordioButton")
	sporulation_final_button = _find_scene("SporulationFinalButton")

	print("🎨 [UIManager] Todos los nodos vinculados. Header=%s" % str(is_instance_valid(header_money_value)))

func _find(node_name: String):
	return root.find_child(node_name, true, false)

func _find_scene(node_name: String):
	if scene:
		return scene.find_child(node_name, true, false)
	return root.find_child(node_name, true, false)

func show_toast(msg: String) -> void:
	if system_message_label:
		system_message_label.text = msg

# --- Métodos de actualización ---

## Muestra la ruta post-trascendencia activa en el header. Llamar una vez al inicio de run.
func update_route_badge() -> void:
	if not is_instance_valid(route_badge_label):
		return
	var text := ""
	var color := Color.WHITE
	if RunManager.vacio_hambriento_active:
		text = "🕳️  VACÍO HAMBRIENTO  ×100"
		color = Color(0.75, 0.2, 1.0)
	elif RunManager.carnaval_active:
		var mut :String= RunManager.carnaval_mutations[RunManager.carnaval_index] if not RunManager.carnaval_mutations.is_empty() else "?"
		text = "🎭  CARNAVAL  [%s]" % mut
		color = Color(1.0, 0.5, 0.1)
	elif RunManager.reencarnacion_active:
		text = "⚱️  REENCARNACIÓN HEREDADA"
		color = Color(0.3, 0.95, 0.6)
	if text == "":
		route_badge_label.visible = false
		return
	route_badge_label.text = text
	route_badge_label.add_theme_color_override("font_color", color)
	route_badge_label.visible = true

func update_money(amount: float):
	if money_label: money_label.text = "Dinero: $" + str(round(amount))

func update_timer(t: float):
	if session_time_label: session_time_label.text = "Tiempo de sesión: " + format_time(t)

# ===== HEADER BAR UPDATES (NEW) =====
func update_header_money(amount: float, delta_per_sec: float):
	if header_money_value:
		if amount >= 1e12:
			header_money_value.text = "%.2fT" % (amount / 1e12)
		elif amount >= 1e9:
			header_money_value.text = "%.2fB" % (amount / 1e9)
		elif amount >= 1e6:
			header_money_value.text = "%.2fM" % (amount / 1e6)
		elif amount >= 1e3:
			header_money_value.text = "%.1fK" % (amount / 1e3)
		else:
			header_money_value.text = str(round(amount))

	if header_money_delta:
		var delta_text = ""
		if delta_per_sec >= 0:
			delta_text = "+"
		if abs(delta_per_sec) >= 1e9:
			delta_text += "%.2fB" % (delta_per_sec / 1e9)
		elif abs(delta_per_sec) >= 1e6:
			delta_text += "%.2fM" % (delta_per_sec / 1e6)
		elif abs(delta_per_sec) >= 1e3:
			delta_text += "%.1fK" % (delta_per_sec / 1e3)
		else:
			delta_text += str(round(delta_per_sec))
		delta_text += "/s"
		header_money_delta.text = delta_text

func update_header_metrics(epsilon: float, omega: float, biomasa: float, biomasa_max: float = 10.0):
	if header_epsilon_bar:
		header_epsilon_bar.value = clamp(epsilon, 0.0, 1.0)
	if header_omega_bar:
		header_omega_bar.value = clamp(omega, 0.0, 1.0)
	if header_biomasa_bar:
		header_biomasa_bar.value = clamp(biomasa / biomasa_max, 0.0, 1.0)
	if header_epsilon_value:
		header_epsilon_value.text = "%.2f" % epsilon
	if header_omega_value:
		header_omega_value.text = "%.2f" % omega
	if header_biomasa_value:
		header_biomasa_value.text = "%.1f/%.0f" % [biomasa, biomasa_max]

func update_structural_metrics(epsilon: float, omega: float, persistence: float, accounting: int):
	if structural_eps_value:
		var eps_col: Color
		if epsilon < 0.30:
			eps_col = Color(0.4, 1.0, 0.5)   # verde — ok
		elif epsilon < 0.55:
			eps_col = Color(1.0, 0.85, 0.2)  # amarillo — precaución
		else:
			eps_col = Color(1.0, 0.35, 0.35) # rojo — peligro
		structural_eps_value.text = "%.3f" % epsilon
		structural_eps_value.add_theme_color_override("font_color", eps_col)

	if structural_omg_value:
		var omg_col: Color
		if omega > 0.50:
			omg_col = Color(0.4, 0.9, 1.0)   # cyan — estable
		elif omega > 0.25:
			omg_col = Color(1.0, 0.75, 0.2)  # naranja — precario
		else:
			omg_col = Color(1.0, 0.3, 0.3)   # rojo — colapso
		structural_omg_value.text = "%.2f" % omega
		structural_omg_value.add_theme_color_override("font_color", omg_col)

	if structural_pers_value:
		structural_pers_value.text = "%.2f" % persistence
	if structural_acc_value:
		structural_acc_value.text = "Nv. %d" % accounting

## Anima la transición de paneles colapsables con tweens suaves (Phase 6)
func _toggle_collapsible_panel(panel: Control, btn: Button, pressed: bool, label: String) -> void:
	if not panel: return

	# Actualizar texto del botón con flecha
	btn.text = EmojiToRichText.strip(("▼ " if pressed else "▶ ") + label)

	# Animar visibilidad + modulate (para fade suave)
	if pressed:
		# Abrir: fade in
		panel.visible = true
		panel.modulate.a = 0.3
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	else:
		# Cerrar: fade out
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		await tween.finished
		panel.visible = false

# --- Generación de Textos de HUD ---

func build_formula_text(main: Node) -> String:
	var has_abc = UpgradeManager.level("click_mult") > 0

	# --- TÉRMINO ACTIVO (Clicks) ---
	var active_term = "clicks · a"
	if has_abc: active_term += " · b"
	active_term += " · cₙ"

	if LegacyManager.get_buff_value("impulso_manual"):
		active_term = "( " + active_term + " · [color=#ffcc00]im[/color] )"
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		active_term += " · [color=#44ee88]rs[/color]"
	if LegacyManager.get_buff_value("aura_dorada"):
		active_term += " · [color=#ffdd44]au[/color]"
	if RunManager.vacio_hambriento_active:
		active_term += " · [color=#bb44ff]vh[/color]"

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

	# --- REDIRECCIÓN + μ ---
	if LegacyManager.get_buff_value("redireccion_energia"):
		formula_main += " + [color=#ffcc00]re[/color]"

	if EconomyManager.cached_mu > 1.01 and UpgradeManager.level("cognitive") > 0:
		formula_main = "[ " + formula_main + " ] · [color=#ff4dff]μ[/color]"

	# --- MULTIPLICADORES GLOBALES DE LEGADO (Λ) ---
	# Aplican a click + pasivo simultáneamente
	var lambda_parts: Array = []
	var lambda_total := 1.0
	# aura_dorada es solo click — se muestra en el término activo como rs/im, no en Λ
	if LegacyManager.get_buff_value("semilla_cosmica"):
		lambda_parts.append("[color=#8899ff]sc[/color]"); lambda_total *= 2.0
	if LegacyManager.get_buff_value("mente_colmena"):
		lambda_parts.append("[color=#ff44ff]mc[/color]"); lambda_total *= 3.0
	var eco_v: float = LegacyManager.get_effect_value("all_income_mult")
	if eco_v > 0.0:
		lambda_parts.append("[color=#44ffaa]ep[/color]"); lambda_total *= (1.0 + eco_v)
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		lambda_parts.append("[color=#ffaa44]cc[/color]")
		lambda_total *= (1.0 + LegacyManager.trascendencia_count * 0.05)
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		lambda_parts.append("[color=#9933cc]mg?[/color]")  # condicional ε>0.40
	if lambda_parts.size() > 0:
		formula_main += " · [color=#ffdd88]Λ[/color]"

	# Auto-escala por longitud
	var plain_str: String = formula_main
	for tag in ["[color=#ffcc00]","[color=#ff4dff]","[color=#44ee88]","[color=#bb44ff]",
				"[color=#ffdd44]","[color=#8899ff]","[color=#ff44ff]","[color=#44ffaa]",
				"[color=#ffaa44]","[color=#9933cc]","[color=#ffdd88]","[color=cyan]","[/color]"]:
		plain_str = plain_str.replace(tag, "")
	var fLen := plain_str.length()
	var fSize := 18
	if fLen > 70: fSize = 13
	elif fLen > 55: fSize = 15
	elif fLen > 40: fSize = 16

	var t: String = "[center][font_size=%d]∫$ = " % fSize + formula_main + "[/font_size]\n"

	# Λ breakdown (solo si hay mults de legado)
	if lambda_parts.size() > 0:
		t += "[color=#ffdd88][font_size=11]Λ = " + " · ".join(lambda_parts)
		if LegacyManager.get_buff_value("metabolismo_glitch"):
			t += "  (mg activo si ε>0.40)"
		t += "[/font_size][/color]\n"

	# Información del Modelo — μ solo cuando Capital Cognitivo está activo
	var raw_n: int = StructuralModel.get_structural_upgrades()
	if UpgradeManager.level("cognitive") > 0:
		t += "fⁿ = c₀ · κμ^(1 - 1/n)\n\n"
		t += "κμ = k · (1 + α · (μ - 1))\n"
		t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  μ = %.2f  n = %d[/color][/center]" % [
			StructuralModel.persistence_base, StructuralModel.persistence_dynamic, EconomyManager.cached_mu, raw_n
		]
	else:
		t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  n = %d[/color][/center]" % [
			StructuralModel.persistence_base, StructuralModel.persistence_dynamic, raw_n
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
	
	var ap = EconomyManager.get_active_passive_breakdown()
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
	if RunManager.vacio_hambriento_active:
		t += "vh = %.0f\n" % RunManager.vacio_hambriento_mult
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
		t += "re = +%.1f/s   Redirección (10%% Click a Pasivo)\n" % (EconomyManager.get_click_power() * 0.10)
	
	t += "\n\n--- MODELO ESTRUCTURAL ---\n"
	var n_struct = StructuralModel.get_effective_structural_n()
	var k_base = EcoModel.get_k_structural(n_struct)
	var alpha = EcoModel.get_alpha(n_struct)
	
	t += "k = %.2f\n" % k_base
	t += "α = %.2f\n" % alpha
	if UpgradeManager.level("cognitive") > 0:
		t += "μ = %.2f\n" % EconomyManager.cached_mu
		t += "κμ = %.2f\n" % StructuralModel.get_k_eff()
	t += "n = %d\n" % StructuralModel.get_structural_upgrades()

	if UpgradeManager.level("cognitive") > 0:
		t += "\n\n--- Capital Cognitivo ---\n"
		t += "μ = %.2f\n" % EconomyManager.cached_mu
		t += "Nivel cognitivo = %d\n" % UpgradeManager.level("cognitive")
		var acc_lvl_d: int = UpgradeManager.level("accounting")
		if acc_lvl_d > 0:
			t += "Contabilidad ×μ = ×%.2f\n" % (1.0 + acc_lvl_d * 0.08)
		if RunManager.resilience_score > 0.0:
			t += "Resiliencia ×μ = ×%.2f (score %.0f)\n" % [1.0 + min(RunManager.resilience_score / 300.0, 1.0) * 0.30, RunManager.resilience_score]

	# --- LEGADO: MULTIPLICADORES DE INGRESOS ---
	var has_income_buff := false
	var income_section := "\n--- LEGADO: Multiplicadores ---\n"
	if LegacyManager.get_buff_value("impulso_manual"):
		income_section += "im  Impulso Manual        click base ×2.00\n"; has_income_buff = true
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		var rs_val: float = min(1.0 + BiosphereEngine.biomasa * 0.05, 2.5)
		income_section += "rs  Resonancia Simbionte   click ×%.2f (bio=%.1f, cap ×2.5)\n" % [rs_val, BiosphereEngine.biomasa]
		has_income_buff = true
	if LegacyManager.get_buff_value("aura_dorada"):
		income_section += "au  Aura Dorada            click ×2.50  [solo click]\n"; has_income_buff = true
	if LegacyManager.get_buff_value("semilla_cosmica"):
		income_section += "sc  Semilla Cósmica        click ×2.00 · pasivo ×2.00\n"; has_income_buff = true
	if LegacyManager.get_buff_value("mente_colmena"):
		income_section += "mc  Mente Colmena          pasivo ×3.00\n"; has_income_buff = true
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		var mg_active := StructuralModel.epsilon_runtime > 0.40
		var mg_state := "ACTIVO" if mg_active else "inactivo (ε=%.2f)" % StructuralModel.epsilon_runtime
		income_section += "mg  Metabolismo Oscuro     click ×1.50 · pasivo ×1.80  [%s]\n" % mg_state
		has_income_buff = true
	var eco_mult: float = LegacyManager.get_effect_value("all_income_mult")
	if eco_mult > 0.0:
		income_section += "ep  Eco Primordial         todos ×%.2f\n" % (1.0 + eco_mult); has_income_buff = true
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		var cc_val := 1.0 + LegacyManager.trascendencia_count * 0.05
		income_section += "cc  Convergencia Cíclica   todos ×%.2f (T=%d)\n" % [cc_val, LegacyManager.trascendencia_count]
		has_income_buff = true
	var cog_mult: float = LegacyManager.get_effect_value("cognitivo_income_mult_per_level")
	if cog_mult > 0.0:
		var cog_val := 1.0 + UpgradeManager.level("accounting") * cog_mult
		income_section += "rc  Resonancia Cognitiva   todos ×%.2f (nv.cog=%d)\n" % [cog_val, UpgradeManager.level("accounting")]
		has_income_buff = true
	if has_income_buff:
		t += income_section

	# --- LEGADO: DEFENSA OMEGA ---
	var has_omega_buff := false
	var omega_section := "\n--- LEGADO: Defensa Ω ---\n"
	if LegacyManager.get_buff_value("plasticidad_adaptativa"):
		omega_section += "Plasticidad Adaptativa    Ω_min inicio ≥ 0.30\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("legado_homeorresis"):
		omega_section += "Trascendencia Cristalina  Ω ≥ 0.55 (tick)\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("legado_alostasis"):
		omega_section += "Resiliencia Alostática    Ω_min +0.02/shock (acumulado: %d shocks)\n" % RunManager.disturbances_survived
		has_omega_buff = true
	var eq_per_dist: float = LegacyManager.get_effect_value("omega_min_per_disturbance")
	if eq_per_dist > 0.0:
		omega_section += "Equilibrio Heredado       Ω_min +%.2f/shock\n" % eq_per_dist; has_omega_buff = true
	var omega_rec: float = LegacyManager.get_effect_value("omega_recovery_speed")
	if omega_rec > 0.0:
		omega_section += "Setpoint Adaptativo       Ω_min regen ×%.2f/s\n" % omega_rec; has_omega_buff = true
	if LegacyManager.get_buff_value("cristalizacion_permanente"):
		omega_section += "Cristalización Permanente shock Ω_min −50%%\n"; has_omega_buff = true
	if has_omega_buff:
		t += omega_section

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

## Formato compacto de número con sufijo K/M/B
func format_compact(v: float) -> String:
	if v >= 1_000_000_000.0:
		return "%.2fB" % (v / 1_000_000_000.0)
	elif v >= 1_000_000.0:
		return "%.2fM" % (v / 1_000_000.0)
	elif v >= 1_000.0:
		return "%.1fK" % (v / 1_000.0)
	else:
		return "%.2f" % v

func epsilon_flag(v: float, limit: float) -> String:
	return "⚠️" if v > limit else "✅"

func build_evo_checklist(main: Node) -> String:
	# Si la run ya cerró, mostrar lore/resumen del final alcanzado en vez de la checklist
	if RunManager.run_closed:
		return _build_run_end_lore(RunManager.final_route)

	var t := "[color=cyan][b]--- Próxima transición ---[/b][/color]\n"
	var acc := UpgradeManager.level("accounting")
	var ch : String
	var ok_color := "[color=%s]" % AccessibilityManager.cok_hex()
	var fail_color := "[color=%s]" % AccessibilityManager.cno_hex()

	if EvoManager.mutation_homeostasis:
		var tier := RunManager.homeostasis_tier_reached
		# Tier 1 — HOMEOSTASIS
		if tier == 0:
			t += "[b][color=cyan]-- Tier 1: HOMEOSTASIS --[/color][/b]\n"
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
			t += "[b][color=aquamarine]-- Tier 2: ALLOSTASIS --[/color][/b]\n"
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
			t += "[b][color=gold]-- Tier 3: HOMEORHESIS --[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.extreme_shocks_recovered >= 1 else fail_color + "[ ] "
			t += ch + "Recuperarse de SHOCK EXTREMO (%d/1)[/color]\n" % RunManager.extreme_shocks_recovered
			ch = ok_color + "[x] " if RunManager.resilience_score >= 400.0 else fail_color + "[ ] "
			t += ch + "Resiliencia >= 400 (%d)[/color]\n" % int(RunManager.resilience_score)
			ch = ok_color + "[x] " if RunManager.omega_min_peak >= 0.50 else fail_color + "[ ] "
			t += ch + "Ω_min pico >= 0.50 (%s)[/color]\n" % snapped(RunManager.omega_min_peak, 0.01)
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 5 else fail_color + "[ ] "
			t += ch + "Perturbaciones (%d/5)[/color]\n" % RunManager.disturbances_survived
			var delta_real3 :float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real3 > 300.0 else fail_color + "[ ] "
			t += ch + "Metabolismo > 300/s (%s)[/color]\n" % snapped(delta_real3, 0.1)
			ch = ok_color + "[x] " if RunManager.run_time >= 1200.0 else fail_color + "[ ] "
			t += ch + "Run >= 20min (%s)[/color]\n" % format_time(RunManager.run_time)
		elif tier == 3:
			t += ok_color + "[x] Tier 3 HOMEORHESIS desbloqueado — sellá el final[/color]\n"
		t += "\n"

	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		t += "[b]Objetivo: Integración Mecánica[/b]\n"

		# Hito 1: Estabilidad
		var eps_ok: bool = StructuralModel.epsilon_runtime <= 0.25 or EvoManager.nucleo_conciencia
		ch = ok_color + "[x] " if eps_ok else fail_color + "[ ] "
		t += ch + "Estabilidad estructural (ε <= 0.25) (" + str(snapped(StructuralModel.epsilon_runtime, 0.01)) + ")[/color]\n"

		# Hito 2: Sincronización (Primordio normal O Mente Colmena NG+)
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

		# NG+ MENTE COLMENA — ruta alternativa cuando last_run == "SINGULARIDAD"
		if LegacyManager.last_run_ending == "SINGULARIDAD" or LegacyManager.last_run_ending == "MENTE COLMENA DISTRIBUIDA":
			t += "\n[color=magenta][b]🧠 Ruta NG+: MENTE COLMENA[/b][/color]\n"
			var mc_timer: float = RunManager.mente_colmena_timer
			var mc_active: bool = RunManager.mente_colmena_active
			if mc_active:
				t += ok_color + "[x] MENTE COLMENA DISTRIBUIDA — IA activa[/color]\n"
			elif mc_timer > 0.0:
				var mc_pct := int(mc_timer / 180.0 * 100.0)
				var filled := int(mc_pct / 5)   # 20 bloques = 100%
				var bar := ""
				for i in range(20):
					bar += "█" if i < filled else "░"
				t += "[color=cyan]>>> Sincronía 50/50: [%s] %d%% (%.0f/180s)[/color]\n" % [bar, mc_pct, mc_timer]
				# Mostrar ratio actual
				var ap :Dictionary = EconomyManager.get_active_passive_breakdown()
				var r_act := int(ap.activo)
				var r_pas := int(ap.pasivo)
				var ratio_color := "[color=cyan]" if abs(r_act - 50) <= 2 else "[color=yellow]"
				t += ratio_color + "    Ratio: %d%% Activo / %d%% Pasivo[/color]\n" % [r_act, r_pas]
			else:
				t += "[color=#aaaaaa]Mantené ratio 50%% Activo / 50%% Pasivo durante 180s[/color]\n"
				t += "[color=#aaaaaa](requiere ε ≤ 0.50)[/color]\n"

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
		ch = ok_color + "[x] " if RunManager.run_time > 200.0 else fail_color + "[ ] "
		t += ch + "Tiempo > 200 s  (%s)[/color]\n" % format_time(RunManager.run_time)

	elif EvoManager.mutation_symbiosis and not EvoManager.mutation_red_micelial:
		t += "[b][color=green]🌱 Simbiosis activa:[/color][/b]\n"
		t += "[color=gray]Sellá la run con el botón SELLAR SIMBIOSIS\no avanzá a Red Micelial para continuar.[/color]\n"

	elif not EvoManager.mutation_red_micelial and not EvoManager.mutation_homeostasis \
		and not EvoManager.mutation_hyperassimilation and not EvoManager.mutation_parasitism \
		and not EvoManager.mutation_symbiosis:
		var ap_snap = EconomyManager.get_active_passive_breakdown()
		var pasivo_domina = ap_snap.pasivo > ap_snap.activo
		var activo_domina = ap_snap.activo > ap_snap.pasivo
		t += "[b]🕸️ Red Micelial (Fase A):[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 11.5 else fail_color + "[ ] "
		t += ch + "Hifas >= 12  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (" + str(snapped(BiosphereEngine.biomasa, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.epsilon_runtime < 0.65 else fail_color + "[ ] "
		t += ch + "ε_runtime < 0.65  (" + str(snapped(StructuralModel.epsilon_runtime, 0.01)) + ")[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + "Contabilidad >= 1  (nivel: " + str(acc) + ")[/color]\n"
		ch = ok_color + "[x] " if pasivo_domina else fail_color + "[ ] "
		t += ch + "Pasivos > Activos  (" + str(int(ap_snap.pasivo)) + "% vs " + str(int(ap_snap.activo)) + "%)[/color]\n"
		t += "\n[b]🌱 Simbiosis:[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 5.0 else fail_color + "[ ] "
		t += ch + "Hifas >= 5  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.omega >= 0.40 else fail_color + "[ ] "
		t += ch + "Ω >= 0.40  (" + str(snapped(StructuralModel.omega, 0.01)) + ")[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + "Contabilidad >= 1  (nivel: " + str(acc) + ")[/color]\n"
		ch = ok_color + "[x] " if activo_domina else fail_color + "[ ] "
		t += ch + "Activos > Pasivos  (" + str(int(ap_snap.activo)) + "% vs " + str(int(ap_snap.pasivo)) + "%)[/color]\n"

	if not EvoManager.mutation_homeostasis and not EvoManager.mutation_hyperassimilation \
		and not EvoManager.mutation_sporulation and not EvoManager.mutation_red_micelial \
		and not EvoManager.mutation_symbiosis:
		t += "\n[color=gray]Homeostasis (Tier 1):[/color]\n"
		ch = ok_color + "[x] " if RunManager.get_en_banda_homeostatica() else fail_color + "[ ] "
		t += ch + "Banda 0.03 < ε < 0.30  (%s)[/color]\n" % snapped(StructuralModel.epsilon_effective, 0.01)
		ch = ok_color + "[x] " if StructuralModel.omega > 0.25 else fail_color + "[ ] "
		t += ch + "Flexib. Ω > 0.25  (%s)[/color]\n" % snapped(StructuralModel.omega, 0.01)
		ch = ok_color + "[x] " if BiosphereEngine.biomasa < 12.0 else fail_color + "[ ] "
		t += ch + "Biomasa < 12  (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)
		ch = ok_color + "[x] " if EconomyManager.delta_per_sec > 30.0 else fail_color + "[ ] "
		t += ch + "Metabolismo > 30/s (%s)[/color]\n" % snapped(EconomyManager.delta_per_sec, 0.1)
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
			"lore": "Equilibrio activo sostenido. El sistema reguló sus variables internas — ε en banda, Ω balanceado, flujos duales. La entropía fue domesticada, no eliminada.",
			"buffs": ["Toda la producción +50% — click y pasivo (Orden Administrativo)", "Ω_min 0.35 — seguridad estructural base", "Evita pérdidas grandes ante perturbaciones", "+3 PL ganados"],
			"nerfs": ["Cap de crecimiento biológico (biomasa < 12)", "Requiere ε en banda + Ω ≥ 0.40 + flujos duales (activo y pasivo)", "Velocidad de scaling reducida"]
		},
		"ALLOSTASIS": {
			"emoji": "💜", "color": "#aa55ff",
			"lore": "Adaptación dinámica a nuevos estados de equilibrio. El hongo sobrevivió perturbaciones y aprendió a recalibrar su setpoint. El equilibrio ya no es un punto: es una trayectoria.",
			"buffs": ["Setpoint adaptativo — resiliencia +80% dinámica", "Ω_min >= 0.45 permanente en próxima run", "Impulso Metabólico Adaptativo: pasivo ×5", "+6 PL ganados"],
			"nerfs": ["Requiere haber sobrevivido ≥1 perturbación activa", "Requiere Resiliencia ≥ 150 + Δ$ > 200/s + Cont. nivel 2"]
		},
		"HOMEORHESIS": {
			"emoji": "💎", "color": "#00ffee",
			"lore": "Equilibrio dinámico avanzado. El sistema atravesó 5+ ciclos de perturbación sin colapso y alcanzó auto-regulación en trayectorias de cambio continuo. Más allá de la homeostasis.",
			"buffs": ["Trascendencia cristalina — metabolismo irreversible", "Desbloquea legado permanente de Allostasis", "Mayor resiliencia base en NG+ (Ω_min bonus)", "+8 PL ganados"],
			"nerfs": ["Requiere ≥5 perturbaciones + recuperarse de shock extremo", "Resiliencia ≥ 400 + Δ$ > 300/s + Ω_min ≥ 0.50", "Extremadamente difícil de sostener"]
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
		# ── FRACTURA EPISTÉMICA ──────────────────────────────────────────────────
		"COLAPSO CONTROLADO": {
			"emoji": "⚡", "color": "#ff6622",
			"lore": "El sistema llegó al límite epistémico — ε extremo, pero Ω mantenida. En vez de colapsar pasivamente, el jugador dirigió la fractura. El conocimiento se rompe, pero deja semillas.",
			"buffs": ["+6 PL base (Fractura Epistémica)", "+PL extra × ε_peak (si tenés Colapso Controlado en Banco Genético)", "Cierre voluntario — sin sorpresas"],
			"nerfs": ["Requiere Fractura Epistémica (Banco Cósmico T3)", "Condición: ε_effective > 0.90 con Ω > 0.30", "Requiere haber desbloqueado la ruta Hiperasimilación + Horizonte Estructural previamente"]
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

# =====================================================
#  BUILDERS DE TEXTO — Genoma y Mutaciones
#  (Movidos desde main.gd para centralizar builders UI)
# =====================================================

func build_genome_text() -> String:
	var t := ""
	# Ruta post-trascendencia activa
	if RunManager.vacio_hambriento_active:
		t += "[b][color=#bb44ff]🕳️ VACÍO HAMBRIENTO — producción ×100[/color][/b]\n"
		t += "[color=#888888]Buffs cósmicos consumidos permanentemente.[/color]\n"
		var _gen: float = EconomyManager.money
		var _run_t: float = RunManager.run_time
		t += "[color=#9955dd]--- ASCESIS PROFUNDA ---[/color]\n"
		if _gen < 1000000.0:
			t += "[color=#666666]Acumulá $1M (%.0f/1000000)[/color]\n\n" % _gen
		elif _run_t < 900.0:
			t += "[color=#666666]Aguantá 15min de run (%.0fs/900s)[/color]\n\n" % _run_t
		else:
			var bio_ok: bool = BiosphereEngine.biomasa < 0.5
			var sin_p: bool = UpgradeManager.level("auto") == 0 and UpgradeManager.level("trueque") == 0
			var eps_ok: bool = StructuralModel.epsilon_runtime < 0.25
			var bio_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if bio_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var pas_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if sin_p else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var eps_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if eps_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			t += "Bio: " + bio_s + "  Pasivo: " + pas_s + "  e: " + eps_s + "\n"
			var prog: float = clamp(RunManager.ascesis_timer / float(RunManager.ASCESIS_DURATION), 0.0, 1.0)
			var filled: int = int(prog * 20)
			var bar: String = "[" + "X".repeat(filled) + ".".repeat(20 - filled) + "]"
			t += bar + " %ds/%ds\n\n" % [int(RunManager.ascesis_timer), RunManager.ASCESIS_DURATION]
	elif RunManager.carnaval_active and not RunManager.carnaval_mutations.is_empty():
		var idx := RunManager.carnaval_index
		var muts := RunManager.carnaval_mutations
		t += "[b][color=#ff8833]🎭 CARNAVAL DE MUTACIONES[/color][/b]\n"
		t += "Rotación: [color=#ffaa55]%s[/color] → %s → %s\n" % [muts[idx], muts[(idx+1)%3], muts[(idx+2)%3]]
		var secs_left := int(RunManager.CARNAVAL_INTERVAL - RunManager.carnaval_timer)
		t += "[color=#888888]Próxima rotación en %ds[/color]\n" % secs_left
		var rot := RunManager.carnaval_total_rotations
		var peak := RunManager.carnaval_peak_money
		t += "[color=#ffdd44]Rotaciones: %d/12 (Polimorfía) | Dinero pico: $%.0fK (Domador)[/color]\n\n" % [rot, peak/1000.0]
	elif RunManager.reencarnacion_active:
		t += "[b][color=#44ee99]⚱️ REENCARNACIÓN HEREDADA[/color][/b]\n"
		t += "[color=#888888]Upgrades heredados del ciclo anterior. Costos escalan ×1.5 extra.[/color]\n\n"
	t += "🧬 GENOMA FÚNGICO\n"
	t += "Hiperasimilación: " + EvoManager.genome.hiperasimilacion + "\n"
	t += "Parasitismo: " + EvoManager.genome.parasitismo + "\n"
	t += "Red micelial: " + EvoManager.genome.red_micelial + "\n"
	t += "Esporulación: " + EvoManager.genome.esporulacion + "\n"
	t += "Simbiosis: " + EvoManager.genome.simbiosis + "\n"
	var dep_state: String = EvoManager.genome.get("depredador", "dormido")
	if dep_state != "dormido" or EvoManager.mutation_depredador:
		t += "Depredador: " + dep_state + "\n"
	var mo_state: String = EvoManager.genome.get("met_oscuro", "dormido")
	if mo_state != "dormido" or EvoManager.mutation_met_oscuro:
		t += "Met.Oscuro: " + mo_state + "\n"

	if EvoManager.mutation_met_oscuro:
		t += "[b][color=#8844aa]🌑 METABOLISMO OSCURO (Post-Depredador):[/color][/b]\n"
		t += "[color=#00ff00]+ Pasivo = Bio × 0.8/s · Click ×3 · Biomasa autoalimentada[/color]\n"
		t += "[color=#ff4444]- Upgrades bloqueados · Ω 0.10 · Devorar detenido[/color]\n"
	elif EvoManager.mutation_depredador:
		t += "[b][color=#ff0055]☠️ DEPREDADOR DE REALIDADES:[/color][/b]\n"
		t += "[color=#00ff00]+ Devora upgrade cada 1.5s (+15 biomasa)[/color]\n"
		t += "[color=#ff4444]- Agotar upgrades cierra la run[/color]\n"
	elif EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ HIPERASIMILACIÓN (Active Rush):[/color][/b]\n"
		t += "[color=#00ff00]+ Sobrecarga Click PUSH x10.0[/color]\n"
		t += "[color=#ff4444]- Producción pasiva atrofiada (-75%)[/color]\n"
		t += "[color=#ff4444]- Colapso persistencia inminente[/color]\n"
	elif EvoManager.genome.hiperasimilacion == "latente":
		t += "\n[color=gray]• Hiperasimilación (LATENTE)[/color]"

	if EvoManager.mutation_met_oscuro:
		t += "\n🌑 Ruta evolutiva: METABOLISMO OSCURO"
	elif EvoManager.mutation_depredador:
		t += "\n☠️ Ruta evolutiva: DEPREDADOR DE REALIDADES"
	elif EvoManager.mutation_homeostasis:
		t += "\n⚖️ Ruta evolutiva: HOMEOSTASIS"
	elif EvoManager.mutation_hyperassimilation:
		t += "\n⚠️ Ruta evolutiva: HIPERASIMILACIÓN"
	elif EvoManager.mutation_symbiosis:
		t += "\n🌱 Ruta evolutiva: SIMBIOSIS"
	elif EvoManager.mutation_parasitism:
		t += "\n🦠 Ruta evolutiva: PARASITISMO"

	if RunManager.run_closed:
		t += "\n\n🏁 FINAL ALCANZADO: " + RunManager.final_route
	return t

func build_mutation_status_text() -> String:
	var t := "\n[color=#aaaaaa]--- Efectos mutacionales activos ---[/color]\n"
	var buff := "[color=#00ff00]+"
	var nerf := "[color=#ff4444]-"

	if EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ HIPERASIMILACIÓN (RUSH):[/color][/b]\n"
		t += buff + " Sobrecarga Click PUSH x10.0[/color]\n"
		t += nerf + " Pasivo -75% / Fragilidad Ω[/color]\n"

	if EvoManager.mutation_homeostasis:
		t += "[b][color=cyan]⚖️ HOMEOSTASIS:[/color][/b]\n"
		t += buff + " Toda la producción +50% — click y pasivo (Orden Administrativo)[/color]\n"
		t += buff + " Estabilidad ε (runtime reducido)[/color]\n"
		t += buff + " Ω_min 0.35 (Seguridad estructural)[/color]\n"
		t += nerf + " Limitación Biomasa (crecimiento controlado)[/color]\n"

	if EvoManager.mutation_symbiosis:
		t += "[b][color=green]🌱 SIMBIOSIS ESTRUCTURAL:[/color][/b]\n"
		t += buff + " Potencia Click PUSH ×2.5 (Domino Activo)[/color]\n"
		t += nerf + " Producción Pasiva -50% (Atrofia Autómata)[/color]\n"

	if EvoManager.mutation_red_micelial:
		t += "[b][color=#9955ff]🕸️ RED MICELIAL:[/color][/b]\n"
		t += buff + " Producción Pasiva TOTAL ×2.5 (Heptasíntesis)[/color]\n"
		t += nerf + " Potencia Click PUSH -50% (Desconexión Motora)[/color]\n"

	if EvoManager.mutation_met_oscuro:
		t += "[b][color=#8844aa]🌑 METABOLISMO OSCURO:[/color][/b]\n"
		t += buff + " Pasivo = Biomasa × 0.8 /s (bioquímica oscura)[/color]\n"
		t += buff + " Click PUSH ×3 (energía alternativa)[/color]\n"
		t += buff + " Biomasa autoalimentada +0.1/s[/color]\n"
		t += buff + " ε_runtime decae -0.05/s (autorregulación)[/color]\n"
		t += nerf + " Devorar DETENIDO (estabilización)[/color]\n"
		t += nerf + " Upgrades bloqueados (no se pueden comprar)[/color]\n"
		t += nerf + " Ω forzado a 0.10 (fragilidad permanente)[/color]\n"
		t += nerf + " Pasivo estructural anulado[/color]\n"
		# Progress bar de saturación hacia el cierre automático (+6 PL)
		var bio_now: float = BiosphereEngine.biomasa
		var bio_pct: int = int(clamp(bio_now / 100.0 * 100.0, 0.0, 100.0))
		var bar_filled: int = int(bio_pct / 5)  # 20 segmentos
		var bio_bar: String = "█".repeat(bar_filled) + "░".repeat(20 - bar_filled)
		var pl_label: String = "+6 PL" if bio_now >= 100.0 else ("+4 PL" if bio_now >= 50.0 else "+2 PL")
		t += "\n[color=#aa66cc]◈ SATURACIÓN (sellado manual: %s):[/color]\n" % pl_label
		t += "[color=#8844aa][%s][/color] [color=white]%.0f / 100[/color]\n" % [bio_bar, bio_now]
		t += "[color=#666688]  Sellado manual disponible tras 2min · Saturación auto (+6PL) · $1M auto (+4PL)[/color]\n"
	elif EvoManager.mutation_depredador:
		t += "[b][color=#ff0055]☠️ DEPREDADOR DE REALIDADES:[/color][/b]\n"
		t += buff + " Devora upgrade cada 1.5s (+15 biomasa cada uno)[/color]\n"
		t += nerf + " Agotar upgrades cierra la run[/color]\n"
		var dev: int = EvoManager.met_oscuro_devoured_count
		var bio: float = BiosphereEngine.biomasa
		var money_now: float = EconomyManager.money
		var d_ok: bool = dev >= 3
		var b_ok: bool = bio >= 25.0
		var r_ok: bool = money_now < 1000.0
		t += "\n[color=#aa66cc]◈ RUTA ALTERNATIVA — MET.OSCURO (Depredación + Recursos críticos):[/color]\n"
		t += "  [color=%s]Devorados ≥ 3 → %d[/color]\n" % ["#00ff88" if d_ok else "#ff5555", dev]
		t += "  [color=%s]Biomasa ≥ 25 → %.1f[/color]\n" % ["#00ff88" if b_ok else "#ff5555", bio]
		t += "  [color=%s]$ crítico < 1000 → $%.0f[/color]\n" % ["#00ff88" if r_ok else "#ff5555", money_now]
		t += "  [color=#aaaaaa]Sostener 15s para activar bioquímica oscura[/color]\n"

	if EvoManager.mutation_parasitism:
		t += "[b][color=#ff4400]🦠 PARASITISMO:[/color][/b]\n"
		t += buff + " Biomasa ×2 (crecimiento descontrolado)[/color]\n"
		t += buff + " Pasivo +20%[/color]\n"
		t += nerf + " Drenaje de dinero = Biomasa × 0.25 / s[/color]\n"
		t += nerf + " Corrosión de infraestructura (irreversible)[/color]\n"
		t += nerf + " Contabilidad -10% / Ω máx 0.25[/color]\n"
		var bio: float = BiosphereEngine.biomasa
		var omg: float = StructuralModel.omega
		var eps: float = StructuralModel.epsilon_effective
		var money: float = EconomyManager.money
		t += "\n[color=#ffaa00]◈ CIERRE (opción A):[/color]\n"
		var a1: bool = bio >= 18.0
		var a2: bool = omg < 0.22
		var a3: bool = eps > 0.45
		t += "  [color=%s]Bio ≥ 18 → %.1f[/color]\n" % ["#00ff88" if a1 else "#ff5555", bio]
		t += "  [color=%s]Ω < 0.22 → %.2f[/color]\n" % ["#00ff88" if a2 else "#ff5555", omg]
		t += "  [color=%s]ε > 0.45 → %.2f[/color]\n" % ["#00ff88" if a3 else "#ff5555", eps]
		t += "[color=#ffaa00]◈ CIERRE (opción B):[/color]\n"
		var b1: bool = bio >= 15.0
		var b2: bool = money < 1000.0
		var b3: bool = bio >= 25.0
		t += "  [color=%s]Bio ≥ 15 + $ < 1000 → %.0f / $%.0f[/color]\n" % ["#00ff88" if (b1 and b2) else "#ff5555", bio, money]
		t += "  [color=%s]  ó Bio ≥ 25 → %.1f[/color]\n" % ["#00ff88" if b3 else "#ff5555", bio]
	return t

func build_institution_panel_text(main: Node) -> String:
	var t := "--- Contabilidad Básica ---\n"
	t += "\n--- ε desglosado (Homeostasis) ---\n"
	t += "%s ε activo = %s\n" % [epsilon_flag(StructuralModel.epsilon_active, 0.15), snapped(StructuralModel.epsilon_active, 0.01)]
	t += "%s ε pasivo = %s\n" % [epsilon_flag(StructuralModel.epsilon_passive, 0.12), snapped(StructuralModel.epsilon_passive, 0.01)]
	t += "%s ε complejidad = %s\n" % [epsilon_flag(StructuralModel.epsilon_complex, 0.08), snapped(StructuralModel.epsilon_complex, 0.01)]
	t += "Ω_min = %s\n" % snapped(StructuralModel.omega_min, 0.01)
	t += "Contabilidad = nivel %d\n" % UpgradeManager.level("accounting")
	t += "Amortiguación = %d%%\n" % int(StructuralModel.get_accounting_effect() * 100.0)
	t += "\nε_peak = %s\n" % snapped(StructuralModel.epsilon_peak, 0.01)
	return t

## Actualiza el panel de mutación en la columna central (genoma + ruta + efectos + checklist)
func update_mutation_center_panel(main: Node = null) -> void:
	if not is_instance_valid(genome_summary_label):
		genome_summary_label = _find("GenomeSummaryLabel")
		if not is_instance_valid(genome_summary_label):
			return
	var t := build_genome_text()
	if not RunManager.run_closed:
		t += build_mutation_status_text()
	if RunManager.homeostasis_mode:
		t += "\n\n⚖️ HOMEOSTASIS MODE"
		t += "\nResiliencia = %s" % snapped(RunManager.resilience_score, 1)
		t += "\nPerturbaciones cada %ds" % RunManager.DISTURBANCE_INTERVAL
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2:
		t += "\n⚠️ La red no puede estabilizarse localmente"
	if main != null:
		t += build_evo_checklist(main)
	genome_summary_label.visible = true
	genome_summary_label.clear()
	genome_summary_label.append_text(EmojiToRichText.rich(t))

# =====================================================
# BIFURCATION PANEL DATA BUILDER
# =====================================================
func build_bifurcation_data() -> Dictionary:
	var hifas = BiosphereEngine.hifas
	var acc_lvl = UpgradeManager.level("accounting")
	var act_domina = EconomyManager.get_active_passive_breakdown().activo > EconomyManager.get_active_passive_breakdown().pasivo

	var data := {
		# Simbiosis sin Red Micelial → sigue siendo tier1 (no tiene sub-ramas propias)
		"tier_mode": "tier1" if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis) else ("tier2_homeostasis" if EvoManager.mutation_homeostasis else "tier2_branches")
	}

	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis):
		data["header"] = "MUTACIÓN DETECTADA (TIER 1)"

		var h_t := LegacyManager.trascendencia_count
		var h_ap: Dictionary = EconomyManager.get_active_passive_breakdown()
		var h_ok_red = StructuralModel.unlocked_d and StructuralModel.unlocked_e
		var h_txt := "[center]⚖️ HOMEOSTASIS\nEquilibrio activo sostenido.\n\n"

		if h_t >= 1:
			# NG+: condiciones más exigentes
			var eps_eff := StructuralModel.epsilon_effective
			var h_ok_eps_ng = eps_eff >= 0.05 and eps_eff <= 0.25
			var h_ok_omega_ng = StructuralModel.omega >= 0.55
			var h_ok_acc_ng = acc_lvl >= 2
			var h_ok_delta_ng = EconomyManager.delta_per_sec > 150.0
			var total_flow: float = float(h_ap["activo"]) + float(h_ap["pasivo"])
			var h_ok_bal = total_flow > 0 and (float(h_ap["pasivo"]) / total_flow) >= 0.30
			var h_ok_bio_ng = BiosphereEngine.biomasa >= 1.0 and BiosphereEngine.biomasa < 10.0
			h_txt += "[color=#ff8800][NG+] Requisitos de equilibrio estrictos[/color]\n\n"
			h_txt += "[color=%s]%s 0.05 < ε < 0.25 (banda NG+)[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_eps_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_eps_ng else "[ ]"]
			h_txt += "[color=%s]%s Equilibrio Ω ≥ 0.55[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_omega_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_omega_ng else "[ ]"]
			h_txt += "[color=%s]%s Balance pasivo ≥ 30%% del flujo[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_bal else AccessibilityManager.cno_hex(), "[x]" if h_ok_bal else "[ ]"]
			h_txt += "[color=%s]%s Producción > 150/s[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_delta_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_delta_ng else "[ ]"]
			h_txt += "[color=%s]%s Biomasa 1.0–10.0[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_bio_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_bio_ng else "[ ]"]
			h_txt += "[color=%s]%s Contabilidad >= 2[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_acc_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_acc_ng else "[ ]"]
			h_txt += "[color=%s]%s Trabajo y Trueque (d+e)[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_red else AccessibilityManager.cno_hex(), "[x]" if h_ok_red else "[ ]"]
		else:
			var h_ok_eps = RunManager.get_en_banda_homeostatica()
			var h_ok_omega = StructuralModel.omega >= 0.40
			var h_ok_delta = EconomyManager.delta_per_sec > 30.0
			var h_ok_bio = BiosphereEngine.biomasa < 12.0
			var h_ok_acc = acc_lvl >= 1
			var h_ok_dual = h_ap["pasivo"] > 0
			h_txt += "[color=%s]%s 0.03 < ε < 0.30 (banda)[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_eps else AccessibilityManager.cno_hex(), "[x]" if h_ok_eps else "[ ]"]
			h_txt += "[color=%s]%s Equilibrio Ω ≥ 0.40[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_omega else AccessibilityManager.cno_hex(), "[x]" if h_ok_omega else "[ ]"]
			h_txt += "[color=%s]%s Flujos duales (activo + pasivo)[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_dual else AccessibilityManager.cno_hex(), "[x]" if h_ok_dual else "[ ]"]
			h_txt += "[color=%s]%s Metabolismo > 30/s[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_delta else AccessibilityManager.cno_hex(), "[x]" if h_ok_delta else "[ ]"]
			h_txt += "[color=%s]%s Biomasa < 12[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_bio else AccessibilityManager.cno_hex(), "[x]" if h_ok_bio else "[ ]"]
			h_txt += "[color=%s]%s Contabilidad >= 1[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_acc else AccessibilityManager.cno_hex(), "[x]" if h_ok_acc else "[ ]"]
			h_txt += "[color=%s]%s Trabajo y Trueque (d+e)[/color]\n" % [AccessibilityManager.cok_hex() if h_ok_red else AccessibilityManager.cno_hex(), "[x]" if h_ok_red else "[ ]"]

		if EvoManager.mutation_homeostasis and RunManager.homeostasis_timer > 0.1:
			var ratio = min(RunManager.homeostasis_timer / RunManager.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0
			h_txt += "\n[color=#ffff00]Estabilizando... %d%%[/color][/center]" % int(ratio)
		else:
			h_txt += "\n[color=#555555]Requiere sostenerse por 18s tras activarse.[/color][/center]"

		data["homeostasis_text"] = h_txt
		data["homeostasis_ready"] = EvoManager.is_homeostasis_ready()

		var r_ok_hifas = hifas >= 11.5
		var r_ok_bio = BiosphereEngine.biomasa >= 5.0
		var r_ok_eps = StructuralModel.epsilon_runtime < 0.65
		var r_ok_acc = acc_lvl >= 1
		var r_ok_dom = not act_domina

		var r_txt = "[center]🕸️ RED MICELIAL\nExpansión pasiva.\n\n"
		r_txt += "[color=%s]%s Hifas >= 11.5[/color]\n" % [AccessibilityManager.cok_hex() if r_ok_hifas else AccessibilityManager.cno_hex(), "[x]" if r_ok_hifas else "[ ]"]
		r_txt += "[color=%s]%s Biomasa >= 5.0[/color]\n" % [AccessibilityManager.cok_hex() if r_ok_bio else AccessibilityManager.cno_hex(), "[x]" if r_ok_bio else "[ ]"]
		r_txt += "[color=%s]%s ε < 0.65[/color]\n" % [AccessibilityManager.cok_hex() if r_ok_eps else AccessibilityManager.cno_hex(), "[x]" if r_ok_eps else "[ ]"]
		r_txt += "[color=%s]%s Contabilidad >= 1[/color]\n" % [AccessibilityManager.cok_hex() if r_ok_acc else AccessibilityManager.cno_hex(), "[x]" if r_ok_acc else "[ ]"]
		r_txt += "[color=%s]%s Dominio Pasivo[/color][/center]" % [AccessibilityManager.cok_hex() if r_ok_dom else AccessibilityManager.cno_hex(), "[x]" if r_ok_dom else "[ ]"]

		data["red_micelial_text"] = r_txt
		data["red_micelial_ready"] = EvoManager.is_red_micelial_ready()

		var s_ok_hifas = hifas >= 5.0
		var s_ok_eps = StructuralModel.epsilon_runtime >= 0.15 and StructuralModel.epsilon_runtime <= 0.45
		var s_ok_acc = acc_lvl >= 1
		var s_ok_dom = act_domina

		var s_txt = "[center]🌱 SIMBIOSIS\nFusión activa.\n\n"
		s_txt += "[color=%s]%s Hifas >= 5.0[/color]\n" % [AccessibilityManager.cok_hex() if s_ok_hifas else AccessibilityManager.cno_hex(), "[x]" if s_ok_hifas else "[ ]"]
		s_txt += "[color=%s]%s ε (0.15 - 0.45)[/color]\n" % [AccessibilityManager.cok_hex() if s_ok_eps else AccessibilityManager.cno_hex(), "[x]" if s_ok_eps else "[ ]"]
		s_txt += "[color=%s]%s Contabilidad >= 1[/color]\n" % [AccessibilityManager.cok_hex() if s_ok_acc else AccessibilityManager.cno_hex(), "[x]" if s_ok_acc else "[ ]"]
		s_txt += "[color=%s]%s Dominio Click[/color][/center]" % [AccessibilityManager.cok_hex() if s_ok_dom else AccessibilityManager.cno_hex(), "[x]" if s_ok_dom else "[ ]"]

		data["simbiosis_text"] = s_txt
		data["simbiosis_ready"] = EvoManager.is_simbiosis_ready()

	elif EvoManager.mutation_homeostasis:
		data["header"] = "TRANSICIÓN ALOSTÁTICA (TIER 2)"
		var works = EvoManager.is_allostasis_ready()

		var h_txt = "[center]🌪️ ALLOSTASIS\nRegulación Dinámica del Sistema.\n\n"
		h_txt += "[color=#00ff00]+ Ingresos Globales x3.0[/color]\n"
		h_txt += "[color=#00ff00]+ Estabilidad Adaptativa (Ω buffer)[/color]\n"
		h_txt += "[color=#ff4444]- Exige Metabolismo > 200/s[/color]\n"
		h_txt += "[color=#ff4444]- Fragilidad por Complejidad[/color][/center]"

		data["allostasis_text"] = h_txt
		data["allostasis_ready"] = works

	else:
		data["header"] = "BIFURCACIÓN DEL GENOMA"

		var col_txt = "[center]🦠 COLONIZACIÓN INVASIVA\nRama biológica.\n\n" + \
			"[color=#00ff00]+ Trabajo Manual x1.5[/color]\n" + \
			"[color=#00ff00]+ Ciclo Primordio → Seta → Esporulación[/color]\n" + \
			"[color=#ffaa00]Sin requisitos extra[/color][/center]"
		data["colonization_text"] = col_txt
		data["colonization_ready"] = true

		var has_mechanics = UpgradeManager.level("accounting") >= 2
		var mec_txt = "[center]🔬 SIMBIOSIS MECÁNICA\nRama hardware.\n\n" + \
			"[color=#00ff00]+ Ω_min 0.50 (estabilidad)[/color]\n" + \
			"[color=#00ff00]+ Núcleo de Conciencia → SINGULARIDAD[/color]\n" + \
			("[color=%s]✓ Contabilidad ≥ 2[/color]" % AccessibilityManager.cok_hex() if has_mechanics else "[color=%s]✗ Requiere Contabilidad nvl 2[/color]" % AccessibilityManager.cno_hex()) + \
			"[/center]"
		data["symbiosis_text"] = mec_txt
		data["symbiosis_ready"] = has_mechanics

	return data

# =====================================================
# EPSILON STICKY LABEL BUILDER
# =====================================================
func build_epsilon_sticky_text(main: Control) -> String:
	var t := ""
	t += "%s ε runtime = %s\n" % [epsilon_flag(StructuralModel.epsilon_runtime, 0.30), snapped(StructuralModel.epsilon_runtime, 0.01)]
	t += "Ω = %s (%s)\n" % [snapped(StructuralModel.omega, 0.01), get_system_phase(StructuralModel.omega)]
	t += "Presión = %s" % snapped(StructuralModel.get_structural_pressure(), 1)

	# DEPREDADOR — siempre visible si venís de PARASITISMO con hiperasimilación
	var hiper_genome: String = EvoManager.genome.get("hiperasimilacion", "")
	var depredador_eligible: bool = LegacyManager.last_run_ending == "PARASITISMO" \
		and (EvoManager.mutation_hyperassimilation or hiper_genome == "activo" or hiper_genome == "latente")
	if depredador_eligible and not EvoManager.mutation_depredador:
		if EvoManager.depredador_timer > 0.0:
			var pct := EvoManager.depredador_timer / 30.0
			var filled := int(pct * 16)
			var bar := "█".repeat(filled) + "░".repeat(16 - filled)
			t += "\n\n☠️ DEPREDADOR [%s] %d%%" % [bar, int(pct * 100)]
			t += "\nε %.2f · %.0f/30s" % [StructuralModel.epsilon_runtime, EvoManager.depredador_timer]
		else:
			var eps_ok: bool = StructuralModel.epsilon_runtime > 0.95
			t += "\n\n☠️ DEPREDADOR DISPONIBLE"
			t += "\nHIPER: %s · ε %.2f%s" % [
				hiper_genome.to_upper(),
				StructuralModel.epsilon_runtime,
				" ✓" if eps_ok else " → necesita > 0.95"
			]

	# MET.OSCURO — evaluable durante Depredador activo
	if EvoManager.mutation_depredador and not EvoManager.mutation_met_oscuro:
		var bio := BiosphereEngine.biomasa
		var dev := EvoManager.met_oscuro_devoured_count
		var mt := EvoManager.met_oscuro_timer
		var req := EvoManager.MET_OSCURO_REQUIRED_TIME
		if mt > 0.0:
			var pct := mt / req
			var filled := int(pct * 16)
			var bar := "█".repeat(filled) + "░".repeat(16 - filled)
			t += "\n\n🌑 MET.OSCURO [%s] %d%%" % [bar, int(pct * 100)]
			t += "\nEstabilizando %.1f/%ds" % [mt, int(req)]
		else:
			var d_ok: bool = dev >= 3
			var b_ok: bool = bio >= 25.0
			var r_ok: bool = EconomyManager.money < 1000.0
			t += "\n\n🌑 MET.OSCURO DISPONIBLE"
			t += "\nDev:%d/3%s · Bio:%.0f/25%s · $:%.0f<1k%s" % [
				dev, " ✓" if d_ok else "",
				bio, " ✓" if b_ok else "",
				EconomyManager.money, " ✓" if r_ok else ""
			]
	elif EvoManager.mutation_met_oscuro:
		t += "\n\n🌑 MET.OSCURO ACTIVO"
		t += "\nBio %.1f · Pasivo %.1f/s" % [BiosphereEngine.biomasa, BiosphereEngine.biomasa * 0.8]
		t += "\nCierre auto: Bio≥100 o $≥1M"

	return t

# =====================================================
# PANEL DE BIFURCACIÓN Y BARRA DE CICLO FÚNGICO
# =====================================================

func update_bifurcation_panel() -> void:
	if not is_instance_valid(evo_choice_panel) or not evo_choice_panel.visible:
		return

	var data := build_bifurcation_data()

	evo_choice_panel.get_node("Margin/VBox/TopBar/Header").text = data["header"]

	if data["tier_mode"] == "tier1":
		opt_homeostasis.visible = true
		opt_colonization.visible = true
		opt_symbiosis.visible = true

		opt_homeostasis.find_child("Desc").text = data["homeostasis_text"]
		btn_homeostasis.text = "Equilibrar"
		btn_homeostasis.disabled = not data["homeostasis_ready"]

		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = data["red_micelial_text"]
		btn_colonization.text = "Ramificar"
		btn_colonization.disabled = not data["red_micelial_ready"]

		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = data["simbiosis_text"]
		btn_symbiosis.text = "Fusionar"
		btn_symbiosis.disabled = not data["simbiosis_ready"]

	elif data["tier_mode"] == "tier2_homeostasis":
		opt_homeostasis.visible = true
		opt_colonization.visible = false
		opt_symbiosis.visible = false

		opt_homeostasis.find_child("Desc").text = data["allostasis_text"]
		btn_homeostasis.text = "¡EVOLUCIONAR!" if data["allostasis_ready"] else "[REQUISITOS NO MET]"
		btn_homeostasis.disabled = not data["allostasis_ready"]
		btn_homeostasis.modulate = Color(0, 1, 1)

	else:
		opt_homeostasis.visible = false
		opt_colonization.visible = true
		opt_symbiosis.visible = true

		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = data["colonization_text"]
		btn_colonization.text = "Colonizar"
		btn_colonization.disabled = not data["colonization_ready"]

		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = data["symbiosis_text"]
		btn_symbiosis.disabled = not data["symbiosis_ready"]
		btn_symbiosis.text = "Integrar Hardware [req. Cont. 2]" if not data["symbiosis_ready"] else "Integrar Hardware"

func update_fungal_cycle_bar() -> void:
	var bar = fungal_cycle_bar

	if EvoManager.red_branch_selected != EvoManager.RedBranch.NONE:
		if is_instance_valid(bar):
			bar.visible = (EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION)
			if bar.visible:
				bar.value = BiosphereEngine.micelio
				if EvoManager.seta_formada:
					bar.tooltip_text = "CICLO COMPLETADO: SETA MADURA"
					bar.value = 100.0
				elif EvoManager.primordio_active:
					var t_left := EvoManager.PRIMORDIO_DURATION - EvoManager.primordio_timer
					bar.tooltip_text = "PRIMORDIO ACTIVO — %.0fs restantes" % t_left
				else:
					bar.tooltip_text = "Micelio: %d%%  — Ciclo Biológico Activo" % int(BiosphereEngine.micelio)

		if is_instance_valid(primordio_button):
			if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
				var puede_iniciar := BiosphereEngine.micelio >= 60.0 and not EvoManager.primordio_active and not EvoManager.seta_formada
				primordio_button.visible = not EvoManager.seta_formada
				primordio_button.disabled = not puede_iniciar
				if EvoManager.primordio_active:
					var t_left := EvoManager.PRIMORDIO_DURATION - EvoManager.primordio_timer
					primordio_button.text = "Primordio activo — %.0fs" % t_left
					primordio_button.disabled = true
				elif puede_iniciar:
					var costo := 20.0 * (1.0 + EvoManager.primordio_abort_count * 0.2)
					primordio_button.text = "Iniciar Primordio (%.0f%% micelio)" % costo
				else:
					primordio_button.text = "Iniciar Primordio (micelio < 60%%)"
			else:
				primordio_button.visible = false

		if is_instance_valid(sporulation_final_button):
			var show_panspermia = LegacyManager.last_run_ending == "ESPORULACIÓN" and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION and EvoManager.primordio_active
			sporulation_final_button.visible = EvoManager.seta_formada or EvoManager.nucleo_conciencia or show_panspermia
			sporulation_final_button.disabled = false

			if EvoManager.nucleo_conciencia:
				sporulation_final_button.text = "CONECTAR SINGULARIDAD (Final)"
				sporulation_final_button.modulate = Color(0.1, 1.0, 1.0)
			elif EvoManager.seta_formada:
				sporulation_final_button.text = "DISPERSAR ESPORAS (Final)"
				sporulation_final_button.modulate = Color(0.4, 1.0, 0.2)
			elif show_panspermia:
				if EconomyManager.money >= 100000.0:
					sporulation_final_button.text = "PANSPERMIA NEGRA ($100k) (Final)"
					sporulation_final_button.modulate = Color(0.8, 0.2, 1.0)
				else:
					sporulation_final_button.text = "REQUIERE $100k PARA PANSPERMIA"
					sporulation_final_button.disabled = true
					sporulation_final_button.modulate = Color(0.4, 0.1, 0.5)
	else:
		if is_instance_valid(bar): bar.visible = false
		if is_instance_valid(primordio_button): primordio_button.visible = false
		if is_instance_valid(sporulation_final_button): sporulation_final_button.visible = false


