# CHANGELOG — AntiIDLE

## [v1.0.0.12] — Hotfix — 2026-05-25

#### Banco Genético — íconos rotos en web (RESUELTO)
Tras una segunda auditoría visual quedaron 5 labels asignando texto crudo a `Label.text` sin pasar por `EmojiToRichText.strip()` en web:
- `MainMenu.gd:759` `name_lbl` — `★ NUEVO` (badge de buff recién desbloqueado)
- `MainMenu.gd:813` `wip_lbl` — `◈ Próximamente...` (BANK_WIP_NOTICE)
- `MainMenu.gd:1245` `counter` — `Ξ Disponible · Trascendencias` (Banco Cósmico)
- `MainMenu.gd:1307` `placeholder` — `◈ Próximamente...` (COSMIC_COMING_SOON)
- `AchievementManager.gd:1110` `header_lbl` — `★ LOGRO LEGENDARIO` (toast popup)
- `AchievementManager.gd:1116,1123` `name_lbl`/`desc_lbl` — strip defensivo (logros tipo "Δ$ ≥ 100/s")

Todos envueltos con `EmojiToRichText.strip(...)`.

---

## [v1.0.0.11] — Hotfix — 2026-05-25

#### Header chip 🧠 roto en web (RESUELTO)
- Chip "IA" (Mente Colmena) mostraba el emoji 🧠 como cuadrado roto en la build web.
- Causa: el lambda `_add_chip` en `main.gd` no aplicaba `EmojiToRichText.strip()` al texto antes de asignarlo al `Label` — el fix estaba en el commit de auditoría (43de923) pero no había sido re-exportado.
- Fix ya aplicado en código; esta versión fuerza re-export con todos los fixes de auditoría incluidos.

---

## [v1.0.0.10] — Hotfix — 2026-05-24

Bundle de fixes de export web + UI compacta.
Nota: se salta a `.10` porque las tags `.7/.8/.9` ya existen en remote apuntando a commits de i18n previos (sin bump de `version.gd` en su momento, por lo que el juego seguía mostrando `1.0.0.6`).

#### Audio web (RESUELTO)
- Audio HTML5 finalmente suena en Chrome. Causa raíz: crear buses con `AudioServer.add_bus()` en runtime no ruteaba al Master en web.
- Nuevo `default_bus_layout.tres` con Master + Music + SFX estáticos, referenciado desde `[audio] buses/default_bus_layout` en `project.godot`.
- `[audio] general/default_playback_type.web=1` (Stream en lugar de Sample): el Sample tenía bugs cuando los buses no estaban registrados al cargarse los streams.
- `AudioManager._setup_buses()` simplificado: solo cachea índices con fallback defensivo a Master + `push_warning`.

#### Export web — bundle previo
- `fix_web_export.bat` + `fix_web_export.ps1`: patcheo post-export del `index.html` (canvasResizePolicy 0→2, inyección JS de audio unlock interceptando `AudioContext` en `<head>`).
- `[display] stretch_mode=canvas_items + aspect=expand`: sin barras negras, clicks alineados con CSS scaling.
- `variant/thread_support=false` en preset HTML5: no requiere COOP/COEP del servidor.
- `exclude_filter` en preset HTML5: `DebugPanel.gd,tests/*` para reducir bundle.

#### UI — botones compactos
- `ProductionPanel` (upgrades): altura mínima 280→150, `v_separation` 8→4, `h_separation` 8→6.
- `UpgradeButton`: altura mínima 56→36, `content_margin` 4→2 en los StyleBox, `font_size` override `AccessibilityManager.fs(11)`.
- Ahorro neto: ~120-130px verticales en el centro de la pantalla. El texto de 2 líneas (label + costo) sigue entrando.

#### Emojis Twemoji en web
- **SELLAR FINAL 🧬**: ahora usa `Button.icon = load("res://emoji/1f9ec.png")` en lugar de char emoji en `text`. Renderiza universal sin depender de la fuente del browser.
- **Iconos de mutación tier1/tier2**: nodos `Icon` (antes Label vacío) ahora son `TextureRect`. Nuevo helper `EmojiToRichText.set_icon_texture(rect, emoji)` carga el PNG por código. Asignados según tier: ⚖️ Homeostasis · 🕸️ Red Micelial · 🤝 Simbiosis · ⚖️ Allostasis · 🌱 Colonización · 🤝 Simbiosis Mecánica.
- `Desc` text de cada opción ahora pasa por `EmojiToRichText.rich()` para convertir emojis inline en `[img]` BBCode.
- `EMOJI_TO_FILE`: agregadas variantes "bare" (sin FE0F invisible) de ⚠ ☠ ☣ ⚖ 🕸 🕳 ⚱ 🏛 🌪 🏗 — antes solo matcheaban las versiones con FE0F y los strings del LocaleManager venían sin él.

#### Otros
- Renames i18n: Barter → Exchange en strings de tutorial.
- Anti-stuck dismiss on scene exit (TutorialManager).
- `ReactorVisual.set_display_delta`: muestra entero en lugar de decimal.
- `AccessibilityManager.reactor_3d_enabled = false` por default (2D primero).
- `RunSnapshot`: run_id con formato `run_DD-MM-YY_HH-MM`.

---

## [v1.0.0] — "Génesis" — 2026-05-15

Primera versión estable para publicación pública.

### Novedades desde v0.9.13

---

#### Balance y rutas NG+

- **Variable PL bonus** en `close_run()` para 11 rutas (`t >= 1`): el bonus escala con el resultado del run (hifas, biomasa, epsilon, tiempo, etc.) con un cap por ruta.
- **Rutas Tier 3 NG+**: condiciones desbloqueables exigentes para Singularidad, Allostasis, Esporulación y otras rutas.
- **Rework resonancia_simbionte y aura_dorada**: fórmulas de buffs de legado post-run reescritas con balance mejorado.
- **Rework omega defense y resonancia cognitiva**: nuevas fórmulas de defensa estructural y amplificación cognitiva.

#### UI / UX

- **Header con stats agregados**: indicadores compactos click×, pas×, Ω≥, PL× reemplazan la lista de buffs individuales. Siempre visibles en juego.
- **Lab mode y fórmula con colores de legado**: los buffs activos muestran su tipo con color para facilitar la lectura.
- **Iconos en panel de bifurcación**: cada rama de mutación tiene su emoji temático (HOMEOSTASIS, RED MICELIAL, SIMBIOSIS, ALLOSTASIS, COLONIZACION INVASIVA, SIMBIOSIS MECANICA).

#### Pantalla de créditos

- Scroll animado full-screen a 72 px/s, aparece automáticamente tras la primera trascendencia de cada slot.
- Botón "Créditos" permanente en el menú principal.
- Compatible con modo "Reducir movimiento" (muestra créditos estáticos).

#### Exportar / Importar save

- **Exportar**: botón en Ajustes descarga el save completo como `.json` (`{run, legacy}`). Funciona en desktop y web.
- **Importar (web)**: sube un `.json` exportado desde desktop y recarga la partida. Usa FileReader + polling para compatibilidad HTML5.
- Retrocompatibilidad con saves viejos (formato solo-run).

#### Compatibilidad web (HTML5)

- Fix sistemático de todos los emojis y símbolos BMP en Labels y Buttons: `EmojiToRichText.strip()` aplicado en `UpgradeButton`, `MainMenu`, `AchievementManager`, `UIManager`, `main.gd`.
- Agregados a `BMP_SYMBOLS`: reloj, engranaje y simbolos de rutas.
- Toast de logros: icono migrado a `RichTextLabel` con `EmojiToRichText.rich()` para soporte Twemoji en web.

#### Sistema de Accesibilidad (nuevo — AccessibilityManager)

Nuevo autoload que persiste configuración en `user://accessibility_settings.json`.

- **Escala de fuente**: 85% / Normal / 115% / 130%. Aplica al recargar escena. 73 overrides de font_size actualizados a `AccessibilityManager.fs(N)`.
- **Reducir movimiento**: suprime tweens en toasts de logros, scroll de créditos y overlay de primera trascendencia.
- **Alto contraste**: botones de upgrade en blanco/negro en lugar de verde/gris.
- **Daltonismo**: Deuteranopia/Protanopia (azul #4488ff / naranja #ff8800) o Tritanopia (magenta / rojo-naranja). 29 colores de status en UIManager actualizados a helpers de AccessibilityManager.

#### Panel de Ajustes

- Fondo completamente opaco (reemplaza `self_modulate` por `StyleBoxFlat`).
- `ScrollContainer` para manejar contenido largo.
- Nueva sección "Accesibilidad" con todos los controles.
- Emoji de engranaje corregido para web.

#### Metadata y publishing

- `version.gd`: v1.0.0 "Génesis".
- `project.godot`: description, version, icon seteados.
- `export_presets.cfg`: company/product/copyright para Windows; meta tags para HTML5.
- `icon.png`: icono fractal del juego.

---

## [v0.9.13] — 2026-05-10

- Sistema de Slots (multiples partidas guardadas).
- Historial de Ciclos con stats por run.
- Autobackup del banco genético para prevenir pérdida de datos.
- Tutorial completo (TutorialManager) con 3 fases.
- AudioManager: SFX pool, música ambient, web autoplay unlock, panel de settings.
- Settings: sliders de volumen, mutes, telemetría, borrar run.

## [v0.9.12]

- Reactor 3D: visualización de biomasa en 3D con cámara dinámica y sync de viewport.

## [v0.9.11]

- Sistema de logros completo (50 logros) con 5 tiers.

## [v0.9.10]

- UX y Debug: panel de debug, atajos de teclado 1-9, mejoras de feedback visual.

## [v0.9.x — v0.8.x]

- Rutas post-trascendencia: VACIO HAMBRIENTO, CARNAVAL, REENCARNACION HEREDADA.
- Sistema de trueque y mecánica de epsilon estructural.
- Reactor metabólico y modelo bioeconómico.

## [v0.7 — v0.1]

- Fundamentos del idle: click, auto, upgrades, prestige, legado cósmico.
