# Pendientes antes de v1.1 (2026-10-16)

El autor decidió **no lanzar v1.1 todavía**. Este documento junta todo lo pendiente (lo que pidió y lo que
quedó de las sesiones anteriores) en bloques, con un orden propuesto. Fuentes: árbol de evoluciones v2
(artifact del autor), `docs/design/involucion_transmutaciones.md`, `docs/design/auditoria_gameplay_2026-10.md`,
memoria del proyecto.

---

## A. Contenido de rutas

### A1. El hueco de Biología (Simbiosis y Parasitismo)
En el árbol, las cinco mutaciones base arrancan en la columna «Mutación», pero sólo tres siguen avanzando:

| Familia | Mutación | Evolución → Sello → Final → Secreto |
|---|---|---|
| Colapso | Hiperasimilación | Depredador → Met. Oscuro → árbol oscuro (5 sub-rutas) → Remisión |
| Red micelial | Red Micelial | Colonización/Simb. Mecánica → Seta/Núcleo → Esporulación/Singularidad → Panspermia/Mente Colmena |
| Orden | Homeostasis | Allostasis → Homeorresis |
| **Biología** | **Parasitismo** | **— (termina ahí)** |
| **Biología** | **Simbiosis** | **— (termina ahí)** |

Parasitismo sólo sirve como `last_run` para el Depredador; Simbiosis no tiene continuación. Las columnas 3–7
de la franja Biología están vacías. Ideas para llenarlo (a definir con el autor):

- **Cruce Parasitismo × Simbiosis — «Endosimbiosis»**: la biología real lo regala (las mitocondrias fueron
  bacterias parásitas que terminaron siendo socias). Puerta tipo Depredador: `last_run = Parasitismo` y
  jugar Simbiosis → el parásito queda **adentro** del pacto. Mecánica posible: llevar las dos economías a la
  vez (la del huésped y la del endosimbionte) y equilibrarlas.
- **Tiers de Simbiosis** (como Homeostasis → Allostasis → Homeorresis): p. ej. Mutualismo → Holobionte.
- Con eso, la Biología tendría su propia **Redención** más adelante.

### A2. Sombras (anti-A) — 1 de 5 hecha
Hecha: Ayuno Primordial (anti-Hiper). Pendientes (spec en `involucion_transmutaciones.md` §6, disparador espejo):
Autosuficiencia (anti-Parasitismo), Autarquía (anti-Simbiosis), Núcleo Aislado (anti-Red Micelial),
Inestabilidad Consciente (anti-Homeostasis, con el botón **OBSERVAR**). Regla de la familia: dan visibilidad
o un sistema nuevo, no multiplicadores.

### A3. Redenciones — 1 de 3
Hecha: Remisión Metabólica (árbol oscuro). Pendientes: **Redención de la Red** (después de Esporulación /
Panspermia) y **Redención del Orden** (después de Singularidad / Mente Colmena). Quedó para «después de las
transmutaciones» → ahora.

### A4. Secretas y Fantasma
- Secretas: Glitch Supremo (easter egg desde Depredador), El Susurro (0 PL, desde Met. Oscuro), El Origen.
- Fantasma (combos de 2 llaves): Dualidad Corrosiva (Fusión + Huésped), Eco Silencioso (Micelio + Caos).

### A5. Meta-endgame (horizonte v2.0)
El Jardín Primigenio (subjuego) → Retorno al Origen (final).

---

## B. Progresión y bancos

### B1. Llaves de involución escalonadas por trascendencia
Hoy **todas** las llaves (5 transmutaciones + Ayuno) se revelan en T ≥ 3, y se habilitan al cerrar la
mutación base. Idea del autor: que cada trascendencia desbloquee caminos nuevos. Propuesta inicial:

| T | Se revela |
|---|---|
| 1 | Fusión Catabólica (Hiper es la primera mutación que se aprende) |
| 2 | Coro Simbiótico · Ayuno Primordial |
| 3 | Caos Orquestado |
| 4 | Micelio Omnisciente |
| 5 | Huésped Soberano |
| 6+ | Sombras nuevas, una por T |

Hay que cruzarlo con lo que ya se desbloquea por T (Banco Cósmico en T1, Omega-Cero en T2, etc.) para que
cada trascendencia traiga algo.

### B2. Rework visual del Banco Genético y del Banco Cósmico
(Pedido del autor; falta definir qué molesta hoy: densidad, categorías, cómo se ven las llaves y los
legados de transmutación, toggles.)

---

## C. Visual

### C1. Paleta del núcleo / mutaciones
Hoy varios colores se pisan (el autor lo marcó). Paso 1: sacar la tabla completa de colores de
`UIManager.get_reactor_color()` (vivo + sellado de cada ruta) y medir distancias; paso 2: proponer una
paleta por familia (Colapso, Oscuro, Biología, Red, Orden, Transmutaciones, Sombras, Post-trascendencia);
paso 3: aplicarla también al árbol y al Codex.

### C2. Árbol de evoluciones (artifact) desactualizado
Ej.: Colapso Controlado todavía dice «ε > 0.90 y Ω > 0.30» (corregido en el juego en `b151c82`).

---

## D. Calidad y deuda técnica (no los mencionó el autor)

| # | Pendiente | Origen |
|---|---|---|
| D1 | **C9 vista**: dirty-checking de labels, sacar `update_ui()` del click, `fungi_ui` sin refresco por frame (~90 % del costo medido de UI) | sprint de deuda 2026-10 |
| D2 | Localización: panel de Ayuno con textos fijos en español (G6); `LEGACY_DEFS` sin traducir | auditoría / memoria |
| D3 | Código muerto: `_on_BigClickButton_pressed` (ε 0.008); `main.tscn` conecta `pressed → _on_pressed` inexistente | hallazgos 2026-10 |
| D4 | **G2**: Colapso Sintético da 0 PL — confirmar si es intencional | auditoría A1 |
| D5 | Codex: entrada de introducción a la involución con las 5 transmutaciones | roadmap v1.1 |
| D6 | Pasada en el export web: símbolos nuevos (⟳ ◈), audio del metrónomo (AudioStreamWAV generado) | R4b |
| D7 | Feedback del autor jugando: Coro (ventana ±0.20 s, 80/95/110 BPM), Huésped, Micelio | R4b–R6 |

---

## E. Orden propuesto

1. **Decisiones baratas primero** (en chat, sin código): escalonado por T (B1), qué es «el hueco» de
   Biología (A1), qué molesta de los bancos (B2).
2. **Paleta** (C1): toca a todo lo que viene después; mejor definirla antes de sumar rutas con color nuevo.
3. **Biología** (A1): llena el hueco más visible del árbol y habilita su Redención.
4. **Sombras** (A2), una por vez con el mismo proceso de las transmutaciones (spec → números → bot).
5. **Redenciones** (A3).
6. **Bancos** (B2) con todo el contenido ya adentro.
7. Secretas / Fantasma (A4) y deuda (D) intercaladas.
