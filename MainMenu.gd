extends Control

@onready var btn_continue = $CenterContainer/VBoxContainer/BtnContinue
@onready var btn_new_game = $CenterContainer/VBoxContainer/BtnNewGame
@onready var btn_achievements = $CenterContainer/VBoxContainer/BtnAchievements
@onready var btn_legacy = $CenterContainer/VBoxContainer/BtnLegacy
@onready var achievements_panel = $AchievementsPanel
@onready var achievements_label = $AchievementsPanel/VBoxContainer/RichTextLabel

@onready var legacy_panel = $GeneticBankPanel
@onready var pl_counter = $GeneticBankPanel/VBoxContainer/PLCounter
@onready var legacy_list = $GeneticBankPanel/VBoxContainer/ScrollContainer/ItemList

func _ready():
	# Solo habilitar 'Continuar' si hay un archivo de guardado
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		btn_continue.disabled = true
		btn_continue.modulate = Color(1, 1, 1, 0.4)
	
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_achievements.pressed.connect(_on_achievements_pressed)
	btn_legacy.pressed.connect(_on_legacy_pressed)
	
	$AchievementsPanel/VBoxContainer/BtnBack.pressed.connect(_on_back_pressed)
	$GeneticBankPanel/VBoxContainer/BtnBackLegacy.pressed.connect(_on_back_pressed)
	$CenterContainer/VBoxContainer/BtnQuit.pressed.connect(get_tree().quit)

func _on_continue_pressed():
	# Cargar la escena principal. SaveManager.load_game se llamará en el _ready de main.gd
	get_tree().change_scene_to_file("res://main.tscn")

func _on_new_game_pressed():
	# 1. Borrar archivo de guardado previo y LEGADO (Hard Reset)
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
		print("🗑️ Memoria de run borrada.")
	
	if FileAccess.file_exists(LegacyManager.LEGACY_PATH):
		DirAccess.remove_absolute(LegacyManager.LEGACY_PATH)
		print("🗑️ Banco Genético formateado.")
	
	# 2. Resetear estados de los sistemas Autoload
	UpgradeManager.reset()
	BiosphereEngine.reset()
	EvoManager.reset()
	LogManager.reset()
	
	# Resetear LegacyManager manualmente ya que no tiene método reset() estándar
	LegacyManager.legacy_points = 0
	LegacyManager.total_runs = 0
	LegacyManager.internal_spores_total = 0.0
	for id in LegacyManager.unlocked_legacies:
		LegacyManager.unlocked_legacies[id] = false
	
	# 3. Cambiar a la escena principal
	get_tree().change_scene_to_file("res://main.tscn")

func _on_achievements_pressed():
	achievements_panel.visible = true
	_update_achievements_view()

func _on_legacy_pressed():
	legacy_panel.visible = true
	_update_legacy_view()

func _on_back_pressed():
	achievements_panel.visible = false
	legacy_panel.visible = false

func _update_legacy_view():
	pl_counter.text = "Legado acumulado: %d PL\nCiclos Bióticos completados: %d" % [LegacyManager.legacy_points, LegacyManager.total_runs]
	
	# Limpiar lista anterior
	for child in legacy_list.get_children():
		child.queue_free()
	
	# Construir lista (en diferido para que limpie primero)
	call_deferred("_populate_legacy_items")

func _populate_legacy_items():
	for id in LegacyManager.LEGACY_DATA:
		var data = LegacyManager.LEGACY_DATA[id]
		var unlocked = LegacyManager.unlocked_legacies[id]
		
		var container = HBoxContainer.new()
		container.custom_minimum_size.y = 60
		
		# Info
		var info = VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		
		var name_lbl = Label.new()
		name_lbl.text = data.name + (" (ADQUIRIDO)" if unlocked else " [%d PL]" % data.cost)
		name_lbl.modulate = Color(0, 1, 0) if unlocked else (Color(1, 1, 0.5) if LegacyManager.legacy_points >= data.cost else Color(0.7, 0.7, 0.7))
		
		var desc_lbl = Label.new()
		desc_lbl.text = data.desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.7, 0.7, 0.7)
		
		info.add_child(name_lbl)
		info.add_child(desc_lbl)
		
		# Botón compra
		var buy_btn = Button.new()
		buy_btn.text = "ADQUIRIR"
		buy_btn.custom_minimum_size.x = 100
		buy_btn.disabled = unlocked or LegacyManager.legacy_points < data.cost
		buy_btn.pressed.connect(_on_buy_legacy.bind(id))
		
		container.add_child(info)
		container.add_child(buy_btn)
		legacy_list.add_child(container)

func _on_buy_legacy(id: String):
	if LegacyManager.purchase_legacy(id):
		_update_legacy_view()

func _update_achievements_view():
	# Cargamos datos temporales para ver logros sin iniciar partida completa
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		achievements_label.text = "[center]No hay datos de guardado detectados.\n[color=gray]Juega una partida para desbloquear logros.[/color][/center]"
		return
	
	var file = FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		file.close()
		var data = json.data
		
		# Extraer flags de logros (basado en la estructura de main.gd.get_save_data)
		var flags = data.get("flags", {})
		var t := "[center][b]--- HISTORIAL DE LOGROS ---[/b][/center]\n\n"
		
		var struct = [
			["unlocked_tree", "✓ Árbol productivo completo"],
			["unlocked_click_dominance", "✓ CLICK domina el sistema"],
			["unlocked_delta_100", "✓ Δ$ ≥ 100 alcanzado"],
			["achievement_millionaire", "✓ Millonario de Esporas"],
			["achievement_fragile_balance", "✓ Equilibrio Frágil"]
		]
		
		var evo = [
			["achievement_homeostasis", "✓ Rutas: HOMEOSTASIS"],
			["achievement_homeostasis_perfect", "✓ HOMEOSTASIS PERFECTA"],
			["achievement_symbiosis", "✓ SIMBIOSIS ESTRUCTURAL"],
			["achievement_hyperassimilation", "✓ HIPERASIMILACIÓN"],
			["achievement_red_micelial", "✓ RED MICELIAL"],
			["achievement_sporulation", "✓ ESPORULACIÓN"],
			["achievement_parasitism", "✓ PARASITISMO"],
			["achievement_insatiable_parasite", "✓ PARÁSITO INSACIABLE"]
		]
		
		t += "[color=cyan][b]Estructurales:[/b][/color]\n"
		for pair in struct:
			if flags.get(pair[0], false):
				t += "[color=green]" + pair[1] + "[/color]\n"
			else:
				t += "[color=gray][ ] " + pair[1].substr(2) + "[/color]\n"
				
		t += "\n[color=magenta][b]Evolutivos:[/b][/color]\n"
		for pair in evo:
			if flags.get(pair[0], false):
				t += "[color=green]" + pair[1] + "[/color]\n"
			else:
				t += "[color=gray][ ] " + pair[1].substr(2) + "[/color]\n"
		
		achievements_label.text = t
