# CHANGELOG

Este documento registra la evolución conceptual, mecánica y matemática del sistema.
El proyecto prioriza:

- transparencia del modelo económico
- separación real de subsistemas
- lectura honesta de los números en tiempo real
- decisiones de diseño fundamentadas


## 🔵 v0.9.0 — “Era Alostática” (Evolución Tier 2)

**Fecha:** 02/04/2026  
**Estado:** ESTABLE — Tier 2 Implementado — Balance NG+
 
### ✨ Cambios principales
#### 🧬 Evolución y Tier 2
- **Allostasis (Tier 2)**: Transición completa desde Homeostasis. Requiere 3 perturbaciones sobrevividas, 150 resiliencia y metabolismo > 200/s.
- **Bonus Alostático**: Multiplicador masivo de **x5.0** al metabolismo pasivo al activar la mutación.
- **Resiliencia Blindada**: Nuevo piso de estabilidad adaptativo ($\Omega \geq 0.60$) en Allostasis.
- **Legado "Resiliencia Alostática"**: Desbloqueo permanente tras cerrar la run que otorga un piso de $\Omega \geq 0.45$ en futuras partidas.

#### 🧮 Refuerzo de la Fórmula Central
- **Término `re` (Redirección de Energía)**: Integración visual y matemática del legado de redirección (10% Click -> Pasivo).
- **Término `ea` (Escalado Alostático)**: Nueva mejora de Tier 2 que potencia el metabolismo basado en la estabilidad.
- **μ-Buff**: El Capital Cognitivo ahora amortigua de forma más agresiva el impacto de la complejidad mecánica.

#### 📺 Interfaz Adaptativa (v0.9)
- **Botón de Evolución Inteligente**: El botón de "Iniciar Mutación" ahora cambia de color (Cian) y se habilita automáticamente al detectar requisitos de Tier 2.
- **Checklist Multi-Tier**: El panel de bifurcación ahora alterna requisitos entre Tier 1 y Tier 2 según el estado del genoma.

#### 🔧 Bug Fixes y Limpieza
- **Deduplicación de Botones**: Corregido error que generaba botones duplicados en el panel de evolución tras múltiples resets.
- **Signal Safety**: Restaurados encabezados de funciones perdidos y corregidos errores de puntero nulo en el EvoChoicePanel.


---


## 🟢 v0.8.3 — “Visual Insights & Achievements Fix” (Upgrade UI)

**Fecha:** 24/03/2026  
**Estado:** ESTABLE — Documentado — UX Refinada

### ✨ Cambios principales
#### 🎨 Interfaz y Documentación
- **Soporte BBCode**: El panel de Contabilidad ahora usa `RichTextLabel` con colores dinámicos (Buffs en verde, Nerfs en rojo).
- **Checklist Evolutivo**: Requisitos de evolución con indicadores de color `[x]` (verde) / `[ ]` (rojo).
- **Manuales Externos**: Generación de `MANUAL_EVOLUCION.HTML` y `MATEMATICA.HTML` con todas las fórmulas y rutas del juego.

#### 🏁 Logros y Progresión
- **Nuevos Logros**: Añadidos "Millonario de Esporas", "Equilibrio Frágil" y "Parásito Insaciable".
- **Fix Dominancia Click**: El logro ya no se obtiene al primer click, requiere haber desbloqueado al menos una mejora de producción automática.

#### 🔧 Bug Fixes (Críticos)
- **Homeostasis Fix**: Ahora el mínimo de Ω (0.35) actúa como un piso real en el cálculo, permitiendo alcanzar las condiciones de cierre de run.
- **Ω Enforced**: Corregido bug donde la flexibilidad podía bajar de 0.35 incluso con la mutación de estabilidad activa.

---

## 🟡 v0.8.2 — “Fungi Stability” (Rework Evolutivo)

**Fecha:** 23/03/2026  
**Estado:** ARCHIVADO

### ✨ Cambios principales
#### 🧬 Rework de Evoluciones (Basado en CAMINOS.HTML)
- **Eliminación de "Paredes de Omega"**: Se eliminaron los bloqueos rígidos de flexibilidad (0.45+) para avanzar a Red Micelial Fase B.
- **Transición Orgánica**: La Red Micelial ahora fluye de Fase A a Fase B basada en Hifas (>10), Biomasa (>=5) y estabilidad ($\epsilon$ < 0.32).
- **Checklist Institucional**: Nueva interfaz de "Próxima transición" en el panel de Contabilidad. Muestra requisitos en tiempo real con `[x]` / `[ ]`.
- **Camino a Esporulación**: Se fijaron los requisitos finales (Epsilon Peak >= 0.75, Omega <= 0.30, Tiempo >= 15 min).

#### 📺 Mejoras de UI/UX
- **Visualización de Hifas**: Se muestra el conteo numérico real de hifas en el panel de Biosfera.
- **Scroll del Sistema**: Se habilitó el desplazamiento en el panel derecho (se bloqueaba con la Biosfera abierta).
- **Limpieza de Logs**: El log de eventos ahora es más conciso. No repite "Desbloqueado" en cada nivel y utiliza iconos (🟢, 🔵, ⚖️) para mejor lectura.
- **Sincronización de Botones**: El botón de "Ver todos los eventos" ahora actualiza su texto correctamente.

---

## 🟢 v0.4 — “Perillas internas del sistema”

**Fecha:** 25/12/2025  
**Estado:** Estable — jugable — tuning abierto

### 🎯 Objetivo de la versión

No crear nuevos productores,
sino profundizar los existentes:

✔ cada subsistema evoluciona dentro de su propia matemática  
✔ la fórmula global se mantiene estable  
✔ el jugador puede “tocar perillas” y ver la ecuación cambiar en vivo

---

### 🧮 Fórmula estructural del sistema

Se fija formalmente como representación base:

Δ$ = clicks × (a × b × c) + d × md + e × me


Donde:

| Símbolo | Sistema | Significado |
|--------|--------|-----------|
| a | Click base | fuerza del acto manual |
| b | Multiplicador | memoria, dominio técnico |
| c | Persistencia | sostenimiento del esfuerzo |
| d | Trabajo manual | ingreso estructural pasivo |
| md | Ritmo de trabajo | eficiencia productiva |
| e | Trueque | intercambio social |
| me | Red de intercambio | expansión de relaciones |

👉 La fórmula **no cambia entre versiones**  
👉 Solo evolucionan los modificadores internos

---

### ✨ Cambios principales

#### ✔ Nuevo modificador interno — Trabajo Manual


Donde:

| Símbolo | Sistema | Significado |
|--------|--------|-----------|
| a | Click base | fuerza del acto manual |
| b | Multiplicador | memoria, dominio técnico |
| c | Persistencia | sostenimiento del esfuerzo |
| d | Trabajo manual | ingreso estructural pasivo |
| md | Ritmo de trabajo | eficiencia productiva |
| e | Trueque | intercambio social |
| me | Red de intercambio | expansión de relaciones |

👉 La fórmula **no cambia entre versiones**  
👉 Solo evolucionan los modificadores internos

---

### ✨ Cambios principales

#### ✔ Nuevo modificador interno — Trabajo Manual

d × md


Nombre conceptual: **Ritmo de Trabajo**

- crecimiento lento pero estable
- costo progresivo moderado
- recompensa sostenida en el tiempo

Rol sistémico:

- refuerza la economía estructural
- compite con el click sin anularlo

---

#### ✔ Nuevo modificador interno — Trueque

e × me


Nombre conceptual: **Red de Intercambio**

- mejora cara
- impacto fuerte
- mantiene ineficiencia estructural (0.75)

Rol sistémico:

- expande el sistema
- no reemplaza al trabajo productivo

---

### 🧠 Decisión de diseño central

Se define como identidad del juego:

> “Click y Pasivos NO deben fusionarse.”
> Cada subsistema crece en su propio espacio matemático.

Esto evita:

❌ colapso a hiperinflación  
❌ dependencias artificiales  
❌ loops dominantes triviales

Y habilita:

✔ tensión permanente entre estrategias  
✔ pacing humano  
✔ lectura del modelo económico

---

### 🎮 Experiencia buscada (v0.4)

- early game → click significativo
- mid game → economía estructural gana peso
- late game → tensión estratégica real

El jugador puede:

✔ elegir su identidad económica  
✔ auditar el sistema en pantalla  
✔ interpretar la evolución del mundo

---

### 🧩 Próximos pasos (v0.5)

Nombre tentativo:

> “Bifurcaciones del sistema”

Posibles líneas:

- mejoras únicas permanentes
- trade-offs estructurales
- decisiones irreversibles de economía

Siempre manteniendo:

Δ$ = clicks × (a × b × c) + d × md + e × me


Como **ley madre del sistema**.

---

Fin del documento.

