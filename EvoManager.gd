extends Node

# EvoManager.gd — Autoload
# Maneja la evolución del genoma y las mutaciones irreversibles.
# Actúa de forma autónoma: observa a BiosphereEngine y main.gd,
# muta su propio estado y emite señales para que main actúe.

signal mutation_unlocked(mutation_id: String)
signal mutation_activated(mutation_id: String, display_name: String)
signal run_ended_by_mutation(route: String, reason: String)
signal primordio_iniciado()
signal primordio_abortado(abort_count: int, reason: String)
signal seta_formada_signal()

var genome := {
	"hiperasimilacion": "dormido",
	"parasitismo": "dormido",
	"red_micelial": "dormido",
	"esporulacion": "dormido",
	"simbiosis": "dormido",
	"homeostasis": "dormido",
	"trascendencia": "dormido",
	"allostasis": "dormido",
	"homeorhesis": "dormido",
	"depredador": "dormido",
	"met_oscuro": "dormido"
}

var mutation_hyperassimilation := false
var mutation_symbiosis := false
var mutation_homeostasis := false
var mutation_red_micelial := false
var mutation_sporulation := false
var mutation_parasitism := false
var mutation_allostasis := false
var mutation_homeorhesis := false

var main: Node # Referencia dinámica al Main Loop

var red_micelial_phase := 0
enum RedBranch { NONE, COLONIZATION, SYMBIOSIS }
var red_branch_selected: int = RedBranch.NONE

# === CICLO BIOLÓGICO: PRIMORDIO ===
const PRIMORDIO_DURATION := 90.0
var primordio_active: bool = false
var primordio_timer: float = 0.0
var primordio_abort_count: int = 0
var seta_formada: bool = false
var nucleo_conciencia := false # Hito final Rama Azul

# === NG+ SECRETOS ===
var allostasis_timer: float = 0.0
var homeorhesis_timer: float = 0.0
var mutation_depredador := false
var depredador_timer: float = 0.0

# === NG+ METABOLISMO OSCURO (Post-Depredador) ===
var mutation_met_oscuro := false
var met_oscuro_timer: float = 0.0  # Progreso de activación (0→15s)
const MET_OSCURO_REQUIRED_TIME := 15.0
var met_oscuro_devoured_count: int = 0  # Upgrades devorados durante la run

func reset() -> void:
	genome = {
		"hiperasimilacion": "dormido",
		"parasitismo": "dormido",
		"red_micelial": "dormido",
		"esporulacion": "dormido",
		"simbiosis": "dormido",
		"homeostasis": "dormido",
		"trascendencia": "dormido",
		"depredador": "dormido",
		"met_oscuro": "dormido",
		"allostasis": "dormido",
		"homeorhesis": "dormido"
}
	mutation_hyperassimilation = false
	mutation_symbiosis = false
	mutation_homeostasis = false
	mutation_red_micelial = false
	mutation_sporulation = false
	mutation_parasitism = false
	mutation_allostasis = false
	mutation_homeorhesis = false
	mutation_depredador = false
	mutation_met_oscuro = false
	met_oscuro_timer = 0.0
	met_oscuro_devoured_count = 0
	red_micelial_phase = 0
	red_branch_selected = RedBranch.NONE
	primordio_active = false
	primordio_timer = 0.0
	primordio_abort_count = 0
	seta_formada = false
	nucleo_conciencia = false
	allostasis_timer = 0.0
	homeorhesis_timer = 0.0
	depredador_timer = 0.0

func update_genome(main_node: Control):
	self.main = main_node # Guardamos la referencia
	if RunManager.run_closed:
		return

	# --- BLOQUEO POR RED MICELIAL O PARASITISMO (Rutas Finales/Tier 1 bloqueado) ---
	if mutation_red_micelial or mutation_parasitism:
		if genome.hiperasimilacion != "activo": _set_genome_state("hiperasimilacion", "bloqueado")
		if genome.homeostasis != "activo": _set_genome_state("homeostasis", "bloqueado")
		if genome.parasitismo != "activo" and not mutation_parasitism: _set_genome_state("parasitismo", "bloqueado")
		if genome.simbiosis != "activo" and not mutation_symbiosis: _set_genome_state("simbiosis", "bloqueado")
		
		# Forzamos estado activo en el genoma para que no se vea como "latente" en el HUD
		if mutation_red_micelial: _set_genome_state("red_micelial", "activo")
		if mutation_parasitism: _set_genome_state("parasitismo", "activo")
		
		# No bloqueamos esporulación ya que es el final de la rama roja (solo si aplica)
		_check_automatic_activations()
		return

	var epsilon_runtime = StructuralModel.epsilon_runtime
	var accounting_level = UpgradeManager.level("accounting")
	var run_time = main.run_time
	var bio_pressure = main.get_structural_pressure()
	
	var biomasa = BiosphereEngine.biomasa
	var hifas = BiosphereEngine.hifas
	var ap = main.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo

	# HIPERASIMILACIÓN (Exceso)
	if mutation_homeostasis or mutation_symbiosis or mutation_parasitism or mutation_red_micelial:
		_set_genome_state("hiperasimilacion", "bloqueado")
	elif ap.activo > 80.0 and epsilon_runtime > 0.4 and biomasa > 4.0 and accounting_level == 0 and run_time > 180.0:
		_set_genome_state("hiperasimilacion", "activo")
	elif ap.activo > 60.0 or epsilon_runtime > 0.4:
		_set_genome_state("hiperasimilacion", "latente")
	else:
		_set_genome_state("hiperasimilacion", "dormido")

	# PARASITISMO (Degeneración)
	# Inactividad: no clickear por 2min + biomasa suficiente. NO requiere epsilon alto
	# porque dejar de clickear colapsa epsilon por diseño (decay_factor en update_epsilon_runtime)
	var inactivity_trigger = EconomyManager.time_since_last_click > 120.0 and biomasa > 3.0
	var stagnation_trigger = run_time > 1800.0 and biomasa > 5.0 and LegacyManager.last_run_ending != "HOMEOSTASIS"
	
	if mutation_parasitism:
		_set_genome_state("parasitismo", "activo")
	elif mutation_homeostasis or mutation_symbiosis or mutation_hyperassimilation or mutation_red_micelial:
		_set_genome_state("parasitismo", "bloqueado")
	elif (biomasa > 6.0 and epsilon_runtime > 0.35 and accounting_level == 0 and run_time > 420.0) \
		or inactivity_trigger or stagnation_trigger:
		_set_genome_state("parasitismo", "activo")
	elif biomasa > 2.0 or EconomyManager.time_since_last_click > 60.0:
		_set_genome_state("parasitismo", "latente")
	else:
		_set_genome_state("parasitismo", "dormido")

	# === NG++ METABOLISMO OSCURO (Post-Depredador: bioquímica oscura) ===
	# Solo evaluable si Depredador está activo Y no estamos ya en MET.OSCURO
	if mutation_met_oscuro:
		_set_genome_state("met_oscuro", "activo")
	elif mutation_depredador:
		# Árbol HTML: "Depredación activa" + "Recursos críticos (< 20%)"
		# → Dinero crítico (< $1000), al menos 3 devours, y biomasa acumulada ≥ 25
		var devoured_ok: bool = met_oscuro_devoured_count >= 3
		var recursos_criticos: bool = EconomyManager.money < 1000.0
		var bio_ok: bool = biomasa >= 25.0
		if devoured_ok and recursos_criticos and bio_ok:
			var prev_mt := met_oscuro_timer
			met_oscuro_timer += main.LOGIC_TICK
			if prev_mt == 0.0 and met_oscuro_timer > 0.0:
				LogManager.add("🌑 BIOQUÍMICA OSCURA — Recursos críticos detectados ($%.0f). Estabilizando en %ds… (devours: %d, bio %.1f)" % [EconomyManager.money, int(MET_OSCURO_REQUIRED_TIME), met_oscuro_devoured_count, biomasa], main)
			# ÁRBOL ACELERADO (Banco Cósmico T2): timers -40%
			var met_oscuro_threshold := MET_OSCURO_REQUIRED_TIME * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
			if met_oscuro_timer >= met_oscuro_threshold:
				_set_genome_state("met_oscuro", "activo")
			else:
				_set_genome_state("met_oscuro", "latente")
		else:
			met_oscuro_timer = max(0.0, met_oscuro_timer - main.LOGIC_TICK * 1.5)
			if met_oscuro_timer == 0.0:
				_set_genome_state("met_oscuro", "dormido")
			else:
				_set_genome_state("met_oscuro", "latente")
	else:
		_set_genome_state("met_oscuro", "dormido")

	# === NG+ DEPREDADOR DE REALIDADES (Glitch Survival) ===
	if mutation_depredador:
		_set_genome_state("depredador", "activo")
	elif LegacyManager.last_run_ending == "PARASITISMO" and (mutation_hyperassimilation or genome.hiperasimilacion == "activo"):
		if epsilon_runtime > 0.95:
			var prev_timer := depredador_timer
			depredador_timer += main.LOGIC_TICK
			# Notificar al iniciar la carga
			if prev_timer == 0.0 and depredador_timer > 0.0:
				LogManager.add("☠️ DEPREDADOR DETECTADO — ε %.2f > 0.95. Cargando 30s... La hiperasimilación está bloqueada." % epsilon_runtime, main)
			# ÁRBOL ACELERADO (Banco Cósmico T2): timer Depredador -40%
			var depredador_threshold := 30.0 * (0.6 if LegacyManager.has_cosmic_buff("arbol_acelerado") else 1.0)
			if depredador_timer >= depredador_threshold:
				_set_genome_state("depredador", "activo")
			else:
				_set_genome_state("depredador", "latente")
		else:
			depredador_timer = max(0.0, depredador_timer - main.LOGIC_TICK * 2.0)
			if depredador_timer == 0.0:
				_set_genome_state("depredador", "dormido")
			else:
				_set_genome_state("depredador", "latente")
	else:
		_set_genome_state("depredador", "dormido")

	# SIMBIOSIS (v0.8.5 - El Camino del Hardware)
	# Árbol: "Estabilidad del ecosistema > 40%" → Ω ≥ 0.40
	if mutation_symbiosis:
		_set_genome_state("simbiosis", "activo")
	elif mutation_homeostasis or mutation_hyperassimilation or mutation_red_micelial or mutation_parasitism:
		_set_genome_state("simbiosis", "bloqueado")
	elif accounting_level >= 1 and hifas >= 5.0 and StructuralModel.omega >= 0.40 and act_domina:
		_set_genome_state("simbiosis", "latente")
	elif accounting_level >= 1 and hifas >= 3.0:
		_set_genome_state("simbiosis", "latente")
	else:
		_set_genome_state("simbiosis", "dormido")

	# HOMEOSTASIS (v0.8.10 - La Ruta del Orden)
	# Árbol: "Al menos 2 sistemas activos + Sin colapso en run actual"
	# → accounting_level >= 1 (institución activa) + biomasa > 0 (biología activa) + ε < 0.50
	var dos_sistemas_activos: bool = accounting_level >= 1 and (biomasa > 1.0 or hifas > 2.0)
	var sin_colapso: bool = epsilon_runtime < 0.50
	var low_fungal_noise: bool = hifas < 8.0
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis or mutation_allostasis or mutation_homeorhesis:
		_set_genome_state("homeostasis", "bloqueado")
	elif mutation_homeostasis:
		_set_genome_state("homeostasis", "activo")
	elif main.is_homeostasis_candidate(main.LOGIC_TICK) and low_fungal_noise and sin_colapso:
		_set_genome_state("homeostasis", "latente")
	elif dos_sistemas_activos and run_time > 120.0:
		_set_genome_state("homeostasis", "latente")
	else:
		_set_genome_state("homeostasis", "dormido")

	# === NG+ ALOSTASIS ===
	# Árbol: "Homeostasis activa + Haber sobrevivido al menos 1 perturbación"
	if mutation_allostasis:
		_set_genome_state("allostasis", "activo")
	elif mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis or not mutation_homeostasis:
		_set_genome_state("allostasis", "bloqueado")
	elif LegacyManager.last_run_ending == "HOMEOSTASIS":
		# Latente desde la primera perturbación sobrevivida (fiel al árbol)
		if RunManager.disturbances_survived >= 1:
			_set_genome_state("allostasis", "latente")
		else:
			_set_genome_state("allostasis", "dormido")
	else:
		_set_genome_state("allostasis", "dormido")
		
	# === NG+ HOMEORRESIS ===
	# Árbol: "Allostasis activa + Más de 5 ciclos sin colapso"
	# → disturbances_survived >= 5 + shock extremo sobrevivido
	if mutation_homeorhesis:
		_set_genome_state("homeorhesis", "activo")
	elif mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis or not mutation_allostasis:
		_set_genome_state("homeorhesis", "bloqueado")
	elif LegacyManager.last_run_ending == "ALLOSTASIS":
		# Latente cuando se cumplen "5 ciclos sin colapso"
		if RunManager.disturbances_survived >= 5 or RunManager.extreme_shock_survived:
			_set_genome_state("homeorhesis", "latente")
		else:
			_set_genome_state("homeorhesis", "dormido")
	else:
		_set_genome_state("homeorhesis", "dormido")

	# RED MICELIAL (v0.8.10 - La Ruta de la Expansión)
	if mutation_red_micelial:
		_set_genome_state("red_micelial", "activo")
	elif mutation_homeostasis or mutation_hyperassimilation or mutation_symbiosis:
		_set_genome_state("red_micelial", "bloqueado")
	elif hifas >= 11.5 and biomasa >= 5.0 and StructuralModel.epsilon_runtime < 0.65 and accounting_level >= 1 and not act_domina:
		_set_genome_state("red_micelial", "latente")
	elif hifas >= 5.0:
		_set_genome_state("red_micelial", "latente")
	else:
		_set_genome_state("red_micelial", "dormido")

	# ESPORULACIÓN (Si ya está en fase 2)
	if mutation_homeostasis or mutation_hyperassimilation:
		_set_genome_state("esporulacion", "bloqueado")
	elif bio_pressure > 20.0:
		_set_genome_state("esporulacion", "activo")
	elif bio_pressure > 8.0:
		_set_genome_state("esporulacion", "latente")
	else:
		_set_genome_state("esporulacion", "dormido")

	_check_automatic_activations()


func _check_automatic_activations():
	# MET.OSCURO tiene prioridad sobre Depredador (congela el devorar)
	if genome.met_oscuro == "activo" and not mutation_met_oscuro:
		activate_met_oscuro()
		return

	# DEPREDADOR tiene prioridad sobre el resto
	if genome.depredador == "activo" and not mutation_depredador:
		activate_depredador()
		return  # Evita que hiperasimilación cierre la run en el mismo tick

	if genome.hiperasimilacion == "activo" and not mutation_hyperassimilation:
		activate_hyperassimilation()

	if genome.parasitismo == "activo" and not mutation_parasitism:
		activate_parasitism()

	if genome.allostasis == "activo" and not mutation_allostasis:
		activate_allostasis()

	if genome.homeorhesis == "activo" and not mutation_homeorhesis:
		activate_homeorhesis()

	# Simbiosis, Homeostasis y Red Micelial ahora son MANUALES vía Choice Panel

	if genome.esporulacion == "activo" and not mutation_sporulation and red_micelial_phase == 2:
		activate_sporulation()

func is_any_latent_tier1() -> bool:
	return genome.simbiosis == "latente" or genome.homeostasis == "latente" or genome.red_micelial == "latente"

func is_homeostasis_ready() -> bool:
	return main.is_homeostasis_candidate(main.LOGIC_TICK)

func is_simbiosis_ready() -> bool:
	var hifas = BiosphereEngine.hifas
	var acc = UpgradeManager.level("accounting")
	var ap = main.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo
	# Árbol: "Estabilidad del ecosistema > 40%" → Ω ≥ 0.40
	return acc >= 1 and hifas >= 5.0 and StructuralModel.omega >= 0.40 and act_domina

func is_red_micelial_ready() -> bool:
	var hifas = BiosphereEngine.hifas
	var biomasa = BiosphereEngine.biomasa
	var acc = UpgradeManager.level("accounting")
	var ap = main.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo
	var eps = StructuralModel.epsilon_runtime
	return hifas >= 11.5 and biomasa >= 5.0 and eps < 0.65 and acc >= 1 and not act_domina

func is_allostasis_ready(main_node: Node) -> bool:
	var ok_dist = RunManager.disturbances_survived >= 3
	var ok_resil = RunManager.resilience_score >= 150.0
	var ok_omega = StructuralModel.omega_min >= 0.40
	var ok_delta = main_node.delta_per_sec >= 200.0
	var ok_acc = UpgradeManager.level("accounting") >= 2
	return ok_dist and ok_resil and ok_omega and ok_delta and ok_acc


func activate_mutation(id: String) -> void:
	match id:
		"hiperasimilacion": activate_hyperassimilation()
		"homeostasis": activate_homeostasis()
		"red_micelial": activate_red_micelial()
		"esporulacion": activate_sporulation()
		"parasitismo": activate_parasitism()
		"simbiosis": activate_symbiosis()
		"allostasis": activate_allostasis()
		"depredador": activate_depredador()
		"met_oscuro": activate_met_oscuro()

func _set_genome_state(mutation: String, new_state: String):
	# Si la clave no existe, la creamos en lugar de crashear
	if not genome.has(mutation):
		genome[mutation] = "dormido"
	
	if genome[mutation] != new_state:
		genome[mutation] = new_state
		if new_state == "latente":
			mutation_unlocked.emit(mutation)


func activate_allostasis():
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis: return
	LogManager.add("🔬 ALOSTASIS ALCANZADA: El sistema ha aprendido a recalibrar su setpoint estructural tras la crisis.", main)
	mutation_allostasis = true
	mutation_activated.emit("allostasis", "Resiliencia Alostática")
	
func activate_homeorhesis():
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis: return
	LogManager.add("✨ HOMEORRESIS ALCANZADA: Evolución irreversible. El metabolismo trasciende la regulación basal.", main)
	mutation_homeorhesis = true
	mutation_activated.emit("homeorhesis", "Trascendencia Cristalina")

func activate_depredador():
	if mutation_homeostasis or mutation_red_micelial or mutation_symbiosis or mutation_parasitism: return
	LogManager.add("⚠️ ALERTA: EL CÓDIGO FUENTE HA SIDO VULNERADO. EL HONGO SE ALIMENTA DE LA REALIDAD.", main)
	mutation_depredador = true
	mutation_activated.emit("depredador", "Depredador de Realidades")

	if not LegacyManager.unlocked_legacies.has("metabolismo_glitch") or not LegacyManager.unlocked_legacies["metabolismo_glitch"]:
		LegacyManager.unlocked_legacies["metabolismo_glitch"] = true
		LegacyManager.save_legacy()
		main.show_system_toast("✨ Has desbloqueado el legado oculto: METABOLISMO GLITCH")

func activate_met_oscuro():
	if mutation_met_oscuro: return
	if not mutation_depredador: return  # Solo post-Depredador
	mutation_met_oscuro = true
	LogManager.add("🌑 METABOLISMO OSCURO ACTIVADO — La bioquímica no documentada reemplaza la economía estructural.", main)
	LogManager.add("🌑 EFECTOS: Devorar DETENIDO · Pasivo = Bio×0.8/s · Click ×3 · ε decae · Ω bloqueado 0.10", main)
	mutation_activated.emit("met_oscuro", "METABOLISMO OSCURO")
	# Recalcular estrés/omega tras aplicar los nerfs permanentes
	StructuralModel.omega = 0.10
	StructuralModel.omega_min = min(StructuralModel.omega_min, 0.10)

func activate_hyperassimilation():
	if mutation_homeostasis or mutation_parasitism or mutation_symbiosis: return
	mutation_hyperassimilation = true
	LogManager.add("⚡⚡⚡ EFECTOS ACTIVOS: Click PUSH ×10 | Pasivo ×0.25 (-75%) | Fragilidad Ω total ⚡⚡⚡", main)
	mutation_activated.emit("hiperasimilacion", "HIPERASIMILACIÓN")
	# Si venimos de PARASITISMO, NO cerramos — esperamos que ε > 0.95 active DEPREDADOR
	if LegacyManager.last_run_ending != "PARASITISMO":
		run_ended_by_mutation.emit("HIPERASIMILACION", "El sistema prioriza absorción total sobre estabilidad")

func activate_homeostasis():
	if mutation_homeostasis or mutation_symbiosis: return
	mutation_homeostasis = true
	mutation_hyperassimilation = false # bloqueo cruzado
	mutation_activated.emit("homeostasis", "HOMEOSTASIS")

func activate_red_micelial():
	if mutation_homeostasis or mutation_hyperassimilation or mutation_symbiosis: return
	mutation_red_micelial = true
	# red_micelial_phase = 1 // This is now handled by check_red_micelial_transition
	mutation_activated.emit("red_micelial", "RED MICELIAL (Fase A)")

func activate_sporulation():
	if mutation_sporulation: return
	if not mutation_red_micelial or red_micelial_phase != 2: return
	if mutation_homeostasis or mutation_hyperassimilation: return
	
	mutation_sporulation = true
	mutation_activated.emit("esporulacion", "ESPORULACIÓN")
	run_ended_by_mutation.emit("ESPORULACION", "El sistema abandona la coherencia local y se dispersa en esporas")

func activate_parasitism():
	if mutation_homeostasis or mutation_symbiosis or mutation_parasitism: return
	mutation_parasitism = true
	mutation_hyperassimilation = false
	BiosphereEngine.apply_parasitism_buffs()
	mutation_activated.emit("parasitismo", "PARASITISMO")
	# El parasitismo no cierra la run inmediatamente, requiere un hito de drenaje o colapso.

func check_parasitism_final(_main: Control):
	if not mutation_parasitism or RunManager.run_closed: return
	
	# Condición de victoria por parasitismo: 1 PL (mínimo histórico)
	if BiosphereEngine.biomasa >= 15.0 and EconomyManager.money < 1000.0:
		LegacyManager.add_pl(1)
		main.close_run("PARASITISMO", "Bancarrota Biológica: el hongo ha drenado toda la liquidez del sistema (+1 PL)")
	elif BiosphereEngine.biomasa >= 25.0:
		LegacyManager.add_pl(1)
		main.close_run("PARASITISMO", "Colapso por Masa Crítica: el tejido biótico ha reemplazado toda la infraestructura (+1 PL)")

func activate_symbiosis():
	if mutation_homeostasis or mutation_hyperassimilation or mutation_red_micelial: return
	mutation_symbiosis = true
	mutation_activated.emit("simbiosis", "SIMBIOSIS ESTRUCTURAL")

# =============================================================
# CICLO BIOLÓGICO: PRIMORDIO (Fase 2)
# =============================================================

func check_red_micelial_transition(main_ref: Node):
	if mutation_red_micelial and red_micelial_phase == 0:
		# Fase A -> Fase B
		var hifas_req = 11.5 if red_branch_selected == RedBranch.COLONIZATION else 9.5
		var eps_req = 0.65 if red_branch_selected == RedBranch.COLONIZATION else 0.35
		
		if BiosphereEngine.hifas >= hifas_req \
		and BiosphereEngine.biomasa >= 5.0 \
		and StructuralModel.epsilon_runtime <= eps_req \
		and main_ref.run_time >= 200.0:
			red_micelial_phase = 1
			main_ref.add_lap("🕸️ Red Micelial Evolucionada (Fase B)")
			main_ref.show_system_toast("RED MICELIAL: Iniciando integración estructural profunda")

func update_primordio(main_ref: Node) -> void:
	if red_branch_selected == RedBranch.COLONIZATION:
		_process_primordio_biological(main_ref)
	elif red_branch_selected == RedBranch.SYMBIOSIS:
		_process_primordio_mechanical(main_ref)

func _process_primordio_biological(main_ref: Node):
	# ... (lógica anterior de primordio biológico) ...
	if not primordio_active and not seta_formada and red_micelial_phase == 1:
		if BiosphereEngine.hifas >= 14.5 and BiosphereEngine.biomasa >= 8.0:
			primordio_active = true
			main_ref.add_lap("⚠️ ADVERTENCIA: Inicio de Primordio Biológico")
			primordio_iniciado.emit()
	
	if primordio_active:
		var dt: float = main_ref.LOGIC_TICK
		primordio_timer += dt
		
		# Condiciones de supervivencia (Relajadas v0.8.40)
		var reason := ""
		if StructuralModel.epsilon_runtime >= 0.50: reason = "Estrés Crítico (>0.50)"
		elif BiosphereEngine.hifas >= 60.0: reason = "Inestabilidad por Hifas (>60)"
		elif main_ref.delta_per_sec < 50.0: reason = "Falta de Nutrientes (<50/$s)"
		
		if reason != "":
			_abort_primordio(reason)
			return
		
		if primordio_timer >= PRIMORDIO_DURATION:
			_complete_primordio()

func _process_primordio_mechanical(main_ref: Node):
	# En la rama azul, el "primordio" es un proceso de Computación Estructural
	if not primordio_active and not nucleo_conciencia and red_micelial_phase == 1:
		# Requisitos: Contabilidad alta y estabilidad
		if UpgradeManager.level("accounting") >= 2 and StructuralModel.epsilon_runtime <= 0.25:
			primordio_active = true
			main_ref.add_lap("⚡ INICIANDO: Sincronización de Núcleo de Conciencia")
			main_ref.show_system_toast("SISTEMA: Integrando redes bióticas en el mainframe")
	
	if primordio_active:
		# La estabilidad acelera el proceso
		var speed_mult = clamp(1.0 + (0.5 - StructuralModel.epsilon_runtime), 0.5, 2.0)
		primordio_timer += main_ref.LOGIC_TICK * speed_mult
		
		if primordio_timer >= PRIMORDIO_DURATION:
			primordio_active = false
			nucleo_conciencia = true
			main_ref.add_lap("💾 HITO: Núcleo de Conciencia Sincronizado")
			# Bonus de eficiencia tecnológica
			EconomyManager.mutation_accounting_bonus += 0.2

func try_iniciar_primordio() -> bool:
	# Guards
	if not mutation_red_micelial: return false
	if red_branch_selected != RedBranch.COLONIZATION: return false
	if primordio_active or seta_formada: return false
	
	# Costo en micelio, escala con abortos previos
	var costo := 20.0 * (1.0 + primordio_abort_count * 0.2)
	if BiosphereEngine.micelio < costo:
		return false
	
	BiosphereEngine.micelio -= costo
	primordio_active = true
	primordio_timer = 0.0
	primordio_iniciado.emit()
	return true

func _abort_primordio(reason: String) -> void:
	primordio_active = false
	primordio_timer = 0.0
	primordio_abort_count += 1
	BiosphereEngine.micelio = max(BiosphereEngine.micelio - 40.0, 0.0)
	primordio_abortado.emit(primordio_abort_count, reason)

func _complete_primordio() -> void:
	primordio_active = false
	primordio_timer = 0.0
	seta_formada = true
	red_micelial_phase = 2  # Fase C: Seta formada, esporulación disponible
	seta_formada_signal.emit()

# =============================================================
# COLOR DEL REACTOR — Fuente Única de Verdad (v0.8.27)
# SOLO modificar aquí si querés cambiar un color del reactor.
# =============================================================
func get_reactor_color() -> Color:
	# Prioridad 0A: MET.OSCURO (post-Depredador, bioquímica oscura)
	if mutation_met_oscuro:
		return Color(0.53, 0.27, 0.67)    # Púrpura Oscuro
	# Prioridad 0B: Depredador de Realidades
	if mutation_depredador:
		return Color(1.0, 0.0, 0.33)      # Rojo Glitch
	# Prioridad 0: Seta Formada (v0.8.42 - Brillo máximo)
	if seta_formada:
		return Color(0.65, 1.2, 0.2)      # Verde Incandescente (sobrepasamos 1.0 para bloom)

	# Prioridad 1: Final por Esporulación
	if mutation_sporulation:
		return Color(0.7, 1.0, 0.4)       # Verde Nuclear

	# Prioridad 2: Ramas elegidas de Red Micelial
	if red_branch_selected == RedBranch.COLONIZATION:
		return Color(0.45, 1.0, 0.05)     # Verde Lima Líquido
	if red_branch_selected == RedBranch.SYMBIOSIS:
		return Color(0.0, 0.9, 1.0)       # Cian Eléctrico

	# Prioridad 3: Mutaciones base activas
	if mutation_hyperassimilation:
		return Color(1.0, 0.1, 0.6)       # Magenta
	if mutation_homeostasis:
		return Color(0.2, 0.85, 1.0)      # Celeste Suave
	if mutation_parasitism:
		return Color(1.0, 0.45, 0.0)      # Naranja
	if mutation_red_micelial:
		return Color(0.3, 1.0, 0.3)       # Verde Hoja
	if mutation_symbiosis:
		return Color(0.4, 0.9, 0.7)       # Verde Agua

	# Prioridad 4: Base (sin mutaciones)
	return Color(0.15, 0.65, 1.0)         # Azul Tecnológico
