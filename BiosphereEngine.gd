extends Node

# BiosphereEngine.gd — Autoload
# Motor biológico aislado. Recibe entropía (ε) del motor económico y gestiona
# el crecimiento de la red micelial (Fungi DLC).

# === CONSTANTES BIOLÓGICAS ===
const PRE_HOMEOSTASIS_CAP := 8.0
const BIOMASS_CAP := 10.0

# === GENES FÚNGICOS (Atributos de especie) ===
var absorption := 0.15   # Cuánto ε se disipa
var efficiency := 0.03   # Fuerza de get_biomass_beta()
var plasticity := 0.05   # Cuánto afecta a μ

# === ESTADO DE LA BIOSFERA ===
var biomasa: float = 0.0
var nutrientes: float = 0.0
var hifas: float = 0.0

# Guarda el epsilon efectivo devuelto al sistema económico
var epsilon_effective: float = 0.0

func reset() -> void:
	biomasa = 0.0
	nutrientes = 0.0
	hifas = 0.0
	epsilon_effective = 0.0
	absorption = 0.15
	efficiency = 0.03
	plasticity = 0.05

# =====================================================
# INTERFAZ PRINCIPAL (Llamada por el Logic Tick)
# =====================================================

func process_tick(delta: float, passive_income: float, epsilon_runtime: float, is_hyperassimilation: bool, is_homeostasis: bool, is_symbiosis: bool) -> float:
	_compute_hifas(passive_income, is_homeostasis)
	_update_nutrients(delta, epsilon_runtime)
	_grow_biomass(delta, epsilon_runtime, is_hyperassimilation, is_homeostasis, is_symbiosis)
	
	# Aseguramos que el epsilon efectivo se calcule siempre, incluso si no hubo crecimiento
	_compute_epsilon_breakdown(delta, epsilon_runtime, is_hyperassimilation, is_homeostasis, is_symbiosis)
	
	return epsilon_effective

# =====================================================
# LÓGICA INTERNA MINUTO A MINUTO
# =====================================================

func _compute_hifas(passive_income: float, is_homeostasis: bool) -> void:
	var h := pow(passive_income, 0.6)
	if is_homeostasis:
		h *= 0.85
	hifas = h

func _grow_biomass(delta: float, _epsilon_runtime: float, _is_hyperassimilation: bool, is_homeostasis: bool, _is_symbiosis: bool) -> void:
	if hifas <= 0 or nutrientes <= 0:
		return

	# Crecimiento base
	var biomass_gain = hifas * sqrt(nutrientes) * 0.02 * delta
	biomasa += biomass_gain

	# Consumo de nutrientes
	nutrientes -= biomass_gain * 0.5
	nutrientes = max(nutrientes, 0.0)

	# --- CÁLCULO DE ESTRÉS ABSORBIDO (Epsilon Efectivo) ---
	_compute_epsilon_breakdown(delta, _epsilon_runtime, _is_hyperassimilation, is_homeostasis, _is_symbiosis)

	# --- PRE-HOMEOSTASIS SOFT CAP ---
	if not is_homeostasis:
		if biomasa > PRE_HOMEOSTASIS_CAP:
			biomasa = lerp(biomasa, PRE_HOMEOSTASIS_CAP, 0.15)

	# --- HOMEOSTASIS: límite biológico duro ---
	if is_homeostasis:
		biomasa = min(biomasa, BIOMASS_CAP)

func _compute_epsilon_breakdown(_delta: float, epsilon_runtime: float, is_hyperassimilation: bool, _is_homeostasis: bool, is_symbiosis: bool) -> void:
	if hifas <= 0:
		epsilon_effective = epsilon_runtime
		return

	if is_hyperassimilation:
		# Hiperasimilación: el hongo GENERA estrés en el sistema (feedback positivo peligroso)
		# Multiplicamos por la biomasa para que sea un efecto creciente
		epsilon_effective = epsilon_runtime * (1.0 + biomasa * 0.25)
	elif is_symbiosis:
		epsilon_effective = epsilon_runtime * 0.4 # Gran absorción
	else:
		# Absorción estándar por biomasa
		epsilon_effective = epsilon_runtime / (1.0 + biomasa * 0.5)
	
	epsilon_effective = max(epsilon_effective, 0.0)

func _update_nutrients(delta: float, epsilon_runtime: float) -> void:
	# El nutriente se genera por la diferencia entre el estrés bruto y el que el hongo disipa
	# Si epsilon_effective < epsilon_runtime, significa que el hongo absorbió estrés -> gana nutrientes
	var diff := epsilon_runtime - epsilon_effective
	
	if diff > 0:
		nutrientes += diff * 12.0 * delta # Ganancia por absorción
	elif epsilon_effective > epsilon_runtime:
		# En hiperasimilación, el hongo GASTA nutrientes para inyectar estrés
		nutrientes -= (epsilon_effective - epsilon_runtime) * 25.0 * delta
	
	nutrientes = max(nutrientes, 0.0)

# =====================================================
# CONSULTAS EXTERNAS
# =====================================================

func get_biomass_beta() -> float:
	return 1.0 + log(1.0 + biomasa) * efficiency

func get_mu_fungi_multiplier(is_hyperassimilation: bool, is_homeostasis: bool) -> float:
	var p = plasticity
	if is_homeostasis:
		p *= 0.5
		
	var mu_fungi = 1.0 + log(1.0 + biomasa) * p
	
	if is_hyperassimilation:
		mu_fungi *= 0.85 

	return mu_fungi

# Cuando ocurre una esporulación, el ecosistema colapsa pero deja esporas
func trigger_sporulation() -> float:
	var spores := biomasa * 0.7
	biomasa = max(biomasa * 0.3, 0.0)
	hifas = max(hifas * 0.2, 0.0)
	nutrientes += spores * 1.5
	return spores

# Efectos permanentes del parasitismo
func apply_parasitism_buffs() -> void:
	absorption *= 1.6
	efficiency *= 1.3
