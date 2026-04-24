# 🧾 CHANGELOG

## v0.6.9 — HUD Split Release (pre‑v0.7)

### ✨ Nuevos
- Separación semántica de HUD en dos dominios:
  - Producción activa (izquierda)
  - Dinámica del sistema (derecha)
- ScrollContainer para bloque científico
- Limpieza de duplicaciones de Δ$ y métricas pasivas
- Export Run actualizado para incluir:
  - snapshot productivo
  - snapshot estructural
  - snapshot sistémico

### 🔧 Refactors
- `update_click_stats_panel()` ahora es fuente única del HUD científico
- Eliminadas variables redundantes del UI loop
- Migradas métricas de ingreso pasivo al panel derecho

### 🧹 Removido
- Texto estático heredado del layout viejo
- “rendimiento diario” duplicado

---

## Historial previo (resumido)
- v0.6.x — Modelo estructural + persistencia dinámica
- v0.5.x — Productores + desbloqueos progresivos
- v0.4.x — Núcleo económico base
