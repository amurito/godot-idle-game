# IDLE — Observatorio fⁿ (v0.6)

Esta versión marca el inicio del análisis estructural del sistema.
El juego sigue siendo jugable, pero ahora también funciona como laboratorio matemático.

## 🎯 Objetivo de la versión

- Medir y observar el impacto de los upgrades estructurales
- Introducir el concepto fⁿ sin modificar aún el gameplay
- Registrar runs para análisis posterior
- Separar:
  • activo (CLICK)
  • pasivo (d+e)
- Relacionar progreso económico con estructura del sistema

---

## 🧮 Fórmula general del sistema

Δ$ = clicks · (a · b · c)  +  d · md  +  e · me

Donde:

a → click base  
b → multiplicador  
c → persistencia  
d → trabajo manual  
md → ritmo de trabajo  
e → trueque corregido  
me → red de intercambio  

---

## 🧪 Introducción de fⁿ (modo observacional)

En v0.6 aparece el eje estructural del sistema:

- Cada upgrade estructural incrementa **n**
- fⁿ describe la persistencia efectiva del sistema

Persistencia dinámica:

cn  =  c · k^(1 − 1/n)

Por ahora:

✔ se mide  
✔ se exporta  
✔ se correlaciona con Δ$  

pero NO modifica aún el gameplay (eso llegará en v0.7).

---

## ⏱️ Herramientas de Laboratorio

### Cronómetro de run
Mide duración total de la sesión.

### Lap markers
Registra eventos relevantes:

- desbloqueos de productores
- cambios de dominio del sistema
- mejoras estructurales
- exportaciones

Solo se muestran los últimos 12 para evitar overflow visual.

---

## 📊 Métricas añadidas

- Δ$ total / s
- Distribución de aporte:
  - CLICK
  - Trabajo Manual
  - Trueque
- Activo vs Pasivo
- n (log)
- n (power)
- fⁿ (observacional)

---

## 📤 Exportación de runs

Formato generado:

- JSON (snapshot completo)
- CSV (lap log)

Incluye:
- estado económico
- métricas estructurales
- fⁿ
- n_log / n_power
- distribución por componente
- eventos clave de la run

---

## 🚧 Limitaciones intencionales

En v0.6:

- fⁿ no afecta aún al gameplay
- el sistema está en fase de observación
- el objetivo es comprender su dinámica
- serve como base para v0.7 (aplicación real de fⁿ)

---

## 🔜 Próxima versión

v0.7 — Persistencia Aplicada

- fⁿ pasa a modificar la fórmula real
- ajustes de balance
- validación empírica con runs exportadas