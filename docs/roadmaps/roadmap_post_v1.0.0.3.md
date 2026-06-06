# Roadmap post-v1.0.0.3

Última actualización: 2026-06-05

**Estado actual:** `v1.0.1.0 "génesis"` (`version.gd` PATCH=1, HOTFIX=0 → muestra `1.0.1`) — **rama verde (Red Micelial) reworkeada anti-AFK**. Antes: `v1.0.0.10` — el juego es **HYPHAE: genesis** (ex-AntiIDLE), publicado en web en `hyphae-game-hub.onrender.com`, bilingüe ES/EN, export web (HTML5) + `.exe` Windows.

**Nota de versionado:** la numeración pública saltó a `.10` porque las tags `.7/.8/.9` ya existían en remote apuntando a commits previos de i18n (sin bump de `version.gd`, el juego mostraba `1.0.0.6`). Todo el sprint quedó consolidado en `v1.0.0.10 "génesis"`; los parches post-release (gameplay, balance, bugs) van sobre la misma versión sin re-bump. El detalle granular vive en `CHANGELOG.md`.

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

## v1.0.0.10 "génesis" — Consolidación + post-release — ✅ PUBLICADO (2026-05-25 → 05-30)

Release pública de cierre del sprint. Detalle granular en `CHANGELOG.md`.

### Rebranding
- Rename **AntiIDLE → HYPHAE: genesis** (código, window title, créditos, tutorial, export `product_name`/`og:title`, README, hosting URL `hyphae-game-hub.onrender.com`)

### Web export estable
- Audio HTML5 funcional en Chrome: `default_bus_layout.tres` estático + `default_playback_type.web=Stream`
- `fix_web_export.ps1/.bat`: patch post-export (canvasResizePolicy, audio unlock)
- `stretch_mode=canvas_items + aspect=expand`; `thread_support=false`; `exclude_filter` DebugPanel/tests

### Emojis Twemoji — cobertura web completa
- `EmojiToRichText`: `rich()` / `strip()` / `set_icon_texture()` + 55 PNGs locales en `res://emoji/`
- Auditoría sistemática (script Python) → **0 issues UI restantes**

### UI — pulido header + pantalla central
- Botones compactos (~120px verticales ahorrados); chip Ω con 1 sola flecha; fórmula Λ forzada a 1 línea
- Mensaje post-primera-trascendencia mejorado (ES+EN) — momento de retención #1

### Achievements rebalance + save import (commit `9a4f957`)
- `import_save_json`: FileDialog nativo en desktop; rebalance del catálogo; fix `close_run` HIPERASIMILACIÓN

### Post-release gameplay (2026-05-30)
- **Rama Depredador**: botón ESTABILIZAR (paga biomasa, resta timer), hitos de devorado `[30,50,70,90]` (−10s c/u), tick acelera 1.5→1.2s, COLAPSO DEPREDATORIO reactor rojo-negro, MET.OSCURO seal req dev≥10/bio≥50
- **COLAPSO CONTROLADO + Entropía Domesticada**: buff exclusivo (×2.0) que invierte la penalización de zona roja (ε>0.65 escala producción); expuesto en lab mode + fórmula Λ
- **ASCESIS PROFUNDA** rework anti-AFK: gate 900→300s, meta $1M→$10M (solo click), timer pausa si no clickeás hace >10s
- **Logros — fix conteo + inalcanzables**: `unlocked_count()` filtra IDs huérfanos; "La Run Imposible" → `mutations_this_run>=3`; "Saturación Total" chequea estado real; "Pico Met.Oscuro" rebalanceado a Δ$≥50K/s instantáneo; contador de mutaciones cuenta Depredador/Met.Oscuro
- **UI rutas post-trascendencia**: ocultar "Próxima transición" en Vacío/Carnaval/Reencarnación
- **Auditoría bugs**: P0 tip anti-stuck no se cerraba, P1 ESTABILIZAR colgado tras sellar MET.OSCURO, P2 timer Depredador no persistía (save-scum)

---

## v1.0.1.0 "génesis" — Rework RAMA VERDE (Red Micelial) — ✅ (2026-06-05)

Las 5 salidas de la rama verde (Colonización · Seta/Esporulación · Panspermia · Singularidad · Mente Colmena) eran AFK ("sostener una postura pasiva durante T s"). Reworkeadas a **gates activos con identidad propia**. Diseño completo en [`rework_rama_verde.md`](../design/rework_rama_verde.md); constantes tuneables en `Balance.gd`. Commit `9ef0a6e`.

- **Colonización — Empuje de Frontera**: el micelio ya no se llena solo (decae); se empuja clickeando + botón Expandir Micelio, contra retracciones escalantes. Tendrils del reactor crecen con el micelio.
- **Seta/Primordio — Maduración activa**: regar (gasta biomasa **finita** — no regenera en primordio) contra contaminaciones escalantes; sin regar, la integridad colapsa.
- **Panspermia — Lanzamiento carga vs calor**: dos presiones opuestas; misfire al sobrecalentar; **5 sobrecargas abortan a esporulación base**.
- **Singularidad — Sincronización**: gate de **4 condiciones de fase simultáneas** (acc≥3, Ω≥0.55, ε∈[0.10–0.22], biomasa≥6) sostenidas; no es minijuego de botón.
- **Mente Colmena — auto-play acotado**: **ráfaga activable** (Override IA, 18s on / 45s cooldown) en vez de permanente; pasivo ×3 queda; gate endurecido a 100s multi-condición.
- Consistencia lore/log de efectos y PL; fixes de UI (botones de final colgados al cerrar, clicks auto-cancelados por toggle de `disabled`).

---

## Pendiente

### 🚀 LANZAMIENTO — próximo paso real
El *pulido de código* pre-launch está hecho. Falta la **ejecución de marketing/comunidad** (ver plan completo en memoria `launch_plan_hyphae_genesis.md`):
- **Pre-launch:** smoke test end-to-end + test caché limpia/incógnito; assets (cover 630×500, 6 screenshots, GIF principal <5MB, logo PNG)
- **Día 0:** publicar página itch.io (descripción ES/EN ya redactada en el plan); post r/incremental_games + cross-post r/godot; probar embed Chrome/Firefox/Edge
- **Semana 1:** recolectar bugs/fricción → hotfix consolidado (no en caliente); DMs a 3-5 youtubers de idle

### Baja prioridad — Localización
- `LegacyManager.LEGACY_DEFS` — nombres y descripciones del Banco Genético (~30-40 strings) ← user dijo "luego"
- `LegacyManager.CAT_NAMES` — 4 categorías
- `UIManager.build_formula_text()` — ~10-20 strings de power-user content

### v1.1 — próxima versión real (post-launch)
- **AI Observer** (`AIObserver.gd` autoload opcional): predicción de próxima mutación, ruta dominante, tensión entre rutas; serializar estado cada 30s; API externa opt-in (OpenRouter/Anthropic) + fallback heurístico offline. Detalle en `roadmap_actual.md § v1.1`
- **Mobile** (responsive / touch)
- **Auditoría de retención**: cada milestone (primera mutación, primera ruta post-trascendencia, Dark Metabolism) necesita mensaje "felicitación + explicación + qué sigue" — ver `launch_plan_hyphae_genesis.md § Retención`

### Futuro — endgame post-trascendencia t>2 (diseño, no implementado)
- **Refactor `RouteManager`** (registry único, data-driven) para escalar más allá de las 3 rutas básicas. Plan completo en [`docs/design/arquitectura_rutas.md`](../design/arquitectura_rutas.md).
- **Transmutaciones** (reversión de mutaciones → rutas OP), **rutas avanzadas/fantasma** y **meta-endgame "Jardín Primigenio"** (subjuego paralelo). Diseño en [`docs/design/nuevas transmutaciones.md`](../design/nuevas%20transmutaciones.md).
