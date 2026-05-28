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
var header_hifas_bar
var header_nutrientes_bar
var header_epsilon_value
var header_omega_value
var header_biomasa_value
var header_hifas_value
var _epsilon_fill_style: StyleBoxFlat
var _omega_fill_style: StyleBoxFlat
var header_nutrientes_value

# ========== CENTER PANEL COLLAPSIBLE — GENOMA ==========
var genome_scroll            # GenomeScroll ScrollContainer (togglable)
var genome_toggle_btn        # MutationToggleBtn Button (locale-aware header)
var route_badge_label        # Label en el header mostrando la ruta activa

# ========== RIGHT PANEL COLLAPSIBLES (Phase 4) ==========
var economy_content          # EconomyContent VBoxContainer (togglable)
var economy_toggle_btn       # EconomyToggleBtn Button (locale-aware header)
var structural_content       # StructuralContent GridContainer (togglable)
var structural_toggle_btn    # StructuralToggleBtn Button (locale-aware header)
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
	header_hifas_bar = _find_scene("HifasBar")
	header_nutrientes_bar = _find_scene("NutrientesBar")
	header_epsilon_value = _find_scene("EpsilonValue")
	header_omega_value = _find_scene("OmegaValue")
	header_biomasa_value = _find_scene("BiomasaValue")
	header_hifas_value = _find_scene("HifasValue")
	header_nutrientes_value = _find_scene("NutrientesValue")

	_apply_bio_header_style()

	# Center panel collapsible — Genoma Fúngico
	genome_scroll = _find("GenomeScroll")
	genome_toggle_btn = _find("MutationToggleBtn")
	if genome_toggle_btn and genome_scroll:
		genome_toggle_btn.text = EmojiToRichText.strip("▼ " + tr("UI_PANEL_GENOME"))
		genome_toggle_btn.toggled.connect(func(pressed: bool):
			_toggle_collapsible_panel(genome_scroll, genome_toggle_btn, pressed, tr("UI_PANEL_GENOME"))
		)

	# Right panel collapsibles (Phase 4)
	economy_content = _find("EconomyContent")
	structural_content = _find("StructuralContent")
	structural_eps_value = _find("EpsValue")
	structural_omg_value = _find("OmgValue")
	structural_pers_value = _find("PersValue")
	structural_acc_value = _find("AccValue")

	# Wire toggle buttons for collapsible sections (Phase 6 — Smooth Transitions)
	economy_toggle_btn = _find("EconomyToggleBtn")
	if economy_toggle_btn:
		economy_toggle_btn.text = EmojiToRichText.strip("▼ " + tr("UI_PANEL_ECONOMY"))
		economy_toggle_btn.toggled.connect(func(pressed: bool):
			_toggle_collapsible_panel(economy_content, economy_toggle_btn, pressed, tr("UI_PANEL_ECONOMY"))
		)

	structural_toggle_btn = _find("StructuralToggleBtn")
	if structural_toggle_btn:
		structural_toggle_btn.text = EmojiToRichText.strip("▶ " + tr("UI_PANEL_STRUCTURE"))
		structural_toggle_btn.toggled.connect(func(pressed: bool):
			_toggle_collapsible_panel(structural_content, structural_toggle_btn, pressed, tr("UI_PANEL_STRUCTURE"))
		)

	if not LocaleManager.locale_changed.is_connected(refresh_panel_labels):
		LocaleManager.locale_changed.connect(refresh_panel_labels)

	# Route badge — RichTextLabel para soporte de emojis en web (Label rompería en HTML5)
	var header_content = _find_scene("HeaderContent")
	if header_content:
		var _rtl := RichTextLabel.new()
		_rtl.bbcode_enabled = true
		_rtl.fit_content = true
		_rtl.scroll_active = false
		_rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		_rtl.add_theme_font_size_override("normal_font_size", AccessibilityManager.fs(13))
		_rtl.visible = false
		# Insertar antes del spacer derecho (último hijo)
		header_content.add_child(_rtl)
		header_content.move_child(_rtl, header_content.get_child_count() - 2)
		route_badge_label = _rtl

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

func refresh_panel_labels(_locale: String = "") -> void:
	if is_instance_valid(economy_toggle_btn):
		var pressed: bool = economy_toggle_btn.button_pressed
		economy_toggle_btn.text = EmojiToRichText.strip(("▼ " if pressed else "▶ ") + tr("UI_PANEL_ECONOMY"))
	if is_instance_valid(structural_toggle_btn):
		var pressed: bool = structural_toggle_btn.button_pressed
		structural_toggle_btn.text = EmojiToRichText.strip(("▼ " if pressed else "▶ ") + tr("UI_PANEL_STRUCTURE"))
	if is_instance_valid(genome_toggle_btn):
		var pressed: bool = genome_toggle_btn.button_pressed
		genome_toggle_btn.text = EmojiToRichText.strip(("▼ " if pressed else "▶ ") + tr("UI_PANEL_GENOME"))

func _make_fill_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_right = 2
	s.corner_radius_bottom_left = 2
	return s

func _apply_bio_header_style() -> void:
	var bio_color := Color(0.78, 0.3, 1.0, 0.9)
	var bio_bars := [header_biomasa_bar, header_hifas_bar, header_nutrientes_bar]
	var bio_labels := [
		_find_scene("BiomasaLabel"), _find_scene("BiomasaValue"),
		_find_scene("HifasLabel"),   _find_scene("HifasValue"),
		_find_scene("NutrientesLabel"), _find_scene("NutrientesValue"),
	]
	for bar in bio_bars:
		if bar:
			bar.add_theme_stylebox_override("fill", _make_fill_style(bio_color))
	for lbl in bio_labels:
		if lbl:
			lbl.add_theme_color_override("font_color", bio_color)

	# StyleBoxes mutables para ε y Ω (se actualizan cada tick con color dinámico)
	_epsilon_fill_style = _make_fill_style(Color.GREEN)
	_omega_fill_style   = _make_fill_style(Color.GREEN)
	if header_epsilon_bar:
		header_epsilon_bar.add_theme_stylebox_override("fill", _epsilon_fill_style)
	if header_omega_bar:
		header_omega_bar.add_theme_stylebox_override("fill", _omega_fill_style)

	# Tooltips: tooltip_text + señal mouse_entered como backup.
	# HeaderBar pasó a MOUSE_FILTER_PASS en el TSCN para que hijos reciban hover.
	var metric_tooltips := {
		"EpsilonMetric": ["EpsilonBar",       "UI_TIP_EPSILON"],
		"OmegaMetric":   ["OmegaBar",         "UI_TIP_OMEGA"],
		"BiomasaMetric": ["BiomasaBar",       "UI_TIP_BIOMASA"],
		"HifasMetric":   ["HifasBar",         "UI_TIP_HIFAS"],
		"NutrientesMetric": ["NutrientesBar", "UI_TIP_NUTRIENTES"],
	}
	for container_name in metric_tooltips:
		var bar_name: String = metric_tooltips[container_name][0]
		var tip_key: String  = metric_tooltips[container_name][1]
		var container = _find_scene(container_name)
		var bar       = _find_scene(bar_name)
		for node in [container, bar]:
			if node:
				node.tooltip_text = tr(tip_key)
				node.mouse_filter = Control.MOUSE_FILTER_STOP
				node.mouse_entered.connect(func(): _show_header_tip(tr(tip_key)))
				node.mouse_exited.connect(func(): _clear_header_tip())

var _header_tip_prev := ""
func _show_header_tip(text: String) -> void:
	if system_message_label:
		_header_tip_prev = system_message_label.text
		system_message_label.text = text

func _clear_header_tip() -> void:
	if system_message_label:
		system_message_label.text = _header_tip_prev

func _find(node_name: String):
	return root.find_child(node_name, true, false)

func _find_scene(node_name: String):
	if scene:
		return scene.find_child(node_name, true, false)
	return root.find_child(node_name, true, false)

func show_toast(msg: String) -> void:
	if system_message_label:
		system_message_label.text = msg

func show_countdown(secs: int, event: String) -> void:
	show_toast("⚠️ %s — %ds" % [event, secs])

# --- Métodos de actualización ---

## Muestra la ruta post-trascendencia activa en el header. Llamar una vez al inicio de run.
func update_route_badge() -> void:
	if not is_instance_valid(route_badge_label):
		return
	var text := ""
	var color := Color.WHITE
	if RunManager.vacio_hambriento_active:
		text = "🕳️  " + tr("ROUTE_VACIO_HAMBRIENTO") + "  ×100"
		color = Color(0.75, 0.2, 1.0)
	elif RunManager.carnaval_active:
		var mut :String= RunManager.carnaval_mutations[RunManager.carnaval_index] if not RunManager.carnaval_mutations.is_empty() else "?"
		text = "🎭  " + tr("ROUTE_CARNAVAL") + "  [%s]" % mut
		color = Color(1.0, 0.5, 0.1)
	elif RunManager.reencarnacion_active:
		text = "⚱️  " + tr("ROUTE_REENCARNACION")
		color = Color(0.3, 0.95, 0.6)
	if text == "":
		route_badge_label.visible = false
		return
	var hex := "#%s" % color.to_html(false)
	route_badge_label.text = "[color=%s]%s[/color]" % [hex, EmojiToRichText.rich(text)]
	route_badge_label.visible = true

func update_money(amount: float):
	if money_label: money_label.text = tr("UI_MONEY") + str(round(amount))

func update_timer(t: float):
	if session_time_label: session_time_label.text = tr("UI_SESSION_TIME") + format_time(t)

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

static func _epsilon_color(e: float) -> Color:
	if e < 0.03:   return Color(0.3, 0.6, 1.0)   # azul — muy bajo
	if e <= 0.30:  return Color(0.2, 0.9, 0.3)   # verde — banda homeostática
	if e <= 0.60:  return Color(1.0, 0.85, 0.1)  # amarillo
	if e <= 1.00:  return Color(1.0, 0.45, 0.1)  # naranja
	return Color(1.0, 0.15, 0.15)                 # rojo — crítico

static func _omega_color(w: float) -> Color:
	if w >= 0.75:  return Color(0.2, 0.9, 0.3)   # verde
	if w >= 0.40:  return Color(1.0, 0.85, 0.1)  # amarillo
	if w >= 0.20:  return Color(1.0, 0.45, 0.1)  # naranja
	return Color(1.0, 0.15, 0.15)                 # rojo

func update_header_metrics(epsilon: float, omega: float, biomasa: float, biomasa_max: float = 10.0, hifas: float = 0.0, nutrientes: float = 0.0):
	if header_epsilon_bar:
		header_epsilon_bar.value = clamp(epsilon, 0.0, 1.0)
		if _epsilon_fill_style:
			_epsilon_fill_style.bg_color = _epsilon_color(epsilon)
	if header_omega_bar:
		header_omega_bar.value = clamp(omega, 0.0, 1.0)
		if _omega_fill_style:
			_omega_fill_style.bg_color = _omega_color(omega)
	if header_biomasa_bar:
		header_biomasa_bar.value = clamp(biomasa / biomasa_max, 0.0, 1.0)
	if header_hifas_bar:
		header_hifas_bar.value = clamp(hifas / 40.0, 0.0, 1.0)
	if header_nutrientes_bar:
		header_nutrientes_bar.value = clamp(nutrientes / 50.0, 0.0, 1.0)
	if header_epsilon_value:
		header_epsilon_value.text = "%.2f" % epsilon
	if header_omega_value:
		header_omega_value.text = "%.2f" % omega
	if header_biomasa_value:
		header_biomasa_value.text = "%.1f/%.0f" % [biomasa, biomasa_max]
	if header_hifas_value:
		header_hifas_value.text = "%.1f" % hifas
	if header_nutrientes_value:
		var nut_disc := int(clamp(nutrientes / 50.0, 0.0, 0.15) * 100.0)
		header_nutrientes_value.text = "%.1f%s" % [nutrientes, " (-%d%%)" % nut_disc if nut_disc > 0 else ""]

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
		structural_acc_value.text = tr("UI_LEVEL_ABBR") % accounting

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

func build_formula_text(_main: Node) -> String:
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
	# aura_dorada es solo click — se muestra en el término activo como rs/im, no en Λ
	if LegacyManager.get_buff_value("semilla_cosmica"):
		lambda_parts.append("[color=#8899ff]sc[/color]")
	if LegacyManager.get_buff_value("mente_colmena"):
		lambda_parts.append("[color=#ff44ff]mc[/color]")
	var eco_v: float = LegacyManager.get_effect_value("all_income_mult")
	if eco_v > 0.0:
		lambda_parts.append("[color=#44ffaa]ep[/color]")
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		lambda_parts.append("[color=#ffaa44]cc[/color]")
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
	# Bandas auto-fit — la línea queda sin wrap (autowrap_mode=0 + clip_contents en .tscn).
	# Bajar a 11 mínimo: aún legible y absorbe fórmulas largas con cognitive + Λ + breakdown.
	var fSize := 18
	if   fLen > 95: fSize = 11
	elif fLen > 80: fSize = 12
	elif fLen > 68: fSize = 13
	elif fLen > 55: fSize = 14
	elif fLen > 45: fSize = 15
	elif fLen > 35: fSize = 16

	var t: String = "[font_size=%d]∫$ = " % fSize + formula_main + "[/font_size]\n"

	# Λ breakdown (solo si hay mults de legado)
	if lambda_parts.size() > 0:
		t += "[color=#ffdd88][font_size=11]Λ = " + " · ".join(lambda_parts)
		if LegacyManager.get_buff_value("metabolismo_glitch"):
			t += tr("FORMULA_MG_ACTIVE")
		t += "[/font_size][/color]\n"

	# Información del Modelo — μ solo cuando Capital Cognitivo está activo
	var raw_n: int = StructuralModel.get_structural_upgrades()
	if UpgradeManager.level("cognitive") > 0:
		t += "fⁿ = c₀ · κμ^(1 - 1/n)\n\n"
		t += "κμ = k · (1 + α · (μ - 1))\n"
		t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  μ = %.2f  n = %d[/color]" % [
			StructuralModel.persistence_base, StructuralModel.persistence_dynamic, EconomyManager.cached_mu, raw_n
		]
	else:
		t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  n = %d[/color]" % [
			StructuralModel.persistence_base, StructuralModel.persistence_dynamic, raw_n
		]


	return t

func build_formula_values(_main: Node) -> String:
	return ""

func build_marginal_contribution(_main: Node) -> String:
	return ""

func update_click_stats_panel(_main: Node) -> String:
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
		
	var t = "[b]" + tr("LAB_APORTE_ACTUAL") + "[/b]\n"
	t += "[color=#cccccc]" + tr("LAB_CLICK_PUSH_LINE") % push + "\n"
	if StructuralModel.unlocked_d: t += tr("LAB_TRABAJO_LINE") % EconomyManager.get_auto_income_effective() + "\n"
	if StructuralModel.unlocked_e: t += tr("LAB_TRUEQUE_LINE") % EconomyManager.get_trueque_income_effective() + "[/color]\n\n"

	t += "[b]" + tr("LAB_DELTA_TOTAL") % ap.total + "[/b]\n"
	if ap.total > 0:
		if ap.activo > ap.pasivo:
			t += tr("LAB_CLICK_DOM") + "\n\n"
		else:
			t += tr("LAB_RED_DOM") + "\n\n"

	t += "[color=#d946ef]--- " + tr("LAB_PROD_ACTIVE") + " ---\n"
	t += "a = %.1f   " % a + tr("LAB_CLICK_BASE") + "\n"
	if UpgradeManager.level("click_mult") > 0:
		t += "b = %.2f   " % b + tr("LAB_MULTIPLICADOR") + "\n"
	if StructuralModel.persistence_upgrade_unlocked:
		t += "c_n(actual) = %.2f\n" % c_n
	if RunManager.vacio_hambriento_active:
		t += "vh = %.0f\n" % RunManager.vacio_hambriento_mult
	if LegacyManager.get_buff_value("impulso_manual"):
		t += "im = 2.00   " + tr("LAB_IMPULSO_MANUAL") + "\n"
	t += "\n"

	if StructuralModel.unlocked_d:
		t += "d = %.1f/s   " % d_raw + tr("LAB_TRABAJO_MANUAL") + "\n"
		if StructuralModel.unlocked_md: t += "md = %.2f   " % md + tr("LAB_RITMO_TRABAJO") + "\n"
		else: t += "md = -- " + tr("LAB_LATENTE") + "\n"
		if UpgradeManager.level("specialization") > 0: t += "so = %.2f   " % so + tr("LAB_ESPECIALIZACION") + "\n"
		t += "\n"

	if StructuralModel.unlocked_e:
		t += "e = %.1f/s   " % e_raw + tr("LAB_TRUEQUE_CORR") + "\n"
		if StructuralModel.unlocked_me:
			t += "me = %.2f   " % me + tr("LAB_RED_INTERCAMBIO") + "\n"
			if UpgradeManager.level("trueque_allo") > 0:
				t += "ea = %.2f   " % UpgradeManager.value("trueque_allo") + tr("LAB_ESCALADO_ALOS") + "\n"
		else: t += "me = -- " + tr("LAB_LATENTE") + "\n"

	if LegacyManager.get_buff_value("redireccion_energia"):
		t += "re = +%.1f/s   " % (EconomyManager.get_click_power() * 0.10) + tr("LAB_REDIRECCION") + "\n"

	t += "\n\n--- " + tr("LAB_MODELO_STRUCT") + " ---\n"
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
		t += "\n\n--- " + tr("LAB_CAPITAL_COG") + " ---\n"
		t += "μ = %.2f\n" % EconomyManager.cached_mu
		t += tr("LAB_NIVEL_COG") % UpgradeManager.level("cognitive") + "\n"
		var acc_lvl_d: int = UpgradeManager.level("accounting")
		if acc_lvl_d > 0:
			t += tr("LAB_CONTAB_MU") % (1.0 + acc_lvl_d * 0.08) + "\n"
		if RunManager.resilience_score > 0.0:
			t += tr("LAB_RESIL_MU") % [1.0 + min(RunManager.resilience_score / 300.0, 1.0) * 0.30, RunManager.resilience_score] + "\n"

	# --- LEGADO: MULTIPLICADORES DE INGRESOS ---
	var has_income_buff := false
	var income_section := "\n--- " + tr("LAB_LEGADO_MULT") + " ---\n"
	if LegacyManager.get_buff_value("impulso_manual"):
		income_section += tr("LAB_IM_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		var rs_val: float = min(1.0 + BiosphereEngine.biomasa * 0.05, 2.5)
		income_section += tr("LAB_RS_LINE") % [rs_val, BiosphereEngine.biomasa] + "\n"
		has_income_buff = true
	if LegacyManager.get_buff_value("aura_dorada"):
		income_section += tr("LAB_AU_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("semilla_cosmica"):
		income_section += tr("LAB_SC_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("mente_colmena"):
		income_section += tr("LAB_MC_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		var mg_active := StructuralModel.epsilon_runtime > 0.40
		var mg_state := tr("LAB_MG_ACTIVO") if mg_active else tr("LAB_MG_INACTIVO") % StructuralModel.epsilon_runtime
		income_section += tr("LAB_MG_LINE") % mg_state + "\n"
		has_income_buff = true
	var eco_mult: float = LegacyManager.get_effect_value("all_income_mult")
	if eco_mult > 0.0:
		income_section += tr("LAB_EP_LINE") % (1.0 + eco_mult) + "\n"; has_income_buff = true
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		var cc_val := 1.0 + LegacyManager.trascendencia_count * 0.05
		income_section += tr("LAB_CC_LINE") % [cc_val, LegacyManager.trascendencia_count] + "\n"
		has_income_buff = true
	var cog_mult: float = LegacyManager.get_effect_value("cognitivo_income_mult_per_level")
	if cog_mult > 0.0:
		var cog_val := 1.0 + UpgradeManager.level("accounting") * cog_mult
		income_section += tr("LAB_RC_LINE") % [cog_val, UpgradeManager.level("accounting")] + "\n"
		has_income_buff = true
	if has_income_buff:
		t += income_section

	# --- LEGADO: DEFENSA OMEGA ---
	var has_omega_buff := false
	var omega_section := "\n--- " + tr("LAB_LEGADO_OMEGA") + " ---\n"
	if LegacyManager.get_buff_value("plasticidad_adaptativa"):
		omega_section += tr("LAB_PA_LINE") + "\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("legado_homeorresis"):
		omega_section += tr("LAB_TC_LINE") + "\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("legado_alostasis"):
		omega_section += tr("LAB_RA_LINE") % RunManager.disturbances_survived + "\n"
		has_omega_buff = true
	var eq_per_dist: float = LegacyManager.get_effect_value("omega_min_per_disturbance")
	if eq_per_dist > 0.0:
		omega_section += tr("LAB_EH_LINE") % eq_per_dist + "\n"; has_omega_buff = true
	var omega_rec: float = LegacyManager.get_effect_value("omega_recovery_speed")
	if omega_rec > 0.0:
		omega_section += tr("LAB_SA_LINE") % omega_rec + "\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("cristalizacion_permanente"):
		omega_section += tr("LAB_CP_LINE") + "\n"; has_omega_buff = true
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

func build_evo_checklist(_main: Node) -> String:
	# Si la run ya cerró, mostrar lore/resumen del final alcanzado en vez de la checklist
	if RunManager.run_closed:
		return _build_run_end_lore(RunManager.final_route)

	var t := "[color=cyan][b]" + tr("EVO_NEXT_TRANS") + "[/b][/color]\n"
	var acc := UpgradeManager.level("accounting")
	var ch : String
	var ok_color := "[color=%s]" % AccessibilityManager.cok_hex()
	var fail_color := "[color=%s]" % AccessibilityManager.cno_hex()

	if EvoManager.mutation_homeostasis:
		var tier := RunManager.homeostasis_tier_reached
		# Tier 1 — HOMEOSTASIS
		if tier == 0:
			t += "[b][color=cyan]" + tr("EVO_TIER1_TITLE") + "[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.get_en_banda_homeostatica() else fail_color + "[ ] "
			t += ch + tr("EVO_BAND_EPS") % snapped(StructuralModel.epsilon_runtime, 0.01) + "[/color]\n"
			ch = ok_color + "[x] " if StructuralModel.unlocked_d and StructuralModel.unlocked_e else fail_color + "[ ] "
			t += ch + tr("EVO_UNLOCKED_DE") + "[/color]\n"
			ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
			t += ch + tr("EVO_ACCOUNTING_N1") % acc + "[/color]\n"
			var pct := int(min(RunManager.homeostasis_timer / Balance.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0)
			t += "[color=cyan]" + tr("EVO_STABILIZING") % [pct, RunManager.homeostasis_timer] + "[/color]\n"
		# Tier 2 — ALLOSTASIS
		elif tier == 1:
			t += ok_color + "[x] " + tr("EVO_TIER1_DONE") + "[/color]\n"
			t += "[b][color=aquamarine]" + tr("EVO_TIER2_TITLE") + "[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 3 else fail_color + "[ ] "
			t += ch + tr("EVO_DISTURBANCES") % [RunManager.disturbances_survived, 3] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.resilience_score >= 150.0 else fail_color + "[ ] "
			t += ch + tr("EVO_RESILIENCE_GE") % [150, int(RunManager.resilience_score)] + "[/color]\n"
			ch = ok_color + "[x] " if StructuralModel.omega_min >= 0.40 else fail_color + "[ ] "
			t += ch + tr("EVO_OMEGA_MIN_GE") % [snapped(0.40, 0.01), snapped(StructuralModel.omega_min, 0.01)] + "[/color]\n"
			var delta_real2 :float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real2 > 200.0 else fail_color + "[ ] "
			t += ch + tr("EVO_METABOLISM_GT") % [200, snapped(delta_real2, 0.1)] + "[/color]\n"
			ch = ok_color + "[x] " if acc >= 2 else fail_color + "[ ] "
			t += ch + tr("EVO_ACCOUNTING_N2") % acc + "[/color]\n"
		# Tier 3 — HOMEORHESIS
		elif tier == 2:
			t += ok_color + "[x] " + tr("EVO_TIER12_DONE") + "[/color]\n"
			t += "[b][color=gold]" + tr("EVO_TIER3_TITLE") + "[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.extreme_shocks_recovered >= 1 else fail_color + "[ ] "
			t += ch + tr("EVO_SHOCK_EXTREME") % RunManager.extreme_shocks_recovered + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.resilience_score >= 400.0 else fail_color + "[ ] "
			t += ch + tr("EVO_RESILIENCE_GE") % [400, int(RunManager.resilience_score)] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.omega_min_peak >= 0.50 else fail_color + "[ ] "
			t += ch + tr("EVO_OMEGA_PEAK_GE") % [snapped(0.50, 0.01), snapped(RunManager.omega_min_peak, 0.01)] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 5 else fail_color + "[ ] "
			t += ch + tr("EVO_DISTURBANCES") % [RunManager.disturbances_survived, 5] + "[/color]\n"
			var delta_real3 :float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real3 > 300.0 else fail_color + "[ ] "
			t += ch + tr("EVO_METABOLISM_GT") % [300, snapped(delta_real3, 0.1)] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.run_time >= 1200.0 else fail_color + "[ ] "
			t += ch + tr("EVO_RUN_GE_TIME") % format_time(RunManager.run_time) + "[/color]\n"
		elif tier == 3:
			t += ok_color + "[x] " + tr("EVO_TIER3_DONE") + "[/color]\n"
		t += "\n"

	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		t += "[b]" + tr("EVO_RED_OBJ_MECH") + "[/b]\n"

		# Hito 1: Estabilidad
		var eps_ok: bool = StructuralModel.epsilon_runtime <= 0.25 or EvoManager.nucleo_conciencia
		ch = ok_color + "[x] " if eps_ok else fail_color + "[ ] "
		t += ch + "Estabilidad estructural (ε <= 0.25) (" + str(snapped(StructuralModel.epsilon_runtime, 0.01)) + ")[/color]\n"

		# Hito 2: Sincronización (Primordio normal O Mente Colmena NG+)
		if EvoManager.primordio_active:
			t += "[color=cyan]" + tr("EVO_SYNC_PCT") % str(int(EvoManager.primordio_timer / Balance.PRIMORDIO_DURATION * 100.0)) + "[/color]\n"
		elif EvoManager.nucleo_conciencia:
			t += ok_color + "[x] " + tr("EVO_NUCLEUS_SYNC") + "[/color]\n"
		else:
			var acc_ok := acc >= 2
			ch = ok_color + "[x] " if acc_ok else fail_color + "[ ] "
			t += ch + tr("EVO_MAINFRAME_ACC") + "[/color]\n"

		# Hito 3: Núcleo
		ch = ok_color + "[x] " if EvoManager.nucleo_conciencia else fail_color + "[ ] "
		t += ch + tr("EVO_SINGULARITY_RDY") + "[/color]\n"

		# NG+ MENTE COLMENA — ruta alternativa cuando last_run == "SINGULARIDAD"
		if LegacyManager.last_run_ending == "SINGULARIDAD" or LegacyManager.last_run_ending == "MENTE COLMENA DISTRIBUIDA":
			t += "\n[color=magenta][b]🧠 " + tr("EVO_MC_ROUTE") + "[/b][/color]\n"
			var mc_timer: float = RunManager.mente_colmena_timer
			var mc_active: bool = RunManager.mente_colmena_active
			if mc_active:
				t += ok_color + "[x] " + tr("EVO_MC_ACTIVE") + "[/color]\n"
			elif mc_timer > 0.0:
				var mc_pct := int(mc_timer / 180.0 * 100.0)
				var filled := int(mc_pct / 5.0)   # 20 bloques = 100%
				var bar := ""
				for i in range(20):
					bar += "█" if i < filled else "░"
				t += "[color=cyan]" + tr("EVO_MC_SYNC_BAR") % [bar, mc_pct, mc_timer] + "[/color]\n"
				# Mostrar ratio actual
				var ap :Dictionary = EconomyManager.get_active_passive_breakdown()
				var r_act := int(ap.activo)
				var r_pas := int(ap.pasivo)
				var ratio_color := "[color=cyan]" if abs(r_act - 50) <= 2 else "[color=yellow]"
				t += ratio_color + "    " + tr("EVO_MC_RATIO_DISPLAY") % [r_act, r_pas] + "[/color]\n"
			else:
				t += "[color=#aaaaaa]" + tr("EVO_MC_RATIO_REQ") + "[/color]\n"
				t += "[color=#aaaaaa]" + tr("EVO_MC_EPS_REQ") + "[/color]\n"

	elif EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		t += "[b]" + tr("EVO_RED_OBJ_BIO") + "[/b]\n"

		# Hito 1: Micelio
		var mic_ok: bool = BiosphereEngine.micelio >= 60.0 or EvoManager.seta_formada
		ch = ok_color + "[x] " if mic_ok else fail_color + "[ ] "
		t += ch + tr("EVO_MICELIO_DEV") % int(BiosphereEngine.micelio) + "[/color]\n"

		# Hito 2: Primordio
		if EvoManager.primordio_active:
			t += "[color=yellow]" + tr("EVO_PRIMORDIO_CURSO") % int(EvoManager.primordio_timer) + "[/color]\n"
		elif EvoManager.seta_formada:
			t += ok_color + "[x] " + tr("EVO_BIO_CYCLE_DONE") + "[/color]\n"
		else:
			ch = fail_color + "[ ] "
			t += ch + tr("EVO_SURVIVE_PRIM") + "[/color]\n"

		# Hito 3: Seta
		ch = ok_color + "[x] " if EvoManager.seta_formada else fail_color + "[ ] "
		t += ch + tr("EVO_SETA_MADURA") + "[/color]\n"

		if EvoManager.seta_formada:
			t += "[color=cyan][b]" + tr("EVO_READY_ESPOR") + "[/b][/color]\n"

	elif EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 1:
		t += "[b]" + tr("EVO_RED_PHASE_B") + "[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas > 10.0 else fail_color + "[ ] "
		t += ch + "Hifas > 10  (%s)[/color]\n" % snapped(BiosphereEngine.hifas, 0.1)
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)
		ch = ok_color + "[x] " if StructuralModel.epsilon_effective < 0.32 else fail_color + "[ ] "
		t += ch + "ε_ef < 0.32  (%s)[/color]\n" % snapped(StructuralModel.epsilon_effective, 0.01)
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + tr("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"
		ch = ok_color + "[x] " if RunManager.run_time > 200.0 else fail_color + "[ ] "
		t += ch + "Tiempo > 200 s  (%s)[/color]\n" % format_time(RunManager.run_time)

	elif EvoManager.mutation_symbiosis and not EvoManager.mutation_red_micelial:
		t += "[b][color=green]" + tr("EVO_SIM_ACTIVE_TITLE") + "[/color][/b]\n"
		t += "[color=gray]" + tr("EVO_SIM_SEAL_HINT") + "[/color]\n"

	elif not EvoManager.mutation_red_micelial and not EvoManager.mutation_homeostasis \
		and not EvoManager.mutation_hyperassimilation and not EvoManager.mutation_parasitism \
		and not EvoManager.mutation_symbiosis:
		var ap_snap = EconomyManager.get_active_passive_breakdown()
		var pasivo_domina = ap_snap.pasivo > ap_snap.activo
		var activo_domina = ap_snap.activo > ap_snap.pasivo
		t += "[b]" + tr("EVO_RED_TITLE") + "[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 11.5 else fail_color + "[ ] "
		t += ch + "Hifas >= 12  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (" + str(snapped(BiosphereEngine.biomasa, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.epsilon_runtime < 0.65 else fail_color + "[ ] "
		t += ch + tr("EVO_EPS_RT_LT65") % snapped(StructuralModel.epsilon_runtime, 0.01) + "[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + tr("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"
		ch = ok_color + "[x] " if pasivo_domina else fail_color + "[ ] "
		t += ch + tr("EVO_PASSIVE_DOM") % [int(ap_snap.pasivo), int(ap_snap.activo)] + "[/color]\n"
		t += "\n[b]" + tr("EVO_SIM_TITLE") + "[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 5.0 else fail_color + "[ ] "
		t += ch + "Hifas >= 5  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.omega >= 0.40 else fail_color + "[ ] "
		t += ch + "Ω >= 0.40  (" + str(snapped(StructuralModel.omega, 0.01)) + ")[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + tr("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"
		ch = ok_color + "[x] " if activo_domina else fail_color + "[ ] "
		t += ch + tr("EVO_ACTIVE_DOM") % [int(ap_snap.activo), int(ap_snap.pasivo)] + "[/color]\n"

	if not EvoManager.mutation_homeostasis and not EvoManager.mutation_hyperassimilation \
		and not EvoManager.mutation_sporulation and not EvoManager.mutation_red_micelial \
		and not EvoManager.mutation_symbiosis:
		t += "\n[color=gray]" + tr("EVO_HOME_HINT_LABEL") + "[/color]\n"
		ch = ok_color + "[x] " if RunManager.get_en_banda_homeostatica() else fail_color + "[ ] "
		t += ch + tr("EVO_BAND_VALUE") % snapped(StructuralModel.epsilon_runtime, 0.01) + "[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.omega > 0.25 else fail_color + "[ ] "
		t += ch + tr("EVO_OMEGA_025") % snapped(StructuralModel.omega, 0.01) + "[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa < 12.0 else fail_color + "[ ] "
		t += ch + tr("EVO_BIOMASA_LT12") % snapped(BiosphereEngine.biomasa, 0.1) + "[/color]\n"
		ch = ok_color + "[x] " if EconomyManager.delta_per_sec > 30.0 else fail_color + "[ ] "
		t += ch + tr("EVO_METABOLISM_GT") % [30, snapped(EconomyManager.delta_per_sec, 0.1)] + "[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.unlocked_d and StructuralModel.unlocked_e else fail_color + "[ ] "
		t += ch + tr("EVO_PASSIVES_DE") + "[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + tr("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"

	if EvoManager.mutation_parasitism:
		t += "\n[color=#ffaa00]" + tr("EVO_COLLAPSE_OBJ") + "[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 15.0 else fail_color + "[ ] "
		t += ch + tr("EVO_BIO_DRAIN") % snapped(BiosphereEngine.biomasa, 0.1) + "[/color]\n"
		ch = ok_color + "[x] " if EconomyManager.money < 1000.0 else fail_color + "[ ] "
		t += ch + tr("EVO_LIQUID_LT1K") % snapped(EconomyManager.money, 1) + "[/color]\n"
		t += "\n" + tr("EVO_OR_SEP") + "\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 25.0 else fail_color + "[ ] "
		t += ch + tr("EVO_BIO_CRITICAL") % snapped(BiosphereEngine.biomasa, 0.1) + "[/color]\n"

	return t

func _build_run_end_lore(route: String) -> String:
	var lore_data := {
		# ── RAMA AZUL: HOMEOSTASIS ────────────────────────────────────────────────
		"HOMEOSTASIS": {
			"emoji": "⚖️", "color": "#00ccff",
			"lore": tr("LORE_HOME_LORE"),
			"buffs": [tr("LORE_HOME_B1"), tr("LORE_HOME_B2"), tr("LORE_HOME_B3"), tr("LORE_HOME_B4")],
			"nerfs": [tr("LORE_HOME_N1"), tr("LORE_HOME_N2"), tr("LORE_HOME_N3")]
		},
		"ALLOSTASIS": {
			"emoji": "💜", "color": "#aa55ff",
			"lore": tr("LORE_ALOS_LORE"),
			"buffs": [tr("LORE_ALOS_B1"), tr("LORE_ALOS_B2"), tr("LORE_ALOS_B3"), tr("LORE_ALOS_B4")],
			"nerfs": [tr("LORE_ALOS_N1"), tr("LORE_ALOS_N2")]
		},
		"HOMEORHESIS": {
			"emoji": "💎", "color": "#00ffee",
			"lore": tr("LORE_HOMR_LORE"),
			"buffs": [tr("LORE_HOMR_B1"), tr("LORE_HOMR_B2"), tr("LORE_HOMR_B3"), tr("LORE_HOMR_B4")],
			"nerfs": [tr("LORE_HOMR_N1"), tr("LORE_HOMR_N2"), tr("LORE_HOMR_N3")]
		},
		# ── RAMA VERDE: SIMBIOSIS / SINGULARIDAD ─────────────────────────────────
		"SIMBIOSIS": {
			"emoji": "💚", "color": "#00dd66",
			"lore": tr("LORE_SIMB_LORE"),
			"buffs": [tr("LORE_SIMB_B1"), tr("LORE_SIMB_B2"), tr("LORE_SIMB_B3"), tr("LORE_SIMB_B4")],
			"nerfs": [tr("LORE_SIMB_N1"), tr("LORE_SIMB_N2"), tr("LORE_SIMB_N3")]
		},
		"SINGULARIDAD": {
			"emoji": "📡", "color": "#ffd060",
			"lore": tr("LORE_SING_LORE"),
			"buffs": [tr("LORE_SING_B1"), tr("LORE_SING_B2"), tr("LORE_SING_B3")],
			"nerfs": [tr("LORE_SING_N1"), tr("LORE_SING_N2")]
		},
		"MENTE COLMENA DISTRIBUIDA": {
			"emoji": "🧠", "color": "#40aaff",
			"lore": tr("LORE_MENTE_LORE"),
			"buffs": [tr("LORE_MENTE_B1"), tr("LORE_MENTE_B2"), tr("LORE_MENTE_B3"), tr("LORE_MENTE_B4")],
			"nerfs": [tr("LORE_MENTE_N1"), tr("LORE_MENTE_N2")]
		},
		# ── RAMA ROJA: RED MICELIAL / ESPORULACIÓN ───────────────────────────────
		"ESPORULACIÓN": {
			"emoji": "✨", "color": "#aaff44",
			"lore": tr("LORE_ESPOR_LORE"),
			"buffs": [tr("LORE_ESPOR_B1"), tr("LORE_ESPOR_B2"), tr("LORE_ESPOR_B3")],
			"nerfs": [tr("LORE_ESPOR_N1"), tr("LORE_ESPOR_N2"), tr("LORE_ESPOR_N3")]
		},
		"ESPORULACION": {
			"emoji": "✨", "color": "#aaff44",
			"lore": tr("LORE_ESPOR_LORE"),
			"buffs": [tr("LORE_ESPOR_B1"), tr("LORE_ESPOR_B2")],
			"nerfs": [tr("LORE_ESPOR_N1"), tr("LORE_ESPOR_N2")]
		},
		"PANSPERMIA NEGRA": {
			"emoji": "🚀", "color": "#dd22ff",
			"lore": tr("LORE_PANSP_LORE"),
			"buffs": [tr("LORE_PANSP_B1"), tr("LORE_PANSP_B2"), tr("LORE_PANSP_B3")],
			"nerfs": [tr("LORE_PANSP_N1"), tr("LORE_PANSP_N2")]
		},
		# ── RAMA NARANJA: PARASITISMO / HIPERASIMILACIÓN ─────────────────────────
		"PARASITISMO": {
			"emoji": "☣️", "color": "#ff4400",
			"lore": tr("LORE_PARAS_LORE"),
			"buffs": [tr("LORE_PARAS_B1"), tr("LORE_PARAS_B2"), tr("LORE_PARAS_B3"), tr("LORE_PARAS_B4")],
			"nerfs": [tr("LORE_PARAS_N1"), tr("LORE_PARAS_N2"), tr("LORE_PARAS_N3"), tr("LORE_PARAS_N4"), tr("LORE_PARAS_N5")]
		},
		"HIPERASIMILACIÓN": {
			"emoji": "🔥", "color": "#ff8800",
			"lore": tr("LORE_HIPERAS_LORE"),
			"buffs": [tr("LORE_HIPERAS_B1"), tr("LORE_HIPERAS_B2"), tr("LORE_HIPERAS_B3"), tr("LORE_HIPERAS_B4")],
			"nerfs": [tr("LORE_HIPERAS_N1"), tr("LORE_HIPERAS_N2"), tr("LORE_HIPERAS_N3")]
		},
		# ── FRACTURA EPISTÉMICA ──────────────────────────────────────────────────
		"COLAPSO CONTROLADO": {
			"emoji": "⚡", "color": "#ff6622",
			"lore": tr("LORE_COL_LORE"),
			"buffs": [tr("LORE_COL_B1"), tr("LORE_COL_B2"), tr("LORE_COL_B3")],
			"nerfs": [tr("LORE_COL_N1"), tr("LORE_COL_N2"), tr("LORE_COL_N3")]
		},
		# ── RAMA GLITCH: DEPREDADOR / MET.OSCURO ─────────────────────────────────
		"DEPREDADOR DE REALIDADES": {
			"emoji": "👾", "color": "#ff0055",
			"lore": tr("LORE_DEP_LORE"),
			"buffs": [tr("LORE_DEP_B1"), tr("LORE_DEP_B2"), tr("LORE_DEP_B3"), tr("LORE_DEP_B4")],
			"nerfs": [tr("LORE_DEP_N1"), tr("LORE_DEP_N2"), tr("LORE_DEP_N3")]
		},
		"METABOLISMO OSCURO": {
			"emoji": "🌑", "color": "#8844aa",
			"lore": tr("LORE_MO_LORE"),
			"buffs": [tr("LORE_MO_B1"), tr("LORE_MO_B2"), tr("LORE_MO_B3"), tr("LORE_MO_B4"), tr("LORE_MO_B5")],
			"nerfs": [tr("LORE_MO_N1"), tr("LORE_MO_N2"), tr("LORE_MO_N3"), tr("LORE_MO_N4")]
		},
	}

	var data = lore_data.get(route, null)
	if data == null:
		return "[color=gray]" + tr("LORE_RUN_DONE") % route + "[/color]\n"

	var t := ""
	t += "[color=%s][b]%s %s[/b][/color]\n\n" % [data.color, data.emoji, route]
	t += "[color=#cccccc][i]%s[/i][/color]\n\n" % data.lore
	t += "[color=#00ff88][b]" + tr("LORE_EFFECTS") + "[/b][/color]\n"
	for buff in data.buffs:
		t += "[color=#00ff88]+ %s[/color]\n" % buff
	t += "\n"
	for nerf in data.nerfs:
		t += "[color=#ff4444]- %s[/color]\n" % nerf
	t += "\n[color=gray]" + tr("LORE_NEW_RUN") + "[/color]"
	return t

# =====================================================
#  BUILDERS DE TEXTO — Genoma y Mutaciones
#  (Movidos desde main.gd para centralizar builders UI)
# =====================================================

func build_genome_text() -> String:
	var t := ""
	# Ruta post-trascendencia activa
	if RunManager.vacio_hambriento_active:
		t += "[b][color=#bb44ff]🕳️ " + tr("GENOME_VACIO_TITLE") + "[/color][/b]\n"
		t += "[color=#888888]" + tr("GENOME_VACIO_DESC") + "[/color]\n"
		var _gen: float = EconomyManager.money
		var _run_t: float = RunManager.run_time
		t += "[color=#9955dd]" + tr("GENOME_ASCESIS_TITLE") + "[/color]\n"
		if _gen < 1000000.0:
			t += "[color=#666666]" + tr("GENOME_ASCESIS_GEN") % _gen + "[/color]\n\n"
		elif _run_t < 900.0:
			t += "[color=#666666]" + tr("GENOME_ASCESIS_TIME") % _run_t + "[/color]\n\n"
		else:
			var bio_ok: bool = BiosphereEngine.biomasa < 0.5
			var sin_p: bool = UpgradeManager.level("auto") == 0 and UpgradeManager.level("trueque") == 0
			var eps_ok: bool = StructuralModel.epsilon_runtime < 0.25
			var bio_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if bio_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var pas_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if sin_p else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var eps_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if eps_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			t += tr("GENOME_ASCESIS_BIO_LBL") + ": " + bio_s + "  " + tr("GENOME_ASCESIS_PAS_LBL") + ": " + pas_s + "  e: " + eps_s + "\n"
			var prog: float = clamp(RunManager.ascesis_timer / float(Balance.ASCESIS_DURATION), 0.0, 1.0)
			var filled: int = int(prog * 20)
			var bar: String = "[" + "X".repeat(filled) + ".".repeat(20 - filled) + "]"
			t += bar + " %ds/%ds\n\n" % [int(RunManager.ascesis_timer), Balance.ASCESIS_DURATION]
	elif RunManager.carnaval_active and not RunManager.carnaval_mutations.is_empty():
		var idx := RunManager.carnaval_index
		var muts := RunManager.carnaval_mutations
		t += "[b][color=#ff8833]🎭 " + tr("ROUTE_CARNAVAL") + "[/color][/b]\n"
		t += tr("GENOME_CARNAVAL_ROT") % ["[color=#ffaa55]" + muts[idx] + "[/color]", muts[(idx+1)%3], muts[(idx+2)%3]] + "\n"
		var secs_left := int(Balance.CARNAVAL_INTERVAL - RunManager.carnaval_timer)
		t += "[color=#888888]" + tr("GENOME_CARNAVAL_NEXT") % secs_left + "[/color]\n"
		var rot := RunManager.carnaval_total_rotations
		var peak := RunManager.carnaval_peak_money
		t += "[color=#ffdd44]" + tr("GENOME_CARNAVAL_STATS") % [rot, peak/1000.0] + "[/color]\n\n"
	elif RunManager.reencarnacion_active:
		t += "[b][color=#44ee99]⚱️ " + tr("ROUTE_REENCARNACION") + "[/color][/b]\n"
		t += "[color=#888888]" + tr("GENOME_REENC_DESC") + "[/color]\n\n"
	t += tr("GENOME_FUNGICO") + "\n"
	t += tr("MUT_LABEL_HIPERAS") + ": " + tr("MUT_STATE_" + EvoManager.genome.hiperasimilacion.to_upper()) + "\n"
	t += tr("MUT_LABEL_PARASIT") + ": " + tr("MUT_STATE_" + EvoManager.genome.parasitismo.to_upper()) + "\n"
	t += tr("MUT_LABEL_RED") + ": " + tr("MUT_STATE_" + EvoManager.genome.red_micelial.to_upper()) + "\n"
	t += tr("MUT_LABEL_ESPOR") + ": " + tr("MUT_STATE_" + EvoManager.genome.esporulacion.to_upper()) + "\n"
	t += tr("MUT_LABEL_SIMBIO") + ": " + tr("MUT_STATE_" + EvoManager.genome.simbiosis.to_upper()) + "\n"
	var dep_state: String = EvoManager.genome.get("depredador", "dormido")
	if dep_state != "dormido" or EvoManager.mutation_depredador:
		t += tr("MUT_LABEL_DEP") + ": " + tr("MUT_STATE_" + dep_state.to_upper()) + "\n"
	var mo_state: String = EvoManager.genome.get("met_oscuro", "dormido")
	if mo_state != "dormido" or EvoManager.mutation_met_oscuro:
		t += tr("MUT_LABEL_MO") + ": " + tr("MUT_STATE_" + mo_state.to_upper()) + "\n"

	if EvoManager.mutation_met_oscuro:
		t += "[b][color=#8844aa]🌑 " + tr("GENOME_MO_TITLE") + "[/color][/b]\n"
		t += "[color=#00ff00]" + tr("GENOME_MO_BUFF") + "[/color]\n"
		t += "[color=#ff4444]" + tr("GENOME_MO_NERF") + "[/color]\n"
	elif EvoManager.mutation_depredador:
		t += "[b][color=#ff0055]☠️ " + tr("GENOME_DEP_TITLE") + "[/color][/b]\n"
		t += "[color=#00ff00]" + tr("GENOME_DEP_BUFF") + "[/color]\n"
		t += "[color=#ff4444]" + tr("GENOME_DEP_NERF") + "[/color]\n"
	elif EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ " + tr("GENOME_HIPERAS_TITLE") + "[/color][/b]\n"
		t += "[color=#00ff00]" + tr("GENOME_HIPERAS_BUFF") + "[/color]\n"
		t += "[color=#ff4444]" + tr("GENOME_HIPERAS_NERF1") + "[/color]\n"
		t += "[color=#ff4444]" + tr("GENOME_HIPERAS_NERF2") + "[/color]\n"
	elif EvoManager.genome.hiperasimilacion == "latente":
		t += "\n[color=gray]• " + tr("GENOME_HIPERAS_LATENTE") + "[/color]"

	var _route_prefix: String = tr("MUT_ROUTE_PREFIX") + ": "
	if EvoManager.mutation_met_oscuro:
		t += "\n🌑 " + _route_prefix + tr("MUT_MET_OSCURO")
	elif EvoManager.mutation_depredador:
		t += "\n☠️ " + _route_prefix + tr("MUT_DEPREDADOR")
	elif EvoManager.mutation_homeostasis:
		t += "\n⚖️ " + _route_prefix + tr("MUT_HOMEOSTASIS")
	elif EvoManager.mutation_hyperassimilation:
		t += "\n⚠️ " + _route_prefix + tr("MUT_HIPERASIMILACION")
	elif EvoManager.mutation_symbiosis:
		t += "\n🌱 " + _route_prefix + tr("MUT_SIMBIOSIS")
	elif EvoManager.mutation_parasitism:
		t += "\n🦠 " + _route_prefix + tr("MUT_PARASITISMO")

	if RunManager.run_closed:
		t += "\n\n" + tr("GENOME_FINAL") + RunManager.final_route
	return t

func build_mutation_status_text() -> String:
	var t := "\n[color=#aaaaaa]" + tr("MSTAT_HEADER") + "[/color]\n"
	var buff := "[color=#00ff00]+"
	var nerf := "[color=#ff4444]-"

	if EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ " + tr("MSTAT_HIPERAS_TITLE") + "[/color][/b]\n"
		t += buff + " " + tr("MSTAT_HIPERAS_B1") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_HIPERAS_N1") + "[/color]\n"

	if EvoManager.mutation_homeostasis:
		var en_banda_home := RunManager.get_en_banda_homeostatica()
		var bonus_color := buff if en_banda_home else "[color=#777777]"
		t += "[b][color=cyan]⚖️ " + tr("MSTAT_HOME_TITLE") + "[/color][/b]\n"
		t += bonus_color + " " + tr("MSTAT_HOME_B1") + "[/color]\n"
		t += bonus_color + " " + tr("MSTAT_HOME_B2") + "[/color]\n"
		t += bonus_color + " " + tr("MSTAT_HOME_B3") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_HOME_N1") + "[/color]\n"
		if not en_banda_home:
			t += "[color=#ff8844]" + tr("MSTAT_HOME_OUT_OF_BAND") + "[/color]\n"

	if EvoManager.mutation_symbiosis:
		t += "[b][color=green]🌱 " + tr("MSTAT_SIMB_TITLE") + "[/color][/b]\n"
		t += buff + " " + tr("MSTAT_SIMB_B1") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_SIMB_N1") + "[/color]\n"

	if EvoManager.mutation_red_micelial:
		t += "[b][color=#9955ff]🕸️ " + tr("MSTAT_RED_TITLE") + "[/color][/b]\n"
		t += buff + " " + tr("MSTAT_RED_B1") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_RED_N1") + "[/color]\n"

	if EvoManager.mutation_met_oscuro:
		t += "[b][color=#8844aa]🌑 " + tr("MSTAT_MO_TITLE") + "[/color][/b]\n"
		t += buff + " " + tr("MSTAT_MO_B1") + "[/color]\n"
		t += buff + " " + tr("MSTAT_MO_B2") + "[/color]\n"
		t += buff + " " + tr("MSTAT_MO_B3") + "[/color]\n"
		t += buff + " " + tr("MSTAT_MO_B4") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_MO_N1") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_MO_N2") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_MO_N3") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_MO_N4") + "[/color]\n"
		var bio_now: float = BiosphereEngine.biomasa
		var bio_pct: int = int(clamp(bio_now / 100.0 * 100.0, 0.0, 100.0))
		var bar_filled: int = int(bio_pct / 5.0)  # 20 segmentos
		var bio_bar: String = "█".repeat(bar_filled) + "░".repeat(20 - bar_filled)
		var pl_label: String = "+6 PL" if bio_now >= 100.0 else ("+4 PL" if bio_now >= 50.0 else "+2 PL")
		t += "\n[color=#aa66cc]" + tr("MSTAT_MO_SAT") % pl_label + "[/color]\n"
		t += "[color=#8844aa][%s][/color] [color=white]%.0f / 100[/color]\n" % [bio_bar, bio_now]
		t += "[color=#666688]  " + tr("MSTAT_MO_SEAL_HINT") + "[/color]\n"
	elif EvoManager.mutation_depredador:
		t += "[b][color=#ff0055]☠️ " + tr("MSTAT_DEP_TITLE") + "[/color][/b]\n"
		t += buff + " " + tr("MSTAT_DEP_B1") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_DEP_N1") + "[/color]\n"
		var dev: int = EvoManager.met_oscuro_devoured_count
		var bio: float = BiosphereEngine.biomasa
		var money_now: float = EconomyManager.money
		var d_ok: bool = dev >= 3
		var b_ok: bool = bio >= 25.0
		var r_ok: bool = money_now < 1000.0
		t += "\n[color=#aa66cc]" + tr("MSTAT_DEP_ALT") + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if d_ok else "#ff5555"] + tr("MSTAT_DEP_DEVOURED") % dev + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if b_ok else "#ff5555"] + tr("MSTAT_DEP_BIO25") % bio + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if r_ok else "#ff5555"] + tr("MSTAT_DEP_MONEY") % money_now + "[/color]\n"
		t += "  [color=#aaaaaa]" + tr("MSTAT_DEP_SUSTAIN") + "[/color]\n"

	if EvoManager.mutation_parasitism:
		t += "[b][color=#ff4400]🦠 " + tr("MSTAT_PARAS_TITLE") + "[/color][/b]\n"
		t += buff + " " + tr("MSTAT_PARAS_B1") + "[/color]\n"
		t += buff + " " + tr("MSTAT_PARAS_B2") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_PARAS_N1") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_PARAS_N2") + "[/color]\n"
		t += nerf + " " + tr("MSTAT_PARAS_N3") + "[/color]\n"
		var bio: float = BiosphereEngine.biomasa
		var omg: float = StructuralModel.omega
		var eps: float = StructuralModel.epsilon_effective
		var money: float = EconomyManager.money
		t += "\n[color=#ffaa00]" + tr("MSTAT_PARAS_CLOSE_A") + "[/color]\n"
		var a1: bool = bio >= 18.0
		var a2: bool = omg < 0.22
		var a3: bool = eps > 0.45
		t += "  [color=%s]" % ["#00ff88" if a1 else "#ff5555"] + tr("MSTAT_PARAS_BIO18") % bio + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if a2 else "#ff5555"] + tr("MSTAT_PARAS_OMEGA22") % omg + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if a3 else "#ff5555"] + tr("MSTAT_PARAS_EPS45") % eps + "[/color]\n"
		t += "[color=#ffaa00]" + tr("MSTAT_PARAS_CLOSE_B") + "[/color]\n"
		var b1: bool = bio >= 15.0
		var b2: bool = money < 1000.0
		var b3: bool = bio >= 25.0
		t += "  [color=%s]" % ["#00ff88" if (b1 and b2) else "#ff5555"] + tr("MSTAT_PARAS_B15") % [bio, money] + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if b3 else "#ff5555"] + tr("MSTAT_PARAS_B25") % bio + "[/color]\n"
	return t

func build_institution_panel_text(_main: Node) -> String:
	var t := "--- " + tr("INST_ACCOUNTING_HDR") + " ---\n"
	t += "\n--- " + tr("INST_EPS_HDR") + " ---\n"
	t += "%s %s = %s\n" % [epsilon_flag(StructuralModel.epsilon_active, 0.15), tr("INST_EPS_ACTIVE"), snapped(StructuralModel.epsilon_active, 0.01)]
	t += "%s %s = %s\n" % [epsilon_flag(StructuralModel.epsilon_passive, 0.12), tr("INST_EPS_PASSIVE"), snapped(StructuralModel.epsilon_passive, 0.01)]
	t += "%s %s = %s\n" % [epsilon_flag(StructuralModel.epsilon_complex, 0.08), tr("INST_EPS_COMPLEX"), snapped(StructuralModel.epsilon_complex, 0.01)]
	t += tr("INST_OMEGA_MIN") + " = %s\n" % snapped(StructuralModel.omega_min, 0.01)
	t += tr("INST_ACCOUNTING_LVL") % UpgradeManager.level("accounting") + "\n"
	t += tr("INST_AMORT") % int(StructuralModel.get_accounting_effect() * 100.0) + "\n"
	t += "\n" + tr("INST_EPS_PEAK") + " = %s\n" % snapped(StructuralModel.epsilon_peak, 0.01)
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
		t += "\n\n⚖️ " + tr("INST_HOME_MODE")
		t += "\n" + tr("INST_RESILIENCE") % snapped(RunManager.resilience_score, 1)
		t += "\n" + tr("INST_DISTURBANCE") % RunManager.DISTURBANCE_INTERVAL
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2:
		t += "\n" + tr("INST_NET_WARN")
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
		data["header"] = tr("EVO_BIF_TIER1_HEADER")

		var h_t := LegacyManager.trascendencia_count
		var h_ap: Dictionary = EconomyManager.get_active_passive_breakdown()
		var h_ok_red = StructuralModel.unlocked_d and StructuralModel.unlocked_e
		var h_txt := "[center]" + tr("EVO_HOME_DESC_TITLE")

		if h_t >= 1:
			# NG+: condiciones más exigentes
			var eps_eff := StructuralModel.epsilon_runtime
			var h_ok_eps_ng = eps_eff >= 0.05 and eps_eff <= 0.25
			var h_ok_omega_ng = StructuralModel.omega >= 0.55
			var h_ok_acc_ng = acc_lvl >= 2
			var h_ok_delta_ng = EconomyManager.delta_per_sec > 150.0
			var total_flow: float = float(h_ap["activo"]) + float(h_ap["pasivo"])
			var h_ok_bal = total_flow > 0 and (float(h_ap["pasivo"]) / total_flow) >= 0.30
			var h_ok_bio_ng = BiosphereEngine.biomasa >= 1.0 and BiosphereEngine.biomasa < 10.0
			h_txt += "[color=#ff8800]" + tr("EVO_HOME_NG_REQ") + "[/color]\n\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_eps_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_eps_ng else "[ ]"] + tr("EVO_HOME_EPS_NG") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_omega_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_omega_ng else "[ ]"] + tr("EVO_HOME_OMEGA55") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_bal else AccessibilityManager.cno_hex(), "[x]" if h_ok_bal else "[ ]"] + tr("EVO_HOME_PASSIVE30") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_delta_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_delta_ng else "[ ]"] + tr("EVO_HOME_PROD150") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_bio_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_bio_ng else "[ ]"] + tr("EVO_HOME_BIO_NG") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_acc_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_acc_ng else "[ ]"] + tr("EVO_HOME_ACC2") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_red else AccessibilityManager.cno_hex(), "[x]" if h_ok_red else "[ ]"] + tr("EVO_HOME_DE") + "[/color]\n"
		else:
			var h_ok_eps = RunManager.get_en_banda_homeostatica()
			var h_ok_omega = StructuralModel.omega >= 0.40
			var h_ok_delta = EconomyManager.delta_per_sec > 30.0
			var h_ok_bio = BiosphereEngine.biomasa < 12.0
			var h_ok_acc = acc_lvl >= 1
			var h_ok_dual = h_ap["pasivo"] > 0
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_eps else AccessibilityManager.cno_hex(), "[x]" if h_ok_eps else "[ ]"] + tr("EVO_HOME_EPS_BASE") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_omega else AccessibilityManager.cno_hex(), "[x]" if h_ok_omega else "[ ]"] + tr("EVO_HOME_OMEGA40") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_dual else AccessibilityManager.cno_hex(), "[x]" if h_ok_dual else "[ ]"] + tr("EVO_HOME_DUAL") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_delta else AccessibilityManager.cno_hex(), "[x]" if h_ok_delta else "[ ]"] + tr("EVO_HOME_META30") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_bio else AccessibilityManager.cno_hex(), "[x]" if h_ok_bio else "[ ]"] + tr("EVO_HOME_BIO12") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_acc else AccessibilityManager.cno_hex(), "[x]" if h_ok_acc else "[ ]"] + tr("EVO_HOME_ACC1") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_red else AccessibilityManager.cno_hex(), "[x]" if h_ok_red else "[ ]"] + tr("EVO_HOME_DE") + "[/color]\n"

		if EvoManager.mutation_homeostasis and RunManager.homeostasis_timer > 0.1:
			var ratio = min(RunManager.homeostasis_timer / Balance.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0
			h_txt += "\n[color=#ffff00]" + tr("EVO_HOME_STAB_PCT") % int(ratio) + "[/color][/center]"
		else:
			h_txt += "\n[color=#555555]" + tr("EVO_HOME_STAB_REQ") + "[/color][/center]"

		data["homeostasis_text"] = h_txt
		data["homeostasis_ready"] = EvoManager.is_homeostasis_ready()

		var r_ok_hifas = hifas >= 11.5
		var r_ok_bio = BiosphereEngine.biomasa >= 5.0
		var r_ok_eps = StructuralModel.epsilon_runtime < 0.65
		var r_ok_acc = acc_lvl >= 1
		var r_ok_dom = not act_domina

		var r_txt = "[center]" + tr("EVO_RED_DESC_TITLE")
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_hifas else AccessibilityManager.cno_hex(), "[x]" if r_ok_hifas else "[ ]"] + tr("EVO_RED_HIFAS115") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_bio else AccessibilityManager.cno_hex(), "[x]" if r_ok_bio else "[ ]"] + tr("EVO_RED_BIO5") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_eps else AccessibilityManager.cno_hex(), "[x]" if r_ok_eps else "[ ]"] + tr("EVO_RED_EPS065") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_acc else AccessibilityManager.cno_hex(), "[x]" if r_ok_acc else "[ ]"] + tr("EVO_RED_ACC1") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_dom else AccessibilityManager.cno_hex(), "[x]" if r_ok_dom else "[ ]"] + tr("EVO_RED_DOM_PAS") + "[/color][/center]"

		data["red_micelial_text"] = r_txt
		data["red_micelial_ready"] = EvoManager.is_red_micelial_ready()

		var s_ok_hifas = hifas >= 5.0
		var s_ok_eps = StructuralModel.epsilon_runtime >= 0.15 and StructuralModel.epsilon_runtime <= 0.45
		var s_ok_acc = acc_lvl >= 1
		var s_ok_dom = act_domina

		var s_txt = "[center]" + tr("EVO_SIM_DESC_TITLE")
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_hifas else AccessibilityManager.cno_hex(), "[x]" if s_ok_hifas else "[ ]"] + tr("EVO_SIM_HIFAS5") + "[/color]\n"
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_eps else AccessibilityManager.cno_hex(), "[x]" if s_ok_eps else "[ ]"] + tr("EVO_SIM_EPS_RANGE") + "[/color]\n"
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_acc else AccessibilityManager.cno_hex(), "[x]" if s_ok_acc else "[ ]"] + tr("EVO_SIM_ACC1") + "[/color]\n"
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_dom else AccessibilityManager.cno_hex(), "[x]" if s_ok_dom else "[ ]"] + tr("EVO_SIM_DOM_CLICK") + "[/color][/center]"

		data["simbiosis_text"] = s_txt
		data["simbiosis_ready"] = EvoManager.is_simbiosis_ready()

	elif EvoManager.mutation_homeostasis:
		data["header"] = tr("EVO_TIER2_HEADER")
		var works = EvoManager.is_allostasis_ready()

		var h_txt = "[center]" + tr("EVO_ALOS_DESC_TITLE")
		h_txt += "[color=#00ff00]" + tr("EVO_ALOS_BUFF1") + "[/color]\n"
		h_txt += "[color=#00ff00]" + tr("EVO_ALOS_BUFF2") + "[/color]\n"
		h_txt += "[color=#ff4444]" + tr("EVO_ALOS_NERF1") + "[/color]\n"
		h_txt += "[color=#ff4444]" + tr("EVO_ALOS_NERF2") + "[/color][/center]"

		data["allostasis_text"] = h_txt
		data["allostasis_ready"] = works

	else:
		data["header"] = tr("EVO_BIF_HEADER")

		var col_txt = "[center]" + tr("EVO_COL_DESC_TITLE") + \
			"[color=#00ff00]" + tr("EVO_COL_BUFF1") + "[/color]\n" + \
			"[color=#00ff00]" + tr("EVO_COL_BUFF2") + "[/color]\n" + \
			"[color=#ffaa00]" + tr("EVO_COL_NOTE") + "[/color][/center]"
		data["colonization_text"] = col_txt
		data["colonization_ready"] = true

		var has_mechanics = UpgradeManager.level("accounting") >= 2
		var mec_txt = "[center]" + tr("EVO_MEC_DESC_TITLE") + \
			"[color=#00ff00]" + tr("EVO_MEC_BUFF1") + "[/color]\n" + \
			"[color=#00ff00]" + tr("EVO_MEC_BUFF2") + "[/color]\n" + \
			("[color=%s]" % AccessibilityManager.cok_hex() + tr("EVO_MEC_ACC_OK") + "[/color]" if has_mechanics else "[color=%s]" % AccessibilityManager.cno_hex() + tr("EVO_MEC_ACC_FAIL") + "[/color]") + \
			"[/center]"
		data["symbiosis_text"] = mec_txt
		data["symbiosis_ready"] = has_mechanics

	return data

# =====================================================
# EPSILON STICKY LABEL BUILDER
# =====================================================
func build_epsilon_sticky_text(_main: Control) -> String:
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
		var req := Balance.MET_OSCURO_REQUIRED_TIME
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

	# Icons (TextureRect) — Twemoji PNG según ruta/tier para que se vean en web.
	var icon_home: TextureRect = opt_homeostasis.find_child("Icon") as TextureRect
	var icon_col: TextureRect = evo_choice_panel.find_child("OptColonization", true, false).find_child("Icon") as TextureRect
	var icon_sym: TextureRect = evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Icon") as TextureRect

	if data["tier_mode"] == "tier1":
		opt_homeostasis.visible = true
		opt_colonization.visible = true
		opt_symbiosis.visible = true

		EmojiToRichText.set_icon_texture(icon_home, "⚖️")
		EmojiToRichText.set_icon_texture(icon_col, "🕸️")
		EmojiToRichText.set_icon_texture(icon_sym, "🤝")

		opt_homeostasis.find_child("Desc").text = EmojiToRichText.rich(data["homeostasis_text"])
		btn_homeostasis.text = tr("EVO_BTN_EQUIL")
		btn_homeostasis.disabled = not data["homeostasis_ready"]

		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = EmojiToRichText.rich(data["red_micelial_text"])
		btn_colonization.text = tr("EVO_BTN_RAMIF")
		btn_colonization.disabled = not data["red_micelial_ready"]

		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = EmojiToRichText.rich(data["simbiosis_text"])
		btn_symbiosis.text = tr("EVO_BTN_FUSION")
		btn_symbiosis.disabled = not data["simbiosis_ready"]

	elif data["tier_mode"] == "tier2_homeostasis":
		opt_homeostasis.visible = true
		opt_colonization.visible = false
		opt_symbiosis.visible = false

		EmojiToRichText.set_icon_texture(icon_home, "⚖️")

		opt_homeostasis.find_child("Desc").text = EmojiToRichText.rich(data["allostasis_text"])
		btn_homeostasis.text = tr("EVO_BTN_EVOLVE") if data["allostasis_ready"] else tr("EVO_BTN_REQS_FAIL")
		btn_homeostasis.disabled = not data["allostasis_ready"]
		btn_homeostasis.modulate = Color(0, 1, 1)

	else:
		opt_homeostasis.visible = false
		opt_colonization.visible = true
		opt_symbiosis.visible = true

		EmojiToRichText.set_icon_texture(icon_col, "🌱")
		EmojiToRichText.set_icon_texture(icon_sym, "🤝")

		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = EmojiToRichText.rich(data["colonization_text"])
		btn_colonization.text = tr("EVO_BTN_COLONIZE")
		btn_colonization.disabled = not data["colonization_ready"]

		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = EmojiToRichText.rich(data["symbiosis_text"])
		btn_symbiosis.disabled = not data["symbiosis_ready"]
		btn_symbiosis.text = tr("EVO_BTN_INTEG_REQ") if not data["symbiosis_ready"] else tr("EVO_BTN_INTEG")

func update_fungal_cycle_bar() -> void:
	var bar = fungal_cycle_bar

	if EvoManager.red_branch_selected != EvoManager.RedBranch.NONE:
		if is_instance_valid(bar):
			bar.visible = (EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION)
			if bar.visible:
				bar.value = BiosphereEngine.micelio
				if EvoManager.seta_formada:
					bar.tooltip_text = tr("TOOLTIP_CYCLE_COMPLETE")
					bar.value = 100.0
				elif EvoManager.primordio_active:
					var t_left := Balance.PRIMORDIO_DURATION - EvoManager.primordio_timer
					bar.tooltip_text = tr("TOOLTIP_PRIMORDIO") % t_left
				else:
					bar.tooltip_text = tr("TOOLTIP_MICELIO_CYCLE") % int(BiosphereEngine.micelio)

		if is_instance_valid(primordio_button):
			if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
				var puede_iniciar := BiosphereEngine.micelio >= 60.0 and not EvoManager.primordio_active and not EvoManager.seta_formada
				primordio_button.visible = not EvoManager.seta_formada
				primordio_button.disabled = not puede_iniciar
				if EvoManager.primordio_active:
					var t_left := Balance.PRIMORDIO_DURATION - EvoManager.primordio_timer
					primordio_button.text = tr("EVO_PRIM_ACTIVE") % t_left
					primordio_button.disabled = true
				elif puede_iniciar:
					var costo := 20.0 * (1.0 + EvoManager.primordio_abort_count * 0.2)
					primordio_button.text = tr("EVO_PRIM_INIT_FULL") % costo
				else:
					primordio_button.text = tr("EVO_PRIM_INIT_LOW")
			else:
				primordio_button.visible = false

		if is_instance_valid(sporulation_final_button):
			var show_panspermia = LegacyManager.last_run_ending == "ESPORULACIÓN" and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION and EvoManager.primordio_active
			sporulation_final_button.visible = EvoManager.seta_formada or EvoManager.nucleo_conciencia or show_panspermia
			sporulation_final_button.disabled = false

			if EvoManager.nucleo_conciencia:
				sporulation_final_button.text = tr("EVO_BTN_CONNECT_SIN")
				sporulation_final_button.modulate = Color(0.1, 1.0, 1.0)
			elif EvoManager.seta_formada:
				sporulation_final_button.text = tr("EVO_BTN_DISPERSE")
				sporulation_final_button.modulate = Color(0.4, 1.0, 0.2)
			elif show_panspermia:
				if EconomyManager.money >= 100000.0:
					sporulation_final_button.text = tr("EVO_BTN_PANSPERMIA")
					sporulation_final_button.modulate = Color(0.8, 0.2, 1.0)
				else:
					sporulation_final_button.text = tr("EVO_BTN_PAN_REQ")
					sporulation_final_button.disabled = true
					sporulation_final_button.modulate = Color(0.4, 0.1, 0.5)
	else:
		if is_instance_valid(bar): bar.visible = false
		if is_instance_valid(primordio_button): primordio_button.visible = false
		if is_instance_valid(sporulation_final_button): sporulation_final_button.visible = false
