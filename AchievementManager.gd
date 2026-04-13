extends Node

# AchievementManager.gd — Autoload
# Sistema de logros con 4 tiers: MICELIO / ESPORA / FRUTO / ANCESTRAL

# Variables de logros (Tier 1 - MICELIO)
var achievement_homeostasis := false
var achievement_homeostasis_perfect := false

# Tier 2 - ESPORA
var achievement_hyperassimilation := false
var achievement_symbiosis := false
var achievement_red_micelial := false
var achievement_sporulation := false

# Tier 3 - FRUTO
var achievement_parasitism := false
var achievement_millionaire := false

# Tier 4 - ANCESTRAL
var achievement_fragile_balance := false
var achievement_insatiable_parasite := false

var fragile_balance_timer := 0.0
const FRAGILE_BALANCE_REQUIRED_TIME := 60.0

# Referencias de main para check_achievements
var main: Node = null

func set_main(main_ref: Node):
	main = main_ref

func unlock_hyperassimilation_achievement():
	if achievement_hyperassimilation: return
	achievement_hyperassimilation = true
	show_toast("LOGRO: Hiperasimilación Desbloqueada")

func unlock_sporulation_achievement():
	if achievement_sporulation: return
	achievement_sporulation = true
	show_toast("LOGRO: Esporulación Irreversible")

func unlock_red_micelial_achievement():
	if achievement_red_micelial: return
	achievement_red_micelial = true
	show_toast("LOGRO: Red Micelial Alcanzada")

func show_toast(message: String) -> void:
	if UIManager.system_message_label:
		UIManager.system_message_label.text = message

func check_achievements():
	if not main:
		return

	# Homeostasis (Tier 1)
	if RunManager.post_homeostasis and not achievement_homeostasis_perfect:
		achievement_homeostasis_perfect = true
		main.add_lap("🏁 Logro — Homeostasis Perfecta")
		show_toast("LOGRO — Homeostasis Perfecta")

	# Millonario de Esporas
	if not achievement_millionaire and main.total_money_generated >= 1000000.0:
		achievement_millionaire = true
		main.add_lap("🏁 Logro — Millonario de Esporas ($1M acumulado)")
		show_toast("LOGRO — Millonario de Esporas ($1M acumulado)")

	# Equilibrio Frágil (60s en ε óptimo)
	if not achievement_fragile_balance and main.epsilon_effective > 0.10 and main.epsilon_effective < 0.20:
		fragile_balance_timer += main.LOGIC_TICK
		if fragile_balance_timer >= FRAGILE_BALANCE_REQUIRED_TIME:
			achievement_fragile_balance = true
			main.add_lap("🏁 Logro — Equilibrio Frágil (60s en ε óptimo)")
			show_toast("LOGRO — Equilibrio Frágil")
	else:
		fragile_balance_timer = 0.0

	# Parásito Insaciable (Biomasa 20 en Parasitismo)
	if not achievement_insatiable_parasite and EvoManager.mutation_parasitism and BiosphereEngine.biomasa >= 20.0:
		achievement_insatiable_parasite = true
		main.add_lap("🏁 Logro — Parásito Insaciable (Biomasa 20 en Parasitismo)")
		show_toast("LOGRO — Parásito Insaciable")

func get_achievements_dict() -> Dictionary:
	return {
		"homeostasis": achievement_homeostasis,
		"homeostasis_perfect": achievement_homeostasis_perfect,
		"hyperassimilation": achievement_hyperassimilation,
		"symbiosis": achievement_symbiosis,
		"red_micelial": achievement_red_micelial,
		"sporulation": achievement_sporulation,
		"parasitism": achievement_parasitism,
		"millionaire": achievement_millionaire,
		"fragile_balance": achievement_fragile_balance,
		"insatiable_parasite": achievement_insatiable_parasite,
	}

func load_achievements(data: Dictionary):
	if data.has("homeostasis"):
		achievement_homeostasis = data.get("homeostasis", false)
	if data.has("homeostasis_perfect"):
		achievement_homeostasis_perfect = data.get("homeostasis_perfect", false)
	if data.has("hyperassimilation"):
		achievement_hyperassimilation = data.get("hyperassimilation", false)
	if data.has("symbiosis"):
		achievement_symbiosis = data.get("symbiosis", false)
	if data.has("red_micelial"):
		achievement_red_micelial = data.get("red_micelial", false)
	if data.has("sporulation"):
		achievement_sporulation = data.get("sporulation", false)
	if data.has("parasitism"):
		achievement_parasitism = data.get("parasitism", false)
	if data.has("millionaire"):
		achievement_millionaire = data.get("millionaire", false)
	if data.has("fragile_balance"):
		achievement_fragile_balance = data.get("fragile_balance", false)
	if data.has("insatiable_parasite"):
		achievement_insatiable_parasite = data.get("insatiable_parasite", false)
