# Auditoría de arquitectura — HYPHAE: genesis

**Fecha:** 2026-10-11 · **Base auditada:** `main` @ `323b591` (último commit de gameplay: 2026-06-29)
**Alcance:** ~25.400 LOC GDScript, 22 autoloads, 52 scripts. Todo hallazgo de este documento fue
verificado contra el código actual (no contra docs ni memorias). Las referencias `archivo:línea`
corresponden a ese commit.

> Regla de este documento: **lo que no está medido se marca como "a medir"**. La sección
> [Mediciones](#mediciones) se completa con datos del simulador de bots headless (`tests/sim/`).

---

## 1. Diagnóstico de una línea

> **Agregar una feature = tocar N archivos-dios en sincronía manual.**

Todas las áreas críticas son instancias de una misma decisión de fondo: **estado y reglas de juego
dispersos en singletons que se conocen todos entre sí, sin frontera entre "modelo" y "vista" y sin
capa declarativa**. La transmutación AYUNO PRIMORDIAL tocó 14 archivos. Cada campo persistente se
escribe a mano en 2 lugares; cada buff económico en 2 pipelines; cada ruta en un `match` de 24
ramas, en el tick, en el save y en la UI.

---

## 2. Mapa de arquitectura y flujo de datos

### 2.1 Tipos de objeto (bien elegidos)

| Tipo | Ejemplos | Rol |
|---|---|---|
| Autoload (`extends Node`) | EconomyManager, EvoManager, RunManager… (22) | Estado mutable global |
| `class_name` estático | GenomeEvaluator, DarkTreeLogic, UITextBuilders, EcoModel | Lógica pura / builders |
| `RefCounted` instanciado | NGPlusButtonManager | Colaborador con refs a nodos |
| Script de escena | main.gd, MainMenu.gd, fungi_ui.gd | Orquestación + UI |

La taxonomía es correcta y `docs/design/arquitectura_scripts.md` está bien mantenido.
El problema no es cómo se reparten los archivos, sino **qué hace cada capa**.

### 2.2 Bucle principal (`main.gd`)

```
_ready()  → cablea 17 managers, carga save, aplica buffs, crea 3 Timers
│
├─ _process(delta)        cada frame   run_time += delta; time_since_last_click += delta
├─ _logic_timer  0.2 s    _on_logic_tick()   ← simulación completa (~230 líneas)
├─ _ui_timer     0.1 s    _on_ui_tick()      ← 0.25 s en web
└─ _autosave     30 s     SaveManager.save_game()

Fuera de main también avanzan estado de juego con el reloj de frame:
├─ TutorialManager._process   anti-stuck: regala $ por tiempo idle real   (TutorialManager.gd:98, :351-353)
└─ fungi_ui._process          desbloqueo de hifas + update_ui() cada frame (fungi_ui.gd:59)
```

### 2.3 Grafo de dependencias

| Archivo | Managers distintos referenciados |
|---|---|
| main.gd | 17 |
| RunManager.gd | 15 |
| EvoManager.gd | 12 |
| EconomyManager.gd | 10 |
| UIManager.gd | 8 |

No hay capas: es un grafo casi completo. Cualquier manager puede leer y **escribir** el estado de
cualquier otro.

---

## 3. Áreas críticas (priorizadas por riesgo para jugadores reales)

### 🔴 C1 — Serialización de saves: dos listas paralelas de ~126 campos escritas a mano

- `SaveManager.build_save_data()` (SaveManager.gd:25-157) escribe cada campo a mano.
- `SaveManager.apply_save_data()` (SaveManager.gd:177-318) los lee a mano con 121 `.get()`.
- Las secciones del JSON **no son por manager**: `"evolution"` mezcla EvoManager con
  BiosphereEngine; `"structural"` mezcla StructuralModel, EconomyManager, RunManager y `main`.
  Un "cada manager se serializa a sí mismo" ingenuo cambiaría el formato y rompería saves existentes.
- Cada campo tiene semántica de carga propia, en 4 dimensiones independientes:
  1. **Default si falta la clave:** valor actual en memoria (`ev.get(k, EvoManager.k)`) vs.
     literal (`false`, `0`, `Balance.X_START`).
  2. **Saneamiento:** `_sf(v, fallback, min)` en algunos floats, nada en otros
     (p.ej. `necrosis_omega`, `autolisis_devour_timer` no pasan por `_sf`).
  3. **Cast:** `int(...)` en algunos campos, ninguno en otros.
  4. **Transformación:** `ayuno_burst_saved_mult` se guarda desde un *método*
     (`EvoManager.ayuno_burst_mult()`, SaveManager.gd:84) y se carga en un campo privado.
- Como los autoloads **no se reinician** entre escenas, "default = valor actual" puede arrastrar
  estado de un slot anterior al cargar un save viejo al que le falta la clave.

**Por qué es el #1:** el modo de falla es **silencioso** y afecta datos de jugadores (ya hubo un
incidente de pérdida de datos). Olvidar un campo en `build_save_data` = no persiste, sin error.

### 🔴 C2 — Lógica de modelo ejecutándose dentro de la vista → comportamiento dependiente de plataforma

`main.update_ui()` (main.gd:1326) es nominalmente un refresco de pantalla, pero llama a
`check_achievements()` (main.gd:157-172), que ejecuta `AchievementManager.check_tick(RunManager.LOGIC_TICK)`.
`check_tick` (AchievementManager.gd:226-234) **acumula tiempo**: `_run_time += delta` y los timers de
logros `sustained` / custom con duración (`_timers[id] += delta`, :271 y :296).

`update_ui()` se llama desde ~30 sitios: cada UI tick (10 Hz desktop / 4 Hz web), **cada click en
desktop** (main.gd:426 — el debounce de 80 ms sólo aplica en web), cada compra, cada mutación.
Como `delta` es siempre `LOGIC_TICK = 0.2`:

| Situación | Segundos de logro por segundo real (teórico) |
|---|---|
| Desktop, sin clicks (10 Hz × 0.2) | **2.0×** |
| Web, sin clicks (4 Hz × 0.2) | **0.8×** |
| Desktop clickeando a 10 cps ((10+10) × 0.2) | **4.0×** |

Consecuencia: un logro "mantené X durante 60 s" se completaría en ~30 s en desktop, ~75 s en web y
~15 s clickeando rápido en desktop. `AchievementManager._run_time` (usado en el payload de
`on_run_closed`) tiene el mismo sesgo. **Es un bug de comportamiento, no sólo de estilo** —
corregirlo cambia la funcionalidad, por eso queda documentado y **no** se corrige en el refactor
sin aprobación explícita. *(Confirmación empírica: ver Mediciones.)*

Otros casos del mismo patrón (vista que muta modelo):

- `_sync_reactor_color()` (main.gd:1310-1325) — función de color que **escribe**
  `UpgradeManager.states["trueque_allo"].unlocked`.
- `check_dominance_transition()` dentro de `update_ui()` muta el log.
- `TutorialManager._process` regala dinero por tiempo idle real (TutorialManager.gd:351-353).
- Efectos visuales consumen el **RNG global** que también usa el gameplay
  (`ReactorVisual.gd:196,205` desde `_process`; `DarkTreeLogic.gd:577`). La secuencia aleatoria del
  juego (shocks de homeostasis, d20, devour aleatorio) depende del framerate.

### 🔴 C3 — Reglas de juego dentro de handlers de botones de `main.gd`

- `_trigger_allostasis()` (main.gd:930) otorga +$50.000 y corta ε a la mitad.
- `_on_branch_selected()` (main.gd:954) multiplica `mutation_auto_factor` ×1.5 y fija `omega_min`.
- `_on_sporulation_final_pressed()` (main.gd:1003) calcula el PL de Singularidad y cierra la run.

Las reglas no tienen API de dominio: para ejecutar "elegir rama Colonización" hay que pasar por un
handler de UI. No son testeables sin instanciar la escena completa.

### 🟠 C4 — Pipeline económico recalculado sin memoización

- `get_click_power()` (EconomyManager.gd:42-151): ~30 multiplicadores condicionales secuenciales.
- `get_passive_total()` (EconomyManager.gd:196-324): ~30 más; puede llamar recursivamente a
  `get_click_power()` (:201, `redireccion_energia`).
- 124 call sites de `get_click_power()` y 67 de `get_passive_total()` en el repo.
- Dentro de cada pipeline, varias llamadas a `LegacyManager.get_effect_value()`
  (LegacyManager.gd:495-507), que **itera todos los buffs comprados** en cada invocación.
- `get_passive_multiplier()` (:352) reconstruye el multiplicador **dividiendo** el total por la base:
  recomputa el pipeline completo sólo para des-aplicarlo.

*Medido:* ~12% del costo de un refresco de UI y ~40% de un tick lógico de 0.6 ms. Era menos crítico
de lo que suponía la auditoría de junio; memoizado en `3638ce2` (−7% UI/click). Ver Mediciones.

### 🟠 C5 — Duplicación buff → multiplicador entre click y pasivo

~15 buffs aplican la misma regla en `get_click_power()` y en `get_passive_total()` en bloques
separados (semilla_cosmica, convergencia_ciclica, apoptosis_heredada, plasticidad_terminal,
sintesis_vital, all_income_mult, cognitivo, entropia_domesticada, vacío…). La cicatriz
`# aura_dorada ya NO afecta pasivo` (EconomyManager.gd:239) muestra una desincronización pasada.

### 🟠 C6 — `EvoManager` como god-object de estado: 51 variables sueltas

No existe el concepto "ruta activa": hay 51 flags/timers independientes (`mutation_*`, `ayuno_*`,
`fusion_*`, `necrosis_*`, `omega_cero_*`…) y el tick los recorre con cadenas `if/elif`
(main.gd:596-617). Una ruta nueva = otra flag + otro `elif` en ~6 lugares + ~9 campos de save.

### 🟠 C7 — `_on_logic_tick`: god-method con orden de ejecución implícito y frágil

~230 líneas, pasos numerados con numeración duplicada (dos "8)"). Ω se calcula y luego cinco bloques
lo re-clampean (parasitismo, met. oscuro, necrosis, omega-cero, floors de legado) en un orden que
importa, con el comentario delator *"re-aplicados aquí porque el paso 8 los pisó"* (main.gd:717).
Reordenar bloques cambia el balance sin ningún error.

### 🟡 C8 — `close_run`: fórmula de bonus NG+ como `match` de 24 ramas

RunManager.gd:145-260. Cada ruta declara implícitamente `{métrica, divisor, cap}` en código.
Es data disfrazada de lógica.

### 🔴 C9 — Rendimiento de UI (el cuello de botella real, medido)

- Desktop: cada click dispara un `update_ui()` completo (main.gd:426).
- `fungi_ui._process` llama a su `update_ui()` **en cada frame** una vez desbloqueadas las hifas.
- `update_ui()` reconstruye strings BBCode grandes (`UITextBuilders`) y hace `clear()` +
  `append_text()` en RichTextLabels aunque el contenido no haya cambiado.

*Medido:* tick de UI 7.3–8.3 ms (13× el tick lógico) y 7 ms por click; ~90% fuera de la economía.

### 🟡 C10 — Red de tests mínima y no aislada

`tests/TestRunner.gd` cubre 4 módulos puros (EcoModel, Biosphere, Legacy, SaveLoad). Cero cobertura
de pipeline económico, `close_run`, tick o carga de saves viejos. Además **corre contra los datos
reales del jugador**: hace snapshot/restore de LegacyManager en memoria, pero cualquier función que
persista durante el test escribe en el banco real.

### ⚪ Riesgo operativo — trabajo sin respaldo remoto

Al momento de la auditoría `main` local tenía **14 commits sin pushear** a `origin` (Fusión Catabólica,
refactor DarkTreeLogic/NGPlusButtonManager, docs, AYUNO PRIMORDIAL completo). `origin/main` estaba en
`19c3f8c` (v1.0.3.0). Ese trabajo existía sólo en una máquina.

---

## 4. Estrategia de refactorización

### Principio rector
**Ningún refactor sin red de caracterización primero.** El objetivo es "mismo comportamiento,
mejor estructura": cada paso debe pasar un golden test byte a byte antes de commitearse.

### Plan (en este orden)

| # | Paso | Ataca | Riesgo | Verificación |
|---|---|---|---|---|
| 0 | **Harness aislado + simulador de bots headless** | C10, mide C2/C4/C9 | nulo (sólo `tests/`, sandbox) | corre en copia del proyecto con `user://` propio |
| 1 | **Golden tests**: pipeline económico (matriz de estados), save build/load (valores y tipos), trayectoria de simulación determinista | red de seguridad | nulo | se graban con el código actual |
| 2 | **Save declarativo**: esquema por campo con sección, clave, getter/setter, política de default, saneamiento, cast y transform | C1 | bajo con #1 | golden save idéntico + golden de carga de saves viejos/corruptos |
| 3 | **Memoización económica** con invalidación explícita | C4 | medio (staleness) | golden de trayectoria idéntico; sólo si la medición lo justifica |
| 4 | Tabla declarativa de buffs económicos | C5 | medio | golden económico |
| 5 | `close_run` data-driven | C8 | bajo | golden de cierre por ruta |
| 6 | Extraer reglas de handlers de UI a API de dominio (EvoManager/RunManager) | C3 | medio | golden de trayectoria con bot que elige ramas |
| 7 | Tick en fases nombradas con orden explícito | C7 | medio | golden de trayectoria |
| — | Bug C2 (tiempo de logros) | C2 | **cambia comportamiento** | requiere decisión del autor |

### Arquitectura del harness (paso 0)

Seguridad por construcción, no por cuidado:

1. `tools/sim/run_sandboxed.ps1` copia el proyecto (sin `builds/`, `docs/`, `.git`…) a un directorio
   sandbox y **renombra `config/name`** → Godot usa otro directorio `user://`. Ningún camino de código
   puede tocar saves, banco de legado, meta de slots, settings ni telemetría del jugador.
2. Cada escena de test verifica al arrancar que `OS.get_user_data_dir()` es el del sandbox; si no,
   aborta antes de hacer nada.
3. Telemetría forzada a `enabled = false` (un `user://` virgen ya arranca deshabilitado).
4. Determinismo: `seed()` fijo, tiempo simulado en frames enteros, visuales apagados.
5. Fidelidad: el simulador instancia `main.tscn` real y ejecuta **el mismo código** que el juego
   (`on_reactor_click`, `UpgradeManager.purchase_upgrade`, `_on_logic_tick`, `_on_ui_tick`,
   `TutorialManager._process`, `fungi_ui._process`) con el orden de frame del motor; sólo reemplaza
   el reloj de pared por tiempo simulado.

---

## Mediciones

Simulador de bots headless (`tests/sim/`), Godot 4.5.1, desktop, sin render (dummy). Los números
absolutos subestiman el costo real (falta el render y, en web, el overhead de wasm/JS); las
proporciones entre fases son lo relevante.

### Costo por fase

| Fase | Frecuencia | Costo medio | Notas |
|---|---|---|---|
| Tick lógico (`_on_logic_tick`) | 5 Hz | **0.5–0.7 ms** | toda la simulación del juego |
| Tick de UI (`_on_ui_tick`) | 10 Hz desktop / 4 Hz web | **7.3–8.3 ms** | ~13× el tick lógico |
| Click (`on_reactor_click`) | por click | **6.9–7.9 ms** | dispara un `update_ui()` completo en desktop |
| `update_ui()` aislado | — | 6–7 ms | |

**Conclusión: el cuello de botella es la vista (C9), no la economía (C4).** Clickeando a 6 cps en
desktop, la UI consume ~120 ms por segundo de CPU sólo en refrescos, sin contar el render.

### Llamadas al pipeline económico por fase (instrumentación temporal)

| Fase | `get_click_power` | `get_passive_total` | auto / trueque | breakdowns | % estimado de la fase |
|---|---|---|---|---|---|
| Tick de UI | 10 | 8 | ~20 c/u | 10 | ~12% |
| Click | 10 | 7 | ~17 c/u | 8 | ~12% |
| Tick lógico | 3.6 | 4.6 | 4.6 | 2 | ~40% de 0.6 ms |

Costo unitario: `get_click_power` 19 µs · `get_passive_total` 34 µs ·
`get_contribution_breakdown` 88 µs · `get_effect_value` 0.9 µs (no es el problema).

### Memoización (C4) — A/B limpio

Mismo harness, escenario `fresh_buy_all` 300 s, dos corridas por lado:

| | Sin memo | Con memo | Δ |
|---|---|---|---|
| Tick de UI | 7.83 ms | 7.29 ms | −6.9% |
| Click | 7.46 ms | 6.90 ms | −7.5% |
| Tick lógico | 0.60 ms | 0.62 ms | +4% |

Ganancia real pero modesta. El ~90% restante del costo de UI está en construir strings BBCode y
re-renderizar RichTextLabels aunque el contenido no cambie.

### Reloj de logros (C2) — confirmado

`AchievementManager._run_time / RunManager.run_time` medido: **3.24–3.45×** con un bot que clickea
6–7 cps en desktop, **2.14–2.45×** con clickeo liviano. El modelo predice
10 Hz × 0.2 + clicks/s × 0.2 + compras × 0.2 ≈ 3.27× para 6 cps: coincide.

---

## Hallazgos del simulador y los goldens

Todo lo siguiente surgió de ejecutar el juego real con bots o de caracterizar el save. Ninguno se
corrigió en este trabajo: o cambian comportamiento, o son decisiones de diseño.

### Bugs

| # | Hallazgo | Evidencia | Severidad |
|---|---|---|---|
| B1 | Reloj de logros 2–4× más rápido según plataforma y ritmo de click (C2) | medición arriba | alta (logros "sostenidos" triviales) |
| B2 | **16 floats se guardan sin `_sf()`** (NaN persiste): `autolisis_devour_timer`, `colonizacion_pert_timer`, `colonizacion_phase_time`, `depredador_inestabilidad`, `depredador_timer`, `met_oscuro_timer`, `micelio`, `necromasa`, … | golden `save_build`, variante `nan_all` | media (el incidente NaN de v1.0.2.0 sigue siendo posible) |
| B3 | Click real usa ε = 0.015; `main._on_BigClickButton_pressed()` (ε = 0.008) es código muerto | `big_click_button.gd:_pressed()` | baja (confusión al balancear) |
| B4 | `main.tscn` conecta `BigClickButton.pressed → _on_pressed`, método inexistente en `big_click_button.gd` | `main.tscn:1009` | baja — probable error de motor por click, **no verificado en runtime** |
| B5 | Tras cargar un save, `UpgradeManager.states[id].level` queda como `float` (JSON) | golden `save_load` (tipos) | baja (inocuo hoy) |
| B6 | `tests/TestRunner.gd` escribía sobre los datos reales del jugador y su mock no tenía `reset_local_state()` | corrida en sandbox | **corregido** (mock) + ahora corre en sandbox |

### Diseño (decisiones del autor)

| # | Hallazgo | Evidencia |
|---|---|---|
| D1 | **Tercer disparador de Parasitismo no documentado ("Masa Crítica")**: biomasa > 6, ε > 0.35, sin Contabilidad y run > 420 s → Parasitismo a los 7 min exactos. Quien busca Hiperasimilación tiene una ventana dura de 7 minutos. El docstring de `update_parasitismo` sólo menciona inactividad y estancamiento. | `GenomeEvaluator.gd:90`; escenarios `fresh_buy_all` y otros cierran a t = 420.x s |
| D2 | **AYUNO + Parasitismo = run en limbo.** Romper el ayuno (Q, +5 biomasa) tras >120 s sin clickear activa Parasitismo (Q no cuenta como click), pero el drain de Ayuno mantiene la biomasa en ~0 y Parasitismo sólo cierra con biomasa ≥ 15–25 → la run queda con ambas mutaciones activas indefinidamente. **"La Trampa del Vacío" es inalcanzable** (exige *cerrar* en Parasitismo). | `ng_ayuno_player`: Parasitismo a t = 231 s, run abierta a t = 1800 s; `ng_ayuno_lazy`: biomasa máx 0.11 en 28 min |
| D3 | **Fusión Catabólica muere a los 420 s**: FC apaga `mutation_hyperassimilation`, que era lo que bloqueaba Parasitismo → la Masa Crítica cierra la run mucho antes de que el sello ($100M + 150 upgrades estructurales + 3 ráfagas) sea alcanzable. Comprando Contabilidad tras activar FC se esquiva (jugada no comunicada), pero el bot llega a $132M y lo mata el estancamiento a los 1800 s antes de los 150 upgrades. | `ng_fusion_player` (t = 420.8 s), `ng_fusion_smart` (t = 1801 s) |
| D4 | AYUNO ya **no** "se logra solo": sin 5 ciclos de Q no se sella (el bot pasivo dura 30 min sin cerrar). El cambio de junio funcionó. | `ng_ayuno_lazy` |
| D5 | Red Micelial exige pasivo > activo; un jugador clickeando 0.3 cps sigue en 55–72% activo y lo cierra el estancamiento a los 30 min. | `fresh_red_micelial` |

---

## Estado del plan (2026-10-11)

| # | Paso | Estado |
|---|---|---|
| 0 | Harness aislado + simulador | ✅ `938252f` |
| 1 | Golden tests (economy 2340 · save 27+144+9 · 4 trayectorias de 450 s), deterministas bit a bit | ✅ `938252f` + `791261e` |
| 2 | Save declarativo (`SaveSchema`) | ✅ `d69cdb7` — SaveManager 664 → 405 líneas, `validate()` |
| 3 | Memoización económica | ✅ `3638ce2` — −7% UI/click (medido) |
| 4 | **C2 / B1** reloj de logros: `check_achievements()` al tick lógico (5 Hz exactos) → 1.00× en desktop y web | ✅ `074c7c7` |
| 5 | **B2** 26 floats del save con `_sf()` (no 16: 10 más fuera de `evolution`) | ✅ `074c7c7` |
| 6 | **D2** Trampa del Vacío: Parasitismo durante Ayuno cierra la run (fin del limbo, logro alcanzable) + aviso a los 100 s | ✅ `074c7c7` |
| 7 | **D3** Fusión hereda el bloqueo de Parasitismo de Hiperasimilación | ✅ `074c7c7` (sello aún exigente: balance) |
| 8 | Simulador visual + lanzador con ventana (`tools/sim/lanzador.cmd`) | ✅ `c49a59c` |
| 9 | **C9** UI: `UpgradeButton` re-aplicaba StyleBoxes en cada refresco (75% de `update_ui`); click sin `update_ui()` completo | ✅ ver abajo |
| — | **B7 (nuevo)** `UpgradeButton` muestra/habilita con `state.current_cost` crudo, la compra usa `UpgradeManager.cost()` con descuentos → botón deshabilitado aunque alcance | requiere decisión |
| 10 | **B7** UpgradeButton usa `UpgradeManager.cost()` (descuentos) para precio y habilitación | ✅ `9b05348` |
| 11 | UI: 8 RichTextLabels de la ruta caliente sólo se re-escriben si cambió el BBCode (`UIManager.set_rich_text`) → tick de UI 2.2 → 1.75 ms | ✅ `af3776c` |
| 12 | **C8** bono NG+ de `close_run` como tabla de reglas (−95 líneas de `match`); nueva suite golden `close_run` (29 rutas × 3 perfiles) | ✅ `e95db58` + `c6dd4da` |
| 13 | **C3** reglas fuera de los handlers de UI: `EvoManager.trigger_allostasis()`, `EvoManager.select_red_branch()`, `RunManager.resolve_sporulation_final()`; nueva suite golden `actions` (11 casos) | ✅ `788c2ba` + este commit |
| 14 | **C7** `_on_logic_tick` de 235 → 25 líneas: secuencia de fases nombradas; Ω en `StructuralModel.resolve_omega()` con las 4 capas documentadas (base → techos → overrides oscuros → pisos); Mente Colmena → `RunManager.tick_mente_colmena()`; procesos de ruta → `EvoManager.tick_route_processes()`; drenaje → `EconomyManager.apply_parasitism_drain()`. Nueva suite golden `tick` (28 casos, una por rama; verificada con mutación: reordenar fases → 153 diffs) | ✅ |
| — | Hallazgo C7: `control_omega_offset` (buff NG+ Control de Ω) no llegaba al Ω final → ahora es la capa 5 de `resolve_omega()` (±0.15 de offset mueve Ω ≈ ±0.15) | ✅ |
| 15 | **C5** `IncomeModifiers.gd`: una fila por regla con factor de click y de pasivo lado a lado + orden por canal; `_compute_click_power`/`_compute_passive_total` −200 líneas; chips `click×`/`pas×` del header leen la tabla (antes una 3ª copia desincronizada). Golden economy bit-exacto | ✅ |
| 16 | **C6 (alcance acotado)** `EvoManager.reset()` automático desde las declaraciones (−90 líneas a mano) + `TRANSIENT_VARS`: `SaveSchema.validate()` exige que toda variable de EvoManager persista o esté declarada transitoria. Invariantes nuevos en la suite save (reset == instancia nueva; clasificación). Agregar una ruta: de ~6 lugares a declaración + SaveSchema + su `process_*` en `tick_route_processes` | ✅ |
| — | C6 completo (objetos de ruta en vez de 90 vars/436 refs) descartado por ahora: cambia formato de save y claves de goldens con poco beneficio extra | descartado |
| — | Hallazgos C6: `nucleo_conciencia`, `primordio_integrity` y `primordio_pert_timer` ahora persisten en el save; `allostasis_timer` y `homeorhesis_timer` (código muerto) eliminados | ✅ |

### Resultado de C9 (mismo escenario, desktop, 6 cps)

| | Antes del sprint | Después |
|---|---|---|
| `update_buttons()` | 4.74 ms | 0.27 ms |
| Tick de UI | 8.9 ms | 2.2 ms |
| Click | 8.4 ms | 0.22 ms |
| Tick lógico | 0.6 ms | 1.2 ms (ahora incluye logros, 5 Hz en vez de 10+) |
| **CPU por segundo de juego** | **~142 ms** | **~29 ms (−80%)** |

Goldens idénticos (el estado de juego no cambió). El simulador corre 31× tiempo real (antes 8×).

### Cómo correr la red

```powershell
.\tools\sim\run_golden.ps1                 # check completo (~7 min)
.\tools\sim\run_golden.ps1 -Suites save    # una suite
.\tools\sim\run_scenarios.ps1              # todos los escenarios del simulador + reportes
```
Los goldens sólo se re-graban (`-Mode record`) cuando el cambio de comportamiento es **intencional**,
y siempre revisando el diff.
