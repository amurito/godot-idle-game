extends Control
class_name MetronomeRing

## Metrónomo visual + sonoro sobre el núcleo (Coro Simbiótico y legado Compás Interno).
## Hijo del botón del reactor (UIManager.big_click_button): un aro que se cierra hacia el núcleo y
## lo toca justo en el golpe. Brilla mientras estás dentro de la ventana de acierto y destella
## blanco (golpe) o rojo (fuera de tiempo) después de cada click. Puramente presentación: el
## juicio del click vive en CoroSimbioticoLogic.on_click().

const RING_START := 1.65     # radio del aro al salir del golpe (× radio del núcleo)
const CORE_FRAC := 0.30      # radio del núcleo ≈ 30 % del lado menor del botón
const FLASH_MS := 220

var _last_beat: int = -2147483648


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 20  # por encima de ReactorVisual (z 10)


func _process(_delta: float) -> void:
	if CoroSimbioticoLogic.period() <= 0.0:
		return
	var k: int = floori(CoroSimbioticoLogic.beat_pos(RunManager.run_time))
	if k != _last_beat:
		if _last_beat != -2147483648 and k == _last_beat + 1:
			AudioManager.play_metronome(CoroSimbioticoLogic.is_downbeat(k))
		_last_beat = k
	queue_redraw()


func _draw() -> void:
	var p: float = CoroSimbioticoLogic.period()
	if p <= 0.0:
		return
	var center: Vector2 = size / 2.0
	var r_core: float = minf(size.x, size.y) * CORE_FRAC
	var phase: float = CoroSimbioticoLogic.beat_phase()          # 0 = en el golpe
	var coro: bool = EvoManager.mutation_coro_simbiotico
	var base := Color(1.0, 0.55, 0.45) if coro else Color(0.85, 0.75, 0.65)
	# Ventana de acierto: cerca del golpe (antes o después) el aro se enciende.
	var to_beat: float = minf(phase, 1.0 - phase) * p
	var in_window: bool = to_beat <= Balance.CORO_HIT_WINDOW
	var r: float = lerpf(r_core * RING_START, r_core, phase)
	var alpha: float = (0.25 + 0.55 * phase) * (1.0 if coro else 0.55)
	var col := base
	col.a = alpha
	if in_window:
		col = Color(1.0, 0.95, 0.85, 0.95 if coro else 0.6)
	draw_arc(center, r, 0.0, TAU, 64, col, 3.0 if coro else 2.0, true)
	# Feedback del último click.
	var since: int = Time.get_ticks_msec() - CoroSimbioticoLogic.last_judge_ms
	if CoroSimbioticoLogic.last_judge_ms >= 0 and since < FLASH_MS:
		var f: float = 1.0 - float(since) / FLASH_MS
		var fc := Color(1.0, 1.0, 1.0, f) if CoroSimbioticoLogic.last_judge_hit else Color(1.0, 0.2, 0.2, f)
		draw_arc(center, r_core * (1.0 + 0.15 * (1.0 - f)), 0.0, TAU, 64, fc, 4.0, true)
