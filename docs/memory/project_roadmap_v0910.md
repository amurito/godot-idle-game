---
name: v0.9.11 completado — próximo v1.1 AI Observer
description: v0.9.11 Logros Completos terminado 2026-05-04. Todo pre-v1.1 está completo.
type: project
originSessionId: 9677ec3b-d91a-46f1-9736-bc5ed57bfcca
---
## v0.9.10 — UX y Debug — COMPLETADO (2026-05-03)

### 1. Banco Genético Rediseñado ✅
- Layout 5 columnas: Economía | Estructura | Biología+Conocimiento | Rutas | NG++Secretos
- Panel full-screen: fix en MainMenu.tscn (VBoxContainer anchors_preset=15)
- Fix multi-nivel: buffs con lvl>0 y no maxeados muestran toggle + botón "Nv.X N PL"

### 2. Lab Mode Expandido ✅
- Tecla L togglea: fórmula+click stats, genome_scroll, todos los eventos

### 3. Fix update_genome ✅
- `_set_genome_state` compara estado previo — ya estaba implementado.

### 4. Debug Panel (F1) ✅
- DebugPanel.gd solo en OS.is_debug_build(). F1 para toggle.

---

## v0.9.11 — Logros Completos — COMPLETADO (2026-05-04)

### Panel de Logros ✅
- Full-screen con ScrollContainer + fit_content=true en RichTextLabel
- Cards estilo Terraria: BBCode table 2 columnas, bgcolor por estado
- MYTHIC tier visible (faltaba en tier_order de MainMenu.gd)
- vacio_absoluto eliminado (era imposible de obtener — trigger custom sin evaluador)

### 16 logros nuevos (total ~65) ✅
- Rutas faltantes: ruta_allostasis, ruta_homeorhesis, ruta_ascesis, ruta_reencarnacion
- Post-trascendencia: carnaval_iniciado, reencarnado, vacio_iniciado
- Biosfera: bioma_despierto (hifas ≥ 0.5)
- Mecánicos: primer_click_letal, depredador_total (50 devours), omega_inviolable
- Endgame: ascension_total (5 trascendencias), dios_de_las_moscas (16 finales), legado_absoluto
- Meta: cinco_legados, metabolismo_oscuro_pico

### Bug fixes ✅
- Hifas unlock: timer 40s sostenido + reset_run() entre partidas
- Omega floor: re-aplicado después del paso 8 del logic tick
- Tooltips indicators: efectos mecánicos concretos (ω_min, multiplicadores)
- EvoManager: activate_mutation incluye "homeorhesis" que faltaba

### Nuevos eventos AchievementManager ✅
- `big_click` (power ≥ $10k), `depredador_devour`, `post_tras_route`
- push_snapshot extendido: `hifas`, `trascendencia_count`
- on_run_closed payload: `reencarnacion_active`

---

## v0.9.11 — Web Export Fix — COMPLETADO (2026-05-07)

### Emoji rendering completo en HTML5 export ✅
- EmojiToRichText.gd: 55 Twemoji PNGs locales + BMP_SYMBOLS (16 entradas)
- Todos los RichTextLabel actualizados a `clear()` + `append_text(EmojiToRichText.rich(...))`
- Todos los Label/Button actualizados a `EmojiToRichText.strip(...)`
- main.tscn: caracteres BMP hardcodeados reemplazados por ASCII
- Cubre: economía, logros, mutaciones, trascendencia, banco genético, evolución

---

## Próximo — v1.1 AI Observer

- AIObserver.gd como autoload opcional
- Panel con predicción de próxima mutación, ruta dominante, tensión entre rutas
- Serializar estado del juego cada 30s + llamada a API externa opt-in
- Fallback offline: análisis heurístico local

**How to apply:** Todo el backlog pre-v1.1 está completo. Próxima sesión puede arrancar v1.1 directamente.
