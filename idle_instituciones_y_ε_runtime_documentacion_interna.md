# IDLE — Modelo Económico Evolutivo
## Documentación interna · ε_runtime e Instituciones

---

## 1. Propósito del documento

Este documento describe la **introducción de ε_runtime** y del **árbol de Instituciones** dentro del proyecto **IDLE — Modelo Económico Evolutivo**, manteniendo compatibilidad total con la versión **v0.7.x (ε : Structural Stability)**.

No se trata de nuevas mecánicas de producción, sino de **capas de lectura y regulación del sistema**.

---

## 2. Principios de diseño

- El progreso no es dinero, es **comprensión estructural**.
- ε no representa error, sino **fricción, tensión y complejidad**.
- Ninguna institución aumenta la producción.
- Toda nueva capa debe emerger del estado del sistema, no adelantarse.

---

## 3. ε_runtime

### 3.1 Definición conceptual

**ε_runtime** es un indicador dinámico de tensión entre:

- lo que el sistema **produce efectivamente** en runtime
- lo que el modelo estructural **espera** que produzca

No corrige el modelo.
No modifica cₙ ni μ.

ε_runtime **observa**, no actúa (en v0.7.x).

---

### 3.2 Definición matemática

ε_runtime se define como:

|Δ$ observado − Δ$ estructural| / Δ$ estructural

Donde:

- Δ$ observado: producción real por segundo
- Δ$ estructural: producción estimada a partir del último estado estable

El valor es normalizado y adimensional.

---

### 3.3 Lectura cualitativa

| ε_runtime | Lectura del sistema |
|----------|--------------------|
| ≈ 0.0 | Sistema alineado |
| 0.05 – 0.15 | Fricción leve |
| 0.15 – 0.30 | Sistema tensionado |
| > 0.30 | Estrés estructural |

---

## 4. Rol de ε_runtime en v0.7.x

En v0.7.x:

- ε_runtime **no penaliza** producción
- ε_runtime **no modifica** fórmulas base
- ε_runtime **habilita lecturas y desbloqueos**

Su primera función activa es **desbloquear Instituciones**.

---

## 5. Instituciones

### 5.1 Definición

Las Instituciones son **estructuras regulatorias internas** que:

- reducen fricción
- estabilizan el sistema
- permiten sostener crecimiento

No son upgrades económicos.
Son **mantenimiento estructural**.

---

## 6. Condición de desbloqueo (unlock compuesto)

Las Instituciones aparecen únicamente cuando el sistema demuestra:

- complejidad suficiente
- tensión real
- escala económica
- masa histórica

### Condiciones requeridas:

- n ≥ 20
- ε_runtime ≥ 0.12 (en algún momento de la run)
- Δ$ / s ≥ 80
- Dinero total histórico generado ≥ $50.000

Este unlock no depende del dinero actual.

---

## 7. Integración en el HUD

- Las Instituciones aparecen como **una nueva sección colapsada**
- No hay tutorial ni explicación explícita
- El jugador decide abrir la capa

Texto sugerido:

"Instituciones (0/3) — Estructuras regulatorias"

---

## 8. Árbol de Instituciones (v0.8-pre)

### 8.1 Contabilidad Básica

- Costo: $8.000
- Requiere: n ≥ 20
- Efecto:
  - ε_runtime × 0.85

Formalización mínima de flujos económicos.

---

### 8.2 Estandarización Operativa

- Costo: $18.000
- Requiere:
  - Contabilidad Básica

- Efecto:
  - ε_runtime × 0.7
  - Desactiva ineficiencia pasiva

Reduce impacto de la fricción, no su causa.

---

### 8.3 Regulación Interna

- Costo: $35.000
- Requiere:
  - Estandarización Operativa
  - μ ≥ 1.15

- Efecto:
  - ε_runtime tiene un máximo de 0.15

Impone un límite estructural al estrés del sistema.

---

## 9. Reglas globales

- Las instituciones no producen dinero
- No afectan clicks
- No afectan cₙ directamente
- Solo modifican la **lectura y gestión de tensión**

---

## 10. Proyección futura (no implementada)

La existencia de Instituciones habilita, a futuro:

- costos de mantenimiento
- burocracia
- obsolescencia institucional
- captura regulatoria
- deuda estructural

Estas capas pertenecen a versiones posteriores.

---

## 11. Cierre

Con ε_runtime e Instituciones, el sistema evoluciona de:

> producir → entender → estabilizar

El jugador deja de optimizar dinero y comienza a **optimizar estructura**.

Este documento define el marco conceptual y técnico para esa transición.

