extends Panel
# DebugPanel.gd — Solo activo en OS.is_debug_build(). F1 para toggle.

var _main: Node
var _info_label: RichTextLabel

const MUTATIONS := [
	"hiperasimilacion", "parasitismo", "red_micelial", "esporulacion",
	"simbiosis", "homeostasis", "allostasis", "depredador", "met_oscuro"
]

func init(main_ref: Node) -> void:
	_main = main_ref
	_build_ui()


func _build_ui() -> void:
	var vp := get_viewport_rect()
	position = Vector2(vp.size.x * 0.25, 40)
	size = Vector2(vp.size.x * 0.5, vp.size.y - 80)
	modulate = Color(1, 1, 1, 0.97)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	scroll.add_child(root)

	var title := Label.new()
	title.text = "DEBUG PANEL  [F1 para cerrar]"
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color(1, 0.4, 0.4)
	root.add_child(title)

	root.add_child(HSeparator.new())
	_build_recursos(root)
	root.add_child(HSeparator.new())
	_build_mutaciones(root)
	root.add_child(HSeparator.new())
	_build_eventos(root)
	root.add_child(HSeparator.new())
	_build_info(root)
	root.add_child(HSeparator.new())
	_build_zona_peligrosa(root)


func _build_recursos(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "RECURSOS"
	lbl.modulate = Color(0.9, 0.85, 0.4)
	parent.add_child(lbl)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)

	_add_resource_row(grid, "Dinero", func(): EconomyManager.money += 10_000, func(): EconomyManager.money += 1_000_000)
	_add_resource_row(grid, "Biomasa", func(): BiosphereEngine.biomasa = min(BiosphereEngine.biomasa + 5.0, 12.0), func(): BiosphereEngine.biomasa = 12.0)
	_add_resource_row(grid, "Hifas", func(): BiosphereEngine.hifas = min(BiosphereEngine.hifas + 3.0, 12.0), func(): BiosphereEngine.hifas = 12.0)
	_add_resource_row(grid, "Micelio", func(): BiosphereEngine.micelio = min(BiosphereEngine.micelio + 2.0, 12.0), func(): BiosphereEngine.micelio = 12.0)
	_add_resource_row(grid, "ε runtime", func(): StructuralModel.epsilon_runtime = min(StructuralModel.epsilon_runtime + 0.1, 1.0), func(): StructuralModel.epsilon_runtime = 0.5)
	_add_resource_row(grid, "Run time", func(): RunManager.run_time += 300.0, func(): RunManager.run_time += 1800.0)


func _add_resource_row(grid: GridContainer, label: String, fn_small: Callable, fn_big: Callable) -> void:
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(lbl)

	var sep := Control.new()
	sep.custom_minimum_size.x = 4
	grid.add_child(sep)

	var b1 := Button.new()
	b1.text = "+poco"
	b1.custom_minimum_size = Vector2(70, 24)
	b1.add_theme_font_size_override("font_size", 10)
	b1.pressed.connect(fn_small)
	grid.add_child(b1)

	var b2 := Button.new()
	b2.text = "+mucho"
	b2.custom_minimum_size = Vector2(70, 24)
	b2.add_theme_font_size_override("font_size", 10)
	b2.pressed.connect(fn_big)
	grid.add_child(b2)


func _build_mutaciones(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "MUTACIONES"
	lbl.modulate = Color(0.5, 0.9, 0.6)
	parent.add_child(lbl)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	parent.add_child(flow)

	for id in MUTATIONS:
		var btn := Button.new()
		btn.text = id.replace("_", " ")
		btn.custom_minimum_size = Vector2(130, 26)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(func():
			EvoManager.activate_mutation(id)
			UIManager.show_toast("DEBUG: Mutación %s activada" % id)
			_main.update_ui()
		)
		flow.add_child(btn)


func _build_eventos(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "EVENTOS"
	lbl.modulate = Color(1.0, 0.65, 0.3)
	parent.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)

	_add_event_btn(hbox, "Perturbación", func(): RunManager.trigger_disturbance())
	_add_event_btn(hbox, "Primordio", func(): EvoManager.try_iniciar_primordio())
	_add_event_btn(hbox, "+5 min", func(): RunManager.run_time += 300.0)
	_add_event_btn(hbox, "+30 min", func(): RunManager.run_time += 1800.0)


func _add_event_btn(parent: HBoxContainer, label: String, fn: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(100, 28)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(fn)
	parent.add_child(btn)


func _build_info(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "INFO EN TIEMPO REAL"
	lbl.modulate = Color(0.5, 0.8, 1.0)
	parent.add_child(lbl)

	_info_label = RichTextLabel.new()
	_info_label.bbcode_enabled = true
	_info_label.fit_content = true
	_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_label.add_theme_font_size_override("normal_font_size", 10)
	parent.add_child(_info_label)


func _build_zona_peligrosa(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "ZONA PELIGROSA"
	lbl.modulate = Color(1.0, 0.2, 0.2)
	parent.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)

	var btn_reset := Button.new()
	btn_reset.text = "Reset Run"
	btn_reset.custom_minimum_size = Vector2(120, 30)
	btn_reset.modulate = Color(1.0, 0.5, 0.2)
	btn_reset.pressed.connect(func():
		_main.reset_local_state()
		UIManager.show_toast("DEBUG: Run reseteada")
	)
	hbox.add_child(btn_reset)

	var btn_wipe := Button.new()
	btn_wipe.text = "Wipe Save"
	btn_wipe.custom_minimum_size = Vector2(120, 30)
	btn_wipe.modulate = Color(1.0, 0.2, 0.2)
	btn_wipe.pressed.connect(func():
		SaveManager.delete_save_and_restart()
	)
	hbox.add_child(btn_wipe)

	var btn_tutorial := Button.new()
	btn_tutorial.text = "Reset Tutorial"
	btn_tutorial.custom_minimum_size = Vector2(120, 30)
	btn_tutorial.modulate = Color(0.7, 0.7, 1.0)
	btn_tutorial.pressed.connect(func():
		TutorialManager.reset_tutorial()
		_main.show_system_toast("DEBUG: Tutorial reiniciado")
	)
	hbox.add_child(btn_tutorial)


func refresh_info() -> void:
	if not is_instance_valid(_info_label):
		return
	var t := ""
	t += "[b]Economía[/b]\n"
	t += "  money=%.0f  delta=%.2f/s  mu=%.3f\n" % [EconomyManager.money, EconomyManager.get_passive_total(), EconomyManager.cached_mu]
	t += "[b]Biosfera[/b]\n"
	t += "  biomasa=%.2f  hifas=%.2f  micelio=%.2f\n" % [BiosphereEngine.biomasa, BiosphereEngine.hifas, BiosphereEngine.micelio]
	t += "[b]Estructura[/b]\n"
	t += "  ε=%.3f  Ω=%.3f  persist=%.3f\n" % [StructuralModel.epsilon_runtime, StructuralModel.omega, StructuralModel.persistence_dynamic]
	t += "[b]Run[/b]\n"
	t += "  run_time=%.0fs  PL=%d  tras=%d  cerrada=%s\n" % [RunManager.run_time, LegacyManager.legacy_points, LegacyManager.trascendencia_count, str(RunManager.run_closed)]
	t += "[b]Genoma[/b]\n"
	for k in EvoManager.genome:
		var s: String = EvoManager.genome[k]
		if s != "dormido":
			t += "  %s → %s\n" % [k, s]
	_info_label.text = t

