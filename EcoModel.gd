extends Node

# EcoModel.gd — Autoload (o Static)
# Centraliza las fórmulas matemáticas del sistema económico.

# Fórmulas de Producción
func get_click_power(base: float, multiplier: float, dynamic_p: float, mu_factor: float) -> float:
	return base * multiplier * dynamic_p * mu_factor

func get_auto_income_effective(income: float, multiplier: float, specialization: float, mu_factor: float, biomass_beta: float, accounting_level: int) -> float:
	var base = income * multiplier * specialization * mu_factor * biomass_beta
	return base * (1.0 + accounting_level * 0.05)

func get_trueque_raw(level: int, base_income: float, efficiency: float) -> float:
	return level * base_income * efficiency

func get_trueque_income_effective(raw_trueque: float, network: float, mu_factor: float, biomass_beta: float, accounting_level: int) -> float:
	var base = raw_trueque * network * mu_factor * biomass_beta
	return base * (1.0 + accounting_level * 0.05)

# Fórmulas Estructurales
func get_persistence_target(base_p: float, k_eff: float, n_struct: float) -> float:
	if n_struct <= 1:
		return base_p
	return base_p * pow(k_eff, (1.0 - 1.0 / n_struct))

func get_alpha(n: int) -> float:
	var base = 0.1
	if LegacyManager.get_buff_value("horizonte_estructural"):
		base = 0.55 # El antiguo límite es ahora el suelo
	
	var val = base + log(1.0 + float(n)) * 0.12
	if LegacyManager.get_buff_value("horizonte_estructural"):
		return val
	return min(val, 0.55)

func get_k_structural(n: int) -> float:
	var base = 1.05
	if LegacyManager.get_buff_value("horizonte_estructural"):
		base = 1.25 # El antiguo límite es ahora el suelo
		
	var val = base + log(1.0 + float(n)) * 0.05
	if LegacyManager.get_buff_value("horizonte_estructural"):
		return val
	return min(val, 1.25)

func get_k_eff(base_k: float, alpha: float, mu: float) -> float:
	return base_k * (1.0 + alpha * (mu - 1.0))

func get_omega(epsilon: float, k_mu: float, n: float) -> float:
	# Suavizamos el impacto de n para que no cristalice tan rápido en el mid-game
	var denom := 1.0 + epsilon * k_mu * pow(n, 0.85) 
	return 1.0 / max(denom, 0.0001)

func get_effective_structural_n(raw_n: int, accounting_level: int) -> float:
	# La contabilidad REDUCE la complejidad percibida (orden), no la aumenta.
	return float(raw_n) / (1.0 + accounting_level * 0.3)

func get_structural_pressure(eps_eff: float, eps_peak: float, n_struct: int, accounting_effect: float) -> float:
	var base := eps_eff * (1.0 + eps_peak) * float(n_struct)
	var mitigated := base * (1.0 - accounting_effect)
	return mitigated
