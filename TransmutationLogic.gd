class_name TransmutationLogic

## TRANSMUTACIÓN (A → A+): "el paso atrás para tomar impulso".
## Spec: docs/design/involucion_transmutaciones.md §3.
##
## Con la llave del Banco comprada y la mutación A activa, aparece un botón de reversión que
## parpadea TRANSMUT_APPEARANCES veces (TRANSMUT_APPEAR_DURATION s cada una) dentro de una ventana
## adaptada a la vida de A, y después desaparece para siempre esa run. Revertir:
##   1. pierde A (su flag y sus efectos; el genoma queda bloqueado esa run),
##   2. la DIGIERE: pago inmediato en el recurso que la definía,
##   3. activa la ruta A+.
## El estado vive en EvoManager (transmut_*); este archivo sólo tiene funciones estáticas,
## igual que DarkTreeLogic / PrimordioLogic.

## Una entrada por transmutación. Agregar una nueva = una entrada + su activate_* + su digest_*.
##   key          buff del Banco (llave permanente, sin toggle)
##   base_flag    var de EvoManager de la mutación A
##   base_genome  clave de EvoManager.genome de A (queda "bloqueado" al revertir)
##   target_flag  var de EvoManager de la ruta A+
##   activate     Callable que activa A+ (método de EvoManager)
##   digest       Callable que paga la digestión y devuelve el texto para el log
##   life         Callable → vida esperada de A en s (la ventana se adapta a ella)
static func defs() -> Dictionary:
	return {
		"fusion": {
			"key": "transmut_fusion",
			"base_flag": "mutation_hyperassimilation",
			"base_genome": "hiperasimilacion",
			"target_flag": "mutation_fusion_catabolica",
			"activate": func() -> void: EvoManager.activate_fusion_catabolica(),
			"digest": func() -> String: return _digest_hiper(),
			"preview": func() -> String: return UIManager.format_compact(_hiper_digest_amount()),
			"base_name": "MUT_HIPERASIMILACION",
			"target_name": "MUT_FUSION_CATABOLICA",
			"lose": "TRANSMUT_FUSION_LOSE",
			"life": func() -> float: return Balance.HYPER_TIMEOUT,
		},
		"caos": {
			"key": "transmut_caos",
			"base_flag": "mutation_homeostasis",
			"base_genome": "homeostasis",
			"target_flag": "mutation_caos_orquestado",
			"activate": func() -> void: CaosOrquestadoLogic.activate(),
			"digest": func() -> String: return CaosOrquestadoLogic.digest_homeostasis(),
			"preview": func() -> String: return TranslationServer.translate("TRANSMUT_DIGEST_OMEGA") % Balance.CAOS_DIGEST_OMEGA_MIN,
			"base_name": "MUT_HOMEOSTASIS",
			"target_name": "MUT_CAOS_ORQUESTADO",
			"lose": "TRANSMUT_CAOS_LOSE",
			# Homeostasis no se cierra sola (el jugador sella su tier): ventana completa de 5 min.
			"life": func() -> float: return 1.0e9,
		},
	}

## Ids de las llaves (el Banco no les muestra toggle: la decisión es en la run).
static func key_ids() -> Array:
	var out: Array = []
	for id in defs():
		out.append(defs()[id].key)
	return out


## La transmutación disponible ahora ("" si ninguna): llave comprada, A activa, A+ no activa,
## no revertida antes esta run, y A no evolucionó a otra cosa (Depredador / Met. Oscuro).
static func candidate() -> String:
	if RunManager.run_closed or EvoManager.mutation_depredador or EvoManager.mutation_met_oscuro:
		return ""
	var d := defs()
	for id in d:
		var t: Dictionary = d[id]
		if LegacyManager.get_buff_level(t.key) <= 0:
			continue
		if not bool(EvoManager.get(t.base_flag)) or bool(EvoManager.get(t.target_flag)):
			continue
		if EvoManager.transmut_reverted.get(t.base_genome, false):
			continue
		return id
	return ""


## Ventanas [inicio, fin) en segundos de A activa. Ventana total W = min(TRANSMUT_WINDOW_MAX,
## vida − TRANSMUT_WINDOW_MARGIN); primera aparición en min(TRANSMUT_FIRST_DELAY, W/4) y las demás
## repartidas para que la última termine justo en W. Hiper (vida 180 s) → 40 / 90 / 140 s.
static func slots(id: String) -> Array:
	var life: float = defs()[id].life.call()
	var w: float = minf(Balance.TRANSMUT_WINDOW_MAX, life - Balance.TRANSMUT_WINDOW_MARGIN)
	var dur: float = Balance.TRANSMUT_APPEAR_DURATION
	var n: int = Balance.TRANSMUT_APPEARANCES
	var t0: float = minf(Balance.TRANSMUT_FIRST_DELAY, w / 4.0)
	var step: float = (w - t0 - dur) / float(maxi(n - 1, 1))
	var out: Array = []
	for k in n:
		var s: float = t0 + step * k
		out.append([s, s + dur])
	return out


## Segundos que le quedan a la aparición actual del botón (0 = no visible).
static func visible_secs_left() -> float:
	var id := candidate()
	if id == "":
		return 0.0
	var t: float = EvoManager.transmut_base_time
	for s in slots(id):
		if t >= s[0] and t < s[1]:
			return s[1] - t
	return 0.0


static func is_visible() -> bool:
	return visible_secs_left() > 0.0


## Apariciones que quedan (incluida la actual) — para el texto del botón.
static func appearances_left() -> int:
	var id := candidate()
	if id == "":
		return 0
	var left := 0
	for s in slots(id):
		if EvoManager.transmut_base_time < s[1]:
			left += 1
	return left


## Tick (fase de procesos de ruta): cuenta el tiempo con A activa y marca el dinero al empezar
## (base de la digestión de Hiper).
static func tick(dt: float) -> void:
	if candidate() == "":
		return
	if EvoManager.transmut_money_mark < 0.0:
		EvoManager.transmut_money_mark = EconomyManager.total_money_generated
	EvoManager.transmut_base_time += dt


## Revierte A → A+. Devuelve true si transmutó. Por defecto exige el botón visible; el diálogo
## de confirmación pasa require_visible=false si se abrió dentro de una aparición (el jugador no
## pierde la decisión por tardar en leer).
static func revert(id: String, require_visible: bool = true) -> bool:
	if id == "" or candidate() != id or (require_visible and not is_visible()):
		return false
	var t: Dictionary = defs()[id]
	var digest_text: String = t.digest.call()
	EvoManager.transmut_reverted[t.base_genome] = true
	EvoManager.set(t.base_flag, false)
	EvoManager._set_genome_state(t.base_genome, "bloqueado")
	LogManager.add(TranslationServer.translate("LOG_TRANSMUT_REVERTED") % [
		TranslationServer.translate(t.base_name), TranslationServer.translate(t.target_name), digest_text])
	t.activate.call()
	return true


# ── Digestiones: cada mutación se digiere en el recurso que la definía ──────

## Hiperasimilación (rush de click) → dinero: TRANSMUT_DIGEST_HIPER del $ generado con Hiper activa.
## Va a `money`, no a total_money_generated: es digestión, no producción (no adelanta sellos).
static func _hiper_digest_amount() -> float:
	var mark: float = maxf(EvoManager.transmut_money_mark, 0.0)
	return maxf(EconomyManager.total_money_generated - mark, 0.0) * Balance.TRANSMUT_DIGEST_HIPER

static func _digest_hiper() -> String:
	var amount: float = _hiper_digest_amount()
	EconomyManager.money += amount
	return TranslationServer.translate("TRANSMUT_DIGEST_MONEY") % UIManager.format_compact(amount)
