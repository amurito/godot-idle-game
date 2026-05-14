class_name RunSnapshot
extends Resource

# =====================================================
# RunSnapshot.gd — v0.9.8
# Estructura tipada para el historial de runs.
# Reemplaza el uso de Dictionary genérico para archivar
# el estado final de cada partida.
#
# Uso:
#   var snap = RunSnapshot.from_run(main)
#   snap.to_dict()       → Dictionary compatible con LogManager
#   ResourceSaver.save(snap, "user://runs/run_001.tres")
# =====================================================

# --- Identificación ---
@export var run_id: String = ""
@export var fecha: String = ""
@export var hora: String = ""
@export var version: String = ""

# --- Tiempo ---
@export var run_time_seconds: float = 0.0

# --- Economía ---
@export var money_final: float = 0.0
@export var total_generated: float = 0.0
@export var delta_per_sec: float = 0.0
@export var click_per_sec: float = 0.0
@export var passive_per_sec: float = 0.0

# --- Estructura ---
@export var epsilon_peak: float = 0.0
@export var epsilon_final: float = 0.0
@export var omega_final: float = 0.0
@export var omega_min_reached: float = 0.0
@export var persistence_final: float = 0.0
@export var persistence_base: float = 0.0

# --- Biosfera ---
@export var biomasa_final: float = 0.0
@export var hifas_final: float = 0.0
@export var micelio_final: float = 0.0
@export var nutrientes_final: float = 0.0

# --- Evolución ---
@export var final_route: String = ""
@export var final_reason: String = ""
@export var mutations_activated: PackedStringArray = []
@export var red_branch: String = ""
@export var seta_formada: bool = false

# --- Métricas de calidad ---
@export var resilience_score: float = 0.0
@export var disturbances_survived: int = 0
@export var homeostasis_mode: bool = false

# --- Legado ganado en esta run ---
@export var pl_gained: int = 0
@export var esencia_gained: int = 0

# =====================================================
# FACTORY — construye un RunSnapshot desde el estado
#            actual de los autoloads + nodo main
# =====================================================

static func from_run(main: Node) -> RunSnapshot:
	var s := RunSnapshot.new()

	# Timestamp
	var t := Time.get_datetime_dict_from_system()
	s.fecha = "%02d/%02d/%d" % [t.day, t.month, t.year]
	s.hora  = "%02d:%02d" % [t.hour, t.minute]
	s.run_id = "run_%02d-%02d-%02d_%02d-%02d" % [t.day, t.month, t.year % 100, t.hour, t.minute]

	# Versión (usa propiedad de main si está disponible)
	if main.get("VERSION"):
		s.version = str(main.get("VERSION"))

	# Tiempo
	s.run_time_seconds = float(main.get("run_time") if main.get("run_time") != null else 0.0)

	# Economía
	s.money_final = EconomyManager.money
	s.total_generated = EconomyManager.total_money_generated

	# Estructura
	s.epsilon_peak  = StructuralModel.epsilon_peak
	s.epsilon_final = StructuralModel.epsilon_runtime
	s.omega_final   = StructuralModel.omega
	s.omega_min_reached = StructuralModel.omega_min
	s.persistence_final = StructuralModel.persistence_dynamic
	s.persistence_base  = StructuralModel.persistence_base

	# Biosfera
	s.biomasa_final    = BiosphereEngine.biomasa
	s.hifas_final      = BiosphereEngine.hifas
	s.micelio_final    = BiosphereEngine.micelio
	s.nutrientes_final = BiosphereEngine.nutrientes

	# Evolución / ruta
	s.final_route   = RunManager.final_route
	s.final_reason  = RunManager.final_reason
	s.red_branch    = EvoManager.red_branch_selected
	s.seta_formada  = EvoManager.seta_formada

	# Mutaciones activas
	var muts: PackedStringArray = []
	if EvoManager.mutation_homeostasis:         muts.append("homeostasis")
	if EvoManager.mutation_hyperassimilation:   muts.append("hyperassimilation")
	if EvoManager.mutation_symbiosis:           muts.append("symbiosis")
	if EvoManager.mutation_red_micelial:        muts.append("red_micelial")
	if EvoManager.mutation_sporulation:         muts.append("sporulation")
	if EvoManager.mutation_parasitism:          muts.append("parasitism")
	if EvoManager.mutation_depredador:          muts.append("depredador")
	if EvoManager.mutation_met_oscuro:          muts.append("met_oscuro")
	s.mutations_activated = muts

	# Métricas
	s.resilience_score     = RunManager.resilience_score
	s.disturbances_survived = RunManager.disturbances_survived
	s.homeostasis_mode     = RunManager.homeostasis_mode

	return s

# =====================================================
# SERIALIZACIÓN — Dictionary compatible con LogManager
# =====================================================

func to_dict() -> Dictionary:
	return {
		"run_id":   run_id,
		"fecha":    fecha,
		"hora":     hora,
		"version":  version,
		"tiempo":   run_time_seconds,
		"economia": {
			"money_final":    money_final,
			"total_generated":total_generated,
			"delta_ps":       delta_per_sec,
			"click_ps":       click_per_sec,
			"passive_ps":     passive_per_sec,
		},
		"estructura": {
			"epsilon_peak":    epsilon_peak,
			"epsilon_final":   epsilon_final,
			"omega_final":     omega_final,
			"omega_min":       omega_min_reached,
			"persistence":     persistence_final,
		},
		"biosfera": {
			"biomasa":   biomasa_final,
			"hifas":     hifas_final,
			"micelio":   micelio_final,
			"nutrientes":nutrientes_final,
		},
		"evolucion": {
			"ruta":       final_route,
			"razon":      final_reason,
			"mutaciones": Array(mutations_activated),
			"red_branch": red_branch,
			"seta":       seta_formada,
		},
		"metricas": {
			"resilience":     resilience_score,
			"disturbances":   disturbances_survived,
			"homeostasis":    homeostasis_mode,
			"pl_ganados":     pl_gained,
			"esencia_ganada": esencia_gained,
		},
	}
