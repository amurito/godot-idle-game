extends Control
## Visualización de la banda senoidal de REMISIÓN METABÓLICA.
## X = tiempo (pasado ← centro → futuro, ventana TIME_WINDOW segundos).
## Y = Ω (0 abajo, OMEGA_RANGE arriba).
## La línea horizontal (Ω actual) es lo que el jugador necesita mantener DENTRO de la banda sombreada.

const TIME_WINDOW := 14.0   # segundos totales mostrados (±7s desde ahora)
const OMEGA_RANGE := 0.62   # tope visual del eje Y

func _ready() -> void:
	custom_minimum_size = Vector2(0, 70)
	set_process(true)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not EvoManager.mutation_remision:
		return
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return

	var t: float = EvoManager.remision_band_timer
	var omega: float = EvoManager.remision_omega
	var in_band: bool = EvoManager.remision_in_band()

	# Fondo reactivo: verde tenue si dentro, oscuro si fuera
	var bg_col := Color(0.04, 0.14, 0.06, 1.0) if in_band else Color(0.06, 0.04, 0.04, 1.0)
	draw_rect(Rect2(0.0, 0.0, w, h), bg_col)

	# Calcular banda para cada columna
	var band_tops: PackedFloat32Array = PackedFloat32Array()
	var band_bots: PackedFloat32Array = PackedFloat32Array()
	band_tops.resize(int(w))
	band_bots.resize(int(w))
	for xi in range(int(w)):
		var time_offset: float = (float(xi) / w - 0.5) * TIME_WINDOW
		var center: float = _band_center(t + time_offset)
		band_tops[xi] = _to_y(center + Balance.REMISION_BAND_HALF, h)
		band_bots[xi] = _to_y(center - Balance.REMISION_BAND_HALF, h)

	# Relleno de banda: más brillante si dentro de la banda
	var fill_alpha: float = 0.55 if in_band else 0.20
	var fill_col := Color(0.15, 0.72, 0.30, fill_alpha)
	for xi in range(int(w)):
		draw_rect(Rect2(float(xi), band_tops[xi], 1.0, band_bots[xi] - band_tops[xi]), fill_col)

	# Bordes de la banda (líneas sólidas — guía clara de dónde mantenerse)
	var edge_col := Color(0.25, 0.90, 0.45, 0.80) if in_band else Color(0.25, 0.90, 0.45, 0.45)
	for xi in range(1, int(w)):
		draw_line(
			Vector2(float(xi - 1), band_tops[xi - 1]),
			Vector2(float(xi), band_tops[xi]),
			edge_col, 1.5)
		draw_line(
			Vector2(float(xi - 1), band_bots[xi - 1]),
			Vector2(float(xi), band_bots[xi]),
			edge_col, 1.5)

	# Línea vertical "AHORA"
	var now_x: float = w * 0.5
	draw_line(Vector2(now_x, 0.0), Vector2(now_x, h), Color(1.0, 1.0, 1.0, 0.15), 1.0)

	# Línea horizontal Ω actual (gruesa, muy visible)
	var omega_y: float = clampf(_to_y(omega, h), 1.0, h - 1.0)
	var line_col := Color(0.20, 1.00, 0.42) if in_band else Color(1.00, 0.30, 0.10)
	# Halo exterior
	draw_line(Vector2(0.0, omega_y), Vector2(w, omega_y), Color(line_col.r, line_col.g, line_col.b, 0.22), 5.0)
	# Línea principal
	draw_line(Vector2(0.0, omega_y), Vector2(w, omega_y), Color(line_col.r, line_col.g, line_col.b, 0.90), 2.0)

	# Punto Ω en NOW (grande, fácil de ver)
	draw_circle(Vector2(now_x, omega_y), 5.5, line_col)
	draw_circle(Vector2(now_x, omega_y), 2.5, Color(1.0, 1.0, 1.0, 0.9))

	# Borde del widget
	var border_col := Color(0.20, 0.55, 0.25, 0.60) if in_band else Color(0.50, 0.18, 0.10, 0.50)
	draw_rect(Rect2(0.0, 0.0, w, h), border_col, false, 1.5)

func _band_center(band_t: float) -> float:
	return Balance.REMISION_BAND_CENTER + Balance.REMISION_BAND_AMP * sin(TAU * Balance.REMISION_BAND_FREQ * band_t)

func _to_y(omega_val: float, h: float) -> float:
	return (1.0 - omega_val / OMEGA_RANGE) * h
