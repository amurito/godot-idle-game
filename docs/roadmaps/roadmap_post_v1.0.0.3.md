# Roadmap post-v1.0.0.3

Última actualización: 2026-05-19

---

## v1.0.0.4 — Deuda técnica post-v1 — ✅ PUBLICADO (2026-05-17)

| Feature | Estado |
|---------|--------|
| `save_version` + `_migrate()` unificado en SaveManager | ✅ |
| `Balance.MAX_LAPS = 200` — cap FIFO en LogManager | ✅ |
| `Balance.PL_REWARDS` dict — table de PL por ruta | ✅ |
| `Balance.NG_CAPS` dict — caps NG+ | ✅ |

---

## v1.0.0.5 — Hotfixes A+B+C — ✅ PUBLICADO (2026-05-17)

### Hotfix A — Countdown "Serás consumido"
- `EvoManager.gd`: vars `_depredador_countdown_last` / `_met_oscuro_countdown_last` (int, init -1)
- Solo emite when el segundo cambia (guard `secs_left != _last`) para evitar spam
- Reset a -1 en else branch y en `reset()`
- `UIManager.show_countdown(secs, event)` — wrappea `show_toast`

### Hotfix B — Buff cósmico "Memoria de Recurso Cósmica"
- `LegacyManager.COSMIC_UPGRADES`: nuevo entry `"memoria_recurso_cosmica"` (20Ξ, T2)
- `UpgradeManager.cost()`: retorna 0.0 cuando `state.level <= 1 and has_cosmic_buff("memoria_recurso_cosmica")`

### Hotfix C — Anti-stuck 2 fases
- `TutorialManager`: `ANTISTUCK_THRESHOLD` 90s → 50s, nuevo `ANTISTUCK_PUSH = 60s`
- `_give_idle_push()`: regala `$10 × max(1, get_passive_total())` + hint

---

## v1.0.0.6 — Biosfera Header + UX batch — ✅ PUBLICADO (2026-05-18)

10 commits. Cambios clave:
- Biosfera: hifas/biomasa/nutrientes al header como barras violetas; panel flotante oculto; KEY_B toggle
- Nutrientes → descuento hasta 15% en costo de upgrades
- ε/Ω barras con color dinámico (azul→verde→amarillo→naranja→rojo)
- Tooltips en métricas del header vía `mouse_entered` → dual strategy (tooltip_text + system_message_label)
- Historial bug fix: `LegacyManager.record_run_end()` llamado desde `close_run()`
- HIPERASIMILACIÓN timeout: 180s en `_update_depredador()` para evitar runs sin salida

---

## v1.0.0.7 — Localización EN ~87% — ✅ PUBLICADO (2026-05-18)

Cobertura: tutorial, shortcuts, upgrade buttons (11), mutations (10), paneles upgrade/mut, rutas, lore endings (~110), institution panel, mutation status (~50), lab/formula panel (~120), logros (71 × name+desc+progress), Banco Cósmico, historial, tooltips header, botones in-game.

---

## v1.0.0.8 — Localización EN ~100% player-visible — ✅ PUBLICADO (2026-05-18)

- Genetic Bank (41 items) → `BANK_*` keys
- Log events (75 strings) → `LOG_*` keys
- Formula panel → `LAB_*` keys
- `close_run` reasons, Bank panel title, credits skip button

---

## v1.0.0.9 — Close run reasons + créditos — ✅ PUBLICADO (2026-05-18)

- `close_run` reasons → `tr()` en RunManager
- Genetic Bank title → `tr()`
- Credits: botón skip → traducible

---

## v1.0.0.10 — Panel labels + SINGULARIDAD color — ✅ PUBLICADO (2026-05-18)

- Panel toggle labels (`▼/▶ Economía/Estructura/Genoma`) → `tr()` + refresh en `locale_changed`
- `UpgradeButton.gd`: ya usaba `tr("UPG_"+id)` — confirmado
- Genome text → `tr()` en todas las secciones de `build_genome_text()`
- SINGULARIDAD color en lore end panel: `#00ffff` → `#ffd060` (dorado, distinto de HOMEOSTASIS `#00ccff`)

---

## v1.0.0.11 — Reactor toggle + colores reactor + diálogos i18n — ✅ (2026-05-19)

### Reactor 2D/3D toggle
- `AccessibilityManager`: `reactor_3d_enabled: bool`, `set_reactor_3d()`, save/load
- `AudioManager`: checkbox "Reactor 3D" en sección accesibilidad del Settings panel
- `main.gd`: lee `AccessibilityManager.reactor_3d_enabled` al arrancar; `toggle_reactor_mode(use_3d)`
- `LocaleManager`: clave `SET_REACTOR_3D` ES/EN

### Colores reactor (ReactorVisual 2D)
- HIPERASIMILACIÓN: `Color(1.0, 0.1, 0.6)` magenta → `Color(0.95, 0.05, 0.05)` rojo
- SINGULARIDAD (nucleo_conciencia): nuevo caso → `Color(0.2, 0.5, 1.0)` azul eléctrico

### Diálogos confirmación i18n
- `SaveManager.confirm_and_reset()`: título/texto/botones → `tr()`
- `LocaleManager`: claves `DLG_NEW_RUN_*`, `DLG_RESET_*`, `MM_CANCEL` en ES+EN

---

## Pendiente

### Baja prioridad — Localización
- `LegacyManager.LEGACY_DEFS` — nombres y descripciones del Banco Genético (~30-40 strings) ← user dijo "luego"
- `LegacyManager.CAT_NAMES` — 4 categorías
- `UIManager.build_formula_text()` — ~10-20 strings de power-user content

### v1.1 — AI Observer (próxima versión real)
- `AIObserver.gd` como autoload opcional
- Panel: predicción de próxima mutación, ruta dominante, tensión entre rutas
- Serializar estado cada 30s: `{epsilon, biomasa, delta, genome, run_time, dominant_term}`
- Llamada a API externa opt-in (OpenRouter/Anthropic)
- Fallback offline: análisis heurístico por umbrales
- Ver `roadmap_actual.md § v1.1` para detalle conceptual
