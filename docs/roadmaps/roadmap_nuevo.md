# ROADMAP — IDLE Fungi

Línea evolutiva del proyecto, actualizada contra el estado real del repo.

Este roadmap prioriza dependencias y decisiones de arquitectura. No intenta listar todas las ideas posibles: intenta ordenar qué conviene tocar primero para que el juego siga creciendo sin volver a concentrar todo en `main.gd`.

Última actualización: 2026-05-02

---

## Estado Actual — v0.9.9 "Post-Biológico"

*Última actualización: 2026-05-02*

Lo que existe y funciona hoy:

- Motor económico con `EconomyManager.gd` (click, pasivo, trueque, β, μ, κ_eff).
- Modelo estructural con `StructuralModel.gd` — ε, ω, fⁿ, persistence_dynamic.
- Ciclo de run y finales en `RunManager.gd` — homeostasis, allostasis, homeorhesis, perturbaciones, resilience_score.
- Mutaciones y genoma fúngico en `EvoManager.gd` — 10 mutaciones con FSM de 4 estados (refactorizado a sub-funciones).
- Biosfera en `BiosphereEngine.gd` — biomasa, hifas, micelio, nutrientes, β.
- UI helpers y builders centralizados en `UIManager.gd`.
- Sistema de logros en `AchievementManager.gd` — 50+ logros, tiers Mythic/Ancestral/Rare/Common, custom evaluators.
- Banco Genético en `LegacyManager.gd` — 40 buffs (UI atual: scrolleable, sin categorizar).
- Banco Cósmico en `LegacyManager.gd` — 10 upgrades con Esencia (Ξ).
- Save/load JSON via `SaveManager.gd`. Tests: 48 assertions, exit 0.
- Log/export de runs via `LogManager.gd`.
- Red Micelial bifurcada: Colonización / Simbiosis Mecánica.
- Ciclo biológico: Primordio → Seta Formada.
- Trascendencia: reset + Ξ + Banco Cósmico, gate de 3 familias.
- NG+ completo: Depredador de Realidades → Metabolismo Oscuro (ambos con cierres múltiples).
- Depredador accesible en Tier I con trascendencia_count > 1.
- Metabolismo Oscuro: sellado escalonado por PL, barra de progreso, Ω forzado 0.10, logros Mythic.
- COLAPSO DEPREDATORIO: cierre alternativo por fractura epistémica (+8 PL), logro Mythic secreto.
- Post-trascendencia: VACÍO HAMBRIENTO + ASCESIS PROFUNDA (sub-ruta), CARNAVAL (Polimorfía + Domador), REENCARNACIÓN HEREDADA.
- `main.gd`: 1750 líneas aprox (era 2304 pre-refactor).

Riesgo actual:

- `update_ui()` sigue acoplada a la escena — no se mueve sin tocar `.tscn`.
- Banco Genético sin organización visual — 40 buffs sin categorizar hacen el late game tedioso.
- Lab mode disperso — L activa lab mode, pero genoma y eventos están en otros paneles.

---

## v0.9.10 — UX y Debug

Prioridad: MEDIA. **Estado: 🔄 EN DESARROLLO**

Objetivo: mejorar experiencia de jugador en late game y acelerar debugging.

### 1. Banco Genético Rediseñado — COLUMNAS POR CATEGORÍA

Complejidad: Media | Estimado: 1-2 sesiones

**Problema actual:** 40 buffs en un solo scrolleable sin contexto. Difícil navegar.

**Solución:** Dividir en 5 columnas como el Banco Cósmico:
- **Economía** (multiplicadores de dinero, costos, trueque)
- **Estructura** (ε, ω, fⁿ, persistencia)
- **Biología** (biomasa, hifas, micelio, nutrientes)
- **Rutas** (buffs específicos de mutaciones/rutas)
- **Meta** (PL, ciclos, essence, reset bonuses)

**Tareas:**
- [ ] Leer `LegacyManager.gd` y categorizar los 40 buffs existentes
- [ ] Crear nuevo layout en `UIManager` o en el panel del Banco Genético (opción: panel nuevo o refactor existente)
- [ ] Mantener la lógica de reveal/lock, solo cambiar presentación visual
- [ ] Probar affordability y tooltips en todas las categorías

**Dependencias:** ninguna (puramente visual)

---

### 2. Lab Mode Expandido — TECLA L = TODO

Complejidad: Baja | Estimado: 30 minutos

**Problema actual:** Lab mode (L) solo activa lab stats; genoma y eventos están en otros paneles. Speedrunners tienen que hacer 3 clicks.

**Solución:** Una sola tecla L que:
- Activa lab mode stats (ya existe)
- Muestra genoma completo (expande EvoManager.genome o crea sección flotante)
- Muestra todos los eventos del LogManager (sin scroll, densa)
- Opcionalmente: agranda fonts de stats clave para lectura rápida

**Tareas:**
- [ ] Modificar Input._input() en `main.gd` para capturar L
- [ ] Si no está en lab mode: activar + mostrar genoma + eventos
- [ ] Si está en lab mode: desactivar todo y volver a normal
- [ ] Considerar: guardar estado de "lab_expanded" en SaveManager si queremos persistir

**Dependencias:** ninguna (puramente UI)

---

### 3. Debug Panel — F1 (Solo Debug Build)

Complejidad: Media | Estimado: 1 sesión

**Problema actual:** Testing de mutaciones/eventos requiere jugar full runs. Lento.

**Solución:** Panel flotante que solo aparece en `OS.is_debug_build()`. Acceso con F1.

**Secciones:**
- Recursos: setear dinero, biomasa, hifas, micelio, ε
- Mutaciones: botones para activar cualquiera instantáneamente
- Eventos: forzar perturbaciones, primordio, seta, cierre de run
- Información: display en tiempo real de todas las variables clave
- Zona peligrosa: reset de run o wipe total

**Tareas:**
- [ ] Crear `DebugPanel.gd` (basado en el código de Sugerencias.md pero **sin `AudioStreamSample`**)
- [ ] Instanciar en `main.gd` solo si `OS.is_debug_build()`
- [ ] Hotkey F1 para toggle
- [ ] Botón flotante "🐛 DEBUG" en esquina inferior derecha

**Notas:**
- El código de Sugerencias.md usa `AudioStreamSample` que fue removido en Godot 4. Saltamos eso.
- El panel de debug no toca audio.

**Dependencias:** ninguna (opcional, solo develop)

---

### 4. Fix Performance — EvoManager Update Genome

Complejidad: Baja | Estimado: 10 minutos

**Problema actual:** `_set_genome_state()` emite `mutation_unlocked` cada vez que se llama, incluso si el estado no cambió.

**Solución:** Comparar estado previo antes de emitir.

```gdscript
func _set_genome_state(mutation: String, new_state: String):
    var old_state = genome.get(mutation, "dormido")
    if old_state == new_state:
        return  # Sin cambio, no emitir
    genome[mutation] = new_state
    if new_state == "latente":
        mutation_unlocked.emit(mutation)
```

**Tareas:**
- [ ] Buscar `_set_genome_state` en `EvoManager.gd`
- [ ] Aplicar el fix
- [ ] Verificar que no rompe ningun test

**Dependencias:** ninguna

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
| **v0.9.10** | **UX y Debug (Banco GenĂ©tico, Lab Mode, Debug Panel)** | **🔄 EN DESARROLLO** |
| v1.1 | AI Observer | 🔮 Conceptual |
| v1.2 | Gymnasium Bridge | 🔮 Conceptual |
| v1.3 | Visualizer 3D | 🔮 Conceptual |
