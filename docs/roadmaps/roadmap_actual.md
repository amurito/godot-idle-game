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

### Shock Tracking → RunManager

- [ ] Mover desde `main.gd` hacia `RunManager.gd`:
  - Detección de shock extremo
  - Recovery al volver a banda homeostática
  - Incremento de `disturbances_survived`
  - Logs relacionados con perturbaciones
- [ ] Agregar señal `disturbance_triggered(shock: bool, is_extreme: bool)` para desacoplar UI/logros.
- [ ] Confirmar que `StructuralModel` no absorbe lógica de run.

### Limpieza deuda

- [ ] Revisar duplicados históricos en `main.gd`:
  - Variables de mutación obsoletas
  - Funciones comentadas o wrappers muertos
  - Cualquier referencia directa a `unlocked_legacies` que haya sobrevivido
- [ ] Objetivo: bajar `main.gd` por debajo de 1800 líneas.
- [ ] Objetivo de mediano plazo: `main.gd` como orquestador de escena, no contenedor de sistemas.
- [ ] No mover `update_ui()` todavía — demasiado acoplado a la escena.

---

## v0.9.8 — Tests y Build

Prioridad: MEDIA.

Objetivo: que el proyecto pueda correr en otro contexto sin romperse.

- [ ] Tests básicos para `BiosphereEngine` y `EcoModel` (sin UI, sin escena).
- [ ] Tests básicos para `LegacyManager`: migración de saves, get_effect_value, is_revealed.
- [ ] Actualizar `export_presets.cfg` para build web (HTML5).
- [ ] Verificar que el juego carga sin save previo sin errores.
- [ ] `RunSnapshot` como estructura dedicada para historial de runs tipado.

---

## v0.9.5 — Missing Endings *(parcialmente pendiente)*

Prioridad: BAJA — algunos ya implementados, otros descartados.

### Depredador de Realidades *(descartado por ahora)*

- Activación implementada. Cierre de run descartado por decisión de diseño.
- Si se retoma: `check_depredador_final()` en `RunManager`, condición ε > 1.0 + biomasa > 25 + money < 500.

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

## Deuda Técnica Sin Milestone

- [ ] `RunSnapshot` como `Resource` tipado de Godot.
- [ ] Tests básicos para `BiosphereEngine`, `EcoModel`, `LegacyManager`, `AchievementManager`.
- [ ] Actualizar `export_presets.cfg` para build web (HTML5).
- [ ] Agregar templates de issues si el repo va a compartirse.
- [ ] Revisar `openrouter_payload.json` y `openrouter_response.json` — limpiar del root si no son necesarios.

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
| v0.9.7 | Refactor Final main.gd | 🔄 En curso |
| v0.9.8 | Tests y Build | 📋 Próximo |
| v0.9.5 | Missing Endings | 🔄 Parcial |
| v1.0 | Prestige Expandido | 🔄 Parcial |
| v1.1 | AI Observer | 🔮 Conceptual |
| v1.2 | Gymnasium Bridge | 🔮 Conceptual |
| v1.3 | Visualizer 3D | 🔮 Conceptual |
