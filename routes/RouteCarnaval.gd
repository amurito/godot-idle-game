class_name RouteCarnaval extends PostTrasRoute

## CARNAVAL DE MUTACIONES — ruta post-trascendencia.
## Selecciona 3 mutaciones aleatorias del pool y las rota cada CARNAVAL_INTERVAL segundos.
## El jugador no puede elegir bifurcación — el genoma está controlado por el carnaval.
##
## Condiciones de cierre:
##   POLIMORFÍA TOTAL  — 12 rotaciones + biomasa≥8 + omega≥0.35 + dinero≥300K
##   DOMADOR DEL CAOS  — 3 rotaciones + pico de dinero ≥ 1M

const POOL: Array = ["homeostasis", "simbiosis", "red_micelial", "parasitismo", "hiperasimilacion"]

var mutations: Array = []
var index: int = 0
var timer: float = 0.0
var total_rotations: int = 0
var peak_money: float = 0.0

func activate() -> void:
	AchievementManager.push_event("post_tras_route", {"route": "carnaval"})
	var pool: Array = POOL.duplicate()
	pool.shuffle()
	mutations = pool.slice(0, 3)
	index = 0
	timer = 0.0
	total_rotations = 0
	peak_money = 0.0
	EvoManager.carnaval_set_mutation(mutations[0])
	print("🎭 [CARNAVAL] Mutaciones: %s" % str(mutations))
	LogManager.add(tr("LOG_CARNAVAL_START") % [mutations[0], mutations[1], mutations[2]])

func tick(delta: float) -> void:
	if RunManager.run_closed or mutations.is_empty():
		return
	timer += delta
	# Actualizar pico de dinero
	peak_money = max(peak_money, EconomyManager.money)

	if timer < Balance.CARNAVAL_INTERVAL:
		return
	timer = 0.0
	index = (index + 1) % mutations.size()
	total_rotations += 1
	var next_mut: String = mutations[index]
	EvoManager.carnaval_set_mutation(next_mut)
	LogManager.add(tr("LOG_CARNAVAL_ROT") % [total_rotations, next_mut])

	# CHEQUEO: POLIMORFÍA TOTAL
	if total_rotations >= 12:
		var biomasa: float = BiosphereEngine.biomasa
		var omega: float = StructuralModel.omega
		var dinero: float = EconomyManager.money
		if biomasa >= 8.0 and omega >= 0.35 and dinero >= 300000.0:
			RunManager.close_run("POLIMORFÍA TOTAL", tr("CLOSE_POLIMORFIA") % [biomasa, omega, dinero / 1000.0])
			return

	# CHEQUEO: DOMADOR DEL CAOS
	if total_rotations >= 3 and peak_money >= 1000000.0:
		RunManager.close_run("DOMADOR DEL CAOS", tr("CLOSE_DOMADOR_CAOS") % [peak_money / 1000000.0])

func allows_bifurcation() -> bool:
	return false

func serialize() -> Dictionary:
	return {
		"mutations": mutations,
		"index": index,
		"timer": timer,
		"total_rotations": total_rotations,
		"peak_money": peak_money,
	}

func deserialize(d: Dictionary) -> void:
	mutations = d.get("mutations", [])
	index = d.get("index", 0)
	timer = d.get("timer", 0.0)
	total_rotations = d.get("total_rotations", 0)
	peak_money = d.get("peak_money", 0.0)

func get_extra_state() -> Dictionary:
	return {
		"mutations": mutations,
		"index": index,
		"timer": timer,
		"total_rotations": total_rotations,
		"peak_money": peak_money,
	}

func get_badge() -> Dictionary:
	var mut: String = mutations[index] if not mutations.is_empty() else "?"
	return {
		"text": "🎭  " + tr("ROUTE_CARNAVAL") + "  [%s]" % mut,
		"color": Color(1.0, 0.5, 0.1),
	}
