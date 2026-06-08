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

# ========== NG+ DYNAMIC BUTTONS (Panel Derecho) ==========
var _met_oscuro_seal_btn: Button = null
var _esclerocio_btn: Button = null
var _autolisis_btn: Button = null
var _depredador_buytime_btn: Button = null
var _mc_override_btn: Button = null
var _simbiosis_seal_btn: Button = null

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

# =====================================================
# NG+ DYNAMIC BUTTONS
# =====================================================

func _right_panel() -> Node:
	return root.get_node_or_null("RightPanel")

## Libera los botones dinámicos de NG+ al resetear la run (llamado desde main.reset_local_state).
func reset_ng_plus_buttons() -> void:
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.queue_free()
		_met_oscuro_seal_btn = null
	if is_instance_valid(_depredador_buytime_btn):
		_depredador_buytime_btn.queue_free()
		_depredador_buytime_btn = null
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.queue_free()
		_simbiosis_seal_btn = null
	if is_instance_valid(_esclerocio_btn):
		_esclerocio_btn.queue_free()
		_esclerocio_btn = null
	if is_instance_valid(_autolisis_btn):
		_autolisis_btn.queue_free()
		_autolisis_btn = null

## Actualiza todos los botones dinámicos de NG+. Llamar desde _on_ui_tick().
func update_ng_plus_buttons() -> void:
	_update_met_oscuro_seal_button()
	_update_esclerocio_button()
	_update_autolisis_button()
	_update_depredador_buytime_button()
	_update_mc_override_button()
	_update_simbiosis_seal_button()

func _update_met_oscuro_seal_button() -> void:
	if RunManager.run_closed:
		return
	var bio := BiosphereEngine.biomasa
	var pl_seal := 2 if bio < 50.0 else (4 if bio < 100.0 else 6)
	var seal_label := EmojiToRichText.strip("🌑 " + tr("BTN_SEAL_MO") % pl_seal)
	if _met_oscuro_seal_btn == null or not is_instance_valid(_met_oscuro_seal_btn):
		if not EvoManager.mutation_met_oscuro:
			return
		_met_oscuro_seal_btn = Button.new()
		_met_oscuro_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
		_met_oscuro_seal_btn.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
		_met_oscuro_seal_btn.custom_minimum_size = Vector2(0, 70)
		_met_oscuro_seal_btn.pressed.connect(_on_met_oscuro_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_met_oscuro_seal_btn)
			panel.move_child(_met_oscuro_seal_btn, 0)
	if not EvoManager.mutation_met_oscuro or RunManager.run_closed:
		_met_oscuro_seal_btn.visible = false
		return
	_met_oscuro_seal_btn.text = seal_label
	_met_oscuro_seal_btn.visible = true

func _on_met_oscuro_seal_pressed() -> void:
	if RunManager.run_closed:
		return
	var bio := BiosphereEngine.biomasa
	var pl_bonus := 0 if bio < 50.0 else (-2 if bio < 100.0 else 2)
	if pl_bonus < 0:
		LegacyManager.add_pl(-2)
	elif pl_bonus > 0:
		LegacyManager.add_pl(2)
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.visible = false
	var pl_total := 2 if bio < 50.0 else (4 if bio < 100.0 else 6)
	RunManager.close_run("METABOLISMO OSCURO", tr("CLOSE_MO_VOLUNTARIO") % [bio, pl_total])

func _update_esclerocio_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_met_oscuro:
		if is_instance_valid(_esclerocio_btn):
			_esclerocio_btn.visible = false
		return
	var devoured_ok: bool = EvoManager.met_oscuro_devoured_count >= Balance.ESCLEROCIO_DEVOURED_REQ
	var bio_ok: bool = BiosphereEngine.biomasa >= Balance.ESCLEROCIO_BIO_REQ
	var eps_ok: bool = StructuralModel.epsilon_runtime < Balance.ESCLEROCIO_EPS_MAX
	if not (devoured_ok and bio_ok and eps_ok):
		if is_instance_valid(_esclerocio_btn):
			_esclerocio_btn.visible = false
		return
	if _esclerocio_btn == null or not is_instance_valid(_esclerocio_btn):
		_esclerocio_btn = Button.new()
		_esclerocio_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
		_esclerocio_btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.75))
		_esclerocio_btn.custom_minimum_size = Vector2(0, 70)
		_esclerocio_btn.pressed.connect(_on_esclerocio_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_esclerocio_btn)
			panel.move_child(_esclerocio_btn, 0)
	_esclerocio_btn.text = EmojiToRichText.strip("🌑 " + tr("BTN_ESCLEROCIO"))
	_esclerocio_btn.visible = true

func _on_esclerocio_pressed() -> void:
	if RunManager.run_closed:
		return
	if is_instance_valid(_esclerocio_btn):
		_esclerocio_btn.visible = false
	RunManager.close_run("ESCLEROCIO OSCURO", tr("CLOSE_ESCLEROCIO"))

func _update_autolisis_button() -> void:
	# Ocultar si MO no activo, ya autólisis activa, o run cerrada
	if RunManager.run_closed or not EvoManager.mutation_met_oscuro or EvoManager.mutation_autolisis:
		if is_instance_valid(_autolisis_btn):
			_autolisis_btn.visible = false
		return
	var bio_ok: bool = BiosphereEngine.biomasa >= Balance.AUTOLISIS_BIO_REQ
	var upgrades_ok: bool = UpgradeManager.get_owned_levels_count() >= Balance.AUTOLISIS_UPGRADES_REQ
	if not (bio_ok and upgrades_ok):
		if is_instance_valid(_autolisis_btn):
			_autolisis_btn.visible = false
		return
	if _autolisis_btn == null or not is_instance_valid(_autolisis_btn):
		_autolisis_btn = Button.new()
		_autolisis_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
		_autolisis_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.1))
		_autolisis_btn.custom_minimum_size = Vector2(0, 70)
		_autolisis_btn.pressed.connect(_on_autolisis_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_autolisis_btn)
			panel.move_child(_autolisis_btn, 0)
	_autolisis_btn.text = EmojiToRichText.strip("🔥 " + tr("BTN_AUTOLISIS"))
	_autolisis_btn.visible = true

func _on_autolisis_pressed() -> void:
	if RunManager.run_closed or EvoManager.mutation_autolisis:
		return
	if is_instance_valid(_autolisis_btn):
		_autolisis_btn.visible = false
	EvoManager.activate_autolisis()

func _update_depredador_buytime_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_depredador or EvoManager.mutation_met_oscuro:
		if is_instance_valid(_depredador_buytime_btn):
			_depredador_buytime_btn.visible = false
		return
	var cost := EvoManager.depredador_time_cost()
	var ext := Balance.DEP_TIME_EXTENSION
	var btn_label := EmojiToRichText.strip("⏳ " + tr("BTN_DEP_BUYTIME") % [ext, cost])
	if _depredador_buytime_btn == null or not is_instance_valid(_depredador_buytime_btn):
		_depredador_buytime_btn = Button.new()
		_depredador_buytime_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(18))
		_depredador_buytime_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
		_depredador_buytime_btn.custom_minimum_size = Vector2(0, 60)
		_depredador_buytime_btn.pressed.connect(_on_depredador_buytime_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_depredador_buytime_btn)
			panel.move_child(_depredador_buytime_btn, 0)
	_depredador_buytime_btn.text = btn_label
	_depredador_buytime_btn.disabled = BiosphereEngine.biomasa < cost
	_depredador_buytime_btn.visible = true

func _on_depredador_buytime_pressed() -> void:
	EvoManager.buy_depredador_time()
	_update_depredador_buytime_button()

func _update_mc_override_button() -> void:
	if RunManager.run_closed or not LegacyManager.get_buff_value("mente_colmena"):
		if is_instance_valid(_mc_override_btn):
			_mc_override_btn.visible = false
		return
	if _mc_override_btn == null or not is_instance_valid(_mc_override_btn):
		_mc_override_btn = Button.new()
		_mc_override_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
		_mc_override_btn.add_theme_color_override("font_color", Color(0.65, 0.45, 1.0))
		_mc_override_btn.custom_minimum_size = Vector2(0, 50)
		_mc_override_btn.pressed.connect(_on_mc_override_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_mc_override_btn)
			panel.move_child(_mc_override_btn, 0)
	if RunManager.mc_burst_timer > 0.0:
		_mc_override_btn.text = EmojiToRichText.strip(tr("BTN_MC_ACTIVE") % RunManager.mc_burst_timer)
		_mc_override_btn.disabled = true
	elif RunManager.mc_cooldown_timer > 0.0:
		_mc_override_btn.text = EmojiToRichText.strip(tr("BTN_MC_COOLDOWN") % RunManager.mc_cooldown_timer)
		_mc_override_btn.disabled = true
	else:
		_mc_override_btn.text = EmojiToRichText.strip(tr("BTN_MC_READY") % Balance.MC_BURST_DURATION)
		_mc_override_btn.disabled = false
	_mc_override_btn.visible = true

func _on_mc_override_pressed() -> void:
	RunManager.activate_mc_burst()
	_update_mc_override_button()

func _update_simbiosis_seal_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_symbiosis:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	if RunManager.run_time < 60.0:
		return
	if _simbiosis_seal_btn == null or not is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn = Button.new()
		_simbiosis_seal_btn.text = EmojiToRichText.strip("🌱 " + tr("BTN_SEAL_SIMB"))
		_simbiosis_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
		_simbiosis_seal_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		_simbiosis_seal_btn.custom_minimum_size = Vector2(0, 70)
		_simbiosis_seal_btn.pressed.connect(_on_simbiosis_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_simbiosis_seal_btn)
			panel.move_child(_simbiosis_seal_btn, 0)
	_simbiosis_seal_btn.visible = true

func _on_simbiosis_seal_pressed() -> void:
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.visible = false
	RunManager.close_run("SIMBIOSIS", tr("CLOSE_SIMBIOSIS_BASE"))

# =====================================================
# LEGACY STORE (Banco Genético)
# =====================================================

func open_legacy_panel() -> void:
	var lp := scene.legacy_panel as Control
	var lp_title := lp.find_child("Title")
	if lp_title is RichTextLabel:
		lp_title.clear()
		lp_title.append_text(EmojiToRichText.rich("[center]🧬 " + tr("BANCO_GENETICO_TITLE") + "[/center]"))
	lp.visible = true
	scene.get_node("DimmerBackground").visible = true
	var vp: Rect2 = scene.get_viewport_rect()
	var margin := 24.0
	var ps := Vector2(vp.size.x - margin * 2, vp.size.y - margin * 2)
	lp.custom_minimum_size = ps
	lp.size = ps
	lp.position = Vector2(margin, margin)
	refresh_legacy_store()
	update_legacy_indicators()

func close_legacy_panel() -> void:
	scene.legacy_panel.visible = false
	scene.get_node("DimmerBackground").visible = false

func refresh_legacy_store() -> void:
	update_legacy_indicators()
	var pl := LegacyManager.legacy_points
	var buffer := LegacyManager.internal_spores_total
	scene.pl_label.text = tr("GAME_PL_COUNTER") % [pl, buffer]
	for child in scene.legacy_list.get_children():
		child.queue_free()

	var col_groups: Array = [
		["economia"],
		["estructura"],
		["biologia", "conocimiento"],
		["ruta"],
		["ng_plus", "secreto"],
	]
	var cat_colors: Dictionary = {
		"economia": Color(0.9, 0.85, 0.4), "estructura": Color(0.5, 0.8, 1.0),
		"biologia": Color(0.4, 0.9, 0.5),  "conocimiento": Color(0.8, 0.6, 1.0),
		"ruta": Color(1.0, 0.65, 0.2),     "ng_plus": Color(0.9, 0.3, 0.9),
		"secreto": Color(0.5, 0.5, 0.5),
	}

	var h_cols: HBoxContainer = HBoxContainer.new()
	h_cols.add_theme_constant_override("separation", 10)
	h_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene.legacy_list.add_child(h_cols)

	for group in col_groups:
		var col: VBoxContainer = VBoxContainer.new()
		col.custom_minimum_size.x = 300
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 3)
		var col_has_items: bool = false
		for cat in group:
			var cat_ids: Array = []
			for id in LegacyManager.LEGACY_DEFS:
				var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
				if def.get("cat", "") == cat and LegacyManager.is_revealed(id):
					cat_ids.append(id)
			if cat_ids.is_empty():
				continue
			if col_has_items:
				col.add_child(HSeparator.new())
			var hdr: Label = Label.new()
			hdr.text = "-- %s --" % tr("LEGACY_CAT_" + cat.to_upper())
			hdr.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
			hdr.modulate = cat_colors.get(cat, Color.WHITE)
			hdr.custom_minimum_size.y = 22
			col.add_child(hdr)
			for id in cat_ids:
				col.add_child(_build_legacy_item(id))
			col_has_items = true
		if col_has_items:
			h_cols.add_child(col)
		else:
			col.queue_free()

func _build_legacy_item(id: String) -> Control:
	var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
	var lvl: int = LegacyManager.get_buff_level(id)
	var max_lvl: int = int(def.get("max_level", 1))
	var is_maxed: bool = lvl >= max_lvl
	var cost: int = LegacyManager.get_current_cost(id)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)

	var name_str: String = tr("LEGACY_" + id.to_upper() + "_NAME")
	if max_lvl > 1:
		name_str += "  [%d/%d]" % [lvl, max_lvl]
	var l_title: Label = Label.new()
	l_title.text = name_str
	l_title.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	l_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var is_enabled: bool = LegacyManager.buff_enabled.get(id, true)
	if lvl > 0 and not is_enabled:
		l_title.modulate = Color(0.45, 0.45, 0.45)
	elif is_maxed:
		l_title.modulate = Color.GREEN
	elif lvl > 0:
		l_title.modulate = Color(0.5, 0.9, 0.6)

	var l_desc: Label = Label.new()
	l_desc.text = tr("LEGACY_" + id.to_upper() + "_FLAVOR")
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_desc.add_theme_font_size_override("font_size", AccessibilityManager.fs(9))
	l_desc.modulate = Color(0.6, 0.6, 0.6)

	v.add_child(l_title)
	v.add_child(l_desc)

	if lvl > 0:
		var is_on: bool = LegacyManager.buff_enabled.get(id, true)
		var toggle_btn: Button = Button.new()
		toggle_btn.custom_minimum_size.y = 22
		toggle_btn.text = tr("GAME_BUFF_ACTIVE") if is_on else tr("GAME_BUFF_INACTIVE")
		toggle_btn.modulate = Color(0.4, 1.0, 0.5) if is_on else Color(0.6, 0.6, 0.6)
		toggle_btn.pressed.connect(func():
			var new_state: bool = LegacyManager.toggle_buff_enabled(id)
			if id == "mente_colmena" and not RunManager.run_closed:
				RunManager.mente_colmena_active = new_state
				scene.add_lap(tr("LAP_MC_IA_MANUAL") % (tr("GAME_BUFF_ACTIVE").to_lower() if new_state else tr("GAME_BUFF_INACTIVE").to_lower()))
			refresh_legacy_store()
			show_toast(tr("GAME_BUFF_ACTIVE") + ": " + def.get("name", id) if new_state else tr("GAME_BUFF_INACTIVE") + ": " + def.get("name", id))
			scene.update_ui()
		)
		v.add_child(toggle_btn)
		if not is_maxed:
			var lvl_btn: Button = Button.new()
			lvl_btn.custom_minimum_size.y = 22
			lvl_btn.text = tr("GAME_BTN_LEVEL") % [lvl + 1, cost]
			lvl_btn.disabled = not LegacyManager.can_afford(id)
			lvl_btn.pressed.connect(func():
				if LegacyManager.purchase_legacy(id):
					refresh_legacy_store()
					show_toast("Banco: Compraste " + def.get("name", id))
			)
			v.add_child(lvl_btn)
	else:
		var btn: Button = Button.new()
		btn.custom_minimum_size.y = 22
		if not LegacyManager.is_unlockable(id):
			btn.text = tr("GAME_BTN_LOCKED")
			btn.disabled = true
		elif def.get("cost", 0) == 0:
			btn.text = tr("GAME_BTN_FREE")
		else:
			btn.text = "%d PL" % cost
			btn.disabled = not LegacyManager.can_afford(id)
		btn.pressed.connect(func():
			if LegacyManager.purchase_legacy(id):
				refresh_legacy_store()
				show_toast("Banco: Compraste " + def.get("name", id))
		)
		v.add_child(btn)

	v.add_child(HSeparator.new())
	return v

func update_legacy_indicators() -> void:
	var ind := scene.get_node_or_null("HeaderBar/HeaderContent/LegacyIndicators")
	if not is_instance_valid(ind):
		return
	ind.mouse_filter = Control.MOUSE_FILTER_PASS
	for c in ind.get_children():
		c.queue_free()

	var _add_chip := func(text: String, tooltip: String, color: Color) -> void:
		var chip := Label.new()
		chip.text = EmojiToRichText.strip(text)
		chip.tooltip_text = tooltip
		chip.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		chip.modulate = color
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.mouse_entered.connect(func(): _show_header_tip(tooltip))
		chip.mouse_exited.connect(func(): _clear_header_tip())
		ind.add_child(chip)

	var click_mult := 1.0
	var click_tip := "Click legado:"
	if LegacyManager.get_buff_value("impulso_manual"):
		click_mult *= 2.0;   click_tip += "\n• Impulso Manual ×2.0"
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		var rs_mult: float = min(1.0 + BiosphereEngine.biomasa * 0.05, 2.5)
		click_mult *= rs_mult
		click_tip += "\n• Resonancia Simbionte ×%.2f (bio=%.1f)" % [rs_mult, BiosphereEngine.biomasa]
	if LegacyManager.get_buff_value("aura_dorada"):
		click_mult *= 2.5;   click_tip += "\n• Aura Dorada ×2.5 (solo click)"
	if LegacyManager.get_buff_value("semilla_cosmica"):
		click_mult *= 2.0;   click_tip += "\n• Semilla Cósmica ×2.0"
	var eco := LegacyManager.get_effect_value("all_income_mult")
	if eco > 0.0:
		click_mult *= (1.0 + eco)
		click_tip += "\n• Eco Primordial ×%.2f" % (1.0 + eco)
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		var cc := 1.0 + LegacyManager.trascendencia_count * 0.05
		click_mult *= cc
		click_tip += "\n• Convergencia Cíclica ×%.2f (T=%d)" % [cc, LegacyManager.trascendencia_count]
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		click_tip += "\n• Metabolismo Oscuro ×1.5 (si ε>0.40)*"
	var cog_mult_val: float = LegacyManager.get_effect_value("cognitivo_income_mult_per_level")
	if cog_mult_val > 0.0:
		click_tip += "\n• Resonancia Cognitiva +5%/nv.cog*"

	var pasivo_mult := 1.0
	var pas_tip := "Pasivo legado:"
	if LegacyManager.get_buff_value("semilla_cosmica"):
		pasivo_mult *= 2.0;  pas_tip += "\n• Semilla Cósmica ×2.0"
	if LegacyManager.get_buff_value("semilla_cosmica_oscura"):
		pasivo_mult *= Balance.SEMILLA_OSCURA_PASIVO_MULT
		pas_tip += "\n• Semilla Cósmica Oscura ×%.1f" % Balance.SEMILLA_OSCURA_PASIVO_MULT
	if LegacyManager.get_buff_value("mente_colmena"):
		pasivo_mult *= 3.0;  pas_tip += "\n• Mente Colmena ×3.0"
	if eco > 0.0:
		pasivo_mult *= (1.0 + eco)
		pas_tip += "\n• Eco Primordial ×%.2f" % (1.0 + eco)
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		pas_tip += "\n• Metabolismo Oscuro ×1.8 (si e>0.40)*"
	if LegacyManager.get_buff_value("glitch_persistente"):
		pas_tip += "\n• Glitch Persistente ×1.15 (red micelial)*"
	if cog_mult_val > 0.0:
		pas_tip += "\n• Resonancia Cognitiva +5%/nv.cog*"

	var omega_min := 0.0
	var omega_tip := "O garantizado:"
	if LegacyManager.get_buff_value("plasticidad_adaptativa"):
		omega_min = max(omega_min, 0.30);  omega_tip += "\n• Plasticidad Adaptativa =0.30"
	if LegacyManager.get_buff_value("legado_alostasis"):
		omega_min = max(omega_min, 0.45);  omega_tip += "\n• Resiliencia Alostática =0.45"
	if LegacyManager.get_buff_value("legado_homeorresis"):
		omega_min = max(omega_min, 0.55);  omega_tip += "\n• Trascendencia Cristalina ≥0.55"
	var omega_rec := LegacyManager.get_effect_value("omega_recovery_speed")
	if omega_rec > 0.0:
		omega_tip += "\n• Regeneración Ω ×%.2f" % omega_rec
	if LegacyManager.get_buff_value("cristalizacion_permanente"):
		omega_tip += "\n• Cristalización Permanente: shock -50%"

	if click_mult > 1.01:
		_add_chip.call("click×%.1f" % click_mult, click_tip, Color(0.4, 0.95, 0.5))
	if pasivo_mult > 1.01:
		_add_chip.call("pas×%.1f" % pasivo_mult, pas_tip, Color(0.85, 0.45, 1.0))
	var alostasis_active := LegacyManager.get_buff_value("legado_alostasis")
	var eq_bonus_active := LegacyManager.get_effect_value("omega_min_per_disturbance") > 0.0
	if omega_min > 0.0 or omega_rec > 0.0 or LegacyManager.get_buff_value("cristalizacion_permanente") \
			or alostasis_active or eq_bonus_active:
		var omega_lbl := "Ω≥%.2f" % omega_min if omega_min > 0.0 else "Ω↑"
		if alostasis_active:
			omega_tip += "\n• Resiliencia Alostática: +0.02/shock*"
		if eq_bonus_active:
			omega_tip += "\n• Equilibrio Heredado: +0.04/shock*"
		if (alostasis_active or eq_bonus_active or omega_rec > 0.0) and "↑" not in omega_lbl:
			omega_lbl += " ↑"
		_add_chip.call(omega_lbl, omega_tip, Color(0.4, 0.9, 1.0))
	if LegacyManager.get_buff_value("deriva_esporada"):
		_add_chip.call("PL×1.25", "Deriva Esporada\nPL ganados ×1.25", Color(0.9, 0.85, 0.4))
	var bio_mult := 1.0
	var bio_tip := "Bio legado:"
	if LegacyManager.get_buff_value("sangre_negra"):
		bio_mult *= 1.3;  bio_tip += "\n• Sangre Negra: inicio ×1.30"
	var absorb := LegacyManager.get_effect_value("nutrient_absorb_mult")
	if absorb > 0.0:
		bio_tip += "\n• Absorción Mejorada +%.0f%%" % (absorb * 100)
	if bio_mult > 1.01 or absorb > 0.0:
		_add_chip.call("bio×%.1f" % bio_mult, bio_tip, Color(0.85, 0.25, 0.25))
	if RunManager.mente_colmena_active:
		_add_chip.call(EmojiToRichText.strip("🧠IA"), tr("CHIP_MENTE_COLMENA"), Color(0.9, 0.3, 0.9))
	if RunManager.is_memoria_oscura_active():
		var mo_tip := tr("CHIP_MEMORIA_OSCURA_TIP")
		if RunManager._has_permanent_dark_legacy():
			mo_tip += "\n" + tr("CHIP_MEMORIA_OSCURA_PERM")
		_add_chip.call(EmojiToRichText.strip("🌑 " + tr("CHIP_MEMORIA_OSCURA")), mo_tip, Color(0.82, 0.55, 1.0))

func update_lab_metrics() -> void:
	var contrib: Dictionary = EconomyManager.get_contribution_breakdown()
	var ap: Dictionary = EconomyManager.get_active_passive_breakdown()

	if sys_delta_label:
		sys_delta_label.text = "∂$ estimado / s = +%s" % snapped(contrib.total, 0.01)

	if delta_total_label:
		var t: float = contrib.total
		var t_str: String
		if t >= 1_000_000_000.0:
			t_str = "+$%.2fB/s" % (t / 1_000_000_000.0)
		elif t >= 1_000_000.0:
			t_str = "+$%.2fM/s" % (t / 1_000_000.0)
		elif t >= 1_000.0:
			t_str = "+$%.1fK/s" % (t / 1_000.0)
		else:
			t_str = "+$%.2f/s" % t
		delta_total_label.text = t_str

	update_timer(RunManager.run_time)

	if sys_active_passive_label:
		var pct_act := int(ap.activo)
		var pct_pas := int(ap.pasivo)
		var bar_len := 20
		var filled := int(pct_act / 100.0 * bar_len)
		var bar := ""
		for i in range(bar_len):
			if i < filled:
				bar += "[color=#00ff88]█[/color]"
			else:
				bar += "[color=#ffcc00]█[/color]"
		var act_col := "[color=#00ff88]" if pct_act >= pct_pas else "[color=#aaaaaa]"
		var pas_col := "[color=#ffcc00]" if pct_pas > pct_act else "[color=#aaaaaa]"
		var push_str := format_compact(ap.push_abs)
		var pass_str := format_compact(ap.passive_abs)
		var txt := act_col + "▲ ACT  %d%%  +%s/s[/color]\n" % [pct_act, push_str]
		txt += pas_col + "▼ PAS  %d%%  +%s/s[/color]\n" % [pct_pas, pass_str]
		txt += "[color=#555555][%s][/color]" % bar
		sys_active_passive_label.clear()
		sys_active_passive_label.append_text(EmojiToRichText.rich(txt))

	if sys_breakdown_label:
		var c_pct := int(contrib.click)
		var d_pct := int(contrib.d)
		var e_pct := int(contrib.e)
		var bar_len := 20
		var fc := int(c_pct / 100.0 * bar_len)
		var fd := int(d_pct / 100.0 * bar_len)
		var fe: int = int(max(bar_len - fc - fd, 0))
		var bar := "[color=#ff8844]" + "█".repeat(fc) + "[/color]"
		bar += "[color=#44aaff]" + "█".repeat(fd) + "[/color]"
		bar += "[color=#00ffcc]" + "█".repeat(fe) + "[/color]"
		var click_str := format_compact(ap.push_abs)
		var auto_str := format_compact(EconomyManager.get_auto_income_effective())
		var trueq_str := format_compact(EconomyManager.get_trueque_income_effective())
		var txt := "[color=#ff8844]● Click %d%% +%s/s[/color]  " % [c_pct, click_str]
		txt += "[color=#44aaff]● Manual %d%% +%s/s[/color]  " % [d_pct, auto_str]
		txt += "[color=#00ffcc]● Trueque %d%% +%s/s[/color]\n" % [e_pct, trueq_str]
		txt += "[color=#555555][%s][/color]" % bar
		# NG+ bonus live estimate — solo si hay al menos 1 trascendencia
		if LegacyManager.trascendencia_count >= 1:
			var ng_route := RunManager.get_predicted_route()
			if not ng_route.is_empty():
				var ng_info := RunManager.compute_ng_bonus(ng_route)
				var ng_col := "[color=#ffd700]" if ng_info.saturated else "[color=#aaaaaa]"
				var cap_mark := " ✓" if ng_info.saturated else ""
				var ng_line := ng_col + "✦ NG+ %d/%d%s — %s[/color]" % [ng_info.bonus, ng_info.cap, cap_mark, ng_route]
				txt += "\n" + ng_line
		sys_breakdown_label.clear()
		sys_breakdown_label.append_text(EmojiToRichText.rich(txt))

func update_core_labels() -> void:
	update_money(EconomyManager.money)
	if formula_label:
		formula_label.clear()
		formula_label.append_text(EmojiToRichText.rich(UITextBuilders.build_formula_text(scene)))
	if click_stats_label:
		click_stats_label.clear()
		click_stats_label.append_text(EmojiToRichText.rich(UITextBuilders.update_click_stats_panel(scene)))

func update_buttons() -> void:
	for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
		if btn.has_method("update_appearance"):
			btn.update_appearance(EconomyManager.money)
	var rb: Button = scene.get("_reset_btn") as Button
	if is_instance_valid(rb):
		if RunManager.run_closed:
			rb.text = tr("GAME_BTN_NEW_RUN")
			rb.modulate = Color(0.4, 0.85, 0.55)
		else:
			rb.text = tr("GAME_BTN_RESET")
			rb.modulate = Color(0.8, 0.4, 0.4)

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

func get_reactor_color() -> Color:
	if RunManager.run_closed and RunManager.final_route == "COLAPSO DEPREDATORIO":
		return Color(0.12, 0.0, 0.02)
	if EvoManager.mutation_autolisis:
		return Color(0.85, 0.3, 0.0)
	if EvoManager.mutation_met_oscuro:
		return Color(0.53, 0.27, 0.67)
	if EvoManager.mutation_depredador:
		return Color(1.0, 0.0, 0.33)
	if RouteManager.is_active("vacio"):
		return Color(0.75, 0.2, 1.0)
	if EvoManager.seta_formada:
		return Color(0.65, 1.2, 0.2)
	if EvoManager.mutation_sporulation:
		return Color(0.7, 1.0, 0.4)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		return Color(0.45, 1.0, 0.05)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		return Color(0.0, 0.9, 1.0)
	if EvoManager.mutation_hyperassimilation:
		if RunManager._fractura_carga_timer > 0.0:
			var t := clampf(RunManager._fractura_carga_timer / RunManager.FRACTURA_CARGA_DURATION, 0.0, 1.0)
			return Color(0.95, 0.05, 0.05).lerp(Color(1.1, 0.85, 0.05), t)
		return Color(0.95, 0.05, 0.05)
	if EvoManager.mutation_homeorhesis:
		return Color(0.55, 1.0, 0.92)
	if EvoManager.mutation_allostasis:
		return Color(0.2, 1.0, 0.88)
	if EvoManager.mutation_homeostasis:
		return Color(0.05, 0.88, 0.68)
	if EvoManager.mutation_parasitism:
		return Color(1.0, 0.45, 0.0)
	if EvoManager.nucleo_conciencia:
		return Color(0.2, 0.5, 1.0)
	if EvoManager.mutation_red_micelial:
		return Color(0.3, 1.0, 0.3)
	if EvoManager.mutation_symbiosis:
		return Color(0.4, 0.9, 0.7)
	return Color(0.15, 0.65, 1.0)
