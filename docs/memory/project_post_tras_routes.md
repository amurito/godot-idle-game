---
name: Post-trascendencia routes
description: Estado y mecánicas de las rutas post-trascendencia: VACÍO HAMBRIENTO, CARNAVAL, REENCARNACIÓN HEREDADA
type: project
originSessionId: 554b9b8e-33ea-46f2-85ae-400b8aa51329
---
Tres rutas post-trascendencia implementadas. Todas en SaveManager bloque "post_tras".

## VACÍO HAMBRIENTO (vh)
- Condición: cerrar run sin comprar upgrade de pasivo (passive income)
- Buff: multiplicador global vh en fórmula de clicks
- Sub-ruta ASCESIS PROFUNDA: cierre alternativo por "renuncia absoluta"
  - Condiciones: run_time ≥ 900s + dinero ≥ $1M + biomasa < 0.5 + sin upgrades auto/trueque + ε < 0.25
  - Timer pausable 300s (no resetea si fallan condiciones)
  - Rewards: +7 PL, logro Mythic "Vacío Absoluto"
- Reactor color: violeta Color(0.75, 0.2, 1.0) cuando activo (prioridad 0C en get_reactor_color)
- UI: fórmula muestra "clicks · a · b · cₙ · [vh]" en violeta
- Lab mode: vh = 100 aparece en click_stats_panel
- Persistencia: vacio_active, mult, carnaval_*, reencarnacion_active guardados en SaveManager

## CARNAVAL DE MUTACIONES
Sub-menú con dos sub-rutas:

**DOMADOR DEL CAOS:**
- Tracking: carnaval_total_rotations
- Condición: biomasa ≥12 + mutaciones específicas
- Buff: legado_caos (all_income_mult ×1.30)
- Notificación en genoma scroll

**POLIMORFÍA TOTAL:**
- Tracking: carnaval_peak_money
- Condición: biomasa ≥12 + ε ≥0.60
- Buff: legado_polimorfia (biomasa start boost +1.5)
- Notificación en genoma scroll
- Bonus: memoria_recurso (primera compra gratis, muestra precio real con "(GRATIS)")

## REENCARNACIÓN HEREDADA
- Condición: $800K + Ω≥0.40 + ε_peak≥0.60 + n>30 + 5min mínimo
- Buff: legado_ciclo (Memoria del Ciclo: -15% todos costos)
- Snapshot: hereda niveles del ciclo anterior con deuda ×1.5 por nivel
- SaveManager: guarda/carga reencarnacion_time y estados

## Logros
- Panel incluye tier MYTHIC (agregado en main.gd:662)

**Why:** Estas mecánicas son el núcleo del late game post-trascendencia.

**How to apply:** Al trabajar en rutas post-tras, verificar que SaveManager serialize/deserialize incluya los nuevos campos.
