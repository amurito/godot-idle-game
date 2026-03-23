extends Node

# EvoManager.gd — Autoload
# Maneja la evolución del genoma y las mutaciones irreversibles.
# Actúa de forma autónoma: observa a BiosphereEngine y main.gd,
# muta su propio estado y emite señales para que main actúe.

signal mutation_unlocked(mutation_id: String)
signal mutation_activated(mutation_id: String, display_name: String)
signal run_ended_by_mutation(route: String, reason: String)

var genome := {
	"hiperasimilacion": "dormido",
	"parasitismo": "dormido",
	"red_micelial": "dormido",
	"esporulacion": "dormido",
	"simbiosis": "dormido"
}

var mutation_hyperassimilation := false
var mutation_symbiosis := false
var mutation_homeostasis := false
var mutation_red_micelial := false
var mutation_sporulation := false
var mutation_parasitism := false

var red_micelial_phase := 0

func reset() -> void:
	genome = {
		"hiperasimilacion": "dormido",
		"parasitismo": "dormido",
		"red_micelial": "dormido",
		"esporulacion": "dormido",
		"simbiosis": "dormido"
	}
	mutation_hyperassimilation = false
	mutation_symbiosis = false
	mutation_homeostasis = false
	mutation_red_micelial = false
	mutation_sporulation = false
	mutation_parasitism = false
	red_micelial_phase = 0

func update_genome(main: Control):
	if main.run_closed:
		return

	var epsilon_runtime = main.epsilon_runtime
	var omega = main.omega
	var accounting_level = UpgradeManager.level("accounting")
	var run_time = main.run_time
	var bio_pressure = main.get_structural_pressure()
	
	var biomasa = BiosphereEngine.biomasa
	var hifas = BiosphereEngine.hifas
	var epsilon_effective = BiosphereEngine.epsilon_effective

	# HIPERASIMILACIÓN
	if mutation_homeostasis or mutation_symbiosis or mutation_parasitism or mutation_red_micelial:
		_set_genome_state("hiperasimilacion", "bloqueado")
	elif epsilon_runtime > 0.6 and biomasa > 5.0 and omega < 0.30 and accounting_level == 0 and run_time > 300.0:
		_set_genome_state("hiperasimilacion", "activo")
	elif epsilon_runtime > 0.3:
		_set_genome_state("hiperasimilacion", "latente")
	else:
		_set_genome_state("hiperasimilacion", "dormido")

	# PARASITISMO
	if mutation_homeostasis or mutation_symbiosis or mutation_hyperassimilation:
		_set_genome_state("parasitismo", "bloqueado") # PARASITISMO (Requiere raw stress alto y sistema inestable)
	elif biomasa > 6.0 and main.epsilon_runtime > 0.45 and omega < 0.4 and accounting_level == 0 and run_time > 420.0:
		_set_genome_state("parasitismo", "activo")
	elif biomasa > 4.0:
		_set_genome_state("parasitismo", "latente")
	else:
		_set_genome_state("parasitismo", "dormido")

	# SIMBIOSIS
	if accounting_level >= 1 and hifas > 5.0 and epsilon_effective >= 0.18 and epsilon_effective <= 0.40 and not mutation_homeostasis and not mutation_hyperassimilation:
		_set_genome_state("simbiosis", "activo")
	elif accounting_level >= 1:
		_set_genome_state("simbiosis", "latente")
	else:
		_set_genome_state("simbiosis", "dormido")

	# RED MICELIAL
	if hifas > 8.0 and biomasa >= 3.0 and epsilon_effective < 0.25 and accounting_level >= 1 and not mutation_homeostasis and not mutation_hyperassimilation:
		_set_genome_state("red_micelial", "activo")
	elif hifas > 3.0:
		_set_genome_state("red_micelial", "latente")
	else:
		_set_genome_state("red_micelial", "dormido")

	# ESPORULACIÓN
	if mutation_homeostasis or mutation_hyperassimilation:
		_set_genome_state("esporulacion", "bloqueado")
	elif bio_pressure > 20.0:
		_set_genome_state("esporulacion", "activo")
	elif bio_pressure > 8.0:
		_set_genome_state("esporulacion", "latente")
	else:
		_set_genome_state("esporulacion", "dormido")

	# --- Activaciones Automáticas ---
	if genome.hiperasimilacion == "activo" and not mutation_hyperassimilation:
		activate_hyperassimilation()

	if genome.parasitismo == "activo" and not mutation_parasitism:
		activate_parasitism()

	if genome.simbiosis == "activo" and not mutation_symbiosis:
		activate_symbiosis()

	if genome.red_micelial == "activo" and not mutation_red_micelial:
		activate_red_micelial()

	if genome.esporulacion == "activo" and not mutation_sporulation and red_micelial_phase == 2:
		activate_sporulation()


func activate_mutation(id: String) -> void:
	match id:
		"hiperasimilacion": activate_hyperassimilation()
		"homeostasis": activate_homeostasis()
		"red_micelial": activate_red_micelial()
		"esporulacion": activate_sporulation()
		"parasitismo": activate_parasitism()
		"simbiosis": activate_symbiosis()

func _set_genome_state(mutation: String, new_state: String):
	if genome[mutation] != new_state:
		genome[mutation] = new_state
		if new_state == "latente":
			mutation_unlocked.emit(mutation)


func activate_hyperassimilation():
	if mutation_homeostasis or mutation_parasitism or mutation_symbiosis: return
	mutation_hyperassimilation = true
	mutation_activated.emit("hiperasimilacion", "HIPERASIMILACIÓN")
	run_ended_by_mutation.emit("HIPERASIMILACION", "El sistema prioriza absorción total sobre estabilidad")

func activate_homeostasis():
	if mutation_homeostasis: return
	mutation_homeostasis = true
	mutation_hyperassimilation = false # bloqueo cruzado
	mutation_activated.emit("homeostasis", "HOMEOSTASIS")

func activate_red_micelial():
	if mutation_homeostasis or mutation_hyperassimilation: return
	mutation_red_micelial = true
	red_micelial_phase = 1
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

func activate_symbiosis():
	if mutation_homeostasis or mutation_hyperassimilation: return
	mutation_symbiosis = true
	mutation_activated.emit("simbiosis", "SIMBIOSIS ESTRUCTURAL")
