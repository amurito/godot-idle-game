class_name ReactorFX

## Efectos visuales del núcleo compartidos por ReactorVisual (2D) y Reactor3D.
## Puramente visual: no toca estado de juego (los goldens no lo ven). Reloj de pared.
##
## · Compresión de TRANSMUTACIÓN (al revertir con [T]): el núcleo se comprime mientras el color de
##   la evolución se va a blanco, aguanta un instante y se expande de golpe en el color de la
##   transmutación (complementario de la evolución: paleta en UIManager.get_reactor_color).
## · Latido a contrafase mientras una transmutación A+ está activa: el núcleo se CONTRAE en el
##   golpe (las evoluciones laten hacia afuera; la transmutación, hacia adentro).

const COMPRESS_IN := 0.9      # s comprimiendo (color → blanco)
const COMPRESS_HOLD := 0.25   # s comprimido y brillante
const COMPRESS_OUT := 0.55    # s expandiendo con rebote (blanco → color nuevo)
const COMPRESS_MIN := 0.28    # escala mínima en el punto de compresión
const BURST_OVERSHOOT := 0.3  # rebote al expandir

const HEARTBEAT_PERIOD := 1.6     # s entre latidos
const HEARTBEAT_DEPTH := 0.09     # cuánto se contrae en el golpe

static var _start_ms: int = -1
static var _from_color: Color = Color.WHITE


## Llamar al revertir (TransmutationLogic.revert), con el color del reactor ANTES del cambio.
static func start_transmutation(from_color: Color) -> void:
	_from_color = from_color
	_start_ms = Time.get_ticks_msec()


static func _elapsed() -> float:
	if _start_ms < 0:
		return -1.0
	var t: float = (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > COMPRESS_IN + COMPRESS_HOLD + COMPRESS_OUT:
		_start_ms = -1
		return -1.0
	return t


static func transmutation_active() -> bool:
	return EvoManager.mutation_fusion_catabolica or EvoManager.mutation_caos_orquestado \
		or EvoManager.mutation_coro_simbiotico or EvoManager.mutation_micelio_omnisciente \
		or EvoManager.mutation_huesped_soberano


## Multiplicador de escala del núcleo (compresión + latido a contrafase).
static func scale_mult() -> float:
	var m := 1.0
	var t := _elapsed()
	if t >= 0.0:
		if t < COMPRESS_IN:
			var k: float = t / COMPRESS_IN
			m = lerpf(1.0, COMPRESS_MIN, k * k)  # acelera al comprimirse
		elif t < COMPRESS_IN + COMPRESS_HOLD:
			m = COMPRESS_MIN
		else:
			var k2: float = (t - COMPRESS_IN - COMPRESS_HOLD) / COMPRESS_OUT
			# expansión con rebote: pasa de largo y se asienta en 1
			m = lerpf(COMPRESS_MIN, 1.0, k2) + sin(k2 * PI) * BURST_OVERSHOOT
		return m
	if transmutation_active() and not RunManager.run_closed:
		var phase: float = fmod(Time.get_ticks_msec() / 1000.0, HEARTBEAT_PERIOD) / HEARTBEAT_PERIOD
		if EvoManager.mutation_coro_simbiotico and CoroSimbioticoLogic.period() > 0.0:
			# Coro: el latido marca el golpe del metrónomo (contracción máxima justo en el golpe).
			phase = fposmod(CoroSimbioticoLogic.beat_phase() + 0.25, 1.0)
		var beat: float = pow(maxf(sin(phase * TAU), 0.0), 4.0)  # golpe corto y seco
		m = 1.0 - HEARTBEAT_DEPTH * beat
	return m


## Color del núcleo durante la compresión (si no hay compresión, devuelve `c` sin tocar).
static func tint(c: Color) -> Color:
	var t := _elapsed()
	if t < 0.0:
		return c
	if t < COMPRESS_IN:
		return _from_color.lerp(Color(1.4, 1.4, 1.4), t / COMPRESS_IN)
	if t < COMPRESS_IN + COMPRESS_HOLD:
		return Color(1.5, 1.5, 1.5)
	return Color(1.5, 1.5, 1.5).lerp(c, (t - COMPRESS_IN - COMPRESS_HOLD) / COMPRESS_OUT)
