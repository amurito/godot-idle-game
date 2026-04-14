extends Node

# StructuralModel.gd — Autoload
# Gestiona modelo estructural: épsilon, omega, persistencia y complejidad.

var main: Node = null

# ==================== PERSISTENCIA ESTRUCTURAL ====================
var persistence_dynamic: float = 1.4
var persistence_base: float = 1.4
var persistence_inertia: float = 1.0

# ==================== EPSILON Y ESTRÉS ====================
var epsilon_runtime: float = 0.0
var epsilon_peak: float = 0.0
var epsilon_active: float = 0.0
var epsilon_passive: float = 0.0
var epsilon_complex: float = 0.0
var epsilon_effective: float = 0.0

# ==================== DEBUG EPSILON ====================
var epsilon_debug := false
var epsilon_debug_throttle := 0.0
const EPSILON_DEBUG_INTERVAL := 0.25

# ==================== FLEXIBILIDAD ====================
var omega: float = 1.0
var omega_min: float = 1.0

# ==================== INSTITUCIONES ====================
var institution_accounting_unlocked: bool = false

# ==================== COOLDOWN ESTRUCTURAL ====================
var structural_cooldown: float = 0.0
const STRUCTURAL_COOLDOWN_TIME := 8.0

# ==================== BASELINE ESTRUCTURAL ====================
var baseline_delta_structural: float = 0.0
var last_stable_structural_upgrades: int = 0

# ==================== DESBLOQUEOS PROGRESIVOS ====================
var unlocked_d := false
var unlocked_md := false
var unlocked_e := false
var unlocked_me := false

# ==================== CONSTANTES ====================
const K_PERSISTENCE := 1.25
const ALPHA_KAPPA := 0.55
const COGNITIVE_MULTIPLIER := 0.05

# ==================== PERSISTENCIA UPGRADE ====================
var persistence_upgrade_unlocked := false

# ==================== INICIALIZACIÓN ====================
func set_main(m: Node):
	main = m

func reset():
	persistence_dynamic = 1.4
	persistence_base = 1.4
	persistence_inertia = 1.0
	epsilon_runtime = 0.0
	epsilon_peak = 0.0
	epsilon_active = 0.0
	epsilon_passive = 0.0
	epsilon_complex = 0.0
	epsilon_effective = 0.0
	epsilon_debug = false
	epsilon_debug_throttle = 0.0
	omega = 1.0
	omega_min = 1.0
	structural_cooldown = 0.0
	baseline_delta_structural = 0.0
	last_stable_structural_upgrades = 0
	unlocked_d = false
	unlocked_md = false
	unlocked_e = false
	unlocked_me = false

# ==================== FUNCIONES OBSERVACIONALES (fⁿ) ====================
func get_n_log() -> float:
	return 1.0 + log(1.0 + float(get_structural_upgrades()))

func get_n_power() -> float:
	return pow(float(get_structural_upgrades()) + 1.0, 0.35)

# ==================== FUNCIÓN SIGMOIDE fⁿ α ====================
func f_n_alpha(n: float) -> float:
	return 1.0 / (1.0 + exp(-0.35 * (n - 6.0)))

# ==================== PERSISTENCIA DINÁMICA ====================
func apply_dynamic_persistence(delta: float) -> void:
	var n_struct := float(get_structural_upgrades())
	var target := get_persistence_target()
	var a := f_n_alpha(n_struct)
	persistence_dynamic = lerp(
		persistence_dynamic,
		target,
		clamp(a * delta * 0.4 * persistence_inertia, 0.0, 0.25)
	)

# ==================== OBJETIVO DE PERSISTENCIA ====================
func get_persistence_target() -> float:
	var n_struct := get_effective_structural_n()
	var k_eff := get_k_eff()
	return EcoModel.get_persistence_target(persistence_base, k_eff, n_struct)

# ==================== CAPITAL COGNITIVO EFECTIVO (μ) ====================
func get_cognitive_mu() -> float:
	var mu: float = 1.0 + log(1.0 + float(UpgradeManager.level("cognitive"))) * COGNITIVE_MULTIPLIER
	return snapped(mu, 0.01)

# ==================== MODELO ESTRUCTURAL ====================
func compute_structural_model() -> Dictionary:
	var n_struct := get_effective_structural_n()
	var k_eff := get_k_eff()
	var f_n_model := persistence_base * pow(k_eff, (1.0 - 1.0 / max(n_struct, 1.0)))
	var c_n_model := persistence_base * pow(k_eff, (1.0 - 1.0 / max(n_struct, 1.0)))
	var eps_model := float(abs(f_n_model - c_n_model))

	return {
		"f_n": f_n_model,
		"c_n_model": c_n_model,
		"eps_model": eps_model,
		"k": K_PERSISTENCE,
		"k_eff": k_eff,
		"n": n_struct,
		"n_log": get_n_log(),
		"n_power": get_n_power()
	}

func get_structural_epsilon() -> float:
	var m := compute_structural_model()
	return m.eps_model

func get_k_eff() -> float:
	var mu :float = main.cached_mu
	var n_struct := get_effective_structural_n()
	var alpha := EcoModel.get_alpha(int(n_struct))
	var k_base := EcoModel.get_k_structural(int(n_struct))
	return EcoModel.get_k_eff(k_base, alpha, mu)

# ==================== BASELINE ESTRUCTURAL ====================
func register_structural_baseline():
	baseline_delta_structural = main.delta_per_sec
	last_stable_structural_upgrades = get_structural_upgrades()

# ==================== OMEGA (FLEXIBILIDAD) ====================
func get_omega(epsilon: float, k_mu: float, n: float) -> float:
	var denom := 1.0 + epsilon * k_mu * n
	return 1.0 / max(denom, 0.0001)

# ==================== RUNTIME ESTRUCTURAL ====================
func compute_structural_runtime() -> float:
	return persistence_dynamic

func update_structural_hud_model_block() -> Dictionary:
	return compute_structural_model()

# ==================== PRESIÓN ESTRUCTURAL ====================
func get_structural_pressure() -> float:
	return EcoModel.get_structural_pressure(epsilon_effective, epsilon_peak, get_structural_upgrades(), get_accounting_effect())

# ==================== CAPITAL COGNITIVO - NIVEL CONTABILIDAD ====================
func get_accounting_effect() -> float:
	var base = float(UpgradeManager.level("accounting")) * 0.05
	return base + EconomyManager.mutation_accounting_bonus + (0.05 if RunManager.legacy_homeostasis else 0.0)

# ==================== FUNCIONES HELPER ====================
func get_structural_upgrades() -> int:
	var total = 0
	total += UpgradeManager.level("auto")
	total += UpgradeManager.level("auto_mult")
	total += UpgradeManager.level("trueque")
	total += UpgradeManager.level("trueque_net")
	total += UpgradeManager.level("trueque_allo") * 3
	total += UpgradeManager.level("cognitive")
	total += UpgradeManager.level("accounting")
	total += UpgradeManager.level("specialization")
	if persistence_upgrade_unlocked: total += 5
	return total

func get_effective_structural_n() -> float:
	return EcoModel.get_effective_structural_n(get_structural_upgrades(), UpgradeManager.level("accounting"))

func get_mu_structural_factor() -> float:
	var n: int = UpgradeManager.level("cognitive")
	var mu_base: float = 1.0
	if n > 0:
		mu_base = 1.0 + log(1.0 + float(n)) * 0.08

	var mu_fungi: float = BiosphereEngine.get_mu_fungi_multiplier(EvoManager.mutation_hyperassimilation, EvoManager.mutation_homeostasis)
	var mu_total: float = mu_base * mu_fungi

	return mu_total

# ==================== APLICADORES DE FACTOR ====================
func apply_flexibility_modifier(factor: float):
	omega *= factor
	omega_min *= factor

func enable_persistence_inertia(factor: float):
	persistence_inertia = factor
