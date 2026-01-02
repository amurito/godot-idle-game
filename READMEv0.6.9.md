# Idle — Economic + Structural HUD

This build corresponds to the **HUD split refactor** prior to v0.7.

The interface is now organized into two conceptual domains:

## 🎯 Panel izquierdo — Producción activa (micro)
> Lo que el jugador hace

Incluye:
- PUSH (click power)
- Fórmula productiva y valores actuales
- Aporte activo por subsistema
- Productores desbloqueados
- Modelo estructural (teórico)

## 🌍 Panel derecho — Dinámica del sistema (macro)
> Cómo el sistema se comporta

Incluye:
- Dinero actual
- Δ$ estimado / s
- Activo vs Pasivo
- Distribución de aporte (productores)
- Tiempo de sesión
- Historial de eventos (Lap markers)

Esta versión elimina duplicaciones conceptuales y separa:
- acción → observación
- producción → medición
- jugador → sistema

---

## 🔧 Tecnologías
- Godot 4.5.x
- GDScript
- UI basada en containers + HUD scrollable

---

## 🚀 Próximo hito – v0.7
> Formalización del panel derecho como dashboard sistémico

Ver `ROADMAP.md` para detalles.
