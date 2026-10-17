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

# NG+ buttons: logica en NGPlusButtonManager.gd
var _ng_buttons: NGPlusButtonManager

func setup(ui_root: Control):
	root = ui_root
	scene = ui_root.get_parent()  # UIRoot (scene root) — contains HeaderBar as sibling

	_ng_buttons = NGPlusButtonManager.new()
	_ng_buttons.setup(root, scene)

	# Limpiar referencias stale de botones dinámicos de sesiones anteriores.
	# Los nodos fueron liberados con la escena anterior; sin esto, is_instance_valid
	# daría false pero la comparación == null también fallaría, causando que _make_autofagia_btn
	# crea el botón pero lo añade a un panel que ya no existe en la escena nueva.
	reset_ng_plus_buttons()

	# Señal del dado d20 de Fagocitosis Doble (conectar una sola vez)
	if not EvoManager.autofagia_dice_rolled.is_connected(_ng_buttons._on_autofagia_dice_rolled):
		EvoManager.autofagia_dice_rolled.connect(_ng_buttons._on_autofagia_dice_rolled)

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
		# Abrir por defecto — el tscn lo define como visible=false para lazy-init
		genome_toggle_btn.set_pressed_no_signal(true)
		genome_scroll.visible = true

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
	# Subtítulos siempre visibles debajo del valor de cada métrica del header
	var metric_subtitles := {
		"EpsilonMetric":   "HEADER_SUB_EPSILON",
		"OmegaMetric":     "HEADER_SUB_OMEGA",
		"BiomasaMetric":   "HEADER_SUB_BIOMASA",
		"HifasMetric":     "HEADER_SUB_HIFAS",
		"NutrientesMetric":"HEADER_SUB_NUTRIENTES",
	}
	for container_name in metric_subtitles:
		var container = _find_scene(container_name)
		if container:
			var sub := Label.new()
			sub.text = tr(metric_subtitles[container_name])
			sub.add_theme_font_size_override("font_size", AccessibilityManager.fs(9))
			sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.75))
			sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(sub)

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
	if money_label:
		var _safe := amount if not (is_nan(amount) or is_inf(amount)) else 0.0
		money_label.text = tr("UI_MONEY") + str(round(_safe))

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
		header_omega_value.text = ("%.4f" if omega < 0.01 else "%.2f") % omega
	if header_biomasa_value:
		header_biomasa_value.text = "%.1f/%.0f" % [biomasa, biomasa_max]
	if header_hifas_value:
		header_hifas_value.text = "%.1f" % hifas
	if header_nutrientes_value:
		# Dos efectos explícitos: descuento de upgrades (-15%/50, cap -45%) y combustible de
		# biomasa (aporte base = hifas·√nut·0.02, lo que realmente "hace" el nutriente).
		var nut_disc := int(clamp(floor(nutrientes / 50.0) * 0.15, 0.0, 0.45) * 100.0)
		var bio_rate := hifas * sqrt(nutrientes) * 0.02
		var disc_part := " · -%d%% upg" % nut_disc if nut_disc > 0 else ""
		var bio_part := " · +%.1f bio/s" % bio_rate if bio_rate > 0.005 else ""
		header_nutrientes_value.text = "%.1f%s%s" % [nutrientes, disc_part, bio_part]

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
		structural_omg_value.text = ("%.4f" if omega < 0.01 else "%.2f") % omega
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
	var t: String
	if EvoManager.mutation_huesped_soberano:
		if RunManager.run_closed and RunManager.final_route == "HUÉSPED SOBERANO":
			t = UITextBuilders.build_huesped_soberano_closed_text()
		elif not RunManager.run_closed:
			t = UITextBuilders.build_huesped_soberano_panel_text()
		else:
			t = UITextBuilders.build_genome_text()
	elif EvoManager.mutation_micelio_omnisciente:
		if RunManager.run_closed and RunManager.final_route == "MICELIO OMNISCIENTE":
			t = UITextBuilders.build_micelio_omnisciente_closed_text()
		elif not RunManager.run_closed:
			t = UITextBuilders.build_micelio_omnisciente_panel_text()
		else:
			t = UITextBuilders.build_genome_text()
	elif EvoManager.mutation_coro_simbiotico:
		if RunManager.run_closed and RunManager.final_route == "CORO SIMBIÓTICO":
			t = UITextBuilders.build_coro_simbiotico_closed_text()
		elif not RunManager.run_closed:
			t = UITextBuilders.build_coro_simbiotico_panel_text()
		else:
			t = UITextBuilders.build_genome_text()
	elif EvoManager.mutation_caos_orquestado:
		if RunManager.run_closed and RunManager.final_route == "CAOS ORQUESTADO":
			t = UITextBuilders.build_caos_orquestado_closed_text()
		elif not RunManager.run_closed:
			t = UITextBuilders.build_caos_orquestado_panel_text()
		else:
			t = UITextBuilders.build_genome_text()
	elif EvoManager.mutation_fusion_catabolica:
		if RunManager.run_closed and RunManager.final_route == "FUSIÓN CATABÓLICA":
			t = _build_fusion_catabolica_closed_text()
		elif not RunManager.run_closed:
			t = _build_fusion_catabolica_panel_text()
		else:
			t = UITextBuilders.build_genome_text()
	elif EvoManager.mutation_ayuno_primordial:
		if RunManager.run_closed and RunManager.final_route == "AYUNO PRIMORDIAL":
			t = UITextBuilders.build_ayuno_primordial_closed_text()
		elif not RunManager.run_closed:
			t = UITextBuilders.build_ayuno_primordial_panel_text()
		else:
			t = UITextBuilders.build_genome_text()
	else:
		t = UITextBuilders.build_genome_text()
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
	set_rich_text(genome_summary_label, t)

func _build_fusion_catabolica_closed_text() -> String:
	return UITextBuilders.build_fusion_catabolica_closed_text()

func _build_fusion_catabolica_panel_text() -> String:
	return UITextBuilders.build_fusion_catabolica_panel_text()

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
						if EvoManager.is_panspermia_window():
							var n_pulses: int = PrimordioLogic.panspermia_launch_estimate()
							_fungal_bar_label.text = tr("PANSPERMIA_BAR_LABEL") % [int(EvoManager.panspermia_charge), int(EvoManager.panspermia_heat),
								n_pulses, format_compact(n_pulses * EvoManager.panspermia_pulse_cost())]
						else:
							_fungal_bar_label.text = tr("COLONIZ_BAR_LABEL") % int(bar.value)
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
# NG+ DYNAMIC BUTTONS -- delegado a NGPlusButtonManager
# =====================================================

func update_ng_plus_buttons() -> void: _ng_buttons.update_ng_plus_buttons()
func reset_ng_plus_buttons() -> void: _ng_buttons.reset_ng_plus_buttons()

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

	# Chip visual ESC en esquina superior derecha — hermano de LegacyPanel
	# (no hijo: PanelContainer estiraría cualquier hijo a pantalla completa)
	const ESC_BTN_W := 80.0
	const ESC_BTN_H := 44.0
	var esc_btn := scene.get_node_or_null("LegacyEscBtn") as Button
	if not is_instance_valid(esc_btn):
		esc_btn = Button.new()
		esc_btn.name = "LegacyEscBtn"
		esc_btn.text = "ESC"
		esc_btn.z_index = 30
		esc_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.08, 0.05, 0.12, 0.97)
		s.set_border_width_all(2)
		s.border_color = Color(0.75, 0.3, 0.95, 0.9)
		s.set_corner_radius_all(10)
		s.content_margin_left = 8.0; s.content_margin_right = 8.0
		s.content_margin_top = 4.0;  s.content_margin_bottom = 4.0
		var sh := s.duplicate() as StyleBoxFlat
		sh.bg_color = Color(0.16, 0.08, 0.22, 1.0)
		sh.border_color = Color(0.9, 0.4, 1.0, 1.0)
		esc_btn.add_theme_stylebox_override("normal", s)
		esc_btn.add_theme_stylebox_override("hover", sh)
		esc_btn.add_theme_stylebox_override("pressed", sh)
		esc_btn.add_theme_color_override("font_color", Color(0.92, 0.85, 1.0, 1.0))
		esc_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		esc_btn.custom_minimum_size = Vector2(ESC_BTN_W, ESC_BTN_H)
		esc_btn.pressed.connect(close_legacy_panel)
		scene.add_child(esc_btn)
	# Posición: esquina sup-der del panel (lp.position + lp.size)
	esc_btn.position = lp.position + Vector2(ps.x - ESC_BTN_W - 10.0, 10.0)
	esc_btn.size = Vector2(ESC_BTN_W, ESC_BTN_H)
	esc_btn.visible = true

	refresh_legacy_store()
	update_legacy_indicators()

func close_legacy_panel() -> void:
	var lp := scene.get_node_or_null("LegacyPanel")
	if lp: lp.visible = false
	var db := scene.get_node_or_null("DimmerBackground")
	if db: db.visible = false
	var esc_btn := scene.get_node_or_null("LegacyEscBtn") as Button
	if is_instance_valid(esc_btn):
		esc_btn.visible = false

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
		["transmutaciones", "ng_plus", "secreto"],
	]
	var cat_colors: Dictionary = {
		"economia": Color(0.9, 0.85, 0.4), "estructura": Color(0.5, 0.8, 1.0),
		"biologia": Color(0.4, 0.9, 0.5),  "conocimiento": Color(0.8, 0.6, 1.0),
		"ruta": Color(1.0, 0.65, 0.2),     "ng_plus": Color(0.9, 0.3, 0.9),
		"transmutaciones": Color(0.2, 0.9, 0.75), "secreto": Color(0.5, 0.5, 0.5),
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

	var is_key: bool = id in TransmutationLogic.key_ids() or id == "transmut_ayuno"
	if lvl > 0 and is_key:
		# Llave de involución comprada: permanente y sin interruptor (la decisión es en la run).
		var key_lbl: Button = Button.new()
		key_lbl.custom_minimum_size.y = 22
		key_lbl.text = tr("GAME_KEY_OWNED_TRANSMUT") if id in TransmutationLogic.key_ids() else tr("GAME_KEY_OWNED_SOMBRA")
		key_lbl.modulate = Color(0.4, 1.0, 0.5)
		key_lbl.focus_mode = Control.FOCUS_NONE
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(key_lbl)
	elif lvl > 0:
		var is_on: bool = LegacyManager.buff_enabled.get(id, true)
		var toggle_btn: Button = Button.new()
		toggle_btn.custom_minimum_size.y = 22
		toggle_btn.text = tr("GAME_BUFF_ACTIVE") if is_on else tr("GAME_BUFF_INACTIVE")
		toggle_btn.modulate = Color(0.4, 1.0, 0.5) if is_on else Color(0.6, 0.6, 0.6)
		toggle_btn.pressed.connect(func():
			var new_state: bool = LegacyManager.toggle_buff_enabled(id)
			if id == "mente_colmena" and not RunManager.run_closed:
				# Solo cancela rafaga activa si se desactiva el buff.
				# NO activa directamente: la rafaga solo arranca con activate_mc_burst().
				if not new_state:
					RunManager.mente_colmena_active = false
					RunManager.mc_burst_timer = 0.0
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

	# click× / pas×: multiplicadores de legado y banco cósmico ACTIVOS ahora mismo, leídos de la
	# misma tabla que usa la economía (IncomeModifiers) → el chip no puede desincronizarse.
	var click_mult := 1.0
	var click_tip := "Click legado:"
	if LegacyManager.get_buff_value("impulso_manual"):
		click_mult *= 2.0;   click_tip += "
• Impulso Manual ×2.0"
	for m in IncomeModifiers.active("click", ["legacy", "cosmic"]):
		click_mult *= m.factor
		click_tip += "
• %s ×%.2f" % [m.name, m.factor]

	var pasivo_mult := 1.0
	var pas_tip := "Pasivo legado:"
	for m in IncomeModifiers.active("passive", ["legacy", "cosmic"]):
		pasivo_mult *= m.factor
		pas_tip += "
• %s ×%.2f" % [m.name, m.factor]

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
		var omega_fmt: String = "%.4f" if omega_min < 0.01 else "%.2f"
		var omega_lbl := ("Ω≥" + omega_fmt) % omega_min if omega_min > 0.0 else "Ω↑"
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
	if EvoManager.mutation_necrosis:
		var nec_tip := tr("CHIP_NECROSIS_TIP") % [EvoManager.necromasa, EvoManager.necrosis_mult(), EvoManager.necrosis_index() * 100.0, EvoManager.necrosis_toxicidad * 100.0]
		var tox_col := Color(0.4, 0.5, 0.25).lerp(Color(0.7, 0.2, 0.2), EvoManager.necrosis_toxicidad)
		_add_chip.call("Ν %.0f ×%.1f ☣%d%%" % [EvoManager.necromasa, EvoManager.necrosis_mult(), int(EvoManager.necrosis_toxicidad * 100.0)], nec_tip, tox_col)
	if EvoManager.mutation_omega_cero:
		var oc_tip := tr("CHIP_OMEGA_CERO_TIP") % [EvoManager.omega_cero_phi, Balance.OMEGA_CERO_PHI_TARGET, EvoManager.omega_cero_phi_mult(), EvoManager.omega_cero_omega]
		_add_chip.call("Φ %.0f/%.0f" % [EvoManager.omega_cero_phi, Balance.OMEGA_CERO_PHI_TARGET], oc_tip, Color(0.72, 0.6, 0.88))
	if EvoManager.mutation_remision:
		var _rem_in: bool = EvoManager.remision_in_band()
		var rem_tip := tr("CHIP_REMISION_TIP") % [EvoManager.remision_omega, EvoManager.remision_band_center(), int(EvoManager.remision_progress() * 100.0), BiosphereEngine.biomasa]
		var rem_col := Color(0.27, 0.87, 0.53) if _rem_in else Color(0.85, 0.55, 0.3)
		_add_chip.call("Θ %d%% · bio %.0f" % [int(EvoManager.remision_progress() * 100.0), BiosphereEngine.biomasa], rem_tip, rem_col)
	if RunManager.is_memoria_oscura_active():
		var mo_tip := tr("CHIP_MEMORIA_OSCURA_TIP")
		if RunManager._has_permanent_dark_legacy():
			mo_tip += "\n" + tr("CHIP_MEMORIA_OSCURA_PERM")
		_add_chip.call(EmojiToRichText.strip("🌑 " + tr("CHIP_MEMORIA_OSCURA")), mo_tip, Color(0.82, 0.55, 1.0))
	var _all_inc := LegacyManager.get_effect_value("all_income_mult")
	if _all_inc > 0.0:
		_add_chip.call("Motor x%.2f" % (1.0 + _all_inc), "Legado: Motor Fundido\n+%.0f%% a todo el ingreso" % (_all_inc * 100.0), Color(0.97, 0.76, 0.05))
	if LegacyManager.get_buff_value("legado_primicia_del_vacio") and RunManager.run_time < Balance.AYUNO_LEGACY_DURATION:
		var _t := clampf(RunManager.run_time / Balance.AYUNO_LEGACY_DURATION, 0.0, 1.0)
		var _m := lerpf(Balance.AYUNO_LEGACY_MULT_START, 1.0, _t)
		_add_chip.call("Primicia x%.2f" % _m, "Legado: Primicia del Vacío\nPasivo x%.2f → x1 (%.0fs restantes)" % [_m, Balance.AYUNO_LEGACY_DURATION - RunManager.run_time], Color(0.55, 0.75, 0.95))

func update_lab_metrics() -> void:
	var contrib: Dictionary = EconomyManager.get_contribution_breakdown()
	var ap: Dictionary = EconomyManager.get_active_passive_breakdown()

	if sys_delta_label:
		var _total_safe: float = contrib.total if not (is_nan(contrib.total) or is_inf(contrib.total)) else 0.0
		sys_delta_label.text = "∂$ estimado / s = +%s" % snapped(_total_safe, 0.01)

	if delta_total_label:
		var t: float = contrib.total if not (is_nan(contrib.total) or is_inf(contrib.total)) else 0.0
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
		set_rich_text(sys_active_passive_label, txt)

	if sys_breakdown_label:
		var c_pct := clampi(int(contrib.click), 0, 100)
		var d_pct := clampi(int(contrib.d), 0, 100)
		var e_pct := clampi(int(contrib.e), 0, 100)
		var bar_len := 20
		var fc := clampi(int(c_pct / 100.0 * bar_len), 0, bar_len)
		var fd := clampi(int(d_pct / 100.0 * bar_len), 0, bar_len - fc)
		var fe: int = bar_len - fc - fd
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
		set_rich_text(sys_breakdown_label, txt)

## Escribe BBCode en un RichTextLabel sólo si cambió. clear()+append_text() re-parsea el BBCode,
## reemplaza emojis y re-maqueta el texto aunque sea idéntico; los paneles que se refrescan en
## cada tick de UI pagaban eso 10 veces por segundo. REGLA: un label escrito con este helper debe
## escribirse SIEMPRE con él (también para vaciarlo), o el caché queda desincronizado.
func set_rich_text(label: RichTextLabel, bbcode: String) -> void:
	# has_meta antes de get_meta: en Godot 4.5 get_meta(k, null) trata null como "sin default" y loguea error.
	if label.has_meta("_rich_src") and label.get_meta("_rich_src") == bbcode:
		return
	label.set_meta("_rich_src", bbcode)
	label.clear()
	if bbcode != "":
		label.append_text(EmojiToRichText.rich(bbcode))

func update_core_labels() -> void:
	update_money(EconomyManager.money)
	if formula_label:
		set_rich_text(formula_label, UITextBuilders.build_formula_text(scene))
	if click_stats_label:
		set_rich_text(click_stats_label, UITextBuilders.update_click_stats_panel(scene))

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
	if RunManager.run_closed:
		match RunManager.final_route:
			"ESCLEROCIO OSCURO":
				return Color(0.23, 0.14, 0.06)  # marrón: un esclerocio real es una masa dura y oscura
			"AUTOFAGIA NECRÓTICA":
				return Color(0.36, 0.08, 0.03)  # vino-óxido
			"NECROSIS CONTROLADA":
				return Color(0.1, 0.28, 0.02)
			"METABOLISMO OSCURO":
				return Color(0.22, 0.08, 0.32)
			"DEPREDADOR DE REALIDADES":
				return Color(0.25, 0.0, 0.04)
			"COLAPSO SINTÉTICO":
				return Color(0.0, 0.23, 0.19)  # verde petróleo
			"COLAPSO DEPREDATORIO":
				return Color(0.12, 0.0, 0.02)
			"REMISIÓN METABÓLICA":
				return Color(1.0, 0.95, 0.84)  # marfil: la familia Redención es luz
			"FUSIÓN CATABÓLICA":
				return Color(0.45, 0.30, 0.01)  # ámbar oscuro: oro metabolico, distinto del teal de Homeostasis
			"AYUNO PRIMORDIAL":
				return Color(0.55, 0.62, 0.70)  # plateado frío: el silencio grabado en el genoma
			"CAOS ORQUESTADO":
				return Color(0.42, 0.04, 0.35)  # fucsia profundo: el caos dirigido, en reposo
			"CORO SIMBIÓTICO":
				return Color(0.66, 0.27, 0.18)  # coral profundo: el ritmo, en silencio
			"MICELIO OMNISCIENTE":
				return Color(0.42, 0.25, 0.78)  # violeta profundo: la red que ve, en reposo
			"HUÉSPED SOBERANO":
				return Color(0.12, 0.23, 0.56)  # índigo profundo: el pacto, en reposo
		# Cualquier otro final (Simbiosis, Homeostasis, Esporulación, …): el color vivo de la ruta,
		# apagado — antes caía en un gris genérico que no decía qué ruta se cerró.
		return _live_reactor_color().darkened(0.45)
	return _live_reactor_color()


## Color del núcleo mientras la run está abierta (también base del color de cierre por defecto).
func _live_reactor_color() -> Color:
	if EvoManager.mutation_omega_cero:
		return Color(0.65, 0.55, 0.88)  # lila pálido (síntesis del árbol oscuro)
	if EvoManager.mutation_remision:
		return Color(1.0, 0.95, 0.84)  # marfil (floración; familia Redención = luz)
	if EvoManager.mutation_autolisis:
		return Color(0.65, 0.04, 0.18)
	if EvoManager.mutation_necrosis:
		return Color(0.25, 0.5, 0.08)  # verde necrótico muerto (apagado, distinto del lima brillante de Esporulación)
	if EvoManager.mutation_met_oscuro:
		return Color(0.53, 0.27, 0.67)
	if EvoManager.mutation_depredador:
		return Color(1.0, 0.0, 0.33)
	if RouteManager.is_active("vacio"):
		return Color(0.75, 0.2, 1.0)
	if EvoManager.seta_formada:
		return Color(0.88, 0.69, 0.44)  # beige de sombrero
	if EvoManager.mutation_sporulation:
		return Color(0.78, 1.0, 0.63)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		return Color(0.69, 1.0, 0.1)  # lima
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		return Color(0.0, 0.9, 1.0)
	# TRANSMUTACIONES: complemento de su evolución, separado para distinguirse (paleta 2026-10-16).
	if EvoManager.mutation_huesped_soberano:
		if EvoManager.huesped_hunger > Balance.HUESPED_BAND_HI:
			return Color(0.85, 0.3, 0.45)  # muerde: el azul se enrojece
		# índigo apagado → vivo según el nivel de confianza
		return Color(0.14, 0.15, 0.5).lerp(Color(0.29, 0.32, 1.0), clampf(HuespedSoberanoLogic.level() / 5.0, 0.0, 1.0))
	if EvoManager.mutation_micelio_omnisciente:
		if MicelioOmniscienteLogic.full_nodes() >= MicelioOmniscienteLogic.NODES.size():
			return Color(0.95, 0.8, 1.25)  # lila casi blanco: la red completa
		# violeta apagado → vivo según cuánto de la red está conectada
		var frac: float = MicelioOmniscienteLogic.connected_total() / (Balance.MICELIO_NODE_MAX * MicelioOmniscienteLogic.NODES.size())
		return Color(0.35, 0.2, 0.55).lerp(Color(0.72, 0.42, 1.0), clampf(frac, 0.0, 1.0))
	if EvoManager.mutation_coro_simbiotico:
		if CoroSimbioticoLogic.score_done():
			return Color(1.25, 0.72, 0.62)  # coral casi blanco: partitura completa
		# coral apagado → coral vivo según el combo
		return Color(0.55, 0.22, 0.18).lerp(Color(1.0, 0.42, 0.36), clampf(float(EvoManager.coro_combo) / Balance.CORO_COMBO_CAP, 0.0, 1.0))
	if EvoManager.mutation_caos_orquestado:
		if EvoManager.caos_burst_timer > 0.0:
			return Color(1.2, 0.4, 1.0)  # fucsia encendido: el colapso dirigido
		# fucsia apagado → encendido según ε: se ve cuánto caos tenés cargado
		return Color(0.5, 0.08, 0.42).lerp(Color(1.0, 0.17, 0.82), clampf(StructuralModel.epsilon_runtime, 0.0, 1.0))
	if EvoManager.mutation_fusion_catabolica:
		if EvoManager.fusion_burst_timer > 0.0:
			return Color(1.1, 0.92, 0.12)  # oro brillante durante ráfaga
		return Color(0.97, 0.76, 0.05)  # ámbar/oro: energía metabólica estable
	if EvoManager.mutation_ayuno_primordial:
		if EvoManager.ayuno_burst_active:
			return Color(1.0, 1.0, 1.05)  # blanco brillante durante el burst
		return Color(0.15, 0.18, 0.22)  # casi negro con toque azul frío: vacío productivo
	if EvoManager.mutation_hyperassimilation:
		if RunManager._fractura_carga_timer > 0.0:
			var t := clampf(RunManager._fractura_carga_timer / RunManager.FRACTURA_CARGA_DURATION, 0.0, 1.0)
			return Color(0.95, 0.05, 0.05).lerp(Color(0.9, 0.96, 1.05), t)  # destello blanco cristal
		return Color(0.95, 0.05, 0.05)
	if EvoManager.mutation_homeorhesis:
		return Color(0.71, 1.0, 0.94)  # menta casi blanca
	if EvoManager.mutation_allostasis:
		return Color(0.0, 0.66, 0.54)  # turquesa profundo
	if EvoManager.mutation_homeostasis:
		return Color(0.05, 0.88, 0.68)
	if EvoManager.mutation_parasitism:
		return Color(1.0, 0.45, 0.0)
	if EvoManager.nucleo_conciencia:
		return Color(0.66, 0.77, 1.0)  # celeste pálido
	if EvoManager.mutation_red_micelial:
		return Color(0.3, 1.0, 0.3)
	if EvoManager.mutation_symbiosis:
		return Color(1.0, 0.56, 0.82)  # rosa orquídea (Biología = naranja → rosa)
	return Color(0.15, 0.65, 1.0)
