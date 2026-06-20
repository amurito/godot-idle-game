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
			# depredador y met_oscuro requieren prerequisitos — forzarlos en debug
			if id == "depredador":
				EvoManager.mutation_homeostasis = false
				EvoManager.mutation_red_micelial = false
				EvoManager.mutation_symbiosis = false
				EvoManager.mutation_parasitism = false
			elif id == "met_oscuro":
				EvoManager.mutation_depredador = true
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

	# ── DEBUG ESCLEROCIO OSCURO (temporal) ──
	var hbox_esc := HBoxContainer.new()
	hbox_esc.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_esc)
	# Siembra una carga durmiente: la Memoria Oscura queda activa (chip + efectos) en esta y futuras runs.
	_add_event_btn(hbox_esc, "Sembrar Esclerocio", func():
		LegacyManager.dark_legacy_charges += 1
		LegacyManager.save_legacy()
		print("🌑 [DEBUG] dark_legacy_charges = %d" % LegacyManager.dark_legacy_charges))
	# Fuerza el cruce: desbloquea el legado semilla_cosmica_oscura en el Banco Genético.
	_add_event_btn(hbox_esc, "Cruce Panspermia", func():
		LegacyManager.esclerocio_panspermia_done = true
		LegacyManager.save_legacy()
		print("🦠 [DEBUG] esclerocio_panspermia_done = true — Semilla Cósmica Oscura desbloqueada"))

	# ── DEBUG METABOLISMO OSCURO / NECROSIS / AUTOFAGIA ──
	var hbox_nec := HBoxContainer.new()
	hbox_nec.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_nec)
	# Activa Met.Oscuro forzando el prerequisito Depredador.
	_add_event_btn(hbox_nec, "Activar MO", func():
		EvoManager.mutation_depredador = true
		EvoManager.activate_met_oscuro()
		UIManager.update_ng_plus_buttons()
		_main.update_ui()
		print("⚗️ [DEBUG] Met.Oscuro activado"))
	# Fuerza MO + Necrosis activa para testear el loop de doble economía.
	_add_event_btn(hbox_nec, "Activar Necrosis", func():
		EvoManager.mutation_depredador = true
		EvoManager.mutation_met_oscuro = true
		EvoManager.activate_necrosis()
		UIManager.update_ng_plus_buttons()
		_main.update_ui()
		print("🦠 [DEBUG] Necrosis activada — Ω = %.4f" % EvoManager.necrosis_omega))
	# Fuerza MO + Autofagia para testear el loop de devours.
	_add_event_btn(hbox_nec, "Activar Autofagia", func():
		EvoManager.mutation_depredador = true
		EvoManager.mutation_met_oscuro = true
		EvoManager.activate_autolisis()
		UIManager.update_ng_plus_buttons()
		_main.update_ui()
		print("🧬 [DEBUG] Autofagia activada — devours = %d" % EvoManager.autolisis_devour_count))

	var hbox_nec2 := HBoxContainer.new()
	hbox_nec2.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_nec2)
	# Regala Necromasa para comprar Agentes sin grindear.
	_add_event_btn(hbox_nec2, "+5000 Ν", func():
		EvoManager.necromasa += 5000.0
		print("🧫 [DEBUG] Necromasa = %.0f" % EvoManager.necromasa))
	# Marca HOMEORHESIS como cerrada para testear el cross.
	_add_event_btn(hbox_nec2, "Marcar Homeorhesis", func():
		LegacyManager.endings_achieved["HOMEORHESIS"] = true
		LegacyManager.save_legacy()
		print("♾️ [DEBUG] HOMEORHESIS marcada — cross Plasticidad Terminal listo"))

	var hbox_oc := HBoxContainer.new()
	hbox_oc.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_oc)
	# Otorga el permiso del Banco + marca las 3 rutas para testear el desbloqueo de Omega-Cero.
	_add_event_btn(hbox_oc, "Desbloq. Omega-Cero", func():
		LegacyManager.endings_achieved["AUTOFAGIA NECRÓTICA"] = true
		LegacyManager.endings_achieved["NECROSIS CONTROLADA"] = true
		LegacyManager.endings_achieved["ESCLEROCIO OSCURO"] = true
		LegacyManager.grant_buff("protocolo_omega_cero")
		LegacyManager.save_legacy()
		print("🕳️ [DEBUG] Protocolo Omega-Cero desbloqueado (3 rutas + permiso)"))
	# Fuerza MO + Omega-Cero activo para testear el loop de síntesis.
	_add_event_btn(hbox_oc, "Activar Omega-Cero", func():
		EvoManager.mutation_depredador = true
		EvoManager.mutation_met_oscuro = true
		EvoManager.activate_omega_cero()
		UIManager.update_ng_plus_buttons()
		_main.update_ui()
		print("🕳️ [DEBUG] Omega-Cero activado — Ω = %.4f" % EvoManager.omega_cero_omega))
	# Regala Φ para testear el sello sin grindear devours.
	_add_event_btn(hbox_oc, "+50 Φ", func():
		EvoManager.omega_cero_phi += 50.0
		print("🕳️ [DEBUG] Φ = %.0f" % EvoManager.omega_cero_phi))

	# ── DEBUG REMISIÓN METABÓLICA ──
	var hbox_rem0 := HBoxContainer.new()
	hbox_rem0.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_rem0)
	# Marca las 4 sub-rutas + otorga el permiso del Banco (15 PL) para habilitar el gate.
	_add_event_btn(hbox_rem0, "Desbloq. Remisión", func():
		LegacyManager.endings_achieved["AUTOFAGIA NECRÓTICA"] = true
		LegacyManager.endings_achieved["NECROSIS CONTROLADA"] = true
		LegacyManager.endings_achieved["ESCLEROCIO OSCURO"] = true
		LegacyManager.endings_achieved["PROTOCOLO OMEGA-CERO"] = true
		LegacyManager.grant_buff("remision_metabolica")
		LegacyManager.save_legacy()
		print("🌿 [DEBUG] REMISIÓN desbloqueada (4 sub-rutas + permiso)"))
	# Fuerza las condiciones de gate: bio>=150 en MO + ruta activa.
	_add_event_btn(hbox_rem0, "Gate listo", func():
		EvoManager.mutation_depredador = true
		EvoManager.mutation_met_oscuro = true
		BiosphereEngine.biomasa = 155.0
		LegacyManager.endings_achieved["AUTOFAGIA NECRÓTICA"] = true
		LegacyManager.endings_achieved["NECROSIS CONTROLADA"] = true
		LegacyManager.endings_achieved["ESCLEROCIO OSCURO"] = true
		LegacyManager.endings_achieved["PROTOCOLO OMEGA-CERO"] = true
		LegacyManager.grant_buff("remision_metabolica")
		LegacyManager.save_legacy()
		UIManager.update_ng_plus_buttons()
		_main.update_ui()
		print("🌿 [DEBUG] Gate listo: MO activo, bio=%.0f, permiso OK" % BiosphereEngine.biomasa))
	# Activa la ruta directamente (salta el gate) para testear el loop de banda.
	_add_event_btn(hbox_rem0, "Activar Remisión", func():
		EvoManager.mutation_depredador = true
		EvoManager.mutation_met_oscuro = true
		BiosphereEngine.biomasa = 155.0
		EvoManager.mutation_remision = true
		EvoManager.remision_omega = Balance.REMISION_OMEGA_START
		EvoManager.remision_theta = 0.0
		EvoManager.remision_band_timer = 0.0
		EvoManager.remision_sealable = false
		UIManager.update_ng_plus_buttons()
		_main.update_ui()
		print("🌿 [DEBUG] Remisión activa — Ω=%.3f, Θ=0s, bio=%.0f" % [EvoManager.remision_omega, BiosphereEngine.biomasa]))

	var hbox_rem1 := HBoxContainer.new()
	hbox_rem1.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_rem1)
	# Sube Θ a 59s para testear el mensaje de sello inminente y el botón SELLAR.
	_add_event_btn(hbox_rem1, "Θ→59s", func():
		EvoManager.remision_theta = 59.0
		print("🌿 [DEBUG] Θ=59s — próximo tick dentro de banda sella"))
	# Fuerza Θ al target para armar el sello (sin esperar el minuto de grinding).
	_add_event_btn(hbox_rem1, "Sello listo (Θ=60)", func():
		EvoManager.remision_theta = Balance.REMISION_THETA_TARGET
		EvoManager.remision_sealable = true
		print("🌿 [DEBUG] Sello armado — pulsá R o el botón SELLAR para cerrar"))
	# Simula la bio baja para forzar la involución (bio < 30 → vuelve a MO).
	_add_event_btn(hbox_rem1, "Forzar Involución", func():
		BiosphereEngine.biomasa = 25.0
		print("🌿 [DEBUG] bio=25 — próximo tick dispara involución"))
	# Limpia la flag de lock para poder reintentar REMISIÓN la misma run.
	_add_event_btn(hbox_rem1, "Unlock run-lock", func():
		EvoManager.remision_locked_run = false
		print("🌿 [DEBUG] remision_locked_run=false — gate disponible nuevamente"))

	var hbox_rem2 := HBoxContainer.new()
	hbox_rem2.add_theme_constant_override("separation", 6)
	parent.add_child(hbox_rem2)
	# Fuerza el cross: marca omega_remision_done para desbloquear sintesis_vital.
	_add_event_btn(hbox_rem2, "Marcar Cross Síntesis", func():
		LegacyManager.omega_remision_done = true
		LegacyManager.save_legacy()
		print("🌿 [DEBUG] omega_remision_done=true — sintesis_vital desbloqueable"))
	# Fuerza el buff Control de Ω para testear la producción pasiva (+30% a offset máx).
	_add_event_btn(hbox_rem2, "Buff Control Ω", func():
		LegacyManager.grant_buff("control_omega")
		LegacyManager.save_legacy()
		StructuralModel.control_omega_offset = 0.15
		print("🌿 [DEBUG] control_omega + offset=0.15 → +%.0f%% producción" % (StructuralModel.control_omega_offset * 2.0 * 100)))


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
	if EvoManager.mutation_remision:
		var band_c := EvoManager.remision_band_center()
		var in_band := EvoManager.remision_in_band()
		var band_str := "[color=green]DENTRO[/color]" if in_band else "[color=red]FUERA[/color]"
		t += "[b]REMISIÓN[/b]  %s\n" % band_str
		t += "  Ω_rem=%.3f  centro=%.3f±%.3f\n" % [EvoManager.remision_omega, band_c, Balance.REMISION_BAND_HALF]
		t += "  Θ=%.1fs / %.0fs  sealable=%s  locked=%s\n" % [EvoManager.remision_theta, Balance.REMISION_THETA_TARGET, str(EvoManager.remision_sealable), str(EvoManager.remision_locked_run)]
		t += "  bio=%.1f (floor=%.0f)  ctrl_Ω_offset=%.3f → +%.0f%%\n" % [BiosphereEngine.biomasa, Balance.REMISION_BIO_FLOOR, StructuralModel.control_omega_offset, StructuralModel.control_omega_offset * 2.0 * 100]
	_info_label.text = t

