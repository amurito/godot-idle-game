# CHANGELOG — AntiIDLE

## [v1.0.0] — "Primera Luz" — 2026-05-15

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

- `version.gd`: v1.0.0 "Primera Luz".
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
