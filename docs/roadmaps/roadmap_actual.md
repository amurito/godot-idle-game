# ROADMAP — IDLE Fungi

Línea evolutiva del proyecto, actualizada contra el estado real del repo.

Este roadmap prioriza dependencias y decisiones de arquitectura. No intenta listar todas las ideas posibles: intenta ordenar qué conviene tocar primero para que el juego siga creciendo sin volver a concentrar todo en `main.gd`.

Última actualización: 2026-04-24

---

## Estado Actual — v0.9.6 "Observatorio Vivo"

Lo que existe y funciona hoy:

- Motor económico con `EconomyManager.gd` (click, pasivo, trueque, β, μ, κ_eff).
- Modelo estructural con `StructuralModel.gd` — ε, ω, fⁿ, persistence_dynamic.
- Ciclo de run y finales en `RunManager.gd` — homeostasis, allostasis, homeorhesis, perturbaciones, resilience_score.
- Mutaciones y genoma fúngico en `EvoManager.gd` — 9 mutaciones con FSM de 4 estados.
- Biosfera en `BiosphereEngine.gd` — biomasa, hifas, micelio, nutrientes, β.
- UI helpers y builders centralizados en `UIManager.gd` — build_genome_text, build_mutation_status_text, build_institution_panel_text, build_formula_text, build_evo_checklist, build_marginal_contribution.
- Sistema de logros en `AchievementManager.gd` — 50 logros, tiers, push_snapshot/push_event, CUSTOM_EVALUATORS, badge NUEVO, toast por tier, progress tracking.
- Banco Genético en `LegacyManager.gd` — 40 buffs con LEGACY_DEFS, reveal/unlock separados, multi-level, route-gated, grant_buff para NG+.
- Banco Cósmico en `LegacyManager.gd` — 10 upgrades con Esencia (Ξ), 3 capas de tiempo (run / Genético / Cósmico).
- Save/load JSON via `SaveManager.gd`.
- Log/export de runs via `LogManager.gd`.
- Red Micelial bifurcada: Colonización / Simbiosis Mecánica.
- Ciclo biológico: Primordio → Seta Formada.
- Trascendencia implementada: reset + Ξ gain + Banco Cósmico, gate de 3 familias.
- Singularidad implementada como cierre de run.
- Repo organizado: `/docs`, `/docs/changelogs`, `/docs/roadmaps`.

Riesgo actual:

- `main.gd` sigue siendo ~2250 líneas — mezcla glue code de escena, save/load, algunos chequeos de run y UI update.
- El tracking de shocks extremos todavía tiene bordes en `main.gd` que deberían vivir en `RunManager`.
- `update_ui()` toca demasiados nodos directamente — difícil de extraer sin mover la escena.

---

## v0.9.7 — Refactor Final de main.gd

Prioridad: MEDIA.

Objetivo: terminar de adelgazar `main.gd`. No inventar managers nuevos — usar los que existen.

**Estado: ✅ COMPLETADO**
- ✅ Shock tracking → RunManager (signal disturbance_triggered)
- ✅ ~19 funciones wrapper/dead eliminadas  
- ✅ Variables muertas limpiadas
- ✅ Export/log helpers → LogManager (-159 líneas)
- ✅ Bifurcation UI logic → UIManager (-72 líneas)
- ✅ Epsilon sticky text → UIManager (-53 líneas)
- ✅ Save/load functions → SaveManager (-173 líneas)
- **Resultado: 2304 → 1729 líneas (-575 líneas, -25%)**
- **✅ Objetivo 1800 alcanzado: 1729 líneas (71 líneas bajo target)**

### Shock Tracking → RunManager

- [x] Mover desde `main.gd` hacia `RunManager.gd`:
  - Detección de shock extremo (`epsilon_runtime > 0.8 → extreme_shock_survived`)
  - Recovery al volver a banda homeostática
  - Incremento de `disturbances_survived`
  - Logs relacionados con perturbaciones
- [x] Agregar señal `disturbance_triggered(shock: float, is_extreme: bool)` para desacoplar UI/logros.
- [x] Confirmar que `StructuralModel` no absorbe lógica de run.

### Limpieza deuda

- [x] Revisar duplicados históricos en `main.gd`:
  - Variables muertas (`pressure`, `pressure_structural`, `mu_structural`) eliminadas
  - ~19 funciones wrapper/dead eliminadas (RunManager delegations, StructuralModel wrappers, `debug_print_epsilon`, `get_flexibility`)
  - Sin referencias a `unlocked_legacies` — eliminadas en v0.9.2
- [x] Objetivo: bajar `main.gd` por debajo de 1800 líneas *(resultado: 1729, era 2304 antes de v0.9.7)*
- [x] Objetivo de mediano plazo: `main.gd` como orquestador de escena, no contenedor de sistemas.
- [ ] No mover `update_ui()` todavía — demasiado acoplado a la escena.

### Extracción completada: Export/Log Helpers → LogManager

- [x] Movidas funciones de export desde `main.gd` → `LogManager.gd`:
  - `build_run_snapshot()` ✅
  - `_get_timestamp_meta()` ✅
  - `_build_run_json()` ✅ (consolidado con versión LogManager)
  - `_build_run_csv()` ✅
  - `_build_clipboard_text()` ✅
  - `ensure_export_dir()` ✅
  - `get_build_string()` ✅
- [x] LogManager se mantuvo como único punto de exportación
- [x] **Resultado: -159 líneas en main.gd (2186 → 2027)**

### Extracción completada: Epsilon Sticky Text → UIManager

- [x] `update_epsilon_sticky()` → `UIManager.build_epsilon_sticky_text(main: Control)` ✅
- [x] Encapsuló lógica de construcción de epsilon_runtime display con omega/pressure
- [x] Incluye secciones condicionales para DEPREDADOR y MET.OSCURO con progress bars
- [x] **Resultado: -53 líneas en main.gd (1955 → 1902)**

### Extracción completada: Save/Load Functions → SaveManager

- [x] `get_save_data()` → `SaveManager.build_save_data(main: Node)` ✅
- [x] `_apply_save_data(data: Dictionary)` → `SaveManager.apply_save_data(main: Node, data: Dictionary)` ✅
- [x] SaveManager.save_game() y load_game() ahora llaman directamente a las funciones movidas
- [x] Mantiene backward compatibility: SaveManager maneja toda la persistencia
- [x] **Resultado: -173 líneas en main.gd (1902 → 1729)**

---

## v0.9.8 — Tests y Build

Prioridad: MEDIA.  **Estado: ✅ COMPLETADO**

Objetivo: que el proyecto pueda correr en otro contexto sin romperse.

- [x] Tests básicos para `BiosphereEngine` y `EcoModel` (sin UI, sin escena).
- [x] Tests básicos para `LegacyManager`: get_effect_value, is_revealed, route_gated, acumulación.
- [x] `export_presets.cfg` actualizado — preset `Web` (HTML5) agregado en `[preset.1]`.
- [x] `SaveManager.apply_save_data({})` testeado: sin save previo no crashea.
- [x] `RunSnapshot.gd` como `class_name RunSnapshot extends Resource` con factory `from_run(main)` y `to_dict()`.
- [x] `tests/TestRunner.tscn` ejecutado en Godot: 48 pasados, 0 fallados.
- [x] Fix de export en `LogManager.gd`: `legacy.type` usa `RunManager.final_route` y el CSV exporta filas de laps.
- [x] Fix de logros post-cierre: `AchievementManager` congela tick/eventos no `run_closed` cuando `RunManager.run_closed` es true.
- [x] Validar una export nueva post-fix: run_25-04-2026_01-22 — `legacy.type == "HOMEOSTASIS"` ✓, CSV 48 filas ✓.

### Detalles de implementación

- **`tests/TestRunner.gd`** — runner mínimo sin plugins (no GUT): 4 suites, 48 assertions.
  - Snapshots de estado antes de cada suite, restauración al salir.
  - Props mock en TestRunner para SaveManager (`memory_trigger_count`, `run_time`, `institutions_unlocked`, `update_ui()`).
  - Salida por consola; exit code 0/1 para CI futuro.
- **`tests/TestRunner.tscn`** — escena mínima para correr en editor (Project → Run Specific Scene).
- **`RunSnapshot.gd`** — Resource tipado con `@export` fields; factory `from_run(main)` lee autoloads directamente; `to_dict()` genera Dictionary compatible con LogManager.
- **`export_presets.cfg`** — preset `[preset.1]` Web con canvas_resize_policy=2, sin PWA, builds en `builds/web/index.html`.

### Cómo correr los tests

```
Project → Run a Specific Scene → tests/TestRunner.tscn
```
Output en la consola de Godot. Si todos pasan: exit 0.

---

## v0.9.5 — Missing Endings *(parcialmente pendiente)*

Prioridad: BAJA — algunos ya implementados, otros descartados.

### Depredador de Realidades *(✅ implementado)*

- Activación implementada.
- ✅ `check_depredador_final()` implementado como cierre "COLAPSO DEPREDATORIO" (+8 PL):
  - condición: devoured_count ≥ 1 + ε > 1.0 + biomasa > 25 + money < 500
  - achievement secreto Mythic: "Fractura Epistémica"
  - sin conflicto con Met.Oscuro (el bloque elif es exclusivo)

### Metabolismo Oscuro *(pendiente)*

- [ ] Definir como rama secreta post-Depredador.
- [ ] Condición tentativa: `parasitism_corrosion > 0.7`, ε en banda media, run ≥ 40 min.
- [ ] Requiere haber cerrado PARASITISMO y HOMEOSTASIS en runs anteriores.
- [ ] Evitar que sea solo "Parasitismo más fuerte" — debe tener identidad propia.

---

## v1.0 — Prestige Expandido *(parcialmente implementado)*

Prioridad: BAJA.

Lo que ya existe:

- ✅ Trascendencia: reset + cálculo Ξ + Banco Cósmico.
- ✅ Gate de 3 familias (orden / biología / colapso).
- ✅ Títulos cósmicos según cantidad de trascendencias.

Lo que falta:

- [ ] Modo Trascendencia como run especial, no como reseteo.
  - Todas las mutaciones empiezan latentes simultáneamente.
  - ε como combustible en vez de estrés.
  - Objetivo: `persistence_dynamic > persistence_base × 100`.
- [ ] Requisitos gate más exigentes: HOMEORHESIS + SINGULARIDAD + DEPREDADOR + (ESPORULACIÓN o MET.OSCURO).
- [ ] Cierre automático cuando el modelo colapsa hacia arriba.

---

## v1.1 — AI Observer

Prioridad: MEDIA/ALTA si el foco es portfolio.

Objetivo: observador inteligente integrado al juego, no dependencia central.

Encaja con el tema "Observatorio fⁿ" del proyecto.

- [ ] `AIObserver.gd` como autoload opcional.
- [ ] Panel con predicción de próxima mutación, ruta dominante y tensión entre rutas.
- [ ] Serializar estado del juego cada 30s como `{epsilon, biomasa, delta, genome, run_time, dominant_term}`.
- [ ] Llamada a API externa (opt-in, no bloquea gameplay).
- [ ] Fallback offline: análisis heurístico local basado en umbrales.
- [ ] Cache de último análisis (`last_analysis: Dictionary`).

---

## v1.2 — Gymnasium Bridge

Prioridad: BAJA — portfolio / investigación RL.

- [ ] `FungiIdleEnv` como wrapper Python de Gymnasium.
- [ ] Simulación paralela del núcleo del juego en Python puro (sin Godot).
- [ ] Observation space: `[epsilon, biomasa, hifas, micelio, delta_norm, run_time_norm, genome_phase]`.
- [ ] Action space inicial: `idle, click, buy_cheapest, activate_homeo, activate_red, activate_simb`.
- [ ] Reward experimental: producción, estabilidad y bonus por rutas.
- [ ] Export `state.json` desde Godot por tick para análisis externo.

---

## v1.3 — Visualizer 3D

Prioridad: BAJA — portfolio / visualización.

- [ ] Visor 3D del reactor (Panda3D o similar).
- [ ] Color y escala según `epsilon_runtime` en tiempo real.
- [ ] Red micelial procedural con L-system o random walk.
- [ ] Sincronización via `state.json` escrito por Godot cada tick.
- [ ] Visualización del genoma como grafo 3D.

---

## Deuda Técnica Sin Milestone — ✅ RESUELTA

- [x] `RunSnapshot` como `Resource` tipado de Godot. ✅ v0.9.8
- [x] Tests básicos para `BiosphereEngine`, `EcoModel`, `LegacyManager`, `SaveManager`. ✅ v0.9.8 (48 assertions)
- [x] Actualizar `export_presets.cfg` para build web (HTML5). ✅ v0.9.8
- [x] Agregar templates de issues si el repo va a compartirse. ✅ `.github/ISSUE_TEMPLATE/bug_report.md`, `feature_request.md`, `config.yml` + `CONTRIBUTING.md`
- [x] `openrouter_payload.json` y `openrouter_response.json` — no necesarios, no presentes. ✅ (legacy, nunca tracked)

---

## Referencia Rápida

| Versión | Nombre | Estado |
|---|---|---|
| v0.5.x | The Lab | ✅ Archivada |
| v0.6.x | Observatorio fⁿ | ✅ Archivada |
| v0.7.x | Métricas Estructurales | ✅ Archivada |
| v0.8.x | Fungi Evolution | ✅ Base estable |
| v0.9.1 | Achievement System Rework | ✅ Completado |
| v0.9.2 | Genetic Bank Rework | ✅ Completado |
| v0.9.6 | Observatorio Vivo | ✅ **Versión actual** |
| v0.9.7 | Refactor Final main.gd | ✅ Completado |
| v0.9.8 | Tests y Build | ✅ Completado |
| v0.9.5 | Missing Endings | 🔄 Parcial |
| v1.0 | Prestige Expandido | 🔄 Parcial |
| v1.1 | AI Observer | 🔮 Conceptual |
| v1.2 | Gymnasium Bridge | 🔮 Conceptual |
| v1.3 | Visualizer 3D | 🔮 Conceptual |

