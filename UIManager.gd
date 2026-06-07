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
var colonize_pulse_button    # Botón dedicado de Empuje de Frontera (Colonización)
var _fungal_bar_label        # Label de número sobre FungalCycleBar (lazy)
var _fungal_bar_style        # StyleBoxFlat de relleno verde de FungalCycleBar (lazy)

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
	colonize_pulse_button = _find_scene("ColonizePulseButton")

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
	var badge: Dictionary = RouteManager.get_badge()
	var text: String = badge.get("text", "")
	if text == "":
		route_badge_label.visible = false
		return
	var color: Color = badge.get("color", Color.WHITE)
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

# --- Helpers de HUD (movidos a UITextBuilders.gd) ---
# Los métodos delegados se mantienen como wrappers para compatibilidad
# con sitios de llamada legacy hasta que se migren.

func build_formula_text(_main: Node) -> String:
	return UITextBuilders.build_formula_text(_main)

func build_formula_values(_main: Node) -> String:
	return ""

func build_marginal_contribution(_main: Node) -> String:
	return ""

func update_click_stats_panel(_main: Node) -> String:
	return UITextBuilders.update_click_stats_panel(_main)


# --- Helpers ---

func update_appearance(money: float):
	for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
		if btn.has_method("update_appearance"):
			btn.update_appearance(money)

func get_system_phase(omega: float) -> String:
	return UITextBuilders.get_system_phase(omega)

func format_time(t: float) -> String:
	return UITextBuilders.format_time(t)

func format_compact(v: float) -> String:
	return UITextBuilders.format_compact(v)

func epsilon_flag(v: float, limit: float) -> String:
	return UITextBuilders.epsilon_flag(v, limit)

func build_evo_checklist(_main: Node) -> String:
	return UITextBuilders.build_evo_checklist(_main)

func _build_run_end_lore(route: String) -> String:
	return UITextBuilders._build_run_end_lore(route)

# =====================================================
#  BUILDERS DE TEXTO — Genoma y Mutaciones
#  (Movidos desde main.gd para centralizar builders UI)
# =====================================================

func build_genome_text() -> String:
	return UITextBuilders.build_genome_text()

func build_mutation_status_text() -> String:
	return UITextBuilders.build_mutation_status_text()

func build_institution_panel_text(_main: Node) -> String:
	return UITextBuilders.build_institution_panel_text(_main)

## Actualiza el panel de mutación en la columna central (genoma + ruta + efectos + checklist)
func update_mutation_center_panel(main: Node = null) -> void:
	if not is_instance_valid(genome_summary_label):
		genome_summary_label = _find("GenomeSummaryLabel")
		if not is_instance_valid(genome_summary_label):
			return
	var t := UITextBuilders.build_genome_text()
	if not RunManager.run_closed:
		t += UITextBuilders.build_mutation_status_text()
	if RunManager.homeostasis_mode:
		t += "\n\n⚖️ " + tr("INST_HOME_MODE")
		t += "\n" + tr("INST_RESILIENCE") % snapped(RunManager.resilience_score, 1)
		t += "\n" + tr("INST_DISTURBANCE") % RunManager.DISTURBANCE_INTERVAL
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2:
		t += "\n" + tr("INST_NET_WARN")
	var _post_tras: bool = RouteManager.has_active_route()
	if main != null and not _post_tras:
		t += UITextBuilders.build_evo_checklist(main)
	genome_summary_label.visible = true
	genome_summary_label.clear()
	genome_summary_label.append_text(EmojiToRichText.rich(t))

# =====================================================
# PANEL DE BIFURCACIÓN Y BARRA DE CICLO FÚNGICO
# =====================================================

func update_bifurcation_panel() -> void:
	if not is_instance_valid(evo_choice_panel) or not evo_choice_panel.visible:
		return

	var data := UITextBuilders.build_bifurcation_data()

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
				_ensure_fungal_bar_style(bar)
				if EvoManager.seta_formada:
					bar.tooltip_text = tr("TOOLTIP_CYCLE_COMPLETE")
					bar.value = EvoManager.panspermia_charge if EvoManager.is_panspermia_window() else 100.0
					if _fungal_bar_style != null:
						_fungal_bar_style.bg_color = Color(0.45, 0.85, 0.15)
				elif EvoManager.primordio_active:
					bar.value = EvoManager.primordio_timer / Balance.PRIMORDIO_BIO_MATURE * 100.0
					var t_left := Balance.PRIMORDIO_BIO_MATURE - EvoManager.primordio_timer
					bar.tooltip_text = tr("TOOLTIP_PRIMORDIO") % t_left
					if _fungal_bar_style != null:
						var integ: float = EvoManager.primordio_integrity / Balance.PRIMORDIO_INTEGRITY_MAX
						_fungal_bar_style.bg_color = Color(0.85, 0.2, 0.15).lerp(Color(0.45, 0.85, 0.15), integ)
				else:
					bar.tooltip_text = tr("TOOLTIP_MICELIO_CYCLE") % int(BiosphereEngine.micelio)
					if _fungal_bar_style != null:
						_fungal_bar_style.bg_color = Color(0.45, 0.85, 0.15)
				if is_instance_valid(_fungal_bar_label):
					if EvoManager.primordio_active:
						_fungal_bar_label.text = tr("PRIMORDIO_BAR_LABEL") % [int(bar.value), int(EvoManager.primordio_integrity)]
					else:
						_fungal_bar_label.text = (tr("PANSPERMIA_BAR_LABEL") % [int(EvoManager.panspermia_charge), int(EvoManager.panspermia_heat)]) if EvoManager.is_panspermia_window() else (tr("COLONIZ_BAR_LABEL") % int(bar.value))
				if is_instance_valid(colonize_pulse_button):
					colonize_pulse_button.visible = EvoManager.is_colonizacion_pushable()
					if colonize_pulse_button.visible:
						colonize_pulse_button.text = tr("COLONIZ_BTN_EXPAND") % Balance.MICELIO_PULSE_GAIN

		if is_instance_valid(primordio_button):
			if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
				var puede_iniciar := BiosphereEngine.micelio >= 60.0 and not EvoManager.primordio_active and not EvoManager.seta_formada
				primordio_button.visible = not EvoManager.seta_formada
				primordio_button.disabled = not (puede_iniciar or EvoManager.primordio_active)
				if EvoManager.primordio_active:
					primordio_button.text = tr("PRIMORDIO_BTN_REGAR") % [Balance.PRIMORDIO_REGAR_COST_BIO, BiosphereEngine.biomasa]
					primordio_button.disabled = false  # siempre clickeable: el click riega o avisa "sin biomasa"
				elif puede_iniciar:
					var costo := 20.0 * (1.0 + EvoManager.primordio_abort_count * 0.2)
					primordio_button.text = tr("EVO_PRIM_INIT_FULL") % costo
				else:
					primordio_button.text = tr("EVO_PRIM_INIT_LOW")
			elif EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS and EvoManager.primordio_active and not EvoManager.nucleo_conciencia:
				primordio_button.visible = true
				primordio_button.disabled = false
				primordio_button.text = tr("NUCLEO_BTN_INTEGRAR") % [int(EvoManager.nucleo_sync), int(EvoManager.nucleo_temp)]
			else:
				primordio_button.visible = false

		if is_instance_valid(sporulation_final_button):
			sporulation_final_button.visible = (EvoManager.seta_formada or EvoManager.nucleo_conciencia) and not RunManager.run_closed
			sporulation_final_button.disabled = false

			if EvoManager.nucleo_conciencia:
				sporulation_final_button.text = tr("EVO_BTN_CONNECT_SIN")
				sporulation_final_button.modulate = Color(0.1, 1.0, 1.0)
			elif EvoManager.seta_formada and EvoManager.is_panspermia_window():
				var p_cost: float = EvoManager.panspermia_pulse_cost()
				sporulation_final_button.text = tr("EVO_BTN_PANSPERMIA") % [int(EvoManager.panspermia_charge), int(EvoManager.panspermia_heat)]
				sporulation_final_button.disabled = EconomyManager.money < p_cost
				sporulation_final_button.modulate = Color(0.8, 0.2, 1.0)
			elif EvoManager.seta_formada:
				sporulation_final_button.text = tr("EVO_BTN_DISPERSE")
				sporulation_final_button.modulate = Color(0.4, 1.0, 0.2)
	else:
		if is_instance_valid(bar): bar.visible = false
		if is_instance_valid(primordio_button): primordio_button.visible = false
		if is_instance_valid(sporulation_final_button): sporulation_final_button.visible = false
		if is_instance_valid(colonize_pulse_button): colonize_pulse_button.visible = false

## Crea (lazy) el relleno verde lima + el label de número sobre la barra de frontera micelial.
func _ensure_fungal_bar_style(bar) -> void:
	if _fungal_bar_style == null:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.45, 0.85, 0.15)  # verde lima (rama colonización)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		_fungal_bar_style = sb
		bar.add_theme_stylebox_override("fill", sb)
	if not is_instance_valid(_fungal_bar_label):
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
		lbl.add_theme_constant_override("shadow_outline_size", 3)
		lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
		bar.add_child(lbl)
		_fungal_bar_label = lbl
