# ROADMAP — IDLE Fungi

Línea evolutiva del proyecto, actualizada contra el estado real del repo.

Este roadmap prioriza dependencias y decisiones de arquitectura. No intenta listar todas las ideas posibles: intenta ordenar qué conviene tocar primero para que el juego siga creciendo sin volver a concentrar todo en `main.gd`.

Última actualización: 2026-05-04

---

## Estado Actual — v0.9.11 "Logros Completos"

*Última actualización: 2026-05-04*

Lo que existe y funciona hoy:

- Motor económico con `EconomyManager.gd` (click, pasivo, trueque, β, μ, κ_eff).
- Modelo estructural con `StructuralModel.gd` — ε, ω, fⁿ, persistence_dynamic.
- Ciclo de run y finales en `RunManager.gd` — homeostasis, allostasis, homeorhesis, perturbaciones, resilience_score.
- Mutaciones y genoma fúngico en `EvoManager.gd` — 10 mutaciones con FSM de 4 estados.
- Biosfera en `BiosphereEngine.gd` — biomasa, hifas, micelio, nutrientes, β.
- UI helpers y builders centralizados en `UIManager.gd`.
- Sistema de logros en `AchievementManager.gd` — **65 logros** en 5 tiers (MICELIO/ESPORA/FRUTO/ANCESTRAL/MYTHIC), panel full-screen con cards estilo Terraria (BBCode tables + bgcolor), MYTHIC visible.
- Banco Genético en `LegacyManager.gd` — 40 buffs, UI full-screen por columnas con ScrollContainer, botón de nivel + toggle.
- Banco Cósmico en `LegacyManager.gd` — 10 upgrades con Esencia (Ξ).
- Save/load JSON via `SaveManager.gd`. Tests: 48 assertions, exit 0.
- Log/export de runs via `LogManager.gd`.
- Red Micelial bifurcada: Colonización / Simbiosis Mecánica.
- Ciclo biológico: Primordio → Seta Formada.
- Trascendencia: reset + Ξ + Banco Cósmico, gate de 3 familias.
- NG+ completo: Depredador de Realidades → Metabolismo Oscuro (ambos con cierres múltiples).
- COLAPSO DEPREDATORIO: cierre alternativo por fractura epistémica (+8 PL), logro Mythic secreto.
- Post-trascendencia: VACÍO HAMBRIENTO + ASCESIS PROFUNDA (sub-ruta), CARNAVAL (Polimorfía + Domador), REENCARNACIÓN HEREDADA.
- Tooltips de indicators del legacy banco con efectos mecánicos concretos (ω_min, multiplicadores).
- Hifas unlock mejorado: timer de 40s sostenido, se resetea entre runs.
- Omega floor robusto: re-aplicado después del paso 8 del logic tick (fix doble cálculo).
- `push_snapshot` incluye: hifas, trascendencia_count. `on_run_closed` incluye: reencarnacion_active.
- Nuevos eventos AchievementManager: `big_click`, `depredador_devour`, `post_tras_route`.
- `main.gd`: ~1760 líneas.

Riesgo actual:

- `update_ui()` sigue acoplada a la escena — no se mueve sin tocar `.tscn`.
- Lab mode disperso — L activa lab mode, pero genoma y eventos están en otros paneles.

---

## v0.9.10 — UX y Debug

Prioridad: MEDIA. **Estado: ✅ COMPLETADO**

Objetivo: mejorar experiencia de jugador en late game y acelerar debugging.

### 1. Banco Genético Rediseñado — COLUMNAS POR CATEGORÍA ✅

Complejidad: Media

**Completado:** UI full-screen con columnas por categoría (economía / estructura / biología / rutas / meta / ng_plus / secreto), ScrollContainer, botón de nivel junto al toggle, offsets 20px todos los lados. Funciona en `MainMenu.tscn` / `MainMenu.gd`.

---

### 2. Panel de Logros Rediseñado ✅

Complejidad: Media

**Completado:**
- Panel full-screen con ScrollContainer (mismo patrón que Banco Genético).
- Título "HISTORIAL DE LOGROS" en dorado.
- Cards estilo Terraria: tabla BBCode 2 columnas (icono del tier escalado | título + descripción), `bgcolor` diferenciado por estado (desbloqueado / bloqueado / secreto).
- MYTHIC tier visible en el panel (faltaba en `tier_order`).
- `vacio_absoluto` eliminado (trigger custom sin evaluador → permanentemente bloqueado).
- **16 logros nuevos** (total: ~65): rutas ALLOSTASIS, HOMEORHESIS, ASCESIS_PROFUNDA, REENCARNACIÓN; bioma despierto; omega inviolable; Depredador Absoluto; Ascensión Total; El Dios de las Moscas; Carnaval / Vacío / Reencarnación iniciados; Primer Click Letal; y más.
- Nuevos eventos: `big_click`, `depredador_devour`, `post_tras_route`.
- `push_snapshot` extendido: `hifas`, `trascendencia_count`.

---

### 3. Lab Mode Expandido — TECLA L ✅

**Completado:** L toggle activa lab stats, muestra `UIManager.genome_scroll` y cambia `LogManager.show_all_laps`. Implementado en `main.gd` `_input()`.

---

### 5. Debug Panel — F1 (Solo Debug Build) ✅

**Completado:** `DebugPanel.gd` instanciado solo si `OS.is_debug_build()`. F1 hace toggle. Panel con recursos, mutaciones, eventos, stats en tiempo real y zona de reset. Sin dependencias de audio.

---

### 6. Fix Performance — EvoManager Update Genome ✅

**Completado:** `_set_genome_state()` ya tiene guarda `if genome[mutation] != new_state` — no emite ni modifica si el estado no cambió.

---

## v0.9.7 — Refactor Final de main.gd

Prioridad: MEDIA. **Estado: ✅ COMPLETADO**

Objetivo: terminar de adelgazar `main.gd`. No inventar managers nuevos — usar los que existen.

- ✅ Shock tracking → RunManager (signal disturbance_triggered)
- ✅ ~19 funciones wrapper/dead eliminadas  
- ✅ Variables muertas limpiadas
- ✅ Export/log helpers → LogManager (-159 líneas)
- ✅ Bifurcation UI logic → UIManager (-72 líneas)
- ✅ Epsilon sticky text → UIManager (-53 líneas)
- ✅ Save/load functions → SaveManager (-173 líneas)
- **Resultado: 2304 → 1729 líneas (-575 líneas, -25%)**
- **✅ Objetivo 1800 alcanzado: 1729 líneas (71 líneas bajo target)**

---

## v0.9.8 — Tests y Build

Prioridad: MEDIA. **Estado: ✅ COMPLETADO**

Objetivo: que el proyecto pueda correr en otro contexto sin romperse.

- [x] Tests básicos para `BiosphereEngine` y `EcoModel` (sin UI, sin escena).
- [x] Tests básicos para `LegacyManager`: get_effect_value, is_revealed, route_gated, acumulación.
- [x] `export_presets.cfg` actualizado — preset `Web` (HTML5) agregado en `[preset.1]`.
- [x] `SaveManager.apply_save_data({})` testeado: sin save previo no crashea.
- [x] `RunSnapshot.gd` como `class_name RunSnapshot extends Resource` con factory `from_run(main)` y `to_dict()`.
- [x] `tests/TestRunner.tscn` ejecutado en Godot: 48 pasados, 0 fallados.
- [x] Fix de export en `LogManager.gd`: `legacy.type` usa `RunManager.final_route` y el CSV exporta filas de laps.
- [x] Fix de logros post-cierre: `AchievementManager` congela tick/eventos cuando `RunManager.run_closed` es true.

---

## v0.9.5 — Missing Endings

Prioridad: BAJA. **Estado: ✅ COMPLETADO**

### Depredador de Realidades *(✅ implementado)*

- Activación implementada.
- ✅ `check_depredador_final()` implementado como cierre "COLAPSO DEPREDATORIO" (+8 PL).

### Metabolismo Oscuro *(✅ implementado)*

- ✅ Rama secreta post-Depredador.
- ✅ 3 cierres (saturación, economía, sellado voluntario).
- ✅ Logros Mythic.

---

## v1.1 — AI Observer

Prioridad: MEDIA/ALTA si el foco es portfolio.

Objetivo: observador inteligente integrado al juego, no dependencia central.

- [ ] `AIObserver.gd` como autoload opcional.
- [ ] Panel con predicción de próxima mutación, ruta dominante y tensión entre rutas.
- [ ] Serializar estado del juego cada 30s.
- [ ] Llamada a API externa (opt-in, no bloquea gameplay).
- [ ] Fallback offline: análisis heurístico local.

---

## v1.2 — Gymnasium Bridge

Prioridad: BAJA — portfolio / investigación RL.

- [ ] `FungiIdleEnv` como wrapper Python de Gymnasium.
- [ ] Simulación paralela del núcleo del juego en Python puro (sin Godot).
- [ ] Observation/action spaces iniciales.
- [ ] Export `state.json` desde Godot por tick para análisis externo.

---

## v1.3 — Visualizer 3D

Prioridad: BAJA — portfolio / visualización.

- [ ] Visor 3D del reactor (Panda3D o similar).
- [ ] Color y escala según `epsilon_runtime` en tiempo real.
- [ ] Red micelial procedural con L-system.
- [ ] Visualización del genoma como grafo 3D.

---

## Deuda Técnica Sin Milestone — ✅ RESUELTA

- [x] `RunSnapshot` como `Resource` tipado de Godot. ✅ v0.9.8
- [x] Tests básicos. ✅ v0.9.8 (48 assertions)
- [x] Actualizar `export_presets.cfg` para build web. ✅ v0.9.8
- [x] Templates de issues. ✅ `.github/ISSUE_TEMPLATE/`

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
| v0.9.5 | Missing Endings | ✅ Completado |
| v0.9.7 | Refactor Final main.gd | ✅ Completado |
| v0.9.8 | Tests y Build | ✅ Completado |
| v0.9.9 | Post-Biológico (Carnaval, Vacío, Reencarnación) | ✅ Completado |
| v0.9.10 | UX y Debug — Banco Genético columnar, Lab Mode, Debug Panel, EvoManager fix | ✅ Completado |
| **v0.9.11** | **Logros Completos — 65 logros, cards Terraria, 16 nuevos, bug fixes** | **✅ Completado** |
| v1.1 | AI Observer | 🔮 Conceptual |
| v1.2 | Gymnasium Bridge | 🔮 Conceptual |
| v1.3 | Visualizer 3D | 🔮 Conceptual |
