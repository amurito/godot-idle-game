# Lore Futuro — Rutas Post-METABOLISMO OSCURO

> Documento de diseño narrativo. Ideas generadas 2026-05-20.
> Contexto: METABOLISMO OSCURO es la ruta final del árbol Depredador.
> El hongo activó bioquímica alternativa "que la ciencia no predijo" sobreviviendo
> con < 20% recursos, Ω forzado a 0.10, upgrades bloqueadas, alimentado solo por
> biomasa oscura y devours previos.

---

## Premisas del árbol

El hongo llegó a Dark Met por: Hiperasimilación → Depredador (3+ devours) → colapso de recursos sostenido 15s.
Es un organismo que sobrevivió lo imposible a través de la depredación y luego de la autosuficiencia extrema.
Cualquier ruta posterior hereda ese trauma y esa capacidad.

---

## Rama A — Profundizar en la oscuridad

### AUTÓLISIS DIRIGIDA
*"La ciencia llama a esto autofagia. El hongo lo llama almuerzo."*

El hongo descubre que puede digerir sus propias estructuras para liberar energía concentrada.
Como un árbol en otoño: la destrucción controlada como estrategia de supervivencia.

**Condición de activación:** Bio ≥ 50 dentro de Dark Met + al menos 5 upgrades comprados en la run
**Mecánica:**
- Cada 30s el hongo "consume" un upgrade (destruye 1 nivel del más caro disponible)
- Cada consumo → burst masivo de $ y bio
- Al quedarse sin upgrades el hongo colapsa → run closes forzosamente
**Tensión:** cuánto esperás para activarla vs. cuándo te quedás sin material
**Efectos:** Click ×5, Passive ×2 durante los últimos devours, PL base +6
**Negativo:** No hay forma de parar la autólisis una vez iniciada
**Flavor:** *"Los restos de lo que construiste ahora te sostienen. Irónicamente, era lo que necesitabas siempre."*

---

### NECROSIS CONTROLADA
*"Morir en partes es sobrevivir en totalidad."*

Los segmentos periféricos del micelio mueren deliberadamente para nutrir el núcleo central.
La fragilidad extrema de Ω se convierte en la herramienta.

**Condición:** Dark Met activo + Ω decae a ≤ 0.05 naturalmente (sin intervención)
**Mecánica:**
- Ω sigue cayendo hasta 0.02
- Pero cada tick de ε genera burst pasivo proporcional a (1/Ω): cuanto más frágil, más productivo
- Si Ω toca 0 sin haber llegado a Bio ≥ 75 → colapso total
**Tensión:** la mecánica es maximizar producción mientras Ω se desintegra
**PL:** base +5, +3 adicionales si Bio ≥ 75 antes del cierre
**Flavor:** *"La periferia se sacrifica. El centro recuerda."*

---

### PROTOCOLO OMEGA-CERO
*"La estructura matemática del sistema se rompe. Eso es el poder."*

Si Ω = 0.10 es fragilidad extrema, existe el límite absoluto: Ω = 0.
El hongo descubre que en ese borde, las reglas del sistema dejan de aplicar.

**Condición:** Necrosis Controlada activa + Ω llega naturalmente a 0.01
**Mecánica:**
- Cuando Ω toca 0.00 → "Singularidad Inversa" de 45 segundos
- Todo el passive acumulado se convierte en click instantáneo
- El jugador tiene 45s para gastar / acumular antes del colapso inevitable
- Al terminar: run closes, no se puede evitar
**PL:** base +8 (el mayor del árbol oscuro)
**Nota de diseño:** Alta skill ceiling — el timing lo es todo
**Flavor:** *"Omega era el límite. Ya no hay límite."*

---

## Rama B — Salir de la oscuridad

### REMISIÓN METABÓLICA
*"La ciencia tampoco predijo esto."*

El hongo que sobrevivió lo imposible empieza a repararse.
Los pathways oscuros se integran al metabolismo normal, creando algo que no era ni hongo ni oscuridad.
La única ruta con "happy ending" del árbol.

**Condición:** Bio ≥ 200 dentro de Dark Met (extremadamente difícil con los penalties)
**Mecánica:**
- Desbloquea compras nuevamente pero a ×10 de costo (cicatrización estructural)
- Ω sube gradualmente +0.01/30s hasta 0.30
- ε_runtime deja de decaer
**PL:** base +5, +3 si se completan 3 compras post-remisión
**Nota de diseño:** Es la "ruta difícil con recompensa justa" — requiere dominar el Dark Met
**Flavor:** *"Algunos organismos no superan la oscuridad. Este la absorbió."*

---

## Rama C — El legado de lo oscuro

### ESPORAS DE CONTINGENCIA
*"No todas las muertes son finales. Esta tampoco."*

Sabiendo que el colapso es inevitable, el hongo invierte todo en producir esporas
ultra-resistentes codificadas con la memoria de la bioquímica oscura.
Muere. Pero sus esporas recuerdan.

**Condición:** Dark Met activo + run_time ≥ 600s + cualquier cierre voluntario activado
**Mecánica:**
- El hongo cierra la run voluntariamente al activarla (no espera colapso)
- Produce un "Legado Oscuro" que se transmite a la siguiente run via LegacyManager
- En la siguiente run: un buff único "Memoria Oscura" activo desde el inicio
  - +15% Bio pasivo, ε decae 30% más lento, Depredador se activa 20% más rápido
**Interacción NG+:** Si la siguiente run llega a REENCARNACIÓN HEREDADA,
  el buff Memoria Oscura se vuelve permanente en el ciclo (stacks con legado_ciclo)
**PL:** base +4 (bajo, pero el valor real está en el buff transmitido)
**Flavor:** *"El ancestral que logró lo imposible deja algo que la ciencia tampoco esperaba."*

---

## Árbol de decisión completo

```
METABOLISMO OSCURO
├── (Bio ≥ 50 + upgrades)     → AUTÓLISIS DIRIGIDA
│   └── (timing perfecto)     → PL+6 máximo
│
├── (Ω decae a 0.05 natural)  → NECROSIS CONTROLADA
│   └── (Ω llega a 0.01)      → PROTOCOLO OMEGA-CERO → PL+8
│
├── (Bio ≥ 200)               → REMISIÓN METABÓLICA  → PL+8 total
│
└── (run_time ≥ 600s)         → ESPORAS DE CONTINGENCIA → buff NG+
```

---

## Notas de implementación

- Todas estas rutas requieren que Dark Met ya esté activo → son sub-rutas, no rutas paralelas
- Ninguna desbloquea Simbiosis ni Red Micelial (ya bloqueadas por Dark Met)
- ESPORAS es la más viable primero: usa sistemas existentes (LegacyManager, SaveManager)
- PROTOCOLO OMEGA-CERO es la más espectacular pero más compleja (Singularidad Inversa UI)
- Los colores sugeridos: Autólisis (naranja oscuro), Necrosis (rojo apagado), Omega-0 (blanco), Remisión (verde oscuro), Esporas (lila/gris)
- Revisar EvoManager para ver dónde enganchar los checks de condición

---

## Frases de flavor adicionales

- "La bioquímica oscura no tiene nombre en los libros. El hongo tampoco lo necesita."
- "Ω = 0. Los modelos matemáticos no contemplan este estado. El hongo sí."
- "Autofagia: consumirse para sobrevivir. El hongo lo hace con precisión quirúrgica."
- "Las esporas no saben que su creador ya no existe. Solo saben lo que aprendió."
