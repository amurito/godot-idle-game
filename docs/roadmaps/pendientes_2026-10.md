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

**Spec para revisión:** `docs/design/biologia_mutualismo_endosimbiosis.md` (Mutualismo = negociar, Holobionte = sostener 4 socios, Endosimbiosis = dosificar genes; 6 preguntas abiertas en §9).

### A2. Sombras (anti-A) — 2 de 6 hechas
Hechas: Ayuno Primordial (anti-Hiper) e **Inestabilidad Consciente** (anti-Homeostasis, 2026-10-18, lore
matemático; su recompensa son los 3 legados de conocimiento). Pendientes (spec `docs/design/sombras.md`, en este
orden): Procariota (anti-Endosimbiosis), Antibiosis (anti-Simbiosis, ex Autarquía), Autosuficiencia
(anti-Parasitismo), Hifa Pionera (anti-Red Micelial, ex Núcleo Aislado). Regla de la familia: dan visibilidad
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
mutación base. **Decidido por el autor (2026-10-16)**: cada trascendencia abre una capa entera:

| T | Se desbloquea |
|---|---|
| 0 | Lo necesario para trascender: mutaciones base + sus ramas directas |
| 1 | Post-trascendencia (lo que ya abre hoy: Panspermia, Mente Colmena…) + **Biología nueva** (Mutualismo → Holobionte, Endosimbiosis) |
| 2 | Árbol oscuro: Depredador / Met. Oscuro y sus 5 sub-rutas (hoy Depredador sale con T > 1 o `last_run` Parasitismo) |
| 3 | Las 5 transmutaciones (como hoy) |
| 4 | Sombras, **Ayuno incluido** (sale de T3) |
| 5 | Redenciones, **Remisión incluida** |
| 6 | Fantasma / combos de 2 llaves |

A revisar al implementar: los `TRANSCENDENCE_MILESTONES` hoy sólo existen para T1–T3; Esclerocio pide T ≥ 1 y
Omega-Cero T ≥ 2 (quedan dentro del árbol oscuro → pasan a T2); Hiper tarda 60 s en vez de 180 s con T > 2.

### B2. Rework visual del Banco Genético y del Banco Cósmico
Decidido por el autor (2026-10-16):
- **Banco Genético**: se siente desordenado → ordenarlo **por familia del árbol** (Colapso, Oscuro, Biología,
  Red, Orden, Transmutaciones, Sombras, Redenciones). ~~Implementar los 3 legados de conocimiento~~ ✅
  2026-10-18: ahora funcionan y son la recompensa de Inestabilidad Consciente (ya no se compran).
- **Banco Cósmico** (15 buffs en tiers 1–3, sin contenido nuevo hace mucho): las cuatro líneas — un tier por
  cada T nueva, atajos de involución (p. ej. arrancar con una llave más avanzada), calidad de vida, y revisar
  los 15 actuales.

---

## C. Visual

### C1. Paleta del núcleo / mutaciones
Hoy varios colores se pisan (el autor lo marcó). Paso 1 ✅: tabla de 40 colores de
`UIManager.get_reactor_color()` / `_live_reactor_color()` y distancias ΔE (CIE76, Lab): **21 pares < 18**.
Peores: Esclerocio ~ Colapso Sintético sellados (4.1), Depredador ~ Caos (6.6), Simbiosis ~ Homeostasis (10.5),
Fractura ~ Fusión (11.8), Núcleo base ~ Huésped (13.9), racimo turquesa del Orden y racimo verde de la Red.

Paso 2 ✅ (aprobada y aplicada en `UIManager.get_reactor_color()` / `_live_reactor_color()` y `TRANSMUT_BTN_COLORS`): cambian 19 colores y 21 quedan igual; todos los pares ≥ 20 salvo
Depredador de Realidades ~ Autofagia sellados (17, ambos casi negros).

| Ruta | Hoy | Propuesto | Por qué |
|---|---|---|---|
| Fractura Epistémica (destello) | `#ffd90d` | `#e6f4ff` blanco cristal | chocaba con Fusión (oro) |
| Autofagia sellado | `#590014` | `#5c1408` vino-óxido | Depredador de Realidades / Caos sellados |
| Esclerocio sellado | `#14002e` | `#3a2410` marrón (un esclerocio real es una masa marrón) | Colapso Sintético |
| Omega-Cero | `#472e61` | `#a58ce0` lila pálido | Met. Oscuro sellado |
| Colapso Sintético sellado | `#1a0d33` | `#003a30` verde petróleo | Esclerocio |
| Remisión | `#14b87a` | `#fff1d6` marfil (familia Redención = luz) | Homeostasis |
| Simbiosis | `#66e6b2` | `#ff8fd0` rosa orquídea (Biología = naranja→rosa) | Homeostasis |
| Colonización | `#73ff0d` | `#b0ff1a` lima | Red Micelial |
| Esporulación | `#b2ff66` | `#c8ffa0` verde pálido | Seta |
| Seta formada | `#a6ff33` | `#e0b070` beige de sombrero | Colonización |
| Núcleo de Conciencia | `#3380ff` | `#a8c4ff` celeste pálido | Núcleo base / Huésped |
| Allostasis | `#33ffe0` | `#00a88a` turquesa profundo | Homeostasis / Homeorresis |
| Homeorresis | `#8cffeb` | `#b5fff0` menta casi blanca | Allostasis |
| Caos Orquestado (vivo / sellado) | `#ff1f61` / `#6b0d2e` | `#ff2bd0` / `#6b0a5a` fucsia | Depredador |
| Coro sellado | `#73241c` | `#a8452e` | Autofagia sellado |
| Micelio sellado | `#4c2175` | `#6a40c8` | Met. Oscuro (vivo y sellado) |
| Huésped (vivo / sellado) | `#5999ff` / `#1a2e6b` | `#4a52ff` / `#1f3a8f` índigo | Núcleo base / Omega-Cero |

Paso 3: el juego no tiene otros colores por ruta (el Codex no usa color por ruta). Falta el árbol del artifact del autor (C2).

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
