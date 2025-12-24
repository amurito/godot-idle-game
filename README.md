# Idle Growth — Minimal System Game

## 🎯 Idea General

Idle Growth es un juego idle minimalista cuyo objetivo no es acumular números grandes,
sino **entender y modificar la fórmula que gobierna el crecimiento**.

El jugador no solo gana dinero:  
**ve, aprende y altera el sistema matemático que lo genera**.

---

## 🧠 Principio de Diseño

> El juego no oculta sus reglas.
> La progresión es transparente y explicable.

Cada incremento de dinero responde a una fórmula visible en pantalla.

---

## 🧮 Modelo Matemático Base (v0.1)

El sistema actual se rige por la siguiente relación:

Dinero(t) = Clicks × ClickValue + ∫ IngresoAutomático dt


Donde:
- `Clicks` es la acción manual del jugador
- `ClickValue` mejora mediante upgrades
- `IngresoAutomático` genera dinero en el tiempo

La fórmula se muestra en tiempo real dentro del juego.

---

## 🎮 Mecánicas Actuales (v0.1)

✔ Botón central de acción (“Ganar $10”)  
✔ Mejora del valor del click  
✔ Ingreso automático escalable  
✔ Costos crecientes  
✔ Fórmula visible y honesta  

---

## 🧩 Qué NO es este juego (todavía)

❌ No es un idle de números gigantes  
❌ No tiene animaciones complejas  
❌ No tiene progresión artificial  
❌ No tiene sistemas ocultos  

Todo sistema nuevo debe poder explicarse con una frase.

---

## 🧠 Filosofía del Late Game

En el late game, el jugador deja de hacer clicks
y pasa a **diseñar, modificar y limitar el sistema de crecimiento**.

El foco no estará en “ganar más” sino en:
- cambiar tasas
- introducir multiplicadores
- aceptar trade-offs
- desbloquear leyes matemáticas

---

## 🔮 Roadmap Conceptual

### v0.1 – Core Loop & Formula 

Click + ingreso automático funcional
Costos crecientes
Fórmula visible en tiempo real
Base para escalado y late game

### v0.2 — Productores
- El ingreso automático se vuelve estructural
- Visualización clara de producción

### v0.3 — Multiplicadores
- Modifican la fórmula
- No generan dinero por sí mismos

### v0.4 — Late Game
- Soft caps
- Leyes del crecimiento
- Decisiones irreversibles

---

## 🧪 Regla de Desarrollo

> Si una feature no puede explicarse con una frase simple,
> no se implementa.

---

## 🛠️ Tecnologías

- Godot Engine 4.x
- GDScript
- Enfoque MVP y versionado incremental

---

## 📌 Estado del Proyecto

Versión actual: **v0.1**  
Estado: **COMPLETA**

Antes de avanzar:
- el core loop debe sentirse claro
- la fórmula debe ser comprensible

## UPGRADES 
1. Diferenciar “jugador” de “diseñador”

Podrías agregar UNA frase tipo:

El jugador comienza como operador (clicks) y progresa hacia diseñador del sistema.

No más que eso.

🔹 2. Aclarar que la fórmula es “viva”

Ejemplo:

La fórmula no es estática: cambia con upgrades y decisiones.

Refuerza el concepto.
v0.1.5 — Claridad del Sistema

Contenido:

El botón “Ganar $X” refleja el valor real del click

Se actualiza al comprar upgrades

La UI refuerza la fórmula

Aprendizaje:

Data binding

UI reactiva

Separación lógica / visual

## 0.1.5 ##

Scope cerrado de v0.1.5

✔ Mostrar valor del click en el botón
✔ Actualización automática del texto
✔ Sin nuevas mecánicas
✔ Sin rebalance
✔ Sin late game todavía
