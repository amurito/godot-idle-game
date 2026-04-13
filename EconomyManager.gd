extends Node

# EconomyManager.gd — Autoload
# Gestiona dinero, ingresos (click, auto, trueque) y economía del juego.

var main: Node = null

# ==================== ESTADO ECONÓMICO ====================
var money: float = 0.0
var total_money_generated: float = 0.0
var time_since_last_click: float = 0.0

# ==================== DINÁMICAS ECONÓMICAS ====================
var trueque_base_income: float = 8.0
var trueque_efficiency: float = 0.75
var mutation_auto_factor: float = 1.0
var mutation_trueque_factor: float = 1.0
var mutation_accounting_bonus: float = 0.0
var parasitism_corrosion: float = 1.0 # 1.0 -> 0.0 (Colapso total)

# ==================== CONSTANTES ====================
const CLICK_RATE := 1.0

# ==================== INICIALIZACIÓN ====================
func set_main(m: Node):
	main = m

func reset():
	money = 0.0
	total_money_generated = 0.0
	time_since_last_click = 0.0
	mutation_auto_factor = 1.0
	mutation_trueque_factor = 1.0
	mutation_accounting_bonus = 0.0
	parasitism_corrosion = 1.0

# ==================== CÁLCULOS DE PODER ====================
func get_click_power() -> float:
	var base := UpgradeManager.value("click")
	# LEGADO: Impulso Manual (Base 1.0 -> 2.0)
	if LegacyManager.get_buff_value("impulso_manual"):
		base *= 2.0

	var power := EcoModel.get_click_power(
		base,
		UpgradeManager.value("click_mult"),
		main.persistence_dynamic,
		main.cached_mu
	)

	# LEGADO: Sincronía Total (Beta afecta al click)
	if LegacyManager.get_buff_value("sincronia_total"):
		power *= BiosphereEngine.get_biomass_beta()

	# Buffs de Mutación (Rutas)
	if EvoManager.mutation_symbiosis:
		power *= 2.5
	if EvoManager.mutation_red_micelial:
		power *= 0.5
	if EvoManager.mutation_hyperassimilation:
		power *= 10.0 # RUSH DE CLICK EXTREMO

	if LegacyManager.get_buff_value("aura_dorada"):
		power *= 1.5 # Aura Dorada (Bonus permanente)

	if LegacyManager.get_buff_value("semilla_cosmica"):
		power *= 2.0 # Semilla Cósmica (Bonus permanente)

	# Corrosión Parasitaria (Converge a 0)
	if EvoManager.mutation_parasitism:
		power *= parasitism_corrosion

	return power

func get_auto_income_effective() -> float:
	var auto_mult := UpgradeManager.value("auto_mult") * mutation_auto_factor

	# LEGADO: Inercia de Escala (Bonus md por contabilidad)
	if LegacyManager.get_buff_value("inercia_escala"):
		var acc_lvl = UpgradeManager.level("accounting")
		auto_mult *= (1.0 + acc_lvl * 0.05)

	var effective := EcoModel.get_auto_income_effective(
		UpgradeManager.value("auto"),
		auto_mult,
		UpgradeManager.value("specialization"),
		main.cached_mu,
		BiosphereEngine.get_biomass_beta(),
		UpgradeManager.level("accounting")
	)

	# ALLOSTASIS: Impulso Metabólico Adaptativo (v0.9)
	if EvoManager.mutation_allostasis:
		effective *= 5.0

	return effective

func get_trueque_raw() -> float:
	return UpgradeManager.value("trueque")

func get_trueque_income_effective() -> float:
	var allo_mult = UpgradeManager.value("trueque_allo") if UpgradeManager.level("trueque_allo") > 0 else 1.0
	return EcoModel.get_trueque_income_effective(
		get_trueque_raw(),
		UpgradeManager.value("trueque_net") * mutation_trueque_factor * allo_mult,
		main.cached_mu,
		BiosphereEngine.get_biomass_beta(),
		UpgradeManager.level("accounting")
	)

func get_passive_total() -> float:
	var total := get_auto_income_effective() + get_trueque_income_effective()

	# LEGADO: Redirección de Energía (10% click a pasivo)
	if LegacyManager.get_buff_value("redireccion_energia"):
		total += get_click_power() * 0.10

	# Buffs de Mutación (Rutas)
	if EvoManager.mutation_symbiosis:
		total *= 0.5
	if EvoManager.mutation_red_micelial:
		total *= 2.5
	if EvoManager.mutation_hyperassimilation:
		total *= 0.25 # Sacrifica el pasivo por el núcleo
	if EvoManager.mutation_homeostasis:
		total *= 1.5 # Orden Administrativa
	if EvoManager.mutation_parasitism:
		total *= 1.2 # Crecimiento Parásito inicial
		total *= parasitism_corrosion # Pero la corrosión lo mata con el tiempo

	if LegacyManager.get_buff_value("aura_dorada"):
		total *= 1.5 # Aura Dorada (Bonus permanente)

	if LegacyManager.get_buff_value("semilla_cosmica"):
		total *= 2.0 # Semilla Cósmica (Bonus permanente)

	if LegacyManager.get_buff_value("mente_colmena"):
		total *= 3.0 # IA Automática (Bonus permanente)

	# Mult por Rama Evolutiva (Nodos Finales DLC)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		total *= 2.5
	elif EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		pass

	return total

func get_delta_total() -> float:
	return get_click_power() + get_passive_total()

# ==================== ANÁLISIS ECONÓMICO ====================
func get_dominant_term() -> String:
	var p := get_click_power()
	var d := get_auto_income_effective()
	var e := get_trueque_income_effective()
	var m: float = float(max(max(p, d), e))

	if m == p: return "CLICK domina el sistema"
	if m == d: return "Trabajo Manual domina el sistema"
	return "Trueque domina el sistema"

func get_contribution_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var d := get_auto_income_effective()
	var e := get_trueque_income_effective()

	var total := push + d + e
	if total == 0: total = 0.00001

	return {
		"click": push / total * 100.0,
		"d": d / total * 100.0,
		"e": e / total * 100.0,
		"total": total
	}

func get_active_passive_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var passive := get_auto_income_effective() + get_trueque_income_effective()

	var total := push + passive
	if total == 0: total = 0.00001

	return {
		"activo": push / total * 100.0,
		"pasivo": passive / total * 100.0,
		"push_abs": push,
		"passive_abs": passive,
		"total": total
	}

# ==================== ACTUALIZACIÓN ECONÓMICA ====================
func update_economy(delta: float):
	var delta_money = main.delta_per_sec * delta
	money += delta_money
	total_money_generated += delta_money
