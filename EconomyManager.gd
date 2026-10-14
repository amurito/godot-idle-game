extends Node

# EconomyManager.gd — Autoload
# Gestiona dinero, ingresos (click, auto, trueque) y economía del juego.

var main: Node = null

# ==================== ESTADO ECONÓMICO ====================
var money: float = 0.0
var total_money_generated: float = 0.0
var time_since_last_click: float = 0.0
var cached_mu: float = 1.0
var delta_per_sec: float = 0.0

# ==================== DINÁMICAS ECONÓMICAS ====================
var trueque_base_income: float = 8.0
var trueque_efficiency: float = 0.75
var mutation_auto_factor: float = 1.0
var mutation_trueque_factor: float = 1.0
var mutation_accounting_bonus: float = 0.0
var parasitism_corrosion: float = 1.0 # 1.0 -> 0.0 (Colapso total)

# ==================== CONSTANTES ====================
const CLICK_RATE := 1.0

# ==================== MEMO DE ALCANCE ACOTADO ====================
# Dentro de un bloque begin_memo()/end_memo() cada getter del pipeline se calcula UNA vez y se
# reutiliza (un refresco de UI pedía get_click_power() ~10 veces y los ingresos ~20). El bloque
# sólo debe envolver código que LEE los insumos del pipeline sin modificarlos (main.update_ui()).
# Fuera del bloque todo se calcula como siempre: no hay invalidaciones manuales que olvidar.
# Un bloque que no se cierre (p.ej. por un error de script a mitad de update_ui) caduca solo al
# cambiar de frame, así nunca puede congelar la economía.
var _memo: Dictionary = {}
var _memo_depth: int = 0
var _memo_frame: int = -1

func begin_memo() -> void:
	var frame := Engine.get_process_frames()
	if _memo_depth == 0 or frame != _memo_frame:
		_memo_depth = 0
		_memo.clear()
		_memo_frame = frame
	_memo_depth += 1

func end_memo() -> void:
	_memo_depth = maxi(0, _memo_depth - 1)
	if _memo_depth == 0:
		_memo.clear()

func _memo_active() -> bool:
	if _memo_depth <= 0:
		return false
	if Engine.get_process_frames() != _memo_frame:
		_memo_depth = 0
		_memo.clear()
		return false
	return true

## Los Dictionary se devuelven como copia: un consumidor que mute el resultado no corrompe el caché.
func _memoized(key: String, compute: Callable) -> Variant:
	if not _memo.has(key):
		_memo[key] = compute.call()
	var value: Variant = _memo[key]
	return value.duplicate() if value is Dictionary else value

# ==================== INICIALIZACIÓN ====================
func set_main(m: Node):
	main = m

func reset():
	money = 0.0
	total_money_generated = 0.0
	time_since_last_click = 0.0
	cached_mu = 1.0
	delta_per_sec = 0.0
	mutation_auto_factor = 1.0
	mutation_trueque_factor = 1.0
	mutation_accounting_bonus = 0.0
	parasitism_corrosion = 1.0

# ==================== CÁLCULOS DE PODER ====================
func get_click_power() -> float:
	if _memo_active():
		return _memoized("get_click_power", _compute_click_power)
	return _compute_click_power()

func _compute_click_power() -> float:
	var base := UpgradeManager.value("click")
	# LEGADO: Impulso Manual (Base 1.0 -> 2.0)
	if LegacyManager.get_buff_value("impulso_manual"):
		base *= 2.0

	var power :float = EcoModel.get_click_power(
		base,
		UpgradeManager.value("click_mult"),
		StructuralModel.persistence_dynamic,
		cached_mu
	)

	# Rutas, legados y buffs cósmicos: tabla declarativa (IncomeModifiers.CLICK_ORDER)
	power = IncomeModifiers.apply("click", power)

	# PROTOCOLO OMEGA-CERO: Φ acumulada amplifica el click durante la run (aditivo, escala con síntesis).
	if EvoManager.mutation_omega_cero:
		power += EvoManager.omega_cero_phi * Balance.OMEGA_CERO_PHI_CLICK_AMP

	return power

func get_auto_income_effective() -> float:
	if _memo_active():
		return _memoized("get_auto_income_effective", _compute_auto_income_effective)
	return _compute_auto_income_effective()

func _compute_auto_income_effective() -> float:
	var auto_mult := UpgradeManager.value("auto_mult") * mutation_auto_factor

	# LEGADO: Inercia de Escala (Bonus md por contabilidad)
	if LegacyManager.get_buff_value("inercia_escala"):
		var acc_lvl = UpgradeManager.level("accounting")
		auto_mult *= (1.0 + acc_lvl * 0.05)

	var effective := EcoModel.get_auto_income_effective(
		UpgradeManager.value("auto"),
		auto_mult,
		UpgradeManager.value("specialization"),
		cached_mu,
		BiosphereEngine.get_biomass_beta(),
		UpgradeManager.level("accounting")
	)

	# ALLOSTASIS: Impulso Metabólico Adaptativo (v0.9)
	if EvoManager.mutation_allostasis:
		effective *= 5.0

	# MICELIO OMNISCIENTE: Contabilidad conectada amplifica su +5 %/nivel (1.0 fuera de la ruta).
	effective *= MicelioOmniscienteLogic.accounting_factor()

	return effective

func get_trueque_raw() -> float:
	return UpgradeManager.value("trueque")

func get_trueque_income_effective() -> float:
	if _memo_active():
		return _memoized("get_trueque_income_effective", _compute_trueque_income_effective)
	return _compute_trueque_income_effective()

func _compute_trueque_income_effective() -> float:
	var allo_mult = UpgradeManager.value("trueque_allo") if UpgradeManager.level("trueque_allo") > 0 else 1.0
	var base := EcoModel.get_trueque_income_effective(
		get_trueque_raw(),
		UpgradeManager.value("trueque_net") * mutation_trueque_factor * allo_mult,
		cached_mu,
		BiosphereEngine.get_biomass_beta(),
		UpgradeManager.level("accounting")
	)

	# RED DE CONFIANZA: +10% eficiencia de trueque por nivel
	var trueque_bonus: float = LegacyManager.get_effect_value("trueque_efficiency_add")
	if trueque_bonus > 0.0:
		base *= (1.0 + trueque_bonus)

	base *= MicelioOmniscienteLogic.accounting_factor()
	base *= HuespedSoberanoLogic.trueque_mult()  # trueque domesticado (1.0 fuera de la ruta)

	return base

func get_passive_total() -> float:
	if _memo_active():
		return _memoized("get_passive_total", _compute_passive_total)
	return _compute_passive_total()

func _compute_passive_total() -> float:
	var total := get_auto_income_effective() + get_trueque_income_effective()

	# LEGADO: Redirección de Energía (10% click a pasivo)
	if LegacyManager.get_buff_value("redireccion_energia"):
		total += get_click_power() * 0.10

	# Rutas, legados y buffs cósmicos: tabla declarativa (IncomeModifiers.PASSIVE_ORDER)
	total = IncomeModifiers.apply("passive", total)

	# MEMORIA SINÁPTICA (NG+ de PROTOCOLO OMEGA-CERO): término pasivo aditivo exp(k·(1−Ω))−1,
	# acotado. Inerte en runs normales (Ω alto → ≈0), explosivo en el árbol oscuro (Ω→0).
	# Aditivo y al final: NO se multiplica por mults de ruta (evita el exploit de VACÍO ×100).
	# La intensidad (k) escala con el Núcleo Φ logrado al sellar el protocolo (kernel persistido).
	if LegacyManager.get_buff_value("memoria_sinaptica"):
		total += _compute_memoria_sinaptica_additive()

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

# Término aditivo de Memoria Sináptica (se suma al pasivo DESPUÉS de los multiplicadores).
# Inerte salvo en el árbol oscuro (omega-cero). Se aísla para no distorsionar el multiplicador.
func get_memoria_sinaptica_additive() -> float:
	if _memo_active():
		return _memoized("get_memoria_sinaptica_additive", _compute_memoria_sinaptica_additive)
	return _compute_memoria_sinaptica_additive()

func _compute_memoria_sinaptica_additive() -> float:
	if not LegacyManager.get_buff_value("memoria_sinaptica"):
		return 0.0
	var kernel: float = clampf(LegacyManager.omega_cero_kernel_max, 1.0, Balance.OMEGA_CERO_KERNEL_CAP)
	var k_eff: float = Balance.OMEGA_CERO_BUFF_K_BASE * kernel
	return min(exp(k_eff * (1.0 - StructuralModel.omega)) - 1.0, Balance.OMEGA_CERO_BUFF_CAP)

# Multiplicador efectivo aplicado al pasivo base (auto+trueque) por todas las rutas/legados.
# get_passive_total() = (auto+trueque) × ESTE + términos aditivos (ms). Lo usamos para que el
# header y los segmentos muestren las contribuciones REALES, no los valores base.
func get_passive_multiplier() -> float:
	if _memo_active():
		return _memoized("get_passive_multiplier", _compute_passive_multiplier)
	return _compute_passive_multiplier()

func _compute_passive_multiplier() -> float:
	var base := get_auto_income_effective() + get_trueque_income_effective()
	if base <= 0.0:
		return 1.0
	return (get_passive_total() - get_memoria_sinaptica_additive()) / base

func get_contribution_breakdown() -> Dictionary:
	if _memo_active():
		return _memoized("get_contribution_breakdown", _compute_contribution_breakdown)
	return _compute_contribution_breakdown()

func _compute_contribution_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var pmult := get_passive_multiplier()
	# Contribuciones efectivas: el pasivo base se escala por todos los multiplicadores (Fusión, PL, bio…).
	var d := get_auto_income_effective() * pmult
	var e := get_trueque_income_effective() * pmult
	var ms := get_memoria_sinaptica_additive()

	var total := push + d + e + ms
	if total == 0.0 or is_nan(total) or is_inf(total):
		total = 0.00001

	return {
		"click": push / total * 100.0,
		"d": d / total * 100.0,
		"e": e / total * 100.0,
		"total": total
	}

func get_active_passive_breakdown() -> Dictionary:
	if _memo_active():
		return _memoized("get_active_passive_breakdown", _compute_active_passive_breakdown)
	return _compute_active_passive_breakdown()

func _compute_active_passive_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var passive := get_passive_total()  # incluye re, ms y todos los términos aditivos

	var total := push + passive
	if total == 0.0 or is_nan(total) or is_inf(total):
		total = 0.00001

	return {
		"activo": push / total * 100.0,
		"pasivo": passive / total * 100.0,
		"push_abs": push,
		"passive_abs": passive,
		"total": total
	}

# ==================== ACTUALIZACIÓN ECONÓMICA ====================
## PARASITISMO: corrosión irreversible de la infraestructura + drenaje directo de liquidez,
## ambos escalados por la biomasa.
func apply_parasitism_drain(dt: float) -> void:
	if not EvoManager.mutation_parasitism:
		return
	var drain_intensity: float = clamp(BiosphereEngine.biomasa / 15.0, 0.4, 3.0)
	parasitism_corrosion = max(0.0, parasitism_corrosion - 0.002 * drain_intensity * dt * HuespedSoberanoLogic.corrosion_rate_mult())
	var money_drain: float = BiosphereEngine.biomasa * 0.25 * dt
	money = max(money - money_drain, 0.0)

func update_economy(delta: float):
	if is_nan(delta_per_sec) or is_inf(delta_per_sec):
		delta_per_sec = 0.0
	var delta_money := delta_per_sec * delta
	money += delta_money
	if is_nan(money) or is_inf(money):
		money = 0.0
	total_money_generated += delta_money
