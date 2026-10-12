# Antes / después del sprint de deuda técnica (2026-10)

**Antes:** `323b591` (último commit previo al sprint) · **Después:** `main` tras el sprint (C1–C9 + fixes).
Mismo harness en ambos (tests/sim y tools/sim actuales copiados al worktree viejo), misma máquina
(RTX 2070 SUPER, Windows 11, Godot 4.5.1 headless), misma semilla (1337), 3 repeticiones por
configuración, mediana. Dispersión entre repeticiones < 3 %.

Reproducir: `tools/sim/run_benchmark.ps1` + `tools/sim/bench_analyze.py` (instrucciones en el script).

## Resumen

| | Antes | Después | Cambio |
|---|---:|---:|---:|
| **CPU de juego por segundo real** (desktop, 6 cps) | 130.9 ms/s (13 % de un núcleo) | 24.7 ms/s (2.5 %) | **−81 %** |
| CPU por segundo (web, 6 cps) | 79.1 ms/s | 14.3 ms/s | **−82 %** |
| Costo de un click | 7.75 ms | 0.21 ms | **−97 %** |
| Tick de UI (media) | 8.12 ms | 1.77 ms | **−78 %** |
| Tick de UI (p95) | 11.3 ms | 2.5 ms | −78 % |
| Peor frame estimado (UI + click + lógica en el mismo frame) | ≈ 20 ms (> 16.7 ms: se pierde un frame a 60 fps) | ≈ 4 ms | |
| Velocidad del simulador headless | 7.4× tiempo real | 37.2× | **×5** |
| Memoria estática | 81.7 MB | 82.2 MB | +0.5 MB |
| Objetos / nodos vivos | 2581 / 387 | 2583 / 387 | = |
| Reloj de logros "sostenidos" | 2.0× (web) – 3.5× (desktop) | 1.00× en todas | bug C2 corregido |

## Por escenario (CPU ms por segundo real)

| Escenario | Antes | Después | Cambio |
|---|---:|---:|---:|
| `fresh_buy_all` desktop (T0, 6 cps) | 130.9 | 24.7 | −81 % |
| `fresh_buy_all` web (UI a 4 Hz) | 79.1 | 14.3 | −82 % |
| `fresh_hiper` desktop (7 cps) | 134.5 | 26.4 | −80 % |
| `ng_fusion_player` desktop (T3 + Fusión) | 150.5 | 26.7 | −82 % |
| `ng_legacy_showcase` desktop (T5, 7 legados) | 154.7 | 35.8 | −77 % |

CPU ms/s = 5 Hz × tick lógico + (10 Hz desktop | 4 Hz web) × tick de UI + clicks/s × costo del click.

## De dónde salió la mejora

**Click (−97 %).** Cada click llamaba a `update_ui()` completo (7.6 ms): con 6–7 cps era la mitad
del CPU del juego. Ahora el click actualiza sólo el header (C9).

**Tick de UI (−78 %).** Desglose por parte (µs por llamada, `fresh_buy_all`):

| Parte | Antes | Después |
|---|---:|---:|
| `update_buttons` | 5281 | 262 |
| `update_mutation_center_panel` | 395 | 204 |
| `update_core_labels` | 374 | 250 |
| `update_lab_metrics` | 352 | 165 |
| `update_achievements_label` | 205 | 181 |
| resto (11 partes) | ≈ 280 | ≈ 290 |

`update_buttons` re-aplicaba estilos a cada botón en cada tick (C9: sólo si cambió el estado);
los RichTextLabel calientes sólo se re-escriben si cambió el BBCode; el pipeline económico se
memoiza dentro de un mismo `update_ui()` (#2).

## Lo que empeoró (y por qué)

**Tick lógico: +83 % (621 → 1138 µs).** Medido en el mismo estado de juego:

| | Antes | Después |
|---|---:|---:|
| Lógica pura | 502 µs | 606 µs |
| `check_achievements` | (corría en la UI) | 480 µs |

- **+480 µs son los logros**, movidos de la UI al tick lógico para arreglar el reloj (C2). Antes
  corrían 10 veces/s + una vez por click (≈ 16/s a 6 cps); ahora 5 veces/s. En CPU total es una
  baja, no una suba.
- **+104 µs (+21 %) son de la tabla de modificadores de ingreso** (C5): cada regla es una lambda.
  Primera versión: `get_click_power` 19 → 42 µs (+120 %). Tras optimizar (Callables precompilados,
  descarte rápido con `buffs.has()`, `get_buff_value` sin llamada anidada): 19.7 → 23.1 µs (+17 %),
  `get_passive_total` 37.6 → 40.7 µs (+8 %). Es el precio de tener una sola fuente de verdad para
  ~25 reglas que antes estaban copiadas 3 veces (y desincronizadas).

**Memoria +0.5 MB**: tablas nuevas (IncomeModifiers, SaveSchema, reglas NG+). Despreciable.

## Código

| | Antes | Después |
|---|---:|---:|
| `main._on_logic_tick` | 229 líneas | 24 |
| `EconomyManager.get_click_power` + `get_passive_total` | 239 líneas | 47 (+ tabla de 229) |
| `SaveManager.build_save_data` + `apply_save_data` | 275 líneas | 16 (+ esquema de 333) |
| `RunManager.close_run` | 247 líneas | 158 |
| `EvoManager.reset` | 102 líneas | 3 |
| Funciones de más de 100 líneas | 23 | 19 |
| Chequeos `get_buff_value("…")` dispersos | 124 | 95 |
| `main.gd` / `EconomyManager.gd` / `SaveManager.gd` | 1396 / 402 / 665 | 1234 / 292 / 406 |

**Red de seguridad:** antes, ningún test de caracterización. Después, 6 suites golden con
≈ 3 600 entradas comparadas bit a bit (economy 2340, save 180, close_run 174, actions 110,
tick 330, 4 trayectorias de 450 s) + invariantes (memo, esquema de save, reset, clasificación
de variables). Cada refactor del sprint pasó con todas idénticas; cada cambio de comportamiento
se regrabó tras revisar el diff.

## Bugs de juego corregidos en el sprint

- Reloj de logros sostenidos 2–3.5× más rápido según plataforma (C2).
- La Trampa del Vacío inalcanzable; Fusión Catabólica moría a los 420 s por Masa Crítica.
- Botones de upgrade mostraban/habilitaban precio sin descuentos (B7).
- Chips `click×`/`pas×` del header desincronizados de la economía real.
- Control de Ω no llegaba al Ω final; su offset, `nucleo_conciencia` y la integridad del
  primordio no persistían al recargar.
- Toast de Mente Colmena con emoji roto (`?? MENTE COLMENA`).
- Floats del save sin protección contra NaN.
