# IDLE — Modelo Económico Evolutivo
## Documento matemático y simbólico (v0.7)

Este archivo documenta **todas las fórmulas, símbolos y relaciones matemáticas** presentes en el juego **IDLE — Modelo Económico Evolutivo**, tomando como fuente el archivo `main.gd`.

El objetivo es que:
- el modelo sea **legible como sistema formal**
- cada símbolo tenga **significado único y estable**
- futuras capas (ε, crisis, nuevos tiers) puedan apoyarse sin romper coherencia

---

## 1. Producción total

La producción total del sistema se expresa como:

```
Δ$ = Δ$_click + Δ$_pasivo
```

Donde:

```
Δ$_click = clicks · (a · b · cₙ)
Δ$_pasivo = d · md · so + e · me
```

---

## 2. Variables de producción

### a — Click base
Valor lineal que aumenta con upgrades directos.

### b — Multiplicador de click
Multiplicador exponencial suave del click.

### cₙ — Persistencia dinámica observada
Factor estructural que amplifica toda la producción activa.

---

## 3. Productores pasivos

### d — Trabajo Manual
Producción pasiva lineal (por segundo).

### md — Ritmo de Trabajo
Multiplicador del productor d.

### so — Especialización de Oficio
Buff estructural aplicado a d.

---

### e — Trueque
Productor alternativo basado en redes.

### me — Red de Intercambio
Multiplicador del sistema de trueque.

---

## 4. Capital Cognitivo (μ)

El **capital cognitivo** representa la capacidad del sistema para organizar, transmitir y estabilizar mejoras.

Se define como:

```
μ(n) = 1 + log(1 + n) · 0.08
```

Donde:
- `n` = nivel cognitivo (`cognitive_level`)
- μ ≥ 1

Propiedades:
- crecimiento logarítmico
- rendimientos decrecientes
- nunca se aplana completamente

μ **no es daño**, es **estructura**.

---

## 5. Persistencia estructural

### c₀ — Persistencia base
Valor basal fijo del sistema.

### k — Constante de persistencia
Constante estructural del modelo.

### n — Upgrades estructurales
Cantidad total de mejoras estructurales desbloqueadas.

---

## 6. κμ — Persistencia efectiva cognitiva

μ no actúa directamente sobre cₙ, sino que **modula k**:

```
κμ = k · (1 + α · (μ − 1))
```

Donde:
- α = coeficiente de impacto cognitivo (actualmente 0.55)

Esto vuelve al capital cognitivo **perceptible en pocas mejoras**, pero estable a largo plazo.

---

## 7. Función estructural fⁿ

La persistencia teórica esperada se define como:

```
fⁿ = c₀ · κμ^(1 − 1/n)
```

Donde:
- n = cantidad de upgrades estructurales

Esta función define el **objetivo estructural** hacia el cual converge cₙ.

---

## 8. Persistencia dinámica observada

El sistema no salta instantáneamente a fⁿ.

cₙ evoluciona mediante una convergencia sigmoidal:

```
cₙ(t+Δt) = lerp(cₙ, fⁿ, α(n)·Δt)
```

Donde:
- α(n) es una función sigmoide del progreso estructural

---

## 9. Dominancia del sistema

El sistema evalúa qué término domina la producción:

- CLICK domina
- Trabajo Manual domina
- Trueque domina

Esto se usa para:
- logs
- achievements
- análisis estructural

---

## 10. ε — Distancia estructural (modelo)

La distancia estructural del modelo se define como:

```
ε_modelo = | fⁿ − cₙ(modelo) |
```

Actualmente:
- ε solo es diagnóstico
- no tiene consecuencias jugables

---

## 11. Próxima capa prevista: ε_runtime (WIP)

Propuesta futura:

```
ε_runtime = | cₙ(runtime) − cₙ(modelo) |
```

Usos posibles:
- fricción
- ineficiencia
- crisis
- decisiones estructurales

---

## 12. Convenciones matemáticas

- Variables latinas: producción directa
- Letras griegas: estructura / meta-sistema
- Subíndices: estado dinámico (ₙ)
- Superíndices: funciones teóricas (fⁿ)

---

## 13. Estado del modelo

- Modelo estable
- HUD limpio
- Fórmulas coherentes
- Listo para nuevos tiers

---

**Documento vivo — actualizar al introducir nuevas capas**

1. Función sigmoide: qué hace y por qué está bien así

En tu modelo actual, la sigmoide:

α(n) = 1 / (1 + e^(−0.35 · (n − 6)))


cumple tres roles clave:

Evita saltos bruscos
cₙ no “teletransporta” a fⁿ. Se aproxima suavemente.

Define una fase media clara
Antes de n≈6 → progreso lento
Después → estabilización estructural

Te habilita gameplay futuro
La pendiente (0.35) y el centro (6) son parámetros jugables:

crisis

reformas

shocks

políticas

👉 Es una muy buena elección para un idle conceptual. No la tocaría ahora.

2. Escalado de precios y upgrades (lo que YA está implícito)

Aunque no lo formalizaste en el .md, el código ya define una jerarquía de escalados:

Escalados suaves (lineales / exponenciales bajos)

click_value

d (Trabajo Manual)

e (Trueque)

Escalados estructurales (meta)

structural_upgrades

cognitive_level

persistencia

Esto es correcto porque:

los precios crecen rápido

pero el impacto estructural crece lento
→ eso sostiene runs largas sin romper el modelo

3. ¿Sigue valiendo n = 1 + log(1 + structural_upgrades)?

👉 Sí, y más que antes.

Pero ojo: ahora hay dos “n” distintos (y eso está bien):

n₁ — progreso estructural
structural_upgrades

n₂ — lectura matemática del progreso
n_log = 1 + log(1 + structural_upgrades)


Esto te permite:

usar n₁ para costos / desbloqueos

usar n₂ para curvas matemáticas suaves

💡 Es una separación muy potente. Yo la mantendría.

4. Sobre tu idea clave: hacer que el 0.08 de μ sea mejorable

“yo tenía pensado el valor de μ(n) = 1 + log(1 + n) · 0.08, hacer que 0.08 se incremente con mejoras”

👉 Sí, es totalmente consecuente
👉 y además es la forma correcta de escalar μ sin romper nada

Interpretación conceptual

μ(n) mide capacidad cognitiva

el coeficiente (0.08) mide calidad institucional / cultural

Eso habilita:

μ(n) = 1 + log(1 + n) · β


Donde:

β empieza en 0.08

β es mejorable vía meta-productores

5. Ideas claras para los nuevos tiers que mencionás
A. Meta-productores (mi favorita para el próximo tier)

No producen dinero.
Producen parámetros.

Ejemplos:

Meta-productor	Afecta
Educación	↑ β (impacto de μ)
Instituciones	↓ ε_runtime
Regulación	suaviza la sigmoide
Cultura técnica	↑ α de κμ

Gameplay:

caros

lentos

impacto global

pocas unidades

B. Regulación (control del sistema)

Regulación no produce, limita extremos.

Ejemplos:

reduce volatilidad

reduce overshoot

permite runs más estables

Puede aparecer como:

slider

decisión binaria

evento

C. Instituciones (estructura persistente)

Instituciones podrían:

bajar costos de upgrades

reducir crecimiento de precios

estabilizar cₙ frente a shocks

Son ideales para:

late game

epsilon_runtime

D. Entropía / Deuda / Complejidad (capa negativa)

Esto es oro conceptual para tu juego.

Propuesta:

Complejidad ∝ structural_upgrades
Entropía ∝ velocidad de crecimiento
Deuda ∝ ε_runtime sostenido


Y obligan a:

invertir en regulación

invertir en instituciones

aceptar estancamientos temporales

6. Próximo paso lógico del modelo (cuando volvamos a ε)

Antes de agregar más productores clásicos, yo haría:

cerrar β como parámetro jugable

introducir ε_runtime con efecto leve

solo después abrir un nuevo tier productivo

Eso mantiene:

coherencia

legibilidad

identidad del juego

7. Sobre el archivo .md

El documento matemático que subiste está excelente como base, y es totalmente válido como source of truth del modelo 

modelo_matematico_v_0_7

.

Lo que falta (y vos ya detectaste bien) es:

sección explícita de sigmoide

sección de costos y escalados

sección de parámetros mejorables (β, α, etc.)

Eso se puede extender sin tocar el código.

Cierre

Lo que estás construyendo ya no es “un idle con fórmulas”:
es un sistema económico formal jugable.

Tu intuición con:

μ

κμ

ε

meta-capas

es muy sólida y consistente con teoría de sistemas reales.